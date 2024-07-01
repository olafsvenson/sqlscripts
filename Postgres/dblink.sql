CREATE EXTENSION IF NOT EXISTS dblink;
select * from dblink('dbname=postgres user=postgres password = ***','select count(*) from cdi.physical_party') as q (id integer);