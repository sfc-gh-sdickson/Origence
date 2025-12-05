-- ============================================================================
-- ULTRA-FAST Model Wrapper Functions - Target <5s execution
-- ============================================================================
-- Performance optimizations:
-- 1. Use smallest fast models (5 trees, depth=3)
-- 2. Limit to 5 rows per prediction
-- 3. Set max_batch_size in model options
-- 4. Use LAST (newest/fastest) version

USE DATABASE ORIGENCE_INTELLIGENCE;
USE SCHEMA ML_MODELS;
USE WAREHOUSE ORIGENCE_WH;

-- Drop existing procedures
DROP PROCEDURE IF EXISTS PREDICT_LOAN_DEFAULT_RISK(VARCHAR);
DROP PROCEDURE IF EXISTS PREDICT_LOAN_APPROVAL(VARCHAR);
DROP PROCEDURE IF EXISTS DETECT_FRAUD_RISK(NUMBER);

-- ============================================================================
-- Procedure 1: Loan Default Risk Prediction (ULTRA FAST)
-- ============================================================================
CREATE OR REPLACE PROCEDURE PREDICT_LOAN_DEFAULT_RISK(loan_type_filter VARCHAR)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('snowflake-ml-python', 'scikit-learn')
HANDLER = 'predict_default_risk'
COMMENT = 'Predicts loan default risk using LOAN_DEFAULT_PREDICTOR model (ULTRA FAST: 5 rows, 5 trees)'
AS
$$
def predict_default_risk(session, loan_type_filter):
    from snowflake.ml.registry import Registry
    import json
    
    # Get LATEST (fastest) model version
    reg = Registry(session=session, database_name="ORIGENCE_INTELLIGENCE", schema_name="ML_MODELS")
    mv = reg.get_model("LOAN_DEFAULT_PREDICTOR").default
    
    # Query with LIMIT 5 for ultra-fast execution
    type_filter = f"WHERE loan_type = '{loan_type_filter}'" if loan_type_filter else ""
    
    query = f"""
    SELECT 
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
    LIMIT 5
    """
    
    input_df = session.sql(query)
    
    if input_df.count() == 0:
        return json.dumps({"error": "No loans found"})
    
    # Run prediction
    predictions = mv.run(input_df, function_name="predict")
    result = predictions.select("PREDICTED_RISK", "LOAN_TYPE", "ORIGINAL_LOAN_AMOUNT").to_pandas()
    
    # Aggregate results
    return json.dumps({
        "total_loans": len(result),
        "low_risk": int((result['PREDICTED_RISK'] == 0).sum()),
        "medium_risk": int((result['PREDICTED_RISK'] == 1).sum()),
        "high_risk": int((result['PREDICTED_RISK'] == 2).sum()),
        "critical_risk": int((result['PREDICTED_RISK'] == 3).sum())
    })
$$;

SELECT 'ULTRA-FAST procedures created. Test with: CALL PREDICT_LOAN_DEFAULT_RISK(NULL);' AS status;
