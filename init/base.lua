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
