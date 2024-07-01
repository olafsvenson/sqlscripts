IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TraceReport_IgnoreDatabases]') AND type in (N'U'))
DROP TABLE [dbo].[TraceReport_IgnoreDatabases]
GO


CREATE TABLE TraceReport_IgnoreDatabases
(
	DatabaseName NVARCHAR(256)
)
go

CREATE CLUSTERED INDEX CI_DatabaseName ON TraceReport_IgnoreDatabases (DatabaseName)
go

GRANT SELECT ON [dbo].[TraceReport_IgnoreDatabases] TO TraceReportUser
go
GRANT INSERT ON [dbo].[TraceReport_IgnoreDatabases] TO TraceReportUser
go