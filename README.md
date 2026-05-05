# Healthcare Analytics — Data Cleaning, ETL & Dashboard

## Project Overview
This project focuses on transforming raw healthcare transactional data into a
clean, analysis-ready dataset and building an interactive two-page dashboard
that gives hospital leadership a full view of revenue, admissions, patient
demographics, medical conditions, medications, and year-over-year trends. The
dataset covers 55,500 patient admission records spanning 2019 through 2024
across 15 columns.

Financial Dashbaord 
## <img width="1009" height="679" alt="Financial Analysis Healthcare " src="https://github.com/user-attachments/assets/ba9f44a4-4916-470e-b4b2-79846749e147" />

Health care over view 
<img width="795" height="804" alt="Health care analytics" src="https://github.com/user-attachments/assets/bc04b552-b635-4222-bb17-ea66f9c85ccd" />



## The Data Analysis Process
I followed a 3-stage ETL framework to move from raw data to a finished dashboard:

1. **Extract:** Loaded the raw CSV into a pandas DataFrame as a staging
   environment, confirmed the shape as 55,500 rows and 15 columns, and
   immediately flagged that `Date of Admission` and `Discharge Date` were
   loaded as plain strings instead of datetime objects, that `Billing Amount`
   contained negative values, and that the `Name` column had severe random
   casing inconsistencies across all records
2. **Transform:** Applied all cleaning operations across six categories —
   null validation, duplicate removal, name casing standardization, whitespace
   correction, date type conversion and logical validation, negative billing
   handling, age group bucketing, and data type enforcement
3. **Dashboard Construction:** Built the Healthcare Analytics Dashboard in
   Power BI across two pages — Overview and Financial Analysis — covering
   KPI cards, blood type distributions, medical condition breakdowns,
   insurance provider comparisons, medication distributions, gender and
   admission type donut charts, test result distributions, age bucket
   breakdowns, and a year-over-year admission trend line

## Data Cleaning Steps

### Null & Missing Values
- **Null Check:** Ran `.isnull().sum()` across all 15 columns — returned
  **zero null values** across every column in the entire dataset
- **Verification:** Did not accept that result at face value — at 55,500
  records, a fully clean null report often means missing values were filled
  upstream with placeholder text like `"N/A"` or `"Unknown"` before the
  file was delivered
- **Whitespace Audit:** Applied `.str.strip()` across all text columns
  because a value like `"Cancer "` with a trailing space passes a null
  check but is treated as a completely different category by SQL, pandas,
  and every BI tool including Power BI
- **Controlled Vocabulary Verification:** After stripping, confirmed the
  unique value counts for all categorical columns:
  - **Medical Condition** — 6 values: Arthritis, Diabetes, Hypertension,
    Obesity, Cancer, Asthma
  - **Admission Type** — 3 values: Elective, Urgent, Emergency
  - **Medication** — 5 values: Lipitor, Ibuprofen, Aspirin, Paracetamol,
    Penicillin
  - **Test Results** — 3 values: Abnormal, Normal, Inconclusive
  - **Gender** — 2 values: Male, Female
  - **Blood Type** — 8 values: all standard ABO/Rh combinations
  - **Insurance Provider** — 5 values: Cigna, Medicare, UnitedHealthcare,
    Blue Cross, Aetna
- **Forward-Looking Rules:** Established imputation rules for future loads:
  - **Age** — impute the median if nulls appear, not the mean, since age
    distributions in clinical data tend to be skewed
  - **Billing Amount** — flag missing values rather than imputing, because
    guessing a dollar amount has direct financial reporting consequences
  - **Categorical columns** — standardize to `"Unknown"` rather than
    dropping the row, preserving the rest of the record

### Duplicate Records
- **Discovery:** Ran `df.duplicated().sum()` and found **534 exact duplicate
  rows** — records that matched another row in all 15 columns, from patient
  name and age all the way down to billing amount and discharge date
- **Root Causes:** Identified likely causes as an ETL pipeline that ran more
  than once without checking for existing records, a manual form submitted
  twice, or a source system bug that logged the same admission event twice
- **Resolution:** Removed all 534 duplicates using `drop_duplicates()`,
  reducing the dataset from **55,500 rows to 54,966 rows**
- **Impact:** Leaving duplicates in would have overstated every count-based
  metric on the dashboard — the Total No. of Admissions KPI showing 40,235,
  the medical condition breakdowns, the insurance provider volumes, and the
  year-over-year admission trend line would all have been inflated by phantom
  records that never occurred

### Inconsistent Name Formatting
- **Discovery:** Inspected the `Name` column and found severe random casing
  across all records — examples included `Bobby JacksOn`, `LesLie TErRy`,
  `DaNnY sMitH`, `EMILY JOHNSOn`, `andrEw waTtS`, and `CHrisTInA MARtinez`
- **Root Cause:** Manual data entry across multiple systems with no input
  validation enforcing a consistent format at the point of capture
- **Functional Impact:**
  - `Bobby Jackson`, `BOBBY JACKSON`, and `BoBby jACKson` are treated as
    three completely different people by SQL, pandas, and every BI tool
  - Any readmission tracking built on name matching would fail — a returning
    patient recorded under a different format would not be matched to their
    previous visit
  - Name-based duplicate detection would produce false negatives — true
    duplicates would go undetected because the strings did not match exactly
- **Resolution:** Standardized all 55,500 names to Title Case using
  `.str.title()` in a single operation and applied `.str.strip()` to remove
  any surviving leading or trailing whitespace

### Date Type Conversion & Logical Validation
- **Type Conversion:** Both `Date of Admission` and `Discharge Date` were
  loaded as plain string objects — converted both to proper datetime objects
  using `pd.to_datetime()` so date arithmetic, filtering, and time-series
  aggregations behave consistently across every tool and query
- **LOS Derivation:** Created a derived **Length of Stay** column calculated
  as `Discharge Date − Date of Admission` in days to validate date logic
- **Overlap Check:** Checked for any record where discharge date fell before
  admission date — returned **zero violations** across all 55,500 records
- **LOS Statistics:** Confirmed the distribution was internally consistent:
  - **Minimum LOS** — 1 day
  - **Maximum LOS** — 30 days
  - **Mean LOS** — approximately 15.5 days
- **Year Range Confirmed:** Admissions spanned **2019 through 2024** —
  matching the Admission Trend YoY line chart visible on the dashboard
  showing the growth from 7.4K in 2019 to a peak of 11.0K in 2022-2023
  before dropping to 3.9K in 2024 as the most recent partial year

### Negative Billing Amounts
- **Discovery:** Ran `.describe()` on `Billing Amount` and found **108
  records with negative values**, with a minimum of **-$2,008.49**
- **Investigation:** A negative charge in a field meant to represent patient
  billing does not make sense as a raw admission charge — likely caused by
  refund or credit adjustments stored in the wrong field, data entry errors
  with accidental minus signs, or financial corrections not separated from
  original charges at the source system
- **Resolution:**
  - Did not delete those rows — the rest of the patient record was still
    valid clinical and operational data
  - Flagged all 108 negative billing records with a boolean column
    `is_billing_adjustment = True`
  - Moved them into a dedicated Adjustments category for accounting
    reconciliation
  - Built all billing dashboards and the Total Revenue KPI of **$1.42bn**
    on the filtered dataset excluding flagged records so the figure
    reflects only actual patient charges

### Age Group Bucketing
- **Range Check:** `patient_age` ranged from **13 to 89** with a mean of
  approximately 51.5 — no invalid values were found
- **Bucketing:** Created four age group buckets to match the dashboard
  age breakdown visible in the Count of Age Bucket donut chart:
  - **Teen (13-17)** — 1.62% of total patients
  - **Young (18-35)** — 29.68% of total patients
  - **Middle Age (36-60)** — 37.67% of total patients
  - **Senior (61-89)** — 31.02% of total patients
- These buckets feed directly into the age distribution donut chart on
  the dashboard — without this transformation step, only raw age values
  would have been available and the grouped breakdown would not have been
  possible

### Data Type Enforcement
- **Dates:** Enforced `Date of Admission` and `Discharge Date` as **DATE**
  types, not VARCHAR, so all date-based queries behave consistently
- **Billing:** Enforced `Billing Amount` as **DECIMAL** for financial
  precision, not FLOAT
- **Age and Room Number:** Enforced as **INTEGER** — no decimals meaningful
- **Categorical columns:** Enforced as standardized string categories with
  controlled vocabularies to prevent undocumented values from entering on
  future loads

## Load & Pipeline Design
- **Schema Constraints:** Defined hard constraints at the warehouse level:
  - `Billing Amount >= 0` in the main billing table — adjusted records
    handled in a separate adjustments table
  - `Discharge Date >= Date of Admission` enforced at the schema level
  - `Age` constrained between 0 and 130
  - `Gender`, `Medical Condition`, `Admission Type`, `Medication`,
    `Test Results`, `Blood Type`, and `Insurance Provider` restricted to
    their validated controlled vocabularies
- **Deduplication at Load:** Built a composite key check using
  `Patient Name + Date of Admission + Hospital` so only net-new records
  are inserted on each pipeline run — preventing duplicate accumulation
  from recurring on every future load
- **Partitioning:** Enforced partitioning by admission year so the
  year-over-year trend analysis and annual aggregations run efficiently
  without full table scans

## Dashboard Construction

### Overview Page
- **KPI Cards:** Four summary cards at the top of the dashboard showing:
  - **Total Revenue** — $1.42bn across all valid admissions
  - **Total No. of Admissions** — 40,235 patient visits
  - **Total No. of Hospitals** — 39,876 distinct facilities
  - **Total No. of Doctors** — 40,341 practitioners
- **Patients by Blood Type:** Horizontal bar chart showing all 8 ABO/Rh
  combinations — A leading at 7.0K, followed by A+ at 7.0K, AB+ at 6.9K,
  AB- at 6.9K, B+ at 6.9K, B at 6.9K, O+ at 6.9K, and O- at 6.5K —
  distribution is nearly uniform across all blood types
- **Patients by Medical Condition:** Horizontal bar chart showing all 6
  conditions nearly evenly distributed — Arthritis at 9.3K, Diabetes at
  9.3K, Hypertension at 9.2K, Obesity at 9.2K, Cancer at 9.2K, and
  Asthma at 9.2K
- **Patients by Insurance Provider:** Horizontal bar chart showing Cigna
  leading at 11.2K, Medicare at 11.2K, UnitedHealthcare at 11.1K, Blue
  Cross at 11.1K, and Aetna at 10.9K
- **Patients by Medication:** Horizontal bar chart showing all 5 medications
  nearly evenly distributed — Lipitor, Ibuprofen, Aspirin, Paracetamol,
  and Penicillin each at approximately 11.1K
- **Gender Distribution:** Donut chart showing Male at 49.96% and Female
  at 50.04% — an almost perfectly balanced gender split
- **Admission Type:** Donut chart showing Elective at 33.61%, Emergency at
  33.47%, and Urgent at 32.92% — evenly distributed across all three types
- **Test Results:** Donut chart showing Abnormal at 33.56%, Inconclusive at
  33.38%, and Normal at 33.07% — nearly equal thirds across all outcomes
- **Age Bucket Distribution:** Donut chart showing Middle Age at 37.67%,
  Senior at 31.02%, Young at 29.68%, and Teen at 1.62%
- **Admission Trend YoY:** Line chart tracking annual admission volume from
  2019 through 2024 — starting at 7.4K in 2019, growing to 10.9K in 2020,
  11.3K in 2021, peaking at 11.0K in both 2022 and 2023, then dropping to
  3.9K in 2024 as the most recent partial year of data
- **Filters:** Doctor, Hospital, Insurance Provider, and Date of Admission
  slicers allow any combination of filters to be applied across all visuals
  simultaneously

## Business Impact

### Removing 534 Duplicate Records
- **Risk Prevented:** The Total No. of Admissions KPI, all medical condition
  breakdowns, all insurance provider volumes, and the year-over-year trend
  line would have been inflated by 534 phantom records that never occurred —
  overstating every count-based metric across both dashboard pages
- **Financial Impact:** With an average billing amount of approximately
  $25,500 per admission, 534 duplicate records represented over **$13.6
  million in phantom revenue** that would have inflated the $1.42bn Total
  Revenue KPI if left uncleaned
- **Operational Impact:** For hospital administrators using admission counts
  to make staffing, bed allocation, and resource planning decisions, inflated
  figures would have led to overprojecting demand and misallocating budgets
  based on visits that never happened

### Standardizing Patient Name Formatting
- **Risk Prevented:** Without consistent casing, the same patient under
  different name formats would appear as multiple distinct individuals —
  breaking readmission tracking, fragmenting longitudinal patient records,
  and causing name-based deduplication to produce false negatives
- **Operational Impact:** Every name-based join, patient lookup, and
  cross-table match now behaves consistently across every tool and analyst
  accessing the data — a patient returning for a follow-up visit is
  correctly linked to their prior record regardless of how their name was
  typed at admission

### Resolving 108 Negative Billing Records
- **Risk Prevented:** Negative values summed alongside positive charges would
  have understated total revenue, distorted average billing per condition,
  and produced unreliable financial projections for insurance reimbursement
  planning
- **Dashboard Impact:** The Total Revenue figure of **$1.42bn** on the
  dashboard reflects only actual patient charges — finance teams can trust
  that number as a true revenue figure rather than a mix of charges and
  unprocessed credits sitting in the wrong field

### Converting Date Strings to Datetime Objects
- **Risk Prevented:** String-stored dates cannot be reliably filtered by
  range, grouped by month or year, or used in time-series calculations
  without conversion — two analysts writing the same query with slightly
  different string formatting would get different results from identical
  underlying data
- **Dashboard Impact:** The Admission Trend YoY line chart tracking growth
  from 2019 through 2024, and all date-based filtering through the Date of
  Admission slicer, depend entirely on correctly typed datetime values —
  none of those visualizations would have been buildable from raw string
  timestamps

### Creating Age Group Buckets
- **Operational Impact:** Raw age values ranging from 13 to 89 are not
  directly usable as a dashboard dimension — grouping them into Teen, Young,
  Middle Age, and Senior enabled the Count of Age Bucket donut chart visible
  on the dashboard
- **Insight Unlocked:** The bucketing revealed that Middle Age patients
  (36-60) make up the largest segment at 37.67%, followed by Seniors at
  31.02% and Young adults at 29.68% — giving clinical leadership a clear
  view of which demographic is driving the majority of ER demand and where
  to focus condition management and preventive care programs

### Enforcing Schema Constraints at Load
- **Risk Prevented:** Without constraints, future data loads could silently
  introduce negative billing amounts, inverted date pairs, undocumented
  medical conditions, or out-of-range ages — corrupting the warehouse and
  every dashboard built on top of it without producing any visible error
- **Operational Impact:** Any future record violating a constraint is
  rejected and logged at ingestion, creating an auditable trail of data
  quality incidents rather than allowing bad data to accumulate undetected
  and corrupt KPIs months after the initial cleanup

### Building Deduplication Into the Pipeline
- **Risk Prevented:** Removing the 534 existing duplicates was a one-time
  fix — without a structural change to the load process, the same problem
  would recur on every future pipeline run
- **Operational Impact:** The composite key check at load time means the
  warehouse can never accumulate duplicates from repeated loads, even if
  the upstream system delivers the same file twice — eliminating an entire
  category of recurring data quality risk without requiring manual
  intervention on future runs

## Key Insights
- **Revenue:** Total revenue across all valid admissions reached **$1.42bn**
  with an average billing amount of approximately $25,500 per admission
- **Volume:** 40,235 total admissions handled across 39,876 hospitals and
  40,341 doctors — admissions peaked in 2022-2023 at 11.0K per year
- **Demographics:** Gender split was nearly perfectly even at 49.96% Male
  and 50.04% Female — Middle Age patients made up the largest age segment
  at 37.67% of total volume
- **Conditions:** All 6 medical conditions were nearly evenly distributed
  across the patient population — Arthritis and Diabetes each at 9.3K
- **Admissions:** All three admission types were nearly equally distributed
  — Elective at 33.61%, Emergency at 33.47%, and Urgent at 32.92%
- **Test Results:** Results split almost evenly into thirds — Abnormal at
  33.56%, Inconclusive at 33.38%, and Normal at 33.07%
- **Trend:** Admission volume grew steadily from 7.4K in 2019 to a peak of
  11.0K in 2022-2023 before the partial 2024 data recorded 3.9K admissions

## Repository Structure
- `/data`: Raw CSV file used for analysis
- `/notebooks`: Python notebook containing all cleaning and validation steps
- `/outputs`: Cleaned dataset exported after all transformations were applied
- `/dashboard`: Power BI workbook containing the Healthcare Analytics Dashboardmade the data warehouse itself a line of defense. Future data loads are validated automatically, which means analysts and business users can query the data with confidence rather than having to second-guess whether the underlying records are trustworthy.
