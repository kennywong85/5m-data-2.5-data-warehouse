SELECT
    item_number,
    item_description,
    category,
    category_name,
    vendor_number,
    vendor_name,
    pack,
    bottle_volume_ml
FROM {{ ref('item_snapshot') }}
WHERE dbt_valid_to IS NULL

-- safety net: keep only one current row per item_number
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY item_number
    ORDER BY dbt_valid_from DESC
) = 1