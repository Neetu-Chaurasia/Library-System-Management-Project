use library_db;
-- https://github.com/najirh/Library-System-Management---P2/tree/main


--                                                                    Project TASK

-- Task 1. Create a New Book Record ("978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
Insert into books
values
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
select * from books;

-- Task 2: Update an Existing Member's Address
select * from members;
update members
set member_address = '124 Main st'
where member_id= 'C101';

-- Task 3: Delete a Record from the Issued Status Table
-- Objective: Delete the record with issued_id = 'IS115' from the issued_status table.
delete from issued_status
where issued_id = 'IS115';


-- Task 4: Retrieve All Books Issued by a Specific Employee
-- Objective: Select all books issued by the employee with emp_id = 'E101'.
select * from issued_status where issued_emp_id = 'E101';

-- Task 5: List Members Who Have Issued More Than One Book
-- Objective: Use GROUP BY to find members who have issued more than one book.
select count(*) as "total books issued", issued_emp_id
from issued_status
group by issued_emp_id;

--                                           ### 3. CTAS (Create Table As Select)

-- Task 6: Create Summary Tables**: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt
with summary_table as (select count(*) as "total books issued",book_title 
from issued_status i 
left join books b on b.isbn = i.issued_book_isbn
group by issued_book_name,book_title)
select * from summary_table;
--                                                             or 
with 
book_sum as (select isbn,book_title from books),
issued_Sum as(select issued_book_isbn,issued_book_name from issued_status)

select count(*) as "total books issued",book_title from issued_sum i 
left join book_sum b on b.isbn = i.issued_book_isbn
group by issued_book_name,book_title;


--                                                       ### 4. Data Analysis & Findings

-- Task 7. **Retrieve All Books in a Specific Category:
select * from books where category = "fiction";

-- Task 8: Find Total Rental Income by Category:
select sum(rental_price) as "rental income",category from books group by category;
select * from members;


-- Task 9. List Members Who Registered in the Last 180 Days
select *  from members
where timestampdiff(day,reg_date,curdate()) <= 180;
--                                      or
select datediff(curdate(),reg_date) as total_days_joined,reg_date,member_name from members
where datediff(curdate(),reg_date) <= 180;


-- Task 10: List Employees with Their Branch Manager's Name and their branch details**:
SELECT e.emp_id,e.emp_name,b.branch_address,b.manager_id,
m.emp_name AS manager_name
FROM employees e
JOIN branch b ON e.branch_id = b.branch_id
LEFT JOIN employees m ON b.manager_id = m.emp_id;    ## self- join

use library_db;

-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold - i.e 7USD - using CTE
with books_price_greater_than_7USD
as(select * from books where rental_price > 7)

select  * from books_price_greater_than_7USD;


-- Task 12: Retrieve the List of Books Not Yet Returned
select i.issued_id,return_id,issued_date,return_date,issued_book_name
from issued_status i
left join return_status r on i.issued_id = r.issued_id
where return_date is null;
    

    --                                                         Advanced SQL Operations

-- Task 13: Identify Members with Overdue Books
-- Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's name, book title, issue date, and days overdue.

select member_name,issued_date,book_title,CURRENT_DATE - i.issued_date as over_dues_days from issued_status i
JOIN books as bk ON bk.isbn = i.issued_book_isbn
left join return_status r on i.issued_id = r.issued_id
join members on member_id = i.issued_member_id
where timestampdiff(day,i.issued_date,curdate()) and return_date is  null;


-- Task 14: Update Book Status on Return
-- Write a query to update the status of books in the books table to "available" when they are returned (based on entries in the return_status table).
update books b
join issued_status i on i.issued_book_isbn = b.isbn
join return_status r on i.issued_id = r.issued_id
set b.book_status = "available" 
where r.return_date is not null;
select * from books;

alter table books
add column book_status varchar(30);

ALTER TABLE books
MODIFY COLUMN status VARCHAR(20);

update books b
join issued_status i on i.issued_book_isbn = b.isbn
left join return_status r on i.issued_id = r.issued_id
set b.book_status = "not available" 
where r.return_date is  null;


-- Task 15: Branch Performance Report
-- Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.
with branch_reports
AS
(SELECT b.branch_id, b.manager_id,
    COUNT(Distinct ist.issued_id) as number_book_issued,
    COUNT(Distinct rs.return_id) as number_of_book_return,
    SUM(bk.rental_price) as total_revenue
FROM issued_status as ist
JOIN employees as e ON e.emp_id = ist.issued_emp_id
JOIN branch as b ON e.branch_id = b.branch_id
LEFT JOIN return_status as rs ON rs.issued_id = ist.issued_id
JOIN books as bk ON ist.issued_book_isbn = bk.isbn
GROUP BY 1, 2)
SELECT * FROM branch_reports;

-- Task 16: CTAS: Create a Table of Active Members
-- Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 6 months.
with active_members
as 
(select count(Distinct issued_id) as "total_issued",members.member_id ,member_name from issued_Status 
join members on members.member_id=issued_status.issued_member_id
where timestampdiff(month,issued_date,curdate()) <= 6
group by 2 )
select * from active_members;

-- Task 17: Find Employees with the Most Book Issues Processed
-- Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.
select count(issued_id) as number_of_books_processed,emp_id,emp_name,branch_id 
from issued_Status i
join employees e on e.emp_id = i.issued_emp_id
group by 2
order by 1 desc
limit 3;

-- Task 18: Identify Members Issuing High-Risk Books
-- Write a query to identify members who have issued books with the book quality "damaged" in the return_status table. Display the member name, book title, and the number of times they've issued damaged books.    

select count(book_quality),member_id,member_name from issued_status i
left join return_Status r on r.issued_id = i.issued_id
join  members on members.member_id=i.issued_member_id
where book_quality = "damaged"
group by 2;


-- Task 19: Create Table As Select (CTAS)
-- Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.
-- Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days. The table should include:
    -- The number of overdue books.
    -- The total fines, with each day's fine calculated at $0.50.
    -- The number of books issued by each member.
    -- The resulting table should show:
    -- Member ID
    -- Number of overdue books
    -- Total fines


CREATE TABLE overdue_books_summary AS
SELECT i.issued_member_id AS member_id,
COUNT(CASE WHEN timestampdiff(day,issued_date,curdate()) > 30 AND r.return_date IS NULL THEN 1 END) AS overdue_books,
SUM(CASE WHEN timestampdiff(day,issued_date,curdate()) > 30 AND r.return_date IS NULL THEN (timestampdiff(day,issued_date,curdate()) - 30) * 0.5 
ELSE 0 END) AS total_fine,
COUNT(i.issued_id) AS total_books_issued
FROM issued_status i
JOIN books bk ON bk.isbn = i.issued_book_isbn
LEFT JOIN return_status r ON i.issued_id = r.issued_id
GROUP BY i.issued_member_id;

select * from overdue_books_summary

