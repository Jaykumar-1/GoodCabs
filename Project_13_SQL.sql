# TASK 1
WITH temp_table AS (
    SELECT
        c.city_name AS city_name,
        COUNT(t.trip_id) AS total_trips,
        SUM(t.fare_amount) AS total_fare,
        SUM(t.distance_travelled_km) AS total_distance_travelled
    FROM
        trips_db.fact_trips t
    JOIN 
        trips_db.dim_city c 
        ON t.city_id = c.city_id
    GROUP BY 
        c.city_name
)
SELECT 
    city_name,
    total_trips,
    ROUND(total_fare / total_distance_travelled, 2) AS total_fare_per_km,
    ROUND(total_fare / total_trips, 2) AS avg_fare_per_trip,
    ROUND(total_trips * 100 / (SELECT SUM(total_trips) FROM temp_table), 2) AS pct_contribution_to_total_trips
FROM 
    temp_table;
--------------------------------------------------------------------------------------------------------------------------
# TASK 2
WITH temp_table AS (
    SELECT
        c.city_name AS city_name,
        MONTHNAME(mtt.month) AS month_name,
        COUNT(t.trip_id) AS actual_trips,
        mtt.total_target_trips AS target_trips
    FROM
        monthly_trips mtt
    JOIN
        trips_db.fact_trips t 
        ON mtt.city_id = t.city_id AND mtt.month = t.month
    JOIN 
        trips_db.dim_city c 
        ON c.city_id = mtt.city_id
    GROUP BY 
        c.city_name, month_name, mtt.total_target_trips
    ORDER BY 
        month_name
)
SELECT 
    *,
    IF(actual_trips > target_trips, "Above Target", "Below Target") AS performance_status,
    ROUND(((actual_trips - target_trips) * 100) / target_trips, 2) AS pct_difference
FROM 
    temp_table;
---------------------------------------------------------------------------------------------------------------------------
# TASK 3
WITH temp_table1 AS (
    SELECT
        c.city_name AS city_name,
        rtd.trip_count AS trip_count,
        SUM(rtd.repeat_passenger_count) AS total_repeated_pass
    FROM
        dim_repeat_trip_distribution rtd
    JOIN 
        dim_city c 
        ON rtd.city_id = c.city_id
    GROUP BY 
        c.city_name, rtd.trip_count
),
temp_table2 AS (
    SELECT
        city_name,
        trip_count,
        ROUND(total_repeated_pass * 100.0 / (SELECT SUM(total_repeated_pass) FROM temp_table1), 2) AS pct
    FROM 
        temp_table1
)
SELECT
    city_name,
    ROUND(SUM(CASE WHEN trip_count = 2 THEN pct END), 2) AS `2-Trips`,
    ROUND(SUM(CASE WHEN trip_count = 3 THEN pct END), 2) AS `3-Trips`,
    ROUND(SUM(CASE WHEN trip_count = 4 THEN pct END), 2) AS `4-Trips`,
    ROUND(SUM(CASE WHEN trip_count = 5 THEN pct END), 2) AS `5-Trips`,
    ROUND(SUM(CASE WHEN trip_count = 6 THEN pct END), 2) AS `6-Trips`,
    ROUND(SUM(CASE WHEN trip_count = 7 THEN pct END), 2) AS `7-Trips`,
    ROUND(SUM(CASE WHEN trip_count = 8 THEN pct END), 2) AS `8-Trips`,
    ROUND(SUM(CASE WHEN trip_count = 9 THEN pct END), 2) AS `9-Trips`,
    ROUND(SUM(CASE WHEN trip_count = 10 THEN pct END), 2) AS `10-Trips`
FROM 
    temp_table2
GROUP BY 
    city_name;
---------------------------------------------------------------------------------------------------------------------------
# TASK 4
WITH temp_table AS (
    SELECT
        c.city_name AS city_name,
        SUM(fps.new_passengers) AS total_new_passengers,
        RANK() OVER(ORDER BY SUM(fps.new_passengers) DESC) AS city_rank
    FROM 
        trips_db.fact_passenger_summary fps
    JOIN 
        dim_city c 
        ON fps.city_id = c.city_id
    GROUP BY 
        c.city_name
)
SELECT 
    city_name,
    total_new_passengers,
    CASE 
        WHEN city_rank <= 3 THEN "Top 3"
        WHEN city_rank > (SELECT MAX(city_rank) FROM temp_table) - 3 THEN "Bottom 3"
        ELSE " "
    END AS city_category
FROM 
    temp_table;
------------------------------------------------------------------------------------------------------------------------
# TASK 5    
WITH temp_table AS (
    SELECT 
        c.city_name AS city_name,
        MONTHNAME(t.month) AS month,
        SUM(t.fare_amount) AS revenue,
        DENSE_RANK() OVER (PARTITION BY c.city_name ORDER BY SUM(t.fare_amount) DESC) AS m_rank
    FROM 
        trips_db.fact_trips t
    JOIN 
        dim_city c 
        ON t.city_id = c.city_id
    GROUP BY 
        c.city_name, month
)
SELECT
    city_name,
    month,
    ROUND(revenue / 1000000, 2) AS revenue_mln,
    ROUND(revenue * 100 / (SELECT SUM(revenue) FROM temp_table), 2) AS percentage_contribution
FROM 
    temp_table
WHERE 
    m_rank <= 1
ORDER BY 
    revenue_mln DESC;
----------------------------------------------------------------------------------------------------------------------
# TASK 6
SELECT 
    c.city_name AS city_name,
    MONTHNAME(fps.month) AS month,
    SUM(fps.total_passengers) AS total_passengers,
    SUM(fps.repeat_passengers) AS repeat_passengers,
    SUM(fps.new_passengers) AS new_passengers,
    ROUND(fps.repeat_passengers * 100 / SUM(fps.total_passengers) OVER(PARTITION BY c.city_name), 2) AS monthly_repeat_passenger_rate,
    ROUND(SUM(fps.repeat_passengers) OVER(PARTITION BY c.city_name) * 100 / SUM(fps.total_passengers) OVER(), 2) AS city_repeat_passenger_rate
FROM 
    trips_db.fact_passenger_summary fps
JOIN 
    dim_city c 
    ON fps.city_id = c.city_id
GROUP BY 
    c.city_name, month, fps.repeat_passengers, fps.total_passengers;
-------------------------------------------------------------------------------------------------------