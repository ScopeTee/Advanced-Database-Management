-- =====================================================
-- CRESTFIELD UNIVERSITY
-- PORTFOLIO 1 - SAMPLE DATA
-- File: 02_sample_data.sql
-- Database: PostgreSQL
-- =====================================================

-- 1. FACULTY
INSERT INTO faculty (faculty_name)
VALUES ('Faculty of Science');

-- 2. DEPARTMENT
INSERT INTO department (faculty_id, department_name)
SELECT faculty_id, 'Computer Science'
FROM faculty
WHERE faculty_name = 'Faculty of Science';

-- 3. PROGRAMME
INSERT INTO programme (
    department_id,
    programme_name,
    award_type,
    maximum_level
)
SELECT
    department_id,
    'BSc Computer Science',
    'Bachelor',
    400
FROM department
WHERE department_name = 'Computer Science';

-- 4. ACADEMIC SESSION
INSERT INTO academic_session (
    session_name,
    start_date,
    end_date
)
VALUES (
    '2026/2027',
    '2026-09-01',
    '2027-07-31'
);

-- 5. SEMESTERS
INSERT INTO semester (
    session_id,
    semester_name,
    start_date,
    end_date
)
SELECT session_id, 'First Semester',
       '2026-09-01', '2027-01-31'
FROM academic_session
WHERE session_name = '2026/2027';

INSERT INTO semester (
    session_id,
    semester_name,
    start_date,
    end_date
)
SELECT session_id, 'Second Semester',
       '2027-02-01', '2027-07-31'
FROM academic_session
WHERE session_name = '2026/2027';

-- 6. USER ACCOUNTS
INSERT INTO user_account (
    email, password_hash, role
)
VALUES
    ('adaeze@crestfield.edu.ng', 'sample_hash_student', 'Student'),
    ('john@crestfield.edu.ng', 'sample_hash_lecturer', 'Lecturer'),
    ('admin@crestfield.edu.ng', 'sample_hash_admin', 'Admin');

-- 7. STUDENT
INSERT INTO student (
    programme_id,
    user_id,
    entry_session_id,
    matric_number,
    first_name,
    last_name,
    admission_date,
    current_level
)
SELECT
    p.programme_id,
    u.user_id,
    a.session_id,
    'CU/2026/001',
    'Adaeze',
    'Okafor',
    '2026-09-01',
    100
FROM programme p
JOIN user_account u
    ON u.email = 'adaeze@crestfield.edu.ng'
JOIN academic_session a
    ON a.session_name = '2026/2027'
WHERE p.programme_name = 'BSc Computer Science';

-- 8. LECTURER
INSERT INTO lecturer (
    department_id,
    user_id,
    staff_number,
    first_name,
    last_name
)
SELECT
    d.department_id,
    u.user_id,
    'STF/001',
    'John',
    'Adeyemi'
FROM department d
JOIN user_account u
    ON u.email = 'john@crestfield.edu.ng'
WHERE d.department_name = 'Computer Science';

-- 9. COURSE
INSERT INTO course (
    department_id,
    assigned_lecturer_id,
    course_code,
    course_title,
    credit_unit
)
SELECT
    d.department_id,
    l.lecturer_id,
    'CSC101',
    'Introduction to Computing',
    3
FROM department d
JOIN lecturer l
    ON l.staff_number = 'STF/001'
WHERE d.department_name = 'Computer Science';

-- 10. PROGRAMME COURSE
INSERT INTO programme_course (
    programme_id,
    course_id,
    study_level,
    course_type
)
SELECT
    p.programme_id,
    c.course_id,
    100,
    'Compulsory'
FROM programme p
CROSS JOIN course c
WHERE p.programme_name = 'BSc Computer Science'
AND c.course_code = 'CSC101';

-- 11. LECTURER ASSIGNMENT HISTORY
INSERT INTO lecturer_assignment_history (
    course_id,
    lecturer_id,
    effective_from,
    changed_by_user_id
)
SELECT
    c.course_id,
    l.lecturer_id,
    '2026-09-01',
    u.user_id
FROM course c
JOIN lecturer l
    ON l.lecturer_id = c.assigned_lecturer_id
JOIN user_account u
    ON u.email = 'admin@crestfield.edu.ng'
WHERE c.course_code = 'CSC101';

-- 12. GRADE SCALE
INSERT INTO grade_scale (
    grade,
    minimum_score,
    maximum_score,
    grade_point
)
VALUES
    ('A', 70.00, 100.00, 5.00),
    ('B', 60.00, 69.99, 4.00),
    ('C', 50.00, 59.99, 3.00),
    ('D', 45.00, 49.99, 2.00),
    ('E', 40.00, 44.99, 1.00),
    ('F', 0.00, 39.99, 0.00);

-- 13. COURSE REGISTRATION: ATTEMPT 1
INSERT INTO course_registration (
    student_id,
    course_id,
    semester_id,
    attempt_number
)
SELECT
    s.student_id,
    c.course_id,
    sem.semester_id,
    1
FROM student s
JOIN course c
    ON c.course_code = 'CSC101'
JOIN semester sem
    ON sem.semester_name = 'First Semester'
WHERE s.matric_number = 'CU/2026/001';

-- 14. RESULT: FAILED ATTEMPT 1
INSERT INTO result (
    registration_id,
    ca_score,
    exam_score,
    grade_id
)
SELECT
    cr.registration_id,
    15.00,
    20.00,
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
AND cr.attempt_number = 1;

-- 15. COURSE REGISTRATION: CARRY-OVER ATTEMPT 2
-- A carry-over is identified by attempt_number = 2.
INSERT INTO course_registration (
    student_id,
    course_id,
    semester_id,
    attempt_number
)
SELECT
    s.student_id,
    c.course_id,
    sem.semester_id,
    2
FROM student s
JOIN course c
    ON c.course_code = 'CSC101'
JOIN semester sem
    ON sem.semester_name = 'Second Semester'
WHERE s.matric_number = 'CU/2026/001'
AND EXISTS (
    SELECT 1
    FROM course_registration previous_cr
    JOIN result previous_result
        ON previous_result.registration_id =
           previous_cr.registration_id
    JOIN grade_scale previous_grade
        ON previous_grade.grade_id =
           previous_result.grade_id
    WHERE previous_cr.student_id = s.student_id
    AND previous_cr.course_id = c.course_id
    AND previous_grade.grade = 'F'
);
