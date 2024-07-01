USE [Monitoring]
GO

/****** Object:  Table [dbo].[monitoring_jobs]    Script Date: 27.11.2015 11:08:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[monitoring_jobs]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[monitoring_jobs](
	[Name] [sysname] NOT NULL,
	[last_run_date] [int] NOT NULL,
	[last_run_time] [int] NOT NULL,
	[description] [nvarchar](512) NULL,
	[Res] [varchar](6) NULL,
	[last_outcome_message] [nvarchar](4000) NULL
) ON [PRIMARY]
END
GO

SET ANSI_PADDING OFF
GO


