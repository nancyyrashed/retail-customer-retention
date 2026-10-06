# Retail Customer Retention Intelligence

This portfolio project simulates a customer-retention analysis for an online retailer using public data. The workflow mirrors customer-retention problems common across e-commerce, telecommunications, subscription services, and fintech.

The project follows the business workflow:

**Understand customer behavior → identify churn risk → explain it → quantify financial risk → forecast revenue → test an intervention.**

---

## Dataset

The project uses the **UCI Online Retail II** dataset containing transaction-level data for a UK-based online retailer between December 2009 and December 2011.

The original workbook contains two yearly worksheets and more than one million transaction rows.

---

## Phase 0 — Data Preparation and Problem Definition

Phase 0 establishes the analysis-ready dataset and the churn framework.

Completed work includes:

- inspected and combined both yearly worksheets;
- identified and removed duplicate transactions and the December 2010 worksheet overlap;
- investigated missing customer IDs, cancellations, returns, stock adjustments, zero-price transactions, and price anomalies;
- separated merchandise purchases from non-merchandise transaction codes;
- defined the eligible customer population;
- defined time-based churn observation and label windows;
- created a PostgreSQL database using Docker;
- loaded and validated the cleaned merchandise transactions.

### Analysis-Ready Dataset

- **Transaction rows:** 776,614
- **Customers:** 5,861
- **Invoices:** 36,629
- **Date range:** 2009-12-01 to 2011-12-09
- **Merchandise revenue:** £17,072,852.29

### Churn Definition

For each customer snapshot:

- **Observation window:** previous 180 days
- **Label window:** following 90 days
- **Churn = 1:** no qualifying merchandise purchase during the following 90 days
- **Churn = 0:** at least one qualifying merchandise purchase during the following 90 days

Customers must have at least one qualifying merchandise purchase during the observation window.

### Historical Cutoffs

Training snapshots:

- 2010-09-01
- 2010-12-01
- 2011-03-01
- 2011-06-01

Final untouched test snapshot:

- 2011-09-01

The final test period is kept chronologically separate from the training snapshots to reduce temporal leakage.

---

## Phase 1 — SQL Business Analytics

PostgreSQL was used to analyze revenue trends, purchasing behavior, customer value, and inactivity patterns using aggregations, CTEs, joins, filtering, and window functions.

### Revenue Trends

Monthly revenue shows strong year-end seasonality.

- Revenue rises sharply from **September through November** in both 2010 and 2011.
- November revenue reached approximately:
  - **£1.16M in 2010**
  - **£1.14M in 2011**
- The seasonal peaks were driven primarily by **higher order volume**, rather than unusually large average order values.
- December 2011 is only a partial month because the dataset ends on December 9.

### Repeat Purchasing

Repeat purchasing represents a major part of customer behavior.

- **72.27% of customers** made more than one merchandise purchase.
- **27.73%** were observed only once.
- Customers placed an average of **6.25 orders**.
- **84.0% of all merchandise orders** were repeat orders.

This indicates that existing customers contribute heavily to transaction activity.

### Customer Revenue Concentration

Revenue is highly concentrated among the highest-value customers.

- Top **1%** of customers generate **32.09%** of merchandise revenue.
- Top **5%** generate **52.03%**.
- Top **10%** generate **63.92%**.
- Top **20%** generate **77.20%**.

The top 20 customers represent only around **0.34% of the customer base**, yet generate approximately **21.98% of total merchandise revenue**.

This concentration suggests that losing even a small number of high-value customers could create substantial financial risk.

### Customer Recency

Customer recency was measured relative to the final transaction date in the dataset.

- **28.43%** purchased within the last 30 days.
- **12.66%** purchased 31–60 days ago.
- **8.14%** purchased 61–90 days ago.
- **10.05%** purchased 91–180 days ago.
- **40.73%** had not purchased for more than 180 days.

Recency alone is not used as the final churn definition; predictive modeling will use the predefined historical observation and label windows.

### Phase 1 Business Takeaway

The SQL analysis shows that:

- the retailer has strong seasonal purchasing behavior;
- repeat customers generate most order activity;
- revenue depends heavily on a relatively small group of high-value customers;
- a substantial share of the customer base shows prolonged inactivity.

These findings provide the business motivation for the next stages of segmentation and churn modeling.

---

## PostgreSQL

The cleaned merchandise data is stored in PostgreSQL 17 using Docker.

Main table:

`retail_transactions`

The table contains transaction-level merchandise sales with:

- invoice ID;
- product code and description;
- quantity;
- transaction date;
- unit price;
- customer ID;
- country;
- line revenue.

Indexes were created on customer ID, invoice date, invoice ID, and the combined `(customer_id, invoice_date)` fields to support analytical queries efficiently.

---

## Project Structure

```text
retail-customer-retention/
├── data/
│   ├── raw/
│   └── processed/
├── notebooks/
│   ├── 01_data_exploration.ipynb
│   └── 02_sql_business_analytics.ipynb
├── scripts/
│   └── load_postgres.py
├── src/
├── sql/
│   ├── schema.sql
│   └── phase1_business_analytics.sql
├── dashboard/
├── .env.example
├── .gitignore
├── DECISIONS.md
├── docker-compose.yml
├── requirements.txt
└── README.md