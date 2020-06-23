--Find out dependent SP on a table and build recompile statements
select distinct 'EXEC sp_recompile ''' + sp.Name+''''
  from sys.objects o inner join sys.sql_expression_dependencies  sd on o.object_id = sd.referenced_id
                inner join sys.objects sp on sd.referencing_id = sp.object_id
                    and sp.type in ('P')
  where o.name  in (  
'tbl_ticket_commission_details','tbl_ticket_primary_info','tbl_routesviacities','tbl_routecities_schedule','tbl_operator_cancellation'
,'tbl_route_master','tbl_ticket_details','tbl_bus_layout_details','tbl_ticket_cancelled_details')
