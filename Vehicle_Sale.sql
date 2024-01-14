--1.Aylar erzinde filiallarin ne qeder satisi olub?
WITH total_Sales AS (
    SELECT b.BRANCH_name, TO_char(s.SALE_DATE, 'Month') AS month, COUNT(s.sale_id) AS total_sales
    FROM SALE s
    JOIN VEHICLE v ON s.VEHICLE_ID = v.VEHICLE_ID
    JOIN BRANCH b ON b.BRANCH_ID = v.BRANCH_ID
    GROUP BY TO_char(s.SALE_DATE, 'Month'), b.BRANCH_name

    UNION ALL

    SELECT b.BRANCH_name, TO_char(os.order_date, 'Month') AS month, COUNT(os.online_sale_id) AS total_sales
    FROM ONLINE_SALE os
    JOIN VEHICLE v ON os.VEHICLE_ID = v.VEHICLE_ID
    JOIN BRANCH b ON b.BRANCH_ID = v.BRANCH_ID
    GROUP BY TO_char(os.ORDER_DATE , 'Month'), b.BRANCH_name
)
SELECT branch_name, month, SUM(total_sales) AS total_sales
FROM total_sales
GROUP BY branch_name, month
HAVING SUM(total_sales) = (SELECT max(a) FROM (SELECT sum(total_Sales) AS a FROM total_sales GROUP BY branch_name, month))


--2.Aylar erzinde filiallarin nece mantliq satisi olub?
WITH total_amount as(
SELECT b.BRANCH_name, TO_char(s.SALE_DATE, 'Month') AS month, sum(s.price) AS total_sales
    FROM SALE s
    JOIN VEHICLE v ON s.VEHICLE_ID = v.VEHICLE_ID
    JOIN BRANCH b ON b.BRANCH_ID = v.BRANCH_ID
    GROUP BY TO_char(s.SALE_DATE, 'Month'), b.BRANCH_name
  UNION ALL
 
 SELECT b.BRANCH_name, TO_char(os.order_date, 'Month') AS month, sum(os.PRICE ) AS total_sales
    FROM ONLINE_SALE os
    JOIN VEHICLE v ON os.VEHICLE_ID = v.VEHICLE_ID
    JOIN BRANCH b ON b.BRANCH_ID = v.BRANCH_ID
    GROUP BY TO_char(os.ORDER_DATE , 'Month'), b.BRANCH_name
    
    UNION ALL
    
    SELECT b.BRANCH_name, TO_char(c.LAST_PAYMENT_DATE , 'Month') AS month, sum(c.total_paid ) AS total_sales
    FROM credit c
    JOIN sale v ON v.CUSTOMER_ID  = c.CUSTOMER_ID 
    JOIN VEHICLE v2 ON v2.VEHICLE_ID  =v.VEHICLE_ID 
    JOIN BRANCH b ON b.BRANCH_ID = v2.BRANCH_ID
    GROUP BY TO_char(c.LAST_PAYMENT_DATE , 'Month'), b.BRANCH_name
    
	UNION ALL
	 SELECT b.BRANCH_name, TO_char(co.LAST_PAYMENT_DATE , 'Month') AS month, sum(co.total_paid ) AS total_sales
    FROM ONLINE_CREDIT  co
    JOIN online_sale v ON v.account_id  = co.account_id 
    JOIN VEHICLE v2 ON v2.VEHICLE_ID  =v.VEHICLE_ID 
    JOIN BRANCH b ON b.BRANCH_ID = v2.BRANCH_ID
    GROUP BY TO_char(co.LAST_PAYMENT_DATE , 'Month'), b.BRANCH_name
    
)
SELECT BRANCH_NAME, MONTH, sum(total_Sales) 
FROM total_amount
GROUP BY BRANCH_NAME,MONTH
ORDER BY MONTH asc


--3.Aylar erzinde neqliyyat vasitelerinin satisini goster
WITH total AS (
    SELECT TO_CHAR(s.sale_date, 'Month') AS AY, v.model, COUNT(v.MODEL) AS say
    FROM SALE s
    JOIN VEHICLE v ON v.VEHICLE_ID = s.VEHICLE_ID
    GROUP BY TO_CHAR(s.sale_date, 'Month'), v.model

    UNION ALL

    SELECT TO_CHAR(os.order_date, 'Month') AS AY, v.model, COUNT(v.MODEL) AS say
    FROM ONLINE_SALE os
    JOIN VEHICLE v ON v.VEHICLE_ID = os.VEHICLE_ID
    GROUP BY TO_CHAR(os.order_Date, 'Month'), v.model
)
SELECT AY, model, SUM(say) AS total_sales
FROM total
GROUP BY AY, MODEL


--4.Online satis ve enenevi satisin goster

WITH SaleCounts AS (

    SELECT COUNT(SALE_ID) AS Enenevi_satis FROM SALE S
),
	OnlineSaleCounts as(
	SELECT COUNT(online_sale_id) AS Online_satis FROM ONLINE_SALE os
)
SELECT
    Enenevi_satis,
    Online_satis
FROM
    SaleCounts,
    OnlineSaleCounts;

   
   
 --5.Online kiraye ve enenevi kiraye goster
WITH RentCounts AS (

    SELECT COUNT(*) AS Enenevi_kiraye FROM RENT S
),
	OnlineRentCount as(
	SELECT COUNT(*) AS Online_kiraye FROM ONLINE_RENT  os
)
SELECT
    Enenevi_kiraye,
    Online_kiraye
FROM
    RentCounts,
    OnlineRentCount;
   
  
--6.Enenevi sekilde alis/veris edenlerden hansilarin tetbiqde(online-app) hesablar var ve nece faiz teskil edir?
   
--a.
     SELECT s.CUSTOMER_ID , c.CUSTOMER_NAME c
    FROM SALE S
    JOIN CUSTOMER C ON C.CUSTOMER_ID = S.CUSTOMER_ID
    WHERE C.CUSTOMER_NAME IN (SELECT us.User_Name FROM USER_ACCOUNT us)
   
   
--b.
 WITH CustomerCount AS (
    SELECT COUNT( S.CUSTOMER_ID) AS CustomerCount
    FROM SALE S
    JOIN CUSTOMER C ON C.CUSTOMER_ID = S.CUSTOMER_ID
    WHERE C.CUSTOMER_NAME IN (SELECT us.User_Name FROM USER_ACCOUNT us)
)

, TotalUserCount AS (
    SELECT COUNT( User_Name) AS TotalUserCount
    FROM USER_ACCOUNT
)

SELECT
    (CustomerCount.CustomerCount * 100) / TotalUserCount.TotalUserCount AS PercentageCustomersOfAllUsers
FROM
    CustomerCount, TotalUserCount;


--7.Musteriler alış/veriş zamani Kartla, Nagd yoxsa Kreditle odemeyi ustun tutur?


WITH MOST AS(
SELECT COUNT(*) AS A , payment_method FROM SALE s 
GROUP BY PAYMENT_METHOD 
UNION ALL
SELECT COUNT(*), payment_method FROM ONLINE_SALE os   
GROUP BY PAYMENT_METHOD )
SELECT SUM(A), PAYMENT_METHOD FROM MOST GROUP BY PAYMENT_METHOD
HAVING  SUM(A)= (SELECT MAX(A) FROM (SELECT SUM(A) AS A FROM MOST GROUP BY PAYMENT_METHOD )






--8.En cox satis olan ayda, evvelki aya nisbeten nece faiz artim olub?
WITH ayalaragore_satis AS (
    SELECT COUNT(*) AS A, TO_CHAR(SALE_DATE, 'Month') AS AY
    FROM SALE s
    GROUP BY TO_CHAR(SALE_DATE, 'Month')

    UNION ALL

    SELECT COUNT(*), TO_CHAR(ORDER_DATE, 'Month')
    FROM ONLINE_SALE os 
    GROUP BY TO_CHAR(ORDER_DATE, 'Month')
)



SELECT (MAX(A)- MIN(A))/MIN(A)*100  AS percentage_increase
FROM (
    SELECT SUM(A) AS A, AY
FROM ayalaragore_satis
GROUP BY AY
HAVING SUM(A) = (SELECT MAX(A) FROM (SELECT SUM(A) AS A FROM ayalaragore_satis GROUP BY AY))

UNION ALL 
SELECT SUM(A), AY
FROM ayalaragore_satis
GROUP BY AY
HAVING substr(AY,1,INSTR(AY,' ')-1)='April'
);


--9.En cox satis olan aydan sonraki ayda nece faiz azalma olub?
WITH ayalaragore_satis AS (
    SELECT COUNT(*) AS A, TO_CHAR(SALE_DATE, 'Month') AS AY
    FROM SALE s
    GROUP BY TO_CHAR(SALE_DATE, 'Month')

    UNION ALL

    SELECT COUNT(*), TO_CHAR(ORDER_DATE, 'Month')
    FROM ONLINE_SALE os 
    GROUP BY TO_CHAR(ORDER_DATE, 'Month')
)


SELECT (MAX(A)- MIN(A))/MIN(A)*100  AS percentage_increase
FROM (
    SELECT SUM(A) AS A, AY
FROM ayalaragore_satis
GROUP BY AY
HAVING SUM(A) = (SELECT MAX(A) FROM (SELECT SUM(A) AS A FROM ayalaragore_satis GROUP BY AY))

UNION ALL 
SELECT SUM(A), AY
FROM ayalaragore_satis
GROUP BY AY
HAVING substr(AY,1,INSTR(AY,' ')-1)='June'

);


--10.Musterilerin nece faizi sigortalanmagi ustun tutur?
WITH INSURANCE AS (
    SELECT COUNT(*) AS COUNT FROM INSURANCE_SALE
    UNION ALL
    SELECT COUNT(*) FROM INSURANCE_SALE_ONLINE
),

CUSTOMERS AS (
    SELECT COUNT(*) AS SAY FROM CUSTOMER
    UNION ALL
    SELECT COUNT(*) FROM ONLINE_SALE os
)


SELECT (SUM(COUNT) *100)/SUM(SAY)
FROM INSURANCE,CUSTOMERS


--11. Musteriler en cox hansi nov sigortaya ustunluk verir ?


WITH sigorta AS(
SELECT count(*) AS cem, i.INSURANCE_TYPE FROM INSURANCE i 
JOIN INSURANCE_SALE is1 ON i.INSURANCE_ID= is1.INSURANCE_ID
GROUP BY INSURANCE_TYPE
UNION ALL
SELECT count(*), i.INSURANCE_TYPE FROM INSURANCE i 
JOIN INSURANCE_SALE_online iso ON i.INSURANCE_ID= iso.INSURANCE_ID
GROUP BY INSURANCE_TYPE
)
SELECT sum(cem), INSURANCE_TYPE FROM sigorta
GROUP BY INSURANCE_TYPE
HAVING sum(cem)=( SELECT max(a) FROM (SELECT sum(cem) AS a FROM sigorta
GROUP BY INSURANCE_TYPE ))


--12. Musteriler en cox hansi sirketin sigortasindan istifade edir?

WITH sigorta AS(
SELECT count(*) AS cem, i.INSURANCE_company FROM INSURANCE i 
JOIN INSURANCE_SALE is1 ON i.INSURANCE_ID= is1.INSURANCE_ID
GROUP BY INSURANCE_company
UNION ALL
SELECT count(*), i.INSURANCE_company FROM INSURANCE i 
JOIN INSURANCE_SALE_online iso ON i.INSURANCE_ID= iso.INSURANCE_ID
GROUP BY INSURANCE_company
)
SELECT sum(cem), INSURANCE_company FROM sigorta
GROUP BY INSURANCE_company
HAVING sum(cem)=( SELECT max(a) FROM (SELECT sum(cem) AS a FROM sigorta
GROUP BY INSURANCE_company ))


--13.Hansi musteri en cox kiraye edib?
WITH say as(
SELECT count(*) AS A, c.customer_name FROM RENT r 
JOIN CUSTOMER c ON c.CUSTOMER_Id= r.CUSTOMER_ID 
GROUP BY customer_name
UNION ALL 
SELECT count(*), ua.user_name FROM ONLINE_RENT ol
JOIN USER_ACCOUNT ua  ON ua.account_id= ol.account_id
GROUP BY user_name
)
SELECT sum(A), CUSTOMER_NAME FROM say
GROUP BY CUSTOMER_NAME
HAVING  sum(A) IN (SELECT MAX(A) FROM (SELECT sum(A) AS A FROM say
GROUP BY CUSTOMER_NAME))


--14. Musterilerin nece faizi kirayeledikden sonra yeniden kiraye edib?
WITH cem as(
SELECT COUNT(*) AS A FROM RENT r 
JOIN CUSTOMER c ON c.customer_id=r.customer_id
JOIN ADDİTİONAL_RENT ar ON R.rent_id =AR.rent_id
GROUP BY customer_name,CUSTOMER_SURNAME
UNION ALL

SELECT COUNT(*) FROM ONLINE_RENT or2   
JOIN  USER_ACCOUNT ua  ON ua.account_id=OR2.account_id
JOIN ADDİTİONAL_RENT_ONLINE aro ON aro.online_RENT_ID= or2.ONLINE_RENT_ID 
GROUP BY user_name , user_surname
), 

TOTAL AS(
SELECT COUNT(*) AS B FROM RENT r 

UNION ALL

SELECT COUNT(*) FROM ONLINE_RENT or2   
)
SELECT  SUM(A)*100/SUM(B) FROM CEM, TOTAL


--15.Elave Kirayelerden qazanilan mebleg ne qederdir?

WITH cem as(
SELECT sum(extra_price) AS a FROM ADDİTİONAL_RENT ar 
UNION ALL
SELECT sum(extra_price) FROM ADDİTİONAL_RENT_ONLINE aro 
)
SELECT sum(A) AS CEM FROM cem


--16.Musterilerin nece faizi endirimden yararlana bilib?

WITH A AS(
SELECT count(customer_name) AS Endirim FROM DISCOUNT_info d
JOIN sale s ON d.SALE_ID =s.sale_id
JOIN CUSTOMER c ON s.CUSTOMER_ID =c.CUSTOMER_ID 

UNION ALL

SELECT count(user_name) FROM online_DISCOUNT_info d1
JOIN online_sale os ON d1.online_SALE_ID =os.online_sale_id
JOIN USER_ACCOUNT ua  ON os.account_id =ua.ACCOUNT_ID  
)

, D AS(
SELECT COUNT(*) AS Umumi FROM SALE  c 
UNION ALL
SELECT COUNT(*) FROM ONLINE_SALE os 
)
SELECT (SUM(Endirim)*100)/SUM(Umumi) FROM D,A

--17. Nece faiz musteri kredit goturub?
WITH a AS (
SELECT count(*) AS kredit FROM SALE s WHERE price=0
UNION all
SELECT COUNT(*) FROM ONLINE_SALE os  WHERE price=0 ),

b as(
SELECT count(*) AS umumi  FROM sale
UNION all
SELECT COUNT(*) FROM ONLINE_SALE 
)

SELECT (sum(kredit)*100)/ sum(umumi) FROM a,b

--18.Musteriler nece ayliq kredit goturmeyi ustun tutur?
WITH a as(
SELECT count(*) AS g, total_month FROM CREDIT c 
GROUP BY total_month

UNION ALL
SELECT count(*), total_month FROM ONLINE_CREDIT oc  
GROUP BY total_month
)
SELECT sum(g), total_month FROM a 
GROUP BY total_month
HAVING sum(g) =( SELECT max(max) from(SELECT sum(g) AS max FROM a GROUP BY total_month) )


--19. Musteriler en cox hansi neqliyyat vasitesi ucun kredit goturub?

WITH a AS (
SELECT count(*) AS say, model FROM CREDIT c 
JOIN sale s ON c.CUSTOMER_ID =s.CUSTOMER_ID 
JOIN VEHICLE v ON v.VEHICLE_ID =s.VEHICLE_ID 
GROUP BY model
UNION ALL 


SELECT count(*), model FROM online_CREDIT oc 
JOIN online_sale os ON oc.account_id=os.ACCOUNT_ID  
JOIN VEHICLE v ON v.VEHICLE_ID =os.VEHICLE_ID 
GROUP BY model
)
SELECT sum(say), model FROM a GROUP BY model
HAVING sum(Say) = (SELECT max(max) FROM (SELECT max(sum(say)) AS max FROM a GROUP BY model))


--20.Il erzinde hansi Filialda daha cox satis olub?
WITH a AS (
SELECT count(*) AS say, to_char(s.sale_date,'yyyy') , b.branch_name FROM sale s
JOIN VEHICLE v ON s.VEHICLE_ID =v.VEHICLE_ID 
JOIN BRANCH b ON s.VEHICLE_ID = v.VEHICLE_ID 
GROUP BY  to_char(sale_date,'yyyy'),branch_name

UNION ALL
SELECT count(*) , to_char(os.order_date,'yyyy'),b.branch_name FROM ONLINE_SALE os 
JOIN VEHICLE v ON v.vehicle_id=os.vehicle_id
JOIN BRANCH b ON v.vehicle_id=os.vehicle_id
GROUP BY  to_char(order_date,'yyyy'),branch_name
)
SELECT sum( say), branch_name FROM a
GROUP BY branch_name
having sum(say) = (SELECT max(cem) FROM (
SELECT sum(say) AS cem FROM a GROUP BY branch_name))

--21.Il erzinde hansi neqliyyat vasitesi daha cox satilib?

WITH RESULT AS (
SELECT count(*) AS count, model, to_char(s.sale_date,'yyyy' ) AS YEARS FROM sale s
JOIN VEHICLE v ON v.VEHICLE_ID =s.VEHICLE_ID 
GROUP BY model,to_char(s.sale_date,'yyyy' )

UNION ALL


SELECT count(*), model, to_char(os.order_date,'yyyy' ) FROM ONLINE_SALE os  
JOIN VEHICLE v ON v.VEHICLE_ID =os.VEHICLE_ID 
GROUP BY model,to_char(os.ORDEr_date,'yyyy' )
)
SELECT sum(count), model, YEARS FROM RESULT
GROUP BY model,YEARS 
HAVING sum(COUNT) = (SELECT max(cem) FROM  (SELECT sum(count) AS CEM, model, YEARS FROM RESULT
GROUP BY model,YEARS ))



--22.Umumi satisdan qazanilan mebleg

WITH a as(

SELECT sum(price) AS b FROM sale 
UNION ALL
SELECT SUM(price) FROM ONLINE_sale
UNION ALL
SELECT SUM(total_paid) FROM credit 
UNION ALL
SELECT sum(total_paid ) FROM ONLINE_CREDIT 
)
SELECT sum(b) FROM a


--23. Kartlarin son 4 reqemini cixarib qalaninin qarsisina ulduz qoy.
SELECT LPAD( SUBSTR(card_number, LENGTH(card_number)-4, 4), LENGTH(card_number), '*') 
FROM CARD_INFO
UNION ALL
SELECT LPAD( SUBSTR(card_number, LENGTH(card_number)-4, 4), LENGTH(card_number), '*') 
FROM CARD_INFO_ONLINE cio ;


--24.Avgusta qeder satisdan qazanilan pul

WITH a as(
SELECT sum(total_paid) AS total, TO_CHAR(c.last_payment_date, 'Month') AS month FROM CREDIT c
GROUP BY TO_CHAR(c.last_payment_date, 'Month') 
UNION all
SELECT sum(price),TO_CHAR(s.sale_date, 'Month')  FROM sale s
GROUP BY TO_CHAR(s.sale_date, 'Month')
UNION ALL
SELECT sum(price),TO_CHAR(os.order_date, 'Month')  FROM online_sale os
GROUP BY TO_CHAR(os.order_date, 'Month')
UNION ALL
SELECT sum(total_paid),TO_CHAR(oc.last_payment_date, 'Month')  FROM online_credit oc
GROUP BY TO_CHAR(oc.last_payment_date, 'Month')
)
SELECT sum(total), month FROM a
GROUP BY month
HAVING MONTH='August   '


--25.Avgusta satisdan qazanilan pul

WITH a as(
SELECT sum(each_month) AS total, TO_CHAR(c.last_payment_date, 'Month') AS month FROM CREDIT c
GROUP BY TO_CHAR(c.last_payment_date, 'Month') 
UNION all
SELECT sum(price),TO_CHAR(s.sale_date, 'Month')  FROM sale s
GROUP BY TO_CHAR(s.sale_date, 'Month')
UNION ALL
SELECT sum(price),TO_CHAR(os.order_date, 'Month')  FROM online_sale os
GROUP BY TO_CHAR(os.order_date, 'Month')
UNION ALL
SELECT sum(each_month),TO_CHAR(oc.last_payment_date, 'Month')  FROM online_credit oc
GROUP BY TO_CHAR(oc.last_payment_date, 'Month')
)
SELECT sum(total), month FROM a
GROUP BY month
HAVING MONTH='August   '