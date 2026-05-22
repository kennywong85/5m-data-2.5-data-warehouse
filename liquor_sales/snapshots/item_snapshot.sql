{% snapshot item_snapshot %}

{{
    config(
      target_schema='snapshots',
      unique_key='item_number',
      strategy='timestamp',
      updated_at='updated_at',
    )
}}

WITH item AS (
    SELECT
        item_number,
        item_description,
        category,
        category_name,
        vendor_number,
        vendor_name,
        pack,
        bottle_volume_ml,
        date
    FROM
        {{ source('iowa_liquor_sales', 'sales') }}
),

grouped_data AS (
    SELECT DISTINCT
        item_number,
        item_description,
        category,
        category_name,
        vendor_number,
        vendor_name,
        pack,
        bottle_volume_ml,

        -- first date this exact item-version appears
        FIRST_VALUE(date) OVER (
            PARTITION BY
                item_number,
                item_description,
                category,
                category_name,
                vendor_number,
                vendor_name,
                pack,
                bottle_volume_ml
            ORDER BY date
        ) AS start_date,

        -- last date this exact item-version appears
        LAST_VALUE(date) OVER (
            PARTITION BY
                item_number,
                item_description,
                category,
                category_name,
                vendor_number,
                vendor_name,
                pack,
                bottle_volume_ml
            ORDER BY date
        ) AS end_date

    FROM item

    -- keep one row per distinct item-version
    QUALIFY RANK() OVER (
        PARTITION BY
            item_number,
            item_description,
            category,
            category_name,
            vendor_number,
            vendor_name,
            pack,
            bottle_volume_ml
        ORDER BY date
    ) = 1
)

SELECT
    item_number,
    item_description,
    category,
    category_name,
    vendor_number,
    vendor_name,
    pack,
    bottle_volume_ml,

    -- start timestamp of this version
    CAST(start_date AS TIMESTAMP) AS start_at,

    -- next version start date becomes this version's end date
    CAST(
        LEAD(start_date) OVER (
            PARTITION BY item_number
            ORDER BY start_date
        ) AS TIMESTAMP
    ) AS end_at,

    -- dbt snapshot needs an updated_at timestamp.
    -- Current/latest version gets CURRENT_TIMESTAMP().
    -- Older versions get NULL.
    IF(
        LEAD(start_date) OVER (
            PARTITION BY item_number
            ORDER BY start_date
        ) IS NULL,
        CURRENT_TIMESTAMP(),
        NULL
    ) AS updated_at

FROM grouped_data
ORDER BY item_number, start_at, end_at

{% endsnapshot %}