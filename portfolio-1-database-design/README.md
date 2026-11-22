# Portfolio 1: Database Design and Modelling

## Expected Evidence

Case study description, ER diagram, relational schema, keys, constraints, and normalisation explanation.

## Implementation

This folder contains the design and initial implementation of the Crestfield University Student Result Portal database.

I first designed the ER diagram based on the case study decisions in the main README, then converted it into DBML using dbdiagram.io. From that, I wrote the PostgreSQL schema, added sample data, and tested the constraints.

| File | Purpose |
|---|---|
| `er-diagram.webp` | My ER diagram showing the 15 entities, keys and relationships |
| `er-diagram-dbdiagram.webp` | The same model rendered from DBML in dbdiagram.io |
| `schema.dbml` | Text version of the ER model, including keys, constraints and defaults |
| `01_schema.sql` | PostgreSQL script that creates the 15 tables with primary keys, foreign keys, UNIQUE and CHECK constraints, and a generated `total_score` column |
| `02_sample_data.sql` | Sample records, including a student who failed CSC101 and registered for a second attempt |
| `03_constraint_tests.sql` | A verification query and three deliberate constraint violations |
| `screenshots/` | Evidence from running the scripts |

**Tools used:** dbdiagram.io (ER modelling), PostgreSQL 17 with SQL Shell (psql).

**Main constraints implemented:**
- CA score between 0 and 40, and exam score between 0 and 60
- A maximum of two attempts per course, with no duplicate attempt numbers
- Unique matric numbers, staff numbers, course codes and email addresses
- Valid levels (100–500), roles, statuses and grade ranges
- `total_score` generated automatically from CA + exam

## How to Run / Test

1. Open SQL Shell (psql) and create the database:
   ```sql
   CREATE DATABASE crestfield_university;
   \c crestfield_university
   ```
2. Run the schema script. Use forward slashes in the path.
   ```sql
   \i 'C:/path/to/portfolio-1-database-design/01_schema.sql'
   ```
   Run `\dt` to confirm that 15 tables were created.
3. Load the sample data:
   ```sql
   \i 'C:/path/to/portfolio-1-database-design/02_sample_data.sql'
   ```
4. Open `03_constraint_tests.sql` and run each block **one at a time**: the verification query first, then tests 1 to 3. Each test should fail with the error noted in its comment.

The scripts assume an empty database. To start again, run `DROP DATABASE crestfield_university;` from the `postgres` database, then repeat from step 1.

## Results and Evidence

| Screenshot | What it shows |
|---|---|
| `screenshots/01-schema-created.png` | `01_schema.sql` running successfully, with 15 `CREATE TABLE` statements |
| `screenshots/02-tables-list.png` | `\dt` listing all 15 tables |
| `screenshots/03-test1-exam-score.png` | An exam score of 75 rejected by `chk_exam_score` |
| `screenshots/04-test2-third-attempt.png` | A third attempt rejected by `chk_attempt_number` |
| `screenshots/05-test3-duplicate-matric.png` | A duplicate matric number rejected by `student_matric_number_key` |
| `screenshots/06-verification-carry-over.png` | The carry-over case: attempt 1 scored 35 (F) in the first semester, and attempt 2 is registered in the second semester with no result yet |

All three constraint tests produced the expected errors, which confirms that the database itself rejects invalid data, not just the application. The `DETAIL` line in test 1 also shows that `total_score` had already been calculated as 95.00 with grade F attached. This is the grade mismatch I describe in the Known Limitations section below.

## Notes / Analysis

### 1.5 Database Normalisation

While designing the database, I tried to avoid storing the same information in multiple places. I wanted each table to have a clear purpose and for related information to be connected using IDs rather than repeatedly entering the same details.

I considered the first three normal forms when structuring the database.

#### 1NF (First Normal Form)

For 1NF, I made sure each column stores one value at a time and that every record can be uniquely identified using a primary key.

For example, if a student registers for five courses in a semester, I don't store all five courses in one row or one column. Each registration gets its own record in the `course_registration` table.

#### 2NF (Second Normal Form)

For 2NF, the idea was to make sure that information in a table depends on the whole key and not just part of it.

One example is how I handled students, courses and course registrations. A registration is identified by the combination of the student, the course and the attempt number. If I had stored the course title in `course_registration`, it would depend only on the course, which is just one part of that combination. That would be a partial dependency, so course details are kept in the `course` table instead.

The same applies to students. Rather than repeating a student's details every time they register for a course, I store the student's information once in the `student` table and use the student's ID when creating a registration.

#### 3NF (Third Normal Form)

For 3NF, I looked at information that could be maintained separately instead of being repeated in other tables.

For example, I created a separate grade scale table to hold the grading boundaries, grades and grade points. The grade details are stored once in `grade_scale`, and the `result` table references the appropriate grade using `grade_id`.

I applied the same approach to other parts of the database, such as faculties, departments and programmes. Each has its own table, with relationships established using foreign keys.

#### Other Design Considerations

There were also a few decisions I made to keep the data consistent:

* **Total Score:** Instead of asking users to enter the total score, it is generated from the CA and examination scores. Strictly speaking, it is a derived value, but because PostgreSQL calculates it automatically, it can't go out of sync. This removes the possibility of someone entering a total that doesn't match the two scores.
* **Grade ID:** The grade can actually be worked out from the total score, so storing `grade_id` in the `result` table is technically a transitive dependency and doesn't fully meet 3NF. I kept it deliberately so that transcripts and GPA can be retrieved without looking up the score range for every result. The risk is that the stored grade could disagree with the score. During testing, the database accepted grade F for a total of 95. I plan to fix this in Portfolio 3 with a trigger that sets the grade automatically from the grade scale.
* **Current Level:** I kept `current_level` in the student record so that the student's current academic level can be accessed directly without calculating it every time. This means it is stored twice in a sense, since it can also be calculated from the entry session, so it has to be updated as the student moves to the next level. It should also never go above the programme's maximum level, which I plan to enforce with a trigger.
* **Foreign Keys:** I used foreign keys to ensure that records are linked to existing records in other tables. For example, a course registration must belong to an existing student and an existing course.

#### Known Limitations

Some rules are not yet enforced by the database itself. At the moment, a grade can disagree with the score, a second attempt can be registered without a failed first attempt, `current_level` does not update on its own, and the grade change and lecturer assignment logs are not filled in automatically. I plan to handle these with triggers in Portfolio 3.

The overall idea was to keep the database organised, avoid unnecessary repetition and make it easier to maintain when more students, courses and academic records are added.
