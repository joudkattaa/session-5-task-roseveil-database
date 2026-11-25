-- Reversible practice: all changes in this file are rolled back.
-- Identity sequence values may still advance after ROLLBACK; gaps are normal.
BEGIN;

-- CREATE: use a dedicated fictional practice record.
INSERT INTO customers (full_name, email, city)
VALUES ('Practice Shopper', 'practice.shopper@example.com', 'Istanbul')
RETURNING customer_id, full_name, email;

-- READ: filter and order explicitly.
SELECT sku, name, price, stock
FROM products
WHERE is_active AND price BETWEEN 10.00 AND 30.00
ORDER BY price, product_id;

-- UPDATE: a unique predicate limits the change to one known record.
UPDATE customers SET city = 'Izmir'
WHERE email = 'practice.shopper@example.com'
RETURNING customer_id, full_name, city;

-- DELETE: only remove the unreferenced practice customer.
DELETE FROM customers
WHERE email = 'practice.shopper@example.com'
  AND NOT EXISTS (
      SELECT 1 FROM orders WHERE orders.customer_id = customers.customer_id
  )
RETURNING customer_id, email;

ROLLBACK;

-- Expected: zero rows after rollback.
SELECT customer_id FROM customers WHERE email = 'practice.shopper@example.com';
