--[[
  Don't change this file!
  Don't change this file!
  Don't change this file!
  Don't change this file!
  Don't change this file!
--]]

-- get $HOME
local f = io.popen("echo -n $HOME")
local l = f:read("*a")
f:close()
-- fix include path
package.path = package.path .. ";" .. l .. "/.imapfilter/?.lua"

require "init/base"

---------------
--  Options  --
---------------

require "options"


----------------
--  Accounts  --
----------------

function my.init.accounts()

   -- initialise accounts and fill my option arrays

   dbgprint("Initialisiere Email-Konten")
   password = my.init.crypt(my.crypt)

   require "accounts"
end


--------------------
--  My functions  --
--------------------

require "init/functions"


----------------------
--  Sort Functions  --
----------------------

require "sort"


-----------
--  END  --
-----------

my.main()
