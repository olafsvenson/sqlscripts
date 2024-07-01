declare
		@date_begin datetime = '2017-09-01',
		@date_end datetime = '2017-09-20',
		@user_id int = 54

if object_id('tempdb..#closed_tickets') is not null 
	drop table #closed_tickets

select 
	ticket_id as id,
    max(id) as last_state_rec_id -- ID последней записи о закрытии
into #closed_tickets
from dm_staging.[otrs].[TR_TICKET_HISTORY]
where 
	history_type_id = 27     -- тикет закрыли
	and create_by = @user_id  -- сделал это указанный пользователь
	and owner_id = @user_id   -- ???
	and state_id not in (12,4)       -- кроме статуса "Уточнение информации", "В работе"
	and change_time BETWEEN @date_begin and @date_end -- в заданный промежуток времени
group by ticket_id
order by id desc

--select * from #closed_tickets

ALTER TABLE #closed_tickets
  ADD CONSTRAINT closed_tickets_pk
    PRIMARY KEY (id);

select 
    t.id,
	t.tn as TicketID,
	t.title,
    t.customer_id,
    t.create_time,
    h.change_time as close_time,
		datediff(hh,t.create_time, h.change_time) duration,
    ct.last_state_rec_id,
    ts.name as closed_status,
    ts.comments as closed_status_name
from dm_staging.otrs.tr_ticket t
	inner join #closed_tickets ct
				on t.id = ct.id
  inner join dm_staging.otrs.tr_ticket_history h
		 		on ct.last_state_rec_id = h.id
  inner join dm_staging.otrs.tr_ticket_state ts
        on ts.id = h.state_id
order by 
				h.change_time;