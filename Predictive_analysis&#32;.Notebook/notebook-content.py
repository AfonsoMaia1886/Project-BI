# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "jupyter",
# META     "jupyter_kernel_name": "python3.12"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "b90961d6-ba06-4fde-834e-3b465d913510",
# META       "default_lakehouse_name": "LH_Pharma4All",
# META       "default_lakehouse_workspace_id": "b7626cf0-cc95-4e17-9611-abea9e945cb8",
# META       "known_lakehouses": [
# META         {
# META           "id": "b90961d6-ba06-4fde-834e-3b465d913510"
# META         }
# META       ]
# META     }
# META   }
# META }

# MARKDOWN ********************

# # Pharma4All — Pharmacy Segmentation Notebook
# 
# This notebook implements a complementary advanced analytics step for the Pharma4All BI project.
# 
# **Objective:** create a new Warehouse-ready analytical table, `dwh.PharmacySegmentation`, by segmenting pharmacies according to historical sales behaviour.
# 
# **Method:** K-Means clustering using pharmacy-level features derived from sales, product, pharmacy and location data.
# 
# **Output:**  
# - `PharmacySegmentation.csv`  
# - SQL scripts to create and load `dwh.PharmacySegmentation`  
# - PCA cluster visualization for interpretation and reporting

# MARKDOWN ********************

# ## 0. Conceptual checklist
# 
# - Read the source files from the Lakehouse `Files` area using standard Python.
# - Apply analytical preprocessing aligned with the dataflow cleaning logic.
# - Correct location district information using `cod_post_map_clean.csv`.
# - Build pharmacy-level behavioural features.
# - Standardize the features and apply K-Means clustering.
# - Interpret the clusters as commercial pharmacy segments.
# - Export a Warehouse-ready table and a PCA visualization.

# CELL ********************

# Configuration

from pathlib import Path

POSSIBLE_DATA_DIRS = [
    "/lakehouse/default/Files",
    "/lakehouse/default/Files/raw",
    "/mnt/data",
    "."
]

SALES_FILE = "Sales (Pharmacy).csv"
PRODUCTS_FILE = "Products.csv"
PHARMACIES_A_FILE = "Pharmacies A.csv"
PHARMACIES_B_FILE = "Pharmacies B.csv"
LOCATIONS_FILE = "Locations.csv"
COD_POST_MAP_FILE = "cod_post_map_clean.csv"

TARGET_SCHEMA = "dwh"
TARGET_TABLE = "PharmacySegmentation"

N_CLUSTERS = 3
RANDOM_STATE = 42

OUTPUT_SUBDIR = "advanced_analytics"

# Manual fallback for location names that are not uniquely resolved by the postal-code mapping.
# Keep these values aligned with the district correction logic used in the dataflows.
MANUAL_DISTRICT_OVERRIDES = {
    "freguesia de sao pedro do sul": "Viseu",
    "malveira da serra": "Lisboa",
    "sao joao de madeira": "Aveiro",
    "vimeiro": "Lisboa"
}

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# CELL ********************

# Standard Python imports

import csv
import math
import unicodedata
from datetime import datetime
from decimal import Decimal, ROUND_HALF_UP

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from IPython.display import display

from sklearn.cluster import KMeans
from sklearn.decomposition import PCA
from sklearn.metrics import silhouette_score
from sklearn.preprocessing import StandardScaler

pd.set_option("display.max_columns", 200)
pd.set_option("display.width", 180)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# CELL ********************

# Helper functions

def normalize_text(value):
    # Normalize text for robust joins: lower case, trimmed, without accents.
    if pd.isna(value):
        return np.nan
    text = str(value).strip().lower()
    text = unicodedata.normalize("NFKD", text)
    text = "".join(char for char in text if not unicodedata.combining(char))
    text = " ".join(text.split())
    return text


def read_csv_smart(path, **kwargs):
    # Read CSV with common encodings used in Portuguese source files.
    encodings = ["utf-8-sig", "utf-8", "cp1252", "latin1", "ISO-8859-1"]
    last_error = None

    for encoding in encodings:
        try:
            return pd.read_csv(path, encoding=encoding, **kwargs)
        except UnicodeDecodeError as error:
            last_error = error

    raise UnicodeDecodeError(
        "encoding",
        b"",
        0,
        1,
        f"Could not read {path} with the supported encodings. Last error: {last_error}"
    )


def find_file(base_dirs, file_name):
    # Find file by exact name or by name without extension.
    normalized_target = normalize_text(Path(file_name).stem)

    for folder in base_dirs:
        folder_path = Path(folder)
        if not folder_path.exists():
            continue

        exact_candidate = folder_path / file_name
        if exact_candidate.exists():
            return exact_candidate

        for candidate in folder_path.rglob("*"):
            if candidate.is_file():
                normalized_name = normalize_text(candidate.stem)
                if normalized_name == normalized_target:
                    return candidate

    raise FileNotFoundError(
        f"Could not find '{file_name}'. Check whether the Lakehouse is attached and whether the file exists in Files."
    )


def clean_cnp(value):
    # Convert product CNP values to stable string keys.
    if pd.isna(value):
        return np.nan

    text = str(value).strip()
    if text.endswith(".0"):
        text = text[:-2]

    try:
        numeric_value = float(text)
        if numeric_value.is_integer():
            return str(int(numeric_value))
    except ValueError:
        pass

    return text


def clean_numeric(series):
    # Convert numeric columns robustly, accepting commas as decimal separators.
    return pd.to_numeric(
        series.astype(str).str.replace(",", ".", regex=False).str.strip(),
        errors="coerce"
    )


def clean_integer_key(series):
    # Convert ID-like columns to stable string keys.
    numeric = pd.to_numeric(series, errors="coerce")
    return numeric.astype("Int64").astype(str).replace("<NA>", np.nan)


def sql_escape(value):
    # Escape values for SQL INSERT statements.
    if pd.isna(value):
        return "NULL"

    if isinstance(value, (np.integer, int)):
        return str(int(value))

    if isinstance(value, (np.floating, float)):
        if math.isnan(float(value)):
            return "NULL"
        return str(float(value))

    if isinstance(value, pd.Timestamp):
        return "'" + value.strftime("%Y-%m-%d") + "'"

    text = str(value).replace("'", "''")
    return f"'{text}'"


def decimal_or_null(value, ndigits=4):
    # Format decimal values for SQL insertion.
    if pd.isna(value):
        return "NULL"
    quant = Decimal("1." + "0" * ndigits)
    return str(Decimal(str(float(value))).quantize(quant, rounding=ROUND_HALF_UP))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# CELL ********************

# Resolve input and output paths

resolved_paths = {
    "sales": find_file(POSSIBLE_DATA_DIRS, SALES_FILE),
    "products": find_file(POSSIBLE_DATA_DIRS, PRODUCTS_FILE),
    "pharmacies_a": find_file(POSSIBLE_DATA_DIRS, PHARMACIES_A_FILE),
    "pharmacies_b": find_file(POSSIBLE_DATA_DIRS, PHARMACIES_B_FILE),
    "locations": find_file(POSSIBLE_DATA_DIRS, LOCATIONS_FILE),
    "cod_post_map": find_file(POSSIBLE_DATA_DIRS, COD_POST_MAP_FILE),
}

DATA_DIR = resolved_paths["sales"].parent

if Path("/lakehouse/default/Files").exists():
    OUTPUT_DIR = Path("/lakehouse/default/Files") / OUTPUT_SUBDIR
else:
    OUTPUT_DIR = Path("/mnt/data") / OUTPUT_SUBDIR

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

print("Input files resolved:")
for name, path in resolved_paths.items():
    print(f"- {name}: {path}")

print(f"\nOutput directory: {OUTPUT_DIR}")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# MARKDOWN ********************

# ## 1. Load source data
# 
# The source files are loaded with standard Python and converted into pandas DataFrames.  
# Some files are treated as headerless because the source structure contains values in the first row instead of column names.

# CELL ********************

# Load source data

sales_raw = read_csv_smart(resolved_paths["sales"])
products_raw = read_csv_smart(resolved_paths["products"], header=None)
pharmacies_a_raw = read_csv_smart(resolved_paths["pharmacies_a"])
pharmacies_b_raw = read_csv_smart(resolved_paths["pharmacies_b"])
locations_raw = read_csv_smart(resolved_paths["locations"], header=None)
cod_post_map_raw = read_csv_smart(resolved_paths["cod_post_map"])

print("Source shapes:")
print("sales_raw:", sales_raw.shape)
print("products_raw:", products_raw.shape)
print("pharmacies_a_raw:", pharmacies_a_raw.shape)
print("pharmacies_b_raw:", pharmacies_b_raw.shape)
print("locations_raw:", locations_raw.shape)
print("cod_post_map_raw:", cod_post_map_raw.shape)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# CELL ********************

# Standardize source column names

products = products_raw.iloc[:, :6].copy()
products.columns = [
    "CNP",
    "ProductName",
    "Manufacturer",
    "Brand",
    "ProductPresentation",
    "Generic"
]

locations = locations_raw.iloc[:, :4].copy()
locations.columns = [
    "LocationCode",
    "LocationName",
    "DistrictOriginal",
    "Country"
]

pharmacies_a = pharmacies_a_raw.rename(columns={
    "Pharmacy ID": "PharmacyID",
    "Nome da farmácia": "PharmacyName",
    "Localização": "LocationCode"
})

pharmacies_b = pharmacies_b_raw.rename(columns={
    "Pharmacy ID": "PharmacyID",
    "Nome da farmácia": "PharmacyName",
    "Localização": "LocationCode"
})

sales = sales_raw.rename(columns={
    "Sale ID": "SaleID",
    "Localização": "SalesLocationCode",
    "Pharmacy": "PharmacyID",
    "operator_id": "OperatorID"
})

display(sales.head())
display(products.head())
display(locations.head())

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# MARKDOWN ********************

# ## 2. Data quality alignment and district correction
# 
# This step applies the same consistency principle used in the ETL dataflows: source keys are standardized, numeric/date fields are typed, duplicate dimension rows are removed, and location districts are corrected using the postal-code mapping file.

# CELL ********************

# District correction using cod_post_map_clean.csv

cod_post_map = cod_post_map_raw.copy()
cod_post_map.columns = [str(col).strip() for col in cod_post_map.columns]

required_map_cols = {"Distrito", "Concelho"}
missing_map_cols = required_map_cols - set(cod_post_map.columns)
if missing_map_cols:
    raise ValueError(f"cod_post_map_clean.csv is missing required columns: {missing_map_cols}")

locations["LocationCode"] = clean_integer_key(locations["LocationCode"])
locations["LocationName"] = locations["LocationName"].astype(str).str.strip()
locations["Country"] = locations["Country"].fillna("Portugal").astype(str).str.strip()
locations["LocationNameKey"] = locations["LocationName"].map(normalize_text)
locations["DistrictCorrected"] = pd.NA
locations["DistrictCorrectionSource"] = pd.NA

mapping_priority = [
    ("Concelho", "municipality_mapping"),
    ("Freguesia", "parish_mapping"),
    ("Freguesia Final (Pós RATF)", "final_parish_mapping")
]

for source_column, source_label in mapping_priority:
    if source_column not in cod_post_map.columns:
        continue

    lookup_source = cod_post_map[[source_column, "Distrito"]].dropna().copy()
    lookup_source["LocationNameKey"] = lookup_source[source_column].map(normalize_text)

    district_counts = lookup_source.groupby("LocationNameKey")["Distrito"].nunique()
    unique_keys = district_counts[district_counts == 1].index

    lookup = (
        lookup_source[lookup_source["LocationNameKey"].isin(unique_keys)]
        .drop_duplicates(subset=["LocationNameKey"])
        .set_index("LocationNameKey")["Distrito"]
    )

    unresolved_mask = locations["DistrictCorrected"].isna()
    mapped_values = locations.loc[unresolved_mask, "LocationNameKey"].map(lookup)

    fill_mask = unresolved_mask & mapped_values.notna()
    locations.loc[fill_mask, "DistrictCorrected"] = mapped_values[fill_mask]
    locations.loc[fill_mask, "DistrictCorrectionSource"] = source_label

manual_override_series = locations["LocationNameKey"].map(MANUAL_DISTRICT_OVERRIDES)
manual_mask = locations["DistrictCorrected"].isna() & manual_override_series.notna()

locations.loc[manual_mask, "DistrictCorrected"] = manual_override_series[manual_mask]
locations.loc[manual_mask, "DistrictCorrectionSource"] = "manual_override"

locations["District"] = locations["DistrictCorrected"].combine_first(locations["DistrictOriginal"])
locations["District"] = locations["District"].fillna("Unknown").astype(str).str.strip()
fallback_source = pd.Series(
    np.where(locations["DistrictOriginal"].notna(), "original_locations", "unknown"),
    index=locations.index
)

locations["DistrictCorrectionSource"] = locations["DistrictCorrectionSource"].where(
    locations["DistrictCorrectionSource"].notna(),
    fallback_source
)

district_correction_summary = pd.DataFrame({
    "Metric": [
        "Locations in source",
        "Locations corrected from municipality mapping",
        "Locations corrected from parish mapping",
        "Locations corrected from final parish mapping",
        "Locations corrected from manual override",
        "Locations using original district",
        "Locations still unknown"
    ],
    "Value": [
        len(locations),
        int((locations["DistrictCorrectionSource"] == "municipality_mapping").sum()),
        int((locations["DistrictCorrectionSource"] == "parish_mapping").sum()),
        int((locations["DistrictCorrectionSource"] == "final_parish_mapping").sum()),
        int((locations["DistrictCorrectionSource"] == "manual_override").sum()),
        int((locations["DistrictCorrectionSource"] == "original_locations").sum()),
        int((locations["District"] == "Unknown").sum())
    ]
})

display(district_correction_summary)
display(locations[["LocationCode", "LocationName", "District", "Country", "DistrictCorrectionSource"]].head(10))

if (locations["District"] == "Unknown").any():
    display(locations.loc[locations["District"] == "Unknown", ["LocationCode", "LocationName"]])
    raise ValueError("Some locations still have unknown district. Update MANUAL_DISTRICT_OVERRIDES in the configuration cell.")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# CELL ********************

# Standardize dimensions

products["CNP"] = products["CNP"].map(clean_cnp)
products["ProductName"] = products["ProductName"].astype(str).str.strip()
products["Manufacturer"] = products["Manufacturer"].astype(str).str.strip()
products["Brand"] = products["Brand"].astype(str).str.strip()
products["ProductPresentation"] = products["ProductPresentation"].astype(str).str.strip()
products["Generic"] = products["Generic"].astype(str).str.strip().str.upper()

products["IsGeneric"] = products["Generic"].isin(["Y", "YES", "1", "TRUE", "GENERIC"])
products["ProductType"] = np.where(products["IsGeneric"], "Generic", "Branded")

products = (
    products
    .dropna(subset=["CNP"])
    .drop_duplicates(subset=["CNP"], keep="first")
)

pharmacies = pd.concat([pharmacies_a, pharmacies_b], ignore_index=True)
pharmacies["PharmacyID"] = clean_integer_key(pharmacies["PharmacyID"])
pharmacies["LocationCode"] = clean_integer_key(pharmacies["LocationCode"])
pharmacies["PharmacyName"] = pharmacies["PharmacyName"].astype(str).str.strip()

pharmacies = (
    pharmacies
    .dropna(subset=["PharmacyID"])
    .drop_duplicates(subset=["PharmacyID"], keep="first")
    .merge(
        locations[["LocationCode", "LocationName", "District", "Country"]],
        on="LocationCode",
        how="left"
    )
)

display(products.head())
display(pharmacies.head())

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# CELL ********************

# Standardize sales fact-like source records

sales["SaleID"] = clean_integer_key(sales["SaleID"])
sales["PharmacyID"] = clean_integer_key(sales["PharmacyID"])
sales["SalesLocationCode"] = clean_integer_key(sales["SalesLocationCode"])
sales["POS"] = clean_integer_key(sales["POS"])
sales["OperatorID"] = clean_integer_key(sales["OperatorID"])
sales["CNP"] = sales["CNP"].map(clean_cnp)

sales["Qty"] = clean_numeric(sales["Qty"])
sales["Amount"] = clean_numeric(sales["Amount"])
sales["Datetime"] = pd.to_datetime(sales["Datetime"], errors="coerce", dayfirst=True)
sales["SaleDate"] = sales["Datetime"].dt.date
sales["SaleYearMonth"] = sales["Datetime"].dt.to_period("M").astype(str)

initial_rows = len(sales)

sales = sales[
    sales["SaleID"].notna()
    & sales["PharmacyID"].notna()
    & sales["CNP"].notna()
    & sales["Datetime"].notna()
    & sales["Qty"].notna()
    & sales["Amount"].notna()
    & (sales["Qty"] > 0)
    & (sales["Amount"] >= 0)
].copy()

quality_summary = pd.DataFrame({
    "Metric": [
        "Initial sales rows",
        "Valid rows after analytical preprocessing",
        "Removed rows",
        "Distinct pharmacies in sales",
        "Distinct products in sales"
    ],
    "Value": [
        initial_rows,
        len(sales),
        initial_rows - len(sales),
        sales["PharmacyID"].nunique(),
        sales["CNP"].nunique()
    ]
})

display(quality_summary)
display(sales.head())

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# MARKDOWN ********************

# ## 3. Enrich sales transactions
# 
# Sales are enriched with product, pharmacy and location attributes.  
# This enriched dataset is not a replacement for the dimensional model. It is only the analytical input needed to compute pharmacy-level features for clustering.

# CELL ********************

# Enrich sales transactions with product and pharmacy attributes

sales_enriched = (
    sales
    .merge(
        products[["CNP", "ProductName", "Manufacturer", "Brand", "ProductPresentation", "IsGeneric", "ProductType"]],
        on="CNP",
        how="left"
    )
    .merge(
        pharmacies[["PharmacyID", "PharmacyName", "LocationCode", "LocationName", "District", "Country"]],
        on="PharmacyID",
        how="left"
    )
)

sales_enriched["IsGeneric"] = sales_enriched["IsGeneric"].fillna(False)
sales_enriched["ProductType"] = sales_enriched["ProductType"].fillna("Unknown")
sales_enriched["PharmacyName"] = sales_enriched["PharmacyName"].fillna("Unknown pharmacy")
sales_enriched["LocationName"] = sales_enriched["LocationName"].fillna("Unknown location")
sales_enriched["District"] = sales_enriched["District"].fillna("Unknown")
sales_enriched["Country"] = sales_enriched["Country"].fillna("Portugal")

join_validation = pd.DataFrame({
    "Metric": [
        "Sales rows after enrichment",
        "Rows without product match",
        "Rows without pharmacy match",
        "Rows with unknown district"
    ],
    "Value": [
        len(sales_enriched),
        int(sales_enriched["ProductName"].isna().sum()),
        int((sales_enriched["PharmacyName"] == "Unknown pharmacy").sum()),
        int((sales_enriched["District"] == "Unknown").sum())
    ]
})

display(join_validation)
display(sales_enriched.head())

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# MARKDOWN ********************

# ## 4. Feature engineering at pharmacy level
# 
# Each row in the modelling dataset represents one pharmacy.  
# The features describe commercial behaviour: sales volume, transaction activity, product variety, branded/generic mix and recency.

# CELL ********************

# Create pharmacy-level analytical features

reference_date = sales_enriched["Datetime"].max().normalize()

sales_enriched["BrandedAmount"] = np.where(~sales_enriched["IsGeneric"], sales_enriched["Amount"], 0.0)
sales_enriched["GenericAmount"] = np.where(sales_enriched["IsGeneric"], sales_enriched["Amount"], 0.0)

pharmacy_features = (
    sales_enriched
    .groupby("PharmacyID", as_index=False)
    .agg(
        PharmacyName=("PharmacyName", "first"),
        LocationCode=("LocationCode", "first"),
        LocationName=("LocationName", "first"),
        District=("District", "first"),
        Country=("Country", "first"),
        TotalSalesAmount=("Amount", "sum"),
        TotalQuantity=("Qty", "sum"),
        NumberOfTransactions=("SaleID", "nunique"),
        ProductVariety=("CNP", "nunique"),
        ManufacturerVariety=("Manufacturer", "nunique"),
        BrandVariety=("Brand", "nunique"),
        BrandedSalesAmount=("BrandedAmount", "sum"),
        GenericSalesAmount=("GenericAmount", "sum"),
        ActiveMonths=("SaleYearMonth", "nunique"),
        FirstSaleDate=("Datetime", "min"),
        LastSaleDate=("Datetime", "max")
    )
)

pharmacy_features["AvgTransactionAmount"] = (
    pharmacy_features["TotalSalesAmount"] / pharmacy_features["NumberOfTransactions"]
).replace([np.inf, -np.inf], np.nan)

pharmacy_features["MonthlySalesIntensity"] = (
    pharmacy_features["TotalSalesAmount"] / pharmacy_features["ActiveMonths"]
).replace([np.inf, -np.inf], np.nan)

pharmacy_features["BrandedSalesShare"] = (
    pharmacy_features["BrandedSalesAmount"] / pharmacy_features["TotalSalesAmount"]
).replace([np.inf, -np.inf], np.nan).fillna(0)

pharmacy_features["GenericSalesShare"] = (
    pharmacy_features["GenericSalesAmount"] / pharmacy_features["TotalSalesAmount"]
).replace([np.inf, -np.inf], np.nan).fillna(0)

pharmacy_features["RecencyDays"] = (
    reference_date - pharmacy_features["LastSaleDate"].dt.normalize()
).dt.days

feature_numeric_columns = [
    "TotalSalesAmount",
    "TotalQuantity",
    "NumberOfTransactions",
    "AvgTransactionAmount",
    "ProductVariety",
    "ManufacturerVariety",
    "BrandVariety",
    "MonthlySalesIntensity",
    "BrandedSalesShare",
    "GenericSalesShare",
    "RecencyDays"
]

pharmacy_features[feature_numeric_columns] = pharmacy_features[feature_numeric_columns].fillna(0)

display(pharmacy_features.head())
display(pharmacy_features[feature_numeric_columns].describe().T)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# MARKDOWN ********************

# ## 5. K-Means clustering
# 
# The selected features are standardized before modelling so that variables measured in different units contribute on a comparable scale.  
# K-Means is used to group pharmacies into behavioural segments.

# CELL ********************

# Fit K-Means clustering

if len(pharmacy_features) < N_CLUSTERS:
    raise ValueError(
        f"N_CLUSTERS={N_CLUSTERS} is larger than the number of pharmacies available: {len(pharmacy_features)}."
    )

X = pharmacy_features[feature_numeric_columns].copy()

scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

kmeans = KMeans(
    n_clusters=N_CLUSTERS,
    random_state=RANDOM_STATE,
    n_init=20
)

pharmacy_features["ClusterID"] = kmeans.fit_predict(X_scaled)

if len(pharmacy_features) > N_CLUSTERS:
    sil_score = silhouette_score(X_scaled, pharmacy_features["ClusterID"])
else:
    sil_score = np.nan

model_summary = pd.DataFrame({
    "Metric": [
        "Algorithm",
        "Number of clusters",
        "Number of pharmacies",
        "Number of model features",
        "Silhouette score"
    ],
    "Value": [
        "K-Means",
        N_CLUSTERS,
        len(pharmacy_features),
        len(feature_numeric_columns),
        round(float(sil_score), 4) if not pd.isna(sil_score) else "Not available"
    ]
})

display(model_summary)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# CELL ********************

# Interpret clusters and assign business labels

cluster_profile = (
    pharmacy_features
    .groupby("ClusterID")
    .agg(
        NumberOfPharmacies=("PharmacyID", "count"),
        AvgTotalSalesAmount=("TotalSalesAmount", "mean"),
        AvgTotalQuantity=("TotalQuantity", "mean"),
        AvgNumberOfTransactions=("NumberOfTransactions", "mean"),
        AvgTransactionAmount=("AvgTransactionAmount", "mean"),
        AvgMonthlySalesIntensity=("MonthlySalesIntensity", "mean"),
        AvgProductVariety=("ProductVariety", "mean"),
        AvgBrandedSalesShare=("BrandedSalesShare", "mean"),
        AvgGenericSalesShare=("GenericSalesShare", "mean"),
        AvgRecencyDays=("RecencyDays", "mean")
    )
    .reset_index()
)

ranking_features = [
    "AvgTotalSalesAmount",
    "AvgNumberOfTransactions",
    "AvgMonthlySalesIntensity",
    "AvgProductVariety"
]

ranking_standardized = StandardScaler().fit_transform(cluster_profile[ranking_features])
cluster_profile["CommercialScore"] = ranking_standardized.mean(axis=1)

cluster_profile = cluster_profile.sort_values("CommercialScore", ascending=False).reset_index(drop=True)
cluster_profile["SegmentRank"] = np.arange(1, len(cluster_profile) + 1)

segment_labels = {
    1: "High-value pharmacies",
    2: "Standard pharmacies",
    3: "Low-value pharmacies"
}

cluster_profile["SegmentLabel"] = cluster_profile["SegmentRank"].map(segment_labels).fillna(
    "Additional segment " + cluster_profile["SegmentRank"].astype(str)
)

cluster_profile["SegmentDescription"] = np.select(
    [
        cluster_profile["SegmentRank"].eq(1),
        cluster_profile["SegmentRank"].eq(2),
        cluster_profile["SegmentRank"].eq(3),
    ],
    [
        "Pharmacies with the strongest sales volume, transaction activity and commercial intensity.",
        "Pharmacies with intermediate commercial behaviour and stable sales activity.",
        "Pharmacies with lower sales intensity or lower transaction activity."
    ],
    default="Additional behavioural pharmacy segment."
)

pharmacy_features = pharmacy_features.merge(
    cluster_profile[["ClusterID", "SegmentRank", "SegmentLabel", "SegmentDescription"]],
    on="ClusterID",
    how="left"
)

display(cluster_profile)
display(pharmacy_features[["PharmacyID", "PharmacyName", "District", "ClusterID", "SegmentLabel"]].head(10))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# MARKDOWN ********************

# ## 6. PCA visualization of clusters
# 
# PCA is used only for visualization.  
# The clustering model is fitted on the full standardized feature set, while PCA projects those features into two dimensions to make the segments easier to inspect and explain.

# CELL ********************

# PCA projection for visual interpretation

pca = PCA(n_components=2, random_state=RANDOM_STATE)
pca_coordinates = pca.fit_transform(X_scaled)

pharmacy_features["PCA1"] = pca_coordinates[:, 0]
pharmacy_features["PCA2"] = pca_coordinates[:, 1]

pca_summary = pd.DataFrame({
    "Component": ["PCA1", "PCA2", "Total"],
    "ExplainedVarianceRatio": [
        pca.explained_variance_ratio_[0],
        pca.explained_variance_ratio_[1],
        pca.explained_variance_ratio_.sum()
    ]
})

display(pca_summary)

fig, ax = plt.subplots(figsize=(9, 6))

for segment_label, segment_data in pharmacy_features.sort_values("SegmentRank").groupby("SegmentLabel"):
    ax.scatter(
        segment_data["PCA1"],
        segment_data["PCA2"],
        s=80,
        alpha=0.8,
        label=segment_label
    )

ax.axhline(0, linewidth=0.8, alpha=0.4)
ax.axvline(0, linewidth=0.8, alpha=0.4)
ax.set_title("Pharmacy clusters projected with PCA")
ax.set_xlabel(f"PCA1 ({pca.explained_variance_ratio_[0]:.1%} explained variance)")
ax.set_ylabel(f"PCA2 ({pca.explained_variance_ratio_[1]:.1%} explained variance)")
ax.legend(title="Segment")
ax.grid(True, alpha=0.3)

pca_plot_path = OUTPUT_DIR / "PharmacySegmentation_PCA.png"
fig.tight_layout()
fig.savefig(pca_plot_path, dpi=160, bbox_inches="tight")
plt.show()

print(f"PCA visualization saved to: {pca_plot_path}")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# MARKDOWN ********************

# ## 7. Final Warehouse-ready output
# 
# The final table contains one row per pharmacy.  
# It includes the model output (`ClusterID`, `SegmentLabel`, `SegmentDescription`) and the supporting indicators needed for Power BI interpretation.

# CELL ********************

# Build final output table

model_run_timestamp = pd.Timestamp.now().floor("s")

final_columns = [
    "PharmacyID",
    "PharmacyName",
    "LocationCode",
    "LocationName",
    "District",
    "Country",
    "TotalSalesAmount",
    "TotalQuantity",
    "NumberOfTransactions",
    "AvgTransactionAmount",
    "ProductVariety",
    "ManufacturerVariety",
    "BrandVariety",
    "MonthlySalesIntensity",
    "BrandedSalesAmount",
    "GenericSalesAmount",
    "BrandedSalesShare",
    "GenericSalesShare",
    "ActiveMonths",
    "RecencyDays",
    "FirstSaleDate",
    "LastSaleDate",
    "ClusterID",
    "SegmentRank",
    "SegmentLabel",
    "SegmentDescription",
    "PCA1",
    "PCA2"
]

pharmacy_segmentation = pharmacy_features[final_columns].copy()

pharmacy_segmentation["FirstSaleDate"] = pd.to_datetime(pharmacy_segmentation["FirstSaleDate"]).dt.date
pharmacy_segmentation["LastSaleDate"] = pd.to_datetime(pharmacy_segmentation["LastSaleDate"]).dt.date
pharmacy_segmentation["ModelRunTimestamp"] = model_run_timestamp

pharmacy_segmentation = pharmacy_segmentation.sort_values(
    ["SegmentRank", "TotalSalesAmount"],
    ascending=[True, False]
).reset_index(drop=True)

display(pharmacy_segmentation.head(20))
print("Final output shape:", pharmacy_segmentation.shape)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# CELL ********************

cluster_summary = (
    pharmacy_segmentation
    .groupby("SegmentLabel")
    .agg(
        NumberOfPharmacies=("PharmacyID", "nunique"),
        AvgSalesAmount=("TotalSalesAmount", "mean"),
        AvgQuantity=("TotalQuantity", "mean"),
        AvgTransactions=("NumberOfTransactions", "mean"),
        AvgTransactionAmount=("AvgTransactionAmount", "mean"),
        AvgProductVariety=("ProductVariety", "mean"),
        AvgBrandedSalesShare=("BrandedSalesShare", "mean"),
        AvgGenericSalesShare=("GenericSalesShare", "mean"),
        AvgRecencyDays=("RecencyDays", "mean")
    )
    .reset_index()
)

cluster_summary

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# CELL ********************

# Save Parquet output

output_parquet_path = OUTPUT_DIR / f"{TARGET_TABLE}.parquet"

# Ensure correct data types before saving to Parquet
integer_columns = [
    "PharmacyID",
    "TotalQuantity",
    "NumberOfTransactions",
    "ProductVariety",
    "RecencyDays",
    "ClusterID",
    "SegmentRank"
]

float_columns = [
    "TotalSalesAmount",
    "AvgTransactionAmount",
    "MonthlySalesIntensity",
    "BrandedSalesShare",
    "GenericSalesShare",
    "PCA1",
    "PCA2"
]

text_columns = [
    "PharmacyName",
    "LocationName",
    "District",
    "SegmentLabel",
    "SegmentDescription"
]

date_columns = [
    "ModelRunDate"
]

for col in integer_columns:
    if col in pharmacy_segmentation.columns:
        pharmacy_segmentation[col] = pd.to_numeric(
            pharmacy_segmentation[col],
            errors="coerce"
        ).fillna(0).astype("int64")

for col in float_columns:
    if col in pharmacy_segmentation.columns:
        pharmacy_segmentation[col] = pd.to_numeric(
            pharmacy_segmentation[col],
            errors="coerce"
        ).fillna(0).astype("float64")

for col in text_columns:
    if col in pharmacy_segmentation.columns:
        pharmacy_segmentation[col] = pharmacy_segmentation[col].fillna("Unknown").astype(str)

for col in date_columns:
    if col in pharmacy_segmentation.columns:
        pharmacy_segmentation[col] = pd.to_datetime(
            pharmacy_segmentation[col],
            errors="coerce"
        ).dt.date

pharmacy_segmentation.to_parquet(
    output_parquet_path,
    index=False,
    engine="pyarrow"
)

print(f"Parquet output saved to: {output_parquet_path}")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# MARKDOWN ********************

# ## 8. SQL scripts for Warehouse integration
# 
# Run these scripts in the Fabric Warehouse after the notebook finishes:
# 
# 1. `01_create_PharmacySegmentation.sql` creates/replaces the target table.
# 2. `02_load_PharmacySegmentation.sql` loads the model output using standard SQL inserts.
# 3. `03_validate_PharmacySegmentation.sql` checks row counts, segment distribution and matching with `dwh.DimPharmacy`.
# 
# The intended final destination is `dwh.PharmacySegmentation`.

# CELL ********************

# Generate SQL scripts for Warehouse integration

table_full_name = f"{TARGET_SCHEMA}.{TARGET_TABLE}"

create_sql = f"""
IF OBJECT_ID('{table_full_name}', 'U') IS NOT NULL
    DROP TABLE {table_full_name};

CREATE TABLE {table_full_name}
(
    PharmacyID VARCHAR(50) NOT NULL,
    PharmacyName VARCHAR(255) NULL,
    LocationCode VARCHAR(50) NULL,
    LocationName VARCHAR(255) NULL,
    District VARCHAR(255) NULL,
    Country VARCHAR(100) NULL,
    TotalSalesAmount DECIMAL(18,2) NULL,
    TotalQuantity DECIMAL(18,2) NULL,
    NumberOfTransactions INT NULL,
    AvgTransactionAmount DECIMAL(18,2) NULL,
    ProductVariety INT NULL,
    ManufacturerVariety INT NULL,
    BrandVariety INT NULL,
    MonthlySalesIntensity DECIMAL(18,2) NULL,
    BrandedSalesAmount DECIMAL(18,2) NULL,
    GenericSalesAmount DECIMAL(18,2) NULL,
    BrandedSalesShare DECIMAL(10,4) NULL,
    GenericSalesShare DECIMAL(10,4) NULL,
    ActiveMonths INT NULL,
    RecencyDays INT NULL,
    FirstSaleDate DATE NULL,
    LastSaleDate DATE NULL,
    ClusterID INT NULL,
    SegmentRank INT NULL,
    SegmentLabel VARCHAR(100) NULL,
    SegmentDescription VARCHAR(500) NULL,
    PCA1 DECIMAL(18,6) NULL,
    PCA2 DECIMAL(18,6) NULL,
    ModelRunTimestamp DATETIME2(0) NULL
);
""".strip()

insert_columns = [
    "PharmacyID",
    "PharmacyName",
    "LocationCode",
    "LocationName",
    "District",
    "Country",
    "TotalSalesAmount",
    "TotalQuantity",
    "NumberOfTransactions",
    "AvgTransactionAmount",
    "ProductVariety",
    "ManufacturerVariety",
    "BrandVariety",
    "MonthlySalesIntensity",
    "BrandedSalesAmount",
    "GenericSalesAmount",
    "BrandedSalesShare",
    "GenericSalesShare",
    "ActiveMonths",
    "RecencyDays",
    "FirstSaleDate",
    "LastSaleDate",
    "ClusterID",
    "SegmentRank",
    "SegmentLabel",
    "SegmentDescription",
    "PCA1",
    "PCA2",
    "ModelRunTimestamp"
]

value_rows = []

for _, row in pharmacy_segmentation.iterrows():
    formatted_values = []

    for col in insert_columns:
        value = row[col]

        if col in [
            "TotalSalesAmount",
            "TotalQuantity",
            "AvgTransactionAmount",
            "MonthlySalesIntensity",
            "BrandedSalesAmount",
            "GenericSalesAmount"
        ]:
            formatted_values.append(decimal_or_null(value, 2))
        elif col in ["BrandedSalesShare", "GenericSalesShare"]:
            formatted_values.append(decimal_or_null(value, 4))
        elif col in ["PCA1", "PCA2"]:
            formatted_values.append(decimal_or_null(value, 6))
        elif col in [
            "NumberOfTransactions",
            "ProductVariety",
            "ManufacturerVariety",
            "BrandVariety",
            "ActiveMonths",
            "RecencyDays",
            "ClusterID",
            "SegmentRank"
        ]:
            formatted_values.append("NULL" if pd.isna(value) else str(int(value)))
        elif col in ["FirstSaleDate", "LastSaleDate"]:
            formatted_values.append("NULL" if pd.isna(value) else f"'{pd.to_datetime(value).strftime('%Y-%m-%d')}'")
        elif col == "ModelRunTimestamp":
            formatted_values.append(f"'{pd.to_datetime(value).strftime('%Y-%m-%d %H:%M:%S')}'")
        else:
            formatted_values.append(sql_escape(value))

    value_rows.append("(" + ", ".join(formatted_values) + ")")

load_sql = f"""
TRUNCATE TABLE {table_full_name};

INSERT INTO {table_full_name}
(
    {", ".join(insert_columns)}
)
VALUES
{",\n".join(value_rows)};
""".strip()

validation_sql = f"""
SELECT COUNT(*) AS RowsInPharmacySegmentation
FROM {table_full_name};

SELECT SegmentLabel, COUNT(*) AS NumberOfPharmacies
FROM {table_full_name}
GROUP BY SegmentLabel
ORDER BY NumberOfPharmacies DESC;

SELECT COUNT(*) AS MissingPharmacyMatches
FROM {table_full_name} ps
LEFT JOIN dwh.DimPharmacy dp
    ON ps.PharmacyID = CAST(dp.PharmacyID AS VARCHAR(50))
WHERE dp.PharmacyID IS NULL;
""".strip()

create_sql_path = OUTPUT_DIR / "01_create_PharmacySegmentation.sql"
load_sql_path = OUTPUT_DIR / "02_load_PharmacySegmentation.sql"
validation_sql_path = OUTPUT_DIR / "03_validate_PharmacySegmentation.sql"

create_sql_path.write_text(create_sql, encoding="utf-8")
load_sql_path.write_text(load_sql, encoding="utf-8")
validation_sql_path.write_text(validation_sql, encoding="utf-8")

print(f"Create SQL saved to: {create_sql_path}")
print(f"Load SQL saved to: {load_sql_path}")
print(f"Validation SQL saved to: {validation_sql_path}")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# CELL ********************

from pathlib import Path
from IPython.display import display, Markdown

sql_path = Path("/lakehouse/default/Files/advanced_analytics/03_validate_PharmacySegmentation.sql")

sql_text = sql_path.read_text(encoding="utf-8")

display(Markdown(f"```sql\n{sql_text}\n```"))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# MARKDOWN ********************

# ## 9. Output validation inside the notebook
# 
# These checks validate the notebook output before it is loaded into the Warehouse.

# CELL ********************

# Notebook-level validation

validation_results = pd.DataFrame({
    "Check": [
        "One row per pharmacy",
        "No missing PharmacyID",
        "No missing SegmentLabel",
        "No missing or unknown District",
        "All shares between 0 and 1",
        "CSV output exists",
        "PCA plot exists",
        "Create SQL exists",
        "Load SQL exists",
        "Validation SQL exists"
    ],
    "Result": [
        pharmacy_segmentation["PharmacyID"].is_unique,
        pharmacy_segmentation["PharmacyID"].notna().all(),
        pharmacy_segmentation["SegmentLabel"].notna().all(),
        pharmacy_segmentation["District"].notna().all() and not pharmacy_segmentation["District"].eq("Unknown").any(),
        pharmacy_segmentation["BrandedSalesShare"].between(0, 1).all()
        and pharmacy_segmentation["GenericSalesShare"].between(0, 1).all(),
        output_parquet_path.exists(),
        pca_plot_path.exists(),
        create_sql_path.exists(),
        load_sql_path.exists(),
        validation_sql_path.exists()
    ]
})

display(validation_results)

if not validation_results["Result"].all():
    raise ValueError("At least one validation check failed. Review the output before loading it into the Warehouse.")

print("All notebook validation checks passed.")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }

# MARKDOWN ********************

# ## 10. Report-ready interpretation
# 
# The notebook introduces a complementary advanced analytics step within the ETL process, without replacing the dimensional modelling logic implemented through the dataflows. The dataflows prepare and load the official Warehouse tables, while the notebook applies a lighter analytical preprocessing layer, aligned with the same source keys and data consistency principles, to support a machine learning task at pharmacy level.
# 
# Using standard Python, the notebook enriches sales transactions with product, pharmacy and corrected location attributes, and then aggregates the data into pharmacy-level behavioural indicators. These include total sales amount, total quantity sold, number of transactions, average transaction value, product variety, branded and generic sales share, monthly sales intensity and recency. The resulting features are standardized and used as input for a K-Means clustering model, which groups pharmacies into commercial segments such as high-value, standard and low-value pharmacies.
# 
# The output is the new table `dwh.PharmacySegmentation`, containing one row per pharmacy, the cluster assignment, the segment label, supporting metrics and PCA coordinates for visualization. This table can be connected to `dwh.DimPharmacy` through `PharmacyID`, allowing the Power BI report to compare sales performance and branded/generic product behaviour across pharmacy segments.

