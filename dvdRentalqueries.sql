---A4. Identify at least one field in the detailed table section that will require a custom transformation with a user-defined function and explain why it should be transformed (e.g., you might translate a field with a value of N to No and Y to Yes).

---Category_name will be used for this, We will be creating a transformation to make sure that the category is uppercased.

---B. Provide original code for function(s) in text format that perform the transformation(s) you identified in part A4.
CREATE FUNCTION format_category_name(name TEXT)
RETURNS TEXT AS $$


BEGIN
   
    RETURN UPPER(name);
END;

$$ LANGUAGE plpgsql;

---C.  Provide original SQL code in a text format that creates the detailed and summary tables to hold your report table sections.
---Detailed Table:
CREATE TABLE Detailed_Rental_Transactions AS
SELECT 
    r.rental_id,
    r.rental_date,
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    f.film_id,
    f.title AS film_title,
    cat.category_id AS category_id,
    format_category_name(cat.name) AS category_name,
    f.rental_rate AS sale_amount
FROM 
    rental r
JOIN 
    inventory i ON r.inventory_id = i.inventory_id
JOIN 
    film f ON i.film_id = f.film_id
JOIN 
    film_category fc ON f.film_id = fc.film_id
JOIN 
    category cat ON fc.category_id = cat.category_id
JOIN 
    customer c ON r.customer_id = c.customer_id;

---Summary Table:
Create Table Category_Profits AS
Select
	cat.category_id, 
	format_category_name(cat.name) AS category_name,
	COUNT(*) AS total_rentals, 
	SUM(f.rental_rate) AS total_sales_amount
From
	rental r
Join
	inventory i ON r.inventory_id = i.inventory_id
Join
	film f ON i.film_id = f.film_id
Join
	film_category fc ON f.film_id = fc.film_id
Join
	category cat ON fc.category_id = cat.category_id
Group BY
	cat.category_id, cat.name
Order By
	total_sales_amount DESC;

---D. Provide an original SQL query in a text format that will extract the raw data needed for the detailed section of your report from the source database
SELECT 
    r.rental_id,
    r.rental_date,
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    f.film_id,
    f.title AS film_title,
    cat.category_id AS category_id,
    format_category_name(cat.name) AS category_name,
    f.rental_rate AS sale_amount
FROM 
    rental r
JOIN 
    inventory i ON r.inventory_id = i.inventory_id
JOIN 
    film f ON i.film_id = f.film_id
JOIN 
    film_category fc ON f.film_id = fc.film_id
JOIN 
    category cat ON fc.category_id = cat.category_id
JOIN 
    customer c ON r.customer_id = c.customer_id;

---E.  Provide original SQL code in a text format that creates a trigger on the detailed table of the report that will continually update the summary table as data is added to the detailed table.
CREATE FUNCTION Update_Category_Profits()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO Category_Profits (category_id, category_name, total_rentals, total_sales_amount)
    VALUES (
        NEW.category_id, 
        format_category_name(NEW.category),
        1, 
        NEW.sale_amount
    )
    ON CONFLICT (category_id) 
    DO UPDATE
    SET 
        total_rentals = Category_Profits.total_rentals + 1,
        total_sales_amount = Category_Profits.total_sales_amount + EXCLUDED.total_sales_amount;

    RETURN NEW;
END;
$$ 
LANGUAGE plpgsql;

---F.  Provide an original stored procedure in a text format that can be used to refresh the data in both the detailed table and summary table. The procedure should clear the contents of the detailed table and summary table and perform the raw data extraction from part D.
CREATE OR REPLACE PROCEDURE Refresh_Rental_Data()
LANGUAGE plpgsql
AS $$
	
BEGIN

    TRUNCATE TABLE Detailed_Rental_Transactions;

    INSERT INTO Detailed_Rental_Transactions (rental_id, rental_date, customer_id, customer_name, film_id, film_title, category_id, category, sale_amount)
    SELECT 
        r.rental_id,
        r.rental_date,
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        f.film_id,
        f.title AS film_title,
        cat.category_id AS category_id,
        format_category_name(cat.name) AS category,
        f.rental_rate AS sale_amount
    FROM 
        rental r
    JOIN 
        inventory i ON r.inventory_id = i.inventory_id
    JOIN 
        film f ON i.film_id = f.film_id
    JOIN 
        film_category fc ON f.film_id = fc.film_id
    JOIN 
        category cat ON fc.category_id = cat.category_id
    JOIN 
        customer c ON r.customer_id = c.customer_id;


    TRUNCATE TABLE Category_Profits;

    INSERT INTO Category_Profits (category_id, category_name, total_rentals, total_sales_amount)
    SELECT
        cat.category_id, 
        format_category_name(cat.name) AS category,
        COUNT(*) AS total_rentals, 
        SUM(f.rental_rate) AS total_sales_amount
    FROM
        rental r
    JOIN 
        inventory i ON r.inventory_id = i.inventory_id
    JOIN 
        film f ON i.film_id = f.film_id
    JOIN 
        film_category fc ON f.film_id = fc.film_id
    JOIN 
        category cat ON fc.category_id = cat.category_id
    GROUP BY
        cat.category_id, cat.name
    ORDER BY
        total_sales_amount DESC;
END;
$$;



