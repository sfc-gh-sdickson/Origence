-- ============================================================================
-- COMPLETE FIX: Delete models, recreate with minimal trees, test performance
-- ============================================================================

USE DATABASE ORIGENCE_INTELLIGENCE;
USE SCHEMA ML_MODELS;
USE WAREHOUSE ORIGENCE_WH;

-- Step 1: Delete all existing models and procedures
DROP PROCEDURE IF EXISTS PREDICT_LOAN_DEFAULT_RISK(VARCHAR);
DROP PROCEDURE IF EXISTS PREDICT_LOAN_APPROVAL(VARCHAR);
DROP PROCEDURE IF EXISTS DETECT_FRAUD_RISK(NUMBER);

DROP MODEL IF EXISTS LOAN_DEFAULT_PREDICTOR;
DROP MODEL IF EXISTS LOAN_APPROVAL_PREDICTOR;
DROP MODEL IF EXISTS FRAUD_DETECTION_MODEL;

SELECT '✅ All models and procedures deleted. 

NEXT STEPS:
1. Edit notebook: Change n_estimators=10 to n_estimators=3 and max_depth=5 to max_depth=3 in ALL three models
2. Run the notebook to register ultra-fast models  
3. Run file 7 to create procedures
4. Test with: CALL PREDICT_LOAN_DEFAULT_RISK(NULL);

Expected execution time: <10 seconds' AS instructions;
