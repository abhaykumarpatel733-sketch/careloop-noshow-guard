-- =====================================================================
-- CareLoop Clinics — No-Show Guard
-- Part 2: SQL Verification and Analysis Queries
-- File: 02_queries.sql
-- Database: noshowguard
-- =====================================================================

-- ---------------------------------------------------------------------
-- Task 2.1: Build and Load Database Verification
-- ---------------------------------------------------------------------
-- Create database and switch context (MySQL Workbench; omit in SQLiteOnline)
CREATE DATABASE IF NOT EXISTS noshowguard;
USE noshowguard;

-- Table DDL (if not already created prior to running load_data.sql)
CREATE TABLE IF NOT EXISTS clinics (
    clinic_id VARCHAR(5) PRIMARY KEY,
    clinic_name VARCHAR(40) NOT NULL,
    city VARCHAR(20) NOT NULL,
    tier VARCHAR(10),
    latitude DECIMAL(8,4),
    longitude DECIMAL(8,4),
    temp_c DECIMAL(5,1)
);

CREATE TABLE IF NOT EXISTS appointments (
    appointment_id VARCHAR(8) PRIMARY KEY,
    patient_id VARCHAR(8) NOT NULL,
    clinic_id VARCHAR(5) NOT NULL,
    booked_on DATE,
    appt_date DATE,
    age INT,
    gender VARCHAR(1),
    distance_km DECIMAL(5,1),
    fee_inr INT,
    booking_channel VARCHAR(10),
    visit_type VARCHAR(12),
    reminder_sent VARCHAR(3),
    prior_no_shows INT,
    status VARCHAR(10),
    lead_days INT,
    no_show INT,
    FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id)
);

-- Verification: Check row counts and total no-shows
SELECT COUNT(*) AS total_clinics FROM clinics;
-- Expected output: 8

SELECT COUNT(*) AS total_appointments, SUM(no_show) AS total_no_shows 
FROM appointments;
-- Expected output: 990 appointments, 218 no-shows

-- Attempt duplicate insert to test Primary Key constraint enforcement:
-- INSERT INTO appointments (appointment_id, patient_id, clinic_id) VALUES ('A0001', 'P999', 'C01');
--
-- Error message observed:
-- In MySQL: ERROR 1062 (23000): Duplicate entry 'A0001' for key 'appointments.PRIMARY'
-- In SQLite: UNIQUE constraint failed: appointments.appointment_id


-- ---------------------------------------------------------------------
-- Task 2.2: No-show rate by clinic
-- ---------------------------------------------------------------------
-- (a) Clinics with at least 95 appointments (HAVING COUNT(*) >= 95)
SELECT 
    c.clinic_name, 
    c.city, 
    COUNT(*) AS appointments, 
    SUM(a.no_show) AS no_shows, 
    ROUND(100.0 * SUM(a.no_show) / COUNT(*), 1) AS no_show_pct
FROM appointments a
JOIN clinics c ON a.clinic_id = c.clinic_id
GROUP BY c.clinic_name, c.city
HAVING COUNT(*) >= 95
ORDER BY no_show_pct DESC;

-- (b) All 8 clinics without HAVING filter
SELECT 
    c.clinic_name, 
    c.city, 
    COUNT(*) AS appointments, 
    SUM(a.no_show) AS no_shows, 
    ROUND(100.0 * SUM(a.no_show) / COUNT(*), 1) AS no_show_pct
FROM appointments a
JOIN clinics c ON a.clinic_id = c.clinic_id
GROUP BY c.clinic_name, c.city
ORDER BY no_show_pct DESC;
-- Note: Gomti Nagar Care Point (Lucknow) has the highest no-show rate overall (33.3%),
-- but has only 90 appointments, so it was filtered out by the HAVING >= 95 threshold.
-- Sitabuldi Health Point (Nagpur) has 82 appointments with a 15.9% no-show rate.


-- ---------------------------------------------------------------------
-- Task 2.3: Does booking far ahead matter? (Lead time bands)
-- ---------------------------------------------------------------------
SELECT 
    CASE 
        WHEN lead_days <= 7 THEN '1-7'
        WHEN lead_days <= 14 THEN '8-14'
        WHEN lead_days <= 30 THEN '15-30'
        ELSE '31+'
    END AS lead_band,
    COUNT(*) AS appointments,
    SUM(no_show) AS no_shows,
    ROUND(100.0 * SUM(no_show) / COUNT(*), 1) AS no_show_pct
FROM appointments
GROUP BY lead_band
ORDER BY MIN(lead_days);


-- ---------------------------------------------------------------------
-- Task 2.4: Month-by-month trend
-- ---------------------------------------------------------------------
WITH monthly AS (
    SELECT 
        SUBSTR(appt_date, 1, 7) AS month,
        COUNT(*) AS appointments,
        ROUND(100.0 * SUM(no_show) / COUNT(*), 1) AS no_show_pct
    FROM appointments
    GROUP BY SUBSTR(appt_date, 1, 7)
)
SELECT 
    month,
    appointments,
    no_show_pct,
    ROUND(no_show_pct - LAG(no_show_pct) OVER (ORDER BY month), 1) AS pct_change
FROM monthly
ORDER BY month;


-- ---------------------------------------------------------------------
-- Task 2.5: Rank clinics inside each city vs overall benchmark
-- ---------------------------------------------------------------------
WITH clinic_rates AS (
    SELECT 
        c.clinic_name AS clinic,
        c.city,
        ROUND(100.0 * SUM(a.no_show) / COUNT(*), 1) AS no_show_pct
    FROM appointments a
    JOIN clinics c ON a.clinic_id = c.clinic_id
    GROUP BY c.clinic_name, c.city
)
SELECT 
    city,
    clinic,
    no_show_pct,
    RANK() OVER (PARTITION BY city ORDER BY no_show_pct DESC) AS rank_in_city,
    CASE 
        WHEN no_show_pct > (SELECT 100.0 * SUM(no_show) / COUNT(*) FROM appointments) THEN 'above'
        WHEN no_show_pct < (SELECT 100.0 * SUM(no_show) / COUNT(*) FROM appointments) THEN 'below'
        ELSE 'equal'
    END AS vs_overall
FROM clinic_rates
ORDER BY city, rank_in_city;
