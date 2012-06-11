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
--]]
