use master;

begin tran;



CREATE RESOURCE POOL poolAdhoc WITH
( MIN_CPU_PERCENT = 10, MAX_CPU_PERCENT = 30, MIN_MEMORY_PERCENT = 15, MAX_MEMORY_PERCENT = 25);

CREATE RESOURCE POOL poolReports WITH
( MIN_CPU_PERCENT = 10, MAX_CPU_PERCENT = 30, MIN_MEMORY_PERCENT = 15, MAX_MEMORY_PERCENT = 25);

CREATE RESOURCE POOL poolAdmin WITH
( MIN_CPU_PERCENT = 10, MAX_CPU_PERCENT = 30, MIN_MEMORY_PERCENT = 15, MAX_MEMORY_PERCENT = 25);
   

-- 3 группы рабочих нагрузок

CREATE WORKLOAD GROUP groupAdhoc USING poolAdhoc;
CREATE WORKLOAD GROUP groupReports USING poolReports;
CREATE WORKLOAD GROUP groupAdmin USING poolAdmin;


-- пользовательская ф-ия  классификации
GO

CREATE FUNCTION classifier_func() RETURNS SYSNAME
WITH SCHEMABINDING
AS
BEGIN
     DECLARE @grp_name AS SYSNAME
      
        IF (SUSER_NAME() = 'sa')   
            SET @grp_name = 'groupAdmin'
            
        IF (APP_NAME() LIKE '%MANAGMENT STUDIO%')
			SET @grp_name = 'groupAdhoc'
			
		IF (APP_NAME() LIKE '%REPORT SERVER%')
		    SET @grp_name = 'groupReports'
      
   RETURN @grp_name
END;  

GO

-- Регистрируем ф-ию
ALTER RESOURCE GOVERNOR  WITH ( CLASSIFIER_FUNCTION = dbo.classifier_func);

COMMIT TRAN;

ALTER RESOURCE GOVERNOR RECONFIGURE;

