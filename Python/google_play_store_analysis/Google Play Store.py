import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import seaborn as sns

# from Test import total_ratings

# -----------------------------------------------------------
# Main Question: What factors contribute to the success of an Android app on the Google Play Store?
# -----------------------------------------------------------
# What means Success in this context
# 1. More installs = If freemium or free = higher chance someone pays or more add revenue. If Paid = Directly more money
# 2. Rating = If freemium = also higher chance someone pays. If paid with Subscription (longer Subscription) If free = Can only influence success through higher installs
# Success = High Install Count + High User Rating
#


# -----------------------------------------------------------
# Section: Load and clean data
# -----------------------------------------------------------
data_google_play = pd.read_csv("https://raw.githubusercontent.com/schlende/practical-pandas-projects/master/datasets/google-play-store-11-2018.csv")
print("General Information about the Data Frame")
print(data_google_play.head())
print(data_google_play.info())
print(data_google_play.columns)
pd.set_option("display.max_columns", 10)
pd.set_option("display.width", 200)
pd.set_option("display.precision", 2)

print("\nData Cleaning\n")
print(data_google_play[data_google_play["app_id"].duplicated()]) # Duplicated() = method to find out weather there are duplicates
# No duplicates
print(data_google_play.isna().sum().to_frame('missing_values')) # 846 values missing in released (Compared to 62694 Rows small amount)
data_google_play = data_google_play.dropna()
print("\nSample of 'released' column:\n")
data_google_play["released"] = pd.to_datetime(data_google_play["released"])  # Needs to be converted to a date object

# -----------------------------------------------------------
# 📊 SECTION: Install Buckets vs. Rating Quality
# -----------------------------------------------------------
# Understand whether apps with higher install counts are truly better rated, or simply more visible.
print("\nApp Popularity Analysis\n")
# Split them into groups of min_installs
# Investigate the amount of apps in each class
data_google_play['install_group'] = pd.cut(data_google_play['min_installs'],
    bins=[0, 100000, 1000000, float('inf')],
    labels=['0-100k', '100k–1M', '>1M'])
a = data_google_play['install_group'].value_counts(normalize = True)
print(f"Amount of Apps in each {a}:")
# Around 8% of app over 1 million, 19% = 100k–1M and 73% = 0-100k

# Next: Look if the satisfaction(star) distribution is different among these groups
print("\nProportion of different Star Ratings in each install_group")
number_ratings_score = data_google_play.groupby("install_group")[
    ['rating_one_star', 'rating_two_star','rating_three_star','rating_four_star', 'rating_five_star']].sum()
total_ratings = number_ratings_score.sum(axis = 1)
number_ratings_score_prop = number_ratings_score.div(total_ratings, axis = 0)
number_ratings_score_prop.columns = [
    'prop_one_star', 'prop_two_star', 'prop_three_star', 'prop_four_star', 'prop_five_star'
]
print(number_ratings_score_prop)
# The App rating distribution is nearly exactly the same across different Popularity level(measured by install brackets)
# Therefore the mean score should also be the same
Star = [1,2,3,4,5]
Average_First = (number_ratings_score_prop.loc["0-100k", :]*Star).sum()
Average_Second = (number_ratings_score_prop.loc["100k–1M", :]*Star).sum()
Average_Third = (number_ratings_score_prop.loc[">1M", :]*Star).sum()
print("\nAverage Ratings across install groups\n")
print(f"Average Rating 0-100k : {Average_First:.2f}")
print(f"Average Rating 100k–1M: {Average_Second:.2f}")
print(f"Average Rating >1M: {Average_Third:.2f}")
# Conclusion: Popular apps (measured by install brackets) are not rated more positively than less popular ones


# Maby Amount of Ratings has an influence
number_ratings_score = number_ratings_score.reset_index()
print(number_ratings_score)
number_ratings_score_long = pd.melt(number_ratings_score,
    id_vars = 'install_group',
    value_vars = ['rating_one_star', 'rating_two_star',
       'rating_three_star', 'rating_four_star', 'rating_five_star'],
    var_name = "star_name",
    value_name = "rating_count"
)
print(number_ratings_score_long)

number_ratings_score_long["star_name"] = number_ratings_score_long["star_name"].map({
    "rating_one_star": "1★",
    "rating_two_star": "2★",
    "rating_three_star": "3★",
    "rating_four_star": "4★",
    "rating_five_star": "5★"
})

plt.figure(figsize=(12, 6))
sns.barplot(data = number_ratings_score_long, x = "star_name", y = "rating_count", hue = "install_group")
plt.yscale('log')
plt.ylabel("Rating Count (log scale)")
plt.title("Rating Count by Star Name (Log Scale)")
plt.show()
# While rating quality stayed flat, the volume of reviews increased massively with install count.
# Of course here due log scale the difference dimension not so obvious but we can see on the left side the 10 potency difference indicate the magnitude
# So amount of reviews (Popularity) seem to be a very significant factor here.
# Nevertheless it isn't sure whether just the high install amounts are the reason for the high reviews and not the other way around
# Can't use correlation as indication here as min_install is highly discrete
# However since the min installs and reviews increase together it seem the apps are simply more visible to get higher installs.




# -----------------------------------------------------------
# 📊 SECTION: App Popularity Analysis by Genre
# -----------------------------------------------------------
# "Certain genres are inherently more successful than others."
print("\nApp Popularity Analysis by Genre\n")

install_levels_genre = data_google_play.groupby("genre")["min_installs"].sum().sort_values(ascending = False)
print(install_levels_genre) # So the 3 most downloaded genres are (Tools, Communication, Productivity)
top_10installs = install_levels_genre.head(10)
top_10apps = data_google_play.value_counts("genre").sort_values(ascending = False).head(10)
top_10scores = data_google_play.groupby("genre")["score"].mean().sort_values(ascending = False).head(10)


# All Categories
top10_installs_genres = set(top_10installs.index)
top10_scores_genres = set(top_10scores.index)
top10_apps_genres = set(top_10apps.index)

highlight_genres = (top10_installs_genres & top10_scores_genres) | \
                   (top10_installs_genres & top10_apps_genres) | \
                   (top10_scores_genres & top10_apps_genres)



fig, axes = plt.subplots(3, 1, figsize=(20, 12))
# Plot 1: Top 10 Genres by Min Installs
colors1 = ['red' if genre in highlight_genres else 'blue' for genre in top_10installs.index]
sns.barplot(
    x=top_10installs.index,
    y=top_10installs.values,
    ax=axes[0],
    palette=colors1
)
axes[0].set_ylabel("Installs in Billions")
axes[0].set_title("Top 10 Genres by Min Installs")
axes[0].set_xlabel('')
# Plot 2: Top 10 Genres by Average Score
colors2 = ['red' if genre in highlight_genres else 'blue' for genre in top_10scores.index]
sns.barplot(
    x=top_10scores.index,
    y=top_10scores.values,
    ax=axes[1],
    palette=colors2

)
axes[1].set_ylabel("Score (1-5)")
axes[1].set_title("Top 10 Genres by Average Score")
axes[1].set_xlabel('')

# Plot 3: Top 10 Genres by Number of Apps
colors3 = ['red' if genre in highlight_genres else 'blue' for genre in top_10apps.index]
sns.barplot(
    x=top_10apps.index,
    y=top_10apps.values,
    ax=axes[2],
    palette=colors3
)
axes[2].set_title("Number of Apps")
axes[2].set_title("Top 10 Genres by Number of Apps")
axes[2].set_xlabel('')

plt.tight_layout()
plt.show()

# High min install unequal to  High Number of Apps and also both unequal good rating across different genres
# Indicating that there a few apps have here a big portion of the overall market
# Maby here looking for these highest apps and compare their proportion to that of the highest 3 categories
# Also casual only 3 in the top 100 despite being the 4 largest genre also look here.



mean_score = genre_stats["average_score"].mean()
median_installs = genre_stats["min_installs"].median()

underrated = genre_stats[(genre_stats["average_score"] > mean_score) & (genre_stats["min_installs"] < median_installs)]



plt.figure(figsize=(12, 6))
sns.scatterplot(data=genre_stats, x="min_installs", y="average_score", size="number_of_apps", hue="average_score", legend=False,)
plt.title("Average Rating vs. Total Installs per Genre")
plt.xlabel("Total Installs")
plt.ylabel("Average Rating")
plt.xscale("log")
plt.axhline(mean_score, color='gray', linestyle='--', label = "Mean Score")
plt.axvline(median_installs, color='gray', linestyle='--', label = "Median Installs")

for genre, row in underrated.iterrows():
    plt.text(row["min_installs"], row["average_score"], genre, fontsize=5)

plt.title("Underrated Genres: High Score, Low Installs")
plt.xlabel("Total Installs (log scale)")
plt.ylabel("Average Score")
plt.legend()
plt.tight_layout()
plt.grid(True)
plt.show()

# -----------------------------------------------------------
# 📊 SECTION: App Popularity Analysis by Genre
# -----------------------------------------------------------
revenue_data = data_google_play[[ 'min_installs', 'offers_iap', 'ad_supported', 'price', 'score']].copy()
revenue_data["min_revenue"] = revenue_data["min_installs"]* revenue_data["price"]
print(revenue_data.sort_values("min_revenue", ascending = False)
print(revenue_data.info())




# Jupyter notebook findings
# usefully to have ordered categorial data so we can simply filter them like numeric values
# filtered_df = ds_jobs_transformed[
#     (ds_jobs_transformed['experience'] >= '10') &
#     (ds_jobs_transformed['company_size'] >= '1000-4999')
# ]
# print(ds_jobs_transformed['relevant_experience'].unique()) = Array with all unqiue values displayed