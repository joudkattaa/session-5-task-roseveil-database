-- Run after seed. This file intentionally commits ONE real demonstration order.
-- Run each block through its matching COMMIT/ROLLBACK. On any SQL error,
-- issue ROLLBACK before proceeding. Never commit a partially edited block.
-- Each purchase uses one conditional UPDATE feeding one INSERT atomically.
-- READ COMMITTED: concurrent UPDATEs wait for the row lock, then recheck stock
-- against the updated row. Only a qualifying UPDATE can produce an order.
-- An INSERT error also rolls back the stock change. Zero returned rows means
-- no purchase (missing customer/product, inactive product, or insufficient stock).
-- Repeatable-read/serializable callers must retry the whole transaction on
-- serialization failure; this demonstration explicitly uses READ COMMITTED.

-- A. Successful purchase: after fresh seed, stock 60 -> 58; orders 12 -> 13.
SELECT sku, stock FROM products WHERE sku = 'RV-M01';
SELECT COUNT(*) AS order_count_before FROM orders;

BEGIN ISOLATION LEVEL READ COMMITTED;
WITH reduced_stock AS (
    UPDATE products
    SET stock = stock - 2
    WHERE sku = 'RV-M01' AND is_active AND stock >= 2
      AND EXISTS (SELECT 1 FROM customers WHERE email = 'mira.vale@example.com')
    RETURNING product_id, price
)
INSERT INTO orders (customer_id, product_id, quantity, unit_price)
SELECT c.customer_id, s.product_id, 2, s.price
FROM reduced_stock s
CROSS JOIN customers c
WHERE c.email = 'mira.vale@example.com'
RETURNING order_id, product_id, quantity, unit_price;
COMMIT;

SELECT sku, stock FROM products WHERE sku = 'RV-M01';
SELECT COUNT(*) AS order_count_after FROM orders;
SELECT o.order_id, o.quantity, o.unit_price FROM orders o
JOIN products p ON p.product_id = o.product_id
WHERE p.sku = 'RV-M01' ORDER BY o.order_id DESC;

-- B. Canceled purchase: compare these before/after values.
SELECT sku, stock FROM products WHERE sku = 'RV-S01';
SELECT COUNT(*) AS order_count_before_cancel FROM orders;

BEGIN ISOLATION LEVEL READ COMMITTED;
WITH reduced_stock AS (
    UPDATE products
    SET stock = stock - 1
    WHERE sku = 'RV-S01' AND is_active AND stock >= 1
      AND EXISTS (SELECT 1 FROM customers WHERE email = 'lina.rowan@example.com')
    RETURNING product_id, price
)
INSERT INTO orders (customer_id, product_id, quantity, unit_price)
SELECT c.customer_id, s.product_id, 1, s.price
FROM reduced_stock s CROSS JOIN customers c
WHERE c.email = 'lina.rowan@example.com'
RETURNING order_id, quantity, unit_price;
-- Visible inside the transaction, but canceled below.
SELECT sku, stock FROM products WHERE sku = 'RV-S01';
ROLLBACK;

-- Expected: same stock and order count as before block B.
SELECT sku, stock FROM products WHERE sku = 'RV-S01';
SELECT COUNT(*) AS order_count_after_cancel FROM orders;

-- C. Insufficient stock: RV-B06 starts at zero. Expected: INSERT returns no rows.
BEGIN ISOLATION LEVEL READ COMMITTED;
WITH reduced_stock AS (
    UPDATE products SET stock = stock - 1
    WHERE sku = 'RV-B06' AND is_active AND stock >= 1
      AND EXISTS (SELECT 1 FROM customers WHERE email = 'mira.vale@example.com')
    RETURNING product_id, price
)
INSERT INTO orders (customer_id, product_id, quantity, unit_price)
SELECT c.customer_id, s.product_id, 1, s.price
FROM reduced_stock s CROSS JOIN customers c
WHERE c.email = 'mira.vale@example.com'
RETURNING order_id;
SELECT sku, stock FROM products WHERE sku = 'RV-B06';
ROLLBACK;

-- Expected: both counts are zero. These checks do not test concurrency itself.
SELECT COUNT(*) AS negative_stock_rows FROM products WHERE stock < 0;
SELECT COUNT(*) AS invalid_order_rows FROM orders
WHERE quantity <= 0 OR unit_price < 0;
