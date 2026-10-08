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

Development snapshots:

- 2010-09-01
- 2010-12-01
- 2011-03-01
- 2011-06-01

Final test snapshot:

- 2011-09-01

The final test period is kept chronologically separate from the development snapshots to reduce temporal leakage.

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

Recency alone is not used as the final churn definition; predictive modeling uses the predefined historical observation and label windows.

### Phase 1 Business Takeaway

The SQL analysis shows that:

- the retailer has strong seasonal purchasing behavior;
- repeat customers generate most order activity;
- revenue depends heavily on a relatively small group of high-value customers;
- a substantial share of the customer base shows prolonged inactivity.

These findings provide the business motivation for the next stages of segmentation and churn modeling.

---

## Phase 2 — Exploratory Data Analysis and Statistical Testing

Customer-level purchasing behavior was explored using descriptive statistics, distribution analysis, non-parametric hypothesis testing, bootstrap confidence intervals, and Spearman correlation.

### Customer Behavior Distributions

Customer purchasing metrics are strongly right-skewed.

- Average order value skewness: **53.42**
- Total revenue skewness: **25.34**
- Total units skewness: **21.84**
- Order count skewness: **12.11**
- Recency skewness: **0.89**
- Customer lifespan skewness: **0.39**

The strongest skew appears in customer spending, purchase volume, and frequency, reflecting a relatively small number of exceptionally high-value customers.

Log transformations were used during exploratory visualization to make highly skewed distributions easier to inspect while preserving the original variables.

### One-Time vs Repeat Customers

Repeat customers show substantially stronger purchasing behavior than one-time customers.

#### One-Time Customers

- Customers: **1,625**
- Median total revenue: **£227.10**
- Mean total revenue: **£342.25**
- Median average order value: **£227.10**
- Median units purchased: **130**
- Median recency: **386 days**

#### Repeat Customers

- Customers: **4,236**
- Median total revenue: **£1,363.86**
- Mean total revenue: **£3,899.13**
- Median average order value: **£291.08**
- Median units purchased: **794**
- Median recency: **59 days**

Repeat customers therefore generate substantially more cumulative value and purchase volume while also showing much more recent engagement.

Total revenue differences are partly structural because repeat customers have multiple purchasing opportunities. Average order value provides a more direct per-order comparison.

### Statistical Comparison of Average Order Value

Because average order value is extremely right-skewed, a **Mann–Whitney U test** was used instead of relying on a normal-distribution assumption.

Results:

- **Repeat customers:** 4,236
- **One-time customers:** 1,625
- **Mann–Whitney U:** 4,105,272
- **p-value:** 2.57 × 10⁻³⁰
- **Rank-biserial correlation:** 0.193

The extremely small p-value provides strong statistical evidence that average order value differs between one-time and repeat customers.

However, the rank-biserial correlation indicates a **relatively small effect size**.

This means the difference is statistically clear but modest in practical magnitude.

### Bootstrap Confidence Interval

The observed difference in median average order value is:

**£63.98**

Repeat customers have a median average order value approximately £64 higher than one-time customers.

The **95% bootstrap confidence interval** is:

**£50.78 to £77.26**

Because the entire interval lies above zero, the bootstrap analysis provides additional support for a positive difference between the groups.

### Customer Metric Relationships

Spearman rank correlation was used because several customer variables are highly skewed and contain extreme values.

Several strong relationships were identified:

- Total units and total revenue: **0.95**
- Order count and customer lifespan: **0.88**
- Order count and total revenue: **0.86**
- Order count and total units: **0.82**
- Total revenue and customer lifespan: **0.77**
- Total units and customer lifespan: **0.73**
- Average order value and total revenue: **0.65**

Recency is negatively associated with several engagement and value metrics:

- Recency vs order count: **-0.56**
- Recency vs customer lifespan: **-0.57**
- Recency vs total units: **-0.51**
- Recency vs total revenue: **-0.51**

Customers who have been inactive for longer therefore tend to have lower historical purchase frequency, revenue, and customer tenure.

These relationships represent associations and should not be interpreted as evidence of causation.

### Phase 2 Takeaway

The exploratory and statistical analysis shows that:

- customer purchasing behavior is highly skewed;
- customer value is concentrated among a relatively small group of highly active customers;
- repeat customers have much higher cumulative revenue and purchase volume;
- repeat customers also tend to have moderately higher average order values;
- the AOV difference is statistically convincing but modest in effect size;
- recency, frequency, monetary value, and customer lifespan are strongly related to customer engagement.

These findings support using **recency, frequency, monetary value, purchase volume, and customer-tenure-related features** in the segmentation and churn-modeling phases that follow.

---

## Phase 3 — Customer Segmentation and Churn Modeling

Phase 3 combines interpretable customer segmentation with leakage-safe churn prediction using historical customer snapshots.

For each snapshot:

- customer features are calculated using only the preceding 180 days;
- churn is defined by whether the customer makes a qualifying merchandise purchase during the following 90 days;
- future behavior is used only to create the churn label and is never included in the predictive features.

### Customer Segmentation

Two segmentation approaches were compared:

- **RFM segmentation**, using Recency, Frequency, and Monetary Value;
- **K-Means clustering**, using standardized and log-transformed RFM behavior.

RFM produced six business-oriented customer groups with substantially different future churn rates:

- **Champions:** 12.90%
- **Loyal Customers:** 39.56%
- **At Risk:** 52.03%
- **Needs Attention:** 65.50%
- **Promising:** 66.01%
- **Hibernating:** 72.37%

K-Means identified three broader customer groups and showed similar overall behavioral patterns.

RFM was retained as the primary segmentation framework because it provides more granular and business-interpretable groups, particularly for identifying valuable customers whose recent activity has weakened.

### Time-Based Churn Modeling

The predictive workflow uses chronological model development rather than a random train/test split.

- **Training snapshots:** 2010-09-01, 2010-12-01, 2011-03-01
- **Validation snapshot:** 2011-06-01
- **Original untouched final test:** 2011-09-01

The original churn model uses five leakage-safe behavioral features:

- recency;
- order frequency;
- monetary value;
- total units purchased;
- average order value.

Two models were compared on the validation period:

- **Logistic Regression:** PR-AUC = 0.699, ROC-AUC = 0.750
- **XGBoost:** PR-AUC = 0.684, ROC-AUC = 0.741

Logistic Regression was retained because it provided stronger churn-risk ranking while remaining simpler and more interpretable.

### Final Test Performance

After refitting Logistic Regression on all development periods, the original final-test evaluation achieved:

- **PR-AUC:** 0.588
- **ROC-AUC:** 0.732
- **churn recall at a 0.50 threshold:** 83.6%
- **churn precision at a 0.50 threshold:** 52.3%

The validation and final-test churn rates differ substantially:

- **Validation churn rate:** 50.04%
- **Final-test churn rate:** 39.31%

Because PR-AUC depends on positive-class prevalence, the reduction from 0.699 to 0.588 should not by itself be interpreted as an equivalent deterioration in model discrimination.

ROC-AUC changed only from 0.750 to 0.732, indicating that ranking discrimination remained broadly similar across the later period.

### Retention Campaign Targeting

The model was also evaluated under limited customer-contact budgets.

On the final test period:

- targeting the highest-risk **5%** of customers captured **8.73%** of all churners, with **68.35% precision** and **1.74× lift**;
- targeting the highest-risk **10%** captured **16.82%** of churners, with **66.06% precision** and **1.68× lift**;
- targeting the highest-risk **20%** captured **32.26%** of churners, with **63.36% precision** and **1.61× lift**.

The cumulative lift curve remained above random targeting across most of the ranking, showing that the model can prioritize customers under different retention-campaign capacities.

### Enhanced Feature Experiment

Five additional leakage-safe behavioral variables were evaluated:

- active purchasing days;
- product diversity;
- purchase span;
- recent 30-day order share;
- recent 30-day revenue share.

These features did not materially improve validation performance.

For Logistic Regression:

- PR-AUC changed from **0.699 to 0.697**;
- ROC-AUC changed from **0.750 to 0.751**.

For XGBoost:

- PR-AUC remained **0.684**;
- ROC-AUC remained **0.741**.

Because the richer feature set produced no consistent predictive improvement, the original five-feature Logistic Regression was retained.

The enhanced models were not evaluated on the final test period because that period had already been inspected and validation results did not justify changing the selected model specification.

### Phase 3 Limitations

- Churn is defined operationally as no purchase during the following 90 days; it does not necessarily represent permanent customer loss.
- The same customer can appear in multiple historical snapshots at different points in time.
- Returns and cancellations are not included in the current churn-model feature table.
- PR-AUC must be interpreted alongside the churn base rate.
- Model predictions represent association rather than causation.
- Probability calibration has not yet been evaluated and will be addressed before predicted probabilities are used for revenue-at-risk calculations.

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
│   ├── 02_sql_business_analytics.ipynb
│   ├── 03_eda_statistics.ipynb
│   └── 04_segmentation_churn_modeling.ipynb
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