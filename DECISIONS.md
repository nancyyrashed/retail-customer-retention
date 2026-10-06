# Project Decisions Log

## Phase 0 — Data Preparation and Problem Definition

### Dataset
- Use the UCI Online Retail II dataset covering transactions from December 2009 to December 2011.
- Combine both yearly worksheets into one dataset.
- Remove duplicated transactions, including the duplicated December 2010 overlap between the two worksheets.

### Customer-Level Analysis
- Customer retention analysis requires a known `Customer ID`.
- Transactions without a customer identifier are excluded from customer-level churn and retention modeling.

### Qualifying Purchases
A qualifying merchandise purchase must:
- belong to an identified customer;
- have a positive quantity;
- have a positive price;
- not be a cancellation invoice;
- not be a special non-merchandise transaction such as postage, manual adjustments, discounts, bank charges, or test products.

Zero-price customer activity is preserved separately but does not count as revenue or as a qualifying purchase.

### Returns and Adjustments
- `C`-prefixed invoices are treated as cancellations or returns.
- Negative quantities without a `C` invoice are treated as stock adjustments or write-offs rather than customer purchases.
- Negative prices are treated as accounting adjustments.
- Extreme purchase values are not automatically removed because some represent legitimate wholesale activity.

### Base Customer Population
- Customers must have at least one qualifying merchandise purchase.
- The resulting base population contains **5,861 customers**.

### Churn Definition
- Observation window: **180 days**.
- Label window: **90 days**.
- A customer is labeled as churned if they make no qualifying merchandise purchase during the following 90 days.
- Customers must have at least one qualifying purchase during the 180-day observation period to be included at a cutoff.

### Modeling Cutoffs
Training snapshots:
- 2010-09-01
- 2010-12-01
- 2011-03-01
- 2011-06-01

Final untouched test snapshot:
- 2011-09-01

The final test period is kept chronologically separate from the training snapshots to avoid temporal leakage.

### PostgreSQL
- Use a dedicated PostgreSQL 17 Docker container.
- Database: `retail_retention`
- Host port: `5433`
- Store the cleaned merchandise transaction data in `retail_transactions`.
- Use PostgreSQL `COPY` for efficient loading.
- The database load contains **776,614 rows**, **5,861 customers**, and **36,629 invoices**.