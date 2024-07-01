DECLARE @indid int;
SET @indid = (SELECT index_id 
              FROM sys.indexes
              WHERE object_id = OBJECT_ID('tblLetters')
                    AND name = 'IX_tblLetters_ToID_TypeID_FolderID_StatusID_DateOfCanceled_AnswerNotRequired_DateOfAdded_DateOfDelivered');
DBCC CHECKTABLE ('tblLetters', @indid) WITH all_errormsgs







 SELECT COUNT(*) FROM tblLetters  with (nolock) 
SELECT index_id 
              FROM sys.indexes WHERE name = 'IX_tblLetters_FromID_TypeID'