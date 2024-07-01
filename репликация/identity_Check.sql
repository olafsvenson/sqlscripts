
-- смотрим на каких таблицах проблемы с indentity
SELECT name, range_begin, range_end, max_used
FROM MSmerge_identity_range mir
    INNER JOIN sysmergearticles sma ON mir.artid = sma.artid
WHERE is_pub_range = 1 AND range_end <= max_used + pub_range


-- можно так смотреть
DBCC CHECKIDENT ("tblMessages", NORESEED);


select MAX(messageid) from tblMessages


-- исправляем их
DBCC CHECKIDENT ("tblMessages", RESEED, 809057137);
