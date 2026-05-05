# Healthcare Analytics: End-to-End Financial & Operational Dashboard

##  Project Overview
This project analyzes a healthcare dataset of **55,500 patient records** to uncover operational and financial insights. I developed an end-to-end pipeline—from raw data cleaning to interactive visualization—to help hospital administrators track revenue and patient trends.

DATASET 
<img width="1440" height="751" alt="Screenshot 2026-05-04 at 4 18 55 AM" src="https://github.com/user-attachments/assets/44ef9a85-3556-4284-8e0a-a73ca51ac452" />


## Tools Used
* **Excel:** Data cleaning and initial Exploratory Data Analysis (EDA).
* **SQL:** Data manipulation and trend calculations.
* **Power BI:** Dashboard design, DAX measures, and data storytelling.

##  The Data Process

### 1. Data Cleaning & Feature Engineering (Excel)
* Standardized formatting for patient and doctor names to ensure data integrity.
* 
The first step was pulling the raw data from its source — a flat CSV file — and loading it into a staging environment where I could inspect it without modifying the original. Preserving the raw source is important because if something goes wrong during cleaning, I need to be able to roll back.
During extraction, I also verified the basic structure: row count, column names, and inferred data types. One issue I caught immediately was that the date columns (Date of Admission and Discharge Date) were loaded as plain strings rather than proper date objects — something I flagged to fix in the Transform phase.

Null / Missing Values
When I ran a null check across all 15 columns, every column returned zero nulls. Rather than treating that as a green light, I questioned it — real healthcare data at 55,500 rows almost always has some missingness. A fully complete dataset usually means missing values were filled in upstream with placeholder text like "N/A", "Unknown", or empty strings before I received the file.
To address this, I scanned each categorical column for fake non-null values and applied .str.strip() to catch hidden whitespace. For any numeric column like Billing Amount or Age where true nulls might appear in future data loads, I established rules: impute the median for age where appropriate, and flag missing billing amounts rather than guessing a dollar value.
Duplicate Records
I found 534 exact duplicate rows — records that matched another row in every single column, from the patient name and age down to the billing amount and discharge date. These were not separate visits by the same patient; they were identical copies of the same record, likely caused by a pipeline running more than once or a double submission at the source system.
I removed them using drop_duplicates(), bringing the dataset from 55,500 rows down to 54,966 rows. Leaving those duplicates in would have inflated every count-based metric in the analysis — total admissions, average billing per condition, patient volume by hospital, and so on.
Inconsistent Formatting
The most immediately visible issue was in the Name column. The first few rows alone showed entries like Bobby JacksOn, LesLie TErRy, DaNnY sMitH, and EMILY JOHNSOn — random mixed casing that was almost certainly the result of manual data entry across multiple systems with no input validation.
This matters because inconsistent casing breaks deduplication and joins. Bobby Jackson, BOBBY JACKSON, and BoBby jACKson would be treated as three different people by SQL or any BI tool. I standardized all names to Title Case using .str.title() and applied .str.strip() across all text columns to remove any trailing or leading whitespace that could cause silent mismatches in grouping and filtering.
Date Overlapping / Logical Inconsistencies
I checked for a specific type of error that is common in healthcare data: a patient's discharge date falling before their admission date, which is logically impossible. I did this by converting both date columns to proper datetime objects and computing a derived Length of Stay field as Discharge Date − Date of Admission. Any negative value would indicate an inverted date range.
After running the check across all 54,966 cleaned records, I found zero overlapping date records — length of stay ranged from 1 to 30 days with a mean of approximately 15.5 days. I also cross-validated edge cases, such as same-day admissions and discharges for serious conditions, and flagged those for clinical review rather than automatic removal.
Outliers and Invalid Numeric Values
I found that the Billing Amount column had a minimum value of -$2,008 — a negative charge. This could represent a refund, a credit adjustment, or a data entry error that was stored in the wrong field. I did not delete those rows outright since the rest of the patient record was valid. Instead, I flagged them and established a business rule: negative billing values are separated into an Adjustments category and excluded from standard billing analyses.
The Age column was clean — values ranged from 13 to 89 with no negatives or impossible values.

I enforced proper data types at the schema level: Date of Admission and Discharge Date as DATE types, Billing Amount as DECIMAL, and Age as INTEGER. I also defined constraints — for example, Billing Amount >= 0 and Discharge Date >= Date of Admission — so that future data loads are validated against the same rules automatically.



### 2. Advanced Analysis (SQL)
* Aggregated total billing by Insurance Provider and Hospital.
* Calculated Year-over-Year (YoY) admission trends to identify growth patterns.
* Filtered top-performing doctors based on patient volume and revenue generation.

### 3. Interactive Visualization (Power BI)
* **Overview Dashboard:** Visualizes patient demographics, admission types, and YoY trends.
* <img width="795" height="804" alt="Health care analytics" src="https://github.com/user-attachments/assets/7e29d7c1-ce2d-4ad6-aa8d-2f2075ef13e8" />

* **Financial Analysis:** Tracks total revenue ($1.42bn) and breaks down billing by insurance provider.
* <img width="795" height="804" alt="Health care analytics" src="https://github.com/user-attachments/assets/403aa08a-e31f-46b9-ae0f-5c3baa22299b" />


##  Key Business Insights
* **Demographics:** Middle Age and Senior patients represent nearly **69%** of total admissions.
* **Revenue Drivers:** Cigna and Medicare are the primary insurance contributors, each exceeding **$285M** in total billing.
* **Growth:** Analysis shows a significant volume peak between 2019 and 2020.

* Business Impact
Why Data Quality Directly Affects Decision-Making
Every report, dashboard, and business decision built on top of this dataset is only as reliable as the data underneath it. The cleaning and ETL work I performed was not just a technical exercise — each issue I resolved had a direct downstream effect on the accuracy of insights, the reliability of operations, and the integrity of financial reporting.

Impact of Removing 534 Duplicate Records
Before deduplication, the dataset contained 534 records that were exact copies of real patient admissions. Had I left those in, every count-based metric in the analysis would have been overstated. Patient admission volumes would have been inflated, average billing calculations would have been skewed, and any model trained on this data would have learned from false observations.
For a healthcare organization, overcounted admissions can affect staffing decisions, bed allocation planning, and insurance reimbursement reporting. If a hospital reports more admissions than actually occurred, it misrepresents its capacity utilization and could trigger compliance issues with insurers or regulators. By removing those 534 rows, I ensured that every metric downstream reflects what actually happened.

Impact of Standardizing Patient Names
The inconsistent casing in the Name column — entries like LesLie TErRy and EMILY JOHNSOn — is more than an aesthetic problem. In any system that uses names as a matching key to link records across tables or time periods, inconsistent formatting causes the same person to appear as multiple distinct individuals.
This has real consequences. A patient readmitted under a slightly different name format would not be recognized as a returning patient, breaking any readmission rate analysis. Marketing or outreach campaigns built on patient history would send duplicate communications. Any longitudinal analysis tracking a patient's condition over time would fragment into disconnected records. Standardizing to Title Case ensures that name-based lookups and joins behave consistently across the entire pipeline.

Impact of Resolving Negative Billing Amounts
The presence of billing amounts as low as -$2,008 in a field meant to capture patient charges is a financial data integrity problem. If those values flow unchecked into a revenue reporting dashboard, total revenue figures would be understated, average billing per condition would be distorted, and any forecasting model built on billing trends would produce unreliable projections.
By flagging negative values and separating them into an Adjustments category, I preserved the integrity of the primary billing analysis while still keeping that data available for accounting reconciliation. Finance teams can now trust that the billing figures in the main dataset represent actual charges, not a mix of charges and unprocessed credits.

Impact of Validating Date Logic
Verifying that no discharge date preceded an admission date protected the integrity of one of the most operationally important metrics in healthcare analytics: Length of Stay (LOS). LOS drives decisions about bed turnover, resource scheduling, staffing ratios, and cost-per-episode calculations. A single inverted date pair can corrupt an entire LOS distribution if it is not caught.
Although my validation returned zero violations in this dataset, the process of building that check into the pipeline means future data loads are also protected. Any record with an illogical date range will be caught before it reaches the warehouse rather than silently distorting reports months later.

Impact of Enforcing Data Types and Load Constraints
Loading dates as strings instead of proper DATE types is one of the most common and quietly destructive ETL mistakes. A string-stored date cannot be filtered by date range, aggregated by month or quarter, or used in any time-series calculation without first converting it — and if that conversion is inconsistent across different queries or tools, results will vary depending on who runs the report and how.
By enforcing DATE types at the schema level, along with constraints like Billing Amount >= 0 and Discharge Date >= Date of Admission, I made the data warehouse itself a line of defense. Future data loads are validated automatically, which means analysts and business users can query the data with confidence rather than having to second-guess whether the underlying records are trustworthy.
