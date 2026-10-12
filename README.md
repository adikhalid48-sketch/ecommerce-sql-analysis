# E-commerce SQL Analysis

20 business questions answered on a 5-table e-commerce database using **PostgreSQL**. The queries move from basic filtering to joins, subqueries, CTEs and window functions.

## Database Schema

![ER Diagram](er_diagram/er_diagram.png)

| Table | Description | Key columns |
|---|---|---|
| `customers` | Customer details | CustomerID (PK), Name, Email, Phone, Address, City, Country |
| `orders` | One row per order | OrderID (PK), CustomerID (FK), OrderDate, TotalAmount |
| `order_items` | One row per product line in an order | OrderItemID (PK), OrderID (FK), ProductID (FK), Quantity, SubTotal |
| `products` | Product catalogue | ProductID (PK), ProductName, CategoryID (FK), Price, Stock |
| `categories` | Product categories | CategoryID (PK), CategoryName |

**Relationships:** `customers` 1→N `orders` 1→N `order_items` N→1 `products` N→1 `categories`

The `orders` and `products` tables act as bridges. To connect a customer's city to category revenue (Q20), the join goes `customers → orders → order_items → products → categories`.

## The 20 Business Questions

![Business Questions](business_queries/questions.png)

## SQL Concepts Covered

| Section | Questions | Concepts |
|---|---|---|
| 1. Basic queries | Q1 to Q5 | `WHERE`, `ORDER BY`, aggregates (`COUNT`, `SUM`, `AVG`), `GROUP BY`, date ranges |
| 2. Joins and grouping | Q6 to Q12 | `INNER JOIN`, `LEFT JOIN`, multi-table joins, anti-join (`LEFT JOIN ... IS NULL`), `LIMIT` with tie-breaking |
| 3. Subqueries, `CASE WHEN`, `HAVING` | Q13 to Q15 | Uncorrelated subquery, `CASE WHEN` bucketing, `HAVING` on aggregates |
| 4. Advanced analytics | Q16 to Q20 | CTEs, `RANK()`, `SUM() OVER` (running total), `PARTITION BY`, percentage of total, `COALESCE` |

## Key Findings

- **Total revenue is ₹6,17,550** across 20 orders, with an average order value of about ₹30,878.
- **Electronics dominates.** It makes about 90% of item-level revenue (₹4,86,000 of ₹5,37,100) and is the top category in 4 of the 6 cities (Mumbai, Delhi, Pune, Bangalore).
- **Revenue is concentrated.** The top 6 customers account for about 90% of total revenue. Arjun Kapoor is the top spender at about 20.6%.
- **Order sizes are skewed.** 6 "Large" orders (over ₹50,000) bring in ₹5,56,000, while 10 "Small" orders (under ₹5,000) bring in ₹28,550.
- **4 products have never sold:** Jacket Leather, Yoga Mat, Harry Potter Book and Data Science Book. The whole Books category has no sales.

### Data quality issues found

- **9 orders have totals that don't match their item subtotals** (Q16), for example order 105 has a total of ₹1,27,000 but items worth ₹1,45,000.
- **2 orders have no items at all** (orders 119 and 120, worth ₹95,000 and ₹1,800). I used a `LEFT JOIN` with `COALESCE` in Q16 so these still show up instead of being dropped.
- Because of these mismatches, revenue calculated from `orders.TotalAmount` and from `order_items.SubTotal` never matches exactly. Questions about money per order, day or customer use `TotalAmount`, and questions about money per category use `SubTotal`.

## Notes on Specific Queries

- **Q9 (top 5 products):** three products tie at 3 units, so I added a tie-breaker on product name to keep the result stable.
- **Q17 (top product per category):** uses `RANK()`, so Electronics returns two rows (iPhone 15 and Laptop Dell XPS tie at 3 units). Swap in `ROW_NUMBER()` with a tie-breaker if exactly one row per category is needed.
- **Q18 (running total):** `SUM(SUM(totalamount)) OVER (ORDER BY orderdate)` groups by date first, so it still works if a date ever has more than one order.

## How to Run

1. Create a new database in PostgreSQL.
2. Open `ecommercesqlproject.sql` in pgAdmin.
3. Change the folder path in the `COPY` commands to where the CSV files from `datasets/` are saved on your computer.
4. Run the table creation and `COPY` section first, then run the queries one at a time.

## Repository Structure

```
├── datasets/                  # 5 CSV files
├── er_diagram/                # ER diagram image
├── business_queries/          # Image of the 20 questions
├── ecommercesqlproject.sql    # Table creation, data import and all 20 solutions
└── README.md
```

## Tools

PostgreSQL 18, pgAdmin 4

## How This Was Built

The dataset came from a YouTube SQL project tutorial. I solved the questions myself before looking at any answers. The 20 questions were written with help from Claude (an AI assistant), and I used it to review my queries, explain concepts like `LEFT JOIN`, CTEs and window functions, and catch mistakes. The CTE and window function questions (Q16 to Q20) were the newest topics for me, so those had the most guidance.
