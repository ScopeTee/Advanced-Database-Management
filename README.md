# Advanced Database Systems Portfolio

**Course:** MIT 8103 – Advanced Database Systems
**Session:** 2026/2027, First Semester Continuous Assessment

## Selected Case Study / Organisation

### 1. Organisation / Scenario
Crestfield University is a fictional Nigerian university offering bachelor's degree programmes across multiple faculties and departments. The university operates an academic result management system to manage student registration, course assignments, and academic performance.

### 2. Nature of the Business / System
The University Student Result Portal is a relational database system designed to manage students' academic records, course registrations, continuous assessment scores, examination results, and GPA calculations. It provides a centralised platform for maintaining academic information and ensuring accurate, consistent, and traceable result management.

### 3. Users of the Database
- **Students:** Register for courses, view their results, and monitor their academic performance.
- **Lecturers:** Enter and upload continuous assessment and examination scores for courses assigned to them.
- **Academic Administrators:** Manage student records, courses, academic sessions, lecturer assignments, and other academic information.

### 4. Major Data to Be Stored
The database stores information about faculties, departments, academic programmes, students, lecturers, user accounts, courses, academic sessions, semesters, course registrations, student scores, grade scales, academic results, carry-over courses, lecturer assignment history, and grade change audit logs.

### 5. Key Operations Supported
The system supports student registration, semester course registration subject to a maximum of 24 credit units including carry-over courses, lecturer assignment, score entry using a fixed 40% continuous assessment and 60% examination structure, result computation, five-point grading and GPA calculation, carry-over registration with a maximum of two attempts, lecturer-restricted grade entry and modification, and audit logging of grade changes and lecturer assignment changes.

## Portfolio Contents

| Portfolio | Topic | Folder |
|---|---|---|
| 1 | Database Design and Modelling | [portfolio-1-database-design](portfolio-1-database-design/) |
| 2 | Query Processing and Optimisation | [portfolio-2-query-optimisation](portfolio-2-query-optimisation/) |
| 3 | Transactions and Concurrency | [portfolio-3-transactions-concurrency](portfolio-3-transactions-concurrency/) |
| 4 | NoSQL and Advanced Data Models | [portfolio-4-nosql](portfolio-4-nosql/) |
| 5 | Distributed and Cloud Database Exercise | [portfolio-5-distributed-cloud](portfolio-5-distributed-cloud/) |
| – | Final Documentation | [docs](docs/) |

## Tools and Environment

| Purpose | Tool / Platform | Version |
|---|---|---|
| Relational DBMS (Portfolios 1–3) | PostgreSQL | 18 |
| SQL client | pgAdmin 4 and SQL Shell (psql) | Bundled with PostgreSQL 18 |
| ER modelling | dbdiagram.io (DBML) | Web |
| NoSQL database (Portfolio 4) | MongoDB Atlas | 8.0.39 |
| NoSQL client | MongoDB Compass with the built-in MongoDB shell (mongosh) | Desktop |
| Cloud platform (Portfolio 5) | MongoDB Atlas free M0 cluster on AWS, Paris (eu-west-3), 3-node replica set | – |
| Version control | Git and GitHub (private repository) | – |
| Operating system | Windows | – |

## References

**Textbooks and papers**
- Connolly, T. and Begg, C. (2015) *Database Systems: A Practical Approach to Design, Implementation, and Management*. 6th edn. Harlow: Pearson.
- Elmasri, R. and Navathe, S.B. (2016) *Fundamentals of Database Systems*. 7th edn. Hoboken, NJ: Pearson.
- Gilbert, S. and Lynch, N. (2002) 'Brewer's conjecture and the feasibility of consistent, available, partition-tolerant web services', *ACM SIGACT News*, 33(2), pp. 51–59.

**PostgreSQL documentation** (PostgreSQL Global Development Group)
- Generated columns: https://www.postgresql.org/docs/current/ddl-generated-columns.html
- Indexes: https://www.postgresql.org/docs/current/indexes.html
- Using EXPLAIN: https://www.postgresql.org/docs/current/using-explain.html
- Trigger functions (PL/pgSQL): https://www.postgresql.org/docs/current/plpgsql-trigger.html
- Explicit locking (`SELECT … FOR UPDATE`): https://www.postgresql.org/docs/current/explicit-locking.html
- Transaction isolation: https://www.postgresql.org/docs/current/transaction-iso.html

**MongoDB documentation** (MongoDB, Inc.)
- Data modeling (embedding and referencing): https://www.mongodb.com/docs/manual/data-modeling/
- Schema validation: https://www.mongodb.com/docs/manual/core/schema-validation/
- Aggregation pipeline: https://www.mongodb.com/docs/manual/aggregation/
- Multikey indexes: https://www.mongodb.com/docs/manual/core/indexes/index-types/index-multikey/
- Replication: https://www.mongodb.com/docs/manual/replication/
- Read preference: https://www.mongodb.com/docs/manual/core/read-preference/
- Write concern: https://www.mongodb.com/docs/manual/reference/write-concern/
- Read concern: https://www.mongodb.com/docs/manual/reference/read-concern/
- Sharding: https://www.mongodb.com/docs/manual/sharding/

**Tools**
- dbdiagram.io: https://dbdiagram.io
- pgAdmin 4: https://www.pgadmin.org/docs/

## AI Use Declaration

**AI tool used:** Claude (Anthropic), through Claude Code.

**What it was used for:** explaining concepts and guiding the setup of PostgreSQL, pgAdmin, MongoDB Atlas and Compass; reviewing my case-study decisions and ER diagram, and converting the diagram into DBML; reviewing and correcting my PostgreSQL schema and checking my sample data and constraint tests; drafting the bulk-data script, revising my queries and drafting the CGPA ranking query (Portfolio 2); drafting the triggers and the transaction, concurrency and isolation demos (Portfolio 3); drafting the MongoDB setup, query and replication scripts (Portfolios 4 and 5); drafting the factual README sections and checking my written analyses for technical accuracy; and managing the Git commits.

**How the output was reviewed, tested and verified:** the case-study rules and design decisions were my own, and the AI reviewed and questioned them. I ran every script myself on my own PostgreSQL 18 installation and MongoDB Atlas cluster, and the screenshots are from those runs. I compared each output with the expected result, and where they differed the cause was investigated and corrected, for example two data-generation flaws found during testing and a MySQL-to-PostgreSQL syntax fix. The analysis sections were written by me, then checked for technical accuracy.
