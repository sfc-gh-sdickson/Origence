-- ============================================================================
-- Origence Intelligence Agent - Intelligence Agent Configuration
-- ============================================================================
-- Purpose: Create and configure Snowflake Intelligence Agent
-- Components: 3 semantic views, 3 Cortex Search services, 3 ML model tools
-- ============================================================================

USE DATABASE ORIGENCE_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE ORIGENCE_WH;

-- ============================================================================
-- Prerequisites Verification
-- ============================================================================

-- Verify semantic views exist
SHOW SEMANTIC VIEWS IN SCHEMA ANALYTICS;

-- Verify Cortex Search services exist
SHOW CORTEX SEARCH SERVICES IN SCHEMA RAW;

-- Verify ML procedures exist
SHOW PROCEDURES IN SCHEMA ML_MODELS;

-- ============================================================================
-- Create Intelligence Agent
-- ============================================================================

CREATE OR REPLACE CORTEX AGENT ORIGENCE_LENDING_AGENT
WAREHOUSE = ORIGENCE_WH
COMMENT = 'Origence credit union lending intelligence agent with ML predictions'
AS
{
  "description": "Intelligence agent for Origence credit union lending platform. Answers questions about loan performance, member credit profiles, credit union metrics, and provides ML-powered predictions for loan default risk, approval likelihood, and fraud detection. Has access to structured data via semantic views and unstructured data via Cortex Search services.",
  
  "semantic_views": [
    {
      "name": "ORIGENCE_INTELLIGENCE.ANALYTICS.SV_LOAN_PERFORMANCE",
      "description": "Semantic view for loan portfolio performance analytics including loan types, volumes, delinquency rates, default rates, and credit union metrics. Use for questions about loan performance trends, portfolio health, and risk analysis."
    },
    {
      "name": "ORIGENCE_INTELLIGENCE.ANALYTICS.SV_MEMBER_CREDIT_PROFILE",
      "description": "Semantic view for member demographics, credit profiles, and loan application patterns. Use for questions about member segments, credit scores, income levels, application approval rates, and member behavior analysis."
    },
    {
      "name": "ORIGENCE_INTELLIGENCE.ANALYTICS.SV_CREDIT_UNION_METRICS",
      "description": "Semantic view for credit union partnership performance including loan volumes, member counts, dealer partnerships, approval rates, and portfolio metrics. Use for questions about credit union performance, regional analysis, and partnership statistics."
    }
  ],
  
  "tools": [
    {
      "type": "cortex_search",
      "name": "search_underwriting_notes",
      "description": "Search underwriting notes and decision rationale. Use when user asks about specific underwriting decisions, credit review findings, risk assessments, or loan officer notes. Searches across note_text field with filters on application_id, loan_officer_id, note_category (CREDIT_REVIEW, INCOME_VERIFICATION, COLLATERAL_ASSESSMENT, RISK_ASSESSMENT, GENERAL_UNDERWRITING), and decision_factor flag.",
      "service": "ORIGENCE_INTELLIGENCE.RAW.UNDERWRITING_NOTES_SEARCH"
    },
    {
      "type": "cortex_search",
      "name": "search_loan_documents",
      "description": "Search loan documentation including pay stubs, tax returns, bank statements, employment letters, vehicle titles, insurance proofs, appraisal reports, and loan contracts. Use when user asks about specific document types or verification materials. Searches document_text field with filters on loan_id, application_id, document_type, and document_category.",
      "service": "ORIGENCE_INTELLIGENCE.RAW.LOAN_DOCUMENTS_SEARCH"
    },
    {
      "type": "cortex_search",
      "name": "search_compliance_policies",
      "description": "Search lending policies, regulatory requirements, and compliance guidelines. Use when user asks about lending policies, compliance rules, regulations (Fair Lending, TILA, BSA/AML, etc.), underwriting standards, or policy requirements. Searches policy_content field with filters on policy_category, regulation_type, and keywords.",
      "service": "ORIGENCE_INTELLIGENCE.RAW.COMPLIANCE_POLICIES_SEARCH"
    },
    {
      "type": "function",
      "name": "predict_loan_default_risk",
      "description": "Predicts default risk for loans in the portfolio. Returns risk distribution (Low/Medium/High/Critical) with counts, percentages, and exposure amounts. Use when user asks about loan default predictions, portfolio risk assessment, or which loans are at risk of default. Can filter by loan_type (AUTO_LOAN, PERSONAL_LOAN, HOME_EQUITY) or analyze entire portfolio.",
      "function": "ORIGENCE_INTELLIGENCE.ML_MODELS.PREDICT_LOAN_DEFAULT_RISK",
      "parameters": [
        {
          "name": "LOAN_TYPE_FILTER",
          "type": "VARCHAR",
          "description": "Optional filter for loan type: 'AUTO_LOAN', 'PERSONAL_LOAN', 'HOME_EQUITY', or NULL for all loans"
        }
      ]
    },
    {
      "type": "function",
      "name": "predict_loan_approval",
      "description": "Predicts approval likelihood for loan applications. Returns distribution of Likely Deny, Needs Review, and Likely Approve with approval percentage and average metrics. Use when user asks which applications are likely to be approved, approval predictions, or fast-track candidates. Typically filter by 'PENDING' status to analyze current pipeline.",
      "function": "ORIGENCE_INTELLIGENCE.ML_MODELS.PREDICT_LOAN_APPROVAL",
      "parameters": [
        {
          "name": "APPLICATION_STATUS_FILTER",
          "type": "VARCHAR",
          "description": "Optional filter for application status: 'PENDING', 'APPROVED', 'DENIED', or NULL for all"
        }
      ]
    },
    {
      "type": "function",
      "name": "detect_fraud_risk",
      "description": "Detects potentially fraudulent loan applications based on suspicious patterns including high application velocity, income verification mismatches, and anomalous credit profiles. Returns fraud risk distribution (Clean/Suspicious/High Risk) with flagged application IDs. Use when user asks about fraud detection, suspicious applications, or application integrity checks. Specify days_back parameter to control lookback period (typically 30 days).",
      "function": "ORIGENCE_INTELLIGENCE.ML_MODELS.DETECT_FRAUD_RISK",
      "parameters": [
        {
          "name": "DAYS_BACK",
          "type": "NUMBER",
          "description": "Number of days to look back for recent applications (default: 30)"
        }
      ]
    }
  ]
};

-- ============================================================================
-- Grant Usage Permissions
-- ============================================================================
GRANT USAGE ON AGENT ORIGENCE_LENDING_AGENT TO ROLE SYSADMIN;

-- ============================================================================
-- Verification
-- ============================================================================
SHOW AGENTS IN SCHEMA ANALYTICS;

DESC AGENT ORIGENCE_LENDING_AGENT;

SELECT 'Origence Intelligence Agent created successfully!' AS status;

-- ============================================================================
-- Test Agent with Sample Questions
-- ============================================================================

-- Test 1: Simple question (uses semantic view)
-- SELECT SNOWFLAKE.CORTEX.COMPLETE_AGENT(
--     'ORIGENCE_LENDING_AGENT',
--     'How many loan applications did we receive this month?'
-- );

-- Test 2: Complex question (uses semantic view with aggregations)
-- SELECT SNOWFLAKE.CORTEX.COMPLETE_AGENT(
--     'ORIGENCE_LENDING_AGENT',
--     'What is the month-over-month growth in loan originations by credit union tier?'
-- );

-- Test 3: ML prediction question (uses ML model tool)
-- SELECT SNOWFLAKE.CORTEX.COMPLETE_AGENT(
--     'ORIGENCE_LENDING_AGENT',
--     'Predict the default risk for auto loans in our current portfolio'
-- );

-- Test 4: Unstructured search question (uses Cortex Search)
-- SELECT SNOWFLAKE.CORTEX.COMPLETE_AGENT(
--     'ORIGENCE_LENDING_AGENT',
--     'What are our policies on debt-to-income ratio requirements?'
-- );

-- Test 5: Combined question (uses multiple tools)
-- SELECT SNOWFLAKE.CORTEX.COMPLETE_AGENT(
--     'ORIGENCE_LENDING_AGENT',
--     'Which pending applications are likely to be approved and what do our underwriting notes say about high credit score applicants?'
-- );

SELECT 'Agent ready for testing - uncomment test queries above' AS instruction;

-- ============================================================================
-- Usage Notes
-- ============================================================================

-- The agent can answer questions about:
-- 1. Loan performance and portfolio metrics
-- 2. Member credit profiles and demographics
-- 3. Credit union partnership performance
-- 4. ML predictions for default risk, approvals, and fraud
-- 5. Unstructured data in underwriting notes, documents, and policies

-- The agent will automatically:
-- - Choose the appropriate semantic view for structured data queries
-- - Use Cortex Search for unstructured data questions
-- - Call ML model tools for prediction questions
-- - Combine multiple tools when needed for complex questions

-- Best practices:
-- - Ask specific questions with clear intent
-- - Use natural language - no SQL required
-- - Reference time periods, filters, or segments as needed
-- - Agent will clarify if question is ambiguous
