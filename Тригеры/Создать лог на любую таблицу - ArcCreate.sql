--BehavioralTargeting.ActivityTypes

USE [pegasus2008ms]

-- Создать лог на любую таблицу - ArcCreate  
-- !!!!!
-- !!!!! Не сохраняются поля типа TEXT,NTEXT - так как в триггере в спец. таблицах  deleted и inserted они не могут участвовать
-- !!!!!
DECLARE @tableName			nvarchar(100),			-- имя таблицы
		@includeFields		nvarchar(max) = null,	-- поля которые надо включить (разделять запятыми)
		@excludeFields		nvarchar(max) = null,	-- поля которые надо исключить (разделять запятыми)
		@simulate			BIT,						-- если 1, то только распечатать команды DDL, иначе выполнить их
		@update				BIT,					-- если 1, то существующие объекты будут обновлены
		@Initialize		    BIT						-- если 1, то заполняем лог текущими значениями  

Set @tableName='_Document556'	-- имя таблицы
Set @includeFields=''		-- поля, которые надо включить (разделять запятыми)
Set @excludeFields=''		-- поля, которые надо исключить (разделять запятыми)
Set @simulate=1				-- если 1, то только распечатать команды DDL, иначе выполнить их
Set @update= 0				-- если 1, то существующие объекты будут обновлены
SET @Initialize=0			-- если 1, то при создании заполняем лог текущими значениями  


IF NOT EXISTS (SELECT * FROM sysobjects WHERE id=object_id(@tableName) AND TYPE='U') BEGIN
	PRINT 'Table doesn''t exists in this database.'
	return
END                                                                               	

	/*
		СОЗДАЕТ ДЛЯ ТАБЛИЦЫ ЛОГ
	*/
	set nocount on
	set ansi_defaults on
	declare @tableId int
			,@i int
			,@colName nvarchar(50)
			,@arcTable nvarchar(50)
			,@triIns nvarchar(50)
			,@triDel nvarchar(50)
			,@triUpd nvarchar(50)
			,@sql nvarchar(max)
			,@colDef nvarchar(max)
			,@colList nvarchar(max)
	declare @inc table ( [name] varchar(50) COLLATE SQL_Latin1_General_CP1251_CI_AS primary key )
	declare @exc table ( [name] varchar(50) COLLATE SQL_Latin1_General_CP1251_CI_AS primary key )
	declare @dif table (
			[name] varchar(50) COLLATE SQL_Latin1_General_CP1251_CI_AS primary key,
			[type] varchar(50) COLLATE SQL_Latin1_General_CP1251_CI_AS, 
			[collation] varchar(50) COLLATE SQL_Latin1_General_CP1251_CI_AS, 
			[variable] bit,
			[xprec] int,
			[xscale] int,
			[length]	int,
			[operation] tinyint
		 )
	declare
			@name nvarchar(50) ,
			@type nvarchar(50) , 
			@collation nvarchar(50) , 
			@variable bit,
			@xprec int,
			@xscale int,
			@length	int,
			@operation tinyint
	select	@tableId = Id 
			, @arcTable = 'Arc'+[name]
			, @triIns = [name]+'_InsertArc' 
			, @triUpd = [name]+'_UpdateArc' 
			, @triDel = [name]+'_DeleteArc' 
		from sysobjects
		where id=object_id(@tableName) and type='U'
	-- убеждаемся что есть такая пользовательская таблица
	if @tableId is null
	begin
		--raiserror('Table %s not found in SYSTABLES!',16,1,@tableName)
		--goto fail
		goto success
	end
	if @update=0 and @simulate=0
	begin
		-- проверяем что нет в системе объектов, которые мы будем создавать
		if object_id(@arcTable) is not null
		begin
			raiserror('Object %s already exists!',16,1,@arcTable)
			goto fail
		end
		if object_id(@triIns) is not null
		begin
			raiserror('Object %s already exists!',16,1,@triIns)
			goto fail
		end
		if object_id(@triUpd) is not null
		begin
			raiserror('Object %s already exists!',16,1,@triUpd)
			goto fail
		end
		if object_id(@triDel) is not null
		begin
			raiserror('Object %s already exists!',16,1,@triDel)
			goto fail
		end
	end
	else
	begin
		if object_id(@triIns) is not null
		begin
			set @sql = 'DROP TRIGGER '+@triIns
			if @simulate<>0 print @sql
			else exec(@sql)
			if @@error<>0 goto fail
			if @simulate<>0 print 'GO'	
		end
		if object_id(@triUpd) is not null
		begin
			set @sql = 'DROP TRIGGER '+@triUpd
			if @simulate<>0 print @sql
			else exec(@sql)
			if @@error<>0 goto fail
			if @simulate<>0 print 'GO'	
		end
		if object_id(@triDel) is not null
		begin
			set @sql = 'DROP TRIGGER '+@triDel
			if @simulate<>0 print @sql
			else exec(@sql)
			if @@error<>0 goto fail
			if @simulate<>0 print 'GO'	
		end
	end
	-- обрабатываем столбцы которые надо включить или исключить
	if @includeFields is not null
		if @includeFields<>'*' and @includeFields<>''
		begin
			set @colName = ''
			set @i = 1
			while @i<=len(@includeFields)
			begin
				if substring(@includeFields, @i, 1)=','
				begin
					if len(@colName)>0
						insert into @inc([name]) values(rtrim(ltrim(upper(@colName))))
					set @colName = ''
				end
				else
					set @colName = @colName + substring(@includeFields, @i, 1)
				set @i = @i + 1
			end
			if len(@colName)>0
				insert into @inc([name]) values(rtrim(ltrim(upper(@colName))))
		end
	if @excludeFields is not null
		if @excludeFields<>'*' and @excludeFields<>''
		begin
			set @colName = ''
			set @i = 1
			while @i<=len(@excludeFields)
			begin
				if substring(@excludeFields, @i, 1)=','
				begin
					if len(@colName)>0
						insert into @exc([name]) values(rtrim(ltrim(upper(@colName))))
					set @colName = ''
				end
				else
					set @colName = @colName + substring(@excludeFields, @i, 1)
				set @i = @i + 1
			end
			if len(@colName)>0
				insert into @exc([name]) values(rtrim(ltrim(upper(@colName))))
		end
	-- формируем список столбцов	
	select  @colDef = 
			isnull(@colDef+','+char(13)+char(10), '') +'['+ c.name+'] '+t.name+
			case
				WHEN t.variable=1 AND c.length=-1  then '(max)' + isnull(' COLLATE '+c.collation,'')	-- например varchar(max)
				when t.variable=1 then '('+convert(nvarchar(10),c.length)+')' + isnull(' COLLATE '+c.collation,'')
				else
					case 
						when t.name='decimal' then '('+convert(nvarchar(10),c.xprec)+','+convert(nvarchar(10),c.xscale)+')'
						else ''
					end
			end 
			, @colList = isnull(@colList+','+char(13)+char(10),'')+'['+c.name+']'
	from syscolumns c
			join systypes t on t.xusertype=c.xusertype
		where c.Id=@tableId 
			and ( upper(c.name) COLLATE SQL_Latin1_General_CP1251_CI_AS in (select i.[name] from @inc i) or not exists(select * from @inc))
			and ( upper(c.name) COLLATE SQL_Latin1_General_CP1251_CI_AS not in (select e.[name] from @exc e) or not exists(select * from @exc))
			AND t.Name NOT IN ('TEXT','NTEXT')		-- !!!!! Не сохраняются поля типа TEXT,NTEXT - так как в триггере в спец. таблицах  deleted и inserted они не могут участвовать

			
	if @update=1 and object_id(@arcTable) is not null
	begin
		-- если таблица существует, то обновляем ее поля
		insert into @dif(name,type,variable,collation,xprec,xscale,length,operation)
			select 
				c.name, t.name, t.variable
				,case t.variable
					when 1 then c.collation
					else null
				end 
				,case  when t.name='decimal' then c.xprec else null end
				,case  when t.name='decimal' then c.xscale else null end
				,c.length
				,0
			from syscolumns c
					join systypes t on t.xusertype=c.xusertype
				where c.Id=@tableId 
					and ( upper(c.name) COLLATE SQL_Latin1_General_CP1251_CI_AS in (select i.[name] from @inc i) or not exists(select * from @inc))
					and ( upper(c.name) COLLATE SQL_Latin1_General_CP1251_CI_AS not in (select e.[name] from @exc e) or not exists(select * from @exc))
			update @dif
			set operation = 
				case
					when x.name is null then 2	-- insert column
					when (x.type COLLATE SQL_Latin1_General_CP1251_CI_AS )<>(d.type  COLLATE SQL_Latin1_General_CP1251_CI_AS )
						or isnull(x.length,0)<>isnull(d.length,0)
						or isnull(x.xprec,0)<>isnull(d.xprec,0)
						or isnull(x.xscale,0)<>isnull(d.xscale,0)
						or (isnull(x.collation,'') COLLATE SQL_Latin1_General_CP1251_CI_AS )<>(isnull(d.collation,'') COLLATE SQL_Latin1_General_CP1251_CI_AS ) then 3	-- update column
					else 0
				end
			from @dif d
				left join 
					(
						select 
							c.name, t.name as [type], t.variable
							,case t.variable
								when 1 then c.collation
								else null
							end as [collation]
							,case  when t.name='decimal' then c.xprec else null end as [xprec]
							,case  when t.name='decimal' then c.xscale else null end as [xscale]
							,c.length
						from syscolumns c
								join systypes t on t.xusertype=c.xusertype
							where c.Id=object_id(@arcTable)
								and c.name not in ('arcDT','arcHost','arcKod','arcUser','arcLogin','arcOperation','arcColumnsUpdated')
					) x on (d.name COLLATE SQL_Latin1_General_CP1251_CI_AS )=(x.name COLLATE SQL_Latin1_General_CP1251_CI_AS )
			insert into @dif(name,type,variable,collation,xprec,xscale,length,operation)
				select 
					(c.name COLLATE SQL_Latin1_General_CP1251_CI_AS ), (t.name COLLATE SQL_Latin1_General_CP1251_CI_AS ) as [type], t.variable
					,case t.variable
						when 1 then c.collation
						else null
					end as [collation]
					,case  when t.name='decimal' then c.xprec else null end as [xprec]
					,case  when t.name='decimal' then c.xscale else null end as [xscale]
					,c.length
					,1	-- delete column
				from syscolumns c
						join systypes t on t.xusertype=c.xusertype
					where c.Id=object_id(@arcTable) and (c.name COLLATE SQL_Latin1_General_CP1251_CI_AS ) not in (select d.[name] from @dif d)
						and c.name not in ('arcDT','arcHost','arcKod','arcUser','arcLogin','arcOperation','arcColumnsUpdated')
			declare crDif cursor fast_forward for
				select name,type,collation,variable,xprec,xscale,length,operation
				from @dif 
				where operation<>0
				order by operation asc
			open crDif
			while 1=1
			begin
				fetch next from crDif into @name,@type,@collation,@variable,@xprec,@xscale,@length,@operation
				if @@fetch_status<>0 break
				set @sql =	'ALTER TABLE '+ @arcTable+' '+
							case @operation
								when 1 then
									' DROP COLUMN ['+@name+']'
								when 2 then
									' ADD ['+@name+'] '+@type+
										case @variable
											when 1 then '('+convert(nvarchar(10),@length)+')'+isnull(' COLLATE '+@collation,'')
											else isnull('('+convert(nvarchar(10),@xprec)+','+convert(nvarchar(10),@xscale)+')','')
										end
								when 3 then
									' ALTER COLUMN  ['+@name+'] '+@type+
										case @variable
											when 1 then '('+convert(nvarchar(10),@length)+')'+isnull(' COLLATE '+@collation,'')
											else isnull('('+convert(nvarchar(10),@xprec)+','+convert(nvarchar(10),@xscale)+')','')
										end
							end
				if @simulate<>0 print @sql
				else exec(@sql)
				if @@error<>0 goto fail
				if @simulate<>0 print 'GO'
			end
			close crDif
			deallocate crDif
	end
	else
	begin
		-- если такой талицы нет, то создаем ее
		set @sql = 'use ['+DB_NAME()+']'+CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10)+
				'CREATE TABLE '+@arcTable+ '( '+CHAR(13)+CHAR(10)
				+'[arcKod] int identity(1,1) primary key, '+CHAR(13)+CHAR(10)
				+'[arcHost] nvarchar(50), '+CHAR(13)+CHAR(10)
				+'[arcUser] nvarchar(50), '+CHAR(13)+CHAR(10)
				+'[arcLogin] nvarchar(50), '+CHAR(13)+CHAR(10)
				+'[arcDT] datetime, '+CHAR(13)+CHAR(10)
				+'[arcOperation] nvarchar(50), '+CHAR(13)+CHAR(10)
				+'[arcColumnsUpdated] varbinary(64), '+CHAR(13)+CHAR(10)
				+@colDef+CHAR(13)+CHAR(10)+')'+CHAR(13)+CHAR(10)
		-- создаем таблицу для архива	
		if @simulate<>0 print @sql
		else exec(@sql)
		if @@error<>0 goto fail
		if @simulate<>0 print 'GO'
	END

	if @Initialize=1 begin
		-- формируем инициализацию таблички текущими значениями
		set @sql =char(13)+char(10)+' INSERT INTO '+@arcTable+'([arcHost], [arcUser],[arcLogin],[arcDT],[arcOperation],[arcColumnsUpdated],'+CHAR(13)+CHAR(10)+@colList+') '
					+char(13)+char(10)
					+' SELECT HOST_NAME(),User,SYSTEM_USER,getUTCdate(),''init'',COLUMNS_UPDATED(),'
					+@colList+char(13)+char(10) +' FROM '+@tableName+' with(nolock)'+CHAR(13)+CHAR(10)
					+'GO'+CHAR(13)+CHAR(10)
		-- создаем тригер On Insert
		if @simulate<>0 print @sql
		else exec(@sql)
	end		

	-- формируем DDL описание тригера On Insert
	set @sql =char(13)+char(10)+' CREATE TRIGGER '+@triIns+' ON '+@tableName
				+char(13)+char(10)
				+' FOR INSERT AS '
				+char(13)+char(10)
				+' INSERT INTO '+@arcTable+'([arcHost], [arcUser],[arcLogin],[arcDT],[arcOperation],[arcColumnsUpdated],'+CHAR(13)+CHAR(10)+@colList+') '
				+char(13)+char(10)
				+' SELECT HOST_NAME(),User,SYSTEM_USER,getUTCdate(),''ins'',COLUMNS_UPDATED(),'
				+@colList+char(13)+char(10) +' FROM inserted'
	-- создаем тригер On Insert
	if @simulate<>0 print @sql
	else exec(@sql)
	if @@error<>0 goto fail
	if @simulate<>0 print 'GO'
	-- формируем DDL описание тригера On Update
	set @sql =char(13)+char(10)+ ' CREATE TRIGGER '+@triUpd+' ON '+@tableName
				+char(13)+char(10)
				+' FOR UPDATE AS '
				+char(13)+char(10)
				+' INSERT INTO '+@arcTable+'([arcHost], [arcUser],[arcLogin],[arcDT],[arcOperation],[arcColumnsUpdated],'+CHAR(13)+CHAR(10)+@colList+') '
				+char(13)+char(10)
				+' SELECT HOST_NAME(),User,SYSTEM_USER,getUTCdate(),''upd'',COLUMNS_UPDATED(),'
				+@colList+char(13)+char(10) +' FROM inserted'
	-- создаем тригер On Insert
	if @simulate<>0 print @sql
	else exec(@sql)
	if @@error<>0 goto fail
	if @simulate<>0 print 'GO'
	-- формируем DDL описание тригера On Delete
	set @sql =char(13)+char(10)+ ' CREATE TRIGGER '+@triDel+' ON '+@tableName
				+char(13)+char(10)
				+' FOR DELETE AS '
				+char(13)+char(10)
				+' INSERT INTO '+@arcTable+'([arcHost], [arcUser],[arcLogin],[arcDT],[arcOperation],[arcColumnsUpdated],'+CHAR(13)+CHAR(10)+@colList+') '
				+char(13)+char(10)
				+' SELECT HOST_NAME(),User,SYSTEM_USER,getUTCdate(),''del'',COLUMNS_UPDATED(),'
				+@colList+char(13)+char(10) +' FROM deleted'
	-- создаем тригер On Insert
	if @simulate<>0 print @sql
	else exec(@sql)
	if @@error<>0 goto fail
	if @simulate<>0 print 'GO'
success:
	if @@trancount>0 commit
--	return 0
fail:	
	if @@trancount>0 rollback
--	return 1
