USE [GreenButton]
GO
CREATE NONCLUSTERED INDEX [IX_custom_is_actual_Груз_inc_БазовыйТариф_Валюта_Период_Регистратор_тип_флаг_Сумма_СуммаРуб_Услуга_ДетализацияУслуги]
ON [stage].[РегистрНакопления.споПредоставленныеСкидки] ([is_actual],[Груз])
INCLUDE ([БазовыйТариф],[Валюта],[Период],[Регистратор_тип_флаг],[Сумма],[СуммаРуб],[Услуга],[ДетализацияУслуги])
WITH (Online = ON,RESUMABLE = ON, data_compression=page,maxdop=2);
GO

-- Просмотр
SELECT 
   name, 
   percent_complete,
   state_desc,
   last_pause_time,
   page_count
FROM sys.index_resumable_operations;

-- PAUSE
ALTER INDEX [IX_custom_Склад_is_actualДата_system_state_id_inc_] ON [GreenButton].[stage].[Документ.споПриемкаГруза]
PAUSE;
GO

-- RESUME
ALTER INDEX [IX_custom_Склад_is_actualДата_system_state_id_inc_] ON [GreenButton].[stage].[Документ.споПриемкаГруза]
RESUME;
GO

-- ABORT

ALTER INDEX [IX_custom_РейсНаправленияПогрузки_id]
ON [stage].[Документ.споРейс.НаправленияПогрузки]
ABORT
