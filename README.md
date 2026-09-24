# 📚 Library Management System — Database & Business Analysis (PostgreSQL)

## 📌 Project Overview
This project presents an end-to-end relational database solution for a Library Management System built with *PostgreSQL*. The database models library operations such as book cataloging, branch and employee assignments, issuance logs, and return tracking. Using advanced SQL techniques, key analytical problems are answered—including inventory turnover, reader activity, and automated overdue fine calculations.

---

## 🏗️ Database Architecture & Schema
The relational model consists of 6 primary tables:
1.**branch:** Branch location and managerial details.
2.**employees:** Staff records and corresponding branch allocations.
3.**books:** Complete catalog with title, category, rental cost, and availability status.
4.**members:** Registered members and registration dates.
5.**issued_status:** Transaction records of issued books and borrower associations.
6.**return_status:** Log of returned items and return timestamps.

---

## 🛠️ Tech Stack & Skills Demonstrated
1. **Database:** PostgreSQL 
2. **Query Tool:** pgAdmin 4
3. **SQL Competencies:**
  - Multi-table Relational Joins (INNER JOIN, LEFT JOIN)
  - Aggregations & Grouping Filters (GROUP BY, HAVING)
  - Subqueries & Common Table Expressions (CTEs)
  - Date & Time Arithmetic (CURRENT_DATE, Date difference, Intervals)
  - Data Definition & Table Creation from Queries (CTAS)

---

## 💡 Key Business Questions & SQL Implementations
* **Inventory Tracking:** Evaluated available stock versus actively issued titles using LEFT JOIN and condition filtering.
* **Member Activity Analysis:** Identified high-frequency borrowers through data aggregation (GROUP BY, COUNT, SUM).
* **Branch Operations:** Analyzed cross-branch rental revenue and employee workload.
* **Overdue Books & Fine Management:** Extracted books unreturned past the standard 30-day window (return_date IS NULL with interval filtering) and computed penalty fees (0.50/day) stored in a summary table using CTAS.

---

## 💻 key SQL Queries and Analysis

## Q1: Identify Members with Overdue Books Write a query to identify members who have overdue books(assume a 100-day return period). Display the member's name, book title, issue date, and days overdue.
```sql
SELECT m.member_name,
       b.book_title,
       iss.issued_date,
       rs.return_date,
       CURRENT_DATE - iss.issued_date AS over_due_days
FROM members AS m
JOIN issued_status AS iss ON m.member_id=iss.issued_member_id
JOIN books AS b ON b.isbn=iss.issued_book_isbn
LEFT JOIN return_status AS rs ON iss.issued_id=rs.issued_id
WHERE rs.return_date IS NULL
  AND CURRENT_DATE - iss.issued_date>100;
```
## Q2: Branch Performance Report Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.
```sql
SELECT b.branch_id,
       count(iss.issued_id) AS total_book_issued,
       count(rs.return_id) AS total_return_book,
       sum(bk.rental_price) AS total_revenue
FROM branch AS b
JOIN employees AS e ON b.branch_id=e.branch_id
LEFT JOIN issued_status AS iss ON e.emp_id=iss.issued_emp_id
LEFT JOIN return_status AS rs ON iss.issued_id=rs.issued_id
LEFT JOIN books AS bk ON iss.issued_book_isbn=bk.isbn
GROUP BY 1
ORDER BY 1;
```
## Q3: Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.
```sql
SELECT emp.emp_id,
       emp.emp_name,
       emp.branch_id,
       count(iss.issued_id) AS total_issued_books
FROM employees AS emp
JOIN issued_status AS iss ON emp.emp_id=iss.issued_emp_id
GROUP BY 1,2,3
ORDER BY 4 DESC
LIMIT 3;
```
## Q4: Write a query to identify members who have issued books with the status "damaged" in the books table. Display the member name, book title, and the number of times they've issued damaged books. 
```sql 
SELECT m.member_name,
       iss.issued_book_name,
       count(rs.book_quality) AS total
FROM members AS m
JOIN issued_status AS iss ON m.member_id=iss.issued_member_id
JOIN return_status AS rs ON iss.issued_id=rs.issued_id 
WHERE rs.book_quality='Damaged'
GROUP BY 1,2;
```
## Q5: create a new table that lists each member and the books they have issued but not returned within 30 days. 
## The table should include: The number of overdue books. The total fines, with each day's fine calculated at 0.50. The number of books issued by each member. 
## The resulting table should show: Member ID Number of overdue books Total fines
```sql
CREATE TABLE overdue_fine_summary AS
SELECT iss.issued_member_id AS member_id,
       count(iss.issued_id) AS no_of_overdue_books,
       sum(((CURRENT_DATE-iss.issued_date)-30)*0.50) AS total_fine
FROM issued_status iss
LEFT JOIN return_status rs ON iss.issued_id=rs.issued_id
WHERE rs.return_date IS NULL
  AND (CURRENT_DATE-iss.issued_date)>30
GROUP BY 1
ORDER BY 3 DESC;


SELECT*
FROM overdue_fine_summary;
```

---
## 🔍 Key Insights
1. A small segment of highly active members accounts for the majority of total book issuances.
2. Automated overdue tracking effectively captures long-pending unreturned items, facilitating immediate penalty assessment and inventory recovery.
