/*
1 - ������� ���� �����������
2 - ������� ��� ���������� 
*/
-- ������� ����������� �� �� ����������
exec sp_replicationdboption
          @dbname = 'svadba_catalog'
        , @optname = N'publish'
        , @value = N'false';



exec sp_removedbreplication 'svadba_catalog'

