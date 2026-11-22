// =========================================================
// CRESTFIELD UNIVERSITY - STUDENT RESULT PORTAL
// PORTFOLIO 4: NOSQL AND ADVANCED DATA MODELS
// File: 01_setup.js
// Database: MongoDB Atlas (run in the MongoDB shell in Compass)
//
// Document model for the same case study:
//   students - one document per student, with their full
//              academic record EMBEDDED as a results array
//              (read together, so stored together)
//   courses  - the course catalogue, REFERENCED by
//              course_code (shared by many students and
//              updated independently, e.g. lecturer changes)
//
// Paste this whole file into the shell and press Enter.
// =========================================================

use('crestfield_university');

db.students.drop();
db.courses.drop();


// ---------------------------------------------------------
// 1. COURSES COLLECTION (referenced data)
// ---------------------------------------------------------
db.courses.insertMany([
  { course_code: 'CSC101', title: 'Introduction to Computing', credit_unit: 3, level: 100,
    department: 'Computer Science', lecturer: { staff_number: 'STF/001', name: 'John Adeyemi' } },
  { course_code: 'CSC102', title: 'Programming Fundamentals',  credit_unit: 3, level: 100,
    department: 'Computer Science', lecturer: { staff_number: 'STF/001', name: 'John Adeyemi' } },
  { course_code: 'CSC201', title: 'Data Structures',           credit_unit: 4, level: 200,
    department: 'Computer Science', lecturer: { staff_number: 'STF/002', name: 'Funmilayo Bello' } },
  { course_code: 'MTH101', title: 'Elementary Mathematics',    credit_unit: 3, level: 100,
    department: 'Mathematics',      lecturer: { staff_number: 'STF/003', name: 'Ibrahim Musa' } },
  { course_code: 'MTH201', title: 'Linear Algebra',            credit_unit: 3, level: 200,
    department: 'Mathematics',      lecturer: { staff_number: 'STF/003', name: 'Ibrahim Musa' } },
  { course_code: 'GST101', title: 'Use of English',            credit_unit: 2, level: 100,
    department: 'General Studies',  lecturer: { staff_number: 'STF/004', name: 'Ngozi Eze' } }
]);

db.courses.createIndex({ course_code: 1 }, { unique: true });


// ---------------------------------------------------------
// 2. STUDENTS COLLECTION WITH SCHEMA VALIDATION
// MongoDB is schema-flexible, but $jsonSchema lets the
// database reject invalid documents - the equivalent of the
// CHECK constraints in Portfolio 1 (CA 0-40, exam 0-60,
// attempt 1-2, valid levels).
// ---------------------------------------------------------
db.createCollection('students', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['matric_number', 'name', 'programme', 'current_level', 'results'],
      properties: {
        matric_number: { bsonType: 'string' },
        current_level: { enum: [100, 200, 300, 400, 500] },
        results: {
          bsonType: 'array',
          items: {
            bsonType: 'object',
            required: ['session', 'semester', 'course_code', 'credit_unit', 'attempt'],
            properties: {
              attempt:    { enum: [1, 2] },
              ca_score:   { bsonType: ['int', 'double'], minimum: 0, maximum: 40 },
              exam_score: { bsonType: ['int', 'double'], minimum: 0, maximum: 60 },
              grade:      { enum: ['A', 'B', 'C', 'D', 'E', 'F'] }
            }
          }
        }
      }
    }
  }
});

db.students.createIndex({ matric_number: 1 }, { unique: true });


// ---------------------------------------------------------
// 3. STUDENT DOCUMENTS (results embedded)
// A result without scores is a current registration that
// is still awaiting a result.
// ---------------------------------------------------------
db.students.insertMany([
  {
    matric_number: 'CU/2026/001',
    name: { first: 'Adaeze', last: 'Okafor' },
    programme: { name: 'BSc Computer Science', department: 'Computer Science',
                 faculty: 'Faculty of Science', maximum_level: 400 },
    entry_session: '2026/2027',
    current_level: 100,
    results: [
      { session: '2026/2027', semester: 'First Semester', course_code: 'CSC101',
        course_title: 'Introduction to Computing', credit_unit: 3, attempt: 1,
        ca_score: 18, exam_score: 20, total_score: 38, grade: 'F', grade_point: 0 },
      { session: '2026/2027', semester: 'First Semester', course_code: 'GST101',
        course_title: 'Use of English', credit_unit: 2, attempt: 1,
        ca_score: 30, exam_score: 42, total_score: 72, grade: 'A', grade_point: 5 },
      { session: '2026/2027', semester: 'Second Semester', course_code: 'CSC101',
        course_title: 'Introduction to Computing', credit_unit: 3, attempt: 2 }
    ]
  },
  {
    matric_number: 'CU/2025/00012',
    name: { first: 'Tunde', last: 'Balogun' },
    programme: { name: 'BSc Computer Science', department: 'Computer Science',
                 faculty: 'Faculty of Science', maximum_level: 400 },
    entry_session: '2025/2026',
    current_level: 200,
    results: [
      { session: '2025/2026', semester: 'First Semester', course_code: 'CSC101',
        course_title: 'Introduction to Computing', credit_unit: 3, attempt: 1,
        ca_score: 32, exam_score: 45, total_score: 77, grade: 'A', grade_point: 5 },
      { session: '2025/2026', semester: 'First Semester', course_code: 'MTH101',
        course_title: 'Elementary Mathematics', credit_unit: 3, attempt: 1,
        ca_score: 12, exam_score: 20, total_score: 32, grade: 'F', grade_point: 0 },
      { session: '2025/2026', semester: 'Second Semester', course_code: 'CSC102',
        course_title: 'Programming Fundamentals', credit_unit: 3, attempt: 1,
        ca_score: 25, exam_score: 38, total_score: 63, grade: 'B', grade_point: 4 },
      { session: '2026/2027', semester: 'First Semester', course_code: 'MTH101',
        course_title: 'Elementary Mathematics', credit_unit: 3, attempt: 2,
        ca_score: 22, exam_score: 31, total_score: 53, grade: 'C', grade_point: 3 },
      { session: '2026/2027', semester: 'First Semester', course_code: 'CSC201',
        course_title: 'Data Structures', credit_unit: 4, attempt: 1,
        ca_score: 28, exam_score: 40, total_score: 68, grade: 'B', grade_point: 4 }
    ]
  },
  {
    matric_number: 'CU/2025/00027',
    name: { first: 'Zainab', last: 'Abubakar' },
    programme: { name: 'BSc Computer Science', department: 'Computer Science',
                 faculty: 'Faculty of Science', maximum_level: 400 },
    entry_session: '2025/2026',
    current_level: 200,
    results: [
      { session: '2025/2026', semester: 'First Semester', course_code: 'CSC101',
        course_title: 'Introduction to Computing', credit_unit: 3, attempt: 1,
        ca_score: 36, exam_score: 52, total_score: 88, grade: 'A', grade_point: 5 },
      { session: '2025/2026', semester: 'First Semester', course_code: 'MTH101',
        course_title: 'Elementary Mathematics', credit_unit: 3, attempt: 1,
        ca_score: 30, exam_score: 41, total_score: 71, grade: 'A', grade_point: 5 },
      { session: '2025/2026', semester: 'Second Semester', course_code: 'CSC102',
        course_title: 'Programming Fundamentals', credit_unit: 3, attempt: 1,
        ca_score: 33, exam_score: 44, total_score: 77, grade: 'A', grade_point: 5 },
      { session: '2026/2027', semester: 'First Semester', course_code: 'CSC201',
        course_title: 'Data Structures', credit_unit: 4, attempt: 1,
        ca_score: 27, exam_score: 35, total_score: 62, grade: 'B', grade_point: 4 }
    ]
  },
  {
    matric_number: 'CU/2025/00031',
    name: { first: 'Chukwuma', last: 'Nnamdi' },
    programme: { name: 'BSc Computer Science', department: 'Computer Science',
                 faculty: 'Faculty of Science', maximum_level: 400 },
    entry_session: '2025/2026',
    current_level: 200,
    results: [
      { session: '2025/2026', semester: 'First Semester', course_code: 'CSC101',
        course_title: 'Introduction to Computing', credit_unit: 3, attempt: 1,
        ca_score: 15, exam_score: 21, total_score: 36, grade: 'F', grade_point: 0 },
      { session: '2025/2026', semester: 'First Semester', course_code: 'MTH101',
        course_title: 'Elementary Mathematics', credit_unit: 3, attempt: 1,
        ca_score: 20, exam_score: 27, total_score: 47, grade: 'D', grade_point: 2 },
      { session: '2025/2026', semester: 'Second Semester', course_code: 'CSC102',
        course_title: 'Programming Fundamentals', credit_unit: 3, attempt: 1,
        ca_score: 21, exam_score: 30, total_score: 51, grade: 'C', grade_point: 3 },
      { session: '2026/2027', semester: 'First Semester', course_code: 'CSC101',
        course_title: 'Introduction to Computing', credit_unit: 3, attempt: 2,
        ca_score: 24, exam_score: 33, total_score: 57, grade: 'C', grade_point: 3 }
    ]
  },
  {
    matric_number: 'CU/2024/00008',
    name: { first: 'Halima', last: 'Yusuf' },
    programme: { name: 'BSc Computer Science', department: 'Computer Science',
                 faculty: 'Faculty of Science', maximum_level: 400 },
    entry_session: '2024/2025',
    current_level: 300,
    results: [
      { session: '2024/2025', semester: 'First Semester', course_code: 'CSC101',
        course_title: 'Introduction to Computing', credit_unit: 3, attempt: 1,
        ca_score: 29, exam_score: 39, total_score: 68, grade: 'B', grade_point: 4 },
      { session: '2024/2025', semester: 'First Semester', course_code: 'MTH101',
        course_title: 'Elementary Mathematics', credit_unit: 3, attempt: 1,
        ca_score: 26, exam_score: 30, total_score: 56, grade: 'C', grade_point: 3 },
      { session: '2025/2026', semester: 'First Semester', course_code: 'CSC201',
        course_title: 'Data Structures', credit_unit: 4, attempt: 1,
        ca_score: 34, exam_score: 49, total_score: 83, grade: 'A', grade_point: 5 },
      { session: '2025/2026', semester: 'Second Semester', course_code: 'MTH201',
        course_title: 'Linear Algebra', credit_unit: 3, attempt: 1,
        ca_score: 18, exam_score: 25, total_score: 43, grade: 'E', grade_point: 1 }
    ]
  }
]);

print('Courses:  ' + db.courses.countDocuments());
print('Students: ' + db.students.countDocuments());
