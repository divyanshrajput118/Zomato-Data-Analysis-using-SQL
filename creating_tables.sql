-- Zomato Analysis Project
-- Creating Tables

CREATE TABLE customers (
    customer_id   INT PRIMARY KEY,
    customer_name VARCHAR(20),
    reg_date      DATE
);

CREATE TABLE riders (
    rider_id    INT PRIMARY KEY,
    rider_name  VARCHAR(15),
    signup_date DATE
);

CREATE TABLE restaurants (
    restaurant_id   INT PRIMARY KEY,
    restaurant_name VARCHAR(15),
    city            VARCHAR(10),
    opening_hours   VARCHAR(55)
);

CREATE TABLE orders (
    order_id      INT PRIMARY KEY,
    customer_id   INT,
    restaurant_id INT,
    order_item    VARCHAR(25),
    order_date    DATE,
    order_time    TIME,
    order_status  VARCHAR(10),
    total_amount  INT,

    CONSTRAINT fk_orders_customers
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    CONSTRAINT fk_orders_restaurants
        FOREIGN KEY (restaurant_id)
        REFERENCES restaurants(restaurant_id)
);

CREATE TABLE deliveries (
    delivery_id     INT PRIMARY KEY,
    order_id        INT,
    delivery_status VARCHAR(15),
    delivery_time   TIME,
    rider_id        INT,

    CONSTRAINT fk_deliveries_orders
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id),

    CONSTRAINT fk_deliveries_riders
        FOREIGN KEY (rider_id)
        REFERENCES riders(rider_id)
);