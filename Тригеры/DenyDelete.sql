CREATE TRIGGER DenyDelete ON dbo.tblCityNames INSTEAD OF DELETE AS
RAISERROR(N'”даление записей из таблицы tblCityNames временно запрещено by v.zheltonogov !',16,0);