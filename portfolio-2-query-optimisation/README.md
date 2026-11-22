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

### Performance Analysis

The purpose of these demonstrations was to examine how indexes affect query execution in PostgreSQL. I compared the execution plans before and after creating the indexes to see whether PostgreSQL could retrieve records more efficiently.

#### 1. Composite Index on `course_registration`

Before creating the index, PostgreSQL had to scan the `course_registration` table to find records matching the selected course and semester. After creating the composite index on `course_id` and `semester_id`, PostgreSQL could locate the matching records more directly. Execution time fell from 502.690 ms to 4.925 ms, about 102 times faster.

This improved the query because only about 675 rows matched the conditions, compared with approximately 788,000 rows in the table. Rather than checking every row, PostgreSQL could use the index to narrow down the records it needed to retrieve.

The index matches the query exactly because the query filters on both columns. I placed `course_id` first because it narrows the search far more than `semester_id`: there are 481 courses but only 8 semesters.

#### 2. Index on `result.grade_id`

For this demonstration, I created an index on `result.grade_id` to improve the retrieval of students who received an F grade.

However, PostgreSQL did not use the index and continued to perform a sequential scan. Execution time was essentially unchanged: 670.870 ms before and 671.319 ms after. This is because `grade_id` has low selectivity. It has only six distinct values, and F grades account for approximately 8% of the records, which is about 50,000 of the 628,000 results. Since the query needs to retrieve a relatively large number of rows, using the index to locate them would mean jumping around the table to fetch each one, which costs more than reading the table straight through.

This shows that creating an index does not automatically mean PostgreSQL will use it. The query planner considers the estimated cost of different execution plans before choosing one.

#### 3. Index on `student.last_name`

The index on `student.last_name` helped PostgreSQL locate approximately 2,400 matching student records more quickly. Execution time fell from 23.367 ms to 10.732 ms, about 2.2 times faster.

Because about 2,400 rows is roughly 5% of all students, PostgreSQL used a bitmap index scan rather than a plain index scan. It first collected the locations of the matching rows from the index, then read them from the table in physical order.

However, the overall improvement was smaller than in the first demonstration. The `student` table is relatively small (50,000 rows), so the sequential scan was already cheap. The query also involved joining the student records to the `programme` table and sorting the results. Although the index reduced the work required to find the matching students, PostgreSQL still had to perform the remaining operations.

This demonstrates that an index can improve one part of a query without necessarily removing the cost of other operations.

#### 4. Indexing Trade-offs

Although the indexes improved some queries, creating and maintaining them also comes with costs.

The index creation times were:

| Index | Build time |
|---|---:|
| Composite index on `course_registration` | 1.719 seconds |
| Index on `result.grade_id` | 1.040 seconds |
| Index on `student.last_name` | 0.380 seconds |

After creating the indexes, I ran `ANALYZE` (5.137 seconds) so that the query planner had up-to-date statistics when deciding whether to use them.

Indexes also require additional disk space and can make insert, update and delete operations slower because PostgreSQL must maintain the indexes whenever the underlying data changes.

Based on the results, I would keep the composite index on `course_registration` and the index on `student.last_name` because they provided useful improvements to the demonstrated queries.

However, I would not keep the index on `result.grade_id`. PostgreSQL did not use it for the tested query, meaning it provided no measurable benefit in that demonstration while still requiring storage and maintenance. It also took almost three times as long to build as the `last_name` index.

#### 5. Conclusion

The demonstrations showed that indexes can improve query performance, particularly when they help PostgreSQL locate a relatively small number of matching records in a large table.

However, indexing every column is not a good approach. The usefulness of an index depends on the query, the number of matching records, the structure of the data and the execution plan selected by PostgreSQL.

Therefore, indexes should be created based on actual query requirements and performance measurements rather than simply adding indexes to every column.
