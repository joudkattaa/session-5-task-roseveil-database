-- INNER JOIN: each order is a single product type; use historical unit_price.
SELECT o.order_id, c.full_name, p.name AS product, o.quantity,
       o.unit_price, o.quantity * o.unit_price AS line_total, o.ordered_at
FROM orders o
INNER JOIN customers c ON c.customer_id = o.customer_id
INNER JOIN products p ON p.product_id = o.product_id
ORDER BY o.ordered_at DESC, o.order_id DESC;

-- LEFT JOIN: include customers who have never purchased.
SELECT c.customer_id, c.full_name, COUNT(o.order_id) AS order_count,
       COALESCE(SUM(o.quantity * o.unit_price), 0) AS total_spent
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY total_spent DESC, c.customer_id;

-- GROUP BY and aggregates: category inventory, including empty categories.
SELECT c.category_id, c.name, COUNT(p.product_id) AS product_count,
       MIN(p.price) AS lowest_price, MAX(p.price) AS highest_price,
       ROUND(AVG(p.price), 2) AS average_price,
       COALESCE(SUM(p.stock), 0) AS units_in_stock,
       COALESCE(SUM(p.price * p.stock), 0) AS inventory_retail_value
FROM categories c
LEFT JOIN products p ON p.category_id = c.category_id
GROUP BY c.category_id, c.name
ORDER BY c.category_id;

-- HAVING filters groups after aggregation.
SELECT p.product_id, p.name, SUM(o.quantity) AS units_sold,
       SUM(o.quantity * o.unit_price) AS sales_value
FROM products p
INNER JOIN orders o ON o.product_id = p.product_id
GROUP BY p.product_id, p.name
HAVING SUM(o.quantity) >= 2
ORDER BY units_sold DESC, p.product_id;

-- Page 1 and page 2: the unique ID breaks price ties deterministically.
-- Concurrent changes can shift OFFSET pages; these are learning examples.
SELECT product_id, sku, name, price FROM products
WHERE is_active ORDER BY price, product_id LIMIT 10 OFFSET 0;

SELECT product_id, sku, name, price FROM products
WHERE is_active ORDER BY price, product_id LIMIT 10 OFFSET 10;
