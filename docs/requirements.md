# Project Requirements

## 1. Building the Data Warehouse (Data Engineering)

### Objective
Develop a modern data warehouse using SQL Server to consolidate sales data from multiple source systems, enabling analytical reporting and informed decision-making.

### Specifications
- **Data Sources**: Import data from two source systems (ERP and CRM) provided as CSV files.
- **Data Quality**: Cleanse and resolve data quality issues prior to analysis.
- **Integration**: Combine both sources into a single, user-friendly data model designed for analytical queries.
- **Scope**: Focus on the latest dataset only; historization of data is not required.
- **Documentation**: Provide clear documentation of the data model to support both business stakeholders and analytics teams.

### Key Deliverables
| Deliverable | Description |
|---|---|
| Bronze Layer | Raw data ingested from CSV files into SQL Server tables using `BULK INSERT`. |
| Silver Layer | Cleansed, standardized, and deduplicated data ready for integration. |
| Gold Layer | Business-ready star schema with dimension and fact tables (views). |
| Quality Checks | SQL scripts to validate data integrity at each layer. |
| Documentation | Data catalog, naming conventions, architecture diagrams. |

---

## 2. BI: Analytics & Reporting (Data Analysis)

### Objective
Develop SQL-based analytics to deliver detailed insights into:
- **Customer Behavior**: Demographics, acquisition trends, segmentation, and lifetime value.
- **Product Performance**: Top/bottom products, category analysis, margins, and product line comparison.
- **Sales Trends**: Monthly/yearly trends, YoY growth, average order value, and shipping patterns.

These insights empower stakeholders with key business metrics, enabling strategic decision-making.

### Key Analytics Reports
| Report | Description |
|---|---|
| Customer Demographics | Gender, marital status, and geographic distribution of customers. |
| Customer Lifetime Value | Revenue segmentation (High/Mid/Low value) per customer. |
| Age Group Analysis | Purchasing behavior by customer age brackets. |
| Top/Bottom Products | Best and worst performing products by revenue. |
| Category Breakdown | Revenue and order analysis by product category and subcategory. |
| Product Margin Analysis | Cost vs. selling price profitability per product. |
| Monthly Sales Trends | Revenue and order patterns over months. |
| YoY Growth | Year-over-year revenue and order growth rates. |
| Shipping Analysis | Average fulfillment times and shipping performance. |

---

## 3. Source Systems

### CRM System
| File | Description |
|---|---|
| `cust_info.csv` | Customer details: ID, name, gender, marital status. |
| `prd_info.csv` | Product details: ID, name, cost, product line, dates. |
| `sales_details.csv` | Sales transactions: orders, products, customers, dates, amounts. |

### ERP System
| File | Description |
|---|---|
| `CUST_AZ12.csv` | Customer demographics: birth date, gender. |
| `LOC_A101.csv` | Customer location: country information. |
| `PX_CAT_G1V2.csv` | Product categories: category, subcategory, maintenance flag. |
