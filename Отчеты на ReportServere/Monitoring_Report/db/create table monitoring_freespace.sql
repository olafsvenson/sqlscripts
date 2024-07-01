USE [Monitoring]
GO

/****** Object:  Table [dbo].[monitoring_freespace]    Script Date: 27.11.2015 11:08:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[monitoring_freespace]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[monitoring_freespace](
	[drive] [nvarchar](100) NULL,
	[MBFree] [int] NULL,
	[AlertSizeGB] [int] NULL
) ON [PRIMARY]
END
GO


