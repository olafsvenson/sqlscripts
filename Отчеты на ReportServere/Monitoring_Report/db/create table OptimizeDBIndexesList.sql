USE [Monitoring]
GO

/****** Object:  Table [dbo].[OptimizeDBIndexesList]    Script Date: 27.11.2015 11:09:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[OptimizeDBIndexesList]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[OptimizeDBIndexesList](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[DB_NAME] [sysname] NOT NULL
) ON [PRIMARY]
END
GO


