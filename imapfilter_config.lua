-----------------------
--  Basic functions  --
-----------------------
DEBUG = true

-- Save print()
printstr = print
-- Debug print()
function dbgprint(s)
   if DEBUG == true then
      printstr("# " .. s)
   end
end
-- Enable logging / overwrite print()
function print(s)
   local logfile = "/var/log/imapfilter.log"
   local date = os.date("%a %d %H:%M:%S")
   local host = "localhost"
   local service = "imapfilter"
   local prefix = string.format("%s %s %s: ",date,host,service)
   local f = io.open(logfile,"a+")
   f:write(prefix .. tostring(s) .. "\n")
   f:flush()
   f:close()
   if DEBUG == true then
      printstr(s)
   end
end
function sleep(n)
  os.execute("sleep " .. tonumber(n))
end


----------------------
--  Init namespace  --
----------------------

my = my or {}
my.init = {}
my.daemon = {}
my.crypt = {}
my.sort = {}


----------------------
--  Global Options  --
----------------------

options.timeout = 120
options.namespace = true
options.subscribe = true


---------------
--  Options  --
---------------

-- be a background daemon
my.daemon.enabled = true
-- wait X seconds between sort intervals
my.daemon.sleep = 600

-- force all accounts to be sorted (dissabled)
my.force = false
-- don't have more than one account logged in at a time
my.singlelogin = true

-- read passwords from encrypted file
my.crypt.enabled = true
-- there are X passwords in that file
my.crypt.num = 3
-- that file can be found there
my.crypt.path = '~/.imapfilter/passwords.enc'

--[[
 The file is encrypted using the openssl(1) command line tool. For
 example the "passwords.txt" file:

 secret1
 secret2

 ... is encrypted and saved to a file named "passwords.enc" with the
 command:

 $ openssl bf -in passwords.txt -out ~/.imapfilter/passwords.enc
 $ rm passwords.txt
]]--

----------------
--  Accounts  --
----------------

function my.init.accounts()

   -- initialise accounts and fill my option arrays

   dbgprint("Initialisiere Email-Konten")
   password = my.init.crypt(my.crypt)

   -- if you don't want your passwords encryptet you could place 'em here
   if (password == nil) then
      password = { 'thisisapassword', 'thisanotherpassword', 'andyetanotherpassword', }
   end

   my.list = { 'foo', 'gmail', 'bar', }

   -- sort this account
   my.foo = my.init.account({
      name = "account on server foo",
      enable = true,
      random = false,
      sort = my.sort.foo, -- how to sort this account -> f(account)
      server = 'foo.my-net.local',
      username = 'myusername',
      password = password[1],
      ssl = 'ssl3',
   })

   -- this account is currently excluded from sorting
   my.gmail = my.init.account({
      name = "Google Mail",
      enable = false,
      random = false,
      sort = my.sort.gmail,
      server = 'imap.googlemail.com',
      username = 'myusername@gmail.com',
      password = password[2],
      ssl = 'ssl3',
   })

   -- this account should only be sorted once in a while
   my.bar = my.init.account({
      name = "account on server bar",
      enable = true,
      random = true,
      sort = my.sort.bar,
      server = 'bar.my-other-net.local',
      username = 'myusername',
      password = password[3],
      ssl = 'ssl3',
   })
end


--------------------
--  My functions  --
--------------------

function my.sort.all()

   -- go through all accounts and start their sort function

   my.init.random()
   dbgprint("Starte Sortierung...")
   dbgprint(" * " .. (my.numaccounts - my.rndfail) .. " Accounts")

   for _,i in pairs(my.list)
   do
      if ((type(my[i].sort) == 'function') and ((my[i].enable == true) or (my.force == true)) and (my[i].account ~= nil)) then
         if ((my[i].name ~= nil) and (my[i].name ~= 'unknown')) then
            dbgprint("Sortiere: " .. my[i].name)
         else
            dbgprint("Sortiere: " .. tostring(i))
         end
		 if (my.singlelogin == true) then
            IMAP.login(my[i].account)
		 end
         my[i].sort(my[i].account)
		 if (my.singlelogin == true) then
            IMAP.logout(my[i].account)
		 end
      end
   end
   dbgprint("Done")
end

function my.daemon.loop()

   -- start these functions when daemon

   dbgprint("daemon loop gestartet")

   my.sort.all()

   dbgprint("sleep " .. my.daemon.sleep .. "sec.")
end

function my.init.crypt(opt)

   -- read passwords from encrypted file

   if ((opt.enabled == true) and (type(opt.path) == 'string') and (type(opt.num) == 'number')) then
      password = {}
      dbgprint("Entschlüssele Passwörter")
      status, output = pipe_from('openssl bf -d -in ' .. opt.path)
      local found = 0
      local i = 1
      while (i <= opt.num)
      do
         _, found, password[i] = string.find(output, '([%w%p]+)\n',found + 1)
         i = i + 1
      end
      return password
   else
      return nil
   end
end

function my.init.random()

   -- randomize the some accounts current "has to be sorted" status

   dbgprint("Randomize...")
   local min, max = 50, 75
   local rmin, rmax = 1, 100
   math.randomseed(os.time())
   my.rndfail = 0
   for _,i in pairs(my.list)
   do
      if ((type(my[i].account) == 'table') and (my[i].random == true) and (my.force == false)) then
         local rnd = math.random(rmin,rmax)
         if ((my[i].name ~= nil) and (my[i].name ~= 'unknown')) then
            dbgprint(my[i].name .. " randomize (" .. rmin .. "-" .. rmax .. "):")
         else
            dbgprint(tostring(i) .. " randomize (" .. rmin .. "-" .. rmax .. "):")
         end
         dbgprint(" => " .. rnd .. " (" .. min .. "-" .. max .. ")")
         if ((rnd < min) or (rnd > max)) then
            dbgprint(" => fail")
            my[i].enable = false
			my.rndfail = my.rndfail + 1
         else
            dbgprint(" => ok")
            my[i].enable = true
         end
      end
   end
end

function my.init.account(arg)

   -- initialise an account

   loginacc = {}
   imapacc = {}

   if (type(arg.server) == 'string') then
      imapacc.server = arg.server
   else
      return nil
   end
   if (type(arg.username) == 'string') then
      imapacc.username = arg.username
   else
      return nil
   end
   if (type(arg.password) == 'string') then
      imapacc.password = arg.password
   end
   if (type(arg.port) == 'number') then
      imapacc.port = arg.port
   end
   if (type(arg.ssl) == 'string') then
      imapacc.ssl = arg.ssl
   end
   if ((arg.enable == true) or (my.force == true)) then
      loginacc.enable = true
   else
      loginacc.enable = false
   end
   if (type(arg.name) == 'string') then
      loginacc.name = arg.name
   else
      loginacc.name = "unknown"
   end
   if (arg.random ~= true) then
      loginacc.random = false
   else
      loginacc.random = true
   end
   if (type(arg.sort) == 'function') then
      loginacc.sort = arg.sort
   else
      loginacc.sort = nil
   end
   if (loginacc.enable == true) then
      dbgprint("* Account: " .. loginacc.name)
      loginacc.account = IMAP(imapacc)
	  if (my.singlelogin == true) then
	     IMAP.logout(loginacc.account)
	  end
	  
	  if (type(my.numaccounts) ~= 'number') then
	     my.numaccounts = 1
	  else
	     my.numaccounts = my.numaccounts + 1
	  end
	  
	  return loginacc
   else
      return nil or {}
   end
end

function my.main()
   if (my.singlelogin ~= false) then
      my.singlelogin = true
   end
   
   my.init.accounts()

   if (type(my.numaccounts) ~= 'number') then
      my.numaccounts = 0
   end
   
   if (my.daemon.enabled == true) then
      dbgprint("werde zum daemon ]:->")
      if (DEBUG == true) then
         while true do
            my.sort.all()
            dbgprint("sleep " .. my.daemon.sleep .. "sec.")
            sleep(my.daemon.sleep)
         end
      else
         become_daemon(my.daemon.sleep, my.daemon.loop)
      end
   else
      my.sort.all()
   end
end


----------------------
--  Sort Functions  --
----------------------

--  Help:
-- "+" means "or"
-- "*" means "and"
-- "-" means "and not"
-- acc.INBOX:mark_seen(msgs)
-- msgs:add_flags({ '\\Seen', '\\Flagged' })


------------------
--  foo Server  --
------------------

function my.sort.foo(acc)
   -- nagios
   dbgprint(" * nagios")
   msgs = acc.INBOX:is_unseen() * (
        acc.INBOX:match_to('nagios@.*') +
        acc.INBOX:match_cc('nagios@.*') )
   acc.INBOX:move_messages(acc['nagios'],msgs)

   -- cron
   dbgprint(" * cron")
   msgs = acc.INBOX:is_unseen() *
        acc.INBOX:contain_subject('cron')
   acc.INBOX:move_messages(acc['cron'],msgs)

   -- logcheck
   dbgprint(" * logcheck")
   msgs = acc.INBOX:is_unseen() * (
        acc.INBOX:match_to('logcheck@.*') +
        acc.INBOX:match_cc('logcheck@.*') )
   acc.INBOX:move_messages(acc['logcheck'],msgs)


   -- Bacula
   dbgprint(" * Bacula")
   msgs = acc.INBOX:is_unseen() *
        acc.INBOX:match_subject('.*Bacula\: Backup.*')
   acc.INBOX:move_messages(acc['Backup/Bacula'],msgs)

   -- backup
   dbgprint(" * Backup")
   msgs = acc.INBOX:is_unseen() *
        acc.INBOX:match_to('backup@.*')
   acc.INBOX:move_messages(acc['Backup'],msgs)
end


-------------------
--  Google Mail  --
-------------------

function my.sort.gmail(acc)
   dbgprint(" * there is nothing here yet... :(")
end


------------------
--  bar Server  --
------------------

function my.sort.foo(acc)
   dbgprint(" * I put my filter rules there")
end


-----------
--  END  --
-----------

my.main()
