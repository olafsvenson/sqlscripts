DECLARE @full_path VARCHAR(1000)
SET @full_path = '\\SERVER\D$\EXPORTFILES\EXPORT001.csv'

SELECT LEFT(@full_path,LEN(@full_path) - charindex('\',reverse(@full_path),1) + 1) [path], 
       RIGHT(@full_path, CHARINDEX('\', REVERSE(@full_path)) -1)  [file_name]