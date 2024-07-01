SELECT  s.name ,
        SUSER_SNAME(s.owner_sid) AS owner,
		'exec msdb..sp_update_job @job_name = '''+ s.name +''', @owner_login_name = ''sa''' as [ChangeOwner]
FROM    msdb..sysjobs s 
where 1=1
	--and SUSER_SNAME(s.owner_sid) <> N'sa'
	ORDER BY name

/*
exec msdb..sp_update_job @job_name = '02bdcb42-c732-48a4-8500-f0c763179e22', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = '0789de61-de68-4ebe-8e15-8e900cde3794', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = '082763f5-f802-42e2-ad5f-31d16de87c49', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = '0c217631-74ae-466f-9dff-a19b862c5be9', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = '0fc5f3c5-fbce-4af1-a457-536b2a780c2a', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = '1a425213-a021-49fd-ab78-42ea108ee0fa', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = '28016812-a613-49b8-9fac-53a6209012ba', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = '31fee80c-9962-4b7c-9f0e-1a1080d9c2bf', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = '32ca303f-655c-4e88-aa0b-06ffb2317422', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = '3303cfb0-6094-49f0-8601-f2ecdb9b2c67', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = '3a06905c-344e-4213-b317-08f56c78b9c3', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = '3b0bfeb1-8346-40b7-bcca-cb73ea98ed95', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = '4288add4-fcbd-4f90-8481-c1fd332eb5b9', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = '46428b2b-4388-451a-a4d7-77e6080a2320', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = '5037f09f-ccf1-40b9-9dbf-1c10b4f33af6', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = '508814d0-b94c-4450-ba1e-5a01ccfb48db', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = '5c1f2983-bbba-4c60-abbf-78d7b5f3619d', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = '60c6e7ab-a610-4822-b843-96c32ad96ecc', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = '676fd962-9b28-436a-a44a-f809e5e88715', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = '6911a430-6718-41d9-bd95-d697a08e5a27', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = '6b3e5d64-b415-4ee5-b8e9-25c81e02c733', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = '730433ac-9a82-4675-9b7a-9587f3817e5f', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = '92a4ec83-5f43-4026-a802-05f6c112738d', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = 'a70c0ffb-4312-41b5-80ff-80349b82a572', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = 'a76e82dc-0665-4a64-b834-25321d5ffb3e', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = 'afd6ed91-451b-41b3-8426-d8c364d4f8ea', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = 'b1717721-b754-40bd-8da0-0282d9c9f3e7', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = 'bb7a8c09-eb6e-4fca-983b-60e8a9ee5232', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = 'c51046f2-33d6-43f3-b6a9-26b8b850508f', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = 'd27877a5-4c9d-4f43-b97f-4a5a41f86721', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = 'ed3fa66d-0794-420f-b0e1-798b1f238f94', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = 'f5c286b6-5d82-40c0-9417-1d11ce1599e4', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = 'f5fd4014-b4eb-4b9d-ae75-c9f5298ee132', @owner_login_name = 'sa'
exec msdb..sp_update_job @job_name = 'f745475b-ceb1-4bd2-a776-b733812d77af', @owner_login_name = 'sa'
*/