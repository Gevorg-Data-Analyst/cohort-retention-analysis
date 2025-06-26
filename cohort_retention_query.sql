 WITH first_orders AS (
    SELECT
        playerid,
        MIN(DATE_TRUNC('month', createddate)) AS cohort_month
    FROM orders
    GROUP BY playerid
),
orders_with_cohort AS (
    SELECT
        o.playerid,
        DATE_TRUNC('month', o.createddate) AS order_month,
        f.cohort_month,
        (EXTRACT(YEAR FROM AGE(o.createddate, f.cohort_month)) * 12) +
        EXTRACT(MONTH FROM AGE(o.createddate, f.cohort_month)) AS month_index
    FROM orders o
    JOIN first_orders f ON o.playerid = f.playerid
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT playerid) AS cohort_size
    FROM first_orders
    GROUP BY cohort_month
)
SELECT
    o.cohort_month,
    o.month_index,
    COUNT(DISTINCT o.playerid) AS players_active,
    ROUND(
        COUNT(DISTINCT o.playerid)::numeric
        /
        c.cohort_size
        * 100, 2
    ) AS retention_percentage
FROM orders_with_cohort o
JOIN player p ON o.playerid = p.id
JOIN cohort_sizes c ON o.cohort_month = c.cohort_month
GROUP BY o.cohort_month, o.month_index, c.cohort_size
ORDER BY o.cohort_month, o.month_index;