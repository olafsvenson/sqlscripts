/*
sfn\dknyazev
sfn\dokolyshev
*/
execute as login = 'SFN\elikholat.adm';

select *
from sys.login_token
where principal_id > 0;

revert;




