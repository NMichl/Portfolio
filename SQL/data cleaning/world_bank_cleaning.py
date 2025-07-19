import pandas as pd
import chardet
import numpy as np

# Check what encoding the file has to read it in
with open(r'C:\Users\Niklas\Desktop\P_Data_Extract_From_International_Debt_Statistics\international_debt.csv', "rb") as f:
    rawdata = f.read(10000)
    result = chardet.detect(rawdata)
    print(result)
# Read it in clean whitespaces, insert NA for '..'
pd.set_option("display.max_columns", 15)
df = pd.read_csv(r'C:\Users\Niklas\Desktop\P_Data_Extract_From_International_Debt_Statistics\international_debt.csv', encoding='ISO-8859-1')
print(df.head(10))
for col in df.select_dtypes(include='object'):
    df[col] = df[col].str.strip()
df.replace('..',   pd.NA , inplace=True)
# Look after different specified missing values
print(df.isna().sum())
print(df.isna())
print(df.tail(5))
# All unnecessary columns therefore drop
df.dropna(inplace = True)
print(df.isna().sum())
# Rename columns
df.columns = [
    "country_name",
    "country_code",
    "counterpart_area_name",
    "counterpart_area_code",
    "series_name",
    "series_code",
    "2019",
    "2020",
    "2021",
    "2022",
    "2023"
]
# Strip out any comma in the files, PostgreSQL has still problems to assessing the right columns with
df["series_name"] = df["series_name"].str.replace(',', '', regex=False)
df["counterpart_area_name"] = df["counterpart_area_name"].str.replace(',', '', regex=False)
df["country_name"] = df["country_name"].str.replace(',', '', regex=False)

# Convert into long format years and values (also helps with the NaN columns directly deletes it)
print(df.dtypes)
id_col = ["country_name","country_code","counterpart_area_name","counterpart_area_code","series_name","series_code"]
values = ["2019","2020","2021","2022", "2023"]
df = df.melt(id_vars = id_col ,value_vars = values, var_name= "year", value_name = "value")
print(df.head())

# Export the file and convert to utf-8
df.to_csv(r'C:\Users\Niklas\Desktop\P_Data_Extract_From_International_Debt_Statistics\international_debt_cleaned.csv', index=False, encoding='utf-8')

