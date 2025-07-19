# Portfolio

# Technical Skills: Python, SQL, R

# 🎓 Education

- **M.Sc. Economics** — Universität zu Köln _(Expected: May 2025)_
- **B.Sc. Economics** — Goethe Universität Frankfurt am Main _(May 2022)_

---

# 📁 Projects

## 🌍 International Debt Analysis (SQL + PostgreSQL)

Analyzes sovereign debt risk using World Bank International Debt Statistics.  
Focus: real-world **data cleaning** and **SQL-based economic analysis**.

**Indicators Used:**
- External debt stocks: PNG, PPG, total, short-term
- Debt-to-GNI, per capita, export ratios

### 📥 Data Source
- [World Bank – International Debt Statistics](https://databank.worldbank.org/source/international-debt-statistics)

### 🗂️ Project Structure

**`SQL/Data_Cleaning/`**
- `international_debt.csv` – Raw dataset
- [`world_bank_cleaning.py`](SQL/Data_Cleaning/world_bank_cleaning.py) – *Data cleaning with `pandas`, `numpy`, `chardet`*

**`SQL/Queries/`**
- `creation_table_cleaning.sql` – Table setup + aggregates
- `basic_exploration.sql` – Initial structure queries
- `advanced_analysis.sql` – Deep dive into debt risk metrics

**`SQL/Results/`**
- [`results_whole_analysis.ipynb`](SQL/Results/results_whole_analysis.ipynb) – *Final queries, visuals, and conclusions*

### 🧹 Data Preparation Highlights

- Fixed encoding errors using `chardet`
- Cleaned text and removed invalid entries
- Reshaped data with `pandas.melt()` for SQL analysis
- Exported UTF-8 cleaned CSV for PostgreSQL

### 📌 Key Insights

- Analysis based on 2019 debt levels with some comparison to 2023
- **High-risk countries**: Mauritius, Dominica, Mongolia (264% debt-to-GNI), Montenegro (151%)
- **China**: High absolute debt, but moderate debt-to-GNI
- **Private vs public debt** varies by country (e.g., Mozambique)
- **Improvement** noted in some countries, but debt imbalances persist

---

## 🤖📈 Trading Algorithm (R Master’s Thesis)

Developed a bubble-detection trading strategy using:
- **SADF (Supremum ADF)**
- **CUSUM structural break tests**

### 📌 Features
- Identifies **explosive price behavior** and bubble crashes
- Implements **entry/exit timing rules**
- Backtests strategy vs. passive benchmark
- Calculates **CAPM, Sharpe Ratio, and returns**

### 🗂️ Project Structure

**`R/Masterarbeit_code/`**
- [`trading-algorithm.R`](R/Masterarbeit_code/trading-algorithm.R) – *All core logic: tests, monitoring, performance metrics*

**`R/Masterarbeit_pdf/`**
- [`masterarbeit.pdf`](R/Masterarbeit_code/trading-algorithm.R) – *Full thesis document*

### 📈 Results

- Outperforms benchmark in volatile markets
- Adapts to macro regime shifts
- Maintains strong Sharpe ratio (risk-adjusted returns)

---


## 📱 Google Play Store App Success Analysis (Python !! Not completed)

**Goal:** Understand what contributes to an app's success on the Google Play Store, defined by:
- 📈 High Install Count
- ⭐ High User Ratings

---

### 🛠️ Tools & Dataset

- Python, pandas, matplotlib, seaborn
- Dataset: [Google Play Store Apps (2018)](https://github.com/schlende/practical-pandas-projects/blob/master/datasets/google-play-store-11-2018.csv)

---

### 📊 Key Analyses

### 1. Ratings vs Popularity
- Apps grouped by install count: `0–100k`, `100k–1M`, `>1M`
- Average star ratings are similar across groups (~4.3)
- Higher installs → much higher review volume
> Popular apps don't get better ratings, just more visibility and more reviews.

---

### 2. Genre-Based Trends
- Compared genres by:
  - Total installs
  - Average rating
  - Number of apps
> No single genre leads across all three metrics — quantity ≠ quality ≠ popularity.

---

### ✅ Conclusion

App **success** is driven by visibility more than rating quality.  
**Genres** perform differently depending on metric — top-performing genres in installs aren't always top-rated.


## 🧾 SEC 13F Filing Data Extractor (Automation)

**Goal:**  
Extract and analyze institutional investment data from SEC **13F-HR filings**, using company CIKs or ticker symbols.

---

### ⚙️ What This Script Does

- ✅ Converts stock tickers (e.g., `BRK.B`) into **CIK numbers** from the SEC database
- ✅ Downloads recent **13F-HR filings** for the company using the EDGAR system
- ✅ Parses **XML filings** with `BeautifulSoup`
- ✅ Extracts key data: company name, CUSIP, shares held, value, etc.
- ✅ Merges filings into one DataFrame and saves it as a **CSV**

---

### 📦 Tools Used

- `pandas`
- `requests`
- `beautifulsoup4`
- `edgar` (Python SEC wrapper)
- `html5lib` (parser dependency)

---

### 🧪 Example Use

You’ll be prompted to:
1. Enter your email for SEC access headers
2. Input the CIK of the institution
3. Set a local path + filename for output



