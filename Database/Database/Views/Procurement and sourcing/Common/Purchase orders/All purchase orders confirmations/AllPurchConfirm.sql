WITH cte
AS (SELECT plav.PURCHID,
           vpoj.PURCHORDERDATE,
           plav.PURCHQTY,
           plav.QTYORDERED,
           plav.ITEMID,
           ROW_NUMBER() OVER (PARTITION BY plav.PURCHID,
                                           plav.ITEMID,
                                           plav.PURCHQTY
                              ORDER BY plav.ITEMID,
                                       vpoj.PURCHORDERDATE DESC,
                                       plav.PURCHQTY DESC
                             ) ROWNO
    FROM dbo.VENDPURCHORDERJOUR vpoj
        LEFT JOIN dbo.PURCHTABLEALLVERSIONS ptav
            ON ptav.PURCHTABLEVERSIONRECID = vpoj.PURCHTABLEVERSION
        LEFT JOIN dbo.PURCHLINEALLVERSIONS plav
            ON plav.PURCHTABLEVERSIONRECID = ptav.PURCHTABLEVERSIONRECID
),
     cte2
AS (SELECT *,
           ROW_NUMBER() OVER (PARTITION BY cte.PURCHID,
                                           cte.ITEMID
                              ORDER BY cte.PURCHORDERDATE DESC
                             ) INROWNO
    FROM cte
    WHERE cte.ROWNO = 1
          AND cte.PURCHQTY <> 0)
SELECT *
FROM cte2
WHERE cte2.INROWNO = 1;