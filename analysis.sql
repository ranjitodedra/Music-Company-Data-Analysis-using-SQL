-- QI: Who is the senior most employee based on job title?

SELECT *
FROM employee
ORDER BY levels DESC
LIMIT 1;

-- Q2: Which countries have the most Invoices?

SELECT billing_country, COUNT(*) AS MostInvoices
FROM invoice
GROUP BY billing_country
ORDER BY MostInvoices DESC;

-- Q3: What are top 3 values of total invoice

SELECT total
FROM invoice
ORDER BY total DESC
LIMIT 3;

-- Q4: Which city has the best customers? We would like to throw a promotional Music 
-- Festival in the city we made the most money. 
-- Write a query that returns one city that has the highest sum of invoice
-- totals.Return both the city name & sum of all invoice totals

SELECT billing_city, SUM(total) AS Total_sum
FROM invoice
GROUP BY billing_city
ORDER BY Total_sum DESC
LIMIT 1;

-- Q5: Who is the best customer? The customer who has spent the most
-- money will be declared the best customer. Write a query that returns
-- the person who has spent the most money.

SELECT customer.customer_id, customer.first_name, customer.last_name, SUM(invoice.total) AS Total_Spent
FROM customer
JOIN invoice
ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id
ORDER BY Total_Spent DESC
LIMIT 1;

-- Q6 : Write query that return email, first name, last name of Rock music 
-- listeners (Here Rock is genre of Music aka track).
-- Return your list ordered alphabetically by email starting with A.

SELECT DISTINCT email, first_name, last_name
FROM customer 
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN ( 
	SELECT track.track_id
	FROM track JOIN genre
	ON track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
ORDER BY email;

-- Q7: Let's invite the artists who have written the most rock music in
-- our dataset. Write a query that returns the artist id, band name and total
-- track count. and return 10 results with most songs( or track)

SELECT artist.artist_id, artist.name, COUNT(track.track_id) as NumberOfTrack
FROM track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY NumberOfTrack DESC
LIMIT 10;

-- Q8: Return all the track names that have a song length longer than the average song length.
-- Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.

SELECT name, milliseconds
FROM track
WHERE milliseconds > (
	SELECT AVG(milliseconds)
	FROM track
	)
GROUP BY track_id
ORDER BY milliseconds DESC;

-- Q9: Find how much amount spent by each customer on top artist (one artist with highest sales)? 
-- Write a query to return customer name, artist name and total spent

WITH Best_Selling_Artist AS (
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name, 
	SUM(invoice_line.quantity*invoice_line.unit_price) AS TotalSales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY artist.artist_id
	ORDER BY TotalSales DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, 
SUM(il.quantity*il.unit_price) AS AmountSpent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album a ON a.album_id = t.album_id
JOIN artist ar ON ar.artist_id = a.artist_id
JOIN Best_Selling_Artist bsa ON bsa.artist_id = ar.artist_id
GROUP BY 1, 2, 3, 4
ORDER BY AmountSpent DESC;

-- Q10: We want to find out the most popular music Genre for each country.
-- We determine the most popular genre as the genre with the highest
-- amount of purchases. Write a query that returns each country along with
-- the top Genre. For countries where the maximum number of purchases
-- is shared return all Genres.

WITH Popular_genre AS
(
	SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id,
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo
	FROM invoice_line
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2, 3, 4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM Popular_genre WHERE RowNo <= 1;

-- or Recursion

WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchase_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id  
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id 
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2, 3, 4
		ORDER BY 2
	),
	max_genre_per_country AS(
		SELECT MAX(purchase_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2
	)
SELECT sales_per_country.*
FROM sales_per_country 
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchase_per_genre = max_genre_per_country.max_genre_number;

-- Q11: Write a query that determines the customer that has spent the most
-- on music for each country. Write a query that returns the country along
-- with the top customer and how much they spent. For countries where
-- the top amount spent is shared, provide all customers who spent this amount

WITH RECURSIVE 
	customer_per_country AS(
		SELECT customer.customer_id, first_name, last_name, billing_country, SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 1, 5 DESC
	),
	country_with_max_spending AS(
		SELECT billing_country, MAX(total_spending) AS max_spending
		FROM customer_per_countrya
		GROUP BY billing_country
	)
SELECT cpc.billing_country, cpc.first_name, cpc.last_name, cpc.customer_id
FROM customer_per_country cpc
JOIN country_with_max_spending cms ON cpc.billing_country = cms.billing_country
WHERE cpc.total_spending = cms.max_spending
ORDER BY 1;

-- or using CTE

 WITH customer_with_country AS (
 	SELECT customer.customer_id, first_name, last_name, billing_country, SUM(total) AS total_spending,
	ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo
	FROM customer 
	JOIN invoice ON invoice.customer_id = customer.customer_id
	GROUP BY 1, 2, 3, 4
	ORDER BY 4 ASC, 5 DESC
 )
 SELECT * FROM customer_with_country WHERE RowNo <= 1;