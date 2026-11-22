-- =========================================================
-- CRESTFIELD UNIVERSITY - STUDENT RESULT PORTAL
-- PORTFOLIO 2: QUERY PROCESSING AND OPTIMISATION
-- File: 02_queries.sql
-- Database: PostgreSQL 18
--
-- Run after 01_bulk_data.sql. Highlight one query at a
-- time and press F5 (or Shift+F7 for Explain Analyze).
-- No extra indexes exist yet: these are the baseline runs.
-- =========================================================


-- ---------------------------------------------------------
-- QUERY 1: Class list - all students registered for a
-- course in a particular semester.
-- Used by: lecturers (attendance, score upload), admin.
--
-- INDEXING DEMONSTRATION 1 (composite index)
-- Filter columns: course_registration.course_id + semester_id
-- No existing index starts with course_id, so PostgreSQL
-- must scan every registration to find this class.
-- ---------------------------------------------------------
SELECT
    s.matric_number,
    s.first_name,
    s.last_name,
    c.course_code,
    c.course_title,
    a.session_name,
    sem.semester_name,
    cr.attempt_number,
    cr.registration_status
FROM course_registration cr
JOIN student s          ON s.student_id   = cr.student_id
JOIN course c           ON c.course_id    = cr.course_id
JOIN semester sem       ON sem.semester_id = cr.semester_id
JOIN academic_session a ON a.session_id   = sem.session_id
WHERE c.course_code     = 'MEE101'
  AND a.session_name    = '2025/2026'
  AND sem.semester_name = 'First Semester'
ORDER BY s.last_name, s.first_name;


-- ---------------------------------------------------------
-- QUERY 2: All failed results (grade F) in an academic
-- session - used to identify students with carry-overs.
--
-- INDEXING DEMONSTRATION 2 (low selectivity case)
-- Filter column: result.grade_id
-- grade_id has only 6 distinct values and F is roughly 8%
-- of all results, so an index may NOT be used. This query
-- tests whether the planner prefers a sequential scan.
-- ---------------------------------------------------------
SELECT
    s.matric_number,
    s.first_name,
    s.last_name,
    c.course_code,
    sem.semester_name,
    cr.attempt_number,
    r.total_score,
    gs.grade
FROM result r
JOIN grade_scale gs         ON gs.grade_id        = r.grade_id
JOIN course_registration cr ON cr.registration_id = r.registration_id
JOIN student s              ON s.student_id       = cr.student_id
JOIN course c               ON c.course_id        = cr.course_id
JOIN semester sem           ON sem.semester_id    = cr.semester_id
JOIN academic_session a     ON a.session_id       = sem.session_id
WHERE gs.grade        = 'F'
  AND a.session_name  = '2025/2026'
ORDER BY c.course_code, s.matric_number;


-- ---------------------------------------------------------
-- QUERY 3: Search for students by surname.
-- Used by: admin staff looking up a student.
--
-- INDEXING DEMONSTRATION 3 (single-column index)
-- Filter column: student.last_name (not indexed yet).
-- An exact match is used: a plain B-tree index cannot
-- serve case-insensitive ILIKE searches.
-- ---------------------------------------------------------
SELECT
    s.matric_number,
    s.first_name,
    s.last_name,
    s.current_level,
    p.programme_name
FROM student s
JOIN programme p ON p.programme_id = s.programme_id
WHERE s.last_name = 'Okafor'
ORDER BY s.first_name, s.matric_number;


-- ---------------------------------------------------------
-- QUERY 4: Academic transcript for one student.
-- LEFT JOIN keeps current-semester registrations that do
-- not have a result yet.
-- (matric_number and student_id are already indexed, so
-- this query is fast without any new index.)
-- ---------------------------------------------------------
SELECT
    a.session_name,
    sem.semester_name,
    c.course_code,
    c.course_title,
    c.credit_unit,
    cr.attempt_number,
    r.ca_score,
    r.exam_score,
    r.total_score,
    gs.grade,
    gs.grade_point
FROM student s
JOIN course_registration cr ON cr.student_id   = s.student_id
JOIN course c               ON c.course_id     = cr.course_id
JOIN semester sem           ON sem.semester_id = cr.semester_id
JOIN academic_session a     ON a.session_id    = sem.session_id
LEFT JOIN result r          ON r.registration_id = cr.registration_id
LEFT JOIN grade_scale gs    ON gs.grade_id     = r.grade_id
WHERE s.matric_number = 'CU/2023/00004'
ORDER BY a.session_name, sem.start_date, c.course_code;


-- ---------------------------------------------------------
-- QUERY 5: Courses with the most failures in a session.
-- Used by: heads of department reviewing difficult courses.
-- ---------------------------------------------------------
SELECT
    c.course_code,
    c.course_title,
    COUNT(*) AS failed_results
FROM result r
JOIN grade_scale gs         ON gs.grade_id        = r.grade_id
JOIN course_registration cr ON cr.registration_id = r.registration_id
JOIN course c               ON c.course_id        = cr.course_id
JOIN semester sem           ON sem.semester_id    = cr.semester_id
JOIN academic_session a     ON a.session_id       = sem.session_id
WHERE gs.grade       = 'F'
  AND a.session_name = '2025/2026'
GROUP BY c.course_code, c.course_title
ORDER BY failed_results DESC, c.course_code
LIMIT 10;


-- ---------------------------------------------------------
-- QUERY 6: Top 10 final-year (400 level) students in each
-- department by CGPA.
-- CGPA = SUM(grade_point x credit_unit) / SUM(credit_unit)
-- over all graded courses, including carry-over attempts.
-- RANK() is a window function: it ranks students within
-- each department (PARTITION BY) without collapsing rows.
-- ---------------------------------------------------------
WITH student_cgpa AS (
    SELECT
        d.department_name,
        s.matric_number,
        s.first_name,
        s.last_name,
        SUM(c.credit_unit) AS total_units,
        ROUND(SUM(gs.grade_point * c.credit_unit)
              / SUM(c.credit_unit), 2) AS cgpa
    FROM student s
    JOIN programme p            ON p.programme_id     = s.programme_id
    JOIN department d           ON d.department_id    = p.department_id
    JOIN course_registration cr ON cr.student_id      = s.student_id
    JOIN course c               ON c.course_id        = cr.course_id
    JOIN result r               ON r.registration_id  = cr.registration_id
    JOIN grade_scale gs         ON gs.grade_id        = r.grade_id
    WHERE s.current_level = 400
    GROUP BY d.department_name, s.matric_number, s.first_name, s.last_name
),
ranked AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY department_name
                     ORDER BY cgpa DESC) AS department_rank
    FROM student_cgpa
)
SELECT
    department_name,
    department_rank,
    matric_number,
    first_name,
    last_name,
    total_units,
    cgpa
FROM ranked
WHERE department_rank <= 10
ORDER BY department_name, department_rank, matric_number;
