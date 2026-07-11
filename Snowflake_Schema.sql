-- ZOMATO DATA ANALYTICS USING SQL



--Creating the snowflake schema of my database.

CREATE TABLE customers
(
  customer_id INT PRIMARY KEY,
  customer_name VARCHAR(30),
  reg_date DATE
);

CREATE TABLE restaurants
(
  restaurant_id INT PRIMARY KEY,
  restaurant_name VARCHAR(40),
  city VARCHAR(15),
  opening_hours VARCHAR(60)
);

CREATE TABLE orders
(
  order_id INT PRIMARY KEY,
  customer_id INT,  -- foreign key to the customers table.
  restaurant_id INT,  -- foreign key to the restaurants table.
  order_item VARCHAR(50),
  order_date DATE,
  order_time TIME,
  order_status VARCHAR(25),
  total_amount FLOAT
);

-- Adding constraints (foreign keys)

ALTER TABLE orders 
ADD CONSTRAINT fk_customers
FOREIGN KEY(customer_id)
REFERENCES customers(customer_id);

ALTER TABLE orders 
ADD CONSTRAINT fk_restaurants
FOREIGN KEY(restaurant_id)
REFERENCES restaurants(restaurant_id);

CREATE TABLE riders
(
  rider_id INT PRIMARY KEY,
  rider_name VARCHAR(50),
  sign_up DATE
);

CREATE TABLE deliveries
(
 delivery_id INT PRIMARY KEY,
 order_id INT,  -- foreign key to the orders table.
 delivery_status VARCHAR(40),
 delivery_time TIME,
 rider_id INT  -- foreign key to the riders table.
);

-- Adding constraints (foreign keys)

ALTER TABLE deliveries 
ADD CONSTRAINT fk_orders
FOREIGN KEY(order_id)
REFERENCES orders(order_id);

ALTER TABLE deliveries 
ADD CONSTRAINT fk_riders
FOREIGN KEY(rider_id)
REFERENCES riders(rider_id);

-- End of the snowflake schema



