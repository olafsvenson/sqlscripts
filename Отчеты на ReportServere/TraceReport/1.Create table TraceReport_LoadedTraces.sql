IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TraceReport_LoadedTraces]') AND type in (N'U'))
DROP TABLE [dbo].[TraceReport_LoadedTraces]
GO


CREATE TABLE TraceReport_LoadedTraces
(
	File_Name VARCHAR(100),
	DateOfLoad DATETIME DEFAULT GETDATE()
)
go

CREATE CLUSTERED INDEX CI_FileName ON TraceReport_LoadedTraces (File_Name)
go

--GRANT SELECT ON [dbo].[TraceReport_LoadedTraces] TO TraceReportUser
--go
--GRANT INSERT ON [dbo].[TraceReport_LoadedTraces] TO TraceReportUser
--go