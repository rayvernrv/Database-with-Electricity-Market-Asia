-- Creating mock database for Asia's electricity market

-- Countries in Asia
CREATE TABLE IF NOT EXISTS "country" (
    "id" INTEGER,
    "country_name" TEXT NOT NULL,
    "population" INTEGER NOT NULL,
    "gdp" NUMERIC NOT NULL,
    PRIMARY KEY ("id")
);

-- Source
CREATE TABLE IF NOT EXISTS "source" (
    "id" INTEGER,
    "source_type" TEXT NOT NULL CHECK("source_type" IN ('Hydro', 'Coal', 'Solar', 'Nuclear', 'Gas', 'Wind')),
    "renewable" TEXT NOT NULL CHECK("renewable" IN ('Renewable', 'Non-renewable')),
    PRIMARY KEY ("id")
);

-- Power Plants
CREATE TABLE IF NOT EXISTS "power_plant" (
    "id" INTEGER,
    "plant_name" TEXT NOT NULL,
    "country_id" INTEGER NOT NULL,
    "source_id" INTEGER NOT NULL,
    "generation_capacity_mw" NUMERIC NOT NULL,
    "commissioned_year" INTEGER,
    PRIMARY KEY ("id"),
    FOREIGN KEY ("country_id") REFERENCES "country"("id"),
    FOREIGN KEY ("source_id") REFERENCES "source"("id")
);

-- Electricity Production
CREATE TABLE IF NOT EXISTS "electricity_production" (
    "id" INTEGER,
    "plant_id" INTEGER NOT NULL,
    "month" TEXT NOT NULL,
    "year" INTEGER NOT NULL,
    "monthly_electricity_production" NUMERIC NOT NULL,
    PRIMARY KEY ("id"),
    FOREIGN KEY ("plant_id") REFERENCES "power_plant"("id")
);

-- Market Price
CREATE TABLE IF NOT EXISTS "market_price" (
    "id" INTEGER,
    "country_id" INTEGER NOT NULL,
    "source_id" INTEGER NOT NULL,
    "month" TEXT NOT NULL,
    "year" INTEGER NOT NULL,
    "price_per_mwh" NUMERIC NOT NULL,
    PRIMARY KEY ("id"),
    FOREIGN KEY ("country_id") REFERENCES "country"("id"),
    FOREIGN KEY ("source_id") REFERENCES "source"("id")
);

-- Consumers
CREATE TABLE IF NOT EXISTS "consumer" (
    "id" INTEGER,
    "sector" TEXT NOT NULL CHECK("sector" IN ('Residential', 'Industrial', 'Commercial')),
    "country_id" INTEGER NOT NULL,
    "month" TEXT NOT NULL,
    "year" INTEGER NOT NULL,
    "monthly_consumption_mwh" NUMERIC NOT NULL,
    PRIMARY KEY ("id"),
    FOREIGN KEY ("country_id") REFERENCES "country"("id")
);


-- Create indexes to speed up common search
CREATE INDEX IF NOT EXISTS index_country_name ON country(country_name);
CREATE INDEX IF NOT EXISTS index_power_plant ON power_plant(country_id, source_id);
CREATE INDEX IF NOT EXISTS index_electricity_production ON electricity_production(plant_id, month, year);
CREATE INDEX IF NOT EXISTS index_market_price ON market_price(country_id, month, year);
CREATE INDEX IF NOT EXISTS index_consumer ON consumer(sector, country_id, month, year);
CREATE INDEX IF NOT EXISTS index_source ON source(source_type, renewable);

-- Views
CREATE VIEW IF NOT EXISTS month_to_numeric AS
    SELECT
        market_price.id AS 'new_id',
        market_price.month,
        CASE
            WHEN month = 'January' THEN '01'
            WHEN month = 'February' THEN '02'
            WHEN month = 'March' THEN '03'
            WHEN month = 'April' THEN '04'
            WHEN month = 'May' THEN '05'
            WHEN month = 'June' THEN '06'
            WHEN month = 'July' THEN '07'
            WHEN month = 'August' THEN '08'
            WHEN month = 'September' THEN '09'
            WHEN month = 'October' THEN '10'
            WHEN month = 'November' THEN '11'
            WHEN month = 'December' THEN '12'
        END AS month_number
    FROM market_price;


-- View for Total Electricity Production by Country and Year
CREATE VIEW IF NOT EXISTS total_electricity_production AS
    SELECT
        co.country_name AS "Country",
        ep.year AS "Year",
        SUM(ep.monthly_electricity_production) AS "Total Production"
    FROM
        electricity_production ep
    LEFT JOIN
        power_plant pp ON ep.plant_id = pp.id
    LEFT JOIN
        country co ON pp.country_id = co.id
    GROUP BY
        co.country_name, ep.year;
