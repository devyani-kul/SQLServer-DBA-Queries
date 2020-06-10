--query to check progress of the task
SELECT session_id as SPID, command, a.text AS Query, start_time, percent_complete, dateadd(second,estimated_completion_time/1000, getdate()) as estimated_completion_time
FROM sys.dm_exec_requests r CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) a
WHERE r.command in ('BACKUP DATABASE','RESTORE LOG')


--Query to check database size over the period of month 

select database_name,DATEPART(month,[backup_start_date]),
DATEPART(year,[backup_start_date]),
CONVERT(DECIMAL(10,2),ROUND(AVG([backup_size]/1024/1024/1024),4)) backup_size_db,
CONVERT(DECIMAL(10,2),ROUND(AVG([compressed_backup_size]/1024/1024/1024),4)) compressed_backup_GB
from     msdb.dbo.backupset
WHERE 
     [type] = 'D' 
group by database_name,DATEPART(year,[backup_start_date]),DATEPART(month,[backup_start_date])
Order by database_name,backup_start_date desc 



---Query for total database size 
use carderp

SELECT 
      database_name = DB_NAME(database_id)
    , log_size_mb = CAST(SUM(CASE WHEN type_desc = 'LOG' THEN size END) * 8. / 1024 AS DECIMAL(8,2))
    , row_size_mb = CAST(SUM(CASE WHEN type_desc = 'ROWS' THEN size END) * 8. / 1024 AS DECIMAL(8,2))
    , total_size_GB = CAST((SUM(size) * 8. / 1024 ) /1024  AS DECIMAL(8,2))
FROM sys.master_files WITH(NOWAIT)
WHERE database_id = DB_ID() -- for current db 
GROUP BY database_id


use CARDUSERSV2 

SELECT 
      database_name = DB_NAME(database_id)
    , log_size_mb = CAST(SUM(CASE WHEN type_desc = 'LOG' THEN size END) * 8. / 1024 AS DECIMAL(8,2))
    , row_size_mb = CAST(SUM(CASE WHEN type_desc = 'ROWS' THEN size END) * 8. / 1024 AS DECIMAL(8,2))
    , total_size_GB = CAST((SUM(size) * 8. / 1024 ) /1024  AS DECIMAL(8,2))
FROM sys.master_files WITH(NOWAIT)
WHERE database_id = DB_ID() -- for current db 
GROUP BY database_id

use skills_online_v1

SELECT 
      database_name = DB_NAME(database_id)
    , log_size_mb = CAST(SUM(CASE WHEN type_desc = 'LOG' THEN size END) * 8. / 1024 AS DECIMAL(8,2))
    , row_size_mb = CAST(SUM(CASE WHEN type_desc = 'ROWS' THEN size END) * 8. / 1024 AS DECIMAL(8,2))
    , total_size_GB = CAST((SUM(size) * 8. / 1024 ) /1024  AS DECIMAL(8,2))
FROM sys.master_files WITH(NOWAIT)
WHERE database_id = DB_ID() -- for current db 
GROUP BY database_id
--Check unused log space size 
SELECT (total_log_size_in_bytes - used_log_space_in_bytes)*1.0/1024/1024 AS [free log space in MB]  
FROM sys.dm_db_log_space_usage;

Select database_id,total_log_size_in_bytes/1024/1024/1024 total_log_size_gb,
used_log_space_in_bytes/1024/1024/1024 used_log_space_GB
 FROM sys.dm_db_log_space_usage
 
 
--Space Used query by each table

-- DROP TABLE #tmpTableSizes
CREATE TABLE #tmpTableSizes
(
    tableName varchar(100),
    numberofRows varchar(100),
    reservedSize varchar(50),
    dataSize varchar(50),
    indexSize varchar(50),
    unusedSize varchar(50)
)
insert #tmpTableSizes
EXEC sp_MSforeachtable @command1="EXEC sp_spaceused '?'"


select  * from #tmpTableSizes
order by cast(LEFT(reservedSize, LEN(reservedSize) - 4) as int)  desc
 
 
 
--DB Access queries
SELECT E.HREmployeeID,
       EL.UserName,
       E.FirstName,
       E.LastName,
       *
FROM tblHREmployees E
    JOIN dbo.tblHREmpLogin EL
        ON EL.HREmployeeID = E.HREmployeeID
WHERE (
          E.FirstName LIKE '%Rebecca%'
          AND E.LastName LIKE '%Namuddu%'
      );

 
 SELECT E.HREmployeeID,
       EL.UserName,
       E.FirstName,
       E.LastName,
       *
FROM tblHREmployees E
    JOIN dbo.tblHREmpLogin EL
        ON EL.HREmployeeID = E.HREmployeeID
WHERE (
          E.FirstName LIKE '%Ursula%'
          AND E.LastName LIKE '%Parker%'
      );


SELECT E.HREmployeeID,
       EL.UserName,
       E.FirstName,
       E.LastName,
       *
FROM tblHREmployees E
    JOIN dbo.tblHREmpLogin EL
        ON EL.HREmployeeID = E.HREmployeeID
WHERE (
          E.FirstName LIKE '%Stephanie%'
          AND E.LastName LIKE '%Roberts%'
      );
	  
	  
---Copy only back ups
BACKUP DATABASE CARDERP 
TO DISK = 'F:\Backup\CARDERP_CopyOnly_20200220.bak'
GO


BACKUP DATABASE [CardUsersV2] 
TO DISK = 'F:\BackupCardUsersV2_CopyOnly_20200130.bak'
WITH COPY_ONLY 
GO


BACKUP DATABASE [Skills_Online_V1] 
TO DISK = 'F:\Backup\Skills_Online_V1_CopyOnly_20200130.bak'
WITH COPY_ONLY 
GO


---Restore prodercopy from carderp
USE [master]
go
Exec sp_kill [proderpcopy] 
go
RESTORE DATABASE [proderpcopy] FROM  DISK = N'C:\Volumes\Database01\MSSQL14.STAGING\MSSQL\Backup\CARDERP_CopyOnly_20200213.bak' WITH  FILE = 1,  
MOVE N'CARDERP' TO N'C:\Volumes\Database01\MSSQL14.STAGING\MSSQL\DATA\proderpcopy.mdf',  
MOVE N'CARDERP_Audit' TO N'C:\Volumes\Database01\MSSQL14.STAGING\MSSQL\DATA\proderpcopyAudit.ndf',  
MOVE N'CARDERP_log' TO N'C:\Volumes\Log01\MSSQL14.STAGING\MSSQL\Logs\proderpcopy_1.ldf',  NOUNLOAD,  STATS = 5
GO
USE [master]
GO
ALTER DATABASE [proderpcopy] SET RECOVERY SIMPLE WITH NO_WAIT
GO

---To see who changed the sql server agent jobs
select j.name, j.date_modified, l.loginname
from sysjobs j
inner join sys.syslogins l on j.owner_sid = l.sid
WHERE j.name LIKE '%Weekly - HIPAA non compliance report - Excel%'


USE [master]
RESTORE DATABASE [ReadyPay] FROM  DISK = N'C:\Volumes\Database01\MSSQL14.STAGING\MSSQL\Backup\ReadyPay_Copyonly_02122020.bak' WITH  FILE = 1,  
NOUNLOAD,  REPLACE,  STATS = 5

GO
 
 
 --Query to read from xml_deadlock_report
 SELECT XEvent.query('(event/data/value/deadlock)[1]') AS DeadlockGraph
FROM (
    SELECT XEvent.query('.') AS XEvent
    FROM (
        SELECT CAST(target_data AS XML) AS TargetData
        FROM sys.dm_xe_session_targets st
        INNER JOIN sys.dm_xe_sessions s ON s.address = st.event_session_address
        WHERE s.NAME = 'system_health'
            AND st.target_name = 'ring_buffer'
        ) AS Data
CROSS APPLY TargetData.nodes('RingBufferTarget/event[@name="xml_deadlock_report"]') AS XEventData(XEvent)
) AS source;


--Query to start extended Event to trace performance issues
CREATE EVENT SESSION [Performance_Trace_Events_0528] ON SERVER 
ADD EVENT sqlserver.degree_of_parallelism,
ADD EVENT sqlserver.exec_prepared_sql,
ADD EVENT sqlserver.partition_sort_info,
ADD EVENT sqlserver.query_execution_batch_global_string_dictionary,
ADD EVENT sqlserver.query_execution_dynamic_push_down_statistics,
ADD EVENT sqlserver.rpc_completed,
ADD EVENT sqlserver.sp_statement_completed,
ADD EVENT sqlserver.sql_batch_completed,
ADD EVENT sqlserver.sql_statement_completed 
ADD TARGET package0.event_file(SET filename=N'D:\Webfarmatics Assignment\Performancetrace0528.xel')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=OFF)
GO



---Query to enable automatic statistics on a database
USE [master]
GO
ALTER DATABASE [AdventureWorksDW2014] SET AUTO_UPDATE_STATISTICS_ASYNC ON WITH NO_WAIT
ALTER DATABASE [AdventureWorksDW2014] SET AUTO_UPDATE_STATISTICS ON WITH NO_WAIT
GO



--Script to run index rebuilds on indices in a server
DECLARE @Database NVARCHAR(255)   
DECLARE @Table NVARCHAR(255)  
DECLARE @cmd NVARCHAR(1000)  

DECLARE DatabaseCursor CURSOR READ_ONLY FOR  
SELECT name FROM master.sys.databases   
WHERE name NOT IN ('master','msdb','tempdb','model','distribution')  -- databases to exclude
--WHERE name IN ('DB1', 'DB2') -- use this to select specific databases and comment out line above
AND state = 0 -- database is online
AND is_in_standby = 0 -- database is not read only for log shipping
ORDER BY 1  

OPEN DatabaseCursor  

FETCH NEXT FROM DatabaseCursor INTO @Database  
WHILE @@FETCH_STATUS = 0  
BEGIN  

   SET @cmd = 'DECLARE TableCursor CURSOR READ_ONLY FOR SELECT ''['' + table_catalog + ''].['' + table_schema + ''].['' +  
   table_name + '']'' as tableName FROM [' + @Database + '].INFORMATION_SCHEMA.TABLES WHERE table_type = ''BASE TABLE'''   

   -- create table cursor  
   EXEC (@cmd)  
   OPEN TableCursor   

   FETCH NEXT FROM TableCursor INTO @Table   
   WHILE @@FETCH_STATUS = 0   
   BEGIN
      BEGIN TRY   
         SET @cmd = 'ALTER INDEX ALL ON ' + @Table + ' REBUILD' 
         --PRINT @cmd -- uncomment if you want to see commands
         EXEC (@cmd) 
      END TRY
      BEGIN CATCH
         PRINT '---'
         PRINT @cmd
         PRINT ERROR_MESSAGE() 
         PRINT '---'
      END CATCH

      FETCH NEXT FROM TableCursor INTO @Table   
   END   

   CLOSE TableCursor   
   DEALLOCATE TableCursor  

   FETCH NEXT FROM DatabaseCursor INTO @Database  
END  
CLOSE DatabaseCursor   
DEALLOCATE DatabaseCursor


---Update statistics for all db on server
sp_MSforeachdb 'use [?]; exec sp_updatestats'


----Enable SQL Server Agent on linux box
sudo /opt/mssql/bin/mssql-conf set sqlagent.enabled true  
sudo systemctl restart mssql-server 


--Change recovery model of database
alter database itiketi_db set recovery full
alter database itiketi_live set recovery full

--Stored procedure Execution statistics Query





