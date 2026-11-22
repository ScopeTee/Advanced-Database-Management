# Final Documentation

This folder holds the 2–3 page documentation submitted through the LMS. The outline below is the structure of that document. Sections marked **(student to write)** are the individual parts and are completed by the student before export to PDF.

---

## MIT 8103 Advanced Database Systems – Portfolio Documentation

**Name:** Fuad Tayo-Subair
**Student ID:** 301906879 
**Course:** MIT 8103 Advanced Database Systems, 2026/2027 First Semester
**GitHub repository:** https://github.com/ScopeTee/Advanced-Database-Management

### 1. Selected Case Study

**Crestfield University Student Result Portal** – a fictional Nigerian university offering bachelor's degree programmes across several faculties. The database manages course registration, continuous assessment (40%) and examination (60%) scores, five-point grading, GPA/CGPA, and carry-overs (maximum two attempts). Its users are students, lecturers (who may only change results for courses assigned to them) and academic administrators. Key rules: a maximum of 24 credit units per semester, a second attempt only after a failed first attempt, and an audit log of every grade change.

### 2. Portfolio 1 – Database Design and Modelling

I designed a 15-entity ER model (faculty, department, programme, student, lecturer, user account, course, programme–course, academic session, semester, course registration, result, grade scale, lecturer assignment history and grade change log) and implemented it in PostgreSQL 18 with primary and foreign keys, UNIQUE and CHECK constraints, and a generated `total_score` column. Sample data includes a student who failed CSC101 and registered a second attempt. Three deliberate constraint violations were rejected by the database. The design follows 3NF, with `grade_id` and `current_level` documented as controlled denormalisation.

*Suggested screenshot:* `portfolio-1-database-design/er-diagram.webp`

### 3. Portfolio 2 – Query Processing and Optimisation

I generated about 50,000 students and 788,000 registrations, wrote six realistic queries (including a CGPA ranking using `RANK()`), and compared execution plans before and after indexing. A composite index on `course_registration (course_id, semester_id)` reduced the class-list query from 502.690 ms to 4.925 ms (about 102×). An index on `result.grade_id` was ignored by the planner because of low selectivity (671 ms before and after). A surname index gave a smaller gain (23.4 ms to 10.7 ms).

*Suggested screenshots:* `09-q1-plan-before.png` and `18-q1-plan-after.png`

### 4. Portfolio 3 – Transactions and Concurrency

I implemented five triggers for rules that constraints could not enforce: automatic grading, lecturer-only grade changes with an audit log, the 24-unit cap, the carry-over rule and the programme level limit. Demonstrations show COMMIT, ROLLBACK (which also undid the audit-log entry) and automatic rollback after an error. A two-session test showed a race condition breaking the 24-unit rule (27 units); adding `SELECT … FOR UPDATE` made the second session wait and then be rejected at 24 units. READ COMMITTED and REPEATABLE READ were compared.

*Suggested screenshots:* `12-partB-tabB-waiting.png` and `13-partB-tabB-rejected.png`

### 5. Portfolio 4 – NoSQL and Advanced Data Models

The same case study was modelled in MongoDB Atlas. Each student is one document with their results embedded, so a transcript is a single read; courses are referenced and joined with `$lookup`. A `$jsonSchema` validator enforces the score ranges (an exam score of 75 was rejected), an aggregation pipeline computes CGPA, and a multikey index on the embedded `results` fields was used (IXSCAN). PostgreSQL remains the system of record; MongoDB suits read-heavy transcript views.

*Suggested screenshot:* `04-q3-q4-push-and-validation.png`

### 6. Portfolio 5 – Distributed and Cloud Database

The Atlas cluster is a 3-node replica set on AWS, Paris (eu-west-3). `db.hello()` showed the three nodes and the primary (`shard-00-02`); a query with `readPref('secondary')` was answered by `shard-00-01`, proving replication. Write concern `majority` and read concern `majority` were demonstrated. The discussion covers automatic failover, consistency, the CAP theorem (consistency chosen for grades) and a hashed `matric_number` shard key design.

*Suggested screenshots:* `02-p2-read-preference.png` and `05-atlas-cluster-overview.png`

### 7. Individual Technical Reflection (student to write)

_About half a page: the design choices you made and why, the challenges you faced (for example the MySQL-to-PostgreSQL syntax, the `\i` path errors, the pgAdmin transaction states, the two data-generation flaws found during testing), and what you learned about indexing, transactions, NoSQL modelling and replication._

### 8. References

See the References section of the main [README](../README.md).

### 9. AI Use Declaration

**AI tool used:** Claude (Anthropic), through Claude Code.

**What it was used for:** explaining concepts and guiding the setup of PostgreSQL, pgAdmin, MongoDB Atlas and Compass; reviewing my case-study decisions and ER diagram, and converting the diagram into DBML; reviewing and correcting my PostgreSQL schema and checking my sample data and constraint tests; drafting the bulk-data script, revising my queries and drafting the CGPA ranking query (Portfolio 2); drafting the triggers and the transaction, concurrency and isolation demos (Portfolio 3); drafting the MongoDB setup, query and replication scripts (Portfolios 4 and 5); drafting the factual README sections and checking my written analyses for technical accuracy; and managing the Git commits.

**How the output was reviewed, tested and verified:** the case-study rules and design decisions were my own, and the AI reviewed and questioned them. I ran every script myself on my own PostgreSQL 18 installation and MongoDB Atlas cluster, and the screenshots are from those runs. I compared each output with the expected result, and where they differed the cause was investigated and corrected, for example two data-generation flaws found during testing and a MySQL-to-PostgreSQL syntax fix. The analysis sections were written by me, then checked for technical accuracy.
