/*
	http://www.rsdn.ru/article/db/ResourceGovernor.xml
		
	”бедитесь в том, что группы нагрузки €вл€ютс€ потребител€ми соответствующих пулов.
*/

select
  group_id
  , a.name
  , a.pool_id
  , b.name as pool_name
from sys.resource_governor_workload_groups a
inner join sys.resource_governor_resource_pools b on a.pool_id = b.pool_id
