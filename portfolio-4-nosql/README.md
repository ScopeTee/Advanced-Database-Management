# Portfolio 4: NoSQL and Advanced Data Models

## Expected Evidence

NoSQL model based on the same case study, document/key-value/column/graph example, implementation evidence, and explanation of suitability.

## Implementation

This folder models the same Crestfield University Student Result Portal as a **document database** in MongoDB Atlas. It uses the same students, courses, grading scale and carry-over rules as Portfolios 1–3.

| File | Purpose |
|---|---|
| `01_setup.js` | Creates the `crestfield_university` database, with two collections, schema validation, indexes and sample data |
| `02_queries.js` | Eight demonstrations: transcript lookup, array queries, updates, validation, aggregation, `$lookup` and indexing |
| `screenshots/` | Output from running each block in the MongoDB shell in Compass |

**Tools used:** MongoDB Atlas (free M0 cluster), MongoDB Compass with its built-in MongoDB shell (mongosh).

### Document model

I used two collections, choosing between **embedding** and **referencing** according to how the data is used.

**`students`: results are embedded.** Each student is one document, and their full academic record is stored inside it as a `results` array. A transcript is always read as a whole, so storing it together means one read with no joins.

```js
{
  matric_number: 'CU/2025/00012',
  name: { first: 'Tunde', last: 'Balogun' },
  programme: { name: 'BSc Computer Science', department: 'Computer Science',
               faculty: 'Faculty of Science', maximum_level: 400 },
  entry_session: '2025/2026',
  current_level: 200,
  results: [
    { session: '2025/2026', semester: 'First Semester', course_code: 'MTH101',
      course_title: 'Elementary Mathematics', credit_unit: 3, attempt: 1,
      ca_score: 12, exam_score: 20, total_score: 32, grade: 'F', grade_point: 0 },
    { session: '2026/2027', semester: 'First Semester', course_code: 'MTH101',
      course_title: 'Elementary Mathematics', credit_unit: 3, attempt: 2,
      ca_score: 22, exam_score: 31, total_score: 53, grade: 'C', grade_point: 3 }
    // ...
  ]
}
```

A result with no scores represents a current registration that is still awaiting a result, for example Adaeze's CSC101 second attempt.

**`courses`: referenced by `course_code`.** Course details such as the assigned lecturer are shared by many students and can change independently. They are kept in their own collection and joined in with `$lookup` when needed.

**Schema validation:** MongoDB is schema-flexible, but I added a `$jsonSchema` validator to `students` that enforces the same rules as my Portfolio 1 CHECK constraints:
- CA score between 0 and 40, and exam score between 0 and 60
- attempt 1 or 2
- valid levels (100–500)
- valid grades (A–F)

**Indexes:**
- unique `matric_number` on `students`
- unique `course_code` on `courses`
- a multikey index on `results.course_code` + `results.session`, which indexes fields inside the embedded array

## How to Run / Test

1. In MongoDB Compass, connect to the Atlas cluster and open the MongoDB shell (`>_ Open MongoDB shell`).
2. Paste the whole of `01_setup.js` and press Enter. It finishes with `Courses: 6` and `Students: 5`.
3. Paste each numbered block from `02_queries.js` (Q1–Q8) one at a time, and check the output.

Running `01_setup.js` again drops and recreates both collections, which resets the data.

## Results and Evidence

| Screenshot | Demonstration | Result |
|---|---|---|
| `01-setup.png` | Setup | 6 courses and 5 students created |
| `02-q1-transcript.png` | Q1: transcript with `findOne` | Tunde's full record returned in a single read, with no joins |
| `03-q2-failed-students.png` | Q2: `$elemMatch` on the results array | Students with an F in 2025/2026: Tunde Balogun and Chukwuma Nnamdi |
| `04-q3-q4-push-and-validation.png` | Q3: `$push` a new result. Q4: invalid exam score | Q3 succeeded (`modifiedCount: 1`). Q4 was rejected with `MongoServerError: Document failed validation` |
| `06-q5-cgpa.png` | Q5: CGPA aggregation (`$unwind`, `$group`, `$project`) | Zainab Abubakar 4.75, Halima Yusuf 3.38, Tunde Balogun 3.25, … |
| `07-q6-pass-rates.png` | Q6: pass rate and average per course | e.g. CSC101: 6 attempts, 4 passed, average 60.7, pass rate 66.7% |
| `08-q7-lookup.png` | Q7: `$lookup` to the `courses` collection | Each of Tunde's courses with its lecturer, e.g. CSC101 → John Adeyemi |
| `10-q8c-ixscan.png` | Q8: index on embedded fields | `FETCH` → `IXSCAN` on `results.course_code_1_results.session_1`, with `isMultiKey: true` |

## Notes / Analysis

**1. Why this model suits the transcript use case**

I chose this model because everything needed for a student's transcript is stored in one document. This means MongoDB can retrieve the entire transcript with a single read, instead of going through the six-table join we used in Portfolio 2, Query 4. This makes retrieving and displaying transcripts simpler and faster. I also indexed fields inside the embedded `results` array (a multikey index), so searches such as 'everyone who took CSC101 in 2025/2026' can still use an index.

**2. Embedding vs. referencing**

I embedded the results because they belong to a student and are always needed together when viewing the transcript. Courses, on the other hand, are referenced because they are shared across different students and can change independently. For example, if a course gets a new lecturer, I only need to update the course record instead of updating every student's document.

**3. Trade-offs MongoDB introduces**

One downside of this model is that course titles are copied into every result, so renaming a course means updating multiple documents. Also, MongoDB does not automatically enforce the business rules we implemented with triggers in Portfolio 3, such as the 24-unit cap, carry-over rule, and automatic grading. These would have to be handled by the application. The validator also checks that scores and grades are within the allowed ranges, but it does not check whether the grade actually matches the score.

**4. Where each database fits**

I would keep PostgreSQL as the system of record for registration and grading because these processes require strict rules and reliable transactions. MongoDB is better suited for displaying transcripts and results, especially on results-release day when many students may be checking their results at the same time. In practice, MongoDB would hold a copy of the results, refreshed from PostgreSQL whenever results are published, so the two databases need to be kept in sync.
