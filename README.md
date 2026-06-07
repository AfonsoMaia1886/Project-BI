# Pharma4All - Data Warehousing & BI Project

End-to-end Data Warehousing and Business Intelligence solution built on **Microsoft Fabric** for Pharma4All, a pharmaceutical company case study. The project covers the full data pipeline — from ingestion and transformation to predictive analytics and reporting.

📄 **[Full report available here](./Report_Pharma4All.pdf)**

---

## Project Structure

| Component | Type | Description |
|---|---|---|
| `LH_Pharma4All` | Lakehouse | Central storage layer for raw and processed data |
| `WH_Pharma4All` | Warehouse | Structured analytical warehouse (star schema) |
| `Df_Load_Dimensions` | Dataflow | Loads dimension tables into the warehouse |
| `DF_02_Load_FactSales` | Dataflow | Loads the FactSales table into the warehouse |
| `DF_Load_FactSales_incremental_batch` | Dataflow | Incremental batch load for FactSales updates |
| `Pipeline_Pharma4All` | Data Pipeline | Orchestrates the full load pipeline |
| `Pipeline_Incremental_Load` | Data Pipeline | Orchestrates the incremental load pipeline |
| `Predictive_analysis` | Notebook | Predictive analysis using Python |
| `SM_Pharma4All` | Semantic Model | Power BI semantic model on top of the warehouse |
| `Report_Pharma4All` | Report | Power BI report with business dashboards |

---

## Architecture Overview

```
Raw Data
   │
   ▼
Lakehouse (LH_Pharma4All)
   │
   ▼
Dataflows (Dimensions + FactSales)
   │
   ▼
Warehouse (WH_Pharma4All) ── Star Schema
   │
   ├──▶ Semantic Model ──▶ Power BI Report
   │
   └──▶ Predictive Analysis Notebook
```

---

## Pipelines

Two orchestration pipelines manage data loading:

- **Full Load** (`Pipeline_Pharma4All`) — loads all dimension and fact tables from scratch.
- **Incremental Load** (`Pipeline_Incremental_Load`) — processes only new or updated records in FactSales, enabling efficient refresh without reprocessing historical data.

---

## Tools & Technologies

- **Microsoft Fabric** — Lakehouse, Warehouse, Dataflows, Pipelines
- **Power BI** — Semantic Model & Report
- **Python** — Predictive analysis (Notebook)

---

## Authors

**Afonso Maia** — Nova IMS
