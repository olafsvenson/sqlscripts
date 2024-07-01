EXECUTE master.dbo.IndexOptimize
@Databases = 'sputnik',
@FragmentationLow = NULL,
@FragmentationMedium =  'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationLevel1 = 50,
@FragmentationLevel2 = 60,
@LogToTable = 'Y',
@SortInTempdb='Y',
@UpdateStatistics='ALL',
@WaitAtLowPriorityMaxDuration=15,
@WaitAtLowPriorityAbortAfterWait='SELF',
@Indexes = 'sputnik.awr.blk_handle_collect.NCIX_tt_sqlhandle'