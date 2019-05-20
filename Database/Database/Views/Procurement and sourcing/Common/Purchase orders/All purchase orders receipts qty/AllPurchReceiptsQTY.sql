SELECT vpsj.PURCHID,
       vpsj.DELIVERYDATE,
       vpst.ITEMID,
       SUM(vpst.ORDERED) ORDERED,
       SUM(vpst.QTY) Received
FROM dbo.VENDPACKINGSLIPJOUR vpsj
    LEFT JOIN dbo.VENDPACKINGSLIPTRANS vpst
        ON vpst.VENDPACKINGSLIPJOUR = vpsj.RECID
GROUP BY vpsj.PURCHID,
         vpsj.DELIVERYDATE,
         vpst.ITEMID;