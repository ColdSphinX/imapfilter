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
