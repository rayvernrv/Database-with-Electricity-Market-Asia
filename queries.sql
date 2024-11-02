-- Insert into country
INSERT INTO "country" ("id", "country_name", "population", "gdp") VALUES
(1, 'China', 1400000000, 14342903),
(2, 'India', 1380000000, 2875142),
(3, 'Japan', 126000000, 5081770);

-- Insert into source
INSERT INTO "source" ("id", "source_type", "renewable") VALUES
(1, 'Hydro', 'Renewable'),
(2, 'Coal', 'Non-renewable'),
(3, 'Solar', 'Renewable'),
(4, 'Nuclear', 'Non-renewable'),
(5, 'Gas', 'Non-renewable'),
(6, 'Wind', 'Renewable');

-- Insert into power_plant
INSERT INTO "power_plant" ("id", "plant_name", "country_id", "source_id", "generation_capacity_mw", "commissioned_year") VALUES
(1, 'Three Gorges Dam', 1, 1, 22500, 2012),
(2, 'Vindhyachal Thermal Power Station', 2, 2, 4760, 1987),
(3, 'Kashiwazaki-Kariwa Nuclear Power Plant', 3, 4, 7965, 1985);

-- Insert into electricity_production
INSERT INTO "electricity_production" ("id", "plant_id", "month", "year", "monthly_electricity_production") VALUES
(1, 1, 'January', 2024, 20000),
(2, 2, 'January', 2024, 4500),
(3, 3, 'January', 2024, 7500);

-- Insert into market_price
INSERT INTO "market_price" ("id", "country_id", "source_id", "month", "year", "price_per_mwh") VALUES
(1, 1, 1, 'January', 2024, 30),
(2, 2, 2, 'January', 2024, 50),
(3, 3, 4, 'January', 2024, 70);

-- Insert into consumer
INSERT INTO "consumer" ("id", "sector", "country_id", "month", "year", "monthly_consumption_mwh") VALUES
(1, 'Residential', 1, 'January', 2024, 10000),
(2, 'Industrial', 2, 'January', 2024, 20000),
(3, 'Commercial', 3, 'January', 2024, 15000);

-- Delete duplicate entries, keeping 1 instance
DELETE FROM electricity_production
WHERE ROWID NOT IN (
    SELECT MIN(ROWID)
    FROM electricity_production
    GROUP BY id
);

DELETE FROM market_price
WHERE ROWID NOT IN (
    SELECT MIN(ROWID)
    FROM market_price
    GROUP BY id
);

DELETE FROM consumer
WHERE ROWID NOT IN (
    SELECT MIN(ROWID)
    FROM consumer
    GROUP BY id
);


-- Rank countries from Highest to Lowest Average Market Price Per MWh for each year
WITH avg_price_ranking AS (
    SELECT
        co.country_name AS Country,
        AVG(mp.price_per_mwh) AS avg_price_per_mwh,
        mp.year
    FROM country co
    LEFT JOIN market_price mp ON co.id = mp.country_id
    GROUP BY co.country_name, mp.year
)
SELECT
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY avg_price_per_mwh DESC) AS "Rank",
    Country,
    avg_price_per_mwh AS "Average Price Per MWh",
    year AS "Year"
FROM avg_price_ranking;


-- Current month-to-date price_per_mwh for each country
-- Get month_number from newly created view "month_to_numeric" for market_price table
SELECT
    co.country_name AS "Country",
    mp.month AS "Month",
    mp.year AS "Year",
    mp.price_per_mwh AS "Price Per MWh"
FROM
    market_price mp
LEFT JOIN
    country co ON mp.country_id = co.id
LEFT JOIN
    month_to_numeric mn ON mp.id = mn.new_id
WHERE
    mn.month_number = strftime('%m', 'now') AND
    mp.year = strftime('%Y', 'now');


-- Country with the highest average of renewable production in year 2023
WITH avg_renewable_production AS (
    SELECT
        co.country_name AS "Country",
        AVG(ep.monthly_electricity_production) AS "Annual Avg"
    FROM
        electricity_production ep
    LEFT JOIN
        power_plant pp ON ep.plant_id = pp.id
    LEFT JOIN
        country co ON pp.country_id = co.id
    LEFT JOIN
        source ON pp.source_id = source.id
    WHERE
        ep.year = 2023
        AND source.renewable = 'Renewable'
    GROUP BY
        co.country_name
),
ranked_production AS (
    SELECT
    "Country",
    "Annual Avg",
    DENSE_RANK() OVER (ORDER BY "Annual Avg" DESC) AS "Rank"
FROM
    avg_renewable_production
)

SELECT
    "Country",
    "Annual Avg"
FROM
    ranked_production
WHERE
    "Rank" = 1;


-- Sum of electricity consumption by sector comparing each country for 2023 and 2024
SELECT
    co.country_name AS "Country",
    cs.sector AS "Sector",
    cs.year "Year",
    SUM(cs.monthly_consumption_mwh) AS "Sum of Consumption"
FROM
    consumer cs
LEFT JOIN
    country co ON cs.country_id = co.id
WHERE
    cs.year IN (2023, 2024)
GROUP BY
    co.country_name, cs.sector, cs.year
ORDER BY
    cs.sector ASC, co.country_name, cs.year;


-- Ratio of average market price for electricity produced by renewable to non-renewable option in 2023 for each country
WITH avg_renewable_price AS (
    SELECT
        mp.country_id,
        AVG(mp.price_per_mwh) AS avg_renewable_price
    FROM
        market_price mp
    LEFT JOIN
        source s ON mp.source_id = s.id
    WHERE
        mp.year = '2023' AND
        s.renewable = 'Renewable'
    GROUP BY
        mp.country_id

), avg_non_renewable_price AS (
    SELECT
        mp.country_id,
        AVG(mp.price_per_mwh) AS avg_non_renewable_price
    FROM
        market_price mp
    LEFT JOIN
        source s ON mp.source_id = s.id
    WHERE
        mp.year = '2023' AND
        s.renewable = 'Non-renewable'
    GROUP BY
        mp.country_id
)

SELECT
    co.country_name AS "Country",
    arp.avg_renewable_price AS "Average Renewable Price",
    anrp.avg_non_renewable_price AS "Average Non-renewable Price",
    CASE
        WHEN anrp.avg_non_renewable_price > 0 THEN -- in case the denominator is 0
            arp.avg_renewable_price/anrp.avg_non_renewable_price
        ELSE
            NULL
    END AS "Renewable/Non-renewable Price Ratio"
FROM
    avg_renewable_price arp
LEFT JOIN
    avg_non_renewable_price anrp ON arp.country_id = anrp.country_id
LEFT JOIN
    country co ON arp.country_id = co.id
ORDER BY
    "Renewable/Non-renewable Price Ratio" DESC;
