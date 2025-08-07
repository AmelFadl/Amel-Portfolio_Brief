--  Table Counts: Data Distribution
SELECT 'Productlines' AS Table_Name, COUNT(*) AS Row_Count FROM Productlines
UNION ALL SELECT 'Products', COUNT(*) FROM Products
UNION ALL SELECT 'Offices', COUNT(*) FROM Offices
UNION ALL SELECT 'Employees', COUNT(*) FROM Employees
UNION ALL SELECT 'Customers', COUNT(*) FROM Customers
UNION ALL SELECT 'Payments', COUNT(*) FROM Payments
UNION ALL SELECT 'Orders', COUNT(*) FROM Orders
UNION ALL SELECT 'Orderdetails', COUNT(*) FROM Orderdetails;

--  Manager Summary View
CREATE OR REPLACE VIEW ManagerSummary AS
SELECT
  CONCAT(m.firstName, ' ', m.lastName) AS Manager_Name,
  m.officeCode AS Office_Number,
  COUNT(e.employeeNumber) AS Employee_Count,
  o.country AS Country
FROM employees m
JOIN employees e ON e.reportsTo = m.employeeNumber
JOIN offices o ON m.officeCode = o.officeCode
GROUP BY m.employeeNumber, m.officeCode, o.country, m.firstName, m.lastName;

--  Customer Information View
CREATE OR REPLACE VIEW CustomerInfo AS
SELECT
  c.customerName AS Customer_Name,
  CONCAT_WS(', ',
    c.addressLine1,
    NULLIF(c.addressLine2, ''),
    NULLIF(c.postalCode, ''),
    c.city,
    c.country
  ) AS Address,
  CONCAT(rep.firstName, ' ', rep.lastName) AS Employee_Name,
  CONCAT(mgr.firstName, ' ', mgr.lastName) AS Manager_Name,
  c.country AS Country,
  c.city AS City,
  CONCAT(c.contactFirstName, ' ', c.contactLastName) AS Contact_Name,
  CONCAT('(', SUBSTRING(c.phone, 1, 3), ') ',
    SUBSTRING(c.phone, 4, 3), ' ',
    SUBSTRING(c.phone, 7, 4)) AS Formatted_Phone
FROM customers c
LEFT JOIN employees rep ON c.salesRepEmployeeNumber = rep.employeeNumber
LEFT JOIN employees mgr ON rep.reportsTo = mgr.employeeNumber;

--  Stored Procedure: Monthly Shipping Summary
DROP PROCEDURE IF EXISTS GetMonthlyShippingSummary;
DELIMITER //
CREATE PROCEDURE GetMonthlyShippingSummary()
BEGIN
  SELECT
    DATE_FORMAT(requiredDate, '%Y-%m') AS Month,
    COUNT(CASE WHEN status = 'Cancelled' THEN 1 END) AS Cancelled,
    COUNT(CASE WHEN status != 'Cancelled' AND shippedDate = requiredDate THEN 1 END) AS OnTime,
    COUNT(CASE WHEN status != 'Cancelled' AND shippedDate < requiredDate THEN 1 END) AS Early,
    COUNT(CASE WHEN status != 'Cancelled' AND shippedDate > requiredDate THEN 1 END) AS Late
  FROM orders
  GROUP BY DATE_FORMAT(requiredDate, '%Y-%m');
END //
DELIMITER ;

-- Customer Ranking View (2003–2005 period)
CREATE OR REPLACE VIEW CustomerRanking AS
SELECT
  c.customerNumber,
  c.customerName,
  SUM(CASE WHEN o.status != 'Cancelled' THEN od.quantityOrdered * od.priceEach ELSE 0 END) AS TotalShippedValue,
  COUNT(CASE WHEN o.status != 'Cancelled' THEN 1 END) AS ShippedOrders,
  COUNT(CASE WHEN o.status = 'Cancelled' THEN 1 END) AS CancelledOrders,
  CASE
    WHEN COUNT(CASE WHEN o.status = 'Cancelled' THEN 1 END) > COUNT(CASE WHEN o.status != 'Cancelled' THEN 1 END) THEN 'YELLOW'
    WHEN SUM(CASE WHEN o.status != 'Cancelled' THEN od.quantityOrdered * od.priceEach ELSE 0 END) >= 100000 THEN 'VIP'
    WHEN SUM(CASE WHEN o.status != 'Cancelled' THEN od.quantityOrdered * od.priceEach ELSE 0 END) >= 50000 THEN 'GOLD'
    WHEN SUM(CASE WHEN o.status != 'Cancelled' THEN od.quantityOrdered * od.priceEach ELSE 0 END) >= 20000 THEN 'SILVER'
    ELSE 'BRONZE'
  END AS RankCategory
FROM customers c
JOIN orders o ON c.customerNumber = o.customerNumber
JOIN orderdetails od ON o.orderNumber = od.orderNumber
WHERE o.orderDate BETWEEN '2003-01-01' AND '2005-12-31'
GROUP BY c.customerNumber, c.customerName;

-- Full Order Lifecycle View
CREATE OR REPLACE VIEW CustomerOrderSummary AS
SELECT
  CONCAT_WS(' - ', c.customerName, CONCAT_WS(' ', c.contactFirstName, c.contactLastName)) AS Customer_FullName,
  c.customerNumber,
  o.orderNumber,
  o.orderDate,
  o.requiredDate,
  o.shippedDate,
  od.orderLineNumber,
  p.productName,
  pl.productLine,
  od.quantityOrdered,
  od.priceEach,
  od.quantityOrdered * od.priceEach AS LineTotal,
  CONCAT('Customer ', c.customerName, ' #', c.customerNumber, ' has ',
    COALESCE((SELECT COUNT(*) FROM orders o1 WHERE o1.customerNumber = c.customerNumber AND o1.status = 'Shipped'), 0), ' orders shipped, ',
    COALESCE((SELECT COUNT(*) FROM orders o2 WHERE o2.customerNumber = c.customerNumber AND o2.status = 'Cancelled'), 0), ' orders cancelled, ',
    COALESCE((SELECT COUNT(*) FROM orders o3 WHERE o3.customerNumber = c.customerNumber AND o3.status = 'In Process'), 0), ' orders waiting to be shipped, ',
    'total amount spent ', FORMAT(COALESCE((SELECT SUM(od1.quantityOrdered * od1.priceEach)
      FROM orders o4
      JOIN orderdetails od1 ON o4.orderNumber = od1.orderNumber
      WHERE o4.customerNumber = c.customerNumber AND o4.status = 'Shipped'), 0), 2), ', total amount due ',
    FORMAT(COALESCE((SELECT SUM(od2.quantityOrdered * od2.priceEach)
      FROM orders o5
      JOIN orderdetails od2 ON o5.orderNumber = od2.orderNumber
      WHERE o5.customerNumber = c.customerNumber AND o5.status = 'In Process'), 0), 2)
  ) AS Note
FROM customers c
JOIN orders o ON c.customerNumber = o.customerNumber
JOIN orderdetails od ON o.orderNumber = od.orderNumber
JOIN products p ON od.productCode = p.productCode
JOIN productlines pl ON p.productLine = pl.productLine;

-- Inventory Snapshot Query
SELECT
  p.productCode,
  p.productName,
  p.quantityInStock,
  p.buyPrice,
  p.MSRP,
  ROUND(p.MSRP - p.buyPrice, 2) AS Margin,
  ROUND(((p.MSRP - p.buyPrice) / p.buyPrice) * 100, 2) AS MarginPercent,
  COALESCE((
    SELECT ROUND(SUM(od.quantityOrdered) / 3, 2)
    FROM orderdetails od
    JOIN orders o ON od.orderNumber = o.orderNumber
    WHERE od.productCode = p.productCode AND o.orderDate >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
  ), 0) AS AvgMonthlyConsumption,
  CASE
    WHEN p.quantityInStock < (
      SELECT SUM(od.quantityOrdered) / 3
      FROM orderdetails od
      JOIN orders o ON od.orderNumber = o.orderNumber
      WHERE od.productCode = p.productCode AND o.orderDate >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
    ) THEN 'LOW STOCK'
    ELSE 'OK'
  END AS StockStatus
FROM products p;

-- Function: TotalPriceFun
DROP FUNCTION IF EXISTS TotalPriceFun;
DELIMITER //
CREATE FUNCTION TotalPriceFun(orderNum INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
  DECLARE total DECIMAL(10,2);
  SELECT SUM(quantityOrdered * priceEach)
  INTO total
  FROM orderdetails
  WHERE orderNumber = orderNum;
  RETURN total;
END //
DELIMITER ;

-- Function: ProductMarginFun
DROP FUNCTION IF EXISTS ProductMarginFun;
DELIMITER //
CREATE FUNCTION ProductMarginFun(prodCode VARCHAR(15))
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
  DECLARE margin DECIMAL(10,2);
  SELECT ROUND(((MSRP - buyPrice) / buyPrice) * 100, 2)
  INTO margin
  FROM products
  WHERE productCode = prodCode;
  RETURN margin;
END //
DELIMITER ;

-- Function: OrderMarginFun
DROP FUNCTION IF EXISTS OrderMarginFun
DELIMITER //
CREATE FUNCTION OrderMarginFun(orderNum INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
  DECLARE profit DECIMAL(10,2);
  SELECT SUM((od.priceEach - p.buyPrice) * od.quantityOrdered)
  INTO profit
  FROM orderdetails od
  JOIN products p ON od.productCode = p.productCode
  WHERE od.orderNumber = orderNum;
  RETURN profit;
END //
DELIMITER ;

-- Stored PROCEDURE: CreateCustomer360ViewByYear
DROP PROCEDURE IF EXISTS CreateCustomer360ViewByYear;
DELIMITER $$

CREATE PROCEDURE CreateCustomer360ViewByYear(IN reportYear INT)
BEGIN

  
  DROP TEMPORARY TABLE IF EXISTS customer_360_view;

  
  CREATE TEMPORARY TABLE customer_360_view AS
  SELECT

   
    c.customerName,

   
    CONCAT_WS(CHAR(13),
      c.addressLine1,
      COALESCE(c.addressLine2, ''),
      c.city,
      COALESCE(c.state, ''),
      COALESCE(c.postalCode, ''),
      c.country
    ) AS customerInfo,

    
    QUARTER(o.orderDate) AS orderQuarter,

    
    o.status AS orderStatus,

    
    COUNT(DISTINCT o.orderNumber) AS totalOrders,

   
    SUM(od.quantityOrdered * od.priceEach) AS totalOrderValue,

    
    SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS profit,

    
    CONCAT_WS(', ',
      CONCAT(e.firstName, ' ', e.lastName),
      CONCAT('Emp#: ', e.employeeNumber),
      CONCAT('City: ', o2.city),
      CONCAT('Office: ', o2.officeCode)
    ) AS salesRepInfo,

    
    (
      SELECT p2.productName
      FROM orders o2
      JOIN orderdetails od2 ON o2.orderNumber = od2.orderNumber
      JOIN products p2 ON od2.productCode = p2.productCode
      WHERE o2.customerNumber = c.customerNumber
        AND YEAR(o2.orderDate) = reportYear
      GROUP BY p2.productCode
      ORDER BY SUM(od2.quantityOrdered * od2.priceEach) DESC, p2.productCode ASC
      LIMIT 1
    ) AS topProduct

  FROM customers c
  JOIN orders o ON c.customerNumber = o.customerNumber
  JOIN orderdetails od ON o.orderNumber = od.orderNumber
  JOIN products p ON od.productCode = p.productCode
  LEFT JOIN employees e ON c.salesRepEmployeeNumber = e.employeeNumber
  LEFT JOIN offices o2 ON e.officeCode = o2.officeCode

  WHERE YEAR(o.orderDate) = reportYear

  GROUP BY c.customerNumber, orderQuarter, o.status;

END$$

DELIMITER ;

-- CALL CreateCustomer360ViewByYear(2005);
-- SELECT * FROM customer_360_view;
