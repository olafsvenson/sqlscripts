EXEC sp_WhoIsActive 67
    @find_block_leaders = 1, 
    @sort_order = '[blocked_session_count] DESC'


exec beta_lockinfo