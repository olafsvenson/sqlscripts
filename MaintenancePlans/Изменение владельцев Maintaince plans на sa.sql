SELECT * FROM [msdb].[dbo].[sysssispackages]

-- Изменение владельцев Maintaince plans на sa
update [msdb].[dbo].[sysssispackages] set ownersid=0x01
where ownersid<>0x01