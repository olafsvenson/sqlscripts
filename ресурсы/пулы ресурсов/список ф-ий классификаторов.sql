/*
	http://www.rsdn.ru/article/db/ResourceGovernor.xml
		
	������ �-�� ���������������
*/

select
  object_name(classifier_function_id) as classifier_function
  , is_enabled -- ���� RG ��������, ����� ������ ���� 0
from sys.resource_governor_configuration
