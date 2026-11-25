# Isolated Index Benchmark

The completed benchmark results are recorded in [README.md](../README.md); no rerun is required. This procedure reads permanent tables but creates and indexes only session-local temporary copies. Permanent data, indexes, and identity sequences remain unchanged. For reproduction, use one fresh pgAdmin Query Tool session connected to `roseveil_db`, with no transaction already open. Run the stages in order without an intervening COMMIT. The repeatable-read snapshot keeps both copies consistent. Temporary storage and physical layout can differ from permanent tables.

**Stage 1 — set up the copies and baseline indexes:**

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;

CREATE TEMP TABLE rv_bench_customers ON COMMIT DROP AS
SELECT * FROM public.customers;

CREATE TEMP TABLE rv_bench_orders ON COMMIT DROP AS
SELECT * FROM public.orders;

CREATE UNIQUE INDEX rv_bench_customers_pk
ON pg_temp.rv_bench_customers (customer_id);
CREATE UNIQUE INDEX rv_bench_customers_email_key
ON pg_temp.rv_bench_customers (email);
CREATE UNIQUE INDEX rv_bench_orders_pk
ON pg_temp.rv_bench_orders (order_id);

ANALYZE pg_temp.rv_bench_customers;
ANALYZE pg_temp.rv_bench_orders;

SELECT COUNT(*) AS copied_orders FROM pg_temp.rv_bench_orders;
```

**Stage 2 — BEFORE:** execute and save the complete plan. Keep normal planner settings.

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, ordered_at, product_id, quantity, unit_price
FROM pg_temp.rv_bench_orders
WHERE customer_id = (
    SELECT customer_id
    FROM pg_temp.rv_bench_customers
    WHERE email = 'mira.vale@example.com'
)
ORDER BY ordered_at DESC, order_id DESC
LIMIT 10;
```

**Stage 3 — create the candidate index on the temporary copy only:**

```sql
CREATE INDEX rv_bench_orders_customer_recent
ON pg_temp.rv_bench_orders (customer_id, ordered_at DESC, order_id DESC);
```

**Stage 4 — AFTER:** execute the identical Stage 2 EXPLAIN and save its plan. For a stronger future comparison, use one warm-up and five measured EXPLAIN executions at each stage; report the median and range separately for planning and execution. Do not repeat setup or index creation. Index creation can warm caches; this is not a controlled cold-cache benchmark.

**Stage 5 — finish:** after saving both sets of results, execute:

```sql
ROLLBACK;
```

This undoes temporary table/index creation. On any error, execute ROLLBACK and stop. Do not drop or disable the permanent index or change database permissions for this exercise.

PostgreSQL 16 documents session-local temporary tables and their need for explicit statistics collection in [CREATE TABLE](https://www.postgresql.org/docs/16/sql-createtable.html), and plan interpretation and measurement caveats in [Using EXPLAIN](https://www.postgresql.org/docs/16/using-explain.html).
