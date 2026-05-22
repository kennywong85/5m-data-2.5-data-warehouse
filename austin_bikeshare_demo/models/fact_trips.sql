WITH source AS (

    SELECT
        trip_id,
        subscriber_type,
        bike_id,
        bike_type,
        start_time,

        -- Convert station IDs to clean STRING keys
        NULLIF(TRIM(CAST(start_station_id AS STRING)), '') AS start_station_id,
        start_station_name,

        NULLIF(TRIM(CAST(end_station_id AS STRING)), '') AS end_station_id,
        end_station_name,

        duration_minutes

    FROM {{ source('austin_bikeshare', 'bikeshare_trips') }}
    WHERE trip_id IS NOT NULL

)

SELECT *
FROM source