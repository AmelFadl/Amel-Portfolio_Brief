# Amel's Projects Overview
Analytics Projects Summary and their Datasets
# [Project 1: SQL360 ]
Description:
*  SQL-powered business intelligence engine that delivers end-to-end analytics across customer prefrences behavior, inventory trends, order fulfillment, and profitability. Built with views, stored procedures, and functions, it transforms raw data into actionable insights for strategic decision-making.
*  Note: This project uses historical data (2003- 2005) to demonstrate SQL-based analytics architecture and business intelligence capabilities.
* Dataset Origin: This dataset,is sourced from a publicly available SQL course in July 2025, is used here solely for educational and demonstration purposes.
* Analysis Tool: SQL Language
* Platform: MySQL Workbench
  
# [Project 2: Telecom Customer Churn Analysis (SQL-Only Project)] 
Project Overview:
* This project analyzes customer churn in a telecom company using a pure SQL approach (no external analytics tools, only SQL logic)
* The goal was to identify key churn drivers, test 10 business hypotheses, and create an automated evaluation system using views and stored procedures.
  
Objectives:
* Design a normalized telecom schema and ERD.
* Establish the baseline churn rate.
* Encode and test 10 hypotheses using CASE logic.
* Automate churn evaluation via SQL stored procedures.
* Deliver actionable insights for retention and strategy.
  
Methodology:
1. ERD Design – Fact table telecom_customer_churn joined with lookup tables.
2. Unified View (churn_analysis) – Combined demographics, usage, contracts, and churn data.
3. Hypotheses View (churn_hypotheses) – Encoded 10 churn-related patterns using CASE logic.
4. Baseline Churn – Computed overall churn at 26.5%.
5. Automated Testing – Created stored procedure evaluate_hypotheses() to summarize and interpret results.
   
Key Findings:
* Monthly contracts, dissatisfaction, and high data usage increase churn.
* Referrals, dependents, and long-term contracts reduce churn.
* Population density had no significant impact.
  
Insights & Recommendations:
* Incentivize long-term contracts.
* Improve customer satisfaction touchpoints.
* Expand referral programs.
* Focus retention on high-risk segments.
  
Tech Stack:
* SQL (MySQL)
* Views, Stored Procedures, CASE Statements, Aggregations
* ER Diagram Design
