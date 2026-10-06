from pathlib import Path
import os

import psycopg2
from dotenv import load_dotenv


# Project paths.
PROJECT_ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = PROJECT_ROOT / "data" / "processed" / "retail_merchandise_clean.csv"
ENV_PATH = PROJECT_ROOT / ".env"

# Load environment variables from the project .env file.
load_dotenv(ENV_PATH)


# PostgreSQL connection settings.
DB_CONFIG = {
    "host": os.getenv("DB_HOST"),
    "port": os.getenv("DB_PORT"),
    "dbname": os.getenv("DB_NAME"),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
}


def load_data():
    """Load the cleaned merchandise dataset into PostgreSQL."""

    if not CSV_PATH.exists():
        raise FileNotFoundError(
            f"Processed dataset not found: {CSV_PATH}"
        )

    print(f"Loading: {CSV_PATH}")

    with psycopg2.connect(**DB_CONFIG) as connection:
        with connection.cursor() as cursor:

            # Clear the table so rerunning the loader does not duplicate rows.
            cursor.execute(
                "TRUNCATE TABLE retail_transactions RESTART IDENTITY;"
            )

            # COPY is much faster than inserting rows one at a time.
            with CSV_PATH.open(
                "r",
                encoding="utf-8",
                newline=""
            ) as csv_file:

                cursor.copy_expert(
                    """
                    COPY retail_transactions (
                        invoice,
                        stock_code,
                        description,
                        quantity,
                        invoice_date,
                        unit_price,
                        customer_id,
                        country,
                        line_revenue
                    )
                    FROM STDIN
                    WITH (
                        FORMAT CSV,
                        HEADER TRUE
                    );
                    """,
                    csv_file,
                )

            # Confirm that the expected rows were loaded.
            cursor.execute(
                "SELECT COUNT(*) FROM retail_transactions;"
            )

            row_count = cursor.fetchone()[0]

    print(f"Rows loaded: {row_count:,}")


if __name__ == "__main__":
    load_data()