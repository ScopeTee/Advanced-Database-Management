# Final Documentation

This folder holds the 2–3 page documentation submitted through the LMS. The outline below is the structure of that document. The individual reflection and AI use declaration are written by the student.

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


### 3. Portfolio 2 – Query Processing and Optimisation

I generated about 50,000 students and 788,000 registrations, wrote six realistic queries (including a CGPA ranking using `RANK()`), and compared execution plans before and after indexing. A composite index on `course_registration (course_id, semester_id)` reduced the class-list query from 502.690 ms to 4.925 ms (about 102×). An index on `result.grade_id` was ignored by the planner because of low selectivity (671 ms before and after). A surname index gave a smaller gain (23.4 ms to 10.7 ms).


### 4. Portfolio 3 – Transactions and Concurrency

I implemented five triggers for rules that constraints could not enforce: automatic grading, lecturer-only grade changes with an audit log, the 24-unit cap, the carry-over rule and the programme level limit. Demonstrations show COMMIT, ROLLBACK (which also undid the audit-log entry) and automatic rollback after an error. Without a row lock, two concurrent registrations could each pass the unit check and together exceed the 24-unit limit. In a two-session test with `SELECT … FOR UPDATE`, the second session waited for the first to commit and was then rejected at 24 units. Under READ COMMITTED, a repeated read in one transaction changed from 20.00 to 21.00 after another session committed; under REPEATABLE READ it stayed at 21.00 until the transaction ended.


### 5. Portfolio 4 – NoSQL and Advanced Data Models

The same case study was modelled in MongoDB Atlas. Each student is one document with their results embedded, so a transcript is a single read; courses are referenced and joined with `$lookup`. A `$jsonSchema` validator enforces the score ranges (an exam score of 75 was rejected), an aggregation pipeline computes CGPA, and a multikey index on the embedded `results` fields was used (IXSCAN). PostgreSQL remains the system of record; MongoDB suits read-heavy transcript views.


### 6. Portfolio 5 – Distributed and Cloud Database

The Atlas cluster is a 3-node replica set on AWS, Paris (eu-west-3). `db.hello()` showed the three nodes and the primary (`shard-00-02`); a query with `readPref('secondary')` was answered by `shard-00-01`, proving replication. Write concern `majority` and read concern `majority` were demonstrated. The discussion covers automatic failover, consistency, the CAP theorem (consistency chosen for grades) and a hashed `matric_number` shard key design.


### 7. Individual Technical Reflection

1. **A design choice I'd defend:** I kept `grade_id` in the results table instead of calculating it every time because it makes it easier to store and retrieve the grade awarded to a student. Strictly, this is a transitive dependency, since the grade depends on the score, but I kept it deliberately for faster transcript queries and used a trigger in Portfolio 3 to keep it consistent with the scores. I also kept the lecturer on the course row and used a separate history log to track changes without losing the current lecturer information.

2. **The hardest problem I hit, and how I got past it:** One of the challenges was getting the MySQL script to work in PostgreSQL, since some of the syntax was different. I also had issues with Windows file paths and pgAdmin transactions, but I worked through them by correcting the commands and rolling back aborted transactions before continuing.

3. **Something that surprised me:** I was surprised that PostgreSQL could ignore an index I had created and still choose a sequential scan. I also learned that two transactions can each pass a validation check but still break a rule when they run at the same time.

4. **What I learned about choosing between databases:** I learned that the choice of database depends on what the system needs most. PostgreSQL is better for registration and grading because of its constraints and transaction support, while MongoDB is useful for retrieving complete transcripts with fewer reads.

5. **What I'd do differently with more time:** I would start earlier and commit my work more consistently instead of leaving too much until the end. I would also build a small front-end to make the database work easier to demonstrate and test.

### 8. References

See the References section of the main [README](../README.md).

### 9. AI Use Declaration

**AI tool used:** Claude (Anthropic), through Claude Code.

**What it was used for:** explaining concepts and guiding the setup of PostgreSQL, pgAdmin, MongoDB Atlas and Compass; reviewing my case-study decisions and ER diagram, and converting the diagram into DBML; reviewing and correcting my PostgreSQL schema and checking my sample data and constraint tests; drafting the bulk-data script, revising my queries and drafting the CGPA ranking query (Portfolio 2); drafting the triggers and the transaction, concurrency and isolation demos (Portfolio 3); drafting the MongoDB setup, query and replication scripts (Portfolios 4 and 5); drafting the factual README sections and checking my written analyses for technical accuracy; and managing the Git commits.

**How the output was reviewed, tested and verified:** the case-study rules and design decisions were my own, and the AI reviewed and questioned them. I ran every script myself on my own PostgreSQL 18 installation and MongoDB Atlas cluster, and the screenshots are from those runs. I compared each output with the expected result, and where they differed the cause was investigated and corrected, for example two data-generation flaws found during testing and a MySQL-to-PostgreSQL syntax fix. The analysis sections were written by me, then checked for technical accuracy.
