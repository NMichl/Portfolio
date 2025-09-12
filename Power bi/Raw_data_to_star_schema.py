import os
import glob
import pandas as pd



def _norm(s):
    """ Dictionary mapping used to group the very different security class names
    into 5 different classes"""

    # Convert NaN/None to empty string
    # Cast to str, uppercase, and strip whitespace
    if pd.isna(s):
        return ""
    return str(s).upper().strip()

# CLASS_MAP provides keyword hints to map noisy "Class" strings into broad buckets.
CLASS_MAP = {
    # We’ll check these with simple "if keyword in Class" tests.
    "Derivative": [
        "OPTION","OPTN","OPT ","WARRANT","WARR","WTS","RIGHT","RTS","FUTURE","FUT","SWAP","CVR"
    ],
    "Debt": [
        "CONVERTIBLE NOTE","CONV NOTE","SUB NT","SNR NT","SR NT","DEBENT","DEB","NOTE","BOND","MTN","NT"
    ],
    "Fund": [
        "ETF","ETN","FUND","TRUST","UNIT TRUST","CEFD","CLOSED-END"
    ],
    "Equity": [
        "COMMON","COM NEW","COM PAR","COM","CMN","ORDINARY","ORD","CLASS A","CLASS B","CLASS C",
        "SHS","STK","ADR","ADS","PFD","PREF","PREFERRED"
    ],
}

# Heuristics to flag inverse/leveraged funds.
# These are optional for reporting, but help keep classification robust.
INVERSE_HINTS_CLASS = ["BEAR","SHORT","INVERSE","-1X","-2X","-3X","ULTRASHORT","ULTRA SHORT"]
INVERSE_HINTS_ISSUER = ["DIREXION","PROSHARES","VELOCITYSHARES"]

def classify_via_dict(class_str: str, issuer_name: str = ""):
    """
    Returns (SecurityType, SecuritySubtype, IsInverseLeveraged)
    Priority: Derivative -> Debt -> Fund -> Equity -> Other
    """
    # Normalize inputs once for consistent substring checks.
    c = _norm(class_str)
    n = _norm(issuer_name)

    # Priority order to avoid accidental equity hits inside debt/derivative strings
    for bucket in ["Derivative","Debt","Fund","Equity"]:
        for kw in CLASS_MAP[bucket]:
            if kw in c:
                if bucket == "Equity":
                    # Equity subtype: distinguish Preferred vs Common/Ordinary.
                    subtype = "Preferred" if any(k in c for k in ["PFD","PREF","PREFERRED"]) else "Common/Ordinary"
                    return "Equity", subtype, False
                if bucket == "Fund":
                    # Mark inverse/leveraged via class hints or (issuer + short/bear terms).
                    # This helps avoid counting leveraged ETFs as plain funds.
                    is_inv = any(k in c for k in INVERSE_HINTS_CLASS) or \
                             (any(k in n for k in INVERSE_HINTS_ISSUER) and any(k in c for k in ["SHORT","BEAR","INVERSE"]))
                    return "Fund", "Inverse/Leveraged" if is_inv else "Standard", is_inv
                # Derivative or Debt
                subtype = "Option/Warrant/Right" if bucket == "Derivative" else "Note/Bond"
                return bucket, subtype, False
    #  If nothing matched, classify as Other to audit later.
    return "Other", "", False






def transform_starschema(input_glob: str, output_folder: str, write_csv: bool = True):
    #  1) Load all matching CSVs and tag FirmName
    # Replace backslashes for glob compatibility, collect and sort file list.
    files = sorted(glob.glob(input_glob.replace("\\", "/")))
    if not files:
        # Fail early with a clear message if the pattern returns nothing.
        raise FileNotFoundError(f"No CSVs matched pattern: {input_glob}")

    frames = []
    for f in files:
        # Read each CSV and copy to avoid chained assignment issues downstream.
        df = pd.read_csv(f)
        df = df.copy()
        # Derive FirmName from the filename (without extension) and tag each row.
        firm_name = os.path.splitext(os.path.basename(f))[0]
        df["FirmName"] = firm_name
        frames.append(df)
    # Concatenate all firm DataFrames vertically
    df_all = pd.concat(frames, ignore_index=True)

    # 2) Parse timestamps and derive QuarterEndDate + attributes (kept)
    df_all["report_dates"] = pd.to_datetime(
        df_all["report_dates"].astype(str).str.strip(), errors="coerce"
    )
    df_all = df_all.copy()
    # Convert to quarterly periods for consistent quarter-based snapshots.
    q = df_all["report_dates"].dt.to_period("Q")

    # Year/Quarter/YearQuarter are derived from the period object.
    df_all["Year"] = q.dt.year
    df_all["Quarter"] = q.dt.quarter
    df_all["YearQuarter"] = q.astype(str)  # e.g. "2024Q1"

    # Quarter end as a plain date (unchanged intent)
    df_all["QuarterEndDate"] = q.dt.end_time.dt.date

    # 2b) Add DateKey (YYYYMMDD) for a proper Dim_Date join
    # Use quarter end date as the snapshot date
    quarter_end_ts = q.dt.end_time  # pandas Timestamp
    df_all["DateKey"] = quarter_end_ts.dt.strftime("%Y%m%d").astype(int)

    # 3) Aggregate to Firm × Security × Quarter
    # Drop Company/Class from grouping to avoid splitting the same CUSIP by text drift
    group_cols = ["FirmName", "CUSIP", "DateKey"]
    agg = (
        df_all.groupby(group_cols, dropna=False)
        .agg(Shares=("Shares", "sum"), Value=("Value", "sum"))
        .reset_index()
    )

    # 4) Build dimensions (Security, Date, Firm)
    # Dim_Security: use latest attributes per CUSIP from source rows
    sec_attrs = (
        df_all.sort_values("report_dates")
        .drop_duplicates(subset=["CUSIP"], keep="last")[["CUSIP", "Company", "Class"]]
    )

    # 4a) Dictionary mapping to Equity / Derivative / Debt (+ Fund/Other)
    sec_attrs["Class_Normalized"] = sec_attrs["Class"].apply(_norm)
    # Apply classifier row-wise, returning a 3-tuple: (SecurityType, SecuritySubtype, IsInverseLeveraged)
    mapped = sec_attrs.apply(
        lambda r: classify_via_dict(r["Class"], r["Company"]), axis=1, result_type="expand"
    )
    mapped.columns = ["SecurityType", "SecuritySubtype", "IsInverseLeveraged"]
    # Attach the mapped columns to the security attributes.
    sec_attrs = pd.concat([sec_attrs, mapped], axis=1)

    # Build Dim_Security with explicit columns and add a convenience IsEquity flag.
    dim_security = (
        sec_attrs.rename(
            columns={
                "CUSIP": "SecurityKey",
                "Company": "IssuerCompanyName",
            }
        )
        .assign(IsEquity=lambda d: d["SecurityType"].eq("Equity"))
        .loc[:, [
                    "SecurityKey",
                    "IssuerCompanyName",
                    "Class",  # raw
                    "Class_Normalized",  # helper
                    "SecurityType",  # Equity / Derivative / Debt / Fund / Other
                    "SecuritySubtype",  # Common/Ordinary, Preferred, etc.
                    "IsInverseLeveraged",  # True for inverse/leveraged funds
                    "IsEquity"
                ]]
        .reset_index(drop=True)
    )

    # Dim_Date: quarter-end members with attributes
    dim_date = (
        df_all[["DateKey", "QuarterEndDate", "Year", "Quarter", "YearQuarter"]]
        .drop_duplicates()
        .sort_values("QuarterEndDate")
        .rename(columns={"QuarterEndDate": "Date"})
        .reset_index(drop=True)
    )

    # Dim_Firm: simple surrogate key for firms (from filename)
    dim_firm = (
        agg[["FirmName"]]
        .drop_duplicates()
        .sort_values("FirmName")
        .reset_index(drop=True)
    )
    # Deterministic surrogate key (1..N) based on first appearance order
    dim_firm["FirmKey"] = pd.factorize(dim_firm["FirmName"])[0] + 1

    # 5) Fact table: only FKs + measures
    fact_holding = (
        agg.merge(dim_firm, on="FirmName", how="left")
        .rename(columns={"CUSIP": "SecurityKey"})
        .loc[:, ["FirmKey", "SecurityKey", "DateKey", "Shares", "Value"]]
        .reset_index(drop=True)
    )


    #  6) Write CSVs (adds Dim_Firm & Dim_Date)
    if write_csv:
        os.makedirs(output_folder, exist_ok=True)

        dim_security.to_csv(
            os.path.join(output_folder, "Dim_Security.csv"), index=False
        )
        dim_date.to_csv(os.path.join(output_folder, "Dim_Date.csv"), index=False)
        dim_firm.to_csv(os.path.join(output_folder, "Dim_Firm.csv"), index=False)

        fact_holding.to_csv(
            os.path.join(output_folder, "Fact_HoldingSnapshot.csv"), index=False
        )
    # Return DataFrames for optional in-memory use.
    return {
        "Dim_Security": dim_security,
        "Dim_Date": dim_date,
        "Dim_Firm": dim_firm,
        "Fact_HoldingSnapshot": fact_holding,
    }


# Example direct call (kept as in your original script)
transform_starschema(
    r"C:\Users\Niklas\Desktop\SEC_Power BI\*.csv",
    r"C:\Users\Niklas\Desktop\SEC_Power BI\Dimensions",
)
