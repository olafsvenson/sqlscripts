set nocount on;
go

if object_id( N'dbo.test_table', N'U' ) is not null
drop table dbo.test_table;
go

create table dbo.test_table
      ( id     int 
      , dt     datetime default getdate()
      , uniqid uniqueidentifier default newid()
      , val    nvarchar(1024) default replicate( 'A', 1024 )
      );
go

with
  cte1 as ( select t1.* from ( values(1),(1) ) t1(i) )
, cte2 as ( select t2.* from cte1 t1 cross join cte1 t2 )
, cte3 as ( select t3.* from cte2 t2 cross join cte2 t3 )
, cte4 as ( select t4.* from cte3 t3 cross join cte3 t4 )
, cte5 as ( select t5.* from cte4 t4 cross join cte4 t5 )
insert into dbo.test_table ( id )
select row_number() over ( order by (select null) ) as id from cte5;
GO


