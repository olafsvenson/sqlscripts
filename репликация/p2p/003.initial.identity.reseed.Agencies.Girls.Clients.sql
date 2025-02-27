USE [svadba_catalog]
GO

CREATE TABLE tmp_identity_info (
	table_name sysname NULL,
	table_identity INT NULL
)
GO

INSERT INTO tmp_identity_info (table_name) VALUES ('tblClients')
INSERT INTO tmp_identity_info (table_name) VALUES ('tblMen')
GO

DECLARE
	@sql NVARCHAR(MAX),
	@clients_identity_old INT, @clients_identity_new INT,
	@men_identity_old INT, @men_identity_new INT,
	@delta INT

-- tblClients
SELECT @clients_identity_old = IDENT_CURRENT('tblClients')

SELECT @delta = 100000 - CAST(RIGHT(CAST(@clients_identity_old AS nvarchar), 5) AS INT)

SET @clients_identity_new = @clients_identity_old + @delta

SET @sql = 'DBCC CHECKIDENT(tblClients, RESEED, ' + CAST(@clients_identity_new AS NVARCHAR) + ')'
EXEC(@sql)

UPDATE tmp_identity_info
SET table_identity = @clients_identity_new
WHERE table_name = 'tblClients'

-- tblMen
SELECT @men_identity_old = IDENT_CURRENT('tblMen')

SELECT @delta = 100000 - CAST(RIGHT(CAST(@men_identity_old AS nvarchar), 5) AS INT)

SET @men_identity_new = @men_identity_old + @delta

SET @sql = 'DBCC CHECKIDENT(tblMen, RESEED, ' + CAST(@men_identity_new AS NVARCHAR) + ')'
EXEC(@sql)

UPDATE tmp_identity_info
SET table_identity = @men_identity_new
WHERE table_name = 'tblMen'