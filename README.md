# Portfolio

Technical Skills: Python, SQL, R

# Education

- **M.Sc. Economics** — Universität zu Köln _(May 2025)_
- **B.Sc. Economics** — Goethe Universität Frankfurt am Main _(May 2022)_

---

# Projects

---

## 🌍 1. International Debt Analysis (PostgreSQL)

Analyzes sovereign debt risk using World Bank International Debt Statistics. 
**Measures**: 
- Debt Indicators (below)
- Own developed debt risk score (Debt-to-GNI > 60%, Debt per capita > $5000, Short-term debt > 30% of total external debt) which assign points for each sustainable debt goal failed (MAX 3). 
**Skills**: Real-world **data cleaning** and **SQL-based economic analysis**.

**Debt Indicators:**
- "DT.DOD.DPNG.CD"	"External debt stocks private nonguaranteed (PNG) (DOD current US$)"
- "DT.DOD.DECT.GN.ZS"	"External debt stocks (% of GNI)"
- "DT.DOD.DPPG.CD"	"External debt stocks public and publicly guaranteed (PPG) (DOD current US$)"
- "DT.DOD.DSTC.CD"	"External debt stocks short-term (DOD current US$)"
- "DT.DOD.DECT.PC.CD"	"Total external debt per capita (US$)"
- "DT.DOD.DECT.EX.ZS"	"External debt stocks (% of exports of goods services and primary income)"
- "DT.DOD.DECT.CD"	"External debt stocks total (DOD current US$)"

---

### 🛠 Tools & Dataset
- `pandas`, `numpy`, `chardet` * For data cleaning
-  PostgreSQL as databse
- [World Bank – International Debt Statistics](https://databank.worldbank.org/source/international-debt-statistics)

### 🗂️ Project Structure
**`SQL/Data_Cleaning/`**
`international_debt.csv` – Raw dataset
[`world_bank_cleaning.py`](SQL/Data_Cleaning/world_bank_cleaning.py) –  Data Cleaning 

**`SQL/Queries/`**
`creation_table_cleaning.sql`- Cleaning
`basic_exploration.sql` – Initial structure queries
`advanced_analysis.sql` – Deep dive into debt risk metrics

**`SQL/Results/`**
[`results_whole_analysis.ipynb`](SQL/Results/results_whole_analysis.ipynb) – *Final queries, visuals, and conclusions*

---

### Data Preparation Highlights
- Fixed encoding errors using `chardet`
- Strips whitespace and removes special characters (e.g., commas, replace '..' with NA)
- Reshaped data with `pandas.melt()` to long format for SQL analysis
- Drops invalid or incomplete row
- Exported UTF-8 cleaned CSV for PostgreSQL

### Results  
Analysis based on 2019 debt, with some comparison to 2023  
**High-risk countries**: Mauritius and Dominica (Risk score = 3)  
Mongolia (264% debt-to-GNI) and Montenegro (151%) and (Risk score = 2).  
Additonaly 7 other countries have Risk score = 2  
**China**: High absolute debt, but moderate debt-to-GNI  
**Private vs public debt** Public debt dominates in most nations  
**Improvement** noted in some countries, but debt imbalances persist  

---

## 📈 2. Trading Algorithm (R Master’s Thesis)

Developed a bubble-detection trading strategy using:
- **SADF (Supremum Augmented Dickey Fuller)**
- **CUSUM (Cumulative Sum)**

### Features
- Identifies **explosive price behavior** and bubble crashes in a real time monitoring scenario
- Implements **entry/exit timing rules**
- Backtests strategy vs. passive benchmark
- Calculates **CAPM, Sharpe Ratio, and returns**
  
---

### 🛠 Tools & Dataset
`ggplot2`, `exuber` (SADF test), `yahoofinancer` (API for data), `dplyr`, `lubridate`, `PerformanceAnalytics`

### 🗂️ Project Structure
**`R/Masterarbeit_code/`**
- [`trading-algorithm.R`](R/Masterarbeit_code/trading-algorithm.R) – *All core logic: tests, monitoring, performance metrics*

**`R/Masterarbeit_pdf/`**
- [`masterarbeit.pdf`](R/Masterarbeit_code/trading-algorithm.R) – *Full thesis document*
  
---

###  Results
- Generate consistent positive returns
- Outperforms benchmark in volatile markets
- Adapts to macro regime shifts
- Maintains strong Sharpe ratio (risk-adjusted returns)

---
## 3. Unemployment Forecasting (Python, scikit-learn)

Analyzes macroeconomic indicators from the World Bank to model and forecast unemployment rates across countries.

**Focus:**
- Time-series forecasting with lagged predictors (1-, 2-, and 4-year lags)
- Hierarchical imputation (country trends → subgroup medians → global fallback)
- Skills: Real-world time-series preparation, hierarchical imputation, and machine learning forecasting with cross-validation.

### 🛠 Tools & Dataset
- `wbgapi` - Api World Bank
- `pandas`, `numpy`, `matplotlib`, `seaborn` — cleaning & visualization
- `scikit-learn` - Machine learning
- Data: World Bank Open Data — macroeconomic indicators

### 🗂️ Project Structure

**`Python/predicting_unemployment`**
`import_data_api.py` – Collects raw macro indicators via World Bank API, reshapes into tidy panel, and exports cleaned dataset
`cleaning_and_model.ipynb` – Missing data diagnostics, hierarchical imputation, lag feature engineering, PCA, and machine learning models (Linear Regression, KNN, Random Forest)

### Data Preparation Highlights
- Restricted window to 1991 onward (availability of unemployment data)
- Dropped countries with insufficient target coverage
- Deleated features with >30% missingness
- Created lagged features for persistence and delayed effects
- Applied region × income subgroup imputations before fallback to global stats

### Results
- Linear Regression — RMSE: 2.393, R²: 0.678, MAE: 1.541
- KNN Regression — RMSE: 2.858, R²: 0.677, MAE: 2.175
- Random Forest Regression — RMSE: 2.584, R²: 0.717, MAE: 1.904
- Good R² values (>0.65) across all models indicate strong explanatory power for macroeconomic forecasting.
- Linear Regression is most accurate on average errors, while Random Forest balances accuracy with higher explanatory strength.
- **Of course further hyperparamter tuning needs to be done to get more reliable results**

---

## 🧾 4. SEC 13F Filing Data Extractor (Automation)

**Goal:**  
Extract and analyze institutional investment data from SEC **13F-HR filings**, using company CIKs or ticker symbols.

---

### ⚙️ What This Script Does

-  Converts stock tickers (e.g., `BRK.B`) into **CIK numbers** from the SEC database
-  Downloads recent **13F-HR filings** for the company using the EDGAR system
-  Parses **XML filings** with `BeautifulSoup`
-  Extracts key data: company name, CUSIP, shares held, value, etc.
-  Merges filings into one DataFrame and saves it as a **CSV**

---

### 🛠 Tools
`pandas`, `requests`, `beautifulsoup4`,  `edgar` (Python SEC wrapper),  `html5lib` (parser dependency)

---

###  Example Use
You’ll be prompted to:
1. Enter your email for SEC access headers
2. Input the CIK of the institution
3. Set a local path + filename for output

---


## 📱 5. App Success Analysis (Python: Not completed !!)

**Goal:** Understand what contributes to an app's success on the Google Play Store, defined by:
- High Install Count
- High User Ratings
  
---

### 🛠 Tools & Dataset
- `Python`, `pandas`, `matplotlib`, `seaborn`
- Dataset: [Google Play Store Apps (2018)](https://github.com/schlende/practical-pandas-projects/blob/master/datasets/google-play-store-11-2018.csv)
  
---

### 📊 Key Analyses

#### 1. Ratings vs Popularity
- Apps grouped by install count: `0–100k`, `100k–1M`, `>1M`
- Average star ratings are similar across groups (~4.3)
- Higher installs → much higher review volume
> Popular apps don't get better ratings, just more visibility and more reviews.

#### 2. Genre-Based Trends
Compared genres by:
  - Total installs
  - Average rating
  - Number of apps
> No single genre leads across all three metrics — quantity ≠ quality ≠ popularity.

---
### Results

App success is driven by visibility more than rating quality.  
Genres perform differently depending on metric — top-performing genres in installs aren't always top-rated.

---

