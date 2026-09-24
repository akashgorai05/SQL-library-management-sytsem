--LIBRARY MANAGEMENT SYSTEM--
 -- Q1: Create a New Book Record
-- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books
VALUES (978-1-60129-456-2, 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

--Q2: delte from books record

DELETE
FROM books
WHERE isbn='-59610';

--Q3:  Update an Existing Member's Address
 
UPDATE members
SET member_address='dhandabag' 
WHERE member_id='C108';

--Q4: Select all books issued by the employee with emp_id = 'E101'.

SELECT issued_emp_id AS emp,
       issued_book_name AS book
FROM issued_status
WHERE issued_emp_id='E101';

--Q5: Find members name and id who have issued more than 3 books.

SELECT mem.member_name,
       iss.issued_member_id,
       count(iss.issued_book_name) AS count_of_books
FROM issued_status AS iss
JOIN members AS mem ON mem.member_id=iss.issued_member_id
GROUP BY 1,
         2
HAVING count(issued_book_name)>3
ORDER BY 3 DESC;

--Q6: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt?

CREATE TABLE book_counts AS
  (SELECT b.isbn,
          b.book_title,
          count(iss.issued_id)
   FROM books AS b
   JOIN issued_status AS iss ON iss.issued_book_isbn=b.isbn
   GROUP BY 1,
            2);

--Q7: Count total number of books from each Category?

SELECT category,
       count(book_title)
FROM books
GROUP BY 1
ORDER BY 1;

--Q8: Find Total Rental Income by Category?

SELECT b.category,
       sum(b.rental_price) AS total_rental_income,
       count(iss.issued_id) AS total_issued_count
FROM books AS b
JOIN issued_status AS iss ON b.isbn=iss.issued_book_isbn
GROUP BY 1
ORDER BY 2 DESC;

--OR--

SELECT b.category,
       sum(b.rental_price*bc.count) AS total_income
FROM books AS b
JOIN book_counts AS bc ON b.isbn=bc.isbn
GROUP BY 1
ORDER BY 2 DESC;

--Q9: List Members Who Registered in the Last 180 Days?

SELECT *
FROM members
WHERE reg_date>= '2024-06-01'::date-interval '100 days';

--Q10: List Employees with Their Branch Manager's Name and their branch details

SELECT emp.emp_name AS employee,
       emp2.emp_name AS manager
FROM employees AS emp
JOIN branch AS b ON b.branch_id=emp.branch_id
JOIN employees AS emp2 ON b.manager_id=emp2.emp_id;

--Q11:  Create a Table of Books with Rental Price Above a Certain Threshold 5 USD

CREATE TABLE books_price_above_7USD AS
SELECT*
FROM books
WHERE rental_price>=7
ORDER BY rental_price DESC;

SELECT*
FROM books_price_above_7USD;

--Q12:  Retrieve the List of Books Not Yet Returned?

SELECT DISTINCT iss.issued_book_name
FROM issued_status AS iss
LEFT JOIN return_status AS rs ON iss.issued_id=rs.issued_id
WHERE rs.return_id IS NULL;

--Q13: Identify Members with Overdue Books Write a query to identify members who have overdue books
--(assume a 100-day return period). Display the member's name, book title, issue date, and days overdue.

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

--or--

WITH cte_name AS
  (SELECT m.member_name,
          b.book_title,
          iss.issued_date,
          rs.return_date,
          CURRENT_DATE - iss.issued_date AS over_due_days
   FROM members AS m
   JOIN issued_status AS iss ON m.member_id=iss.issued_member_id
   JOIN books AS b ON b.isbn=iss.issued_book_isbn
   LEFT JOIN return_status AS rs ON iss.issued_id=rs.issued_id)
SELECT *
FROM cte_name
WHERE return_date IS NULL
  AND over_due_days>100;

--Q14: Update Book Status on Return
--Write a query to update the status of books in the books table to "available" when they are returned
--(based on entries in the return_status table).

UPDATE books
SET status='yes'
WHERE isbn IN
    (SELECT iss.issued_book_isbn
     FROM return_status AS rs
     JOIN issued_status AS iss ON iss.issued_id=rs.issued_id);

--Q15: Branch Performance Report
--Create a query that generates a performance report for each branch,
--showing the number of books issued, the number of books returned,
--and the total revenue generated from book rentals.

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

--Q16: create a new table active_members containing members who have issued at least one book in the last 6 months.

CREATE TABLE active_members AS
  (SELECT DISTINCT m.member_id,
                   m.member_name
   FROM members AS m
   JOIN issued_status AS iss ON m.member_id=iss.issued_member_id
   WHERE iss.issued_date>=CURRENT_DATE-interval '6 months')
SELECT *
FROM active_members;

--17: Write a query to find the top 3 employees who have processed the most book issues.
--Display the employee name, number of books processed, and their branch.

SELECT emp.emp_id,
       emp.emp_name,
       emp.branch_id,
       count(iss.issued_id) AS total_issued_books
FROM employees AS emp
JOIN issued_status AS iss ON emp.emp_id=iss.issued_emp_id
GROUP BY 1,2,3
ORDER BY 4 DESC
LIMIT 3;

--Q18:Write a query to identify members who have issued books with the status "damaged" in the books table.
--Display the member name, book title, and the number of times they've issued damaged books. 
 
SELECT m.member_name,
       iss.issued_book_name,
       count(rs.book_quality) AS total
FROM members AS m
JOIN issued_status AS iss ON m.member_id=iss.issued_member_id
JOIN return_status AS rs ON iss.issued_id=rs.issued_id 
WHERE rs.book_quality='Damaged'
GROUP BY 1,2;

--Q19: create a new table that lists each member and the books they have issued but not returned within 30 days.
--The table should include:
--The number of overdue books.
--The total fines, with each day's fine calculated at $0.50.
--The number of books issued by each member.
--The resulting table should show:
--Member ID
--Number of overdue books
--Total fines

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