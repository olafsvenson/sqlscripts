/*
	задержки из-за сети
*/

    SELECT * from SYS.SYSPROCESSES
    WHERE lastwaittype = 'ASYNC_NETWORK_IO'


