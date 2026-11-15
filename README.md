# CareLoop Clinics — No-Show Guard
**From Raw Bookings to a Risk Model and AI-Assisted Follow-Up Review**

**Repository URL**: [https://github.com/abhay-careloop/careloop-noshow-guard](https://github.com/abhay-careloop/careloop-noshow-guard)

---

## 1. Executive Summary (Four-Part Findings)
- **Part 1 (Data Foundations)**: Cleaned 1,020 raw clinic bookings down to 990 verified records after dropping 20 exact duplicates, 6 unreadable dates, and 4 missing statuses, identifying 218 no-shows (22.0% baseline rate) and capping 26 distance and 3 fee outliers.
- **Part 2 (SQL Analytics)**: Database queries revealed substantial clinic-level variance, with Lucknow's Gomti Nagar clinic exhibiting the highest no-show rate at 33.3% (90 visits), while appointments booked 31+ days in advance experienced a 60.5% no-show rate compared to just 16.2% for 1–7 day lead times.
- **Part 3 (Machine Learning)**: A regularized Logistic Regression pipeline achieved the highest cross-validated training ROC-AUC (0.775) and test ROC-AUC (0.789); tuning the classification threshold to 0.35 elevated test recall to 57.1% (F1 = 0.57, 49 flagged), revealing that sending an appointment reminder is associated with a 69% reduction in no-show odds ($\text{OR} \approx 0.31$).
- **Part 4 (GenAI Intelligence)**: Pydantic-validated Gemini Flash analysis of call-centre notes established that 100% (2 of 2) of patients citing forgetfulness had not received a reminder (`reminder_sent = No`), and 50% (5 of 10) of all surveyed missed visits lacked automated notification.

---

## 2. Business Recommendation
To eliminate idle doctor consulting capacity across its eight clinics, CareLoop management should immediately execute a coordinated operational protocol:
First, mandate automated multi-channel (SMS and WhatsApp) reminders for every booking, as sending a reminder is associated with a **69% reduction in the odds of a no-show** ($\text{OR} = 0.31$, $p < 0.001$) and directly resolves the root cause for **100% (2 of 2)** of patients who missed visits simply due to forgetting. Second, deploy the Logistic Regression risk model on the evening prior to appointments (T-1) at an operational threshold of **0.35**; this flags **49 high-risk bookings** (24.7% of the schedule) while successfully intercepting **57.1% of all impending no-shows** (test recall = 0.57) for dedicated 2-minute front-desk confirmation calls. Front-desk teams must prioritize patients with long booking lead times, as visits scheduled **31+ days in advance** suffer a staggering **60.5% no-show rate** (versus **16.2%** for 1–7 days), alongside targeted operational reviews at underperforming facilities like Lucknow (**33.3%** no-shows) and Pune Hadapsar (**27.3%** no-shows).

---

## 3. Model Selection & Operational Threshold Rationale
### Model Choice
- **Selected Model**: Logistic Regression with `StandardScaler` Pipeline (`max_iter=1000`, $C=1.0$).
- **Selection Criteria**: Evaluated strictly on the training set via 5-fold cross-validation, Logistic Regression achieved the highest CV ROC-AUC (**0.775**), outperforming the tuned Random Forest (**0.771**), default Random Forest (**0.751**), and depth-3 Decision Tree (**0.684**).
- **Test Performance**: On the held-out test set ($N=198$, 49 no-shows), Logistic Regression delivered an **ROC-AUC of 0.789**, outperforming unconstrained Decision Trees which suffered severe overfitting (collapsing from 1.00 training accuracy to 0.672 test accuracy, well below the 0.7525 majority-class baseline).
- **Clinical Governance**: Logistic Regression provides fully transparent, auditable odds ratios required for healthcare administrative compliance.

### Threshold Calibration (0.50 vs 0.35)
- **Out-of-Fold (OOF) Training Evaluation**:
  - Threshold 0.50: Precision = 0.586, Recall = 0.243, F1 = 0.343, Flagged = 70.
  - Threshold 0.35: Precision = 0.519, Recall = 0.473, F1 = 0.495, Flagged = 154.
- **Test Set Evaluation at Threshold 0.35**:
  - Precision = **0.571**, Recall = **0.571**, F1 = **0.571**, Flagged = **49**, ROC-AUC = **0.789**.
- **Operational Alignment**: In outpatient clinic economics, an unaddressed no-show permanently wastes an entire clinician consultation slot worth **₹500 to ₹1,200**, whereas an outgoing front-desk phone call takes only **1 to 2 minutes**. Threshold 0.35 captures more than double the missed visits compared to default 0.50 while generating approximately 6–7 calls per clinic evening, perfectly matching staff capacity.

---

## 4. Honest Methodological Limitations
1. **Pilot Call-Centre Sample Size**: The 10 qualitative notes analyzed in Part 4 serve as an illustrative demonstration of GenAI classification capabilities; they cannot represent the full distribution of patient attrition factors across all 8 clinics and thousands of annual visits.
2. **Pre-Split Data Leakage in Cleaning**: Domain medians (age = 48, distance = 8.25 km) and IQR outlier capping fences (upper fee = ₹1,218.75) were computed across the entire 990-row dataset prior to partitioning. In a live clinical deployment, all transformers and imputers must be fitted strictly on past training records.
3. **Observational Association vs Causality**: All findings reflect observational correlations within historical records. While reminders show a strong negative coefficient ($\beta = -0.58$, $\text{OR} = 0.31$), this does not prove reminders causally prevent no-shows without randomized A/B trial validation.

---

## 5. Repository Structure
```
careloop-noshow-guard/
├── data/
│   ├── appointments.csv         # Original raw booking export (1,020 rows)
│   ├── clinics.csv              # Clinic master table (8 clinics)
│   └── followup_notes.csv       # Unstructured call-centre notes (30 rows)
├── 01_ingest_clean.ipynb        # Tasks 1.1–1.6: Ingest, inspect, clean, enrich
├── rejected_rows.json           # Malformed raw records rejected during type parsing (32 rows)
├── appointments_clean.csv       # Cleaned, validated appointments table (990 rows, 16 cols)
├── clinics_enriched.csv         # Clinics enriched with live Open-Meteo weather data (8 rows)
├── load_data.sql                # Relational SQL DDL and INSERT script (998 statements)
├── 02_queries.sql               # Part 2 SQL verification and clinic performance queries
├── 03_model.ipynb               # Tasks 3.1–3.5: Feature matrix, ML models, CV, thresholding
├── test_risk_scores.csv         # Test set risk predictions and outreach flags (198 rows)
├── 04_genai.ipynb               # Tasks 4.1–4.4: Gemini API CRAFT prompt, Pydantic, synthesis
├── notes_analysed.csv           # Structured intelligence from patient notes (10 rows, 8 cols)
└── README.md                    # Project documentation and executive business case
```

---

## 6. Execution Instructions
### Prerequisites
- **Python**: 3.10+ (tested on Python 3.11.9)
- **Required Libraries**: `pandas`, `numpy`, `scikit-learn`, `pydantic`, `google-genai`, `requests`
```bash
pip install pandas numpy scikit-learn pydantic google-genai requests
```
### Running the Analysis
1. Open `01_ingest_clean.ipynb` to execute data ingestion, cleaning, Open-Meteo enrichment, and export.
2. Run `02_queries.sql` in MySQL Workbench (or SQLite) after executing `load_data.sql` to verify database analytics.
3. Run `03_model.ipynb` to reproduce model training, cross-validation, and risk scoring.
4. Run `04_genai.ipynb` to execute structured GenAI note classification (requires a free Google AI Studio API key).
