create database supermarket;
use supermarket;
SELECT *
FROM customers;
SELECT COUNT(*)
FROM customers;
SELECT COUNT(*) AS TotalRows
FROM sales;
SELECT COUNT(*) AS Customers FROM customers;
SELECT COUNT(*) AS Products FROM products;
SELECT COUNT(*) AS Stores FROM stores;
SELECT COUNT(*) AS Sales FROM sales;
SELECT COUNT(*) AS Returns FROM returns;
SELECT COUNT(*) AS Targets FROM targets;
USE supermarket;
GO

SELECT TOP 10 * FROM customers;
SELECT TOP 10 * FROM products;
SELECT TOP 10 * FROM stores;
SELECT TOP 10 * FROM sales;
SELECT TOP 10 * FROM returns;
SELECT TOP 10 * FROM targets;
SELECT
    CustomerID,
    COUNT(*) AS NumberOfRows
FROM customers
GROUP BY CustomerID
HAVING COUNT(*) > 1;
SELECT
    ProductID,
    COUNT(*) AS NumberOfRows
FROM products
GROUP BY ProductID
HAVING COUNT(*) > 1;
SELECT
    StoreID,
    COUNT(*) AS NumberOfRows
FROM stores
GROUP BY StoreID
HAVING COUNT(*) > 1;
SELECT
    SaleID,
    COUNT(*) AS NumberOfRows
FROM sales
GROUP BY SaleID
HAVING COUNT(*) > 1;
SELECT StoreID, COUNT(*)
FROM targets
GROUP BY StoreID;
SELECT
    StoreID,
    Month,
    COUNT(*) AS NumberOfRows
FROM targets
GROUP BY StoreID, Month
HAVING COUNT(*) > 1;
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN
(
    'customers',
    'products',
    'stores',
    'sales',
    'returns',
    'targets'
)
ORDER BY TABLE_NAME, ORDINAL_POSITION;
SELECT TOP 10 * FROM sales;
SELECT
    SaleID,
    COUNT(*) AS NumberOfRows
FROM sales
GROUP BY SaleID
HAVING COUNT(*) > 1;
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales'
ORDER BY ORDINAL_POSITION;
SELECT
    COUNT(*) AS NullQuantity
FROM sales
WHERE Quantity IS NULL;
SELECT
    COUNT(*) AS ZeroQuantity
FROM sales
WHERE Quantity = 0;
SELECT
    MIN(Quantity) AS MinQuantity,
    MAX(Quantity) AS MaxQuantity
FROM sales;
SELECT
    COUNT(*) AS NullUnitPrice
FROM sales
WHERE UnitPrice IS NULL;
SELECT
    MIN(UnitPrice) AS MinPrice,
    MAX(UnitPrice) AS MaxPrice
FROM sales;
SELECT COUNT(*) AS NullQuantity
FROM sales
WHERE Quantity IS NULL;

SELECT COUNT(*) AS ZeroQuantity
FROM sales
WHERE Quantity = 0;

SELECT COUNT(*) AS NullUnitPrice
FROM sales
WHERE UnitPrice IS NULL;

SELECT COUNT(*) AS ZeroUnitPrice
FROM sales
WHERE UnitPrice = 0;
DROP TABLE sales;
SELECT MIN(Quantity), MAX(Quantity)
FROM sales;

SELECT MIN(UnitPrice), MAX(UnitPrice)
FROM sales;
SELECT *
FROM sales
WHERE Quantity <= 0;
SELECT *
FROM sales
WHERE UnitPrice <= 0;
SELECT *
FROM sales
WHERE Discount < 0
   OR Discount > 0.50;
  SELECT
    SaleID,
    COUNT(*) AS NumberOfRows
FROM sales
GROUP BY SaleID
HAVING COUNT(*) > 1;
SELECT DISTINCT
    s.CustomerID
FROM sales s
LEFT JOIN customers c
    ON s.CustomerID = c.CustomerID
WHERE c.CustomerID IS NULL
  AND s.CustomerID IS NOT NULL;
  SELECT DISTINCT
    s.ProductID
FROM sales s
LEFT JOIN products p
    ON s.ProductID = p.ProductID
WHERE p.ProductID IS NULL;
SELECT DISTINCT
    s.StoreID
FROM sales s
LEFT JOIN stores st
    ON s.StoreID = st.StoreID
WHERE st.StoreID IS NULL;
-- Missing customer details
SELECT *
FROM customers
WHERE City IS NULL
   OR State IS NULL;
   -- Missing product details
SELECT *
FROM products
WHERE Category IS NULL
   OR SubCategory IS NULL;
   -- Returns connected to a SaleID that does not exist
SELECT r.*
FROM returns r
LEFT JOIN sales s
    ON r.SaleID = s.SaleID
WHERE s.SaleID IS NULL;
SELECT *
FROM sales
WHERE SaleID IN
(
    SELECT SaleID
    FROM sales
    GROUP BY SaleID
    HAVING COUNT(*) > 1
)
ORDER BY SaleID;
CREATE VIEW vw_customers_clean AS

SELECT
    CustomerID,
    CustomerName,
    Gender,
    COALESCE(City, 'Unknown') AS City,
    COALESCE(State, 'Unknown') AS State,
    JoinDate,
    CustomerType
FROM customers

UNION ALL

SELECT
    'GUEST',
    'Guest Customer',
    'Unknown',
    'Unknown',
    'Unknown',
    CAST(NULL AS DATE),
    'Guest'

UNION ALL

SELECT
    'UNKNOWN',
    'Unknown Customer',
    'Unknown',
    'Unknown',
    'Unknown',
    CAST(NULL AS DATE),
    'Unknown';
    CREATE VIEW vw_products_clean AS
SELECT
    ProductID,
    ProductName,
    COALESCE(Category, 'Unknown') AS Category,
    COALESCE(SubCategory, 'Unknown') AS SubCategory,
    Brand,
    CostPrice,
    SellingPrice
FROM products;
CREATE VIEW vw_sales_clean AS

WITH DeduplicatedSales AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY SaleID
            ORDER BY SaleID
        ) AS RowNumber
    FROM sales
)

SELECT
    s.SaleID,
    s.TransactionID,
    s.SaleDate,

    CASE
        WHEN s.CustomerID IS NULL THEN 'GUEST'
        WHEN c.CustomerID IS NULL THEN 'UNKNOWN'
        ELSE s.CustomerID
    END AS CustomerID,

    s.ProductID,
    s.StoreID,
    s.Quantity,
    s.UnitPrice,
    s.Discount,
    s.PaymentMethod

FROM DeduplicatedSales s

INNER JOIN products p
    ON s.ProductID = p.ProductID

INNER JOIN stores st
    ON s.StoreID = st.StoreID

LEFT JOIN customers c
    ON s.CustomerID = c.CustomerID

WHERE
    s.RowNumber = 1
    AND s.Quantity > 0
    AND s.UnitPrice > 0
    AND s.Discount BETWEEN 0 AND 0.50;
SELECT TOP 20 *
FROM vw_sales_clean;
SELECT COUNT(*) AS RawSales
FROM sales;

CREATE OR ALTER VIEW vw_sales_clean AS

WITH DeduplicatedSales AS
(
    SELECT
        SaleID,
        TransactionID,
        SaleDate,
        CustomerID,
        ProductID,
        StoreID,
        Quantity,
        UnitPrice,
        Discount,
        PaymentMethod,
        ROW_NUMBER() OVER
        (
            PARTITION BY SaleID
            ORDER BY SaleID
        ) AS rn
    FROM sales
)

SELECT
    s.SaleID,
    s.TransactionID,
    s.SaleDate,

    CASE
        WHEN s.CustomerID IS NULL THEN 'GUEST'
        WHEN c.CustomerID IS NULL THEN 'UNKNOWN'
        ELSE s.CustomerID
    END AS CustomerID,

    s.ProductID,
    s.StoreID,
    s.Quantity,
    s.UnitPrice,
    s.Discount,
    s.PaymentMethod

FROM DeduplicatedSales s

LEFT JOIN customers c
    ON s.CustomerID = c.CustomerID

WHERE
    s.rn = 1
    AND s.Quantity > 0
    AND s.UnitPrice > 0
    AND s.Discount BETWEEN 0 AND 0.50

    AND EXISTS
    (
        SELECT 1
        FROM products p
        WHERE p.ProductID = s.ProductID
    )

    AND EXISTS
    (
        SELECT 1
        FROM stores st
        WHERE st.StoreID = s.StoreID
    );
    SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('sales', 'customers', 'products', 'stores')
AND COLUMN_NAME IN
(
    'SaleID',
    'TransactionID',
    'CustomerID',
    'ProductID',
    'StoreID'
)
ORDER BY TABLE_NAME, COLUMN_NAME;
CREATE INDEX IX_sales_SaleID
ON sales(SaleID);

CREATE INDEX IX_sales_CustomerID
ON sales(CustomerID);

CREATE INDEX IX_sales_ProductID
ON sales(ProductID);

CREATE INDEX IX_sales_StoreID
ON sales(StoreID);

CREATE INDEX IX_customers_CustomerID
ON customers(CustomerID);

CREATE INDEX IX_products_ProductID
ON products(ProductID);

CREATE INDEX IX_stores_StoreID
ON stores(StoreID);
SELECT TOP 20 *
FROM vw_sales_clean;


SELECT COUNT(*) AS CleanSales
FROM vw_sales_clean;
-- Invalid quantity
SELECT *
FROM vw_sales_clean
WHERE Quantity <= 0;
-- Invalid price
SELECT *
FROM vw_sales_clean
WHERE UnitPrice <= 0;
-- Invalid discount
SELECT *
FROM vw_sales_clean
WHERE Discount < 0
   OR Discount > 0.50;
   -- Duplicate SaleIDs
SELECT
    SaleID,
    COUNT(*) AS NumberOfRows
FROM vw_sales_clean
GROUP BY SaleID
HAVING COUNT(*) > 1;
SELECT
    CustomerID,
    COUNT(*) AS SalesRows
FROM vw_sales_clean
WHERE CustomerID IN ('GUEST', 'UNKNOWN')
GROUP BY CustomerID;

-- Total Net Sales
SELECT
    SUM(Quantity * UnitPrice * (1 - Discount)) AS TotalSales
FROM vw_sales_clean;
-- Total Transactions
SELECT
    COUNT(DISTINCT TransactionID) AS TotalTransactions
FROM vw_sales_clean;
-- Unique Customers
SELECT
    COUNT(DISTINCT CustomerID) AS TotalCustomers
FROM vw_sales_clean;
-- Total Units Sold
SELECT
    SUM(Quantity) AS TotalUnits
FROM vw_sales_clean;
SELECT
    SUM(
        s.Quantity * s.UnitPrice * (1 - s.Discount)
    ) AS TotalSales,

    SUM(
        s.Quantity * p.CostPrice
    ) AS TotalCost,

    SUM(
        (s.Quantity * s.UnitPrice * (1 - s.Discount))
        -
        (s.Quantity * p.CostPrice)
    ) AS TotalProfit

FROM vw_sales_clean s

JOIN vw_products_clean p
    ON s.ProductID = p.ProductID;
   SELECT
    YEAR(SaleDate) AS SalesYear,
    MONTH(SaleDate) AS SalesMonth,
    SUM(Quantity * UnitPrice * (1 - Discount)) AS TotalSales
FROM vw_sales_clean
GROUP BY
    YEAR(SaleDate),
    MONTH(SaleDate)
ORDER BY
    SalesYear,
    SalesMonth;
    SELECT
    COUNT(DISTINCT CustomerID) AS RegisteredCustomers
FROM vw_sales_clean
WHERE CustomerID NOT IN ('GUEST', 'UNKNOWN');
SELECT
    CustomerID,
    COUNT(DISTINCT TransactionID) AS Transactions,
    SUM(Quantity * UnitPrice * (1 - Discount)) AS Sales
FROM vw_sales_clean
WHERE CustomerID IN ('GUEST', 'UNKNOWN')
GROUP BY CustomerID;
SELECT
    p.Category,

    SUM(s.Quantity) AS UnitsSold,

    SUM(
        s.Quantity * s.UnitPrice * (1 - s.Discount)
    ) AS TotalSales,

    SUM(
        s.Quantity * p.CostPrice
    ) AS TotalCost,

    SUM(
        s.Quantity * s.UnitPrice * (1 - s.Discount)
        - s.Quantity * p.CostPrice
    ) AS TotalProfit

FROM vw_sales_clean s

JOIN vw_products_clean p
    ON s.ProductID = p.ProductID

GROUP BY p.Category

ORDER BY TotalSales DESC;
SELECT
    p.Category,

    SUM(
        s.Quantity * s.UnitPrice * (1 - s.Discount)
    ) AS TotalSales,

    SUM(
        s.Quantity * s.UnitPrice * (1 - s.Discount)
        - s.Quantity * p.CostPrice
    ) AS TotalProfit,

    (
        SUM(
            s.Quantity * s.UnitPrice * (1 - s.Discount)
            - s.Quantity * p.CostPrice
        )
        /
        NULLIF(
            SUM(
                s.Quantity * s.UnitPrice * (1 - s.Discount)
            ),
            0
        )
    ) * 100 AS ProfitMarginPercent

FROM vw_sales_clean s

JOIN vw_products_clean p
    ON s.ProductID = p.ProductID

GROUP BY p.Category

ORDER BY TotalSales DESC;
SELECT TOP 10
    p.ProductID,
    p.ProductName,
    p.Category,
    SUM(s.Quantity) AS UnitsSold,
    SUM(
        s.Quantity * s.UnitPrice * (1 - s.Discount)
    ) AS TotalSales
FROM vw_sales_clean s
JOIN vw_products_clean p
    ON s.ProductID = p.ProductID
GROUP BY
    p.ProductID,
    p.ProductName,
    p.Category
ORDER BY TotalSales DESC;
SELECT TOP 10
    p.ProductID,
    p.ProductName,
    p.Category,
    SUM(s.Quantity) AS UnitsSold,
    SUM(
        s.Quantity * s.UnitPrice * (1 - s.Discount)
    ) AS TotalSales
FROM vw_sales_clean s
JOIN vw_products_clean p
    ON s.ProductID = p.ProductID
GROUP BY
    p.ProductID,
    p.ProductName,
    p.Category
ORDER BY TotalSales ASC;
SELECT TOP 10
    p.ProductName,

    SUM(
        s.Quantity * s.UnitPrice * (1 - s.Discount)
    ) AS Sales,

    SUM(
        s.Quantity * p.CostPrice
    ) AS Cost,

    SUM(
        s.Quantity * s.UnitPrice * (1 - s.Discount)
        - s.Quantity * p.CostPrice
    ) AS Profit

FROM vw_sales_clean s
JOIN vw_products_clean p
    ON s.ProductID = p.ProductID

GROUP BY p.ProductName
ORDER BY Profit DESC;
SELECT
    st.StoreID,
    st.StoreName,
    st.City,
    st.Region,

    COUNT(DISTINCT s.TransactionID) AS Transactions,

    SUM(s.Quantity) AS UnitsSold,

    SUM(
        s.Quantity * s.UnitPrice * (1 - s.Discount)
    ) AS TotalSales,

    SUM(
        s.Quantity * s.UnitPrice * (1 - s.Discount)
        - s.Quantity * p.CostPrice
    ) AS TotalProfit

FROM vw_sales_clean s

JOIN stores st
    ON s.StoreID = st.StoreID

JOIN vw_products_clean p
    ON s.ProductID = p.ProductID

GROUP BY
    st.StoreID,
    st.StoreName,
    st.City,
    st.Region

ORDER BY TotalSales DESC;
SELECT
    st.Region,

    COUNT(DISTINCT s.TransactionID) AS Transactions,

    SUM(
        s.Quantity * s.UnitPrice * (1 - s.Discount)
    ) AS TotalSales,

    SUM(
        s.Quantity * s.UnitPrice * (1 - s.Discount)
        - s.Quantity * p.CostPrice
    ) AS TotalProfit

FROM vw_sales_clean s

JOIN stores st
    ON s.StoreID = st.StoreID

JOIN vw_products_clean p
    ON s.ProductID = p.ProductID

GROUP BY st.Region

ORDER BY TotalSales DESC;
SELECT TOP 10
    c.CustomerID,
    c.CustomerName,
    c.CustomerType,

    COUNT(DISTINCT s.TransactionID) AS Transactions,

    SUM(
        s.Quantity * s.UnitPrice * (1 - s.Discount)
    ) AS TotalSpend

FROM vw_sales_clean s

JOIN vw_customers_clean c
    ON s.CustomerID = c.CustomerID

WHERE s.CustomerID NOT IN ('GUEST', 'UNKNOWN')

GROUP BY
    c.CustomerID,
    c.CustomerName,
    c.CustomerType

ORDER BY TotalSpend DESC;
SELECT
    SUM(
        Quantity * UnitPrice * (1 - Discount)
    )
    /
    COUNT(DISTINCT TransactionID) AS AverageTransactionValue
FROM vw_sales_clean;
SELECT
    CAST(SUM(Quantity) AS FLOAT)
    /
    COUNT(DISTINCT TransactionID) AS AverageBasketSize
FROM vw_sales_clean;
WITH MonthlyStoreSales AS
(
    SELECT
        StoreID,
        YEAR(SaleDate) AS SalesYear,
        MONTH(SaleDate) AS SalesMonth,

        SUM(
            Quantity * UnitPrice * (1 - Discount)
        ) AS ActualSales

    FROM vw_sales_clean

    GROUP BY
        StoreID,
        YEAR(SaleDate),
        MONTH(SaleDate)
)

SELECT
    m.StoreID,
    m.SalesYear,
    m.SalesMonth,
    m.ActualSales,
    t.SalesTarget,

    m.ActualSales - t.SalesTarget AS Variance,

    (m.ActualSales / NULLIF(t.SalesTarget, 0)) * 100
        AS TargetAchievementPercent

FROM MonthlyStoreSales m

JOIN targets t
    ON m.StoreID = t.StoreID
    AND m.SalesYear = YEAR(t.Month)
    AND m.SalesMonth = MONTH(t.Month)

ORDER BY
    m.StoreID,
    m.SalesMonth;
    WITH MonthlyStoreSales AS
(
    SELECT
        StoreID,
        YEAR(SaleDate) AS SalesYear,
        MONTH(SaleDate) AS SalesMonth,
        SUM(
            Quantity * UnitPrice * (1 - Discount)
        ) AS ActualSales
    FROM vw_sales_clean
    GROUP BY
        StoreID,
        YEAR(SaleDate),
        MONTH(SaleDate)
)

SELECT
    m.StoreID,
    m.SalesMonth,
    m.ActualSales,
    t.SalesTarget,

    (m.ActualSales / NULLIF(t.SalesTarget, 0)) * 100
        AS AchievementPercent,

    CASE
        WHEN m.ActualSales >= t.SalesTarget
            THEN 'Target Achieved'
        ELSE 'Target Missed'
    END AS TargetStatus

FROM MonthlyStoreSales m

JOIN targets t
    ON m.StoreID = t.StoreID
    AND m.SalesYear = YEAR(t.Month)
    AND m.SalesMonth = MONTH(t.Month);
 USE supermarket;
GO

CREATE OR ALTER VIEW vw_returns_clean AS

SELECT
    r.ReturnID,
    r.SaleID,
    r.ReturnDate,
    r.ReturnQuantity,
    r.ReturnReason

FROM returns r

INNER JOIN vw_sales_clean s
    ON r.SaleID = s.SaleID;
GO
SELECT TOP 20 *
FROM vw_returns_clean;
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'returns';
DROP TABLE IF EXISTS sales_clean;
GO

SELECT DISTINCT
    s.SaleID,
    s.TransactionID,
    s.SaleDate,

    CASE
        WHEN s.CustomerID IS NULL THEN 'GUEST'
        WHEN c.CustomerID IS NULL THEN 'UNKNOWN'
        ELSE s.CustomerID
    END AS CustomerID,

    s.ProductID,
    s.StoreID,
    s.Quantity,
    s.UnitPrice,
    s.Discount,
    s.PaymentMethod

INTO sales_clean

FROM sales s

INNER JOIN products p
    ON s.ProductID = p.ProductID

INNER JOIN stores st
    ON s.StoreID = st.StoreID

LEFT JOIN customers c
    ON s.CustomerID = c.CustomerID

WHERE
    s.Quantity > 0
    AND s.UnitPrice > 0
    AND s.Discount BETWEEN 0 AND 0.50;
GO
SELECT COUNT(*) AS CleanRows
FROM sales_clean;
DROP TABLE IF EXISTS sales_clean;
GO
SELECT *
INTO sales_clean
FROM vw_sales_clean;
GO
SELECT COUNT(*) AS CleanRows
FROM sales_clean;
SELECT TOP 20 *
FROM sales_clean;
CREATE UNIQUE INDEX IX_sales_clean_SaleID
ON sales_clean(SaleID);

CREATE INDEX IX_sales_clean_ProductID
ON sales_clean(ProductID);

CREATE INDEX IX_sales_clean_StoreID
ON sales_clean(StoreID);

CREATE INDEX IX_sales_clean_CustomerID
ON sales_clean(CustomerID);
CREATE INDEX IX_returns_SaleID
ON returns(SaleID);
DROP TABLE IF EXISTS sales_clean;
GO

SELECT *
INTO sales_clean
FROM vw_sales_clean;
GO

SELECT COUNT(*) AS CleanRows
FROM sales_clean;
CREATE OR ALTER VIEW vw_returns_clean AS

SELECT
    r.ReturnID,
    r.SaleID,
    r.ReturnDate,
    r.ReturnQuantity,
    r.ReturnReason
FROM returns r
INNER JOIN sales_clean s
    ON r.SaleID = s.SaleID;
GO
SELECT TOP 20 *
FROM vw_returns_clean;
SELECT COUNT(*) AS RawReturns
FROM returns;

SELECT COUNT(*) AS CleanReturns
FROM vw_returns_clean;
SELECT
    ReturnReason,
    COUNT(*) AS NumberOfReturns,
    SUM(ReturnQuantity) AS ReturnedUnits
FROM vw_returns_clean
GROUP BY ReturnReason
ORDER BY NumberOfReturns DESC;
SELECT TOP 10
    p.ProductName,
    COUNT(r.ReturnID) AS NumberOfReturns,
    SUM(r.ReturnQuantity) AS ReturnedUnits
FROM vw_returns_clean r
JOIN sales_clean s
    ON r.SaleID = s.SaleID
JOIN vw_products_clean p
    ON s.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY ReturnedUnits DESC;