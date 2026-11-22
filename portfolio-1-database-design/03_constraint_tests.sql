-- =====================================================
-- CRESTFIELD UNIVERSITY
-- PORTFOLIO 1 - VERIFICATION QUERY AND CONSTRAINT TESTS
-- File: 03_constraint_tests.sql
-- Database: PostgreSQL
-- Run after 01_schema.sql and 02_sample_data.sql.
-- Run each test individually: PostgreSQL aborts the
-- current transaction after a statement error.
-- =====================================================


-- =====================================================
-- VERIFICATION: the student's course attempts and results
-- Expected:
--   Attempt 1 | First Semester  | 35.00 | F
--   Attempt 2 | Second Semester | NULL  | NULL  (carry-over, awaiting result)
-- =====================================================

SELECT
    s.matric_number,
    s.first_name,
    c.course_code,
    c.course_title,
    sem.semester_name,
    cr.attempt_number,
    r.ca_score,
    r.exam_score,
    r.total_score,
    gs.grade,
    gs.grade_point
FROM course_registration cr
JOIN student s
    ON s.student_id = cr.student_id
JOIN course c
    ON c.course_id = cr.course_id
JOIN semester sem
    ON sem.semester_id = cr.semester_id
LEFT JOIN result r
    ON r.registration_id = cr.registration_id
LEFT JOIN grade_scale gs
    ON gs.grade_id = r.grade_id
WHERE s.matric_number = 'CU/2026/001'
ORDER BY cr.attempt_number;


-- =====================================================
-- TEST 1: Examination score above 60
-- Expected error:
--   violates check constraint "chk_exam_score"
-- =====================================================

INSERT INTO result (
    registration_id,
    ca_score,
    exam_score,
    grade_id
)
SELECT
    cr.registration_id,
    20,
    75,
    gs.grade_id
FROM course_registration cr
JOIN student s
    ON s.student_id = cr.student_id
JOIN course c
    ON c.course_id = cr.course_id
JOIN grade_scale gs
    ON gs.grade = 'F'
WHERE s.matric_number = 'CU/2026/001'
AND c.course_code = 'CSC101'
AND cr.attempt_number = 2;


-- =====================================================
-- TEST 2: Third attempt at a course
-- Expected error:
--   violates check constraint "chk_attempt_number"
-- =====================================================

INSERT INTO course_registration (
    student_id,
    course_id,
    semester_id,
    attempt_number
)
SELECT
    cr.student_id,
    cr.course_id,
    cr.semester_id,
    3
FROM course_registration cr
JOIN student s
    ON s.student_id = cr.student_id
WHERE s.matric_number = 'CU/2026/001'
AND cr.attempt_number = 2;


-- =====================================================
-- TEST 3: Duplicate matriculation number
-- Expected error:
--   duplicate key value violates unique constraint
--   "student_matric_number_key"
-- =====================================================

INSERT INTO student (
    programme_id,
    entry_session_id,
    matric_number,
    first_name,
    last_name,
    admission_date,
    current_level
)
SELECT
    programme_id,
    entry_session_id,
    'CU/2026/001',
    'Another',
    'Student',
    '2026-09-01',
    100
FROM student
WHERE matric_number = 'CU/2026/001';
