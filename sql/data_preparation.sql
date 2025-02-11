WITH preprocessed_data AS (
  SELECT DISTINCT
    CAST(ticket_number AS INT64) AS ticket_number,
    date AS transaction_date,
    TIME(
      CAST(SPLIT(time, ':')[OFFSET(0)] AS INT64), -- Extract hours
      CAST(SPLIT(time, ':')[OFFSET(1)] AS INT64), -- Extract minutes
      0 -- Set seconds to 0
    ) AS transaction_time,
    article AS item_name,
    CAST(quantity AS INT64) AS quantity,
    unit_price
  FROM `portfolio-db-0.Bakery_Sales.transaction_records`
  WHERE
    unit_price != 0.0
),

date_time_components AS (
  SELECT
    ticket_number,
    EXTRACT(YEAR FROM transaction_date) AS transaction_year,
    EXTRACT(MONTH FROM transaction_date) AS transaction_month,
    EXTRACT(DAY FROM transaction_date) AS transaction_day,
    FORMAT_DATE('%A', transaction_date) AS transaction_weekday,
    EXTRACT(HOUR FROM transaction_time) AS transaction_hour,
    EXTRACT(MINUTE FROM transaction_time) AS transaction_minute,
    item_name,
    quantity,
    unit_price
  FROM preprocessed_data
),

augmented_data AS (
  SELECT
    *,
    TRIM(
      REGEXP_REPLACE(
        REGEXP_REPLACE(
          item_name,
          r'[0-9]*[,.]?[0-9]+[A-Za-z]*$', -- Matches size/variant patterns at the end
          ''
        ),
        r'^[0-9]+ ', -- Matches size/variant patterns at the beginning
        ''
      )
    ) AS item_type,
    (quantity * unit_price) AS total_price
  FROM date_time_components
)

SELECT
  ROW_NUMBER() OVER() AS transaction_id,
  ticket_number,
  transaction_year,
  transaction_month,
  transaction_day,
  transaction_weekday,
  transaction_hour,
  transaction_minute,
  item_name,
  item_type,
  quantity,
  unit_price,
  total_price
FROM augmented_data;