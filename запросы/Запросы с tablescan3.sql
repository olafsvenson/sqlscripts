WITH XMLNAMESPACES(DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan'),
     CachedPlans(ParentOperationID, 
                 OperationID, 
                 PhysicalOperator, 
                 LogicalOperator, 
                 EstimatedCost, 
                 EstimatedIO, 
                 EstimatedCPU, 
                 EstimatedRows, 
                 PlanHandle, 
                 QueryText, 
                 QueryPlan, 
                 CacheObjectType, 
                 ObjectType)
     AS (SELECT RelOp.op.value(N'../../@NodeId', N'int') AS ParentOperationID, 
                RelOp.op.value(N'@NodeId', N'int') AS OperationID, 
                RelOp.op.value(N'@PhysicalOp', N'varchar(50)') AS PhysicalOperator, 
                RelOp.op.value(N'@LogicalOp', N'varchar(50)') AS LogicalOperator, 
                RelOp.op.value(N'@EstimatedTotalSubtreeCost ', N'float') AS EstimatedCost, 
                RelOp.op.value(N'@EstimateIO', N'float') AS EstimatedIO, 
                RelOp.op.value(N'@EstimateCPU', N'float') AS EstimatedCPU, 
                RelOp.op.value(N'@EstimateRows', N'float') AS EstimatedRows, 
                cp.plan_handle AS PlanHandle, 
                st.TEXT AS QueryText, 
                qp.query_plan AS QueryPlan, 
                cp.cacheobjtype AS CacheObjectType, 
                cp.objtype AS ObjectType
         FROM sys.dm_exec_cached_plans cp
              CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
              CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
              CROSS APPLY qp.query_plan.nodes(N'//RelOp') RelOp(op))
     SELECT top 20 --count(1)
			PlanHandle, 
            ParentOperationID, 
            OperationID, 
            PhysicalOperator, 
            LogicalOperator, 
            QueryText, 
            CacheObjectType, 
            ObjectType, 
            EstimatedCost, 
            EstimatedIO, 
            EstimatedCPU, 
            EstimatedRows
     FROM CachedPlans
     WHERE 
		 CacheObjectType = N'Compiled Plan'
        
		AND (PhysicalOperator = 'Clustered Index Scan'
                OR PhysicalOperator = 'Table Scan'
                OR PhysicalOperator = 'Index Scan')
		
		/*
		AND (PhysicalOperator = 'Clustered Index Seek'
                OR PhysicalOperator = 'Table Seek'
                OR PhysicalOperator = 'Index Seek');
				*/
order by [EstimatedRows] desc

-- IndexScan 43741
-- IndexSeek 107577
