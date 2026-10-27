-- Practice dataset for sql-interview-coach. Idempotent: drops and recreates.
-- E-commerce (customers/products/orders/order_items/shipments) + HR (employees/departments).
-- Deliberately contains: NULLs, inactive customers, cancelled orders,
-- products never ordered, employees without departments, duplicate-ish names,
-- multi-year span for date math, consecutive-event patterns.

BEGIN;

DROP TABLE IF EXISTS shipment_items cascade;
DROP TABLE IF EXISTS shipments cascade;
DROP TABLE IF EXISTS order_items cascade;
DROP TABLE IF EXISTS orders cascade;
DROP TABLE IF EXISTS products cascade;
DROP TABLE IF EXISTS customers cascade;
DROP TABLE IF EXISTS employees cascade;
DROP TABLE IF EXISTS departments cascade;

CREATE TABLE customers (
  customer_id   serial PRIMARY KEY,
  name          text NOT NULL,
  email         text UNIQUE,
  city          text,
  signup_date   date NOT NULL,
  is_active     boolean NOT NULL DEFAULT true
);

CREATE TABLE products (
  product_id    serial PRIMARY KEY,
  name          text NOT NULL,
  category      text NOT NULL,
  unit_price    numeric(10,2) NOT NULL,
  launch_date   date
);

CREATE TABLE departments (
  department_id serial PRIMARY KEY,
  dept_name     text UNIQUE NOT NULL
);

CREATE TABLE employees (
  employee_id   serial PRIMARY KEY,
  name          text NOT NULL,
  department_id int REFERENCES departments,   -- NULLs: no department
  manager_id    int REFERENCES employees,     -- NULLs: top of hierarchy (CEO)
  hire_date     date NOT NULL,
  salary        numeric(10,2) NOT NULL
);

CREATE TABLE orders (
  order_id      serial PRIMARY KEY,
  customer_id   int REFERENCES customers,
  order_date    timestamp NOT NULL,
  status        text NOT NULL,                -- placed/shipped/cancelled/returned
  total_amount  numeric(12,2)                 -- NULL on some cancelled orders
);

CREATE TABLE order_items (
  order_item_id serial PRIMARY KEY,
  order_id      int REFERENCES orders,
  product_id    int REFERENCES products,
  quantity      int NOT NULL,
  unit_price    numeric(10,2) NOT NULL        -- price AT purchase time
);

CREATE TABLE shipments (
  shipment_id   serial PRIMARY KEY,
  order_id      int REFERENCES orders UNIQUE,
  shipped_at    timestamp,
  delivered_at  timestamp                     -- NULL while in transit
);

INSERT INTO departments (dept_name) VALUES
  ('Engineering'), ('Sales'), ('Marketing'), ('HR'), ('Finance');

INSERT INTO employees (name, department_id, manager_id, hire_date, salary) VALUES
  ('Ava Chen',      1, NULL, '2016-03-14', 165000),
  ('Liam Osei',     1, 1,    '2018-07-02', 140000),
  ('Mia Rossi',     1, 1,    '2020-01-20', 132000),
  ('Noah Ventra',   2, 1,    '2017-11-05', 120000),
  ('Priya Nair',    2, 4,    '2019-05-19', 115000),
  ('Oscar Dom',     2, 4,    '2021-09-01', 98000),
  ('Ivy Zhang',     3, NULL, '2019-02-11', 118000),
  ('Carlos Rivera', 4, 1,    '2022-04-25', 87000),
  ('Zoe Adams',     NULL, 1,  '2023-08-15', 91000),
  ('Ravi Kumar',    3, 7,    '2020-10-12', 102000),
  ('Elena Petrova', 5, 1,    '2016-06-30', 128000),
  ('Tom Hart',      5, 11,   '2021-01-11', 96000);

INSERT INTO customers (name, email, city, signup_date, is_active) VALUES
  ('Grace Kim',    'grace.kim@example.com',     'Seoul',       '2021-01-15', true),
  ('Ben James',    'ben.james@example.com',     'London',      '2021-02-20', true),
  ('Nina Alvarez', 'nina.alvarez@example.com',  'Madrid',      '2021-06-03', false),
  ('Kenji Sato',   'kenji.sato@example.com',    'Tokyo',       '2022-03-10', true),
  ('Farah Ali',    'farah.ali@example.com',     'Dubai',       '2022-07-22', true),
  ('Ola Nowak',    NULL,                        'Warsaw',      '2022-11-14', true),
  ('Sampeak Moda', 'sampeak.moda@example.com',  'Bangkok',     '2023-01-08', true),
  ('Ruby Harnel',  'ruby.harnel@example.com',   'Melbourne',   '2023-04-30', false),
  ('Pete Sampat',  'pete.sampat@example.com',   'Pune',        '2023-05-21', true),
  ('Lone Wolf',    NULL,                        'Reykjavik',   '2024-02-29', true); -- signed up, never ordered

INSERT INTO products (name, category, unit_price, launch_date) VALUES
  ('Laptop Pro 14',   'Electronics', 1990.00, '2021-09-01'),
  ('Mech Keyboard',   'Electronics', 129.00,  '2021-09-15'),
  ('Wireless Mouse',  'Electronics', 59.00,   '2022-01-10'),
  ('Stand Desk',      'Furniture',   449.00,  '2022-03-05'),
  ('Ergo Chair',      'Furniture',   320.00,  '2022-03-05'),
  ('Monitor 27"',     'Electronics', 380.00,  '2022-06-20'),
  ('USB-C Hub',       'Accessories', 45.00,   '2022-08-11'),
  ('Webcam 4K',       'Electronics', 120.00,  '2023-02-17'),
  ('Desk Mat XL',     'Accessories', 39.00,   '2023-05-02'),
  ('Cable Tidy Kit',  'Accessories', 19.00,   NULL);  -- launched late, never ordered

INSERT INTO orders (customer_id, order_date, status, total_amount) VALUES
  (1, '2022-06-01 10:15:00', 'shipped',   2119.00),
  (1, '2022-09-12 16:40:00', 'cancelled', NULL),
  (1, '2023-11-03 09:05:00', 'shipped',   129.00),
  (2, '2022-06-14 14:22:00', 'shipped',   449.00),
  (2, '2023-02-20 11:00:00', 'shipped',   380.00),
  (2, '2023-02-21 11:30:00', 'returned',  380.00),
  (3, '2021-07-01 08:45:00', 'shipped',   59.00),   -- inactive customer
  (3, '2021-07-01 08:46:00', 'shipped',   59.00),   -- near-duplicate for dedup exercises
  (4, '2023-05-30 19:10:00', 'shipped',   858.00),
  (4, '2024-01-15 13:00:00', 'placed',    164.00),
  (5, '2023-08-08 12:12:00', 'shipped',   2519.00),
  (5, '2024-03-02 17:55:00', 'cancelled', NULL),
  (6, '2022-12-24 21:00:00', 'shipped',   84.00),   -- NULL city customer
  (7, '2023-06-11 10:30:00', 'shipped',   121.00),
  (7, '2023-06-12 10:30:00', 'shipped',   320.00),  -- consecutive-day orders
  (9, '2024-04-04 15:45:00', 'placed',    59.00),
  (9, '2024-04-05 15:45:00', 'placed',    120.00),
  (9, '2024-04-06 15:45:00', 'placed',    39.00);   -- 3 consecutive days, for streak problems

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
  (1, 1, 1, 1990.00),
  (1, 2, 1, 129.00),
  (3, 2, 1, 129.00),
  (4, 4, 1, 449.00),
  (5, 6, 1, 380.00),
  (6, 6, 1, 380.00),
  (7, 3, 1, 59.00),
  (8, 3, 1, 59.00),
  (9, 1, 1, 1990.00),
  (9, 7, 2, 40.00),          -- discounted unit price vs list price
  (9, 8, 1, 120.00),         -- note: 1990+80+120 = 2190 but order total says 858 (integrity trap!)
  (10, 2, 1, 129.00),
  (10, 7, 1, 35.00),
  (11, 1, 1, 1990.00),
  (11, 4, 1, 449.00),        -- 1990+449 = 2439 vs order total 2519 (another mismatch)
  (13, 3, 1, 59.00),
  (13, 7, 1, 25.00),
  (14, 8, 1, 121.00),
  (15, 5, 1, 320.00),
  (16, 3, 1, 59.00),
  (17, 8, 1, 120.00),
  (18, 9, 1, 39.00);

INSERT INTO shipments (order_id, shipped_at, delivered_at) VALUES
  (1, '2022-06-02 09:00:00', '2022-06-06 14:00:00'),
  (3, '2023-11-04 09:00:00', '2023-11-09 12:00:00'),
  (4, '2022-06-15 09:00:00', '2022-06-18 09:30:00'),
  (5, '2023-02-21 09:00:00', '2023-02-26 16:00:00'),
  (6, '2023-02-22 09:00:00', '2023-02-25 11:00:00'),
  (7, '2021-07-02 09:00:00', '2021-07-10 10:00:00'),  -- slow delivery case
  (8, '2021-07-03 09:00:00', '2021-07-05 10:00:00'),
  (9, '2023-05-31 09:00:00', NULL),                  -- still in transit
  (11, '2023-08-09 09:00:00', '2023-08-11 10:00:00'),
  (13, '2022-12-26 09:00:00', '2022-12-30 15:00:00');
  -- orders 10, 12, 14..18 have NO shipment row (recent/cancelled)

COMMIT;
