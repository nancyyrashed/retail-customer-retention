# Retail Customer Retention Intelligence

This portfolio project simulates a customer-retention analysis for an online retailer using public data. The workflow mirrors customer-retention problems common across e-commerce, telecommunications, subscription services, and fintech.

The project follows the business workflow:

**Understand customer behavior → identify churn risk → explain it → quantify financial risk → forecast revenue → test an intervention.**

## Dataset

The project uses the **UCI Online Retail II** dataset containing transaction-level data for a UK-based online retailer between December 2009 and December 2011.

The original workbook contains two yearly worksheets and more than one million transaction rows.

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

## Churn Definition

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

## PostgreSQL

The cleaned merchandise data is stored in PostgreSQL 17 using Docker.

Main table:

`retail_transactions`

The table contains transaction-level merchandise sales with customer, invoice, product, quantity, price, date, country, and revenue information.

## Project Structure

```text
retail-customer-retention/
├── data/
│   ├── raw/
│   └── processed/
├── notebooks/
├── scripts/
├── src/
├── sql/
├── dashboard/
├── .env.example
├── .gitignore
├── DECISIONS.md
├── docker-compose.yml
├── requirements.txt
└── README.md
```

## Planned Analysis

The remaining project phases will cover:

1. SQL business analytics
2. Exploratory data analysis and statistical testing
3. Customer segmentation and churn modeling
4. SHAP explanations, calibration, and revenue at risk
5. Revenue forecasting
6. Retention experiment design and A/B test analysis
7. Power BI dashboard and final project presentation

## Tech Stack

Python, Pandas, NumPy, PostgreSQL, Docker, SQL, Jupyter, Matplotlib, Seaborn, Plotly, SciPy, statsmodels, scikit-learn, and Power BI.