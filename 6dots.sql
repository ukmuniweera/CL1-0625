-- Question 1: Write SQL statements to create each of the above tables

-- Create Patients table
CREATE TABLE Patients (
    patient_id INT PRIMARY KEY,
    patient_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    phone VARCHAR(15),
    address VARCHAR(200)
);

-- Create Treatments table
CREATE TABLE Treatments (
    treatment_id INT PRIMARY KEY,
    treatment_name VARCHAR(100) NOT NULL,
    cost DECIMAL(10,2) NOT NULL,
    duration_minutes INT
);

-- Create Appointments table
CREATE TABLE Appointments (
    appointment_id INT PRIMARY KEY,
    patient_id INT,
    treatment_id INT,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    status VARCHAR(20) DEFAULT 'Scheduled',
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id),
    FOREIGN KEY (treatment_id) REFERENCES Treatments(treatment_id)
);

-- Create Treatment_Cost_Log table (for question 2.iii)
CREATE TABLE Treatment_Cost_Log (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    treatment_id INT,
    old_cost DECIMAL(10,2),
    new_cost DECIMAL(10,2),
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (treatment_id) REFERENCES Treatments(treatment_id)
);

-- Create Treatment_Stats table (for question 2.v)
CREATE TABLE Treatment_Stats (
    treatment_id INT PRIMARY KEY,
    appointment_count INT DEFAULT 0,
    FOREIGN KEY (treatment_id) REFERENCES Treatments(treatment_id)
);

-- Create Billing table (for question 3.iii)
CREATE TABLE Billing (
    billing_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT,
    treatment_id INT,
    amount DECIMAL(10,2),
    billing_date DATE,
    status VARCHAR(20) DEFAULT 'Pending',
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id),
    FOREIGN KEY (treatment_id) REFERENCES Treatments(treatment_id)
);

-- Question 2: Write SQL statements to create the following triggers

-- 2.i: BEFORE INSERT trigger on Patients table to prevent inserting patients under 18
DELIMITER //
CREATE TRIGGER check_patient_age
BEFORE INSERT ON Patients
FOR EACH ROW
BEGIN
    IF TIMESTAMPDIFF(YEAR, NEW.date_of_birth, CURDATE()) < 18 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient must be 18 years or older';
    END IF;
END//
DELIMITER ;

-- 2.ii: BEFORE DELETE trigger on Patients table to log patient info before deletion
DELIMITER //
CREATE TRIGGER log_patient_deletion
BEFORE DELETE ON Patients
FOR EACH ROW
BEGIN
    INSERT INTO Patient_Log (patient_id, full_name, deleted_timestamp)
    VALUES (OLD.patient_id, OLD.patient_name, NOW());
END//
DELIMITER ;

-- Create Patient_Log table for the above trigger
CREATE TABLE Patient_Log (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT,
    full_name VARCHAR(100),
    deleted_timestamp DATETIME
);

-- 2.iii: AFTER UPDATE trigger on Treatments table to record cost changes
DELIMITER //
CREATE TRIGGER track_cost_changes
AFTER UPDATE ON Treatments
FOR EACH ROW
BEGIN
    IF OLD.cost != NEW.cost THEN
        INSERT INTO Treatment_Cost_Log (treatment_id, old_cost, new_cost)
        VALUES (NEW.treatment_id, OLD.cost, NEW.cost);
    END IF;
END//
DELIMITER ;

-- 2.iv: BEFORE INSERT trigger on Appointments to prevent past appointments
DELIMITER //
CREATE TRIGGER check_appointment_date
BEFORE INSERT ON Appointments
FOR EACH ROW
BEGIN
    IF NEW.appointment_date < CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot schedule appointment in the past';
    END IF;
END//
DELIMITER ;

-- 2.v: AFTER INSERT trigger on Appointments to update treatment statistics
DELIMITER //
CREATE TRIGGER update_treatment_stats
AFTER INSERT ON Appointments
FOR EACH ROW
BEGIN
    INSERT INTO Treatment_Stats (treatment_id, appointment_count)
    VALUES (NEW.treatment_id, 1)
    ON DUPLICATE KEY UPDATE appointment_count = appointment_count + 1;
END//
DELIMITER ;

-- Question 3: Write SQL statements to create transactions

-- 3.i: Transaction to book two appointments for same patient on same day
START TRANSACTION;

INSERT INTO Appointments (appointment_id, patient_id, treatment_id, appointment_date, appointment_time, status)
VALUES (101, 1, 1, '2025-07-01', '09:00:00', 'Scheduled');

INSERT INTO Appointments (appointment_id, patient_id, treatment_id, appointment_date, appointment_time, status)
VALUES (102, 1, 2, '2025-07-01', '11:00:00', 'Scheduled');

COMMIT;

-- 3.ii: Transaction to insert new patient and schedule their first appointment
START TRANSACTION;

INSERT INTO Patients (patient_id, patient_name, date_of_birth, phone, address)
VALUES (201, 'John Smith', '1990-05-15', '555-0123', '123 Main St');

INSERT INTO Appointments (appointment_id, patient_id, treatment_id, appointment_date, appointment_time, status)
VALUES (201, 201, 1, '2025-07-02', '10:00:00', 'Scheduled');

COMMIT;

-- 3.iii: Transaction to add billing record and deduct from patient account
START TRANSACTION;

-- Assume patients have an account_balance field
ALTER TABLE Patients ADD COLUMN account_balance DECIMAL(10,2) DEFAULT 0.00;

-- Insert billing record
INSERT INTO Billing (patient_id, treatment_id, amount, billing_date, status)
VALUES (1, 1, 150.00, CURDATE(), 'Charged');

-- Deduct from patient's account
UPDATE Patients 
SET account_balance = account_balance - 150.00 
WHERE patient_id = 1;

-- Check if balance is sufficient
IF (SELECT account_balance FROM Patients WHERE patient_id = 1) < 0 THEN
    ROLLBACK;
    SELECT 'Transaction rolled back: Insufficient balance' AS message;
ELSE
    COMMIT;
    SELECT 'Transaction completed successfully' AS message;
END IF;

-- 3.iv: Transaction to delete treatment and all associated appointments
START TRANSACTION;

DELETE FROM Appointments WHERE treatment_id = 5;
DELETE FROM Treatments WHERE treatment_id = 5;

COMMIT;

-- 3.v: Transaction with SAVEPOINT for partial rollback scenario
START TRANSACTION;

-- Set savepoint before billing operations
SAVEPOINT billing_start;

-- Insert billing records for all three treatments
INSERT INTO Billing (patient_id, treatment_id, amount, billing_date, status)
VALUES (1, 1, 100.00, CURDATE(), 'Processed');

INSERT INTO Billing (patient_id, treatment_id, amount, billing_date, status)
VALUES (1, 2, 150.00, CURDATE(), 'Processed');

-- This treatment might fail due to cost limit or stock unavailability
INSERT INTO Billing (patient_id, treatment_id, amount, billing_date, status)
VALUES (1, 3, 200.00, CURDATE(), 'Failed');

-- Rollback only the failed treatment
ROLLBACK TO SAVEPOINT billing_start;

-- Re-insert only the successful treatments
INSERT INTO Billing (patient_id, treatment_id, amount, billing_date, status)
VALUES (1, 1, 100.00, CURDATE(), 'Processed');

INSERT INTO Billing (patient_id, treatment_id, amount, billing_date, status)
VALUES (1, 2, 150.00, CURDATE(), 'Processed');

-- Commit the successful transactions
COMMIT;