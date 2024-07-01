SELECT 
	EC.CLIENT_NET_ADDRESS ,
	ES.[PROGRAM_NAME] ,
	ES.[HOST_NAME] ,
	ES.LOGIN_NAME ,
	COUNT(EC.SESSION_ID) AS [CONNECTION COUNT]
FROM SYS.DM_EXEC_SESSIONS AS ES
INNER JOIN SYS.DM_EXEC_CONNECTIONS AS EC
	ON ES.SESSION_ID = EC.SESSION_ID
GROUP BY EC.CLIENT_NET_ADDRESS ,
	ES.[PROGRAM_NAME] ,
	ES.[HOST_NAME] ,
	ES.LOGIN_NAME
ORDER BY 
	EC.CLIENT_NET_ADDRESS ,
	ES.[PROGRAM_NAME]