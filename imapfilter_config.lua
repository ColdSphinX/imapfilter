require "init/base"

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
