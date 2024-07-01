EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', 
                     N'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL.1\MSSQLServer\SuperSocketNetLib\Np', 
                     N'Enabled', N'REG_DWORD', 0 ;
GO
--------------------------------------
[HKEY_LOCAL_MACHINE\ SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL.1\MSSQLServer\SuperSocketNetLib\Np]
"Enabled"=dword:00000000
"PipeName"="\\\\.\\pipe\\MSSQL$UNISON\\sql\\query"
"DisplayName"="Named Pipes"



EXEC master..xp_instance_regwrite
      @rootkey = N'HKEY_LOCAL_MACHINE',
      @key =N'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQLServer\SuperSocketNetLib\NP',
	  @value_name = N'Enabled',
	  @type = N'REG_DWORD',
      @value = 0

      --0 = No, 1 = Yes

--To check if an instance is hidden you can use xp_instance_regread to check registry values:

DECLARE @getValue INT
EXEC master..xp_instance_regread
      @rootkey = N'HKEY_LOCAL_MACHINE',
      @key=N'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQLServer\SuperSocketNetLib\NP',
	  @value_name = N'Enabled',
	  @value = @getValue OUTPUT

SELECT @getValue