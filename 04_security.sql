-- CPU4:103 Part D: least privilege, assigned roles and data protection.
-- Run after 01 -> 02 -> 03, as a LOCAL MySQL administrator.
-- Creates only crownfield_* demonstration roles/accounts. Accounts are LOCKED.
-- Do not run on a server where these names are used by an unrelated application.
USE crownfield_ro_pl_demo;

-- A high-entropy synthetic patient-linked token: retain ONLY its SHA-256 digest.
-- This illustrates token protection, NOT password hashing or medical-record encryption.
-- For real passwords use salted Argon2id/bcrypt/scrypt in an application.
SET @training_token = HEX(RANDOM_BYTES(32));
INSERT INTO demo_protected_token (Token_ID, Patient_ID, Token_Hash)
VALUES (1, 'OP001', SHA2(@training_token,256))
ON DUPLICATE KEY UPDATE Token_Hash = SHA2(@training_token,256);
SELECT Token_ID, Patient_ID, Token_Hash,
       CHAR_LENGTH(Token_Hash) AS Hash_Length,
       (Token_Hash = SHA2(@training_token,256)) AS Hash_Matches_Input
FROM demo_protected_token WHERE Token_ID=1;
SET @training_token = NULL;

CREATE ROLE IF NOT EXISTS 'crownfield_admin', 'crownfield_doctor',
                          'crownfield_receptionist', 'crownfield_patient';
-- Scope administrator power to this fictional database, not the whole server.
GRANT ALL PRIVILEGES ON crownfield_ro_pl_demo.* TO 'crownfield_admin';

GRANT SELECT ON crownfield_ro_pl_demo.patient TO 'crownfield_doctor';
GRANT SELECT ON crownfield_ro_pl_demo.appointment TO 'crownfield_doctor';
GRANT UPDATE (Status, Notes) ON crownfield_ro_pl_demo.appointment TO 'crownfield_doctor';
GRANT SELECT ON crownfield_ro_pl_demo.clinic TO 'crownfield_doctor';
GRANT SELECT ON crownfield_ro_pl_demo.clinician TO 'crownfield_doctor';
GRANT SELECT ON crownfield_ro_pl_demo.specialty TO 'crownfield_doctor';
GRANT SELECT ON crownfield_ro_pl_demo.medicine TO 'crownfield_doctor';
GRANT SELECT, INSERT, UPDATE, DELETE ON crownfield_ro_pl_demo.diagnosis TO 'crownfield_doctor';
GRANT SELECT, INSERT, UPDATE ON crownfield_ro_pl_demo.prescription TO 'crownfield_doctor';
GRANT SELECT, INSERT, UPDATE ON crownfield_ro_pl_demo.prescription_item TO 'crownfield_doctor';
GRANT SELECT, INSERT, UPDATE ON crownfield_ro_pl_demo.follow_up TO 'crownfield_doctor';
GRANT EXECUTE ON PROCEDURE crownfield_ro_pl_demo.GetPatientAppointments TO 'crownfield_doctor';

GRANT SELECT, INSERT, UPDATE ON crownfield_ro_pl_demo.patient TO 'crownfield_receptionist';
GRANT SELECT, INSERT, UPDATE, DELETE ON crownfield_ro_pl_demo.appointment TO 'crownfield_receptionist';
GRANT SELECT ON crownfield_ro_pl_demo.clinic TO 'crownfield_receptionist';
GRANT SELECT ON crownfield_ro_pl_demo.clinician TO 'crownfield_receptionist';

-- This deliberately limited view contains no identifying or clinical patient data.
-- DEFINER permits use of this public projection without granting the clinic table.
CREATE OR REPLACE SQL SECURITY DEFINER VIEW public_clinic_directory AS
SELECT Clinic_Name, City, Country FROM clinic;
GRANT SELECT ON crownfield_ro_pl_demo.public_clinic_directory TO 'crownfield_patient';
-- MySQL roles alone do not implement per-patient row-level record access.
-- The patient role is not allowed to read the patient table or call the procedure.

-- No real credentials are included. Locked accounts cannot authenticate.
CREATE USER IF NOT EXISTS 'crownfield_admin_demo'@'localhost' ACCOUNT LOCK;
CREATE USER IF NOT EXISTS 'crownfield_doctor_demo'@'localhost' ACCOUNT LOCK;
CREATE USER IF NOT EXISTS 'crownfield_receptionist_demo'@'localhost' ACCOUNT LOCK;
CREATE USER IF NOT EXISTS 'crownfield_patient_demo'@'localhost' ACCOUNT LOCK;
GRANT 'crownfield_admin' TO 'crownfield_admin_demo'@'localhost';
GRANT 'crownfield_doctor' TO 'crownfield_doctor_demo'@'localhost';
GRANT 'crownfield_receptionist' TO 'crownfield_receptionist_demo'@'localhost';
GRANT 'crownfield_patient' TO 'crownfield_patient_demo'@'localhost';
SET DEFAULT ROLE 'crownfield_admin' TO 'crownfield_admin_demo'@'localhost';
SET DEFAULT ROLE 'crownfield_doctor' TO 'crownfield_doctor_demo'@'localhost';
SET DEFAULT ROLE 'crownfield_receptionist' TO 'crownfield_receptionist_demo'@'localhost';
SET DEFAULT ROLE 'crownfield_patient' TO 'crownfield_patient_demo'@'localhost';

SHOW GRANTS FOR 'crownfield_admin';
SHOW GRANTS FOR 'crownfield_doctor';
SHOW GRANTS FOR 'crownfield_receptionist';
SHOW GRANTS FOR 'crownfield_patient';
SHOW GRANTS FOR 'crownfield_doctor_demo'@'localhost' USING 'crownfield_doctor';
SELECT User,Host,account_locked FROM mysql.user WHERE User IN
('crownfield_admin_demo','crownfield_doctor_demo','crownfield_receptionist_demo','crownfield_patient_demo')
ORDER BY User;

-- OPTIONAL SECURE-CODING EXAMPLE (run in an authenticated client session).
-- Bound data is never concatenated into SQL syntax, even if it contains quotes.
SET @safe_sql = 'SELECT Appointment_ID, Appointment_Date, Status FROM crownfield_ro_pl_demo.appointment WHERE Patient_ID = ? ORDER BY Appointment_Date, Appointment_ID';
PREPARE safe_lookup FROM @safe_sql;
SET @patient_input = 'OP001';
EXECUTE safe_lookup USING @patient_input;
-- SQL-injection-looking input is treated as a literal patient ID: returns no rows.
SET @patient_input = 'OP001'' OR ''1''=''1';
EXECUTE safe_lookup USING @patient_input;
DEALLOCATE PREPARE safe_lookup;
SET @safe_sql=NULL;
SET @patient_input=NULL;
