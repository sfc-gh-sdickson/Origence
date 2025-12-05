-- ============================================================================
-- Set Latest Model Versions as Default
-- ============================================================================
-- The notebook creates new versions but doesn't set them as default
-- This script makes the LATEST versions (without label in signature) the default

USE DATABASE ORIGENCE_INTELLIGENCE;
USE SCHEMA ML_MODELS;

-- Get the latest versions and set them as default
ALTER MODEL LOAN_DEFAULT_PREDICTOR SET DEFAULT_VERSION = (
    SELECT version_name 
    FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) 
    WHERE name = 'LOAN_DEFAULT_PREDICTOR' 
    ORDER BY created_on DESC 
    LIMIT 1
);

-- For now, manually set the latest version names
-- Check SHOW MODELS output to see the "LAST" alias version names

-- Example: If the latest version is "PROUD_KIWI_2", run:
ALTER MODEL LOAN_DEFAULT_PREDICTOR SET DEFAULT_VERSION = 'PROUD_KIWI_2';
ALTER MODEL LOAN_APPROVAL_PREDICTOR SET DEFAULT_VERSION = 'HUNGRY_GORILLA_2';  
ALTER MODEL FRAUD_DETECTION_MODEL SET DEFAULT_VERSION = 'CHATTY_LIONFISH_3';

SELECT 'Model defaults updated to latest versions' AS status;
