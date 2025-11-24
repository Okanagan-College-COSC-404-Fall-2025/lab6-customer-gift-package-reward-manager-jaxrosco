[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/OeWihA70)
# Lab6: Customer Gift Package Reward Manager (Nested Tables + Packages + CASE)
In this lab, we aim to work on the Customer-Order database that we installed in lab2. The schema of this database is provided in this assignment. You will need to use this schema in order to complete the lab. 


### Schema Diagram

```mermaid
---
title: CO schema
config:
  layout: elk
---
erDiagram
  CUSTOMERS ||--o{  ORDERS      : have
  CUSTOMERS ||--o{  SHIPMENTS   : have
  STORES    ||--o{  ORDERS      : have
  STORES    ||--o{  SHIPMENTS   : have
  STORES    ||--o{  INVENTORY   : have
  ORDERS    ||--|{  ORDER_ITEMS : have
  SHIPMENTS ||--|{  ORDER_ITEMS : have
  PRODUCTS  ||--o{  ORDER_ITEMS : have
  PRODUCTS  ||--o{  INVENTORY   : have

  CUSTOMERS {
    interger       customer_id    PK
    varchar2(255)  email_address  UK "NN"
    varchar2(255)  full_name         "NN"
  }

  STORES {
    integer        store_id            PK
    varchar2(255)  store_name          UK "NN"
    varchar2(100)  web_address
    varchar2(512)  physical_address
    number(9)      latitude
    number(9)      longitude
    blob           logo
    varchar2(512)  logo_mime_type
    varchar2(512)  logo_filename
    varchar2(512)  logo_charset
    date           logo_last_updated
  }

  PRODUCTS {
    interger       product_id         PK
    varchar2(255)  product_name          "NN"
    number(10)     unit_price
    blob           product_details
    blob           product_image
    varchar2(512)  image_mime_type
    varchar2(512)  image_filename
    varchar2(512)  image_charset
    date           image_last_updated
  }

  ORDERS {
    integer      order_id       PK
    timestamp    order_tms         "NN"
    interger     customer_id    FK "NN"
    varchar2(10) order_status      "NN"
    integer      store_id       FK "NN"
  }

  SHIPMENTS {
    integer        shipment_id       PK
    integer        store_id          FK "NN"
    integer        customer_id       FK "NN"
    varchar2(512)  delivery_address     "NN"
    varchar2(100)  shipment_status      "NN"
  }

  ORDER_ITEMS {
    integer   order_id      PK "FK, NN"
    integer   line_item_id  PK "NN"
    integer   product_id    FK "NN"
    integer   unit_price    "NN"
    integer   quantity      "NN"
    integer   shipment_id   FK
  }

  INVENTORY {
    integer    inventory_id       PK
    integer    store_id           FK "NN"
    integer    product_id         FK "NN"
  integer      product_inventory     "NN"
}
```
## Part A — Create Gift Types and GIFT_CATALOG Table (Nested Tables)
(8 marks)
1.	Create a nested table type to store multiple gift items (e.g., 'Teddy Bear', 'Chocolate Box').
2.	Create a table GIFT_CATALOG with the following columns:
     - GIFT_ID (NUMBER)— PRIMARY KEY
     - MIN_PURCHASE (NUMBER) — the minimum purchase amount to qualify for the gift package
     - a nested table of gift items (use the type created above)
3. Configure nested table storage:
```
NESTED TABLE gifts STORE AS <your_storage_table>;
```
4. Insert at least three gift packages, each containing multiple gift items.

**Example rows (You can insert your own values in this table)** 
  	
| GIFT_ID | MIN_PURCHASE | GIFTS (nested table) |
|---------|--------------|-----------------------|
| 1       | 100           | { 'Stickers', 'Pen Set' } |
| 2       | 1000           | { 'Teddy Bear', 'Mug', 'Perfume Sample' } |
| 3       | 10000           | { 'Backpack', 'Thermos Bottle', 'Chocolate Collection' } |

## Part B — Create CUSTOMER_REWARDS Table (Nested Table + Foreign Key)
(3 marks)

Create a table CUSTOMER_REWARDS:
-	REWARD_ID — primary key (identity or sequence)
-	CUSTOMER_EMAIL — customer email from CUSTOMERS
-	GIFT_ID — FOREIGN KEY referencing GIFT_CATALOG(GIFT_ID)
-	REWARD_DATE — defaults to SYSDATE

**This table will be populated by a function that you will implement in this lab**

**Example**

| REWARD_ID | CUSTOMER_EMAIL     | GIFT_ID | REWARD_DATE |
|-----------|--------------------|---------|--------------|
| 101       | alice@example.com  | 2       | 2025-11-12   |
| 102       | bob@example.org    | 1       | 2025-11-12   |
| 103       | charlie@domain.com | 3       | 2025-11-12   |


## Part C — Package CUSTOMER_MANAGER Using the CO Schema

(14 marks)

Create a PL/SQL package named CUSTOMER_MANAGER that assigns gift packages to customers based on the total value of their completed orders.

Your package must work directly with the CO schema shown above. Your package needs to have the following features

1. A public function `GET_TOTAL_PURCHASE(customer_id)`: The function accepts a customer ID and returns the total value of all purchases made by that customer. 
2. A private function `CHOOSE_GIFT_PACKAGE(p_total_purchase)`:
   **Requirements:**
   - Use a CASE expression or CASE logic
   - Select the gift package from GIFT_CATALOG where:
     `MIN_PURCHASE is the largest value <= p_total_purchase`
   - Return the GIFT_ID of the chosen package.
   - If no package applies, return NULL.
3. a public procedure `ASSIGN_GIFTS_TO_ALL`:
   **Requirements**
   For each customer in **CUSTOMERS:**
   1. Compute total purchase (use your function)
   2. Select a suitable gift package (via GIFT_ID returned by your function)
   3. Insert into CUSTOMER_REWARDS:
        -  	customer email
        -  	gift_id
        -  	reward date (current data)

## Part D: Test Package:
(5 marks)

Implement a procedure that joins the `CUSTOMER_REWARDS` and `GIFT_CATALOG` tables and displays the results for the first five customers. Capture a screenshot of the output.

## Submssion
Make a directory named scripts and place all your SQL scripts inside it. Additionally, create another directory named screenshots and include the screenshot for Part D in that folder. Push your submission to the remote repository. Finally, submit the link to your repository in the Moodle assignment.
  


