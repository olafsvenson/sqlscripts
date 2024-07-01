USE [Monitoring]
GO

/****** Object:  Table [dbo].[monitoring_backups]    Script Date: 27.11.2015 11:08:00 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[monitoring_backups]') AND type in (N'U'))
DROP TABLE [dbo].[monitoring_backups]
GO

/****** Object:  Table [dbo].[monitoring_backups]    Script Date: 27.11.2015 11:08:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[monitoring_backups]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[monitoring_backups](
	[name] [sysname] NOT NULL,
	[type] [varchar](100) NULL,
	[backup_age] [varchar](100) NULL,
	[recovery_model] [varchar](100) NULL,
	[backup_start_date] [datetime] NULL,
	[backup_finish_date] [datetime] NULL,
	[backup_size] [decimal](20, 3) NULL,
	[compressed_backup_size] [decimal](20, 3) NULL
) ON [PRIMARY]
END
GO

SET ANSI_PADDING OFF
GO


