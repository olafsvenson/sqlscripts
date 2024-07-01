
-- To enable fulltext search on a database on SQL server 2000 execute the following SP in query analyser.

exec sp_fulltext_database 'enable'

Other useful SPs that can be helpful in fulltext search

/*This will return the version on MSSQLServer:*/

SELECT SERVERPROPERTY('productversion')

 

/*This will return the service pack information of MSSQLServer:*/

SELECT SERVERPROPERTY('productlevel')

 

/*This will Full Text Search component is installed or not:*/

SELECT SERVERPROPERTY('IsFullTextInstalled')

 

/*This will show - is current database is full-text indexed:*/

select DatabaseProperty(db_name(), 'IsFulltextEnabled')

 

/*This will enable full-text indexing for the current database:*/

exec sp_fulltext_database 'enable'

 

/*This creates a catalog:*/

exec sp_fulltext_catalog 'catalogname', 'create'

 

/*This enables indexing of a table:*/

exec sp_fulltext_table 'tablename', 'create','catalogname', 'indexname'

 

/*This adds a column to an index:*/

exec sp_fulltext_column 'tablename', 'columnname', 'add'

 

/*This activates fulltext on a table:*/

exec sp_fulltext_table 'tablename', 'activate'

 

/*These two enable automatic filling of the full-text index when changes occur to a table:*/

exec sp_fulltext_table 'tablename','start_change_tracking'

exec sp_fulltext_table 'tablename','start_background_updateindex'


