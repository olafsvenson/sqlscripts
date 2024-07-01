-- Find the total size of each Filegroup
select data_space_id, (sum(size)*8)/1000 as total_size_MB
into #filegroups
from sys.database_files
group by data_space_id
order by data_space_id

-- FInd how much we have allocated in each FG
select ds.name, au.data_space_id
, (sum(au.total_pages) * 8)/1000 as Allocated_MB
, (sum(au.used_pages) * 8)/1000 as used_MB
, (sum(au.data_pages) * 8)/1000 as Data_MB
, ((sum(au.total_pages) - sum(au.used_pages) ) * 8 )/1000 as Free_MB
into #Allocations
from sys.allocation_units as au inner join sys.data_spaces as ds
on au.data_space_id = ds.data_space_id
group by ds.name, au.data_space_id
order by au.data_space_id

-- Bring it all together
select f.data_space_id
, a.name
, f.total_size_MB
, a.allocated_MB
, f.total_size_MB - a.allocated_MB as free_in_fg_MB
, a.used_MB
, a.data_MB
, a.Free_MB
from #filegroups as f inner join #allocations as a
on f.data_space_id = a.data_space_id
order by f.data_space_id

drop table #allocations
drop table #filegroups
