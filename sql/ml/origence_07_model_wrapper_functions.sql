-- ============================================================================
-- Origence Intelligence Agent - ML Model Wrapper Functions
-- ============================================================================
-- Purpose: SQL procedures that wrap Model Registry models for Intelligence Agent
-- Models: 3 ML models registered in ML_MODELS schema
-- Pattern: Uses FEATURE VIEWS as single source of truth for features
-- ============================================================================

USE DATABASE ORIGENCE_INTELLIGENCE;
USE SCHEMA ML_MODELS;
USE WAREHOUSE ORIGENCE_WH;

-- ============================================================================
-- Procedure 1: Loan Default Risk Prediction
-- ============================================================================
-- Model: LOAN_DEFAULT_PREDICTOR
-- Output: Risk levels (0=Low, 1=Medium, 2=High, 3=Critical)
-- Input: loan_type filter (optional)
-- ============================================================================

CREATE OR REPLACE PROCEDURE PREDICT_LOAN_DEFAULT_RISK(
    LOAN_TYPE_FILTER VARCHAR
)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('snowflake-ml-python', 'scikit-learn')
HANDLER = 'predict_default_risk'
COMMENT = 'Predicts loan default risk using LOAN_DEFAULT_PREDICTOR model'
AS
$$
def predict_default_risk(session, loan_type_filter):
    from snowflake.ml.registry import Registry
    import json
    
    # Get model from registry
    reg = Registry(session, database_name="ORIGENCE_INTELLIGENCE", schema_name="ML_MODELS")
    model = reg.get_model("LOAN_DEFAULT_PREDICTOR").default
    
    # Build query using FEATURE VIEW (single source of truth)
    type_filter = f"WHERE loan_type = '{loan_type_filter}'" if loan_type_filter else ""
    
    query = f"""
    SELECT 
        loan_id,
        loan_type,
        original_loan_amount,
        loan_term_months,
        interest_rate,
        payments_made,
        days_past_due,
        credit_score,
        annual_income,
        age,
        debt_to_income_ratio,
        loan_to_value_ratio,
        is_cudl_dealer,
        loan_age_months,
        loan_to_income_ratio
    FROM ORIGENCE_INTELLIGENCE.ANALYTICS.V_LOAN_DEFAULT_FEATURES
    {type_filter}
    LIMIT 1000
    """
    
    input_df = session.sql(query)
    
    if input_df.count() == 0:
        return json.dumps({
            "error": "No active loans found for prediction",
            "loan_type_filter": loan_type_filter
        })
    
    # Get predictions
    predictions = model.run(input_df, function_name="predict")
    
    # Analyze predictions
    result = predictions.select("PREDICTED_RISK", "LOAN_TYPE", "ORIGINAL_LOAN_AMOUNT").to_pandas()
    
    # Count by predicted risk
    low_risk = int((result['PREDICTED_RISK'] == 0).sum())
    medium_risk = int((result['PREDICTED_RISK'] == 1).sum())
    high_risk = int((result['PREDICTED_RISK'] == 2).sum())
    critical_risk = int((result['PREDICTED_RISK'] == 3).sum())
    total_count = len(result)
    total_exposure = float(result['ORIGINAL_LOAN_AMOUNT'].sum())
    high_risk_exposure = float(result[result['PREDICTED_RISK'] >= 2]['ORIGINAL_LOAN_AMOUNT'].sum())
    
    return json.dumps({
        "model": "LOAN_DEFAULT_PREDICTOR",
        "loan_type_filter": loan_type_filter or "ALL",
        "loans_analyzed": total_count,
        "predicted_low_risk": low_risk,
        "predicted_medium_risk": medium_risk,
        "predicted_high_risk": high_risk,
        "predicted_critical_risk": critical_risk,
        "at_risk_loans": high_risk + critical_risk,
        "at_risk_percentage": round((high_risk + critical_risk) / total_count * 100, 2) if total_count > 0 else 0,
        "total_portfolio_exposure": round(total_exposure, 2),
        "high_risk_exposure": round(high_risk_exposure, 2),
        "high_risk_exposure_pct": round(high_risk_exposure / total_exposure * 100, 2) if total_exposure > 0 else 0
    })
$$;

-- ============================================================================
-- Procedure 2: Loan Approval Prediction
-- ============================================================================
-- Model: LOAN_APPROVAL_PREDICTOR
-- Output: Approval likelihood (0=Likely Deny, 1=Review, 2=Likely Approve)
-- Input: application_status filter (optional - typically 'PENDING')
-- ============================================================================

CREATE OR REPLACE PROCEDURE PREDICT_LOAN_APPROVAL(
    APPLICATION_STATUS_FILTER VARCHAR
)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('snowflake-ml-python', 'scikit-learn')
HANDLER = 'predict_approval'
COMMENT = 'Predicts loan approval likelihood using LOAN_APPROVAL_PREDICTOR model'
AS
$$
def predict_approval(session, status_filter):
    from snowflake.ml.registry import Registry
    import json
    
    # Get model from registry
    reg = Registry(session, database_name="ORIGENCE_INTELLIGENCE", schema_name="ML_MODELS")
    model = reg.get_model("LOAN_APPROVAL_PREDICTOR").default
    
    # Build query using FEATURE VIEW
    status_condition = f"WHERE approval_label = 1" if status_filter == 'PENDING' else ""
    
    query = f"""
    SELECT 
        application_id,
        loan_type,
        requested_amount,
        loan_term_months,
        credit_score_at_app,
        annual_income,
        debt_to_income_ratio,
        loan_to_value_ratio,
        employment_verified,
        employment_length_months,
        age,
        is_cudl_dealer,
        loan_to_income_ratio
    FROM ORIGENCE_INTELLIGENCE.ANALYTICS.V_LOAN_APPROVAL_FEATURES
    {status_condition}
    LIMIT 1000
    """
    
    input_df = session.sql(query)
    
    if input_df.count() == 0:
        return json.dumps({
            "error": "No applications found for prediction",
            "status_filter": status_filter
        })
    
    # Get predictions
    predictions = model.run(input_df, function_name="predict")
    
    # Analyze predictions
    result = predictions.select("PREDICTED_APPROVAL", "LOAN_TYPE", "REQUESTED_AMOUNT", "CREDIT_SCORE_AT_APP").to_pandas()
    
    # Count by predicted outcome
    likely_deny = int((result['PREDICTED_APPROVAL'] == 0).sum())
    needs_review = int((result['PREDICTED_APPROVAL'] == 1).sum())
    likely_approve = int((result['PREDICTED_APPROVAL'] == 2).sum())
    total_count = len(result)
    
    # Calculate average metrics by prediction
    avg_credit_score = round(result['CREDIT_SCORE_AT_APP'].mean(), 0)
    avg_requested = round(result['REQUESTED_AMOUNT'].mean(), 2)
    
    return json.dumps({
        "model": "LOAN_APPROVAL_PREDICTOR",
        "status_filter": status_filter or "ALL",
        "applications_analyzed": total_count,
        "predicted_likely_deny": likely_deny,
        "predicted_needs_review": needs_review,
        "predicted_likely_approve": likely_approve,
        "approval_likelihood_pct": round(likely_approve / total_count * 100, 2) if total_count > 0 else 0,
        "avg_credit_score": avg_credit_score,
        "avg_requested_amount": avg_requested,
        "recommendation": "Focus on " + str(likely_approve) + " likely approvals for fast-track processing"
    })
$$;

-- ============================================================================
-- Procedure 3: Fraud Risk Detection
-- ============================================================================
-- Model: FRAUD_DETECTION_MODEL
-- Output: Fraud risk (0=Clean, 1=Suspicious, 2=High Risk)
-- Input: days_back (number of days to look back, default 30)
-- ============================================================================

CREATE OR REPLACE PROCEDURE DETECT_FRAUD_RISK(
    DAYS_BACK NUMBER
)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('snowflake-ml-python', 'scikit-learn')
HANDLER = 'detect_fraud'
COMMENT = 'Detects potentially fraudulent applications using FRAUD_DETECTION_MODEL'
AS
$$
def detect_fraud(session, days_back):
    from snowflake.ml.registry import Registry
    import json
    
    # Default to 30 days if not specified
    if days_back is None or days_back <= 0:
        days_back = 30
    
    # Get model from registry
    reg = Registry(session, database_name="ORIGENCE_INTELLIGENCE", schema_name="ML_MODELS")
    model = reg.get_model("FRAUD_DETECTION_MODEL").default
    
    # Build query using FEATURE VIEW
    query = f"""
    SELECT 
        f.application_id,
        f.loan_type,
        f.requested_amount,
        f.credit_score_at_app,
        f.annual_income,
        f.debt_to_income_ratio,
        f.employment_verified,
        f.employment_length_months,
        f.application_velocity,
        f.income_to_request_ratio,
        f.credit_score_change,
        f.high_loan_to_income_flag,
        f.high_dti_flag,
        f.income_verification_mismatch
    FROM ORIGENCE_INTELLIGENCE.ANALYTICS.V_FRAUD_DETECTION_FEATURES f
    INNER JOIN ORIGENCE_INTELLIGENCE.RAW.LOAN_APPLICATIONS a 
        ON f.application_id = a.application_id
    WHERE a.application_date >= DATEADD(day, -{days_back}, CURRENT_DATE())
    LIMIT 1000
    """
    
    input_df = session.sql(query)
    
    if input_df.count() == 0:
        return json.dumps({
            "error": "No recent applications found",
            "days_back": days_back
        })
    
    # Get predictions
    predictions = model.run(input_df, function_name="predict")
    
    # Analyze predictions
    result = predictions.select("PREDICTED_FRAUD_RISK", "APPLICATION_ID", "REQUESTED_AMOUNT", "CREDIT_SCORE_AT_APP").to_pandas()
    
    # Count by fraud risk
    clean = int((result['PREDICTED_FRAUD_RISK'] == 0).sum())
    suspicious = int((result['PREDICTED_FRAUD_RISK'] == 1).sum())
    high_risk = int((result['PREDICTED_FRAUD_RISK'] == 2).sum())
    total_count = len(result)
    
    # Get flagged application IDs
    flagged_apps = result[result['PREDICTED_FRAUD_RISK'] >= 1]['APPLICATION_ID'].tolist()[:10]
    flagged_count = len(result[result['PREDICTED_FRAUD_RISK'] >= 1])
    
    return json.dumps({
        "model": "FRAUD_DETECTION_MODEL",
        "days_analyzed": days_back,
        "applications_analyzed": total_count,
        "predicted_clean": clean,
        "predicted_suspicious": suspicious,
        "predicted_high_risk": high_risk,
        "total_flagged": flagged_count,
        "fraud_rate_pct": round(flagged_count / total_count * 100, 2) if total_count > 0 else 0,
        "sample_flagged_application_ids": flagged_apps[:5],
        "recommendation": f"Review {flagged_count} flagged applications for potential fraud indicators"
    })
$$;

-- ============================================================================
-- Grant Permissions
-- ============================================================================
GRANT USAGE ON PROCEDURE PREDICT_LOAN_DEFAULT_RISK(VARCHAR) TO ROLE SYSADMIN;
GRANT USAGE ON PROCEDURE PREDICT_LOAN_APPROVAL(VARCHAR) TO ROLE SYSADMIN;
GRANT USAGE ON PROCEDURE DETECT_FRAUD_RISK(NUMBER) TO ROLE SYSADMIN;

-- ============================================================================
-- Confirmation
-- ============================================================================
SELECT 'ML model wrapper procedures created successfully' AS status;

SHOW PROCEDURES IN SCHEMA ML_MODELS;

-- ============================================================================
-- Test Calls (Run after models are registered via notebook)
-- ============================================================================

-- Test 1: Predict default risk for all loans
-- CALL PREDICT_LOAN_DEFAULT_RISK(NULL);

-- Test 2: Predict default risk for auto loans only
-- CALL PREDICT_LOAN_DEFAULT_RISK('AUTO_LOAN');

-- Test 3: Predict approval for pending applications
-- CALL PREDICT_LOAN_APPROVAL('PENDING');

-- Test 4: Detect fraud in last 30 days
-- CALL DETECT_FRAUD_RISK(30);

-- Test 5: Detect fraud in last 7 days
-- CALL DETECT_FRAUD_RISK(7);

SELECT 'Test calls ready - uncomment and run after ML models are trained' AS instruction;
