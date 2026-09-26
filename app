import streamlit as st
import pandas as pd
import plotly.express as px

# --------------------------------------------------
# PAGE CONFIGURATION
# --------------------------------------------------

st.set_page_config(
    page_title="Sales & Revenue Dashboard",
    page_icon="📊",
    layout="wide"
)

# --------------------------------------------------
# TITLE
# --------------------------------------------------

st.title("📊 Sales & Revenue Analysis Dashboard")
st.markdown("Analyze sales performance, revenue trends and top-performing products.")

# --------------------------------------------------
# FILE UPLOAD
# --------------------------------------------------

st.sidebar.header("📂 Upload Data")

uploaded_file = st.sidebar.file_uploader(
    "Upload Excel or CSV file",
    type=["csv", "xlsx"]
)

# --------------------------------------------------
# LOAD DATA
# --------------------------------------------------

if uploaded_file is not None:

    if uploaded_file.name.endswith(".csv"):
        df = pd.read_csv(uploaded_file)
    else:
        df = pd.read_excel(uploaded_file)

else:
    # Sample data if no file is uploaded

    data = {
        "Date": [
            "2026-01-05", "2026-01-10", "2026-01-15",
            "2026-02-05", "2026-02-12", "2026-02-20",
            "2026-03-05", "2026-03-15", "2026-03-25",
            "2026-04-10", "2026-04-18", "2026-04-25"
        ],
        "Product": [
            "Laptop", "Mobile", "Headphones",
            "Laptop", "Tablet", "Mobile",
            "Laptop", "Headphones", "Tablet",
            "Mobile", "Laptop", "Headphones"
        ],
        "Category": [
            "Electronics", "Electronics", "Accessories",
            "Electronics", "Electronics", "Electronics",
            "Electronics", "Accessories", "Electronics",
            "Electronics", "Electronics", "Accessories"
        ],
        "Region": [
            "North", "South", "East",
            "West", "North", "South",
            "East", "West", "North",
            "South", "East", "West"
        ],
        "Quantity": [
            5, 10, 15,
            7, 8, 12,
            6, 20, 9,
            15, 10, 25
        ],
        "Sales": [
            250000, 180000, 75000,
            350000, 240000, 216000,
            300000, 100000, 270000,
            270000, 500000, 125000
        ]
    }

    df = pd.DataFrame(data)

# --------------------------------------------------
# DATA CLEANING
# --------------------------------------------------

df["Date"] = pd.to_datetime(df["Date"], errors="coerce")

df["Sales"] = pd.to_numeric(
    df["Sales"],
    errors="coerce"
).fillna(0)

df["Quantity"] = pd.to_numeric(
    df["Quantity"],
    errors="coerce"
).fillna(0)

df = df.dropna(subset=["Date"])

# --------------------------------------------------
# SIDEBAR FILTERS
# --------------------------------------------------

st.sidebar.header("🔎 Filters")

regions = st.sidebar.multiselect(
    "Select Region",
    options=sorted(df["Region"].dropna().unique()),
    default=sorted(df["Region"].dropna().unique())
)

categories = st.sidebar.multiselect(
    "Select Category",
    options=sorted(df["Category"].dropna().unique()),
    default=sorted(df["Category"].dropna().unique())
)

products = st.sidebar.multiselect(
    "Select Product",
    options=sorted(df["Product"].dropna().unique()),
    default=sorted(df["Product"].dropna().unique())
)

# --------------------------------------------------
# APPLY FILTERS
# --------------------------------------------------

filtered_df = df[
    (df["Region"].isin(regions)) &
    (df["Category"].isin(categories)) &
    (df["Product"].isin(products))
]

# --------------------------------------------------
# KPI CALCULATIONS
# --------------------------------------------------

total_sales = filtered_df["Sales"].sum()

total_quantity = filtered_df["Quantity"].sum()

total_orders = len(filtered_df)

average_sales = (
    total_sales / total_orders
    if total_orders > 0
    else 0
)

# --------------------------------------------------
# KPI CARDS
# --------------------------------------------------

col1, col2, col3, col4 = st.columns(4)

col1.metric(
    "💰 Total Revenue",
    f"₹{total_sales:,.0f}"
)

col2.metric(
    "📦 Total Units Sold",
    f"{total_quantity:,.0f}"
)

col3.metric(
    "🛒 Total Orders",
    f"{total_orders:,}"
)

col4.metric(
    "📈 Average Order Value",
    f"₹{average_sales:,.0f}"
)

st.markdown("---")

# --------------------------------------------------
# MONTHLY REVENUE TREND
# --------------------------------------------------

st.subheader("📈 Revenue Trend")

monthly_sales = (
    filtered_df
    .groupby(filtered_df["Date"].dt.to_period("M"))["Sales"]
    .sum()
    .reset_index()
)

monthly_sales["Date"] = monthly_sales["Date"].astype(str)

fig_revenue = px.line(
    monthly_sales,
    x="Date",
    y="Sales",
    markers=True,
    title="Monthly Revenue"
)

fig_revenue.update_layout(
    xaxis_title="Month",
    yaxis_title="Revenue",
    hovermode="x unified"
)

st.plotly_chart(
    fig_revenue,
    use_container_width=True
)

# --------------------------------------------------
# PRODUCT & CATEGORY ANALYSIS
# --------------------------------------------------

col1, col2 = st.columns(2)

with col1:

    st.subheader("🏆 Top Performing Products")

    product_sales = (
        filtered_df
        .groupby("Product")["Sales"]
        .sum()
        .sort_values(ascending=False)
        .reset_index()
    )

    fig_product = px.bar(
        product_sales,
        x="Sales",
        y="Product",
        orientation="h",
        title="Sales by Product"
    )

    st.plotly_chart(
        fig_product,
        use_container_width=True
    )

with col2:

    st.subheader("📊 Sales by Category")

    category_sales = (
        filtered_df
        .groupby("Category")["Sales"]
        .sum()
        .reset_index()
    )

    fig_category = px.pie(
        category_sales,
        names="Category",
        values="Sales",
        hole=0.4,
        title="Revenue Distribution by Category"
    )

    st.plotly_chart(
        fig_category,
        use_container_width=True
    )

# --------------------------------------------------
# REGION ANALYSIS
# --------------------------------------------------

st.subheader("🌍 Regional Sales Performance")

region_sales = (
    filtered_df
    .groupby("Region")["Sales"]
    .sum()
    .sort_values(ascending=False)
    .reset_index()
)

fig_region = px.bar(
    region_sales,
    x="Region",
    y="Sales",
    title="Revenue by Region",
    text_auto=True
)

st.plotly_chart(
    fig_region,
    use_container_width=True
)

# --------------------------------------------------
# TOP 10 PRODUCTS TABLE
# --------------------------------------------------

st.subheader("🥇 Top 10 Products")

top_products = (
    filtered_df
    .groupby("Product")
    .agg(
        Total_Sales=("Sales", "sum"),
        Units_Sold=("Quantity", "sum")
    )
    .sort_values(
        "Total_Sales",
        ascending=False
    )
    .head(10)
    .reset_index()
)

top_products["Total_Sales"] = top_products[
    "Total_Sales"
].apply(lambda x: f"₹{x:,.0f}")

st.dataframe(
    top_products,
    use_container_width=True,
    hide_index=True
)

# --------------------------------------------------
# RAW DATA
# --------------------------------------------------

with st.expander("📋 View Filtered Data"):

    st.dataframe(
        filtered_df,
        use_container_width=True
    )

# --------------------------------------------------
# DOWNLOAD DATA
# --------------------------------------------------

csv = filtered_df.to_csv(index=False)

st.download_button(
    label="⬇️ Download Filtered Data",
    data=csv,
    file_name="filtered_sales_data.csv",
    mime="text/csv"
)

# --------------------------------------------------
# FOOTER
# --------------------------------------------------

st.markdown("---")

st.caption(
    "Sales & Revenue Analysis Dashboard | "
    "Built using Python, Pandas, Plotly and Streamlit"
)
