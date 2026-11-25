# ROSEVEIL Cosmetics Database

A Session 5 academic project modeling a fictional cosmetics store with PostgreSQL 16 and plain SQL. Four related tables demonstrate relational design, constraints, CRUD, analytical queries, transactions, and index evaluation. No application framework or additional dependencies are required.

## Requirements and execution

In pgAdmin, connect to the existing **roseveil_db** and confirm with `SELECT current_database();`. For an initial installation, run the following complete files in order using Query Tool. Do not wrap them in an additional transaction.

| Requirement | Script | Coverage |
| --- | --- | --- |
| 1. Schema | [01_schema.sql](sql/01_schema.sql) | Four tables; primary/foreign keys; NOT NULL, UNIQUE, CHECK, defaults, and deletion rules |
| 2. Seed data | [02_seed.sql](sql/02_seed.sql) | 4 categories, 32 products, 8 fictional customers, and 12 historical orders |
| 3. CRUD | [03_crud.sql](sql/03_crud.sql) | INSERT, SELECT, targeted UPDATE, and guarded DELETE; practice changes rolled back |
| 4. Advanced queries | [04_advanced_queries.sql](sql/04_advanced_queries.sql) | INNER/LEFT JOIN, GROUP BY, aggregate functions, HAVING, and LIMIT/OFFSET with deterministic ordering |
| 5. Transactions | [05_transactions.sql](sql/05_transactions.sql) | Atomic purchase with COMMIT, canceled purchase with ROLLBACK, insufficient-stock example, and verification queries |
| 6. Index evaluation | [06_indexes.sql](sql/06_indexes.sql) | Matching EXPLAIN ANALYZE queries before and after a composite index |

Schema and seed scripts run once in a schema without conflicting objects; they are not reset scripts. File 05 commits one purchase on each successful run. File 06 provides a true no-index baseline only before its index exists. Do not rerun these files against the verified database to recreate evidence. If an error aborts a transaction, issue `ROLLBACK;` and inspect the cause before continuing.

Use the existing pgAdmin connection; keep passwords out of project files. The scripts do not create or drop databases, drop tables, or truncate data. `.gitignore` excludes common credentials and unnecessary local files.

## Database structure and design

| Table | Purpose | Main rules |
| --- | --- | --- |
| categories | Makeup, Skincare, Perfume, Beauty Tools | Unique required name |
| products | Catalog, current USD price, and stock | Unique SKU; required category; nonnegative price and stock |
| customers | Fictional shoppers | Required name; unique trimmed lowercase email with a basic format check |
| orders | Purchase of one product type | Required customer/product; positive integer quantity; nonnegative purchase-time unit price |

All tables use generated integer primary keys. Required columns, CHECK constraints, and appropriate defaults enforce valid records. Money uses exact `NUMERIC(10,2)` values; numeric NaN is rejected. Timestamps use `TIMESTAMPTZ`. Customer records are fictional and use example.com addresses.

An order stores one product type; purchasing different products produces separate orders. Its stored unit price preserves purchase history when catalog prices change. Totals are calculated as `quantity * unit_price`. Foreign keys use `ON DELETE RESTRICT` to preserve references; products can be retired with `is_active = FALSE`. Historical seed orders are accompanied by current stock balances that already account for those purchases.

Purchases use a conditional stock UPDATE feeding an INSERT through `RETURNING`. At READ COMMITTED, competing updates lock the product row and recheck available stock after waiting. An insert failure also undoes the stock reduction; zero returned rows means no purchase. New purchases must follow this pattern: arbitrary direct order inserts do not automatically reduce stock. Rolled-back identity allocations can leave normal sequence gaps.

See the [Mermaid ER diagram and detailed design rationale](docs/erd.md).

## SQL examples

Available catalog:

```sql
SELECT sku, name, price, stock
FROM products
WHERE is_active AND stock > 0
ORDER BY name, product_id;
```

Historical purchase values:

```sql
SELECT o.order_id, c.full_name, p.name,
       o.quantity * o.unit_price AS purchase_total
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN products p ON p.product_id = o.product_id
ORDER BY o.order_id;
```

## Verification results

I manually executed all six SQL scripts in pgAdmin using PostgreSQL 16. I confirmed that all four tables were created, inspected the seed products, ran the CRUD and advanced queries, and checked the recorded stock, order totals, and index validity. I also completed the isolated temporary-table index benchmark, recorded its BEFORE and AFTER execution plans, and successfully executed the final ROLLBACK.

| Check | Recorded result |
| --- | --- |
| RV-M01 stock | 58 |
| RV-S01 stock | 65 |
| Total orders | 13 |
| Invalid order rows | 0 |
| idx_orders_customer_recent | Exists; validity check returned true |
| Original permanent-table EXPLAIN | Planning: 0.352 ms; execution: 0.102 ms |
| Original customer access | Index Scan using customers_email_key |
| Original order access | Sequential Scan; 4 matching rows, 9 filtered rows |
| Isolated benchmark cleanup | Final ROLLBACK completed successfully |

The stock and order totals match the expected committed and canceled purchase outcomes after one transaction-script run. Current state supports those outcomes without independently reconstructing transaction history. Exact category/customer counts, a separate negative-stock count, an explicit canceled-customer/product order count, and concurrent-purchase execution were not separately reported. Concurrency protection was reviewed in the SQL rather than demonstrated in a concurrent execution test.

## Index benchmark

The composite index `(customer_id, ordered_at DESC, order_id DESC)` supports customer-history filtering and newest-first ordering. The isolated benchmark compared the same query on temporary copies with equivalent baseline indexes, before and after adding the candidate orders index. Permanent data, indexes, and identity sequences were unchanged. The original permanent-table timing above is a separate observation, not this benchmark's baseline.

| Metric | BEFORE candidate index | AFTER candidate index |
| --- | --- | --- |
| Planning Time | 0.357 ms | 9.298 ms |
| Execution Time | 0.068 ms | 0.058 ms |
| Customer scan | Sequential Scan | Sequential Scan |
| Order scan | Sequential Scan | Sequential Scan |
| Matching / filtered order rows | 4 / 9 | 4 / 9 |
| Buffers | local hit=2 | local hit=2 |
| Sort method / memory | quicksort / 25 kB | quicksort / 25 kB |

Both plans used sequential scans and sorting; the candidate index was unused. Reading a 13-row orders table directly can be cheaper than traversing an index and fetching table rows. PostgreSQL chooses the estimated cheapest plan, not necessarily an available index. Local buffer hits describe temporary-table access.

Execution time was 0.010 ms lower after index creation, while planning time increased. **A single measurement pair proves neither an improvement nor a repeatable regression.** Caching, timing noise, and planning overhead may affect the observations; the planning-time difference has no established cause. No repeated-run statistics were supplied, and these results do not establish performance at larger scale or on permanent storage. Indexes also require storage and add write overhead.

The complete SQL procedure is in [Isolated Index Benchmark](docs/index-benchmark.md). Measurement guidance is available in PostgreSQL 16's [Using EXPLAIN](https://www.postgresql.org/docs/16/using-explain.html).

## AI Assistance

I used AI assistance for database design, SQL implementation, documentation, local file checks, and code review. I personally executed the scripts in pgAdmin, inspected the database records and query results, checked the transaction outcomes, and collected the actual EXPLAIN ANALYZE measurements documented above.

I compared my observations with the expected behavior and retained the testing limitations in this README. Concurrent-purchase behavior was reviewed in the SQL but was not tested through concurrent execution. The AI did not connect to PostgreSQL, execute the SQL scripts or benchmark, or independently reproduce my measurements.
