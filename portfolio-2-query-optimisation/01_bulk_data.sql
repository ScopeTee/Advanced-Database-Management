-- =====================================================
-- CRESTFIELD UNIVERSITY
-- PORTFOLIO 2 - BULK DATA GENERATION
-- File: 01_bulk_data.sql
-- Database: PostgreSQL 18
--
-- Purpose: create a realistic volume of data so that
-- query plans and indexing effects can be measured.
--
-- Requires: 01_schema.sql and 02_sample_data.sql from
-- Portfolio 1 (uses the existing grade scale, the
-- 2026/2027 session and the admin account).
-- Run ONCE. Expected run time: roughly 30-90 seconds.
--
-- What it creates:
--   5 faculties, 20 departments, 20 programmes
--   3 earlier sessions (2023/2024 - 2025/2026), 6 semesters
--   200 lecturers, 480 courses
--   50,000 students (100 - 400 level)
--   ~750,000 course registrations with results
--   carry-over (attempt 2) registrations for failed courses
-- =====================================================


-- -----------------------------------------------------
-- 1. FACULTIES (5)
-- -----------------------------------------------------
INSERT INTO faculty (faculty_name)
VALUES
    ('Faculty of Engineering'),
    ('Faculty of Social Sciences'),
    ('Faculty of Arts'),
    ('Faculty of Management Sciences'),
    ('Faculty of Environmental Sciences');


-- -----------------------------------------------------
-- 2. DEPARTMENTS (20) - department code kept in a
--    temporary table to build course codes later
-- -----------------------------------------------------
CREATE TEMP TABLE dept_seed (
    dept_code   VARCHAR(3),
    dept_name   VARCHAR(100),
    faculty     VARCHAR(100),
    max_level   INTEGER
);

INSERT INTO dept_seed VALUES
    ('MEE', 'Mechanical Engineering',         'Faculty of Engineering', 500),
    ('EEE', 'Electrical Engineering',         'Faculty of Engineering', 500),
    ('CVE', 'Civil Engineering',              'Faculty of Engineering', 500),
    ('CHE', 'Chemical Engineering',           'Faculty of Engineering', 500),
    ('ECO', 'Economics',                      'Faculty of Social Sciences', 400),
    ('POL', 'Political Science',              'Faculty of Social Sciences', 400),
    ('SOC', 'Sociology',                      'Faculty of Social Sciences', 400),
    ('PSY', 'Psychology',                     'Faculty of Social Sciences', 400),
    ('ENG', 'English',                        'Faculty of Arts', 400),
    ('HIS', 'History',                        'Faculty of Arts', 400),
    ('PHI', 'Philosophy',                     'Faculty of Arts', 400),
    ('LIN', 'Linguistics',                    'Faculty of Arts', 400),
    ('ACC', 'Accounting',                     'Faculty of Management Sciences', 400),
    ('BUS', 'Business Administration',        'Faculty of Management Sciences', 400),
    ('BFN', 'Banking and Finance',            'Faculty of Management Sciences', 400),
    ('MKT', 'Marketing',                      'Faculty of Management Sciences', 400),
    ('ARC', 'Architecture',                   'Faculty of Environmental Sciences', 500),
    ('EST', 'Estate Management',              'Faculty of Environmental Sciences', 400),
    ('URP', 'Urban and Regional Planning',    'Faculty of Environmental Sciences', 400),
    ('QSV', 'Quantity Surveying',             'Faculty of Environmental Sciences', 400);

INSERT INTO department (faculty_id, department_name)
SELECT f.faculty_id, d.dept_name
FROM dept_seed d
JOIN faculty f ON f.faculty_name = d.faculty;


-- -----------------------------------------------------
-- 3. PROGRAMMES (one per new department)
-- -----------------------------------------------------
INSERT INTO programme (department_id, programme_name, award_type, maximum_level)
SELECT dp.department_id, 'BSc ' || d.dept_name, 'Bachelor', d.max_level
FROM dept_seed d
JOIN department dp ON dp.department_name = d.dept_name;


-- -----------------------------------------------------
-- 4. EARLIER SESSIONS AND THEIR SEMESTERS
--    (2026/2027 already exists from the sample data)
-- -----------------------------------------------------
INSERT INTO academic_session (session_name, start_date, end_date)
SELECT y || '/' || (y + 1),
       make_date(y, 9, 1),
       make_date(y + 1, 7, 31)
FROM generate_series(2023, 2025) AS y;

INSERT INTO semester (session_id, semester_name, start_date, end_date)
SELECT a.session_id, 'First Semester',
       make_date(LEFT(a.session_name, 4)::INT, 9, 1),
       make_date(LEFT(a.session_name, 4)::INT + 1, 1, 31)
FROM academic_session a
WHERE a.session_name IN ('2023/2024', '2024/2025', '2025/2026')
UNION ALL
SELECT a.session_id, 'Second Semester',
       make_date(LEFT(a.session_name, 4)::INT + 1, 2, 1),
       make_date(LEFT(a.session_name, 4)::INT + 1, 7, 31)
FROM academic_session a
WHERE a.session_name IN ('2023/2024', '2024/2025', '2025/2026');


-- -----------------------------------------------------
-- 5. LECTURERS (10 per department = 200)
-- -----------------------------------------------------
INSERT INTO user_account (email, password_hash, role)
SELECT 'lecturer' || n || '@crestfield.edu.ng', 'sample_hash', 'Lecturer'
FROM generate_series(1, 200) AS n;

INSERT INTO lecturer (department_id, user_id, staff_number, first_name, last_name)
SELECT
    dp.department_id,
    u.user_id,
    'STF/' || (1000 + n),
    (ARRAY['Chinedu','Funmilayo','Ibrahim','Ngozi','Olumide',
           'Aisha','Emeka','Yetunde','Musa','Chiamaka'])[1 + n % 10],
    (ARRAY['Okeke','Adebayo','Bello','Eze','Ogunleye',
           'Danjuma','Nwosu','Akinola','Usman','Obi'])[1 + (n / 10) % 10]
FROM generate_series(1, 200) AS n
JOIN user_account u ON u.email = 'lecturer' || n || '@crestfield.edu.ng'
JOIN dept_seed d ON d.dept_code = (SELECT dept_code FROM dept_seed
                                   ORDER BY dept_code
                                   OFFSET ((n - 1) % 20) LIMIT 1)
JOIN department dp ON dp.department_name = d.dept_name;


-- -----------------------------------------------------
-- 6. COURSES (6 per level, 100-400, per department = 480)
--    Course number 1-3 = First Semester, 4-6 = Second.
--    Credit units 2-4, so a normal semester is 9 units.
-- -----------------------------------------------------
INSERT INTO course (department_id, assigned_lecturer_id, course_code,
                    course_title, credit_unit)
SELECT
    dp.department_id,
    (SELECT l.lecturer_id FROM lecturer l
     WHERE l.department_id = dp.department_id
     ORDER BY l.lecturer_id
     OFFSET (lvl / 100 + i) % 10 LIMIT 1),
    d.dept_code || (lvl + i),
    d.dept_name || ' ' || (lvl / 100) || '0' || i,
    2 + (i % 3)
FROM dept_seed d
JOIN department dp ON dp.department_name = d.dept_name
CROSS JOIN generate_series(100, 400, 100) AS lvl
CROSS JOIN generate_series(1, 6) AS i;

-- Link each course to its department's programme
INSERT INTO programme_course (programme_id, course_id, study_level, course_type)
SELECT p.programme_id, c.course_id,
       (SUBSTRING(c.course_code FROM 4 FOR 1)::INT) * 100,
       CASE WHEN RIGHT(c.course_code, 1) = '6' THEN 'Elective' ELSE 'Compulsory' END
FROM course c
JOIN programme p ON p.department_id = c.department_id
JOIN dept_seed d ON LEFT(c.course_code, 3) = d.dept_code;

-- Record the initial lecturer assignment for each new course
INSERT INTO lecturer_assignment_history (course_id, lecturer_id, effective_from,
                                         changed_by_user_id)
SELECT c.course_id, c.assigned_lecturer_id, '2023-09-01', u.user_id
FROM course c
JOIN dept_seed d ON LEFT(c.course_code, 3) = d.dept_code
JOIN user_account u ON u.email = 'admin@crestfield.edu.ng';


-- -----------------------------------------------------
-- 7. STUDENTS (50,000)
--    Entry session decides the current level:
--    2023 -> 400, 2024 -> 300, 2025 -> 200, 2026 -> 100
--    Matric format CU/<year>/<5 digits> so it never
--    clashes with the sample student CU/2026/001.
-- -----------------------------------------------------
INSERT INTO user_account (email, password_hash, role)
SELECT 'student' || n || '@crestfield.edu.ng', 'sample_hash', 'Student'
FROM generate_series(1, 50000) AS n;

INSERT INTO student (programme_id, user_id, entry_session_id, matric_number,
                     first_name, last_name, admission_date, current_level)
SELECT
    p.programme_id,
    u.user_id,
    a.session_id,
    'CU/' || (2023 + n % 4) || '/' || LPAD(n::TEXT, 5, '0'),
    (ARRAY['Adaeze','Tunde','Zainab','Chukwuma','Bisi','Halima','Ifeanyi',
           'Kemi','Sani','Nkechi','Femi','Amina','Obinna','Tolu','Hauwa',
           'Kelechi','Segun','Fatima','Uche','Bukola'])[1 + n % 20],
    (ARRAY['Okafor','Adeyemi','Abubakar','Nnamdi','Balogun','Ibrahim',
           'Chukwu','Oladipo','Garba','Onyeka','Afolabi','Yusuf','Ezeh',
           'Ojo','Lawal','Okonkwo','Salami','Mohammed','Ani','Fashola'])[1 + (n / 20) % 20],
    a.start_date,
    (2027 - (2023 + n % 4)) * 100
FROM generate_series(1, 50000) AS n
JOIN user_account u ON u.email = 'student' || n || '@crestfield.edu.ng'
JOIN academic_session a ON a.session_name = (2023 + n % 4) || '/' || (2024 + n % 4)
JOIN programme p ON p.programme_name = 'BSc ' ||
     (SELECT dept_name FROM dept_seed ORDER BY dept_code OFFSET ((n / 4) % 20) LIMIT 1);


-- -----------------------------------------------------
-- 8. REGISTRATIONS - ATTEMPT 1
--    Each student registers for their programme's
--    courses at the level matching each session since
--    entry. Everything is 'Completed' (has a result)
--    except 2026/2027 Second Semester, which is the
--    current semester and still awaiting results.
-- -----------------------------------------------------
INSERT INTO course_registration (student_id, course_id, semester_id,
                                 attempt_number, registration_status,
                                 registration_date)
SELECT
    s.student_id,
    c.course_id,
    sem.semester_id,
    1,
    CASE WHEN a.session_name = '2026/2027' AND sem.semester_name = 'Second Semester'
         THEN 'Registered' ELSE 'Completed' END,
    sem.start_date
FROM student s
JOIN academic_session entry ON entry.session_id = s.entry_session_id
JOIN programme_course pc ON pc.programme_id = s.programme_id
JOIN course c ON c.course_id = pc.course_id
JOIN academic_session a
     ON LEFT(a.session_name, 4)::INT
        = LEFT(entry.session_name, 4)::INT + pc.study_level / 100 - 1
JOIN semester sem
     ON sem.session_id = a.session_id
    AND sem.semester_name = CASE WHEN RIGHT(c.course_code, 1)::INT <= 3
                                 THEN 'First Semester' ELSE 'Second Semester' END
WHERE s.matric_number LIKE 'CU/____/_____'
  AND pc.study_level <= s.current_level;


-- -----------------------------------------------------
-- 9. RESULTS FOR COMPLETED ATTEMPT-1 REGISTRATIONS
--    CA 10-40, exam 15-60. grade_id is looked up from
--    grade_scale so it always matches total_score.
-- -----------------------------------------------------
INSERT INTO result (registration_id, ca_score, exam_score, grade_id, result_date)
SELECT x.registration_id, x.ca, x.ex, gs.grade_id, x.end_date
FROM (
    SELECT cr.registration_id,
           10 + FLOOR(RANDOM() * 31) AS ca,
           15 + FLOOR(RANDOM() * 46) AS ex,
           sem.end_date
    FROM course_registration cr
    JOIN student s ON s.student_id = cr.student_id
    JOIN semester sem ON sem.semester_id = cr.semester_id
    WHERE cr.registration_status = 'Completed'
      AND s.matric_number LIKE 'CU/____/_____'
    OFFSET 0  -- keeps RANDOM() evaluated once per row
) x
JOIN grade_scale gs ON (x.ca + x.ex) BETWEEN gs.minimum_score AND gs.maximum_score;


-- -----------------------------------------------------
-- 10. CARRY-OVERS - ATTEMPT 2
--     Every F from 2023/2024 - 2025/2026 is retaken in
--     the same semester of the following session.
-- -----------------------------------------------------
INSERT INTO course_registration (student_id, course_id, semester_id,
                                 attempt_number, registration_status,
                                 registration_date)
SELECT
    cr.student_id,
    cr.course_id,
    next_sem.semester_id,
    2,
    CASE WHEN next_a.session_name = '2026/2027' AND next_sem.semester_name = 'Second Semester'
         THEN 'Registered' ELSE 'Completed' END,
    next_sem.start_date
FROM course_registration cr
JOIN result r ON r.registration_id = cr.registration_id
JOIN grade_scale gs ON gs.grade_id = r.grade_id AND gs.grade = 'F'
JOIN semester sem ON sem.semester_id = cr.semester_id
JOIN academic_session a ON a.session_id = sem.session_id
JOIN academic_session next_a
     ON LEFT(next_a.session_name, 4)::INT = LEFT(a.session_name, 4)::INT + 1
JOIN semester next_sem
     ON next_sem.session_id = next_a.session_id
    AND next_sem.semester_name = sem.semester_name
JOIN student s ON s.student_id = cr.student_id
WHERE cr.attempt_number = 1
  AND s.matric_number LIKE 'CU/____/_____';

-- Results for completed carry-overs (slightly better scores)
INSERT INTO result (registration_id, ca_score, exam_score, grade_id, result_date)
SELECT x.registration_id, x.ca, x.ex, gs.grade_id, x.end_date
FROM (
    SELECT cr.registration_id,
           15 + FLOOR(RANDOM() * 26) AS ca,
           20 + FLOOR(RANDOM() * 41) AS ex,
           sem.end_date
    FROM course_registration cr
    JOIN semester sem ON sem.semester_id = cr.semester_id
    LEFT JOIN result r ON r.registration_id = cr.registration_id
    WHERE cr.attempt_number = 2
      AND cr.registration_status = 'Completed'
      AND r.result_id IS NULL
    OFFSET 0
) x
JOIN grade_scale gs ON (x.ca + x.ex) BETWEEN gs.minimum_score AND gs.maximum_score;


-- -----------------------------------------------------
-- 11. CLEAN UP AND REFRESH PLANNER STATISTICS
-- -----------------------------------------------------
DROP TABLE dept_seed;

ANALYZE;


-- -----------------------------------------------------
-- 12. CHECK THE VOLUMES
-- -----------------------------------------------------
SELECT 'students' AS item, COUNT(*) FROM student
UNION ALL SELECT 'courses', COUNT(*) FROM course
UNION ALL SELECT 'registrations', COUNT(*) FROM course_registration
UNION ALL SELECT 'results', COUNT(*) FROM result
UNION ALL SELECT 'carry-overs (attempt 2)', COUNT(*) FROM course_registration WHERE attempt_number = 2;
