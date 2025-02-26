USE svadba_catalog
GO

SELECT
	ROW_NUMBER() OVER (PARTITION BY gfnv.Name ORDER BY gfnv.Name, gfnv.FirstNameID) AS row,
	gfnv.FirstNameID, gfnv.Name
INTO #first_names
FROM tblGirlFirstNameValues gfnv WITH(NOLOCK)
	INNER JOIN (
		SELECT Name, COUNT(1) AS cnt
		FROM tblGirlFirstNameValues WITH(NOLOCK)
		WHERE CultureID = 1
		GROUP BY Name HAVING COUNT(1) > 1
) q
		ON gfnv.Name = q.Name
WHERE gfnv.CultureID = 1
ORDER BY gfnv.Name, gfnv.FirstNameID
GO

-- select * from #first_names

SELECT g.*
INTO __tblGirls_backup_201110
FROM tblGirls g WITH (NOLOCK)
	INNER JOIN (
		SELECT * FROM #first_names WHERE row = 2
	) seconds
		ON g.FirstNameID = seconds.FirstNameID
	INNER JOIN (
		SELECT * FROM #first_names WHERE row = 1
	) firsts
		ON seconds.Name = firsts.Name
GO

SELECT c.*
--INTO livechat.dbo.__tblContacts_backup_201110
FROM livechat.dbo.tblContacts c WITH (NOLOCK)
	INNER JOIN (
		SELECT * FROM #first_names WHERE row = 2
	) seconds
		ON c.GirlFirstNameID = seconds.FirstNameID
	INNER JOIN (
		SELECT * FROM #first_names WHERE row = 1
	) firsts
		ON seconds.Name = firsts.Name
GO

SELECT *
INTO __tblGirlFirstNames_backup1_201110
FROM tblGirlFirstNames
WHERE FirstNameID IN (
	SELECT FirstNameID FROM #first_names WHERE row = 1
) AND Active = 0
GO

SELECT *
INTO __tblGirlFirstNameValues_backup_201110
FROM tblGirlFirstNameValues
WHERE FirstNameID IN (
	SELECT FirstNameID FROM #first_names WHERE row = 2
)
GO

SELECT *
INTO __tblGirlFirstNames_backup2_201110
FROM tblGirlFirstNames
WHERE FirstNameID IN (
	SELECT FirstNameID FROM #first_names WHERE row = 2
)
GO

DISABLE TRIGGER [dbo].[tblGirls_UpdateFirstNameID] ON [dbo].[tblGirls] 
GO

UPDATE g
SET g.FirstnameID = firsts.FirstNameID
FROM tblGirls g
	INNER JOIN (
		SELECT * FROM #first_names WHERE row = 2
	) seconds
		ON g.FirstNameID = seconds.FirstNameID
	INNER JOIN (
		SELECT * FROM #first_names WHERE row = 1
	) firsts
		ON seconds.Name = firsts.Name
GO

ENABLE TRIGGER [dbo].[tblGirls_UpdateFirstNameID] ON [dbo].[tblGirls]
GO

UPDATE c
SET c.GirlFirstNameID = firsts.FirstNameID
FROM livechat.dbo.tblContacts c
	INNER JOIN (
		SELECT * FROM #first_names WHERE row = 2
	) seconds
		ON c.GirlFirstNameID = seconds.FirstNameID
	INNER JOIN (
		SELECT * FROM #first_names WHERE row = 1
	) firsts
		ON seconds.Name = firsts.Name
GO

UPDATE tblGirlFirstNames
SET Active = 1
WHERE FirstNameID IN (
	SELECT FirstNameID FROM #first_names WHERE row = 1
) AND Active = 0
GO

DELETE FROM tblGirlFirstNameValues
WHERE FirstNameID IN (
	SELECT FirstNameID FROM #first_names WHERE row = 2
)
GO

DELETE FROM tblGirlFirstNames
WHERE FirstNameID IN (
	SELECT FirstNameID FROM #first_names WHERE row = 2
)
GO

SELECT * into __FirstNames_Doubles FROM #first_names ORDER BY Name, Row

DROP TABLE #first_names
GO