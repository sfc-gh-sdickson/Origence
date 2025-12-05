-- ============================================================================
-- Delete Old ML Models to Force Re-registration
-- ============================================================================
-- Run this BEFORE re-running the notebook to ensure new optimized models are registered

USE DATABASE ORIGENCE_INTELLIGENCE;
USE SCHEMA ML_MODELS;

-- Delete all existing models
DROP MODEL IF EXISTS LOAN_DEFAULT_PREDICTOR;
DROP MODEL IF EXISTS LOAN_APPROVAL_PREDICTOR;
DROP MODEL IF EXISTS FRAUD_DETECTION_MODEL;

SELECT 'Old models deleted - now re-run the notebook to register optimized models' AS instruction;
