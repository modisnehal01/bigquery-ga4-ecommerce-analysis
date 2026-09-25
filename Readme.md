
# GA4 E-commerce Analysis | Google BigQuery

**GoogleSQL · GA4 · Customer Acquisition · Purchase Funnel · Revenue Analysis**

## Project Overview

An SQL analysis of Google's public, obfuscated Google Merchandise Store GA4 dataset, covering November 2020 to January 2021.

Nine BigQuery analyses examine website events, customer acquisition, the purchase funnel, device performance, top products, monthly revenue, returning visitors and data quality.

## Business Questions

- Which website events occur most frequently?
- Which acquisition sources are associated with purchases?
- How do sessions progress from product views to purchases?
- Which devices and products generate the most revenue?
- How does performance change by month?
- How many visitors return in the following month?

## Monthly Performance

| Month | Observed User IDs | Purchase Events | Purchase Revenue |
|---|---:|---:|---:|
| Nov 2020 | 79,421 | 2,054 | $144,260 |
| Dec 2020 | 104,315 | 2,434 | $160,555 |
| Jan 2021 | 94,790 | 1,204 | $57,350 |

## Key Findings

- November recorded **1,472,712 events** across 30 days.
- Google organic search was associated with **30,440 observed user IDs** and **$37,360 in purchase revenue** in November. This represents first-user acquisition.
- The ordered purchase funnel recorded **25,943 product-view sessions**, **1,917 add-to-cart sessions**, **740 checkout sessions** and **366 purchase sessions**.
- Desktop generated **$79,289** in November purchase revenue; mobile generated **$62,087**.
- Google Zip Hoodie F/C was the highest-revenue product in the analysis, with **$6,564** in recorded item revenue.
- **4,651** December visitor IDs were also observed in November.
- The data-quality audit identified **23 purchases without transaction IDs** and **2 purchases without item records**.

## SQL Techniques

GoogleSQL, CTEs, UNNEST, JOINs, COUNT DISTINCT, conditional aggregation, SAFE_DIVIDE, window functions, date calculations and data-quality checks.

## SQL Scripts

[View all nine SQL analyses](BigQuery_All_9_Queries.sql)

## Analysis Results

| Analysis | Result |
|---|---|
| Dataset overview | [CSV](01_dataset_overview.csv) |
| Customer events | [CSV](02_customer_event_analysis.csv) |
| Customer acquisition | [CSV](03_customer_acquisition.csv) |
| Purchase funnel | [CSV](04_purchase_funnel.csv) |
| Device performance | [CSV](05_device_performance.csv) |
| Top products | [CSV](06_top_products.csv) |
| Monthly performance | [CSV](07_monthly_performance.csv) |
| Returning visitors | [CSV](08_returning_users.csv) |
| Data quality | [CSV](09_data_quality.csv) |

## Data Source

[Google's public GA4 e-commerce sample](https://developers.google.com/analytics/bigquery/web-ecommerce-demo-dataset)

The dataset is historical and obfuscated. User IDs are pseudonymous identifiers, not verified individual customers. The results represent an independent portfolio analysis of public data.

## Tools

Google BigQuery · GoogleSQL · Google Analytics 4 event data
