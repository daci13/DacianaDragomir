-- Q5: patient-history procedure with input parameter.
-- Q6: appointment-status audit trigger with rollback demonstration.
USE crownfield_ro_pl_demo;
-- INVOKER means callers require SELECT rights on appointment and clinic.
DROP PROCEDURE IF EXISTS GetPatientAppointments;
DELIMITER $$
CREATE PROCEDURE GetPatientAppointments(IN p_patient_id VARCHAR(10))
SQL SECURITY INVOKER
READS SQL DATA
BEGIN
  SELECT a.Appointment_ID, a.Appointment_Date, a.Appointment_Time,
         a.Status, cl.Clinic_Name
  FROM appointment a
  JOIN clinic cl ON cl.Clinic_ID = a.Clinic_ID
  WHERE a.Patient_ID = p_patient_id
  ORDER BY a.Appointment_Date, a.Appointment_Time;
END$$
DELIMITER ;
CALL GetPatientAppointments('OP001');

DROP TRIGGER IF EXISTS trg_appointment_status_audit;
DELIMITER $$
CREATE TRIGGER trg_appointment_status_audit
AFTER UPDATE ON appointment
FOR EACH ROW
BEGIN
  IF NOT (OLD.Status <=> NEW.Status) THEN
    INSERT INTO appointment_status_audit (Appointment_ID, Old_Status, New_Status)
    VALUES (NEW.Appointment_ID, OLD.Status, NEW.Status);
  END IF;
END$$
DELIMITER ;

-- Demonstrate the trigger inside a rolled-back transaction.
START TRANSACTION;
UPDATE appointment SET Status = 'Completed' WHERE Appointment_ID = 1;
SELECT * FROM appointment_status_audit WHERE Appointment_ID = 1 ORDER BY Audit_ID DESC;
ROLLBACK;


SELECT Appointment_ID,Status AS Status_After_Rollback FROM appointment WHERE Appointment_ID=1;
SELECT COUNT(*) AS Audit_Rows_After_Rollback FROM appointment_status_audit WHERE Appointment_ID=1;

-- A cross-table date rule cannot be expressed as a MySQL CHECK.
-- Reject follow-ups before their appointment, on both INSERT and UPDATE.
DROP TRIGGER IF EXISTS trg_followup_date_insert;
DROP TRIGGER IF EXISTS trg_followup_date_update;
DROP TRIGGER IF EXISTS trg_prescription_date_insert;
DROP TRIGGER IF EXISTS trg_prescription_date_update;
DROP TRIGGER IF EXISTS trg_appointment_date_update;
DROP TRIGGER IF EXISTS trg_patient_dob_insert;
DROP TRIGGER IF EXISTS trg_patient_dob_update;
DELIMITER $$
CREATE TRIGGER trg_followup_date_insert BEFORE INSERT ON follow_up FOR EACH ROW
BEGIN
 IF NEW.Follow_Up_Date < (SELECT Appointment_Date FROM appointment WHERE Appointment_ID=NEW.Appointment_ID) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Follow-up cannot precede appointment';
 END IF;
END$$
CREATE TRIGGER trg_followup_date_update BEFORE UPDATE ON follow_up FOR EACH ROW
BEGIN
 IF NEW.Follow_Up_Date < (SELECT Appointment_Date FROM appointment WHERE Appointment_ID=NEW.Appointment_ID) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Follow-up cannot precede appointment';
 END IF;
END$$
CREATE TRIGGER trg_prescription_date_insert BEFORE INSERT ON prescription FOR EACH ROW
BEGIN
 IF NEW.Issued_Date < (SELECT Appointment_Date FROM appointment WHERE Appointment_ID=NEW.Appointment_ID) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Issue date cannot precede appointment';
 END IF;
END$$
CREATE TRIGGER trg_prescription_date_update BEFORE UPDATE ON prescription FOR EACH ROW
BEGIN
 IF NEW.Issued_Date < (SELECT Appointment_Date FROM appointment WHERE Appointment_ID=NEW.Appointment_ID) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Issue date cannot precede appointment';
 END IF;
END$$
-- Guard the parent side as well: documented visit dates are immutable.
CREATE TRIGGER trg_appointment_date_update BEFORE UPDATE ON appointment FOR EACH ROW
BEGIN
 IF NOT (OLD.Appointment_Date <=> NEW.Appointment_Date) AND
  (EXISTS(SELECT 1 FROM diagnosis WHERE Appointment_ID=OLD.Appointment_ID)
   OR EXISTS(SELECT 1 FROM prescription WHERE Appointment_ID=OLD.Appointment_ID)
   OR EXISTS(SELECT 1 FROM follow_up WHERE Appointment_ID=OLD.Appointment_ID)) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Create a new booking rather than redate a documented visit';
 END IF;
END$$
CREATE TRIGGER trg_patient_dob_insert BEFORE INSERT ON patient FOR EACH ROW
BEGIN
 IF NEW.Date_Of_Birth > CURRENT_DATE() THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Date of birth cannot be in the future';
 END IF;
END$$
CREATE TRIGGER trg_patient_dob_update BEFORE UPDATE ON patient FOR EACH ROW
BEGIN
 IF NEW.Date_Of_Birth > CURRENT_DATE() THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Date of birth cannot be in the future';
 END IF;
END$$
DELIMITER ;
