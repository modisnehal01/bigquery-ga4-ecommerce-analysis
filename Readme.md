# GA4 E-commerce Analytics | Google BigQuery SQL

**GoogleSQL · GA4 event export · Customer acquisition · Purchase funnel · Product analytics · Returning-user analysis**

## Project overview

This project analyses Google's **public, obfuscated Google Merchandise Store GA4 BigQuery dataset**, covering **November 2020–January 2021**. Nine GoogleSQL queries explore visitor behaviour, first-user acquisition, an ordered e-commerce purchase funnel, device performance, top products, monthly revenue, repeat visits and data quality. Results in this repository are actual BigQuery CSV exports from the analysis.

**Data source:** [Google's official public GA4 e-commerce sample](https://developers.google.com/analytics/bigquery/web-ecommerce-demo-dataset) — `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`.

## Business questions

- Which website events are most frequent, and how many pseudonymous visitor IDs were observed?
- Which first-user sources are associated with purchasers and purchase revenue?
- How many observed sessions progress through product view, cart, checkout and purchase?
- Which devices and products account for recorded purchase revenue?
- How did observed users and revenue change across the three months?
- What share of each month's visitor IDs had also appeared in the previous month?
- What data-quality exceptions affect the analysis?

## Key results

Period | Observed user IDs | Purchase events | Purchasing user IDs | Purchase revenue |
|---|---:|---:|---:|---:|
| November 2020 | 79,421 | 2,054 | 1,532 | $144,260 |
| December 2020 | 104,315 | 2,434 | 1,975 | $160,555 |
| January 2021 | 94,790 | 1,204 | 1,069 | $57,350 |

November recorded **1,472,712 events** and **79,421 pseudonymous visitor IDs** across **30 days**.

![Monthly purchase revenue](chart_monthly_purchase_revenue.png)

## Selected findings

**Acquisition.** The `google / organic` first-user source/medium group contains **30,440 observed visitor IDs** and **$37,360 in purchase revenue** in November 2020. This is *first-user acquisition*, not attribution of purchases to their most recent session.

**Purchase funnel.** The simplified ordered same-session funnel records **25,943 product-view sessions**, **1,917 add-to-cart sessions** (**7.39%** of product-view sessions), **740 checkout sessions** and **366 purchase sessions**. It requires the earliest event of each type to follow the preceding stage; it is *not* the count of all purchases.

![Same-session ordered purchase funnel](chart_ordered_purchase_funnel.png)

**Device performance.** Desktop contributes **$79,289** of November purchase revenue; mobile contributes **$62,087**. Comparing purchasing sessions with total observed sessions provides additional context beyond revenue alone.

![Purchase revenue by device](chart_device_revenue.png)

**Products.** The highest-revenue item in this sample is **Google Zip Hoodie F/C** with **$6,564** in item-level revenue and **128 units** recorded in purchase events.

![Top products](chart_top_products.png)

**Returning visitors.** **4,651** December visitor IDs were also observed in November (**4.46%** of December's visitor IDs). In January, **3,209** IDs were also observed in December (**3.39%** of January's visitor IDs). These are month-to-month returning-user shares, not conventional prior-cohort retention rates.

**Data quality.** An audit of **4,295,584 events** across all three months finds **23 purchase events without transaction IDs** and **2 purchases without item records**. Other checks in the audit return zero issues; see [the full audit](09_data_quality.csv).

## SQL techniques demonstrated

`UNNEST` on nested GA4 event parameters and item arrays; common table expressions; `COUNT(DISTINCT)`; conditional aggregation; `SAFE_DIVIDE`; date conversion and month grouping; `LAG` window functions; composite pseudonymous session keys; self-joins for repeat-visit analysis; missing-data checks.

## Repository contents

| SQL analysis | Exported result |
|---|---|
| [01 Dataset overview](01_dataset_overview.sql) | [Overview CSV](01_dataset_overview.csv) |
| [02 Customer events](02_customer_event_analysis.sql) | [Event breakdown CSV](02_customer_event_analysis.csv) |
| [03 First-user acquisition](03_customer_acquisition.sql) | [Acquisition CSV](03_customer_acquisition.csv) |
| [04 Ordered purchase funnel](04_purchase_funnel.sql) | [Funnel CSV](04_purchase_funnel.csv) |
| [05 Device performance](05_device_performance.sql) | [Device CSV](05_device_performance.csv) |
| [06 Top products](06_top_products.sql) | [Products CSV](06_top_products.csv) |
| [07 Monthly performance](07_monthly_performance.sql) | [Monthly CSV](07_monthly_performance.csv) |
| [08 Returning users](08_returning_users.sql) | [Returning users CSV](08_returning_users.csv) |
| [09 Data quality](09_data_quality.sql) | [Audit CSV](09_data_quality.csv) |

Four charts visualise the monthly revenue, ordered funnel, device revenue and best-selling products. See [METRIC_DEFINITIONS.md](METRIC_DEFINITIONS.md) for measurement details.

## Data and measurement notes

The public dataset is historical and **obfuscated**, with some placeholder source values and possible inconsistencies. Observed user IDs are pseudonymous identifiers, not verified individual people. November-only queries and full-period queries have different date ranges; monthly unique users should not be summed to get three-month unique users. Revenue values are reported in **USD** from the export. This is an independent analysis of Google's public sample, not a live client's property or the GA4 demo-account reporting data.
