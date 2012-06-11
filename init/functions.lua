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

