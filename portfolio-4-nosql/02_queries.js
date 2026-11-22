// =========================================================
// CRESTFIELD UNIVERSITY - STUDENT RESULT PORTAL
// PORTFOLIO 4: NOSQL AND ADVANCED DATA MODELS
// File: 02_queries.js
// Database: MongoDB Atlas (MongoDB shell in Compass)
//
// Run after 01_setup.js. Paste ONE numbered block at a time
// into the shell, press Enter, and screenshot the output.
// =========================================================

use('crestfield_university');


// ---------------------------------------------------------
// Q1. TRANSCRIPT - one student's full record
// One read returns everything: no joins are needed because
// the results are embedded in the student document.
// (Compare with the 6-table join in Portfolio 2, Query 4.)
// ---------------------------------------------------------
db.students.findOne(
  { matric_number: 'CU/2025/00012' },
  { _id: 0, matric_number: 1, name: 1, current_level: 1, results: 1 }
);


// ---------------------------------------------------------
// Q2. STUDENTS WITH A FAILED COURSE IN A SESSION
// $elemMatch requires the SAME array element to match both
// conditions (session = 2025/2026 AND grade = F).
// ---------------------------------------------------------
db.students.find(
  { results: { $elemMatch: { session: '2025/2026', grade: 'F' } } },
  { _id: 0, matric_number: 1, 'name.first': 1, 'name.last': 1 }
);


// ---------------------------------------------------------
// Q3. LECTURER UPLOADS A NEW RESULT ($push)
// Adds a result to Zainab's embedded results array.
// ---------------------------------------------------------
db.students.updateOne(
  { matric_number: 'CU/2025/00027' },
  { $push: { results: {
      session: '2026/2027', semester: 'First Semester', course_code: 'MTH201',
      course_title: 'Linear Algebra', credit_unit: 3, attempt: 1,
      ca_score: 31, exam_score: 46, total_score: 77, grade: 'A', grade_point: 5
  } } }
);


// ---------------------------------------------------------
// Q4. SCHEMA VALIDATION REJECTS AN INVALID RESULT
// Exam score 75 breaks the $jsonSchema rule (maximum 60),
// so MongoDB refuses the update: "Document failed validation".
// ---------------------------------------------------------
db.students.updateOne(
  { matric_number: 'CU/2025/00027' },
  { $push: { results: {
      session: '2026/2027', semester: 'First Semester', course_code: 'GST101',
      course_title: 'Use of English', credit_unit: 2, attempt: 1,
      ca_score: 20, exam_score: 75
  } } }
);


// ---------------------------------------------------------
// Q5. CGPA FOR EVERY STUDENT (aggregation pipeline)
// $unwind turns each embedded result into its own row,
// $match keeps graded results only, $group computes
// SUM(grade_point x credit_unit) / SUM(credit_unit).
// ---------------------------------------------------------
db.students.aggregate([
  { $unwind: '$results' },
  { $match: { 'results.grade': { $exists: true } } },
  { $group: {
      _id: '$matric_number',
      name: { $first: { $concat: ['$name.first', ' ', '$name.last'] } },
      total_units: { $sum: '$results.credit_unit' },
      weighted_points: { $sum: { $multiply: ['$results.grade_point', '$results.credit_unit'] } }
  } },
  { $project: {
      _id: 0, matric_number: '$_id', name: 1, total_units: 1,
      cgpa: { $round: [{ $divide: ['$weighted_points', '$total_units'] }, 2] }
  } },
  { $sort: { cgpa: -1 } }
]);


// ---------------------------------------------------------
// Q6. PASS RATE AND AVERAGE SCORE PER COURSE
// ---------------------------------------------------------
db.students.aggregate([
  { $unwind: '$results' },
  { $match: { 'results.grade': { $exists: true } } },
  { $group: {
      _id: '$results.course_code',
      attempts: { $sum: 1 },
      passed: { $sum: { $cond: [{ $ne: ['$results.grade', 'F'] }, 1, 0] } },
      average_score: { $avg: '$results.total_score' }
  } },
  { $project: {
      _id: 0, course_code: '$_id', attempts: 1, passed: 1,
      average_score: { $round: ['$average_score', 1] },
      pass_rate_percent: { $round: [{ $multiply: [{ $divide: ['$passed', '$attempts'] }, 100] }, 1] }
  } },
  { $sort: { course_code: 1 } }
]);


// ---------------------------------------------------------
// Q7. REFERENCING WITH $lookup
// Course details that change independently (e.g. the
// lecturer) live in the courses collection and are joined
// in when needed: who teaches each course Tunde took?
// ---------------------------------------------------------
db.students.aggregate([
  { $match: { matric_number: 'CU/2025/00012' } },
  { $unwind: '$results' },
  { $lookup: {
      from: 'courses',
      localField: 'results.course_code',
      foreignField: 'course_code',
      as: 'course'
  } },
  { $unwind: '$course' },
  { $project: {
      _id: 0,
      course_code: '$results.course_code',
      session: '$results.session',
      grade: '$results.grade',
      lecturer: '$course.lecturer.name'
  } }
]);


// ---------------------------------------------------------
// Q8. INDEXING AN EMBEDDED FIELD
// Find every student who took CSC101 in 2025/2026.
// First check the plan WITHOUT an index (COLLSCAN), then
// create a multikey index on the embedded array fields and
// check again (IXSCAN).
// ---------------------------------------------------------

// 8a. before the index -> look for "stage: 'COLLSCAN'"
db.students.find(
  { results: { $elemMatch: { course_code: 'CSC101', session: '2025/2026' } } }
).explain('queryPlanner').queryPlanner.winningPlan;

// 8b. create the index
db.students.createIndex({ 'results.course_code': 1, 'results.session': 1 });

// 8c. after the index -> look for "stage: 'IXSCAN'"
db.students.find(
  { results: { $elemMatch: { course_code: 'CSC101', session: '2025/2026' } } }
).explain('queryPlanner').queryPlanner.winningPlan;
