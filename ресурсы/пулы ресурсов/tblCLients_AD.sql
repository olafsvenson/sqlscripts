SELECT * 
into TrackingSystem..tblClients
FROM svadba_catalog..tblClients 

use TrackingSystem
go
create clustered index CI_tblCLients_ClientID on tblClients (clientid)

create index tblCLients_EmailAddress_inc_ALL on tblClients (EmailAddress) include (password)

CREATE NONCLUSTERED INDEX [tt] ON [dbo].[tblClients] (	[EmailAddress] ASC,	[ClientID] ASC,	[AFID] ASC) WHERE StorageID <> 1000003 



SELECT * 
into TrackingSystem..tblClients_OB
FROM tmpdb..tblClients_OB


SELECT * 
into TrackingSystem..TokensStat_OB
FROM tmpdb.dbo.TokensStat_OB


USE [tmpDB]
GO

/****** Object:  Index [TokensStat_AD]    Script Date: 06/18/2013 14:09:35 ******/
CREATE NONCLUSTERED INDEX [TokensStat_AD] ON [dbo].[TokensStat_AD] 
(
	[clientid] ASC
)
INCLUDE ( [Tokens_Sum],
[Tokens_count]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

USE [tmpDB]
GO

/****** Object:  Index [TokensStat_OB]    Script Date: 06/18/2013 14:10:06 ******/
CREATE NONCLUSTERED INDEX [TokensStat_OB] ON [dbo].[TokensStat_OB] 
(
	[clientid] ASC
)
INCLUDE ( [Tokens_Sum],
[Tokens_count]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

