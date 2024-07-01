SET NOCOUNT ON; 

DECLARE @Temp TABLE (Drive VARCHAR(5), MB_Free DECIMAL(12, 3)); 

INSERT INTO @Temp 
EXEC xp_fixeddrives; 

SELECT Drive,CAST(MB_Free / 1024 AS int) AS GB_Free 
FROM @Temp