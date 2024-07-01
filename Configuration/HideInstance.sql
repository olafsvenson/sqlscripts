EXEC master..xp_instance_regwrite
      @rootkey = N'HKEY_LOCAL_MACHINE',
      @key =N'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQLServer\SuperSocketNetLib',
	  @value_name = N'HideInstance',
	  @type = N'REG_DWORD',
      @value = 1

      --0 = No, 1 = Yes

--To check if an instance is hidden you can use xp_instance_regread to check registry values:

DECLARE @getValue INT
EXEC master..xp_instance_regread
      @rootkey = N'HKEY_LOCAL_MACHINE',
      @key=N'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQLServer\SuperSocketNetLib',
	  @value_name = N'HideInstance',
	  @value = @getValue OUTPUT

SELECT @getValue