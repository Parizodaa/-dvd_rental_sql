-- ================================
-- VIEW
-- ================================

-- This view shows total revenue by film category
-- only for the current quarter

CREATE OR REPLACE VIEW sales_revenue_by_category_qtr AS
SELECT
    c.category_id,
    c.name AS category_name,
    SUM(p.amount) AS total_revenue
FROM payment p
INNER JOIN rental r ON p.rental_id = r.rental_id
INNER JOIN inventory i ON r.inventory_id = i.inventory_id
INNER JOIN film_category fc ON i.film_id = fc.film_id
INNER JOIN category c ON fc.category_id = c.category_id
-- filter only current quarter and current year
WHERE EXTRACT(QUARTER FROM p.payment_date) = EXTRACT(QUARTER FROM CURRENT_DATE)
  AND EXTRACT(YEAR FROM p.payment_date) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY c.category_id, c.name
-- exclude categories with zero revenue
HAVING SUM(p.amount) > 0
-- sort from highest revenue
ORDER BY total_revenue DESC;

SELECT * FROM sales_revenue_by_category_qtr;


-- ================================
--  FUNCTION
-- ================================

-- this function returns same data but for selected quarter (1-4)

CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(qtr INT)
RETURNS TABLE (
    category_id INT,
    category_name TEXT,
    total_revenue NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.category_id,
        c.name,
        SUM(p.amount)
    FROM payment p
    INNER JOIN rental r ON p.rental_id = r.rental_id
    INNER JOIN inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN film_category fc ON i.film_id = fc.film_id
    INNER JOIN category c ON fc.category_id = c.category_id
    -- filter by quarter AND current year (same logic as view)
    WHERE EXTRACT(QUARTER FROM p.payment_date) = qtr
      AND EXTRACT(YEAR FROM p.payment_date) = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY c.category_id, c.name
    HAVING SUM(p.amount) > 0
    ORDER BY SUM(p.amount) DESC;
END;
$$;

SELECT * FROM get_sales_revenue_by_category_qtr(2);



-- ================================
-- PROCEDURE
-- ================================

-- this procedure adds new movie with random values
-- also checks if Klingon language exists

CREATE OR REPLACE PROCEDURE new_movie(movie_title TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
    lang_id INT;
BEGIN
    -- try to find Klingon language
    SELECT language_id INTO lang_id
    FROM language
    WHERE name = 'Klingon'
    LIMIT 1;

    -- if not found so error
    IF lang_id IS NULL THEN
        RAISE EXCEPTION 'Klingon language not found';
    END IF;

    -- insert new movie
    INSERT INTO film (
        title,
        rental_rate,
        rental_duration,
        replacement_cost,
        release_year,
        language_id
    )
    VALUES (
        movie_title,
        (random() * 99 + 1)::NUMERIC(5,2), -- random 1..100
        (floor(random() * 10) + 1)::INT,   -- random 1..10
        (random() * 49 + 1)::NUMERIC(5,2), -- random 1..50
        EXTRACT(YEAR FROM CURRENT_DATE),   -- current year
        lang_id
    );
END;
$$;

CALL new_movie('Test Movie');

-- check result
SELECT title, rental_rate, rental_duration, replacement_cost, release_year
FROM film
WHERE title = 'Test Movie';
