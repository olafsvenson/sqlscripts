/*
	http://www.rsdn.ru/article/db/ResourceGovernor.xml
		
	список ф-ий классификаторов
*/

select
  object_name(classifier_function_id) as classifier_function
  , is_enabled -- если RG выключен, здесь должен быть 0
from sys.resource_governor_configuration
