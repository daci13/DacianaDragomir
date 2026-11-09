-- Q1-Q4; Q5 procedure and Q6 trigger are demonstrated in 03.
-- AI-assisted adaptations of the supplied individual SQL examples.
USE crownfield_ro_pl_demo;

-- Q1: Which clinicians have at least one appointment?
SELECT c.Clinician_ID, CONCAT(c.First_Name, ' ', c.Last_Name) AS Clinician,
       COUNT(a.Appointment_ID) AS Appointment_Count
FROM clinician c JOIN appointment a ON a.Clinician_ID = c.Clinician_ID
GROUP BY c.Clinician_ID, c.First_Name, c.Last_Name
HAVING COUNT(a.Appointment_ID) >= 1
ORDER BY Appointment_Count DESC, Clinician;

-- Q2: Which patients are booked with which clinicians and clinics?
SELECT a.Appointment_ID, CONCAT(p.First_Name,' ',p.Last_Name) AS Patient,
       CONCAT(c.First_Name,' ',c.Last_Name) AS Clinician,
       cl.Clinic_Name, a.Appointment_Date
FROM appointment a
INNER JOIN patient p ON p.Patient_ID = a.Patient_ID
INNER JOIN clinician c ON c.Clinician_ID = a.Clinician_ID
INNER JOIN clinic cl ON cl.Clinic_ID = a.Clinic_ID
ORDER BY a.Appointment_Date, a.Appointment_ID;

-- Q3: Which appointments do not have follow-up plans?
SELECT a.Appointment_ID, a.Appointment_Date, f.Follow_Up_ID
FROM appointment a LEFT JOIN follow_up f ON f.Appointment_ID = a.Appointment_ID
WHERE f.Follow_Up_ID IS NULL
ORDER BY a.Appointment_ID;

-- Q4: Which appointments have more medicine items than the average visit?
-- The average is over ALL appointments, including those with zero items.
WITH appointment_counts AS (
 SELECT a.Appointment_ID, COUNT(pi.Prescription_Item_ID) AS Item_Count
 FROM appointment a
 LEFT JOIN prescription p ON p.Appointment_ID=a.Appointment_ID
 LEFT JOIN prescription_item pi ON pi.Prescription_ID=p.Prescription_ID
 GROUP BY a.Appointment_ID
)
SELECT Appointment_ID,Item_Count FROM appointment_counts
WHERE Item_Count > (SELECT AVG(Item_Count) FROM appointment_counts)
ORDER BY Item_Count DESC,Appointment_ID;

-- Controlled UPDATE: temporary note change is rolled back.
START TRANSACTION;
UPDATE appointment SET Notes='Temporary rollback demonstration' WHERE Appointment_ID=1;
SELECT Appointment_ID,Notes FROM appointment WHERE Appointment_ID=1;
ROLLBACK;
SELECT Appointment_ID,Notes FROM appointment WHERE Appointment_ID=1;

-- Controlled DELETE: delete only a newly inserted child row; preserve all seeds.
START TRANSACTION;
INSERT INTO diagnosis VALUES (9999,1,'Temporary test diagnosis','Transaction demo only');
DELETE FROM diagnosis WHERE Diagnosis_ID=9999;
SELECT COUNT(*) AS Remaining_Temporary_Diagnoses FROM diagnosis WHERE Diagnosis_ID=9999;
ROLLBACK;
