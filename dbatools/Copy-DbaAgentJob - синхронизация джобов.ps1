#Тестовые сервера
# 'sql-u-01','sql-pp-01','sql-i-01','sql-d-01','sfn-etl-u-01','dwh-u-01','sfn-dmart-u-01','sfn-dmart-u-02','lk-dmart-u-01:54831','lk-dmart-u-02:54831','1c-d-sql','1c-u-sql'

$Servers = 'sql-pp-01','sql-i-01','sql-d-01','sfn-etl-u-01','dwh-u-01','sfn-dmart-u-01','sfn-dmart-u-02','lk-dmart-u-01:54831','lk-dmart-u-02:54831','1c-u-sql'
Copy-DbaAgentJob -Source sql-u-01 -Destination $Servers -Job "History.WhoIsActive" -Force