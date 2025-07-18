from pickle import GLOBAL
import pandas as pd
import edgar as ed
import requests
from bs4 import BeautifulSoup
# pip install html5lib need to be run in the terminal (Together with the above installed packages of course)

# Find from ticker the matching CIK number
def ticker_matching_cik(ticker, headers=None):
    global user_email
    if headers is None:
        user_email = input("Enter your email address for SEC reqeusts: ")
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
print(ticker_matching_cik("brk.b"))




# Access filings
def csv__with_13fdata():
    cik = input("Please provide you cik number (without space):")
    storage = input("Please provide the path you want to store the data at you computer:")
    storage = storage.replace("\\", "/")
    name = input("Please provide the name of the file (/name_datei.csv at the end):")
    ed.set_identity(user_email) # Send the identity to the Server of the SEC
    berkshire = ed.Company(cik)
    berkshire_filings = berkshire.get_filings(form="13F-HR")  # Subset to 13F Filings                            #
    latest_13fs = berkshire_filings.latest(n=10) # subset to only a few years of 13F fillings
    # Get automatically the filing_date
    pd.set_option("display.max_columns", None)
    filing_date = latest_13fs.to_pandas() # data frame so the filing_date can be simply extracted
    filing_dates = filing_date.iloc[0:9, 3]
    # initializing of the final data frame
    final_data_frame = pd.DataFrame()
    w = 0
    while w <= 6:
        latest_13f = latest_13fs[w]
        print(latest_13f)
        file = latest_13f.attachments[2] # the data is stored in xml files inside these attachments (just the name of the xml files)
        file_html_code = file.download() # we download each of these xml using the name from above

        soup = BeautifulSoup(file_html_code, "xml")

        rows = []

        for info in soup.find_all("infoTable"):
            row = {
                "Company": info.find("nameOfIssuer").text if info.find("nameOfIssuer") else None,
                "Class": info.find("titleOfClass").text if info.find("titleOfClass") else None,
                "CUSIP": info.find("cusip").text if info.find("cusip") else None,
                "Value": int(info.find("value").text) if info.find("value") else None,
                "Shares": int(info.find("shrsOrPrnAmt").find("sshPrnamt").text) if info.find("shrsOrPrnAmt") else None,
                "SharesType": info.find("shrsOrPrnAmt").find("sshPrnamtType").text if info.find(
                    "shrsOrPrnAmt") else None,
                "Discretion": info.find("investmentDiscretion").text if info.find("investmentDiscretion") else None,
                
            }
            rows.append(row)

        # Convert to DataFrame
        data_frames = pd.DataFrame(rows)
        print(data_frames.head()) # shows how the data look like in the data frame we created trough BeautifulSoup
        print(data_frames.info())


        data_frames["filling_dates"] = filing_dates.iloc[w] # assign the filling_date to the whole file


        # Making important summary statistics
        additional_data = data_frames.groupby('Company').agg({"Value": "sum", "Shares": "sum"})
        print(additional_data.sort_values("Value", ascending = False))
        print(additional_data.sort_values("Shares", ascending = False))

        final_data_frame = pd.concat([final_data_frame, data_frames], ignore_index=True)
        w = w+1
    full_path = f"{storage}/{name}".replace("//", "/")  # Ensure no double slashes if someone insert the path with backslash at the end
    final_data_frame.to_csv(full_path, index=False)

csv__with_13fdata()