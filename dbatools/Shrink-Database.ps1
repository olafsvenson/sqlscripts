$Instances = 'sql-01.sfn.local','sql-p-02.sfn.local\pythia','lk-dmart-p-01.sfn.local:54831','lk-dmart-p-02.sfn.local:54831','sfn-dmart-p-01.sfn.local','sfn-dmart-p-02.sfn.local','sfn-etl-p-01.sfn.local','1c-sql.sfn.local','1c-sql-02.sfn.local'
Import-Module dbatools;
Invoke-DbaDbShrink -SqlInstance $Instances -Database msdb