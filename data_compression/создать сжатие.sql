ALTER TABLE [_InfoRg50163] REBUILD WITH (DATA_COMPRESSION = PAGE );

ALTER INDEX [NoNCompressed Table3_Cl_Idx] on [NoNCompressed Table3]
REBUILD WITH (DATA_COMPRESSION = PAGE );


CREATE NONCLUSTERED INDEX IX_SalesPerson_SalesQuota_SalesYTD
    ON Sales.SalesPerson (SalesQuota, SalesYTD);