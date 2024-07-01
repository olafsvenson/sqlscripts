use tempdb
go
select   sysfilegroups.groupid
		,Files.FileId
		,sysfilegroups.groupname
		,Files.FileName
		,Files.AllocatedMb
		,Files.SpaceUsedMb
		,Files.AllocatedMb - Files.SpaceUsedMb as SpaceFreeMb
from	dbo.sysfilegroups
	JOIN	(
				SELECT	sysfiles.FileId
						,sysfiles.name 		AS FileName
						,sysfiles.groupid	
						--,sysfiles.size 
						,(CONVERT(BIGINT, sysfiles.size) * 8 / 1024) 	AS AllocatedMb
						,( (CAST(FILEPROPERTY(sysfiles.name, 'SpaceUsed' ) AS bigint) * 8 ) / 1024)  AS SpaceUsedMb
				FROM 	dbo.sysfiles
		) as Files	
		on sysfilegroups.groupid = Files.groupid
order by 
		sysfilegroups.groupid,
		Files.FileId