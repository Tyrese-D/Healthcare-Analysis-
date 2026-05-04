-- 1. DATA TRANSFORMATION: CREATING AGE BUCKETS
-- Replicating Excel logic to segment patients for demographic analysis.
-- Supports 'Count of Age Bucket' visualization.
SELECT 
    Name,
    Age,
    CASE 
        WHEN Age < 20 THEN 'Teen'
        WHEN Age BETWEEN 20 AND 39 THEN 'Young'
        WHEN Age BETWEEN 40 AND 59 THEN 'Middle Age'
        ELSE 'Senior'
    END AS Age_Bucket,
    Gender,
    [Blood Type],
    [Medical Condition]
FROM healthcare_dataset;

--------------------------------------------------------------------------

-- 2. FINANCIAL ANALYSIS: REVENUE BY INSURANCE PROVIDER
-- Calculating total billing and volume per provider.
-- Supports 'Total No. of Patients by Insurance Provider' visualization.
SELECT 
    [Insurance Provider],
    COUNT(Name) AS Total_Admissions,
    ROUND(SUM([Billing Amount]), 2) AS Total_Revenue
FROM healthcare_dataset
GROUP BY [Insurance Provider]
ORDER BY Total_Revenue DESC;

--------------------------------------------------------------------------

-- 3. OPERATIONAL ANALYSIS: ADMISSION TRENDS (YEAR-OVER-YEAR)
-- Grouping data by year to identify growth patterns.
-- Supports 'Admission Trend YoY' visualization.
SELECT 
    YEAR([Date of Admission]) AS Admission_Year,
    COUNT(*) AS Number_of_Patients,
    ROUND(SUM([Billing Amount]), 2) AS Annual_Revenue
FROM healthcare_dataset
GROUP BY YEAR([Date of Admission])
ORDER BY Admission_Year;

--------------------------------------------------------------------------

-- 4. PROVIDER PERFORMANCE: TOP 5 DOCTORS
-- Identifying high-volume and high-revenue healthcare providers.
-- Supports 'Top 5 Doctors By Revenue and Patients' visualization.
SELECT TOP 5
    Doctor,
    COUNT(Name) AS Patient_Count,
    ROUND(SUM([Billing Amount]), 2) AS Total_Revenue
FROM healthcare_dataset
GROUP BY Doctor
ORDER BY Total_Revenue DESC;

--------------------------------------------------------------------------

-- 5. CLINICAL ANALYSIS: MEDICAL CONDITION BREAKDOWN
-- Analyzing the prevalence of conditions across the patient base.
-- Supports 'Total No. of Patients by Medical Conditions' visualization.
SELECT 
    [Medical Condition],
    COUNT(*) AS Condition_Count,
    ROUND(AVG([Billing Amount]), 2) AS Avg_Treatment_Cost
FROM healthcare_dataset
GROUP BY [Medical Condition]
ORDER BY Condition_Count DESC;
