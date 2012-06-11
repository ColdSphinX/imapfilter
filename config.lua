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

require "sort/foo"
require "sort/gmail"
require "sort/bar"


-----------
--  END  --
-----------

my.main()
