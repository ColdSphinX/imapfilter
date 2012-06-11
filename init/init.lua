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
   local host = "cold-nas"
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
my.daemon.enabled = false
-- wait X seconds between sort intervals
my.daemon.sleep = 600
-- read passwords from encrypted file
my.crypt.enabled = false
-- there are X passwords in that file
my.crypt.num = 3
-- that file can be found there
my.crypt.path = '~/.imapfilter/passwords.enc'
-- force all accounts to be sorted (dissabled)
my.force = false
-- don't have more than one account logged in at a time
my.singlelogin = true


----------------
--  Accounts  --
----------------

function my.init.accounts()

   -- initialise accounts and fill my option arrays

   dbgprint("Initialisiere Email-Konten")
   password = my.init.crypt(my.crypt)

   -- if you don't want your passwords encryptet you could place 'em here
   if (password == nil) then
      password = { 'cold1-pp', 'Fe3C-SphinX_', 'coldy132xn', }
   end

   my.list = { 'pps', 'gmail', 'xinux', }

   -- sort this account
   my.pps = my.init.account({
      name = "Piratenpartei Saar",
      enable = true,
      random = false,
      sort = my.sort.pps, -- how to sort this account -> f(account)
      server = 'mail.piratenpartei-saarland.de',
      username = 'pascal.briehl',
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
      username = 'pascal.briehl@googlemail.com',
      password = password[2],
      ssl = 'ssl3',
   })

   -- this account should only be sorted once in a while
   my.xinux = my.init.account({
      name = "Xinux e.K.",
      enable = true,
      random = true,
      sort = my.sort.xinux,
      server = 'baltar.tuxmen.de',
      username = 'pascal',
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


---------------------
--  Piratenpartei  --
---------------------

function my.sort.pps(acc)

   --  Ankuendigungen
   dbgprint(" * Ankuendigungen")
   msgs = acc.INBOX:is_unseen() * (
          acc.INBOX:match_to('ankuendigungen@.*piratenpartei.*\.de') +
          acc.INBOX:match_cc('ankuendigungen@.*piratenpartei.*\.de') +
          acc.INBOX:match_bcc('ankuendigungen@.*piratenpartei.*\.de') )
   acc.INBOX:move_messages(acc['MailingLists/Ankuendigungen'],msgs)

   --  LV Saarland  --
   -------------------
   dbgprint(" * LV Saarland")

   --  Ankuendigungen
   dbgprint("   - Ankuendigungen")
   msgs = acc.INBOX:is_unseen() * (
          acc.INBOX:match_to('announce-verteiler@.*piratenpartei.*\.de') +
          acc.INBOX:match_cc('announce-verteiler@.*piratenpartei.*\.de') +
          acc.INBOX:match_bcc('announce-verteiler@.*piratenpartei.*\.de') )
   acc.INBOX:move_messages(acc['MailingLists/Saar/Ankuendigungen'],msgs)

   --  Saarland ML
   dbgprint("   - Saarland ML")
   msgs = acc.INBOX:is_unseen() * (
          acc.INBOX:match_to('[Ss]aarland@.*piratenpartei.*\.de') +
          acc.INBOX:match_cc('[Ss]aarland@.*piratenpartei.*\.de') +
          acc.INBOX:match_bcc('[Ss]aarland@.*piratenpartei.*\.de') )
   acc.INBOX:mark_seen(msgs)
   acc.INBOX:move_messages(acc['MailingLists/Saar'],msgs)

   --  Server  --
   --------------

   --  Cron
   dbgprint("   - Cron")
   msgs = acc.INBOX:is_unseen() *
          acc.INBOX:match_from('root@.*piratenpartei.*\.de') *
          acc.INBOX:contain_subject('Cron')
   acc.INBOX:move_messages(acc['Piraten/Server/cron'],msgs)

   --  ML Moderatoranforderungen
   dbgprint("   - ML Moderatoranforderungen")
   msgs = acc.INBOX:is_unseen() * (
          acc.INBOX:match_to('.*-owner@.*piratenpartei.*\.de') +
          acc.INBOX:match_cc('.*-owner@.*piratenpartei.*\.de') +
          acc.INBOX:match_bcc('.*-owner@.*piratenpartei.*\.de') +
          acc.INBOX:match_from('.*-bounces@.*piratenpartei.*\.de') )
   acc.INBOX:move_messages(acc['MailingLists'],msgs)

   --  Sonstige
   dbgprint("   - Sonstige")
   msgs = (( acc.INBOX:is_unseen() * (
          acc.INBOX:contain_from('www-data') +
          acc.INBOX:match_from('root@.*piratenpartei.*\.de') ) ) -
          acc.INBOX:contain_subject('Cron') )
   acc.INBOX:move_messages(acc['Piraten/Server'],msgs)

   --  AG MLs  --
   --------------

   --  Technik
   dbgprint("   - AG Technik ML")
   msgs = acc.INBOX:is_unseen() * (
          acc.INBOX:match_to('ag-technik@.*piratenpartei.*\.de') +
          acc.INBOX:match_cc('ag-technik@.*piratenpartei.*\.de') +
          acc.INBOX:match_bcc('ag-technik@.*piratenpartei.*\.de') )
   acc.INBOX:move_messages(acc['MailingLists/Saar/AG-Technik'],msgs)

end


-------------------
--  Google Mail  --
-------------------

function my.sort.gmail(acc)
   dbgprint(" * there is nothing here yet... :(")
end


-------------
--  Xinux  --
-------------

function my.sort.xinux(acc)

   -- Bacula
   dbgprint(" * Bacula")
   msgs = acc.INBOX:is_unseen() *
	acc.INBOX:match_subject('.*Bacula\: Backup.*')
   acc.INBOX:move_messages(acc['Bacula'],msgs)

   -- backup
   dbgprint(" * Backup")
   msgs = acc.INBOX:is_unseen() *
	acc.INBOX:match_to('backup@.*')
   acc.INBOX:move_messages(acc['Backup'],msgs)

   -- Stundenzettel
   dbgprint(" * Stundenzettel")
   msgs = acc.INBOX:is_unseen() *
	acc.INBOX:contain_subject('Stundenzettel')
   acc.INBOX:move_messages(acc['Stundenzettel'],msgs)

   -- nagios
   dbgprint(" * nagios")
   msgs = acc.INBOX:is_unseen() * (
	acc.INBOX:match_to('nagios@.*') +
	acc.INBOX:match_cc('nagios@.*') )
   acc.INBOX:move_messages(acc['nagios'],msgs)

   -- Spam
   dbgprint(" * Spam")
   msgs = acc.INBOX:is_unseen() *
	acc.INBOX:contain_subject('Phish found notification')
   acc.INBOX:move_messages(acc['Spam'],msgs)

   -- cron
   dbgprint(" * cron")
   msgs = acc.INBOX:is_unseen() *
	acc.INBOX:contain_subject('cron')
   acc.INBOX:move_messages(acc['cron'],msgs)

   -- logcheck
   dbgprint(" * logcheck")
   msgs = acc.INBOX:is_unseen() * (
	acc.INBOX:contain_to('logcheck@xinux.de') +
	acc.INBOX:contain_cc('logcheck@xinux.de') )
   acc.INBOX:move_messages(acc['logcheck'],msgs)

   -- trendmicro
   dbgprint(" * trendmicro")
   msgs = acc.INBOX:is_unseen() * (
	acc.INBOX:match_to('trendmicro@.*') +
	acc.INBOX:match_cc('trendmicro@.*') +
	acc.INBOX:match_from('iwsva@.*') +
	acc.INBOX:match_subject('.*[Ii]nter[Ss]can.*') )
   acc.INBOX:move_messages(acc['trendmicro'],msgs)

   -- technik
   dbgprint(" * Technik")
   msgs = acc.INBOX:is_unseen() * (
	acc.INBOX:match_to('technik@.*') +
	acc.INBOX:match_cc('technik@.*') )
   acc.INBOX:move_messages(acc['technik'],msgs)

end


-----------
--  END  --
-----------

my.main()
