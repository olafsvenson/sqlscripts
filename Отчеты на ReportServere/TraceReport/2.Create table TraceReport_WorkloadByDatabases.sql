IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TraceReport_WorkloadByDatabases]') AND type in (N'U'))
DROP TABLE [dbo].[TraceReport_WorkloadByDatabases]
GO



SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TraceReport_WorkloadByDatabases](
	DateOfAdded DATE DEFAULT GETDATE(),
	[DatabaseName] [nvarchar](256) NULL,
	[sumCPU] [int] NULL,
	[avgCPU] [int] NULL,
	[sumDurationSec] [bigint] NULL,
	[avgDurationMs] [bigint] NULL,
	[avgReads] [bigint] NULL,
	[avgWrites] [bigint] NULL,
	[Count] [int] NULL
) ON [PRIMARY]

GO
--GRANT SELECT ON [dbo].[TraceReport_WorkloadByDatabases] TO TraceReportUser
--go
--GRANT INSERT ON [dbo].[TraceReport_WorkloadByDatabases] TO TraceReportUser
--go

CREATE CLUSTERED INDEX  [CI_DateOfAdded]
ON [dbo].[TraceReport_WorkloadByDatabases] ([DateOfAdded])

GO