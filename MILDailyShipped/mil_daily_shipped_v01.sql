/* driver={iSeries Access ODBC Driver};system=MILPROD;default collection=AMFLIBL,AFILELIBL,DISTLIBL;ccsid=65535;translate=1
*/

WITH itm AS (
SELECT t.STID, t.ITNBR, t.ITCLS, t.B2Z95S, t.WEGHT, s.ITMCQTY,
        (CASE WHEN t.ITCLS IN ('WPLS','PLST') THEN 'Plastic'
            WHEN t.ITCLS IN ('PVN') THEN 'Unkits'
            WHEN t.ITCLS LIKE  'Z%K' THEN 'Unkits'
            WHEN t.ITCLS IN ('PVN2','QA','QB') THEN 'RAW'
            WHEN t.ITCLS = 'CHS' THEN 'RP-CGs'
            WHEN t.ITCLS IN ('CTA','MTA','HTA','GTA') THEN 'RP CGs'
            WHEN t.ITCLS LIKE 'CH%' THEN 'RAW'
            WHEN t.ITCLS LIKE 'CR%' THEN 'RAW'
            WHEN t.ITCLS LIKE 'CN%' THEN 'RAW'
            WHEN t.ITCLS IN ('TAF','FFR') THEN 'RP'
            WHEN t.ITCLS IN ('BBFR') THEN 'FR Sock'
            WHEN t.ITCLS IN ('ZDTP') THEN 'Pillow'
            WHEN t.ITCLS IN ('MVN') THEN 'Quilting'
            WHEN t.ITCLS IN ('ZKIZ','TAB') THEN 'Zipper Cover'
            WHEN t.ITCLS IN ('WVHC','WVVG') THEN 'Verona'
            WHEN t.ITCLS IN ('PVN') THEN 'Fabric'
            WHEN t.ITCLS IN ('WVCS') THEN 'Foundation'
            WHEN t.ITCLS IN ('ZABC','ZECD','ZDAA','ZECD','ZDWC','ZDAB','ZDAE','ZDAW','ZDBC','ZDWC','ZDAY','ZEBR','ZVTY','ZVTC','ZEOT','ZDYB') THEN 'CaseGoods'
            WHEN t.ITCLS IN ('ZAIS','ZKIS','ZNFR','ZKBP','ZKBA','ZBMA','ZCIM') THEN 'Bedding'
            ELSE 'Check' END) AS Product
FROM AMFLIBL.ITMRVA AS t
JOIN AFILELIBL.ITMEXT AS s ON t.itnbr = s.itnbr
WHERE t.STID = '51'
),
ContainerDetails AS (
    SELECT
        TRIM(a.WCICONTAINERNUMBER) AS ContainerNumber,
        a.WCIORIGIN,
        a.WCIDESTINATION,
        a.WCIORDER,
        TRIM(a.WCIITEMNUMBER) AS ItemNumber,
        a.WCIQUANTITYLOADED AS Qty,
        a.WCILASTMAINTENANCETIMESTAMP,
        a.WCILASTMAINTENANCEUSER,
        c.ITMCQTY,
        c.itcls,
        c.B2Z95S AS UnitCube,
        c.WEGHT AS UnitWeight,
        a.WCIQUANTITYLOADED * c.B2Z95S AS Cubes,
        CEIL(a.WCIQUANTITYLOADED / c.ITMCQTY) AS Cartons,
        TRIM(a.WCIORIGIN) || '-' || TRIM(a.WCICONTAINERNUMBER) || '-' || TRIM(a.WCIDESTINATION) AS Container#,
        c.Product
    FROM DISTLIBL.TBL_WVCONTAINER_DTL_ITM a
    LEFT JOIN itm c ON a.WCIITEMNUMBER = c.ITNBR
    WHERE a.WCIORIGIN = '51'
      AND TRIM(a.WCICONTAINERNUMBER) NOT LIKE '%AIR%'
      --AND a.WCILASTMAINTENANCETIMESTAMP BETWEEN CURRENT DATE - 400 DAYS AND CURRENT DATE

    UNION ALL

    SELECT
        TRIM(a.WCICONTAINERNUMBER) AS ContainerNumber,
        a.WCIORIGIN,
        a.WCIDESTINATION,
        a.WCIORDER,
        TRIM(a.WCIITEMNUMBER) AS ItemNumber,
        a.WCIQUANTITYLOADED AS Qty,
        a.WCILASTMAINTENANCETIMESTAMP,
        a.WCILASTMAINTENANCEUSER,
        c.ITMCQTY,
        c.itcls,
        c.B2Z95S AS UnitCube,
        c.WEGHT AS UnitWeight,
        a.WCIQUANTITYLOADED * c.B2Z95S AS Cubes,
        CEIL(a.WCIQUANTITYLOADED / c.ITMCQTY) AS Cartons,
        TRIM(a.WCIORIGIN) || '-' || TRIM(a.WCICONTAINERNUMBER) || '-' || TRIM(a.WCIDESTINATION) || '-' || SUBSTR(CHAR(a.WCIARCHIVETIMESTAMP), 1, 13) AS Container#,
        c.Product
    FROM ASHLEYARCL.WVCNTIDA a
    LEFT JOIN itm c ON a.WCIITEMNUMBER = c.ITNBR
    WHERE a.WCIORIGIN = '51'
      AND a.WCILASTMAINTENANCETIMESTAMP BETWEEN CURRENT DATE - 400 DAYS AND CURRENT DATE
      AND TRIM(a.WCICONTAINERNUMBER) NOT LIKE '%AIR%'
),
ContainerType AS (
    SELECT
        Container#,
        CASE WHEN COUNT(DISTINCT Product) = 1 THEN 'None-Mixed' ELSE 'Mixed' END AS ContainerType
    FROM ContainerDetails
    GROUP BY Container#
),
HeaderDetails AS (
    SELECT
        TRIM(a.WCHCONTAINERNUMBER) AS ContainerNumber,
        a.WCHCONTAINERSIZE,
        a.WCHDOORNUMBER,
        a.WCHBUILDING,
        a.WCHPOSTEDTIMESTAMP,
        TRIM(a.WCHORIGIN) || '-' || TRIM(a.WCHCONTAINERNUMBER) || '-' || TRIM(a.WCHDESTINATION) AS Container#,
        a.WCHTOTALCUBES as H_Cubes
    FROM DISTLIBL.TBL_WVCONTAINER_HDR a
    WHERE a.WCHCONTAINERSTATUS IN ('P', 'T')
      AND a.WCHORIGIN = '51'
      AND TRIM(a.WCHCONTAINERNUMBER) NOT LIKE '%AIR%'
      AND a.WCHDESTINATION NOT IN ('001')

    UNION ALL

    SELECT
        TRIM(a.WCHCONTAINERNUMBER) AS ContainerNumber,
        a.WCHCONTAINERSIZE,
        a.WCHDOORNUMBER,
        a.WCHBUILDING,
        a.WCHPOSTEDTIMESTAMP,
        TRIM(a.WCHORIGIN) || '-' || TRIM(a.WCHCONTAINERNUMBER) || '-' || TRIM(a.WCHDESTINATION) || '-' || SUBSTR(CHAR(a.WCHARCHIVETIMESTAMP), 1, 13) AS Container#,
        a.WCHTOTALCUBES as H_Cubes
    FROM ASHLEYARCL.WVCNTHDA a
    WHERE a.WCHCONTAINERSTATUS IN ('P', 'T')
      AND a.WCHPOSTEDTIMESTAMP BETWEEN CURRENT DATE - 360 DAYS AND CURRENT DATE
      AND a.WCHORIGIN = '51'
      AND TRIM(a.WCHCONTAINERNUMBER) NOT LIKE '%AIR%'
      AND a.WCHDESTINATION NOT IN ('001')
)
SELECT
    d.WCIORIGIN,
    d.Container#,
    d.Cubes,
    d.itcls,
    d.Product,
    d.WCIDESTINATION,
    d.WCIORDER,
    d.ItemNumber,
    d.Qty,
    VARCHAR_FORMAT(d.WCILASTMAINTENANCETIMESTAMP, 'YYYY-MM-DD HH:MI:SS') AS WCILASTMAINTENANCETIMESTAMP,
    d.ContainerNumber,
    t.ContainerType,
    d.WCILASTMAINTENANCEUSER,
    d.ITMCQTY,
    d.UnitCube,
    d.UnitWeight,
    d.Cartons,
    h.WCHCONTAINERSIZE,
    h.WCHDOORNUMBER,
    h.WCHBUILDING,
    h.H_Cubes,
    h.Container#,
    TO_CHAR(h.WCHPOSTEDTIMESTAMP, 'yyyy-mm-dd') AS Date,
    CASE
        WHEN TRIM(SUBSTR(h.WCHCONTAINERSIZE, 1, 2)) = '53' THEN d.Cubes / 3831
        WHEN TRIM(SUBSTR(h.WCHCONTAINERSIZE, 1, 2)) = '50' THEN d.Cubes / 3333
        WHEN TRIM(SUBSTR(h.WCHCONTAINERSIZE, 1, 2)) = '45' THEN d.Cubes / 3037
        WHEN TRIM(SUBSTR(h.WCHCONTAINERSIZE, 1, 3)) = '40H' THEN d.Cubes / 2650
        WHEN TRIM(SUBSTR(h.WCHCONTAINERSIZE, 1, 2)) = '40' THEN d.Cubes / 2383
        WHEN SUBSTR(h.WCHCONTAINERSIZE, 1, 1) = '2' THEN d.Cubes / 1191
        ELSE d.Cubes / 2650
    END AS Utilization,
    'MIL' AS WH,
    CASE
        WHEN ROW_NUMBER() OVER (PARTITION BY d.Container#, d.ItemNumber ORDER BY d.WCILASTMAINTENANCETIMESTAMP) = 1 THEN 1
        ELSE 0
    END AS SKU_Count
FROM ContainerDetails d
JOIN ContainerType t ON d.Container# = t.Container#
RIGHT JOIN HeaderDetails h ON d.Container# = h.Container#
ORDER BY d.WCIORIGIN, d.ContainerNumber, d.WCILASTMAINTENANCETIMESTAMP