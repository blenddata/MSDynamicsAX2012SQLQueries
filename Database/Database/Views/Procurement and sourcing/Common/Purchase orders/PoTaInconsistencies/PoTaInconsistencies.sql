WITH PRICES
AS (SELECT pdt.AMOUNT,
           pdt.FROMDATE,
           pdt.TODATE,
           id.INVENTSITEID,
           pdt.ITEMRELATION,
           pdt.MODULE,
           pdt.ACCOUNTRELATION,
           pdt.RELATION
    FROM MicrosoftDynamicsAX.dbo.PRICEDISCTABLE pdt
        LEFT JOIN MicrosoftDynamicsAX.dbo.INVENTDIM id
            ON id.INVENTDIMID = pdt.INVENTDIMID
    WHERE pdt.MODULE IN ( 0, 2 ) --inventory  
          AND pdt.RELATION = 0 --purch  
),
     ITEMS
AS (SELECT pl.ITEMID,
           pt.ACCOUNTINGDATE
    FROM MicrosoftDynamicsAX.dbo.PURCHLINE pl
        LEFT JOIN MicrosoftDynamicsAX.dbo.PURCHTABLE pt
            ON pl.PURCHID = pt.PURCHID
    GROUP BY pl.ITEMID,
             pt.ACCOUNTINGDATE),
     ITEMPRICES
AS (SELECT i.ITEMID,
           i.ACCOUNTINGDATE,
           p.AMOUNT,
           p.MODULE,
           p.ACCOUNTRELATION,
           p.RELATION,
           p.INVENTSITEID,
           ROW_NUMBER() OVER (PARTITION BY i.ITEMID,
                                           i.ACCOUNTINGDATE,
                                           p.INVENTSITEID
                              ORDER BY p.TODATE DESC,
                                       p.MODULE ASC,
                                       p.INVENTSITEID
                             ) ROWNO
    FROM ITEMS i
        LEFT JOIN PRICES p
            ON p.ITEMRELATION = i.ITEMID
               AND
               (
                   i.ACCOUNTINGDATE >= p.FROMDATE
                   AND i.ACCOUNTINGDATE <= p.TODATE
               ))
SELECT CAST(ROW_NUMBER() OVER (ORDER BY pl.RECID) AS INT) ID,
       pl.PURCHID PurchId,
       pt.ACCOUNTINGDATE AccountingDate,
       lid.INVENTSITEID Site,
       lid.INVENTLOCATIONID Warehouse,
       pl.ITEMID ItemNumber,
       pl.PURCHPRICE PoPrice,
       spp.AMOUNT SitePurchPrice,
       ppp.AMOUNT PublicPurchPrice,
       ISNULL(spp.AMOUNT, ppp.AMOUNT) Amount
FROM MicrosoftDynamicsAX.dbo.PURCHTABLE pt
    LEFT JOIN MicrosoftDynamicsAX.dbo.PURCHLINE pl
        ON pl.PURCHID = pt.PURCHID
    LEFT JOIN MicrosoftDynamicsAX.dbo.INVENTDIM lid
        ON lid.INVENTDIMID = pl.INVENTDIMID
    LEFT JOIN ITEMPRICES spp
        ON spp.INVENTSITEID = lid.INVENTSITEID
           AND spp.ITEMID = pl.ITEMID
           AND spp.ACCOUNTINGDATE = pt.ACCOUNTINGDATE
           AND spp.ROWNO = 1
    LEFT JOIN ITEMPRICES ppp
        ON ppp.ITEMID = pl.ITEMID
           AND spp.AMOUNT IS NULL
           AND ppp.INVENTSITEID IS NULL
           AND ppp.ACCOUNTINGDATE = pt.ACCOUNTINGDATE
           AND ppp.ROWNO = 1
WHERE pt.DOCUMENTSTATE = 40 -- Confirmed   
      AND pl.PURCHSTATUS IN ( 2, 3 ) --Received,Invoiced  
      AND ISNULL(spp.AMOUNT, ppp.AMOUNT) NOT
      BETWEEN pl.PURCHPRICE - 1 AND pl.PURCHPRICE + 1;


