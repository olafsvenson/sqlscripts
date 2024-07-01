SELECT @@servicename
       ,name
       ,recovery_model_desc
FROM sys.databases WHERE name <> 'model' AND recovery_model <> 3