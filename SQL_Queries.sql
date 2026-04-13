-- ============================================================
-- IBM HR ATTRITION ANALYSIS — SQL QUERIES
-- Author: Arpita Kumari
-- Database: ibm_hr | Table: ibm_hr_data
-- Tool: MySQL Workbench
-- ============================================================

-- ── QUERY 1: Overall Attrition Rate ──────────────────────────
-- Business Question: How bad is the attrition problem overall?
SELECT 
    COUNT(*) AS total_employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS employees_left,
    SUM(CASE WHEN Attrition = 'No' THEN 1 ELSE 0 END) AS employees_stayed,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) 
        AS attrition_rate_pct
FROM ibm_hr_data;
-- Result: 16.12% — above industry benchmark of 10-15%

-- ── QUERY 2: Attrition by Department ─────────────────────────
-- Business Question: Which department is losing the most people?
SELECT 
    Department,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS employees_left,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) 
        AS attrition_pct
FROM ibm_hr_data
GROUP BY Department
ORDER BY attrition_pct DESC;
-- Result: Sales 20.63% | HR 19.05% | R&D 13.84%

-- ── QUERY 3: Overtime Impact on Attrition ────────────────────
-- Business Question: Are we burning employees out?
SELECT 
    OverTime,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS employees_left,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) 
        AS attrition_pct
FROM ibm_hr_data
GROUP BY OverTime
ORDER BY attrition_pct DESC;
-- Result: Overtime Yes = 30.53% vs No = 10.44% (3x difference)

-- ── QUERY 4: Salary Comparison — Left vs Stayed ──────────────
-- Business Question: Do people who leave earn less?
SELECT 
    Attrition,
    JobRole,
    ROUND(AVG(MonthlyIncome), 0) AS avg_monthly_income
FROM ibm_hr_data
GROUP BY Attrition, JobRole
ORDER BY JobRole, Attrition;
-- Result: Most leavers earn less except Research Directors

-- ── QUERY 5: Attrition by Age Group (CTE) ────────────────────
-- Business Question: Which age group is most at risk?
WITH age_buckets AS (
    SELECT *,
        CASE 
            WHEN age < 25 THEN 'Under 25'
            WHEN age BETWEEN 25 AND 34 THEN '25-34'
            WHEN age BETWEEN 35 AND 44 THEN '35-44'
            WHEN age BETWEEN 45 AND 54 THEN '45-54'
            ELSE '55+' 
        END AS age_group
    FROM ibm_hr_data
)
SELECT 
    age_group,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS employees_left,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) 
        AS attrition_pct
FROM age_buckets
GROUP BY age_group
ORDER BY attrition_pct DESC;
-- Result: Under 25 = 39.18% | 25-34 = 20.22% (highest volume)

-- ── QUERY 6: Tenure Risk Ranking (Window Function) ───────────
-- Business Question: At what point in tenure do employees most leave?
SELECT 
    YearsAtCompany,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS employees_left,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) 
        AS attrition_pct,
    RANK() OVER (
        ORDER BY SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) DESC
    ) AS risk_rank
FROM ibm_hr_data
GROUP BY YearsAtCompany
ORDER BY risk_rank;
-- Result: Year 1 = 34.50% (highest meaningful volume) — onboarding failure signal

-- ── QUERY 7: Job Satisfaction vs Attrition ───────────────────
-- Business Question: Does low satisfaction predict leaving?
SELECT 
    JobSatisfaction,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS employees_left,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) 
        AS attrition_pct
FROM ibm_hr_data
GROUP BY JobSatisfaction
ORDER BY JobSatisfaction;
-- Result: Score 1 = 22.84% vs Score 4 = 11.33% (2x difference)

-- ── QUERY 8: Highest Risk Profiles (Multi-factor CTE) ────────
-- Business Question: Which specific employee profile is most likely to leave?
WITH risk_profile AS (
    SELECT 
        Department,
        JobRole,
        OverTime,
        ROUND(AVG(MonthlyIncome), 0) AS avg_income,
        ROUND(AVG(JobSatisfaction), 2) AS avg_satisfaction,
        COUNT(*) AS total_employees,
        SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS employees_left,
        ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) 
            AS attrition_pct
    FROM ibm_hr_data
    GROUP BY Department, JobRole, OverTime
    HAVING COUNT(*) >= 5
)
SELECT * FROM risk_profile
ORDER BY attrition_pct DESC
LIMIT 10;
-- Result: Sales Rep + Overtime = 66.67% — highest risk profile

-- ── QUERY 9: Salary Hike vs Attrition ────────────────────────
-- Business Question: Does a higher salary hike retain employees?
SELECT 
    CASE 
        WHEN PercentSalaryHike < 12 THEN 'Low Hike (< 12%)'
        WHEN PercentSalaryHike BETWEEN 12 AND 15 THEN 'Medium Hike (12-15%)'
        ELSE 'High Hike (> 15%)'
    END AS hike_category,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS employees_left,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) 
        AS attrition_pct
FROM ibm_hr_data
GROUP BY hike_category
ORDER BY attrition_pct DESC;
-- Result: Salary hike alone is NOT the primary retention lever