-- Compare plans for one customer's newest orders. Run once for a true baseline.
-- EXPLAIN ANALYZE executes this read-only SELECT and reports measured timings.
-- User-reported measurements are documented in README.md.
-- The assistant did not execute this script or collect measurements itself.
ANALYZE orders;

-- BEFORE: on the first run, the proposed index does not yet exist.
EXPLAIN ANALYZE
SELECT order_id, ordered_at, product_id, quantity, unit_price
FROM orders
WHERE customer_id = (SELECT customer_id FROM customers WHERE email = 'mira.vale@example.com')
ORDER BY ordered_at DESC, order_id DESC
LIMIT 10;

-- Equality on customer_id followed by the requested sort order.
CREATE INDEX IF NOT EXISTS idx_orders_customer_recent
ON orders (customer_id, ordered_at DESC, order_id DESC);

ANALYZE orders;

-- AFTER: compare scan type, sort node, actual rows, and Execution Time.
EXPLAIN ANALYZE
SELECT order_id, ordered_at, product_id, quantity, unit_price
FROM orders
WHERE customer_id = (SELECT customer_id FROM customers WHERE email = 'mira.vale@example.com')
ORDER BY ordered_at DESC, order_id DESC
LIMIT 10;

-- A sequential scan may remain best for this tiny dataset. Cache effects and
-- run-to-run noise affect timings. An index adds storage and write overhead.
-- Re-running does not recreate a no-index baseline. Do not drop objects merely
-- to repeat this exercise; use a separately authorized fresh database instead.
