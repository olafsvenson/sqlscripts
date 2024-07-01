USE [Monitoring]
GO

/****** Object:  Index [IX_CheckPointLog_DateStart_DateEnd_DBID]    Script Date: 27.11.2015 11:07:11 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[CheckPointLog]') AND name = N'IX_CheckPointLog_DateStart_DateEnd_DBID')
DROP INDEX [IX_CheckPointLog_DateStart_DateEnd_DBID] ON [dbo].[CheckPointLog]
GO

/****** Object:  Table [dbo].[CheckPointLog]    Script Date: 27.11.2015 11:07:11 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CheckPointLog]') AND type in (N'U'))
DROP TABLE [dbo].[CheckPointLog]
GO

/****** Object:  Table [dbo].[CheckPointLog]    Script Date: 27.11.2015 11:07:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CheckPointLog]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[CheckPointLog](
	[DBID] [int] NOT NULL,
	[DateStart] [datetime] NOT NULL,
	[DateEnd] [datetime] NOT NULL,
	[DurationMls] [int] NOT NULL,
	[DurationSec]  AS ([DurationMls]/(1000)) PERSISTED,
	[DurationMin]  AS (([DurationMls]/(1000))/(60)) PERSISTED,
	[DBName] [varchar](500) NULL,
	[ServerName] [varchar](500) NOT NULL,
	[ProcessInfo] [varchar](1000) NULL
) ON [PRIMARY]
END
GO

SET ANSI_PADDING OFF
GO

/****** Object:  Index [IX_CheckPointLog_DateStart_DateEnd_DBID]    Script Date: 27.11.2015 11:07:12 ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[CheckPointLog]') AND name = N'IX_CheckPointLog_DateStart_DateEnd_DBID')
CREATE NONCLUSTERED INDEX [IX_CheckPointLog_DateStart_DateEnd_DBID] ON [dbo].[CheckPointLog]
(
	[DateStart] ASC,
	[DateEnd] ASC,
	[DBID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO


