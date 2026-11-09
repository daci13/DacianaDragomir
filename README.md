# Crownfield Eye Hospital — CPU4:103 SQL repository

A fictional ophthalmology database for the Introduction to Database assessment. This package contains the ordered runnable MySQL files and ER diagram requested in the brief. It is not a clinical application and must never contain real patient data.

**Student name / ID:** [complete before submission]  
**Individual contribution:** [describe only work you personally completed and can explain]

## Repository structure

```text
01_schema.sql
02_individual_queries.sql
03_procedure_and_trigger.sql
04_security.sql
05_ERD/
    crownfield_erd.mmd
    crownfield_erd.png
    original_supplied_erd.webp
README.md
```

`01_schema.sql` builds the schema, constraints, indexes and seed data. `02_individual_queries.sql` demonstrates Q1–Q4 and controlled UPDATE/DELETE transactions. `03_procedure_and_trigger.sql` demonstrates Q5–Q6 and adds temporal validation triggers. `04_security.sql` implements four roles, role assignments, token hashing and parameterized query examples. `05_ERD` holds an editable Mermaid source, its Crow’s Foot PNG export and the supplied original diagram.

## Setup requirements

Use **MySQL 8.4** where possible. The scripts require MySQL **8.0.16 or later** for enforced CHECK constraints and also use roles, CTEs and MySQL-specific syntax. They are not written for MariaDB, PostgreSQL or SQLite. Install MySQL Server and either MySQL Workbench or the `mysql` command-line client.

Use a local administrative account that can create/drop the demonstration database, create tables, routines, triggers, roles and users, grant privileges and inspect account metadata. All tables use InnoDB. A normal read-only or hosted application account will not have enough privileges for setup.

**Destructive reset warning:** `01_schema.sql` executes `DROP DATABASE IF EXISTS crownfield_ro_pl_demo`. This removes every object and record in that named database. Run it only in a dedicated local teaching environment. Do not point these scripts at a real hospital system or a database you need to preserve.

## File execution order

Run the files in this exact order:

1. `01_schema.sql`
2. `02_individual_queries.sql`
3. `03_procedure_and_trigger.sql`
4. `04_security.sql`

Q5 and Q6 are intentionally demonstrated in file 03, after their objects are created. The ERD files are documentation, not SQL scripts.

### MySQL command-line client

Extract the ZIP, open a terminal **in the extracted repository folder**, and connect:

```bash
mysql -u root -p
```

Enter your own local administrator password at the prompt, then run:

```sql
SOURCE 01_schema.sql;
SOURCE 02_individual_queries.sql;
SOURCE 03_procedure_and_trigger.sql;
SOURCE 04_security.sql;
```

On Linux, if the local root account uses socket authentication, `sudo mysql` may be the correct connection command. Do not change authentication just to match the example. Use the connection method configured on your computer.

Alternatively, from a shell in the repository folder:

```bash
mysql -u root -p --table < 01_schema.sql
mysql -u root -p --table < 02_individual_queries.sql
mysql -u root -p --table < 03_procedure_and_trigger.sql
mysql -u root -p --table < 04_security.sql
```

Stop and resolve any error before running the next file. The command-line client and Workbench understand `DELIMITER`, used for routines and triggers; a generic SQL driver may not.

### MySQL Workbench

Connect as the local administrator, open each SQL file, and execute the **whole file** in the order above. File 01 creates and selects the database; the later files also select it explicitly. Refresh the Schemas panel after file 01. Run individual SELECT/CALL demonstrations separately when taking your own legible assessment screenshots.

### Running again

Files 02–04 can be rerun after setup. The routine/trigger definitions are replaced, and transaction demonstrations roll back their data changes. File 04 regenerates the synthetic token digest, so the digest will differ on each run.

For a complete reset, run **01 → 02 → 03 → 04** again. Database-level objects are recreated, but server-level roles/accounts survive the database reset. `IF NOT EXISTS` prevents duplicate account creation; it does not remove unrelated privileges or change an existing account’s password/lock state. Reserve the `crownfield_*` names for this exercise and verify SHOW GRANTS. Fresh accounts created by file 04 are locked.

## Data assumptions and changes from the supplied SQL

The original SQL is a synthetic dataset, not a faithful import of Appendix 1: its OP001–OP004 refer to different people. Its 14 synthetic patients are therefore rekeyed as **SYN001–SYN014**, including their appointment foreign keys. The appendix patients retain **OP001–OP004**, and all five appendix visits are added as appointment IDs **101–105**. The original upload is not modified.

Appendix postcodes are retained in the added `patient.Postcode` field. Birth dates, patient city/contact details and clinician email addresses not supplied in the appendix are NULL; they are not invented. Birth date and patient city are nullable for that reason. A clinician’s primary specialty is optional in the schema, consistent with “may have one” in the brief.

Appendix appointment dates, times, diagnoses, medicine names, priorities and notes are preserved. “None” for Sofia Bennett becomes no prescription or medicine item, not a medicine named “None”. Existing Glaucoma, Retina, Cornea, Latanoprost and Timolol reference records are reused. Three additional specialty names retain at least ten non-source specialty records.

Follow-up dates are calculated from the appointment date plus the stated number of weeks. In appendix visit order, the resulting dates are 2026-11-16, 2026-11-02, 2027-02-08, 2027-04-06 and 2026-12-02. Follow-up status defaults to Pending. Clinic cities/country, medicine form, prescription issue dates and appointment status are documented prototype assumptions. Appendix quantities are assumed to be 1; unspecified dose, route, frequency and duration are explicitly labelled “Not supplied”. These values are not treatment advice.

Status in the original synthetic records is preserved. Planned visits may contain carried-forward diagnoses and planned prescriptions; the future appendix visit remains Scheduled. This is a teaching snapshot, not a clinically validated workflow. It does not prevent clinician double booking, supply authentication or enforce NHS production requirements.

Foreign keys use restrictive deletion. A patient/appointment with dependent records cannot be deleted first. Each appointment has one patient, clinician and clinic; diagnoses/prescriptions are optional one-to-many relationships. `follow_up.Appointment_ID` is UNIQUE, allowing at most one follow-up plan per visit. A patient can have at most one demonstration token. Both auxiliary tables have foreign keys; no table is disconnected.

A prescription is intended to contain one or more items, but ordinary foreign keys do not enforce the minimum of one child. The seeded prescriptions all contain items; future header/item creation should use one controlled transaction. The supplied table-write role grants do not enforce this minimum, so the ERD honestly shows the physically permitted zero-to-many relationship.

## Six individual SQL demonstrations

| Feature | File | Purpose and expected result after a fresh setup |
|---|---|---|
| Q1 — GROUP BY and HAVING | 02 | Counts appointments per clinician and retains clinicians with at least one booking. Returns 16 clinicians; Maya Shah has 3 bookings. |
| Q2 — INNER JOIN | 02 | Joins appointment, patient, clinician and clinic to show who is booked where. Returns 20 appointments. |
| Q3 — LEFT JOIN | 02 | Finds appointments without follow-up plans. Returns appointment 14 with a NULL follow-up ID. |
| Q4 — CTE and subquery | 02 | Compares medicine-item counts with the average across all appointments, including zero-item visits. Returns appointments 2 and 101, each with 2 items. |
| Q5 — input-parameter procedure | 03 | `CALL GetPatientAppointments('OP001');` returns Amina Yusuf’s appointments 101 and 103. `SQL SECURITY INVOKER` prevents privilege elevation. |
| Q6 — status-audit trigger | 03 | Changing appointment 1 from Scheduled to Completed inserts an audit row. ROLLBACK restores Scheduled and removes that transaction’s audit row. |

File 02 also changes a temporary note and deletes a temporary diagnosis inside rolled-back transactions. The original note returns to NULL, the temporary diagnosis count is zero, and no seeded record is permanently removed. File 03 rejects future birth dates, follow-ups/issue dates before the associated appointment and redating visits with clinical children. These temporal rules are created after the seed import; setup data was checked during validation. AUTO_INCREMENT gaps after rolled-back audit inserts are normal.

## Security access matrix

`S` = SELECT, `I` = INSERT, `U` = UPDATE, `D` = DELETE. An omitted privilege is deliberately withheld.

| Role | Allowed database access | Deliberately withheld |
|---|---|---|
| Administrator | All privileges within `crownfield_ro_pl_demo` | No server-wide user-management authority is granted by this role. |
| Doctor | S on patient, appointment, clinic, clinician, specialty and medicine; U on appointment Status/Notes only; S/I/U/D on diagnosis; S/I/U on prescriptions, items and follow-ups; EXECUTE on patient-history procedure | No patient demographics update, token-table access or appointment deletion |
| Receptionist | S/I/U on patient; S/I/U/D on appointment; S on clinic and clinician | No diagnosis, prescription, follow-up or token access |
| Patient | S on the public clinic-directory view only | No patient/clinical tables or patient-history procedure |

Four local demonstration users receive their corresponding roles with `GRANT` and `SET DEFAULT ROLE`. New accounts are created **ACCOUNT LOCK**, with no real passwords in the repository. To test login on your own computer, locally set a strong password and unlock the desired account using administrator `ALTER USER ... IDENTIFIED BY ... ACCOUNT UNLOCK`; do not commit that password statement. Reconnect as the demo user and run `SELECT CURRENT_ROLE();`, then test allowed and denied queries. Relock the account when finished.

MySQL table privileges are not per-patient row-level security. The patient role intentionally sees only public clinic information; it does **not** provide a patient portal. Authenticated, row-filtered access would need a separate application. The public view is a restricted DEFINER projection of clinic data; the patient-history procedure uses INVOKER permissions.

The protection demonstration hashes a freshly generated, high-entropy synthetic patient token using SHA-256 and stores only its 64-character digest. `Hash_Matches_Input=1` verifies the result before the input variable is cleared. It does not encrypt medical records and must not be presented as secure password storage. Real password storage needs an appropriate salted password-hashing method such as Argon2id.

The final PREPARE/EXECUTE example binds patient input with `?`. The valid OP001 input returns two appointments; injection-looking input is treated as a literal ID and returns no rows. It never concatenates user data into SQL syntax.

## ER diagram

![Updated Crow’s Foot ER diagram](05_ERD/crownfield_erd.png)

Edit `05_ERD/crownfield_erd.mmd` in a Mermaid-compatible editor; GitHub also renders Mermaid code blocks. The PNG is a high-resolution export suitable for zooming or inserting into the report. The uploaded `original_supplied_erd.webp` is retained unchanged for provenance, but is not the final diagram: it lacks the added postcode and patient-token relationship. Types such as `varchar_10` in the editable diagram mean SQL `VARCHAR(10)`; PK, FK and UK mean primary, foreign and unique keys. SQL remains authoritative for nullability, DEFAULT and CHECK definitions.

## Execution validation

Executed on **9 November 2026** in a local Linux **MySQL 8.0.46** instance. All four files ran successfully in the documented order. MySQL 8.4 compatibility is intended; this package was not executed on an 8.4 server. The complete sequence was also rerun to check reset/repeat execution.

Expected row counts after file 01:

```text
patient            18
specialty          13
clinician          16
clinic             16
medicine           16
appointment        20
diagnosis          20
prescription       18
prescription_item  20
follow_up          19
```

These combine Appendix 1 with at least ten additional records in each main/reference table. The auxiliary audit starts empty; the token table gains one demonstration row in file 04.

Validation accepted a valid clinical UPDATE/ROLLBACK and rejected an invalid appointment status, zero quantity, duplicate patient ID, orphan diagnosis, deletion of a referenced patient, duplicate follow-up for one visit, early follow-up/issue date, redating of a documented visit, future birth date and a zero calendar date. Separate logins confirmed all four default roles, allowed access and representative denied access. Temporary validation passwords were not recorded, and all demonstration accounts were relocked afterwards.

These are execution findings from package preparation, not screenshots of the student’s own work. Independently run the demonstrations and capture your own labelled results for the report/presentation.

## Attribution and submission

The baseline schema/data and Q1–Q6 originated in the supplied `Crownfield_Eye_Hospital_Complete.sql`; the original diagram came from `newerd.webp`. Packaging, source-data import, Q4 correction, linked token entity, security assignments, temporal checks, editable ERD and documentation were prepared with AI assistance. No student/group contribution or Git commit history has been invented. Complete the identity/contribution fields, review every SQL feature and follow your institution’s AI-use rules before submission.

For GitHub, extract the ZIP and upload the **six entries shown above** at the repository root, not the ZIP itself. Create an individual repository, preferably private unless your lecturer requires public access, and ensure the assessor can access it. This archive has not been uploaded to GitHub and is not a Moodle submission. The report, slides and recording are separate deliverables.

## Technical references

Oracle, *MySQL 8.4 Reference Manual: Using Roles*, accessed 2 November 2026: https://dev.mysql.com/doc/refman/8.4/en/roles.html

Oracle, *MySQL 8.4 Reference Manual: CHECK Constraints*, accessed 5 November 2026: https://dev.mysql.com/doc/refman/8.4/en/create-table-check-constraints.html
