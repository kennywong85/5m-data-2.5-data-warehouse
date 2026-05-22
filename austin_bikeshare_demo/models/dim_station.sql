WITH station_source AS (

    SELECT
        NULLIF(TRIM(CAST(station_id AS STRING)), '') AS station_id,
        name AS station_name,
        status,
        location,
        address,
        modified_date,
        1 AS source_priority

    FROM {{ source('austin_bikeshare', 'bikeshare_stations') }}
    WHERE station_id IS NOT NULL

),

trip_start_stations AS (

    SELECT DISTINCT
        NULLIF(TRIM(CAST(start_station_id AS STRING)), '') AS station_id,
        start_station_name AS station_name,
        CAST(NULL AS STRING) AS status,
        CAST(NULL AS STRING) AS location,
        CAST(NULL AS STRING) AS address,
        CAST(NULL AS TIMESTAMP) AS modified_date,
        2 AS source_priority

    FROM {{ source('austin_bikeshare', 'bikeshare_trips') }}
    WHERE start_station_id IS NOT NULL

),

trip_end_stations AS (

    SELECT DISTINCT
        NULLIF(TRIM(CAST(end_station_id AS STRING)), '') AS station_id,
        end_station_name AS station_name,
        CAST(NULL AS STRING) AS status,
        CAST(NULL AS STRING) AS location,
        CAST(NULL AS STRING) AS address,
        CAST(NULL AS TIMESTAMP) AS modified_date,
        2 AS source_priority

    FROM {{ source('austin_bikeshare', 'bikeshare_trips') }}
    WHERE end_station_id IS NOT NULL

),

all_stations AS (

    SELECT * FROM station_source

    UNION ALL

    SELECT * FROM trip_start_stations

    UNION ALL

    SELECT * FROM trip_end_stations

),

deduplicated AS (

    SELECT
        station_id,
        station_name,
        status,
        location,
        address,
        modified_date

    FROM all_stations
    WHERE station_id IS NOT NULL

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY station_id
        ORDER BY source_priority ASC, modified_date DESC
    ) = 1

)

SELECT *
FROM deduplicated