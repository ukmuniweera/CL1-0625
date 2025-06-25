-- Start MySQL
mysql -u root -p

-- Create and use the database
CREATE DATABASE Stocks;
USE Stocks;

-- Create tables
CREATE TABLE Products (
    Maker VARCHAR(20),
    Model INT NOT NULL PRIMARY KEY,
    Type VARCHAR(20)  
);

CREATE TABLE Laptops (
    LT_Model INT NOT NULL PRIMARY KEY,
    LT_Speed INT,
    LT_RAM INT,
    LT_HD INT,
    Screen DECIMAL(5,3),
    LT_Price INT,
    FOREIGN KEY(LT_Model) REFERENCES Products(Model)
);

CREATE TABLE Personal_Computers (
    PC_Model INT NOT NULL PRIMARY KEY,
    PC_Speed INT,
    PC_RAM INT,
    PC_HD INT,
    CD_ROM VARCHAR(20),
    PC_Price INT,
    FOREIGN KEY(PC_Model) REFERENCES Products(Model)
);

CREATE TABLE Printers (
    PR_Model INT NOT NULL PRIMARY KEY,
    Colour VARCHAR(20),
    PR_Type VARCHAR(20),
    PR_Price INT,
    FOREIGN KEY(PR_Model) REFERENCES Products(Model)   
);

-- Insert data into Products
INSERT INTO Products (Maker, Model, Type) VALUES
('A', 1001, 'PC'), ('A', 1002, 'PC'), ('A', 1003, 'PC'),
('A', 2004, 'Laptop'), ('A', 2005, 'Laptop'), ('A', 2006, 'Laptop'),
('B', 1004, 'PC'), ('B', 1005, 'PC'), ('B', 1006, 'PC'),
('B', 2001, 'Laptop'), ('B', 2002, 'Laptop'), ('B', 2003, 'Laptop'),
('C', 1007, 'PC'), ('C', 1008, 'PC'), ('C', 2008, 'Laptop'),
('C', 2009, 'Laptop'), ('C', 3002, 'Printer'), ('C', 3003, 'Printer'),
('C', 3006, 'Printer'), ('D', 1009, 'PC'), ('D', 1010, 'PC'),
('D', 1011, 'PC'), ('D', 2007, 'Laptop'), ('E', 1012, 'PC'),
('E', 1013, 'PC'), ('E', 2010, 'Laptop'), ('F', 3001, 'Printer'),
('F', 3004, 'Printer'), ('G', 3005, 'Printer'), ('H', 3007, 'Printer');

-- Insert into Personal_Computers
INSERT INTO Personal_Computers (PC_Model, PC_Speed, PC_RAM, PC_HD, CD_ROM, PC_Price) VALUES
(1001, 700, 64, 10, '48XCD', 799), (1002, 1500, 128, 60, '12XCD', 2499),
(1003, 866, 128, 20, '8XCD', 1999), (1004, 866, 64, 10, '12XCD', 999),
(1005, 1000, 128, 20, '12XCD', 1499), (1006, 1300, 256, 40, '16XCD', 2119),
(1007, 1400, 128, 80, '12XCD', 2299), (1008, 700, 64, 30, '24XCD', 999),
(1009, 1200, 128, 80, '16XCD', 1699), (1010, 750, 64, 30, '40XCD', 699),
(1011, 1100, 128, 60, '16XCD', 1299), (1012, 350, 64, 7, '48XCD', 799),
(1013, 733, 256, 60, '12XCD', 2499);

-- Insert into Laptops
INSERT INTO Laptops (LT_Model, LT_Speed, LT_RAM, LT_HD, Screen, LT_Price) VALUES
(2001, 700, 64, 5, 12.1, 1448), (2002, 800, 96, 10, 15.1, 2584),
(2003, 850, 64, 10, 15.1, 2738), (2004, 550, 32, 5, 12.1, 999),
(2005, 600, 64, 6, 12.1, 2399), (2006, 800, 96, 20, 15.7, 2999),
(2007, 850, 128, 20, 15.0, 3099), (2008, 650, 64, 10, 12.1, 1249),
(2009, 750, 256, 20, 15.1, 2599), (2010, 366, 64, 10, 12.1, 1499);

-- Insert into Printers
INSERT INTO Printers (PR_Model, Colour, PR_Type, PR_Price) VALUES
(3001, 'true', 'ink-jet', 231), (3002, 'true', 'ink-jet', 267),
(3003, 'false', 'laser', 390), (3004, 'true', 'ink-jet', 439),
(3005, 'true', 'bubble', 200), (3006, 'true', 'laser', 1999),
(3007, 'false', 'laser', 350);

-- Transaction Queries
START TRANSACTION;

-- 1: Laptops with speed > 600
SELECT * FROM Laptops WHERE LT_Speed > 600;

-- 2: Laptops with 64MB RAM
SELECT * FROM Laptops WHERE LT_RAM = 64;

-- 3: Maker and Type of cheapest Laptop
SELECT P.Maker, P.Type
FROM Products P
JOIN Laptops L ON P.Model = L.LT_Model
WHERE L.LT_Price = (SELECT MIN(LT_Price) FROM Laptops);

-- 4: Most expensive PC
SELECT * FROM Personal_Computers P1
JOIN Products P2 ON P1.PC_Model = P2.Model
WHERE P1.PC_Price = (SELECT MAX(PC_Price) FROM Personal_Computers);

-- 5: Colour Printers
SELECT PR_Model, PR_Price FROM Printers WHERE Colour = 'true';

-- 6: Makers of Laptops
SELECT DISTINCT Maker FROM Products WHERE Type = 'laptop';

-- 7: Makers of Printers
SELECT DISTINCT Maker FROM Products WHERE Type = 'printer';

-- 8: Maker of fastest Laptop
SELECT P.Maker
FROM Products P
JOIN Laptops L ON P.Model = L.LT_Model
WHERE L.LT_Speed = (SELECT MAX(LT_Speed) FROM Laptops);

-- 9: Most expensive and fastest PC maker
SELECT P2.Maker, P1.PC_Price
FROM Personal_Computers P1
JOIN Products P2 ON P1.PC_Model = P2.Model
WHERE P1.PC_Speed = (SELECT MAX(PC_Speed) FROM Personal_Computers);

-- 10: RAM of cheapest PC
SELECT PC_RAM
FROM Personal_Computers
WHERE PC_Price = (SELECT MIN(PC_Price) FROM Personal_Computers);

COMMIT;

-- Trigger Exercises

-- Trigger 1: Validate RAM size
CREATE TABLE PersonalComputers (
  PC_Model INT PRIMARY KEY,
  PC_Speed INT,
  PC_RAM INT,
  PC_HD INT,
  CD_ROM VARCHAR(10),
  PC_Price DECIMAL(10,2)
);

DELIMITER //
CREATE TRIGGER check_pc_ram
BEFORE INSERT ON PersonalComputers
FOR EACH ROW
BEGIN
    IF NEW.PC_RAM NOT IN (64, 128, 256) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid RAM size. Only 64, 128, or 256 allowed.';
    END IF;
END;
//
DELIMITER ;

-- Test trigger
INSERT INTO PersonalComputers VALUES (1014, 600, 32, 8, '48XCD', 699); -- Invalid
INSERT INTO PersonalComputers VALUES (1015, 800, 64, 10, '48XCD', 1799); -- Valid

-- Trigger 2: Price change log
CREATE TABLE Printers_Logs (
  PR_Model INT NOT NULL PRIMARY KEY,
  Old_PR_Price INT
);

DELIMITER //
CREATE TRIGGER update_printer_price
BEFORE UPDATE ON Printers
FOR EACH ROW
BEGIN 
    INSERT INTO Printers_Logs (PR_Model, Old_PR_Price)
    VALUES (OLD.PR_Model, OLD.PR_Price);
    SET NEW.PR_Price = OLD.PR_Price * 2;
END;
//
DELIMITER ;

-- Test trigger
UPDATE Printers SET PR_Price = PR_Price WHERE PR_Model = 3003;

-- Trigger 3: Log deleted printer
CREATE TABLE Deleted_Printers (
  PR_Model INT PRIMARY KEY,
  Colour VARCHAR(10),
  PR_Type VARCHAR(20),
  PR_Price DECIMAL(10,2)
);

DELIMITER //
CREATE TRIGGER Deleted_Printers_Log
BEFORE DELETE ON Printers
FOR EACH ROW
BEGIN
    INSERT INTO Deleted_Printers(PR_Model, Colour, PR_Type, PR_Price)
    VALUES(OLD.PR_Model, OLD.Colour, OLD.PR_Type, OLD.PR_Price);
END;
//
DELIMITER ;

-- Test trigger
DELETE FROM Printers WHERE PR_Model = 3003;
