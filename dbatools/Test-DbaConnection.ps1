# https://sqldbawithabeard.com/2017/11/28/2-ways-to-loop-through-collections-in-pester/
$Instances = 'sql-01.sfn.local','sql-p-02.sfn.local\pythia','lk-dmart-p-01.sfn.local:54831','lk-dmart-p-02.sfn.local:54831','sfn-dmart-p-01.sfn.local','sfn-dmart-p-02.sfn.local','sfn-etl-p-01.sfn.local','1c-sql.sfn.local','1c-sql-02.sfn.local'

#,'sql-d-01','sql-i-01','1c-d-sql.sfn.local','1c-u-sql.sfn.local','lk-dmart-u-01:54831','lk-dmart-u-02:54831','sfn-dmart-u-01','sfn-dmart-u-02','sfn-etl-u-01','sql-u-01','dwh-u-01','dwh-p-01','dwh-p-02'

# Create an empty array
$TestCases = @()

# Fill the Testcases with the values and a Name of Instance
$Instances.ForEach{$TestCases += @{Instance = $_}}
Describe 'Testing connection to SQL Instances' {
    # Put the TestCases 'Name' in <> and add the TestCases parameter
    It "Connects successfully to <Instance>" -TestCases $TestCases {
        # Add a Parameter to the test with the same name as the TestCases Name
        Param($Instance)
        # Write the test using the TestCases Name
        (Test-DbaConnection -SqlInstance $Instance).ConnectSuccess | Should Be $True
    }
}