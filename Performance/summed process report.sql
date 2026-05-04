/*
select top 10 * from [PowerBI_Distribution].[ProcessReport]  

select p.*, w.process_code
from [PowerBI_Distribution].[ProcessReport]  as p
left join (select * from [PowerBI_Distribution].[LAProcess] where wh_id='335') as w on p.process_id = w.process_id
where p.wh_id='335' and p.work_day = '2026-03-24' and p.employee_id = '1000861' and w.process_code like 'lunch%'


select 

select top 100 * from [PowerBI_Distribution].[ProcessReport] where wh_id='335' and work_day = '2026-03-24' and employee_id = '782'
select top 100 * from [PowerBI_Distribution].[employee] where wh_id='335' and   emp_number = '00782' 
select top 100 * from  [PowerBI_Distribution].[LAProcess]
*/



SELECT a.[wh_id]
         , b.[EmployeeName]
         , b.[EmployeeNumber]
         ,[process_transaction]
         , CAST([work_day] AS DATE)   [work_day]
         , SUM([actual_elapsed_time]) AS total_mins
         , count(a.[process_id])AS total_transactions
         , SUM([total_sam]) AS Total_SAM_MINS
         , a.[labor_type]
		 ,a.[process_id]
		 ,c.[process_code]
         , MIN(a.process_start) process_start_min
         , MAX(a.process_end)  process_end_max
    FROM [PowerBI_Distribution].[ProcessReport] a
        LEFT JOIN [PowerBI_Distribution].[DimEmployee]               b
            ON a.[employee_id] = b.[EmployeeID]
               AND a.[wh_id] = b.[WarehouseID]
         Left Join [PowerBI_Distribution].[LAProcess] c
		    ON a.[process_id] = c.[process_id]
               AND a.[wh_id] = c.[wh_id]
    WHERE a.[wh_id] IN ('335','35')
          AND [work_day] > DATEADD(DAY, -15, GETDATE())
          and a.[application]='WA'
    GROUP BY b.[EmployeeName]
           , b.[EmployeeNumber]
           , [work_day]
           , a.[wh_id]
           ,a.[process_transaction]
           ,a.[labor_type]
		   ,a.[process_id]
		   ,c.[process_code]