-- ============================================================================
-- Origence Intelligence Agent - Synthetic Data Generation
-- ============================================================================
-- Purpose: Generate realistic synthetic data for credit union lending platform
-- Data Volume: ~231,450 total rows across 9 tables
-- Execution Time: 10-15 minutes on MEDIUM warehouse
-- ============================================================================

USE DATABASE ORIGENCE_INTELLIGENCE;
USE SCHEMA RAW;
USE WAREHOUSE ORIGENCE_WH;

-- ============================================================================
-- Table 1: CREDIT_UNIONS (1,100 rows)
-- ============================================================================
INSERT INTO CREDIT_UNIONS
WITH states AS (
    SELECT * FROM (VALUES
        ('CA', 'WEST'), ('TX', 'SOUTH'), ('FL', 'SOUTH'), ('NY', 'NORTHEAST'),
        ('PA', 'NORTHEAST'), ('IL', 'MIDWEST'), ('OH', 'MIDWEST'), ('GA', 'SOUTH'),
        ('NC', 'SOUTH'), ('MI', 'MIDWEST'), ('NJ', 'NORTHEAST'), ('VA', 'SOUTH'),
        ('WA', 'WEST'), ('AZ', 'WEST'), ('MA', 'NORTHEAST'), ('TN', 'SOUTH'),
        ('IN', 'MIDWEST'), ('MO', 'MIDWEST'), ('MD', 'SOUTH'), ('WI', 'MIDWEST'),
        ('CO', 'WEST'), ('MN', 'MIDWEST'), ('SC', 'SOUTH'), ('AL', 'SOUTH'),
        ('LA', 'SOUTH'), ('KY', 'SOUTH'), ('OR', 'WEST'), ('OK', 'SOUTH'),
        ('CT', 'NORTHEAST'), ('UT', 'WEST'), ('IA', 'MIDWEST'), ('NV', 'WEST'),
        ('AR', 'SOUTH'), ('MS', 'SOUTH'), ('KS', 'MIDWEST'), ('NM', 'WEST'),
        ('NE', 'MIDWEST'), ('WV', 'SOUTH'), ('ID', 'WEST'), ('HI', 'WEST'),
        ('NH', 'NORTHEAST'), ('ME', 'NORTHEAST'), ('MT', 'WEST'), ('RI', 'NORTHEAST'),
        ('DE', 'NORTHEAST'), ('SD', 'MIDWEST'), ('ND', 'MIDWEST'), ('AK', 'WEST'),
        ('VT', 'NORTHEAST'), ('WY', 'WEST')
    ) AS t(state_code, region)
),
base_sequence AS (
    SELECT SEQ4() AS seq FROM TABLE(GENERATOR(ROWCOUNT => 1100))
)
SELECT
    'CU' || LPAD(seq::VARCHAR, 6, '0') AS credit_union_id,
    CASE MOD(seq, 20)
        WHEN 0 THEN 'Community First Credit Union'
        WHEN 1 THEN 'Members Choice Financial'
        WHEN 2 THEN 'United Federal Credit Union'
        WHEN 3 THEN 'Peoples Trust Credit Union'
        WHEN 4 THEN 'Regional Credit Union'
        WHEN 5 THEN 'State Employees Credit Union'
        WHEN 6 THEN 'Liberty Credit Union'
        WHEN 7 THEN 'Alliance Federal Credit Union'
        WHEN 8 THEN 'First Community Credit Union'
        WHEN 9 THEN 'Prime Financial Credit Union'
        WHEN 10 THEN 'Coastal Credit Union'
        WHEN 11 THEN 'Mountain West Credit Union'
        WHEN 12 THEN 'Heritage Credit Union'
        WHEN 13 THEN 'Summit Credit Union'
        WHEN 14 THEN 'Beacon Credit Union'
        WHEN 15 THEN 'Pioneer Credit Union'
        WHEN 16 THEN 'Keystone Federal Credit Union'
        WHEN 17 THEN 'Gateway Credit Union'
        WHEN 18 THEN 'Horizon Credit Union'
        ELSE 'Lakeside Credit Union'
    END || ' - ' || state_code AS credit_union_name,
    CASE 
        WHEN seq <= 110 THEN 'TIER_1'
        WHEN seq <= 440 THEN 'TIER_2'
        WHEN seq <= 880 THEN 'TIER_3'
        ELSE 'TIER_4'
    END AS credit_union_tier,
    state_code AS state,
    region AS region,
    CASE 
        WHEN seq <= 110 THEN UNIFORM(50000, 150000, RANDOM())
        WHEN seq <= 440 THEN UNIFORM(20000, 50000, RANDOM())
        WHEN seq <= 880 THEN UNIFORM(5000, 20000, RANDOM())
        ELSE UNIFORM(1000, 5000, RANDOM())
    END AS member_count,
    CASE 
        WHEN seq <= 110 THEN UNIFORM(500, 2000, RANDOM())
        WHEN seq <= 440 THEN UNIFORM(200, 500, RANDOM())
        WHEN seq <= 880 THEN UNIFORM(50, 200, RANDOM())
        ELSE UNIFORM(10, 50, RANDOM())
    END AS asset_size_millions,
    0 AS total_loans_funded,
    0 AS avg_loan_amount,
    0 AS default_rate,
    0 AS approval_rate,
    'ACTIVE' AS active_status,
    DATEADD(month, -UNIFORM(12, 360, RANDOM()), CURRENT_DATE()) AS partnership_start_date,
    CURRENT_TIMESTAMP() AS created_at,
    CURRENT_TIMESTAMP() AS last_updated
FROM base_sequence
CROSS JOIN states
WHERE MOD(seq, 50) = MOD(ASCII(state_code), 50)
LIMIT 1100;

SELECT 'Credit Unions: ' || COUNT(*) || ' rows inserted' AS status FROM CREDIT_UNIONS;

-- ============================================================================
-- Table 2: MEMBERS (100,000 rows)
-- ============================================================================
INSERT INTO MEMBERS
WITH base_members AS (
    SELECT SEQ4() AS seq FROM TABLE(GENERATOR(ROWCOUNT => 100000))
)
SELECT
    'MBR' || LPAD(seq::VARCHAR, 8, '0') AS member_id,
    'CU' || LPAD(UNIFORM(1, 1100, RANDOM())::VARCHAR, 6, '0') AS credit_union_id,
    UNIFORM(18, 80, RANDOM()) AS age,
    CASE 
        WHEN UNIFORM(0, 100, RANDOM()) < 5 THEN UNIFORM(300, 579, RANDOM())
        WHEN UNIFORM(0, 100, RANDOM()) < 20 THEN UNIFORM(580, 669, RANDOM())
        WHEN UNIFORM(0, 100, RANDOM()) < 50 THEN UNIFORM(670, 739, RANDOM())
        WHEN UNIFORM(0, 100, RANDOM()) < 80 THEN UNIFORM(740, 799, RANDOM())
        ELSE UNIFORM(800, 850, RANDOM())
    END AS credit_score,
    CASE 
        WHEN UNIFORM(0, 100, RANDOM()) < 20 THEN UNIFORM(25000, 40000, RANDOM())
        WHEN UNIFORM(0, 100, RANDOM()) < 50 THEN UNIFORM(40000, 60000, RANDOM())
        WHEN UNIFORM(0, 100, RANDOM()) < 75 THEN UNIFORM(60000, 80000, RANDOM())
        WHEN UNIFORM(0, 100, RANDOM()) < 90 THEN UNIFORM(80000, 100000, RANDOM())
        ELSE UNIFORM(100000, 200000, RANDOM())
    END AS annual_income,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN 'FULL_TIME'
        WHEN 2 THEN 'FULL_TIME'
        WHEN 3 THEN 'FULL_TIME'
        WHEN 4 THEN 'PART_TIME'
        ELSE 'SELF_EMPLOYED'
    END AS employment_status,
    UNIFORM(3, 480, RANDOM()) AS employment_length_months,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'OWN'
        WHEN 2 THEN 'RENT'
        WHEN 3 THEN 'MORTGAGE'
        ELSE 'RENT'
    END AS housing_status,
    CASE UNIFORM(1, 50, RANDOM())
        WHEN 1 THEN 'CA' WHEN 2 THEN 'TX' WHEN 3 THEN 'FL' WHEN 4 THEN 'NY'
        WHEN 5 THEN 'PA' WHEN 6 THEN 'IL' WHEN 7 THEN 'OH' WHEN 8 THEN 'GA'
        WHEN 9 THEN 'NC' WHEN 10 THEN 'MI' WHEN 11 THEN 'NJ' WHEN 12 THEN 'VA'
        WHEN 13 THEN 'WA' WHEN 14 THEN 'AZ' WHEN 15 THEN 'MA' WHEN 16 THEN 'TN'
        WHEN 17 THEN 'IN' WHEN 18 THEN 'MO' WHEN 19 THEN 'MD' WHEN 20 THEN 'WI'
        WHEN 21 THEN 'CO' WHEN 22 THEN 'MN' WHEN 23 THEN 'SC' WHEN 24 THEN 'AL'
        WHEN 25 THEN 'LA' ELSE 'CA'
    END AS state,
    DATEADD(month, -UNIFORM(1, 240, RANDOM()), CURRENT_DATE()) AS member_since_date,
    0 AS total_loans,
    0 AS total_loan_amount,
    UNIFORM(0, 1, RANDOM())::BOOLEAN AS has_checking,
    UNIFORM(0, 1, RANDOM())::BOOLEAN AS has_savings,
    UNIFORM(0, 1, RANDOM())::BOOLEAN AS has_credit_card,
    CASE 
        WHEN UNIFORM(0, 100, RANDOM()) < 25 THEN 'BRONZE'
        WHEN UNIFORM(0, 100, RANDOM()) < 60 THEN 'SILVER'
        WHEN UNIFORM(0, 100, RANDOM()) < 85 THEN 'GOLD'
        ELSE 'PLATINUM'
    END AS member_tier,
    CURRENT_TIMESTAMP() AS created_at,
    CURRENT_TIMESTAMP() AS last_updated
FROM base_members;

SELECT 'Members: ' || COUNT(*) || ' rows inserted' AS status FROM MEMBERS;

-- ============================================================================
-- Table 3: DEALERS (20,000 rows)
-- ============================================================================
INSERT INTO DEALERS
WITH base_dealers AS (
    SELECT SEQ4() AS seq FROM TABLE(GENERATOR(ROWCOUNT => 20000))
),
dealer_names AS (
    SELECT * FROM (VALUES
        ('Premium Auto Group'), ('Elite Motors'), ('Quality Auto Sales'),
        ('Prime Auto Dealership'), ('Superior Motors'), ('Classic Cars'),
        ('Precision Auto'), ('Reliable Motors'), ('Affordable Auto'),
        ('Best Buy Motors'), ('Top Choice Auto'), ('Value Auto Sales'),
        ('Summit Motors'), ('Prestige Auto'), ('Excellence Motors'),
        ('Royal Auto Group'), ('Liberty Motors'), ('Victory Auto'),
        ('Heritage Motors'), ('Freedom Auto Sales')
    ) AS t(dealer_name)
)
SELECT
    'DLR' || LPAD(seq::VARCHAR, 6, '0') AS dealer_id,
    (SELECT dealer_name FROM dealer_names OFFSET UNIFORM(0, 19, RANDOM()) ROWS FETCH NEXT 1 ROW ONLY) || ' - ' || 
    CASE UNIFORM(1, 50, RANDOM())
        WHEN 1 THEN 'CA' WHEN 2 THEN 'TX' WHEN 3 THEN 'FL' WHEN 4 THEN 'NY'
        WHEN 5 THEN 'PA' WHEN 6 THEN 'IL' WHEN 7 THEN 'OH' WHEN 8 THEN 'GA'
        ELSE 'CA'
    END AS dealer_name,
    CASE UNIFORM(1, 6, RANDOM())
        WHEN 1 THEN 'NEW_CAR_FRANCHISE'
        WHEN 2 THEN 'USED_CAR_DEALER'
        WHEN 3 THEN 'LUXURY_DEALER'
        WHEN 4 THEN 'INDEPENDENT_DEALER'
        WHEN 5 THEN 'BUY_HERE_PAY_HERE'
        ELSE 'NEW_CAR_FRANCHISE'
    END AS dealer_type,
    CASE UNIFORM(1, 50, RANDOM())
        WHEN 1 THEN 'CA' WHEN 2 THEN 'TX' WHEN 3 THEN 'FL' WHEN 4 THEN 'NY'
        WHEN 5 THEN 'PA' WHEN 6 THEN 'IL' WHEN 7 THEN 'OH' WHEN 8 THEN 'GA'
        WHEN 9 THEN 'NC' WHEN 10 THEN 'MI' WHEN 11 THEN 'NJ' WHEN 12 THEN 'VA'
        WHEN 13 THEN 'WA' WHEN 14 THEN 'AZ' WHEN 15 THEN 'MA' WHEN 16 THEN 'TN'
        ELSE 'CA'
    END AS state,
    CASE 
        WHEN state IN ('CA', 'TX', 'FL', 'NY') THEN 'WEST'
        WHEN state IN ('PA', 'MA', 'NJ') THEN 'NORTHEAST'
        WHEN state IN ('IL', 'OH', 'MI') THEN 'MIDWEST'
        ELSE 'SOUTH'
    END AS region,
    CASE WHEN UNIFORM(0, 100, RANDOM()) < 75 THEN TRUE ELSE FALSE END AS cudl_certified,
    0 AS total_loans_facilitated,
    0 AS avg_loan_amount,
    UNIFORM(35, 50, RANDOM()) / 10.0 AS member_satisfaction_score,
    DATEADD(month, -UNIFORM(6, 120, RANDOM()), CURRENT_DATE()) AS partnership_start_date,
    'ACTIVE' AS active_status,
    CURRENT_TIMESTAMP() AS created_at,
    CURRENT_TIMESTAMP() AS last_updated
FROM base_dealers;

SELECT 'Dealers: ' || COUNT(*) || ' rows inserted' AS status FROM DEALERS;

-- ============================================================================
-- Table 4: LOAN_OFFICERS (250 rows)
-- ============================================================================
INSERT INTO LOAN_OFFICERS
WITH base_officers AS (
    SELECT SEQ4() AS seq FROM TABLE(GENERATOR(ROWCOUNT => 250))
),
first_names AS (
    SELECT * FROM (VALUES
        ('James'), ('Mary'), ('John'), ('Patricia'), ('Robert'),
        ('Jennifer'), ('Michael'), ('Linda'), ('William'), ('Elizabeth'),
        ('David'), ('Barbara'), ('Richard'), ('Susan'), ('Joseph'),
        ('Jessica'), ('Thomas'), ('Sarah'), ('Christopher'), ('Karen')
    ) AS t(first_name)
),
last_names AS (
    SELECT * FROM (VALUES
        ('Smith'), ('Johnson'), ('Williams'), ('Brown'), ('Jones'),
        ('Garcia'), ('Miller'), ('Davis'), ('Rodriguez'), ('Martinez'),
        ('Hernandez'), ('Lopez'), ('Gonzalez'), ('Wilson'), ('Anderson'),
        ('Thomas'), ('Taylor'), ('Moore'), ('Jackson'), ('Martin')
    ) AS t(last_name)
)
SELECT
    'OFF' || LPAD(seq::VARCHAR, 5, '0') AS officer_id,
    (SELECT first_name FROM first_names OFFSET UNIFORM(0, 19, RANDOM()) ROWS FETCH NEXT 1 ROW ONLY) || ' ' ||
    (SELECT last_name FROM last_names OFFSET UNIFORM(0, 19, RANDOM()) ROWS FETCH NEXT 1 ROW ONLY) AS officer_name,
    'CU' || LPAD(UNIFORM(1, 1100, RANDOM())::VARCHAR, 6, '0') AS credit_union_id,
    DATEADD(month, -UNIFORM(12, 300, RANDOM()), CURRENT_DATE()) AS hire_date,
    FLOOR(UNIFORM(12, 300, RANDOM()) / 12) AS experience_years,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'AUTO_LOANS'
        WHEN 2 THEN 'PERSONAL_LOANS'
        WHEN 3 THEN 'MORTGAGE_LOANS'
        ELSE 'GENERAL_LENDING'
    END AS specialization,
    0 AS total_loans_processed,
    0 AS avg_approval_rate,
    0 AS avg_processing_days,
    'ACTIVE' AS active_status,
    CURRENT_TIMESTAMP() AS created_at,
    CURRENT_TIMESTAMP() AS last_updated
FROM base_officers;

SELECT 'Loan Officers: ' || COUNT(*) || ' rows inserted' AS status FROM LOAN_OFFICERS;

-- ============================================================================
-- Table 5: LOAN_APPLICATIONS (50,000 rows)
-- ============================================================================
INSERT INTO LOAN_APPLICATIONS
WITH base_apps AS (
    SELECT SEQ4() AS seq FROM TABLE(GENERATOR(ROWCOUNT => 50000))
)
SELECT
    'APP' || LPAD(seq::VARCHAR, 8, '0') AS application_id,
    'MBR' || LPAD(UNIFORM(1, 100000, RANDOM())::VARCHAR, 8, '0') AS member_id,
    m.credit_union_id,
    'OFF' || LPAD(UNIFORM(1, 250, RANDOM())::VARCHAR, 5, '0') AS loan_officer_id,
    CASE WHEN UNIFORM(0, 100, RANDOM()) < 60 THEN 'DLR' || LPAD(UNIFORM(1, 20000, RANDOM())::VARCHAR, 6, '0') ELSE NULL END AS dealer_id,
    DATEADD(day, -UNIFORM(1, 365, RANDOM()), CURRENT_DATE()) AS application_date,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN 'AUTO_LOAN'
        WHEN 2 THEN 'AUTO_LOAN'
        WHEN 3 THEN 'PERSONAL_LOAN'
        WHEN 4 THEN 'HOME_EQUITY'
        ELSE 'AUTO_LOAN'
    END AS loan_type,
    CASE 
        WHEN loan_type = 'AUTO_LOAN' THEN 'VEHICLE_PURCHASE'
        WHEN loan_type = 'PERSONAL_LOAN' THEN CASE UNIFORM(1, 3, RANDOM())
            WHEN 1 THEN 'DEBT_CONSOLIDATION'
            WHEN 2 THEN 'HOME_IMPROVEMENT'
            ELSE 'MAJOR_PURCHASE'
        END
        ELSE 'HOME_EQUITY_LINE'
    END AS loan_purpose,
    CASE 
        WHEN loan_type = 'AUTO_LOAN' THEN UNIFORM(15000, 45000, RANDOM())
        WHEN loan_type = 'PERSONAL_LOAN' THEN UNIFORM(5000, 35000, RANDOM())
        ELSE UNIFORM(20000, 100000, RANDOM())
    END AS requested_amount,
    CASE 
        WHEN loan_type = 'AUTO_LOAN' THEN UNIFORM(36, 72, RANDOM())
        WHEN loan_type = 'PERSONAL_LOAN' THEN UNIFORM(24, 60, RANDOM())
        ELSE UNIFORM(60, 180, RANDOM())
    END AS loan_term_months,
    CASE 
        WHEN m.credit_score >= 740 THEN UNIFORM(35, 55, RANDOM()) / 10.0
        WHEN m.credit_score >= 670 THEN UNIFORM(55, 75, RANDOM()) / 10.0
        WHEN m.credit_score >= 580 THEN UNIFORM(75, 105, RANDOM()) / 10.0
        ELSE UNIFORM(105, 145, RANDOM()) / 10.0
    END AS interest_rate,
    m.credit_score AS credit_score_at_app,
    m.annual_income,
    UNIFORM(15, 50, RANDOM()) / 100.0 AS debt_to_income_ratio,
    CASE WHEN UNIFORM(0, 100, RANDOM()) < 85 THEN TRUE ELSE FALSE END AS employment_verified,
    CASE WHEN loan_type = 'AUTO_LOAN' THEN requested_amount * UNIFORM(110, 150, RANDOM()) / 100.0 ELSE NULL END AS collateral_value,
    CASE WHEN loan_type = 'AUTO_LOAN' THEN requested_amount * UNIFORM(10, 25, RANDOM()) / 100.0 ELSE 0 END AS down_payment_amount,
    CASE WHEN collateral_value > 0 THEN requested_amount::FLOAT / collateral_value ELSE NULL END AS loan_to_value_ratio,
    CASE 
        WHEN m.credit_score >= 740 AND debt_to_income_ratio < 0.35 AND employment_verified THEN 
            CASE UNIFORM(1, 100, RANDOM()) WHEN 1 THEN 'DENIED' WHEN 2 THEN 'PENDING' ELSE 'APPROVED' END
        WHEN m.credit_score >= 670 AND debt_to_income_ratio < 0.43 THEN
            CASE UNIFORM(1, 100, RANDOM()) WHEN 1 THEN 'DENIED' WHEN 2 THEN 'DENIED' ELSE CASE UNIFORM(1, 2, RANDOM()) WHEN 1 THEN 'APPROVED' ELSE 'PENDING' END END
        WHEN m.credit_score >= 580 THEN
            CASE UNIFORM(1, 3, RANDOM()) WHEN 1 THEN 'APPROVED' WHEN 2 THEN 'DENIED' ELSE 'PENDING' END
        ELSE 'DENIED'
    END AS application_status,
    CASE 
        WHEN application_status IN ('APPROVED', 'DENIED') THEN DATEADD(day, UNIFORM(1, 14, RANDOM()), application_date)
        ELSE NULL
    END AS decision_date,
    CASE 
        WHEN application_status = 'DENIED' THEN CASE UNIFORM(1, 5, RANDOM())
            WHEN 1 THEN 'Insufficient credit history'
            WHEN 2 THEN 'High debt-to-income ratio'
            WHEN 3 THEN 'Unable to verify employment'
            WHEN 4 THEN 'Low credit score'
            ELSE 'Insufficient collateral value'
        END
        WHEN application_status = 'APPROVED' THEN 'Application meets all lending criteria'
        ELSE NULL
    END AS decision_reason,
    CASE WHEN decision_date IS NOT NULL THEN DATEDIFF(day, application_date, decision_date) ELSE NULL END AS days_to_decision,
    CURRENT_TIMESTAMP() AS created_at,
    CURRENT_TIMESTAMP() AS last_updated
FROM base_apps
INNER JOIN MEMBERS m ON m.member_id = 'MBR' || LPAD(UNIFORM(1, 100000, RANDOM())::VARCHAR, 8, '0');

SELECT 'Loan Applications: ' || COUNT(*) || ' rows inserted' AS status FROM LOAN_APPLICATIONS;

-- ============================================================================
-- Table 6: LOANS (35,000 rows - approved applications only)
-- ============================================================================
INSERT INTO LOANS
SELECT
    'LN' || LPAD(ROW_NUMBER() OVER (ORDER BY a.application_date)::VARCHAR, 8, '0') AS loan_id,
    a.application_id,
    a.member_id,
    a.credit_union_id,
    a.loan_officer_id,
    a.dealer_id,
    a.decision_date AS origination_date,
    a.loan_type,
    a.loan_purpose,
    a.requested_amount AS original_loan_amount,
    a.requested_amount * UNIFORM(70, 100, RANDOM()) / 100.0 AS current_balance,
    a.loan_term_months,
    a.interest_rate,
    (a.requested_amount * (a.interest_rate / 1200) * POWER(1 + a.interest_rate / 1200, a.loan_term_months)) / 
        (POWER(1 + a.interest_rate / 1200, a.loan_term_months) - 1) AS monthly_payment,
    FLOOR(DATEDIFF(month, a.decision_date, CURRENT_DATE())) AS payments_made,
    a.loan_term_months - FLOOR(DATEDIFF(month, a.decision_date, CURRENT_DATE())) AS payments_remaining,
    CASE 
        WHEN UNIFORM(0, 100, RANDOM()) < 3 THEN UNIFORM(31, 90, RANDOM())
        WHEN UNIFORM(0, 100, RANDOM()) < 8 THEN UNIFORM(1, 30, RANDOM())
        ELSE 0
    END AS days_past_due,
    CASE 
        WHEN days_past_due = 0 THEN 'CURRENT'
        WHEN days_past_due <= 30 THEN '30_DAYS'
        WHEN days_past_due <= 60 THEN '60_DAYS'
        WHEN days_past_due <= 90 THEN '90_DAYS'
        ELSE 'SERIOUS_DELINQUENCY'
    END AS delinquency_status,
    CASE WHEN days_past_due > 120 AND UNIFORM(0, 100, RANDOM()) < 60 THEN TRUE ELSE FALSE END AS has_defaulted,
    CASE WHEN has_defaulted THEN DATEADD(day, UNIFORM(120, 365, RANDOM()), origination_date) ELSE NULL END AS default_date,
    monthly_payment * payments_made * 0.3 AS total_interest_paid,
    CASE 
        WHEN has_defaulted THEN 'CHARGED_OFF'
        WHEN current_balance <= 0 THEN 'PAID_OFF'
        ELSE 'ACTIVE'
    END AS loan_status,
    DATEADD(month, a.loan_term_months, a.decision_date) AS maturity_date,
    CURRENT_TIMESTAMP() AS created_at,
    CURRENT_TIMESTAMP() AS last_updated
FROM LOAN_APPLICATIONS a
WHERE a.application_status = 'APPROVED'
  AND a.decision_date IS NOT NULL
LIMIT 35000;

SELECT 'Loans: ' || COUNT(*) || ' rows inserted' AS status FROM LOANS;

-- ============================================================================
-- Table 7: UNDERWRITING_NOTES (15,000 rows)
-- ============================================================================
INSERT INTO UNDERWRITING_NOTES
WITH base_notes AS (
    SELECT 
        a.application_id,
        a.loan_officer_id,
        a.application_date,
        a.application_status,
        a.credit_score_at_app,
        a.debt_to_income_ratio,
        ROW_NUMBER() OVER (ORDER BY a.application_date) AS seq
    FROM LOAN_APPLICATIONS a
    WHERE UNIFORM(0, 100, RANDOM()) < 30
    LIMIT 15000
)
SELECT
    'NOTE' || LPAD(seq::VARCHAR, 8, '0') AS note_id,
    application_id,
    loan_officer_id,
    CASE UNIFORM(1, 10, RANDOM())
        WHEN 1 THEN 'Reviewed applicant credit history. Score of ' || credit_score_at_app || ' reflects strong payment history with no recent delinquencies. Employment verification completed through HR department. Debt-to-income ratio of ' || ROUND(debt_to_income_ratio * 100, 1) || '% is within acceptable range for this loan type.'
        WHEN 2 THEN 'Applicant provided comprehensive documentation including pay stubs, tax returns, and bank statements. Income appears stable with consistent monthly deposits. Collateral appraisal came in at expected value. Recommend approval with standard terms.'
        WHEN 3 THEN 'Credit score indicates some payment irregularities in past 24 months. Spoke with applicant regarding previous late payments - explained circumstances were due to temporary job loss, now resolved. Current employment verified stable for 18 months. Conditional approval recommended pending verification of recent accounts.'
        WHEN 4 THEN 'High DTI ratio of ' || ROUND(debt_to_income_ratio * 100, 1) || '% raises concerns about repayment capacity. However, strong credit history and substantial down payment mitigate risk. Applicant has significant liquid assets in savings. Approval recommended with rate adjustment for risk.'
        WHEN 5 THEN 'Applicant is existing member in good standing with checking and savings accounts. Previous auto loan paid off early with no late payments. Employment verification shows 8 years with current employer. Strong application - recommend approval at premium rate tier.'
        WHEN 6 THEN 'Documentation review reveals inconsistencies in reported income versus tax returns. Requested additional documentation from applicant. Self-employment income appears variable. Will require 3 years of tax returns and YTD profit/loss statements before making final determination.'
        WHEN 7 THEN 'Credit report shows recent credit inquiries across multiple lenders. Discussed with applicant - shopping for best rates on planned vehicle purchase. No new debt taken on. Credit score of ' || credit_score_at_app || ' supports approval. Normal processing recommended.'
        WHEN 8 THEN 'Collateral value assessment completed. Vehicle appraisal shows LTV ratio well within guidelines. No title issues identified. Insurance requirements discussed with member. All underwriting criteria met - recommend standard approval.'
        WHEN 9 THEN 'Applicant has thin credit file with limited payment history. However, employment is stable and income documentation is strong. Co-signer with excellent credit (780+) willing to guarantee loan. Approval recommended with co-signer requirement.'
        ELSE 'Standard application review completed. All documentation in order. Credit profile, income verification, and collateral assessment all meet lending criteria. Recommend approval at standard rates and terms for this loan category.'
    END AS note_text,
    application_date AS note_date,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN 'CREDIT_REVIEW'
        WHEN 2 THEN 'INCOME_VERIFICATION'
        WHEN 3 THEN 'COLLATERAL_ASSESSMENT'
        WHEN 4 THEN 'RISK_ASSESSMENT'
        ELSE 'GENERAL_UNDERWRITING'
    END AS note_category,
    CASE WHEN application_status IN ('APPROVED', 'DENIED') THEN TRUE ELSE FALSE END AS decision_factor,
    CURRENT_TIMESTAMP() AS created_at
FROM base_notes;

SELECT 'Underwriting Notes: ' || COUNT(*) || ' rows inserted' AS status FROM UNDERWRITING_NOTES;

-- ============================================================================
-- Table 8: LOAN_DOCUMENTS (10,000 rows)
-- ============================================================================
INSERT INTO LOAN_DOCUMENTS
WITH base_docs AS (
    SELECT 
        l.loan_id,
        l.application_id,
        l.origination_date,
        ROW_NUMBER() OVER (ORDER BY l.origination_date) AS seq
    FROM LOANS l
    WHERE UNIFORM(0, 100, RANDOM()) < 30
    LIMIT 10000
)
SELECT
    'DOC' || LPAD(seq::VARCHAR, 8, '0') AS document_id,
    loan_id,
    application_id,
    CASE UNIFORM(1, 8, RANDOM())
        WHEN 1 THEN 'PAY_STUB'
        WHEN 2 THEN 'TAX_RETURN'
        WHEN 3 THEN 'BANK_STATEMENT'
        WHEN 4 THEN 'EMPLOYMENT_LETTER'
        WHEN 5 THEN 'VEHICLE_TITLE'
        WHEN 6 THEN 'INSURANCE_PROOF'
        WHEN 7 THEN 'APPRAISAL_REPORT'
        ELSE 'LOAN_CONTRACT'
    END AS document_type,
    CASE document_type
        WHEN 'PAY_STUB' THEN 'Pay period ending ' || TO_CHAR(origination_date, 'MM/DD/YYYY') || '. Gross Pay: $4,250.00. Federal Tax: $637.50. State Tax: $212.50. FICA: $325.13. Net Pay: $3,075.00. Year-to-Date Gross: $51,000.00. Employer: ABC Corporation. Employee verification completed.'
        WHEN 'TAX_RETURN' THEN 'Form 1040 U.S. Individual Income Tax Return for tax year ' || YEAR(origination_date) || '. Wages, salaries, tips: $85,000. Interest income: $1,250. Capital gains: $3,500. Adjusted Gross Income: $89,750. Standard deduction: $12,950. Taxable income: $76,800. Total tax: $13,244. Verified with IRS transcript.'
        WHEN 'BANK_STATEMENT' THEN 'Account statement for period ending ' || TO_CHAR(origination_date, 'MM/DD/YYYY') || '. Beginning balance: $8,450.23. Total deposits: $4,250.00 (salary deposits consistent). Total withdrawals: $3,125.67. Ending balance: $9,574.56. Average balance: $9,000. No NSF or overdraft fees.'
        WHEN 'EMPLOYMENT_LETTER' THEN 'To Whom It May Concern: This letter confirms employment of applicant with our company since ' || TO_CHAR(DATEADD(year, -5, origination_date), 'MM/DD/YYYY') || '. Current position: Senior Analyst. Employment status: Full-time. Base salary: $85,000 annually. Employment is in good standing with no disciplinary issues.'
        WHEN 'VEHICLE_TITLE' THEN 'Certificate of Title - State DMV. Vehicle: 2021 Honda Accord. VIN: 1HGCV1F3XLA123456. Owner: Applicant Name. Lien holder: None. Odometer: 24,500 miles. Title status: Clean, no salvage or flood damage. Title issued: ' || TO_CHAR(origination_date, 'MM/DD/YYYY') || '.'
        WHEN 'INSURANCE_PROOF' THEN 'Certificate of Insurance. Policy Number: AUTO-987654321. Effective Date: ' || TO_CHAR(origination_date, 'MM/DD/YYYY') || '. Coverage: Comprehensive and Collision. Deductible: $500. Liability limits: $100,000/$300,000. Named insured: Applicant. Loss payee: Credit Union as lienholder.'
        WHEN 'APPRAISAL_REPORT' THEN 'Vehicle Appraisal Report dated ' || TO_CHAR(origination_date, 'MM/DD/YYYY') || '. Vehicle condition: Excellent. Mileage: 24,500. Market value: $28,500. Wholesale value: $26,000. Retail value: $30,500. Comparable sales support valuation. No damage or mechanical issues noted.'
        ELSE 'Loan Agreement effective ' || TO_CHAR(origination_date, 'MM/DD/YYYY') || '. Principal amount: $27,500. Interest rate: 4.99% APR. Term: 60 months. Monthly payment: $518.00. Late payment fee: $25. Prepayment: Allowed without penalty. Borrower and lender signatures verified.'
    END AS document_text,
    CASE UNIFORM(1, 3, RANDOM())
        WHEN 1 THEN 'VERIFICATION'
        WHEN 2 THEN 'LEGAL'
        ELSE 'SUPPORTING'
    END AS document_category,
    origination_date AS upload_date,
    CURRENT_TIMESTAMP() AS created_at
FROM base_docs;

SELECT 'Loan Documents: ' || COUNT(*) || ' rows inserted' AS status FROM LOAN_DOCUMENTS;

-- ============================================================================
-- Table 9: COMPLIANCE_POLICIES (50 rows)
-- ============================================================================
INSERT INTO COMPLIANCE_POLICIES
WITH policy_data AS (
    SELECT * FROM (VALUES
        ('Fair Lending Policy', 'POLICY001', 'LENDING', 'FAIR_LENDING', 'Our institution is committed to fair and equitable lending practices in compliance with the Equal Credit Opportunity Act (ECOA) and Fair Housing Act. All credit decisions must be based solely on creditworthiness factors including credit history, income, employment stability, and debt-to-income ratio. Prohibited factors include race, color, religion, national origin, sex, marital status, age, or because an applicant receives public assistance. All loan officers must complete annual fair lending training. Regular monitoring and testing ensure compliance with fair lending requirements.', 'fair lending, ECOA, discrimination, equal opportunity'),
        ('Truth in Lending Act Compliance', 'POLICY002', 'DISCLOSURE', 'TILA', 'All consumer credit transactions must comply with Regulation Z implementing the Truth in Lending Act. Loan officers must provide clear and conspicuous disclosure of Annual Percentage Rate (APR), finance charges, amount financed, total of payments, and payment schedule. Disclosures must be provided within required timeframes: initial disclosure within 3 business days, final disclosure at least 3 days before consummation. Right of rescission applies to certain transactions. APR calculations must be accurate and include all applicable fees.', 'TILA, Regulation Z, APR, disclosure, finance charge'),
        ('Bank Secrecy Act and Anti-Money Laundering', 'POLICY003', 'COMPLIANCE', 'BSA_AML', 'The institution maintains a comprehensive BSA/AML program to detect and prevent money laundering and terrorist financing. Customer identification program (CIP) requires verification of identity for all new accounts. Currency Transaction Reports (CTRs) must be filed for cash transactions exceeding $10,000. Suspicious Activity Reports (SARs) must be filed within required timeframes when suspicious activity is identified. All employees receive BSA/AML training annually. Enhanced due diligence applies to high-risk customers.', 'BSA, AML, CTR, SAR, money laundering, CIP'),
        ('Auto Loan Collateral Requirements', 'POLICY004', 'LENDING', 'COLLATERAL', 'Auto loan collateral requirements ensure adequate security for vehicle financing. Maximum loan-to-value ratio is 110% for new vehicles, 100% for used vehicles. Vehicles must be no older than 10 years at loan origination. Mileage limits: new vehicles under 7,500 miles, used vehicles under 100,000 miles. Comprehensive and collision insurance required with institution named as loss payee. Title must be clear with no salvage or flood damage history. Vehicle appraisals required for loans exceeding $50,000.', 'auto loan, collateral, LTV, vehicle title, insurance'),
        ('Debt-to-Income Ratio Guidelines', 'POLICY005', 'UNDERWRITING', 'DTI', 'Debt-to-income ratio guidelines establish maximum acceptable debt levels relative to gross monthly income. Maximum DTI ratio is 43% for conventional loans, with exceptions up to 50% for compensating factors such as excellent credit scores (750+), significant liquid reserves (6+ months), or substantial down payments (20%+). DTI calculation includes all recurring monthly debt obligations: mortgage/rent, auto loans, student loans, credit cards, child support, and alimony. Documentation of all debts required from credit report and applicant disclosure.', 'DTI, debt-to-income, underwriting, qualifying ratio'),
        ('Credit Score Minimum Requirements', 'POLICY006', 'UNDERWRITING', 'CREDIT_SCORE', 'Minimum credit score requirements vary by loan type and risk profile. Auto loans: 620 minimum for standard terms, 580-619 requires enhanced review and rate adjustment. Personal loans: 640 minimum. Home equity: 680 minimum. Applicants below minimums may qualify with strong compensating factors including high income, low DTI, substantial down payment, or qualified co-signer. Credit score must be from recognized consumer reporting agency (Experian, TransUnion, Equifax). Score must be current within 90 days of application.', 'credit score, FICO, credit history, underwriting standards'),
        ('Employment Verification Standards', 'POLICY007', 'VERIFICATION', 'EMPLOYMENT', 'Employment verification is required for all loan applications to confirm income stability and repayment capacity. Acceptable verification methods include: verbal verification with HR department, written employment letter on company letterhead, recent pay stubs (30 days) showing year-to-date income, or W-2 forms for prior year. Self-employed applicants require 2 years of tax returns including Schedule C. Minimum employment length: 2 years same employer or same field. Job changes within 60 days of application require additional review.', 'employment verification, income, pay stub, tax return'),
        ('Privacy and Information Security', 'POLICY008', 'DATA_PROTECTION', 'PRIVACY', 'Institution maintains strict privacy and security controls pursuant to the Gramm-Leach-Bliley Act (GLBA) and state privacy laws. Customer nonpublic personal information (NPI) is protected through administrative, technical, and physical safeguards. Access to NPI limited to employees with legitimate business need. Annual privacy notices provided to customers. Vendor management program ensures third parties maintain adequate security. Data encryption required for electronic transmission. Secure disposal of paper and electronic records containing NPI. Privacy breach response plan maintained and tested annually.', 'privacy, GLBA, data security, NPI, confidentiality'),
        ('Adverse Action Notice Requirements', 'POLICY009', 'DISCLOSURE', 'ADVERSE_ACTION', 'Adverse action notices must be provided when credit applications are denied, approved for lesser amount, or approved with less favorable terms. Notice must be provided within 30 days of adverse action and include: specific reasons for action, credit score disclosure if score was factor, credit reporting agency contact information, and notice of right to obtain free credit report. Acceptable reasons must relate to creditworthiness: insufficient credit history, high debt-to-income ratio, low credit score, delinquent credit history, insufficient collateral. General or vague reasons not permitted.', 'adverse action, denial, ECOA, credit score disclosure'),
        ('Flood Insurance Requirements', 'POLICY010', 'COMPLIANCE', 'FLOOD_INSURANCE', 'Flood insurance required for all loans secured by collateral located in Special Flood Hazard Area (SFHA) as designated by FEMA. Standard Flood Hazard Determination must be performed using approved vendor within 15 days of application. Coverage must equal lesser of: outstanding loan balance, maximum coverage available, or insurable value of collateral. Coverage must be maintained for life of loan. Notice of requirement must be provided to borrower at application. Force-placed flood insurance may be purchased if borrower fails to maintain required coverage.', 'flood insurance, SFHA, FEMA, hazard determination')
    ) AS t(title, policy_id, category, regulation, content, keywords)
)
SELECT
    policy_id,
    title AS policy_title,
    content AS policy_content,
    category AS policy_category,
    regulation AS regulation_type,
    DATEADD(month, -UNIFORM(6, 36, RANDOM()), CURRENT_DATE()) AS effective_date,
    DATEADD(month, -UNIFORM(1, 6, RANDOM()), CURRENT_DATE()) AS last_review_date,
    keywords,
    CURRENT_TIMESTAMP() AS created_at,
    CURRENT_TIMESTAMP() AS last_updated
FROM policy_data;

-- Additional 40 policies
INSERT INTO COMPLIANCE_POLICIES
WITH additional_policies AS (
    SELECT SEQ4() AS seq FROM TABLE(GENERATOR(ROWCOUNT => 40))
)
SELECT
    'POLICY' || LPAD((seq + 11)::VARCHAR, 3, '0') AS policy_id,
    CASE UNIFORM(1, 8, RANDOM())
        WHEN 1 THEN 'Interest Rate Determination Guidelines'
        WHEN 2 THEN 'Loan Officer Authority Limits'
        WHEN 3 THEN 'Collection and Recovery Procedures'
        WHEN 4 THEN 'Loan Modification Standards'
        WHEN 5 THEN 'Co-Signer and Guarantor Requirements'
        WHEN 6 THEN 'Loan Servicing Quality Standards'
        WHEN 7 THEN 'Member Communication Protocols'
        ELSE 'Risk-Based Pricing Methodology'
    END AS policy_title,
    'This policy establishes standards and procedures for ' || policy_title || '. All lending personnel must adhere to these guidelines to ensure consistent, compliant, and fair treatment of all members. Policy requirements include documentation standards, approval workflows, exception handling procedures, and quality control measures. Regular policy review ensures alignment with regulatory requirements and industry best practices. Training on policy requirements is mandatory for all staff involved in lending operations. Violations of policy may result in disciplinary action.' AS policy_content,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'LENDING'
        WHEN 2 THEN 'UNDERWRITING'
        WHEN 3 THEN 'COMPLIANCE'
        ELSE 'OPERATIONS'
    END AS policy_category,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN 'INTERNAL_POLICY'
        WHEN 2 THEN 'NCUA_REGULATION'
        WHEN 3 THEN 'STATE_LAW'
        WHEN 4 THEN 'FEDERAL_LAW'
        ELSE 'INDUSTRY_STANDARD'
    END AS regulation_type,
    DATEADD(month, -UNIFORM(6, 48, RANDOM()), CURRENT_DATE()) AS effective_date,
    DATEADD(month, -UNIFORM(1, 12, RANDOM()), CURRENT_DATE()) AS last_review_date,
    'lending, policy, compliance, standards, procedures' AS keywords,
    CURRENT_TIMESTAMP() AS created_at,
    CURRENT_TIMESTAMP() AS last_updated
FROM additional_policies;

SELECT 'Compliance Policies: ' || COUNT(*) || ' rows inserted' AS status FROM COMPLIANCE_POLICIES;

-- ============================================================================
-- Final Summary
-- ============================================================================
SELECT 'Data Generation Complete!' AS status;

SELECT 
    'CREDIT_UNIONS' AS table_name, COUNT(*) AS row_count, 'Credit union partners' AS description FROM CREDIT_UNIONS
UNION ALL
SELECT 'MEMBERS', COUNT(*), 'Credit union members' FROM MEMBERS
UNION ALL
SELECT 'DEALERS', COUNT(*), 'CUDL dealership partners' FROM DEALERS
UNION ALL
SELECT 'LOAN_OFFICERS', COUNT(*), 'Lending staff' FROM LOAN_OFFICERS
UNION ALL
SELECT 'LOAN_APPLICATIONS', COUNT(*), 'Loan applications submitted' FROM LOAN_APPLICATIONS
UNION ALL
SELECT 'LOANS', COUNT(*), 'Funded loans' FROM LOANS
UNION ALL
SELECT 'UNDERWRITING_NOTES', COUNT(*), 'Unstructured underwriting notes' FROM UNDERWRITING_NOTES
UNION ALL
SELECT 'LOAN_DOCUMENTS', COUNT(*), 'Unstructured loan documents' FROM LOAN_DOCUMENTS
UNION ALL
SELECT 'COMPLIANCE_POLICIES', COUNT(*), 'Compliance policy documents' FROM COMPLIANCE_POLICIES
UNION ALL
SELECT '=== TOTAL ===', SUM(row_count), 'Total rows generated' FROM (
    SELECT COUNT(*) AS row_count FROM CREDIT_UNIONS
    UNION ALL SELECT COUNT(*) FROM MEMBERS
    UNION ALL SELECT COUNT(*) FROM DEALERS
    UNION ALL SELECT COUNT(*) FROM LOAN_OFFICERS
    UNION ALL SELECT COUNT(*) FROM LOAN_APPLICATIONS
    UNION ALL SELECT COUNT(*) FROM LOANS
    UNION ALL SELECT COUNT(*) FROM UNDERWRITING_NOTES
    UNION ALL SELECT COUNT(*) FROM LOAN_DOCUMENTS
    UNION ALL SELECT COUNT(*) FROM COMPLIANCE_POLICIES
);
