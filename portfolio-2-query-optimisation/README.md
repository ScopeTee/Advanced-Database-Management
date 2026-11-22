# Portfolio 2: Query Processing and Optimisation

## Expected Evidence

SQL queries, query results, execution plans, indexing/optimisation evidence, and brief performance analysis.

## Implementation

This folder contains the query processing and optimisation work for the Crestfield University Student Result Portal. It builds on the Portfolio 1 schema and sample data.

To make the effect of indexing measurable, I first generated a realistic volume of data, then wrote six queries based on real portal operations, captured their execution plans, added indexes for three of them, and compared the plans before and after.

| File | Purpose |
|---|---|
| `01_bulk_data.sql` | Generates 5 faculties, 20 departments and programmes, 3 earlier sessions, 200 lecturers, 480 courses, 50,000 students and about 788,000 course registrations with results, including carry-over attempts |
| `02_queries.sql` | Six queries: class list, failed results in a session, surname search, student transcript, most-failed courses, and top 10 final-year students per department by CGPA (using `RANK()`) |
| `03_indexes.sql` | The three indexes created for the optimisation demonstrations, followed by `ANALYZE` |
| `screenshots/` | Query results, execution plans before and after indexing, and index creation output |

**Tools used:** PostgreSQL 18, pgAdmin 4 (Query Tool, `EXPLAIN ANALYZE`, graphical explain plans).

**Data checks:** After loading, I checked that the generated data respected the business rules from Portfolio 1:
- every grade matches its total score
- no student exceeds 24 units in a semester
- every second attempt follows a failed first attempt
- every programme has students at all four levels

During testing I also found that student names were tied to the programme. All students in a department and entry year had the same first name. I corrected the script to assign names randomly, and applied the same change to my loaded data with an `UPDATE`.

**Indexes created:**

| Index | Table (columns) | Used by |
|---|---|---|
| `idx_reg_course_semester` | `course_registration (course_id, semester_id)` | Query 1 |
| `idx_result_grade` | `result (grade_id)` | Query 2 |
| `idx_student_last_name` | `student (last_name)` | Query 3 |

Queries 4–6 were not used for indexing demonstrations. Query 4 already uses existing indexes (`matric_number` and the unique key on `course_registration`). Queries 5 and 6 are aggregation reports over large parts of the data.

## How to Run / Test

1. Make sure the Portfolio 1 scripts have been run on an empty `crestfield_university` database: `01_schema.sql`, then `02_sample_data.sql`.
2. In pgAdmin, open a Query Tool on `crestfield_university`, open `01_bulk_data.sql`, and run it once (F5). It takes about 2–3 minutes and ends with a table of record counts.
3. Open `02_queries.sql`. Highlight one query at a time and press **F5** to see its results.
4. To capture a **baseline plan**, add `EXPLAIN (ANALYZE, BUFFERS)` above a query and run it twice, recording the second run's Execution Time. Press **Shift + F7** for the graphical plan.
5. Run the statements in `03_indexes.sql`.
6. Repeat step 4 for Queries 1–3 and compare the plans and timings.

To return to the baseline, drop the three indexes:
```sql
DROP INDEX idx_reg_course_semester, idx_result_grade, idx_student_last_name;
```

## Results and Evidence

**Data volume**

| Screenshot | What it shows |
|---|---|
| `01-bulk-data-volumes.png` | Record counts after the bulk load: 50,001 students, 481 courses, 788,037 registrations, 628,476 results and 38,036 carry-overs |
| `02-programmes-all-levels.png` | All 20 generated programmes have students at all four levels |

**Query results**

| Screenshot | Query | Rows returned |
|---|---|---|
| `03-q1-results.png` | Q1: class list for MEE101, 2025/2026 First Semester | 675 |
| `04-q2-results.png` | Q2: failed results (F) in 2025/2026 | 19,072 |
| `05-q3-results.png` | Q3: students with surname Okafor | 2,422 |
| `06-q4-results.png` | Q4: transcript for CU/2023/00004 | 25 |
| `07-q5-results.png` | Q5: ten courses with the most failures in 2025/2026 | 10 |
| `08-q6-results.png` | Q6: top 10 final-year students per department by CGPA | 212 (ties share a rank) |

**Execution plans**

| Screenshot | What it shows |
|---|---|
| `09`–`11-…-plan-before.png` and `-graphical.svg` | Q1–Q3 before indexing |
| `12`–`14-index-…-created.png`, `15-analyze.png` | Index creation (1.719 s, 1.040 s and 0.380 s) and statistics refresh (5.137 s) |
| `16-q4-plan-graphical.svg`, `17-q5-plan-graphical.svg` | Plans for Q4 (already index-based) and Q5 |
| `18`–`20-…-plan-after.png` | Q1–Q3 after indexing |

**Before and after indexing** (Execution Time from `EXPLAIN (ANALYZE, BUFFERS)`, second run)

| Query | Index | Before | After | Change |
|---|---|---|---|---|
| Q1: class list | `idx_reg_course_semester` | 502.690 ms | 4.925 ms | About 102× faster |
| Q2: failed results | `idx_result_grade` | 670.870 ms | 671.319 ms | No change |
| Q3: surname search | `idx_student_last_name` | 23.367 ms | 10.732 ms | About 2.2× faster |

The reasons for these differences are discussed in the Notes / Analysis section below.

## Notes / Analysis

> _To be completed._
