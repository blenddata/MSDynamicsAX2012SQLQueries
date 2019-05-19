SELECT wlt.LOADID,
       wlt.INVENTSITEID,
       wlt.INVENTLOCATIONID,
       (CASE wlt.LOADSTATUS
            WHEN 0 THEN
                'Open'
            WHEN 1 THEN
                'Posted'
            WHEN 2 THEN
                'Waved'
            WHEN 3 THEN
                'InProcess'
            WHEN 4 THEN
                'InPacking'
            WHEN 5 THEN
                'Loaded'
            WHEN 6 THEN
                'Shipped'
            WHEN 8 THEN
                'Received'
            ELSE
                'Unknown'
        END
       ) [LOADSTATUS],
       wlt.LOADWEIGHT,
       wll.LoadVolume,
       wlt.CARRIERCODE,
       wlt.LOADSHIPCONFIRMUTCDATETIME LoadShippedConfirmationDate,
       wlt.CREATEDDATETIME,
       wlt.CREATEDBY,
       tdl.DRIVERNAME,
       ta.TRAILERNUMBER,
       ta.TRACTORNUMBER,
       tdl.BANKIBAN,
       tdl.BANKIBAN_NAME BANKIBANNAME,
       (CASE wlt.LOADDIRECTION
            WHEN 0 THEN
                'None'
            WHEN 1 THEN
                'Inbound'
            WHEN 2 THEN
                'Outbound'
            ELSE
                'Unknown'
        END
       ) [LOADDIRECTION],
       CASE wll.INVENTTRANSTYPE
           WHEN 0 THEN
               'Sales order'
           WHEN 3 THEN
               'Purchase order'
           WHEN 4 THEN
               'InventTransaction'
           WHEN 6 THEN
               'InventTransfer'
           WHEN 11 THEN
               'WMSOrder'
           WHEN 13 THEN
               'InventCounting'
           WHEN 14 THEN
               'WMSTransport'
           WHEN 15 THEN
               'QuarantineOrder'
           WHEN 21 THEN
               'TransferOrderShip'
           WHEN 22 THEN
               'TransferOrderReceive'
           WHEN 23 THEN
               'TransferOrderScrap'
           WHEN 24 THEN
               'SalesQuotation'
           WHEN 25 THEN
               'QualityOrder'
           WHEN 26 THEN
               'Blocking'
           WHEN 102 THEN
               'FixedAssets_RU'
           WHEN 150 THEN
               'Statement'
           WHEN 201 THEN
               'WHSWork'
           WHEN 202 THEN
               'WHSQuarantine'
           WHEN 203 THEN
               'WHSContainer'
           ELSE
               'Unspecified'
       END AS REFERENCECATEGORY,
       wll.OrderNumbers,
       wll.Warehouses,
       IIF(tr.ROUTESTATUS <> 1, ncrate.RATECUR, rate.RATECUR) Rate, -- !Confirmed
       tit.VENDINVOICEID,
       (CASE tit.INVOICESTATUS
            WHEN 0 THEN
                'Open'
            WHEN 1 THEN
                'Pending'
            WHEN 2 THEN
                'Submitted'
            WHEN 3 THEN
                'Approved'
            WHEN 4 THEN
                'Rejected'
            WHEN 5 THEN
                'PartiallyApproved'
            WHEN 6 THEN
                'Resubmitted'
            WHEN 7 THEN
                'PendingAfterReject'
            ELSE
                'Unknown'
        END
       ) [INVOICESTATUS],
       tljr.REFJOURNALNUM InvoiceJournalId,
       tit.REFJOURNALNUM,
       ljt.JOURNALNUM,
       ljtt.VOUCHER
FROM dbo.WHSLOADTABLE wlt
    OUTER APPLY
(
    SELECT SUM(IIF(wpdu.RECID IS NOT NULL, wll.QTY * (wpdu.DEPTH * wpdu.HEIGHT * wpdu.WIDTH), (it.UNITVOLUME * wll.QTY))) LoadVolume,
           STUFF(
                    (
                        SELECT ', ' + tmpWll.ORDERNUM
                        FROM dbo.WHSLOADLINE tmpWll
                        WHERE tmpWll.LOADID = wll.LOADID
                        GROUP BY tmpWll.ORDERNUM
                        FOR XML PATH(''), TYPE
                    ).value('.[1]', 'nvarchar(max)'),
                    1,
                    2,
                    ''
                ) OrderNumbers,
           STUFF(
                    (
                        SELECT ', ' + tmpId.INVENTLOCATIONID
                        FROM dbo.WHSLOADLINE tmpWll
                            LEFT JOIN dbo.INVENTDIM tmpId
                                ON tmpId.INVENTDIMID = tmpWll.INVENTDIMID
                        WHERE tmpWll.LOADID = wll.LOADID
                        GROUP BY tmpId.INVENTLOCATIONID
                        FOR XML PATH(''), TYPE
                    ).value('.[1]', 'nvarchar(max)'),
                    1,
                    2,
                    ''
                ) Warehouses,
           wll.INVENTTRANSTYPE
    FROM dbo.WHSLOADLINE wll
        LEFT JOIN dbo.WHSPHYSDIMUOM wpdu
            ON wpdu.ITEMID = wll.ITEMID
               AND wpdu.UOM = wll.UOM
        LEFT JOIN dbo.INVENTTABLE it
            ON it.ITEMID = wll.ITEMID
    WHERE wll.LOADID = wlt.LOADID
    GROUP BY wll.LOADID,
             wll.INVENTTRANSTYPE
) wll
    LEFT JOIN dbo.TMSAPPOINTMENT ta
        ON ta.APPTREFNUM = wlt.LOADID
           AND ta.APPTREFTYPE = 3
    LEFT JOIN dbo.TMSDRIVERLOG tdl
        ON tdl.APPTID = ta.APPTID
    LEFT JOIN dbo.TMSROUTE tr
        ON tr.ROUTECODE = wlt.ROUTECODE
    OUTER APPLY
(
    SELECT trs.CURRENCYCODE,
           trs.ROUTECODE,
           SUM(trs.RATECUR) RATECUR
    FROM dbo.TMSROUTESEGMENT trs
    WHERE trs.ROUTECODE = wlt.ROUTECODE
    GROUP BY trs.CURRENCYCODE,
             trs.ROUTECODE
) rate
    OUTER APPLY
(
    SELECT trat.CURRENCYCODE,
           trat.ROUTECODE,
           SUM(trat.RATECUR) RATECUR
    FROM dbo.TMSROUTEACCESSORIALTABLE trat
    WHERE trat.ROUTECODE = wlt.ROUTECODE
    GROUP BY trat.CURRENCYCODE,
             trat.ROUTECODE
) ncrate
    LEFT JOIN dbo.TMSINVOICETABLE tit
        ON tit.LOADID = wlt.LOADID
    LEFT JOIN dbo.LEDGERJOURNALTABLE ljt
        ON ljt.JOURNALNUM = tit.REFJOURNALNUM
    LEFT JOIN dbo.LEDGERJOURNALTRANS ljtt
        ON ljtt.JOURNALNUM = ljt.JOURNALNUM
           AND ljtt.ACCOUNTTYPE = 2 --vendor
    LEFT JOIN dbo.TMSINVOICELINE til
        ON til.INTERNALINVNUMBER = tit.INTERNALINVNUMBER
    LEFT JOIN dbo.TMSLEDGERJOURREF tljr
        ON tljr.REFRECID = til.REFRECID;