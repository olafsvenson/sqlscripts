CREATE TRIGGER DenyDelete ON dbo.tblCityNames INSTEAD OF DELETE AS
RAISERROR(N'�������� ������� �� ������� tblCityNames �������� ��������� by v.zheltonogov !',16,0);