# Portfolio 1: Database Design and Modelling

## Expected Evidence

Case study description, ER diagram, relational schema, keys, constraints, and normalisation explanation.

## Implementation

> _To be completed._

## How to Run / Test

> _To be completed._

## Results and Evidence

> _To be completed (outputs, screenshots, logs)._

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
