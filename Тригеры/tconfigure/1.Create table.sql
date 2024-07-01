USE [sputnik]
GO

/****** Object:  Table [adt].[jconfigure]    Script Date: 30.09.2021 11:25:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [adt].[jconfigure](
	[tt] [datetime2](3) NOT NULL,
	[PName] [nvarchar](50) NOT NULL,
	[POldValue] [int] NOT NULL,
	[PNewValue] [int] NOT NULL,
	[LoginName] [sysname] NOT NULL,
	[spid] [smallint] NOT NULL,
	[Host] [nvarchar](75) NOT NULL,
	[HostName] [nvarchar](100) NULL,
	[Host_pid] [int] NULL,
	[ProgramName] [nvarchar](200) NULL
) ON [PRIMARY]
GO

ALTER AUTHORIZATION ON [adt].[jconfigure] TO  SCHEMA OWNER 
GO

GRANT INSERT ON [adt].[jconfigure] TO [audit_writer] AS [dbo]
GO

/****** Object:  Index [ci_tt]    Script Date: 30.09.2021 11:25:13 ******/
CREATE CLUSTERED INDEX [ci_tt] ON [adt].[jconfigure]
(
	[tt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

