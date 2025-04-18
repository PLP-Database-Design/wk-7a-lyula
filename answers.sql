-- answers.sql

-- Assuming we have a table named ProductDetail with columns OrderID, CustomerName, and Products
-- where Products is a comma-separated string of product names.

-- To achieve 1NF in MySQL, we need to split the comma-separated 'Products'
-- into separate rows. This can be done using a combination of functions
-- and a numbers table (or a similar approach to generate a sequence).

-- First, we need a numbers table .
-- This table simply contains a sequence of integers: 1, 2, 3, ...


CREATE TABLE IF NOT EXISTS numbers (n INT UNSIGNED NOT NULL PRIMARY KEY);
INSERT IGNORE INTO numbers (n) VALUES
(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),
(11),(12),(13),(14),(15),(16),(17),(18),(19),(20);
-- You can insert more numbers as needed based on the maximum
-- number of products you expect in a single row.


-- Now, the query to transform the ProductDetail table to 1NF:
SELECT
    pd.OrderID,
    pd.CustomerName,
    SUBSTRING_INDEX(SUBSTRING_INDEX(pd.Products, ',', n.n), ',', -1) AS Product
FROM
    ProductDetail pd
CROSS JOIN
    numbers n ON CHAR_LENGTH(pd.Products) - CHAR_LENGTH(REPLACE(pd.Products, ',', '')) >= n.n - 1
WHERE
    SUBSTRING_INDEX(SUBSTRING_INDEX(pd.Products, ',', n.n), ',', -1) <> '';

-- Explanation:

-- 1. `FROM ProductDetail pd CROSS JOIN numbers n`:
--    This performs a cross join between  ProductDetail table and the numbers table.
--    For each row in ProductDetail, it will be combined with each row in the numbers table.

-- 2. `ON CHAR_LENGTH(pd.Products) - CHAR_LENGTH(REPLACE(pd.Products, ',', '')) >= n.n - 1`:
--    This is the join condition that helps us determine how many times to split the 'Products' string for each row.
--    - `CHAR_LENGTH(pd.Products)` gets the total length of the 'Products' string.
--    - `CHAR_LENGTH(REPLACE(pd.Products, ',', ''))` gets the length of the string after removing all commas.
--    - The difference between these two lengths gives the number of commas, which is one less than the number of products.
--    - `n.n - 1` represents the index of the comma we are currently considering (0 for the first product, 1 for the second, etc.).
--    - The condition ensures that we generate enough rows from the numbers table to cover all the products in the 'Products' string.

-- 3. `SUBSTRING_INDEX(SUBSTRING_INDEX(pd.Products, ',', n.n), ',', -1) AS Product`:
--    This is the core part that extracts each individual product:
--    - `SUBSTRING_INDEX(pd.Products, ',', n.n)`: This extracts the substring of 'Products' up to the nth comma.
--    - `SUBSTRING_INDEX(..., ',', -1)`: This then extracts the substring after the last comma in the result of the previous `SUBSTRING_INDEX`, effectively giving us the nth product.

-- 4. `WHERE SUBSTRING_INDEX(SUBSTRING_INDEX(pd.Products, ',', n.n), ',', -1) <> ''`:
--    This `WHERE` clause filters out any empty strings that might result if there are consecutive commas or a comma at the beginning or end of the 'Products' string.




-- Question 2

-- Assuming we have a table named OrderDetails with columns OrderID, CustomerName, Product, and Quantity.
-- The primary key of this table is likely a composite key (OrderID, Product) since a single order can have multiple products.

-- To achieve 2NF, we need to remove the partial dependency where CustomerName depends only on OrderID,
-- not on the entire primary key (OrderID, Product).

-- We will create two tables:
-- 1. Orders: This table will store information about each order, with OrderID as the primary key
--            and CustomerName as a non-key attribute.
-- 2. OrderItems: This table will store the details of each product in an order, with (OrderID, Product)
--               as the composite primary key and Quantity as a non-key attribute.

-- Step 1: Create the Orders table
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    CustomerName VARCHAR(255)
);

-- Step 2: Populate the Orders table with distinct OrderIDs and their corresponding CustomerNames
INSERT INTO Orders (OrderID, CustomerName)
SELECT DISTINCT OrderID, CustomerName
FROM OrderDetails;

-- Step 3: Create the OrderItems table
CREATE TABLE OrderItems (
    OrderID INT,
    Product VARCHAR(255),
    Quantity INT,
    PRIMARY KEY (OrderID, Product),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
);

-- Step 4: Populate the OrderItems table with OrderID, Product, and Quantity
INSERT INTO OrderItems (OrderID, Product, Quantity)
SELECT OrderID, Product, Quantity
FROM OrderDetails;

-- Result of the transformation:

-- The original OrderDetails table is now decomposed into two tables: Orders and OrderItems.

-- Orders Table:
-- | OrderID | CustomerName |
-- |---------|--------------|
-- | 101     | John Doe     |
-- | 102     | Jane Smith   |
-- | 103     | Emily Clark  |

-- OrderItems Table:
-- | OrderID | Product  | Quantity |
-- |---------|----------|----------|
-- | 101     | Laptop   | 2        |
-- | 101     | Mouse    | 1        |
-- | 102     | Tablet   | 3        |
-- | 102     | Keyboard | 1        |
-- | 102     | Mouse    | 2        |
-- | 103     | Phone    | 1        |

-- Now, in the Orders table, CustomerName fully depends on the primary key OrderID.
-- In the OrderItems table, Quantity fully depends on the composite primary key (OrderID, Product).
-- This structure satisfies the requirements of the Second Normal Form (2NF).

-- To retrieve the original information , we can use a JOIN query:
SELECT
    o.OrderID,
    o.CustomerName,
    oi.Product,
    oi.Quantity
FROM
    Orders o
JOIN
    OrderItems oi ON o.OrderID = oi.OrderID;