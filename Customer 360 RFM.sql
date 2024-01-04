select * from customer_registered cr 
select * from customer_transaction ct 


------- RFM calculate
set @report_date =  '2022-09-01'

create table
customer_rfm_calculate as(

with RFM_base as(
select CustomerID,
	datediff(@report_date,Purchase_Date) as R,
	Count(distinct Purchase_Date  ) as F,
	Sum(GMV) as M
from customer_transaction ct
where CustomerID <> 0
group by CustomerID 
), RFM_score as(
select CustomerID, R,F,M,
	ntile(4) OVER(order by R desc) as Recency,
	ntile(4) over(order by F asc ) as Frequency,
	ntile(4) over(order by M asc) as Monetary
from RFM_base
),RFM_Overall as (
select CustomerID, R,F,M,
	Concat(Recency,Frequency,Monetary) as RFM
from RFM_score
)
select rl.CustomerID, rl.R, rl.F, rl.M, rl.RFM, rs.segment  
from RFM_Overall rl left join `rfm-project`.rfm_segment rs on rl.RFM = rs.rfm 
)

select * from customer_rfm_calculate
drop table customer_rfm_calculate 

-- change the report_date into automatically and set everything as a procedures

CREATE PROCEDURE calculating_rfm_data ()
BEGIN 
    SET @report_date = CURRENT_DATE();

    CREATE TABLE customer_rfm_calculate AS
    WITH RFM_base AS (
        SELECT CustomerID,
            DATEDIFF(@report_date, Purchase_Date) AS R,
            COUNT(DISTINCT Purchase_Date) AS F,
            SUM(GMV) AS M
        FROM customer_transaction ct
        WHERE CustomerID <> 0
        GROUP BY CustomerID 
    ), RFM_score AS (
        SELECT CustomerID, R, F, M,
            NTILE(4) OVER(ORDER BY R DESC) AS Recency,
            NTILE(4) OVER(ORDER BY F ASC) AS Frequency,
            NTILE(4) OVER(ORDER BY M ASC) AS Monetary
        FROM RFM_base
    ), RFM_Overall AS (
        SELECT CustomerID, R, F, M,
            CONCAT(Recency, Frequency, Monetary) AS RFM
        FROM RFM_score
    )
    SELECT rl.CustomerID, rl.R, rl.F, rl.M, rl.RFM, rs.segment  
    FROM RFM_Overall rl
    LEFT JOIN `rfm-project`.rfm_segment rs ON rl.RFM = rs.rfm;
   
    SELECT * FROM customer_rfm_calculate;


    DROP TABLE customer_rfm_calculate;
END;

call `rfm-project`.calculating_rfm_data

create event rfm_date
on schedule every 1 month 
do call `rfm-project`.calculating_rfm_data
show processlist
