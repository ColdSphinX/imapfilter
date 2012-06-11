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
