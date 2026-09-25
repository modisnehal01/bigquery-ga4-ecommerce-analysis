

-- ========================================================================-- GA4 public e-commerce sample | November 2020
-- Counts all events, pseudonymous user IDs, and days with recorded events.
SELECT
  COUNT(*) AS event_count,
  COUNT(DISTINCT user_pseudo_id) AS observed_users,
  COUNT(DISTINCT event_date) AS days_with_events
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130';


-- Event distribution in the November 2020 sample.
SELECT
  event_name,
  COUNT(*) AS total_events,
  COUNT(DISTINCT user_pseudo_id) AS unique_users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
GROUP BY event_name
ORDER BY total_events DESC;


-- First-user acquisition, not session-level attribution.
-- Obfuscated placeholders can appear in source or medium.
SELECT
  COALESCE(traffic_source.source, '(not set)') AS first_user_source,
  COALESCE(traffic_source.medium, '(not set)') AS first_user_medium,
  COUNT(DISTINCT user_pseudo_id) AS observed_users,
  COUNT(DISTINCT IF(event_name = 'purchase', user_pseudo_id, NULL)) AS purchasing_users,
  COUNTIF(event_name = 'purchase') AS purchase_events,
  ROUND(
    SUM(IF(event_name = 'purchase', COALESCE(ecommerce.purchase_revenue_in_usd, 0), 0)),
    2
  ) AS purchase_revenue_usd
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
GROUP BY 1, 2
ORDER BY observed_users DESC
LIMIT 15;


-- Same-session, earliest-event ordered funnel for November 2020.
-- The first occurrence of every event type must follow the prior stage.
-- This is a conservative simplified funnel, not a full GA4 path exploration.
WITH events AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    event_name,
    event_timestamp
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
    AND event_name IN ('view_item', 'add_to_cart', 'begin_checkout', 'purchase')
    AND user_pseudo_id IS NOT NULL
),
sessions AS (
  SELECT
    user_pseudo_id,
    session_id,
    MIN(IF(event_name = 'view_item', event_timestamp, NULL)) AS view_time,
    MIN(IF(event_name = 'add_to_cart', event_timestamp, NULL)) AS cart_time,
    MIN(IF(event_name = 'begin_checkout', event_timestamp, NULL)) AS checkout_time,
    MIN(IF(event_name = 'purchase', event_timestamp, NULL)) AS purchase_time
  FROM events
  WHERE session_id IS NOT NULL
  GROUP BY 1, 2
),
funnel AS (
  SELECT
    COUNTIF(view_time IS NOT NULL) AS views,
    COUNTIF(cart_time > view_time) AS carts,
    COUNTIF(cart_time > view_time AND checkout_time > cart_time) AS checkouts,
    COUNTIF(
      cart_time > view_time
      AND checkout_time > cart_time
      AND purchase_time > checkout_time
    ) AS purchases
  FROM sessions
)
SELECT
  stage,
  session_count,
  ROUND(
    100 * SAFE_DIVIDE(session_count, LAG(session_count) OVER (ORDER BY stage_number)),
    2
  ) AS previous_stage_conversion_pct
FROM funnel,
UNNEST([
  STRUCT(1 AS stage_number, 'Product view' AS stage, views AS session_count),
  STRUCT(2, 'Add to cart', carts),
  STRUCT(3, 'Begin checkout', checkouts),
  STRUCT(4, 'Purchase', purchases)
])
ORDER BY stage_number;


-- Sessions and purchase revenue by device category, November 2020.
-- Session key combines pseudonymous user and GA4 session ID.
WITH session_events AS (
  SELECT
    device.category AS device_category,
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    event_name,
    ecommerce.purchase_revenue_in_usd AS revenue_usd
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
)
SELECT
  device_category,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(DISTINCT CONCAT(user_pseudo_id, '.', CAST(session_id AS STRING))) AS sessions,
  COUNTIF(event_name = 'purchase') AS purchases,
  COUNT(DISTINCT IF(
    event_name = 'purchase',
    CONCAT(user_pseudo_id, '.', CAST(session_id AS STRING)),
    NULL
  )) AS purchasing_sessions,
  ROUND(
    SUM(IF(event_name = 'purchase', COALESCE(revenue_usd, 0), 0)),
    2
  ) AS revenue_usd
FROM session_events
GROUP BY device_category
ORDER BY revenue_usd DESC;


-- Item-level product revenue from purchase events, November 2020.
SELECT
  item.item_name AS product_name,
  item.item_category AS category,
  SUM(COALESCE(item.quantity, 0)) AS units_sold,
  COUNT(DISTINCT user_pseudo_id) AS purchasing_users,
  ROUND(SUM(COALESCE(item.item_revenue_in_usd, 0)), 2) AS product_revenue_usd
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
UNNEST(items) AS item
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
  AND event_name = 'purchase'
  AND item.item_name IS NOT NULL
GROUP BY product_name, category
ORDER BY product_revenue_usd DESC
LIMIT 10;


-- November 2020 through January 2021: users, purchase events, revenue.
WITH monthly AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', event_date)) AS month,
    COUNT(DISTINCT user_pseudo_id) AS observed_users,
    COUNTIF(event_name = 'purchase') AS purchases,
    COUNT(DISTINCT IF(event_name = 'purchase', user_pseudo_id, NULL)) AS purchasing_users,
    ROUND(
      SUM(IF(event_name = 'purchase', COALESCE(ecommerce.purchase_revenue_in_usd, 0), 0)),
      2
    ) AS revenue_usd
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY month
)
SELECT
  month,
  observed_users,
  purchases,
  purchasing_users,
  revenue_usd,
  ROUND(100 * SAFE_DIVIDE(purchasing_users, observed_users), 2) AS purchasing_user_rate_pct
FROM monthly
ORDER BY month;


-- Share of current-month pseudonymous IDs also observed in prior month.
-- November 2020 is blank: October is outside the three-month sample.
WITH monthly_users AS (
  SELECT DISTINCT
    DATE_TRUNC(PARSE_DATE('%Y%m%d', event_date), MONTH) AS month_start,
    user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND user_pseudo_id IS NOT NULL
),
monthly_retention AS (
  SELECT
    current_month.month_start,
    COUNT(*) AS observed_users,
    COUNTIF(previous_month.user_pseudo_id IS NOT NULL) AS returning_users
  FROM monthly_users AS current_month
  LEFT JOIN monthly_users AS previous_month
    ON current_month.user_pseudo_id = previous_month.user_pseudo_id
    AND previous_month.month_start = DATE_SUB(current_month.month_start, INTERVAL 1 MONTH)
  GROUP BY current_month.month_start
)
SELECT
  FORMAT_DATE('%Y-%m', month_start) AS month,
  observed_users,
  IF(month_start = DATE '2020-11-01', NULL, returning_users) AS returning_users,
  IF(
    month_start = DATE '2020-11-01',
    NULL,
    ROUND(100 * SAFE_DIVIDE(returning_users, observed_users), 2)
  ) AS returning_user_share_pct
FROM monthly_retention
ORDER BY month_start;


-- Data-quality audit over the complete 2020-11 to 2021-01 sample.
WITH events AS (
  SELECT
    event_date,
    event_name,
    event_timestamp,
    user_pseudo_id,
    ecommerce.transaction_id AS transaction_id,
    ecommerce.purchase_revenue_in_usd AS revenue_usd,
    ARRAY_LENGTH(items) AS item_count,
    (
      SELECT ANY_VALUE(value.int_value)
      FROM UNNEST(event_params)
      WHERE key = 'ga_session_id'
    ) AS session_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),
audit AS (
  SELECT
    COUNT(*) AS total_events,
    COUNTIF(event_name IS NULL OR TRIM(event_name) = '') AS missing_event_names,
    COUNTIF(user_pseudo_id IS NULL) AS missing_user_ids,
    COUNTIF(event_timestamp IS NULL) AS missing_timestamps,
    COUNTIF(SAFE.PARSE_DATE('%Y%m%d', event_date) IS NULL) AS invalid_dates,
    COUNTIF(
      event_name = 'purchase'
      AND (transaction_id IS NULL OR TRIM(transaction_id) = '')
    ) AS purchases_missing_transaction_id,
    COUNTIF(event_name = 'purchase' AND revenue_usd < 0) AS negative_purchase_revenue,
    COUNTIF(event_name = 'purchase' AND item_count = 0) AS purchases_without_items,
    COUNTIF(
      event_name IN ('page_view', 'view_item', 'add_to_cart', 'begin_checkout', 'purchase')
      AND session_id IS NULL
    ) AS selected_events_missing_session_id
  FROM events
)
SELECT check_name, event_count
FROM audit,
UNNEST([
  STRUCT(1 AS sort_order, 'Total events' AS check_name, total_events AS event_count),
  STRUCT(2, 'Missing event names', missing_event_names),
  STRUCT(3, 'Missing visitor IDs', missing_user_ids),
  STRUCT(4, 'Missing timestamps', missing_timestamps),
  STRUCT(5, 'Invalid dates', invalid_dates),
  STRUCT(6, 'Purchases without transaction ID', purchases_missing_transaction_id),
  STRUCT(7, 'Negative purchase revenue', negative_purchase_revenue),
  STRUCT(8, 'Purchases without items', purchases_without_items),
  STRUCT(9, 'Selected events without session ID', selected_events_missing_session_id)
])
ORDER BY sort_order;
