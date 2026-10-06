-- Retail Customer Retention Intelligence
-- Phase 0: PostgreSQL schema

CREATE TABLE IF NOT EXISTS retail_transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    invoice VARCHAR(20) NOT NULL,
    stock_code VARCHAR(30) NOT NULL,
    description TEXT,
    quantity INTEGER NOT NULL,
    invoice_date TIMESTAMP NOT NULL,
    unit_price NUMERIC(12, 3) NOT NULL,
    customer_id INTEGER NOT NULL,
    country VARCHAR(100) NOT NULL,
    line_revenue NUMERIC(14, 2) NOT NULL
);

-- Indexes used frequently in customer and time-based analysis.
CREATE INDEX IF NOT EXISTS idx_retail_customer_id
    ON retail_transactions(customer_id);

CREATE INDEX IF NOT EXISTS idx_retail_invoice_date
    ON retail_transactions(invoice_date);

CREATE INDEX IF NOT EXISTS idx_retail_invoice
    ON retail_transactions(invoice);

CREATE INDEX IF NOT EXISTS idx_retail_customer_date
    ON retail_transactions(customer_id, invoice_date);