-- CPU4:103 Crownfield Eye Hospital: fictional teaching prototype.
-- Adapted from the user-supplied SQL with AI assistance. See README attribution.
-- WARNING: destructive reset of the dedicated crownfield_ro_pl_demo database.
-- MySQL 8.0.16+; MySQL 8.4 recommended. Not compatible with MariaDB.
DROP DATABASE IF EXISTS crownfield_ro_pl_demo;
CREATE DATABASE crownfield_ro_pl_demo CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE crownfield_ro_pl_demo;
SET NAMES utf8mb4;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION,ONLY_FULL_GROUP_BY';

-- patient
CREATE TABLE `patient` (
  `Patient_ID` varchar(10) NOT NULL,
  `First_Name` varchar(60) NOT NULL,
  `Last_Name` varchar(60) NOT NULL,
  `Date_Of_Birth` date DEFAULT NULL,
  `Phone` varchar(25) DEFAULT NULL,
  `Email` varchar(120) DEFAULT NULL,
  `City` varchar(80) DEFAULT NULL,
  `Postcode` varchar(10) DEFAULT NULL,
  CONSTRAINT chk_patient_dob CHECK (Date_Of_Birth IS NULL OR Date_Of_Birth BETWEEN '1900-01-01' AND '2100-12-31'),
  PRIMARY KEY (`Patient_ID`),
  UNIQUE KEY `Email` (`Email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- specialty
CREATE TABLE `specialty` (
  `Specialty_ID` int NOT NULL,
  `Specialty_Name` varchar(100) NOT NULL,
  PRIMARY KEY (`Specialty_ID`),
  UNIQUE KEY `Specialty_Name` (`Specialty_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- clinician
CREATE TABLE `clinician` (
  `Clinician_ID` int NOT NULL,
  `First_Name` varchar(60) NOT NULL,
  `Last_Name` varchar(60) NOT NULL,
  `Specialty_ID` int DEFAULT NULL,
  `Email` varchar(120) DEFAULT NULL,
  PRIMARY KEY (`Clinician_ID`),
  UNIQUE KEY `Email` (`Email`),
  KEY `fk_clinician_specialty` (`Specialty_ID`),
  CONSTRAINT `fk_clinician_specialty` FOREIGN KEY (`Specialty_ID`) REFERENCES `specialty` (`Specialty_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- clinic
CREATE TABLE `clinic` (
  `Clinic_ID` int NOT NULL,
  `Clinic_Name` varchar(120) NOT NULL,
  `Hospital_Name` varchar(140) NOT NULL,
  `City` varchar(80) NOT NULL,
  `Country` varchar(40) NOT NULL,
  PRIMARY KEY (`Clinic_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- medicine
CREATE TABLE `medicine` (
  `Medicine_ID` int NOT NULL,
  `Medicine_Name` varchar(100) NOT NULL,
  `Form` varchar(50) NOT NULL,
  PRIMARY KEY (`Medicine_ID`),
  UNIQUE KEY `Medicine_Name` (`Medicine_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- appointment
CREATE TABLE `appointment` (
  `Appointment_ID` int NOT NULL,
  `Patient_ID` varchar(10) NOT NULL,
  `Clinician_ID` int NOT NULL,
  `Clinic_ID` int NOT NULL,
  `Appointment_Date` date NOT NULL,
  `Appointment_Time` time NOT NULL,
  `Appointment_Type` varchar(50) DEFAULT NULL,
  `Status` varchar(20) NOT NULL DEFAULT 'Scheduled',
  `Notes` text,
  CONSTRAINT chk_appointment_date CHECK (Appointment_Date >= '1900-01-01'),
  CONSTRAINT chk_appointment_time CHECK (Appointment_Time >= '00:00:00' AND Appointment_Time < '24:00:00'),
  PRIMARY KEY (`Appointment_ID`),
  KEY `fk_appointment_patient` (`Patient_ID`),
  KEY `fk_appointment_clinician` (`Clinician_ID`),
  KEY `fk_appointment_clinic` (`Clinic_ID`),
  CONSTRAINT `fk_appointment_clinic` FOREIGN KEY (`Clinic_ID`) REFERENCES `clinic` (`Clinic_ID`),
  CONSTRAINT `fk_appointment_clinician` FOREIGN KEY (`Clinician_ID`) REFERENCES `clinician` (`Clinician_ID`),
  CONSTRAINT `fk_appointment_patient` FOREIGN KEY (`Patient_ID`) REFERENCES `patient` (`Patient_ID`),
  CONSTRAINT `chk_appointment_status` CHECK ((`Status` in (_utf8mb4'Scheduled',_utf8mb4'Completed',_utf8mb4'Cancelled')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- diagnosis
CREATE TABLE `diagnosis` (
  `Diagnosis_ID` int NOT NULL,
  `Appointment_ID` int NOT NULL,
  `Diagnosis_Name` varchar(120) NOT NULL,
  `Diagnosis_Notes` varchar(250) DEFAULT NULL,
  PRIMARY KEY (`Diagnosis_ID`),
  KEY `fk_diagnosis_appointment` (`Appointment_ID`),
  CONSTRAINT `fk_diagnosis_appointment` FOREIGN KEY (`Appointment_ID`) REFERENCES `appointment` (`Appointment_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- prescription
CREATE TABLE `prescription` (
  `Prescription_ID` int NOT NULL,
  `Appointment_ID` int NOT NULL,
  `Issued_Date` date NOT NULL,
  `Instructions` varchar(250) DEFAULT NULL,
  CONSTRAINT chk_prescription_date CHECK (Issued_Date >= '1900-01-01'),
  PRIMARY KEY (`Prescription_ID`),
  KEY `fk_prescription_appointment` (`Appointment_ID`),
  CONSTRAINT `fk_prescription_appointment` FOREIGN KEY (`Appointment_ID`) REFERENCES `appointment` (`Appointment_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- prescription_item
CREATE TABLE `prescription_item` (
  `Prescription_Item_ID` int NOT NULL,
  `Prescription_ID` int NOT NULL,
  `Medicine_ID` int NOT NULL,
  `Quantity` int NOT NULL,
  `Dose` varchar(100) NOT NULL,
  `Route` varchar(50) NOT NULL DEFAULT 'Ophthalmic',
  `Frequency` varchar(100) NOT NULL DEFAULT 'As directed',
  `Duration` varchar(50) NOT NULL DEFAULT 'As directed',
  PRIMARY KEY (`Prescription_Item_ID`),
  KEY `fk_item_prescription` (`Prescription_ID`),
  KEY `fk_item_medicine` (`Medicine_ID`),
  CONSTRAINT `fk_item_medicine` FOREIGN KEY (`Medicine_ID`) REFERENCES `medicine` (`Medicine_ID`),
  CONSTRAINT `fk_item_prescription` FOREIGN KEY (`Prescription_ID`) REFERENCES `prescription` (`Prescription_ID`),
  CONSTRAINT `chk_item_quantity` CHECK ((`Quantity` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- follow_up
CREATE TABLE `follow_up` (
  `Follow_Up_ID` int NOT NULL,
  `Appointment_ID` int NOT NULL,
  `Follow_Up_Date` date NOT NULL,
  `Plan` varchar(250) NOT NULL,
  `Priority` varchar(20) NOT NULL DEFAULT 'Routine',
  `Status` varchar(20) NOT NULL DEFAULT 'Pending',
  CONSTRAINT `chk_followup_priority` CHECK (`Priority` IN ('Routine','High','Urgent')),
  CONSTRAINT `chk_followup_status` CHECK (`Status` IN ('Pending','Completed','Cancelled')),
  CONSTRAINT chk_followup_date CHECK (Follow_Up_Date >= '1900-01-01'),
  PRIMARY KEY (`Follow_Up_ID`),
  UNIQUE KEY `Appointment_ID` (`Appointment_ID`),
  CONSTRAINT `fk_followup_appointment` FOREIGN KEY (`Appointment_ID`) REFERENCES `appointment` (`Appointment_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ALTER TABLE: index supporting patient-history queries.
ALTER TABLE appointment ADD INDEX ix_appointment_patient_date (Patient_ID, Appointment_Date);

-- Preserve baseline synthetic data, rekeyed to avoid Appendix 1 patient-ID collisions.
START TRANSACTION;
INSERT INTO `patient` (`Patient_ID`,`First_Name`,`Last_Name`,`Date_Of_Birth`,`Phone`,`Email`,`City`) VALUES ('SYN001','Andreea','Popescu','1971-02-02','07000000001','patient001@crownfield.example','Bucharest'),('SYN002','Jakub','Kowalski','1972-03-03','07000000002','patient002@crownfield.example','Warsaw'),('SYN003','Ioana','Ionescu','1973-04-04','07000000003','patient003@crownfield.example','Cluj-Napoca'),('SYN004','Zofia','Nowak','1974-05-05','07000000004','patient004@crownfield.example','Kraków'),('SYN005','Mihai','Dumitrescu','1975-06-06','07000000005','patient005@crownfield.example','Bucharest'),('SYN006','Aleksandra','Wiśniewska','1976-07-07','07000000006','patient006@crownfield.example','Warsaw'),('SYN007','Elena','Stan','1977-08-08','07000000007','patient007@crownfield.example','Cluj-Napoca'),('SYN008','Piotr','Zieliński','1978-09-09','07000000008','patient008@crownfield.example','Kraków'),('SYN009','Radu','Marinescu','1979-10-10','07000000009','patient009@crownfield.example','Bucharest'),('SYN010','Katarzyna','Wójcik','1980-11-11','07000000010','patient010@crownfield.example','Warsaw'),('SYN011','Cristina','Pavel','1981-12-12','07000000011','patient011@crownfield.example','Cluj-Napoca'),('SYN012','Mateusz','Lewandowski','1982-01-13','07000000012','patient012@crownfield.example','Kraków'),('SYN013','Sorina','Georgescu','1983-02-14','07000000013','patient013@crownfield.example','Bucharest'),('SYN014','Tomasz','Kamiński','1984-03-15','07000000014','patient014@crownfield.example','Warsaw');
INSERT INTO `specialty` VALUES (4,'Cataract Surgery'),(6,'Cornea'),(1,'General Ophthalmology'),(2,'Glaucoma'),(10,'Low Vision'),(9,'Medical Retina'),(7,'Neuro-Ophthalmology'),(8,'Oculoplastics'),(5,'Paediatric Ophthalmology'),(3,'Retina');
INSERT INTO `clinician` VALUES (1,'Ana','Georgescu',1,'ana.georgescu@crownfield.example'),(2,'Mateusz','Lewandowski',2,'mateusz.lewandowski@crownfield.example'),(3,'Cristina','Pavel',3,'cristina.pavel@crownfield.example'),(4,'Agnieszka','Kaminska',4,'agnieszka.kaminska@crownfield.example'),(5,'Mihai','Radu',5,'mihai.radu@crownfield.example'),(6,'Zofia','Kowalczyk',6,'zofia.kowalczyk@crownfield.example'),(7,'Irina','Munteanu',7,'irina.munteanu@crownfield.example'),(8,'Piotr','Mazur',8,'piotr.mazur@crownfield.example'),(9,'Andrei','Dobre',9,'andrei.dobre@crownfield.example'),(10,'Katarzyna','Jankowska',10,'katarzyna.jankowska@crownfield.example'),(11,'Elena','Vasilescu',1,'elena.vasilescu@crownfield.example'),(12,'Tomasz','Wrobel',2,'tomasz.wrobel@crownfield.example'),(13,'Sorina','Iliescu',3,'sorina.iliescu@crownfield.example');
INSERT INTO `clinic` VALUES (1,'City Road Eye Clinic','Crownfield Eye Hospital','London','United Kingdom'),(2,'Islington Glaucoma Clinic','Crownfield Eye Hospital','London','United Kingdom'),(3,'Camden Retina Clinic','Crownfield Eye Hospital','London','United Kingdom'),(4,'Hackney Cataract Clinic','Crownfield Eye Hospital','London','United Kingdom'),(5,'Enfield Vision Clinic','Crownfield Eye Hospital','London','United Kingdom'),(6,'Haringey Cornea Clinic','Crownfield Eye Hospital','London','United Kingdom'),(7,'Barnet Eye Clinic','Crownfield Eye Hospital','London','United Kingdom'),(8,'Westminster Eye Clinic','Crownfield Eye Hospital','London','United Kingdom'),(9,'Ealing Retina Clinic','Crownfield Eye Hospital','London','United Kingdom'),(10,'Croydon Vision Clinic','Crownfield Eye Hospital','London','United Kingdom'),(11,'Greenwich Eye Clinic','Crownfield Eye Hospital','London','United Kingdom'),(12,'Waltham Forest Glaucoma Clinic','Crownfield Eye Hospital','London','United Kingdom'),(13,'Lewisham Eye Clinic','Crownfield Eye Hospital','London','United Kingdom');
INSERT INTO `medicine` VALUES (1,'Latanoprost','Eye Drops'),(2,'Timolol','Eye Drops'),(3,'Brimonidine','Eye Drops'),(4,'Dorzolamide','Eye Drops'),(5,'Artificial Tears','Eye Drops'),(6,'Carbomer Gel','Eye Gel'),(7,'Sodium Hyaluronate','Eye Drops'),(8,'Olopatadine','Eye Drops'),(9,'Ketotifen','Eye Drops'),(10,'Chloramphenicol','Eye Drops'),(11,'Aciclovir','Eye Ointment'),(12,'Cyclopentolate','Eye Drops'),(13,'Prednisolone Acetate','Eye Drops'),(14,'Acetazolamide','Tablets');
INSERT INTO `appointment` VALUES (1,'SYN001',1,1,'2026-11-02','09:00:00','Eye Examination','Scheduled',NULL),(2,'SYN002',2,2,'2026-11-02','10:00:00','Glaucoma Review','Scheduled',NULL),(3,'SYN003',3,3,'2026-11-03','11:00:00','Retina Examination','Scheduled',NULL),(4,'SYN004',4,4,'2026-11-03','12:00:00','Cataract Consultation','Scheduled',NULL),(5,'SYN005',5,5,'2026-11-04','09:30:00','Vision Assessment','Scheduled',NULL),(6,'SYN006',6,6,'2026-11-04','10:30:00','Cornea Examination','Scheduled',NULL),(7,'SYN007',7,7,'2026-11-05','11:30:00','Eye Examination','Scheduled',NULL),(8,'SYN008',8,8,'2026-11-05','14:00:00','Follow-up Consultation','Scheduled',NULL),(9,'SYN009',9,9,'2026-11-06','09:00:00','Retina Review','Scheduled',NULL),(10,'SYN010',10,10,'2026-11-06','10:00:00','Vision Assessment','Scheduled',NULL),(11,'SYN011',11,11,'2026-11-09','09:00:00','Eye Examination','Scheduled',NULL),(12,'SYN012',12,12,'2026-11-09','10:00:00','Glaucoma Review','Scheduled',NULL),(13,'SYN013',13,13,'2026-11-10','11:00:00','Retina Examination','Scheduled',NULL),(14,'SYN014',1,1,'2026-11-10','14:00:00','Eye Examination','Scheduled',NULL),(15,'SYN001',2,1,'2026-11-16','09:30:00','Glaucoma Review','Scheduled',NULL);
INSERT INTO `diagnosis` VALUES (1,1,'Dry Eye Syndrome','Mild symptoms'),(2,2,'Glaucoma','Routine monitoring'),(3,3,'Diabetic Retinopathy','Retinal examination'),(4,4,'Cataract','Initial assessment'),(5,5,'Myopia','Vision assessment'),(6,6,'Keratitis','Cornea assessment'),(7,7,'Conjunctivitis','Mild irritation'),(8,8,'Astigmatism','Follow-up review'),(9,9,'Macular Degeneration','Retina review'),(10,10,'Hyperopia','Vision assessment'),(11,11,'Dry Eye Syndrome','Routine examination'),(12,12,'Glaucoma','Pressure monitoring'),(13,13,'Retinal Tear','Retina assessment'),(14,14,'Blepharitis','Eyelid inflammation'),(15,15,'Glaucoma','Follow-up monitoring');
INSERT INTO `prescription` VALUES (1,1,'2026-11-02','Follow clinician instructions'),(2,2,'2026-11-02','Review at next appointment'),(3,3,'2026-11-03','Follow treatment plan'),(4,4,'2026-11-03','Review after consultation'),(5,5,'2026-11-04','Follow clinician instructions'),(6,6,'2026-11-04','Review symptoms'),(7,7,'2026-11-05','Follow treatment plan'),(8,8,'2026-11-05','Review at follow-up'),(9,9,'2026-11-06','Follow clinician instructions'),(10,10,'2026-11-06','Review if symptoms change'),(11,11,'2026-11-09','Follow treatment plan'),(12,12,'2026-11-09','Review eye pressure'),(13,13,'2026-11-10','Follow clinician instructions'),(14,15,'2026-11-16','Review at next appointment');
INSERT INTO `prescription_item` (`Prescription_Item_ID`,`Prescription_ID`,`Medicine_ID`,`Quantity`,`Dose`) VALUES (1,1,5,1,'As directed by clinician'),(2,2,1,1,'As directed by clinician'),(3,2,2,1,'As directed by clinician'),(4,3,7,1,'As directed by clinician'),(5,4,12,1,'As directed by clinician'),(6,5,5,1,'As directed by clinician'),(7,6,6,1,'As directed by clinician'),(8,7,10,1,'As directed by clinician'),(9,8,7,1,'As directed by clinician'),(10,9,13,1,'As directed by clinician'),(11,10,5,1,'As directed by clinician'),(12,11,6,1,'As directed by clinician'),(13,12,3,1,'As directed by clinician'),(14,13,12,1,'As directed by clinician'),(15,14,1,1,'As directed by clinician');
INSERT INTO `follow_up` (`Follow_Up_ID`,`Appointment_ID`,`Follow_Up_Date`,`Plan`) VALUES (1,1,'2026-12-02','Routine eye review'),(2,2,'2026-12-02','Glaucoma monitoring'),(3,3,'2026-12-03','Retina assessment'),(4,4,'2026-12-03','Cataract consultation review'),(5,5,'2026-12-04','Vision reassessment'),(6,6,'2026-12-04','Cornea review'),(7,7,'2026-12-05','General eye review'),(8,8,'2026-12-05','Follow-up examination'),(9,9,'2026-12-06','Retina monitoring'),(10,10,'2026-12-06','Vision review'),(11,11,'2026-12-09','Dry eye review'),(12,12,'2026-12-09','Eye pressure monitoring'),(13,13,'2026-12-10','Retina follow-up'),(14,15,'2026-12-16','Glaucoma follow-up');

-- Reuse source specialties Glaucoma/Retina/Cornea; retain 10 additional names.
INSERT INTO specialty VALUES
(11,'Ocular Oncology'),(12,'Ophthalmic Imaging'),(13,'Vitreoretinal Surgery');

-- Assessment Appendix 1: original IDs and names, missing DOB/contact/city = NULL.
INSERT INTO patient (Patient_ID,First_Name,Last_Name,Postcode) VALUES
('OP001','Amina','Yusuf','NE1 4AB'),('OP002','Daniel','Reed','N16 7QP'),
('OP003','Sofia','Bennett','E8 2LD'),('OP004','Michael','Okoro','SE6 3RT');
INSERT INTO clinician VALUES
(101,'Maya','Shah',2,NULL),(102,'Leo','Grant',3,NULL),(103,'Priya','Nair',6,NULL);
-- Clinic cities/country and medicine form are prototype assumptions, not source facts.
INSERT INTO clinic VALUES
(101,'City Road','Crownfield Eye Hospital','London','United Kingdom'),
(102,'Bedford','Crownfield Eye Hospital','Bedford','United Kingdom'),
(103,'Croydon','Crownfield Eye Hospital','London','United Kingdom');
INSERT INTO medicine VALUES
(101,'Aflibercept','Injection'),(102,'Sodium chloride drops','Eye Drops');
-- Statuses and issue dates are seed assumptions; future source visit 103 is planned.
INSERT INTO appointment VALUES
(101,'OP001',101,101,'2026-10-05','09:00:00',NULL,'Completed','Review IOP'),
(102,'OP002',102,101,'2026-10-05','09:30:00',NULL,'Completed','OCT before review'),
(103,'OP001',101,102,'2026-11-16','10:15:00',NULL,'Scheduled','Visual field test'),
(104,'OP003',101,101,'2026-10-06','11:00:00',NULL,'Completed','Monitor'),
(105,'OP004',103,103,'2026-10-07','14:00:00',NULL,'Completed','Corneal topography');
INSERT INTO diagnosis VALUES
(101,101,'Ocular hypertension',NULL),(102,102,'Diabetic macular oedema',NULL),
(103,103,'Ocular hypertension',NULL),(104,104,'Glaucoma suspect',NULL),
(105,105,'Keratoconus',NULL);
INSERT INTO prescription VALUES
(101,101,'2026-10-05',NULL),(102,102,'2026-10-05',NULL),
(103,103,'2026-11-16',NULL),(105,105,'2026-10-07',NULL);
-- Quantities are assumed to be 1; unspecified regimen uses nonclinical placeholders.
INSERT INTO prescription_item VALUES
(101,101,1,1,'Not supplied','Not supplied','Not supplied','Not supplied'),
(102,101,2,1,'Not supplied','Not supplied','Not supplied','Not supplied'),
(103,102,101,1,'Not supplied','Not supplied','Not supplied','Not supplied'),
(104,103,1,1,'Not supplied','Not supplied','Not supplied','Not supplied'),
(105,105,102,1,'Not supplied','Not supplied','Not supplied','Not supplied');
-- Source 'None' at appointment 104 means no prescription or items.
-- Due dates derive from appointment date + the stated number of weeks.
INSERT INTO follow_up VALUES
(101,101,DATE_ADD('2026-10-05',INTERVAL 6 WEEK),'Review IOP','High','Pending'),
(102,102,DATE_ADD('2026-10-05',INTERVAL 4 WEEK),'OCT before review','Urgent','Pending'),
(103,103,DATE_ADD('2026-11-16',INTERVAL 12 WEEK),'Visual field test','Routine','Pending'),
(104,104,DATE_ADD('2026-10-06',INTERVAL 26 WEEK),'Monitor','Routine','Pending'),
(105,105,DATE_ADD('2026-10-07',INTERVAL 8 WEEK),'Corneal topography','Routine','Pending');

-- Enrich only baseline synthetic follow-ups, preserving appendix priorities.
UPDATE follow_up
SET Priority=CASE WHEN Follow_Up_ID IN (2,3,12,14) THEN 'High'
 WHEN Follow_Up_ID=13 THEN 'Urgent' ELSE 'Routine' END,
 Status=CASE WHEN Follow_Up_ID=1 THEN 'Completed' ELSE 'Pending' END
WHERE Follow_Up_ID < 100;
-- Synthetic and planned regimens are test text only; never use as clinical advice.
COMMIT;

CREATE TABLE appointment_status_audit (
 Audit_ID BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
 Appointment_ID INT NOT NULL, Old_Status VARCHAR(20) NOT NULL,
 New_Status VARCHAR(20) NOT NULL,
 Changed_At TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_audit_appointment FOREIGN KEY (Appointment_ID)
 REFERENCES appointment(Appointment_ID)
) ENGINE=InnoDB;
CREATE TABLE demo_protected_token (
 Token_ID INT PRIMARY KEY, Patient_ID VARCHAR(10) NOT NULL UNIQUE,
 Token_Hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 CONSTRAINT fk_token_patient FOREIGN KEY (Patient_ID) REFERENCES patient(Patient_ID)
) ENGINE=InnoDB;

SELECT '01 schema and seed complete' AS Step;
SELECT 'patient' AS Table_Name,COUNT(*) AS Records FROM patient
UNION ALL SELECT 'specialty',COUNT(*) FROM specialty
UNION ALL SELECT 'clinician',COUNT(*) FROM clinician
UNION ALL SELECT 'clinic',COUNT(*) FROM clinic
UNION ALL SELECT 'medicine',COUNT(*) FROM medicine
UNION ALL SELECT 'appointment',COUNT(*) FROM appointment
UNION ALL SELECT 'diagnosis',COUNT(*) FROM diagnosis
UNION ALL SELECT 'prescription',COUNT(*) FROM prescription
UNION ALL SELECT 'prescription_item',COUNT(*) FROM prescription_item
UNION ALL SELECT 'follow_up',COUNT(*) FROM follow_up;
