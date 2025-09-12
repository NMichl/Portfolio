import os
import pandas as pd
import edgar as ed
import requests
from bs4 import BeautifulSoup



# pip install html5lib need to be run in the terminal (Together with the above installed packages of course)

# Find from ticker the matching CIK number
def ticker_matching_cik(ticker, headers=None):
    if headers is None:
        user_email = input("Enter your email address for SEC requests: ")
        headers = {"User-Agent": user_email}
    ticker = ticker.upper().replace(".", "-")
    cik_data = requests.get("https://www.sec.gov/files/company_tickers.json", headers=headers)
    data = cik_data.json()
    for row in data.values():
        if ticker == row["ticker"]:
            company_name = row['title']
            cik = str(row['cik_str']).zfill(10)
            return cik, company_name
    return None, None


# Example Berkshire Hathaway ticker
# print(ticker_matching_cik("brk.b"))



# Access filings
def csv__with_13fdata():
    """
    Download and parse 13F filings for a given CIK.
    For each reportDate:
        - decide if later filings (13F-HR/A) are replacements of the original report (13F-HR) or
          partial amendments (based on row-count thresholds: >=80% = replacement, <=20% = patch).
        - combine main + patch filings into one holdings table.
        - ambiguous filings are saved separately for manual review.
    Finally, all reportDates are concatenated and written to CSV.
    """
    user_email = input("Enter your email address for SEC requests: ")
    cik = input("Please provide you cik number (without space):")
    storage = input("Please provide the path you want to store the data at you computer:")
    storage = storage.replace("\\", "/")
    name = input("Please provide the name of the file (/name_datei.csv at the end):")
    begin_date_str = input("Please provide the begin Date for 'Period of Report' (YYYY-MM-DD): ").strip()
    base_name = name[:-4]  # Used later for name ambiguous file

    ed.set_identity(user_email)  # Send the identity to the Server of the SEC
    company_filings = ed.Company(cik)
    subset_company_filings = company_filings.get_filings(form="13F-HR")  # Subset to 13F Filings

    # Subset the company filings until the desired Date
    begin_date = pd.to_datetime(begin_date_str)
    all_meta_df = subset_company_filings.to_pandas()
    all_meta_df["reportDate"] = pd.to_datetime(all_meta_df["reportDate"])
    df = all_meta_df[all_meta_df["reportDate"] >= begin_date].copy()


    allowed_accs = set(df["accession_number"])
    latest_13fs_subset = [f for f in subset_company_filings if f.accession_no in allowed_accs]
    latest_13fs_number = len(latest_13fs_subset)

    latest_13fs = subset_company_filings.latest(n= latest_13fs_number)
    # filings metadata to pandas for sorting
    pd.set_option("display.max_columns", None)
    df = latest_13fs.to_pandas()  # data frame so the filing_date can be simply extracted


    # Normalize datatypes and sort: newest reportDate first; within each period, oldest filing first
    df["reportDate"] = pd.to_datetime(df["reportDate"])
    df.sort_values(["reportDate", "filing_date"], ascending=[False, True], inplace=True)
    print(df)

    # Build a lookup so we can get the right Filing object by accession number
    # Fixes the mismatch between the sorted df and the unsorted latest_13fs list
    acc_to_filing = {f.accession_no: f for f in latest_13fs}
    print(acc_to_filing)

    # Initialization of variables
    current_date = None
    upper_threshold = 0.8
    lower_threshold = 0.2
    i = 0
    n = len(df)
    final_dataframe = pd.DataFrame()  # holds all periods combined
    same_date_df = pd.DataFrame()  # cache for current period rows


    # --- Walk through the sorted filings; process one reportDate group at a time
    while i < n:
        if current_date is None:
            current_date = df.iloc[i, :]

            same_date_df = df[df["reportDate"] == current_date["reportDate"]]

        length_original = 0  # baseline row count (from the first file in period)
        main_dataframe = pd.DataFrame()  # the "replacement"/main filing for this period
        subsidiary_dataframe = pd.DataFrame()  # collected "patch" filings for this period
        # "ambiguous" filings for this period are directly saved to a folder

        w = 0
        while w < len(same_date_df):
            print(w)
            # Pick the right Filing object by accession number from the sorted row
            row = same_date_df.iloc[w]
            acc = row["accession_number"]
            latest_13f = acc_to_filing[acc]
            print(latest_13f)

            file = latest_13f.attachments[
                2]  # the data is stored in xml files inside these attachments (just the name of the xml files)
            file_html_code = file.download()  # we download each of these xml using the name from above

            # Parse holdings rows from the XML
            soup = BeautifulSoup(file_html_code, "xml")
            rows = []
            for info in soup.find_all("infoTable"):
                row = {
                    "Company": info.find("nameOfIssuer").text if info.find("nameOfIssuer") else None,
                    "Class": info.find("titleOfClass").text if info.find("titleOfClass") else None,
                    "CUSIP": info.find("cusip").text if info.find("cusip") else None,
                    "Value": int(info.find("value").text) if info.find("value") else None,
                    "Shares": int(info.find("shrsOrPrnAmt").find("sshPrnamt").text) if info.find(
                        "shrsOrPrnAmt") else None,
                    "SharesType": info.find("shrsOrPrnAmt").find("sshPrnamtType").text if info.find(
                        "shrsOrPrnAmt") else None,
                    "Discretion": info.find("investmentDiscretion").text if info.find("investmentDiscretion") else None,

                }
                rows.append(row)

            # Convert to DataFrame
            data_frame = pd.DataFrame(rows)
            print(data_frame.head())  # shows how the data look like in the data frame we created trough BeautifulSoup
            print(data_frame.info())

            # Keep the period metadata on these rows (report date from the group anchor)
            data_frame["report_dates"] = current_date["reportDate"]  # assign the filling_date to the whole file

            
            # Before 2022 Q4 the SEC reported values in thousands, so multiply *1000 the values before that point.
            rd = pd.to_datetime(current_date["report_dates"])
            cutoff = pd.Timestamp(2022, 10, 1) # start of Q4 2022

            if rd < cutoff:
                data_frame["Value"] = data_frame["Value"] * 1000
            else:
                pass

            # Decide replacement vs. patch vs. ambiguous for this period
            if w == 0:
                # First filing in this period becomes the baseline for row-count comparisons
                length_original = len(data_frame)
                main_dataframe = data_frame
                # The first file is treated as the provisional "main" (until a replacement appears)

            else:
                length_attachment = len(data_frame)

                #  >=80% of original rows => treat as replacement (use this as new main)
                if length_attachment * upper_threshold > length_original:
                    main_dataframe = data_frame

                # <=20% of original rows => treat as patch (append to subsidiary)
                elif length_attachment * lower_threshold < length_original:
                    subsidiary_dataframe = pd.concat([subsidiary_dataframe, data_frame], ignore_index=True)

                # Otherwise ambiguous => save to disk for manual review (does not change main)
                else:
                    # save ambiguous filing separately

                    save_dir = r"C:\Users\Niklas\Desktop\SEC_Power BI\main_or_attachment"
                    # use the current group's report date in the filename
                    report_str = pd.to_datetime(current_date["reportDate"]).strftime("%Y-%m-%d")
                    out_path = os.path.join(save_dir, f"{base_name}_{report_str}_decision.csv")
                    data_frame.to_csv(out_path, index=False)
                    print(f"[decision] saved: {out_path}")

            w = w + 1  # next filing in this period

        #  Build the combined holdings for this reportDate
        complete_dataframe = pd.concat([main_dataframe, subsidiary_dataframe], ignore_index=True)

        # Move to the next reportDate group
        i += len(same_date_df)
        current_date = None

        # Accumulate across all periods (this prevents overwriting)
        final_dataframe = pd.concat([final_dataframe, complete_dataframe], ignore_index=True)

    #  Ensure no double slashes if someone insert the path with backslash at the end
    full_path = f"{storage}/{name}".replace("//", "/")
    final_dataframe.to_csv(full_path, index=False)


csv__with_13fdata()
