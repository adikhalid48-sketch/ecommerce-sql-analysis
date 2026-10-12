-- ==========================================
-- E-COMMERCE SQL ANALYSIS (PostgreSQL)
-- Tables: categories, customers, products, orders, order_items
-- ==========================================

-- IMPORTING ALL TABLES INTO POSTGRESQL

-- CATEGORIES TABLE
CREATE TABLE categories (
    CategoryID INT PRIMARY KEY,
    CategoryName VARCHAR(50)
);

-- CUSTOMERS TABLE
CREATE TABLE customers (
    CustomerID INT PRIMARY KEY,
    Name VARCHAR(100),
    Email VARCHAR(100),
    Phone BIGINT,
    Address VARCHAR(150),
    City VARCHAR(50),
    Country VARCHAR(50)
);

-- PRODUCTS TABLE
CREATE TABLE products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(100),
    CategoryID INT REFERENCES categories(CategoryID),
    Price INT,
    Stock INT
);

-- ORDERS TABLE
CREATE TABLE orders (
    OrderID INT PRIMARY KEY,
    CustomerID INT REFERENCES customers(CustomerID),
    OrderDate DATE,
    TotalAmount INT
);

-- ORDER_ITEMS TABLE
CREATE TABLE order_items (
    OrderItemID INT PRIMARY KEY,
    OrderID INT REFERENCES orders(OrderID),
    ProductID INT REFERENCES products(ProductID),
    Quantity INT,
    SubTotal INT
);

-- NOTE: change the folder path below to wherever your CSV files are saved
COPY categories FROM 'D:/random small dataset/categories.csv' CSV HEADER;
COPY customers FROM 'D:/random small dataset/customers.csv' CSV HEADER;
COPY products FROM 'D:/random small dataset/products.csv' CSV HEADER;
COPY orders FROM 'D:/random small dataset/orders.csv' CSV HEADER;
COPY order_items FROM 'D:/random small dataset/order_items.csv' CSV HEADER;


-- VIEW ALL THE TABLES
SELECT * FROM categories;
SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM orders;
SELECT * FROM order_items;


-- ==========================================
-- QUERIES AND THEIR SOLUTIONS
-- ==========================================

-- SECTION 1: BASIC QUERIES (FILTERING AND AGGREGATION)

--1.List the name and email of all customers living in Delhi.
SELECT name, email
FROM customers
WHERE city = 'Delhi';

--2.Show all products priced above ₹5,000, most expensive first.
SELECT *
FROM products
WHERE price > 5000
ORDER BY price DESC;

--3.What's the total number of orders, total revenue, and average order value?
SELECT COUNT(*) AS total_orders,
SUM(totalamount) AS total_revenue,
ROUND(AVG(totalamount), 2) AS avg_order_value
FROM orders;

--4.How many customers do we have per city? Highest first.
SELECT city,
COUNT(*) AS total_customers
FROM customers
GROUP BY city
ORDER BY total_customers DESC, city;

--5.Which orders were placed in the first week of September (1st to 7th)?
SELECT *
FROM orders
WHERE orderdate >= '2025-09-01' AND orderdate < '2025-09-08';


-- SECTION 2: JOINS AND GROUPING

--6.Show every product with its category name.
SELECT p.productname,
c.categoryname
FROM products p
INNER JOIN categories c
USING(categoryid);

--7.For each category, how many products do we carry and what's the average price?
SELECT c.categoryname,
COUNT(*) AS number_of_products,
ROUND(AVG(p.price), 2) AS avg_price
FROM categories c
INNER JOIN products p
USING(categoryid)
GROUP BY c.categoryid, c.categoryname;

--8.Show each order with the customer's name and city.
SELECT o.orderid,
c.name,
c.city
FROM orders o
INNER JOIN customers c
USING(customerid);

--9.What are the top 5 products by total quantity sold?
-- (tie-breaker on product name so ties at 3 units give a stable result)
SELECT p.productname,
SUM(oi.quantity) AS total_quantity
FROM order_items oi
INNER JOIN products p
USING(productid)
GROUP BY p.productid, p.productname
ORDER BY total_quantity DESC, p.productname
LIMIT 5;

--10.Which category brings in the most revenue? Use the order_items subtotals.
SELECT c.categoryname,
SUM(oi.subtotal) AS total_revenue
FROM order_items oi
INNER JOIN products p
USING(productid)
INNER JOIN categories c
USING(categoryid)
GROUP BY c.categoryid, c.categoryname
ORDER BY total_revenue DESC;

--11.Which products have never been sold?
SELECT p.productid,
p.productname
FROM products p
LEFT JOIN order_items oi
USING(productid)
WHERE oi.orderitemid IS NULL;

--12.Which orders have no items attached to them?
SELECT o.orderid, o.customerid, o.orderdate, o.totalamount
FROM orders o
LEFT JOIN order_items oi
USING(orderid)
WHERE oi.orderitemid IS NULL;


-- SECTION 3: SUBQUERIES, CASE WHEN AND HAVING

--13.Which customers placed an order above the average order value? Show name and amount.
SELECT c.name, o.totalamount
FROM customers c
INNER JOIN orders o
USING(customerid)
WHERE o.totalamount > (SELECT AVG(totalamount) FROM orders)
ORDER BY o.totalamount DESC;

--14.Bucket orders into Small (< ₹5,000), Medium (₹5,000 to ₹50,000), and Large (> ₹50,000). Show order count and revenue per bucket.
SELECT
    CASE
        WHEN totalamount < 5000 THEN 'Small'
        WHEN totalamount BETWEEN 5000 AND 50000 THEN 'Medium'
        ELSE 'Large'
    END AS bucket,
    COUNT(*) AS order_count,
    SUM(totalamount) AS total_revenue
FROM orders
GROUP BY bucket
ORDER BY MIN(totalamount);

--15.Stock value is Price * Stock. Which categories have a total stock value above ₹5,00,000?
SELECT c.categoryname,
SUM(p.price * p.stock) AS stock_value
FROM products p
INNER JOIN categories c
USING(categoryid)
GROUP BY c.categoryid, c.categoryname
HAVING SUM(p.price * p.stock) > 500000
ORDER BY stock_value DESC;


-- SECTION 4: ADVANCED ANALYTICS (CTEs AND WINDOW FUNCTIONS)

--16.Find orders where TotalAmount doesn't match the sum of that order's item subtotals. Show both numbers and the difference. Decide what to do with orders that have no items.
-- LEFT JOIN keeps orders with no items; COALESCE turns their NULL sum into 0
SELECT o.orderid,
o.totalamount,
COALESCE(SUM(oi.subtotal), 0) AS sum_of_subtotals,
o.totalamount - COALESCE(SUM(oi.subtotal), 0) AS difference
FROM orders o
LEFT JOIN order_items oi
USING(orderid)
GROUP BY o.orderid, o.totalamount
HAVING o.totalamount <> COALESCE(SUM(oi.subtotal), 0)
ORDER BY o.orderid;

--17.For each category, which product sold the highest quantity?
-- RANK() keeps ties (Electronics has a tie: iPhone 15 and Laptop Dell XPS at 3 units)
-- Use ROW_NUMBER() with a tie-breaker if exactly one row per category is needed
WITH product_sales AS (
    SELECT c.categoryid,
    c.categoryname,
    p.productid,
    p.productname,
    SUM(oi.quantity) AS total_quantity
    FROM order_items oi
    INNER JOIN products p
    USING(productid)
    INNER JOIN categories c
    USING(categoryid)
    GROUP BY c.categoryid, c.categoryname, p.productid, p.productname
),
ranked AS (
    SELECT *,
    RANK() OVER (PARTITION BY categoryid ORDER BY total_quantity DESC) AS rnk
    FROM product_sales
)
SELECT categoryname, productname, total_quantity
FROM ranked
WHERE rnk = 1;

--18.Show daily revenue with a running total by date.
SELECT orderdate,
SUM(totalamount) AS daily_revenue,
SUM(SUM(totalamount)) OVER (ORDER BY orderdate) AS running_total
FROM orders
GROUP BY orderdate
ORDER BY orderdate;

--19.Rank customers by total spend and show each one's percentage share of overall revenue.
WITH customer_spend AS (
    SELECT c.customerid,
    c.name,
    SUM(o.totalamount) AS total_spend
    FROM customers c
    INNER JOIN orders o
    USING(customerid)
    GROUP BY c.customerid, c.name
)
SELECT name,
total_spend,
RANK() OVER (ORDER BY total_spend DESC) AS spend_rank,
ROUND(total_spend * 100.0 / SUM(total_spend) OVER (), 2) AS revenue_share_pct
FROM customer_spend
ORDER BY spend_rank;

--20.For each city, which category generates the most revenue? (This one touches all 5 tables.)
WITH city_category AS (
    SELECT cu.city,
    ca.categoryname,
    SUM(oi.subtotal) AS revenue
    FROM customers cu
    INNER JOIN orders o USING(customerid)
    INNER JOIN order_items oi USING(orderid)
    INNER JOIN products p USING(productid)
    INNER JOIN categories ca USING(categoryid)
    GROUP BY cu.city, ca.categoryid, ca.categoryname
),
ranked AS (
    SELECT *,
    RANK() OVER (PARTITION BY city ORDER BY revenue DESC) AS rnk
    FROM city_category
)
SELECT city, categoryname, revenue
FROM ranked
WHERE rnk = 1;
