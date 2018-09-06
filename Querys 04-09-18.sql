
Prueba
------------------------------------------
SELECT * into MiNuevaTabla From MITABLA
------------------------------------------
SELECT MVC_IDECLI,
   SUM(MVC_TOTALX) AS TOTAL_VENTA
 FROM   MOVIMCAB
 GROUP BY MVC_IDECLI 
-----------------------------------
CREATE TABLE departamento20 AS
SELECT empno, ename, sal 
FROM emp
WHERE deptno = 20;
------------------------------------------
SELECT column_name(s)
FROM table1
FULL OUTER JOIN table2 ON table1.column_name = table2.column_name;
------------------------------------------------------------------
SELECT City FROM Customers
UNION
SELECT City FROM Suppliers
ORDER BY City;
---------------------------
SELECT City FROM Customers
UNION ALL
SELECT City FROM Suppliers
ORDER BY City;
---------------------------
SELECT Shippers.ShipperName,COUNT(Orders.OrderID) AS NumberOfOrders FROM Orders
LEFT JOIN Shippers ON Orders.ShipperID = Shippers.ShipperID
GROUP BY ShipperName;
--------------------------------------------------------------------------------
SELECT COUNT(CustomerID), Country
FROM Customers
GROUP BY Country  
HAVING COUNT(CustomerID) > 5
ORDER BY COUNT(CustomerID) DESC;
----------------------------------
Esquema ECM5461E  de netezza podemos crear tablas y creo que demás objetos necesarios. 
existe la tabla TBL_PREPAGO_DATSMS_201807, que tiene las variables por cada número de prepago de SMS y datos, para el mes de julio.
 * es importante ir adicionando estas tablas al documento de inventario de fuentes para que vayamos teniendo un panorama general de la información que se está almacenando en todo netezza.
 * Siempre dejémosle el prefijo TBL_PREPAGO, para las tablas que utilicemos, cualquier recomendación o documento que tengan de estándares que les gustaría que se use, 
   lo comparten para que las personas que trabajen sobre este esquema lo implementen
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

DB_DWH_DESARROLLO.ECM5461E.TBL_PREPAGO_RECARPU_201807
-----------------------------------------------------
SELECT count (calling_number) Cant_llam_sal       ---> VOZ
      ,ROUND(SUM(duracion)) TOTAL_DUR_VOZ_SEG 
FROM db_dwh_voz.voz.tbl_fact_voz_trafico_saliente
where calling_number = 3112748807
and fecha_hora BETWEEN '2018-07-01 00:00:00' AND '2018-07-31 23:59:59'
LIMIT 100;
----------------------------------------------------------------------
SELECT TELE_NUMB NUM_TELEFONO                                    ------> Query General con voz
      ,VOZ.DUR_SEG TOTAL_DUR_VOZ_SEG
	  ,MAX(NVL(VOZ.CANT_LLAM_SAL,0)) TOTAL_LLAM_OUT
      ,MAX(NVL(SMS.CANT_SMS,0)) TOTAL_SMS_OUT
      ,ROUND(SUM(CASE WHEN (F.RATING_GROUP IN ('53')) OR (F.RATING_GROUP = '211' AND S.SERVICEID = '32101225') THEN TAB1.CONSUMO_BYTES_TOTAL ELSE 0 END)/(1024*1024),2) MB_WHATSAPP
      ,ROUND(SUM(CASE WHEN (F.RATING_GROUP IN ('54','55')) OR (F.RATING_GROUP = '211' AND S.SERVICEID = '32101226') THEN TAB1.CONSUMO_BYTES_TOTAL ELSE 0 END)/(1024*1024),2) MB_TWITER_Y_FACEBOOK
      ,ROUND(SUM(TAB1.CONSUMO_BYTES_TOTAL)/(1024*1024),2) - 
       ROUND(SUM(CASE WHEN (F.RATING_GROUP IN ('53','54','55')) OR (F.RATING_GROUP = '211' AND S.SERVICEID IN ('32101225', '32101226')) THEN TAB1.CONSUMO_BYTES_TOTAL ELSE 0 END)/(1024*1024),2) MB_NAVEGACION
      ,ROUND(SUM(TAB1.CONSUMO_BYTES_TOTAL)/(1024*1024),2) MB_CONSUMO_TOTAL

FROM  DWH_DB.SEGMENTACION.INH_SEG_BSCS_CLIENTES CLI

LEFT   JOIN ( SELECT TELE_NUMB TN
                    ,SK_CHARGING_CHARACTERISTICS
					,SK_RATING_GROUP
					,SK_NODO_MED
					,SK_SERVICEID
					,CONSUMO_BYTES_TOTAL
                FROM DB_DWH_DATOS.DATOS.TBL_FACT_DATOS_TRAFICO_USU_201807 
			)TAB1 ON TAB1.TN = CLI.TELE_NUMB
			
LEFT   JOIN DWH_DB.DATOS.TBL_DIM_TIPOUSUARIO_T1 E ON TAB1.SK_CHARGING_CHARACTERISTICS = E.ID_TIPO_USUARIO
LEFT   JOIN DWH_DB.DATOS.TBL_DIM_RATING_GROUP_T2 F ON TAB1.SK_RATING_GROUP = F.ID_RATING_GROUP
LEFT   JOIN DWH_DB.MDRS.NODOS_GPRS G ON TAB1.SK_NODO_MED = G.NODO_ID
LEFT   JOIN DWH_DB.DATOS.TBL_DIM_SERVICEID_T1 S ON TAB1.SK_SERVICEID = S.ID_SERVICEID
LEFT   JOIN DB_DWH_VOZ.VOZ.TBL_FACT_VOZ_TRAFICO_SALIENTE V ON V.CALLING_NUMBER = CLI.TELE_NUMB 
			
LEFT   JOIN ( SELECT CALLING_NUMBER
             ,COUNT (CALLING_NUMBER) CANT_SMS
               FROM DWH_DB.MDRS.SMSMMS
              WHERE CAUSE_FOR_TERMINATION = '100C'
                AND MESSAGE_DELIVERYTIME BETWEEN '2018-07-01 00:00:00' AND '2018-07-31 23:59:59'
                AND RECORD_TYPE = 1
           GROUP BY 1 
            )SMS ON '57'||CLI.TELE_NUMB = SMS.CALLING_NUMBER
			
LEFT   JOIN ( SELECT CALLING_NUMBER
             ,COUNT (CALLING_NUMBER) CANT_LLAM_SAL
			 ,ROUND(SUM(DURACION)) DUR_SEG
               FROM DB_DWH_VOZ.VOZ.TBL_FACT_VOZ_TRAFICO_SALIENTE
              WHERE FECHA_HORA BETWEEN '2018-07-01 00:00:00' AND '2018-07-31 23:59:59'                
           GROUP BY 1 
            )VOZ ON CLI.TELE_NUMB = VOZ.CALLING_NUMBER
			
AND TAB1.SK_NODO_MED <> 510
AND E.TIPO_USUARIO = 'Prepago'
AND CLI.TIPO_LINEA = 'Prepago'
AND CLI.ESTADO = 'a' OR CLI.ESTADO = 's'
GROUP BY TELE_NUMB,DUR_SEG
LIMIT 100;
----------------------------------------------------------------------------------------------------------------
COUNT
21642.382.242 --> voz saliente
--------------
SELECT TELE_NUMB 
,SUM(CANT_CARGAS) CANT_RECARGAS
,ROUND(SUM(VLR_CARGAS)) VALOR_RECA_MES
FROM DB_DWH_DESARROLLO.ECM5461E.TBL_PREPAGO_RECARPU_201807
GROUP BY 1
------------------------------------------------------------
Query Recargas - general 

SELECT TELE_NUMB NUM_TELEFONO
      ,SUM(R.CANT_CARGAS) CANT_RECARGAS
      ,ROUND(SUM(R.VLR_CARGAS)) VALOR_REC_MES
      ,MAX(NVL(SMS.CANT_SMS,0)) TOTAL_SMS_OUT
      ,ROUND(SUM(CASE WHEN (F.RATING_GROUP IN ('53')) OR (F.RATING_GROUP = '211' AND S.SERVICEID = '32101225') THEN TAB1.CONSUMO_BYTES_TOTAL ELSE 0 END)/(1024*1024),2) MB_WHATSAPP
      ,ROUND(SUM(CASE WHEN (F.RATING_GROUP IN ('54','55')) OR (F.RATING_GROUP = '211' AND S.SERVICEID = '32101226') THEN TAB1.CONSUMO_BYTES_TOTAL ELSE 0 END)/(1024*1024),2) MB_TWITER_Y_FACEBOOK
      ,ROUND(SUM(TAB1.CONSUMO_BYTES_TOTAL)/(1024*1024),2) - 
       ROUND(SUM(CASE WHEN (F.RATING_GROUP IN ('53','54','55')) OR (F.RATING_GROUP = '211' AND S.SERVICEID IN ('32101225', '32101226')) THEN TAB1.CONSUMO_BYTES_TOTAL ELSE 0 END)/(1024*1024),2) MB_NAVEGACION
      ,ROUND(SUM(TAB1.CONSUMO_BYTES_TOTAL)/(1024*1024),2) MB_CONSUMO_TOTAL
	  
FROM  DWH_DB.SEGMENTACION.INH_SEG_BSCS_CLIENTES CLI

LEFT   JOIN ( SELECT TELE_NUMB TN
                    ,SK_CHARGING_CHARACTERISTICS
					,SK_RATING_GROUP
					,SK_NODO_MED
					,SK_SERVICEID
					,CONSUMO_BYTES_TOTAL
                FROM DB_DWH_DATOS.DATOS.TBL_FACT_DATOS_TRAFICO_USU_201807 
			)TAB1 ON TAB1.TN = CLI.TELE_NUMB
			
LEFT   JOIN DWH_DB.DATOS.TBL_DIM_TIPOUSUARIO_T1 E ON TAB1.SK_CHARGING_CHARACTERISTICS = E.ID_TIPO_USUARIO
LEFT   JOIN DWH_DB.DATOS.TBL_DIM_RATING_GROUP_T2 F ON TAB1.SK_RATING_GROUP = F.ID_RATING_GROUP
LEFT   JOIN DWH_DB.MDRS.NODOS_GPRS G ON TAB1.SK_NODO_MED = G.NODO_ID
LEFT   JOIN DWH_DB.DATOS.TBL_DIM_SERVICEID_T1 S ON TAB1.SK_SERVICEID = S.ID_SERVICEID

LEFT   JOIN ( SELECT TELE_NUMB TEL
                    ,CANT_CARGAS					
					,VLR_CARGAS
                FROM DB_DWH_DESARROLLO.ECM5461E.TBL_PREPAGO_RECARPU_201807
				WHERE FECHA_HORA BETWEEN '2018-07-01 00:00:00' AND '2018-07-01 23:59:59' 
			)R ON R.TEL = CLI.TELE_NUMB 
			
LEFT   JOIN ( SELECT CALLING_NUMBER
             ,COUNT (CALLING_NUMBER) CANT_SMS
               FROM DWH_DB.MDRS.SMSMMS
              WHERE CAUSE_FOR_TERMINATION = '100C'
                AND MESSAGE_DELIVERYTIME BETWEEN '2018-07-01 00:00:00' AND '2018-07-31 23:59:59'
                AND RECORD_TYPE = 1
           GROUP BY 1 
            )SMS ON '57'||CLI.TELE_NUMB = SMS.CALLING_NUMBER
			
AND TAB1.SK_NODO_MED <> 510
AND E.TIPO_USUARIO = 'Prepago'
AND CLI.TIPO_LINEA = 'Prepago'
AND CLI.ESTADO = 'a' OR CLI.ESTADO = 's'
GROUP BY TELE_NUMB
LIMIT 100;
----------------------------------------------------------------------------------------------------------

