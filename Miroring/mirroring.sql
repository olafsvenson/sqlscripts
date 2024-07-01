/*
  Ќј—“–ќ… ј «≈– јЋ»–ќ¬јЌ»я
*/

   
-- (1) на главном сервере создаем endpoint
CREATE ENDPOINT MirrorEndpoint 
STATE = STARTED AS TCP(LISTENER_PORT = 35001)
FOR DATABASE_MIRRORING (ROLE=PARTNER)

-- (2) на главном сервере создаем учетную запись

CREATE LOGIN [RESCUE\vint] FROM WINDOWS;

GRANT CONNECT ON ENDPOINT::MirrorEndpoint TO [RESCUE\vint]

-- (3) на зеркальном сервере 

CREATE ENDPOINT MirrorEndpoint 
STATE = STARTED AS TCP(LISTENER_PORT = 35001)
FOR DATABASE_MIRRORING (ROLE=ALL)


CREATE LOGIN [RESCUE\vint] FROM WINDOWS;

GRANT CONNECT ON ENDPOINT::MirrorEndpoint TO [RESCUE\vint]

-- (4) на свидетеле

CREATE ENDPOINT MirrorEndpoint 
STATE = STARTED AS TCP(LISTENER_PORT = 35001)
FOR DATABASE_MIRRORING (ROLE=ALL)


CREATE LOGIN [RESCUE\vint] FROM WINDOWS;

GRANT CONNECT ON ENDPOINT::MirrorEndpoint TO [RESCUE\vint]

BACKUP DATABASE MyDB TO DISK = '\\PRINCIPAL\MIRRORBackup\MyDB.bak' WITH FORMAT

RESTORE DATABASE MyDB FROM DISK = '\\PRINCIPAL\MIRRORBackup\MyDB.bak' WITH REPLACE, NORECOVERY


BACKUP Log MyDB TO DISK = '\\PRINCIPAL\MIRRORBackup\MyDB_log.bak'

RESTORE Log MyDB FROM DISK = '\\PRINCIPAL\MIRRORBackup\MyDB_log.bak' WITH NORECOVERY

--  (5) на зеркале

ALTER DATABASE MyDb SET PARTNER = 'TCP://MyPrincipalServer.MyDomain:35001'

-- (6) на главном сервере

ALTER DATABASE MyDb SET PARTNER = 'TCP://MyPrincipalServer.MyDomain:35001'


/*

Adding a Witness Server to a Database Mirroring Session
1	-- Database Name: AdventureWorks
2	ALTER DATABASE AdventureWorks
3	  SET WITNESS = 'TCP://ServerWit:7022'

Removing the Witness Server from a Database Mirroring Session
1	-- DatabaseName: AdventureWorks
2	ALTER DATABASE AdventureWorks SET WITNESS OFF

Terminating Database Mirroring Session
1	-- Terminate Mirroring Session of AdventureWorks database
2	-- Command to be run on the Principal Server.
3	ALTER DATABASE AdventureWorks SET PARTNER OFF

To Pause a Database Mirroring Session
1	-- Suspending Mirroring Session on AdventureWorks database
2	-- Command to be run on the Principal Server.
3	ALTER DATABASE AdventureWorks SET PARTNER SUSPEND

Resuming Database Mirroring Session
1	-- Resuming Mirroring Session on AdventureWorks database
2	-- Command to be run on the Principal Server.
3	ALTER DATABASE AdventureWorks SET PARTNER RESUME

Changing Mirroring Session to Asynchronous Mode
1	-- Database Name: AdventureWorks
2	ALTER DATABASE AdventureWorks SET SAFETY OFF

Changing Mirroring Session to Synchronous
1	-- Database Name: AdventureWorks
2	ALTER DATABASE AdventureWorks SET SAFETY ON

Turning Transaction Safety ON
1	-- Database Name: AdventureWorks
2	ALTER DATABASE AdventureWorks SET PARTNER SAFETY FULL

Turning OFF Transaction Safety
1	-- Database Name: AdventureWorks
2	ALTER DATABASE AdventureWorks SET PARTNER SAFETY OFF

*/