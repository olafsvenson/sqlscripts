
  
  SELECT * FROM sysarticles AS t  WHERE name LIKE 'tblCountries' 
  
  SELECT *  FROM [distribution].[dbo].[MSarticles]  with (nolock) 
  WHERE article LIKE 'tblCountries'
  
  SELECT * FROM dbo.syspublications AS s WHERE id=19