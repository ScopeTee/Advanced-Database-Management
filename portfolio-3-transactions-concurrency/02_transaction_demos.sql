-- =========================================================
-- CRESTFIELD UNIVERSITY - STUDENT RESULT PORTAL
-- PORTFOLIO 3: TRANSACTIONS AND CONCURRENCY
-- File: 02_transaction_demos.sql
-- Database: PostgreSQL 18
--
-- Run after 01_triggers.sql, in ONE pgAdmin Query Tool.
-- Highlight and run each block separately (F5), and
-- screenshot the result of each.
--
-- All demos use the Portfolio 1 sample student Adaeze
-- Okafor (CU/2026/001), whose CSC101 first attempt was
-- CA 15 + exam 20 = 35 (F). CSC101 is assigned to the
-- lecturer John Adeyemi (john@crestfield.edu.ng).
-- =========================================================


-- ---------------------------------------------------------
-- HELPER QUERY: Adaeze's CSC101 attempt-1 result and its
-- audit log. Re-run this whenever a demo says "check".
-- ---------------------------------------------------------
SELECT r.result_id, r.ca_score, r.exam_score, r.total_score, gs.grade,
       (SELECT COUNT(*) FROM grade_change_log l
        WHERE l.result_id = r.result_id) AS audit_log_entries
FROM result r
JOIN grade_scale gs         ON gs.grade_id        = r.grade_id
JOIN course_registration cr ON cr.registration_id = r.registration_id
JOIN student s              ON s.student_id       = cr.student_id
JOIN course c               ON c.course_id        = cr.course_id
WHERE s.matric_number = 'CU/2026/001'
  AND c.course_code   = 'CSC101'
  AND cr.attempt_number = 1;


-- =========================================================
-- DEMO 1: COMMIT
-- The assigned lecturer corrects the CA score from 15 to
-- 18. The score change and its audit-log entry are saved
-- together when the transaction commits.
-- =========================================================
BEGIN;

SELECT set_config('app.user_id',
       (SELECT user_id::TEXT FROM user_account
        WHERE email = 'john@crestfield.edu.ng'), TRUE);
SELECT set_config('app.change_reason', 'CA re-marked after script review', TRUE);

UPDATE result r
SET ca_score = 18
FROM course_registration cr
JOIN student s ON s.student_id = cr.student_id
JOIN course c  ON c.course_id  = cr.course_id
WHERE r.registration_id = cr.registration_id
  AND s.matric_number = 'CU/2026/001'
  AND c.course_code = 'CSC101'
  AND cr.attempt_number = 1;

COMMIT;
-- Check: CA 18, total 38, still F, audit_log_entries = 1

SELECT changed_by_user_id, old_ca_score, new_ca_score,
       old_exam_score, new_exam_score, change_timestamp, change_reason
FROM grade_change_log
ORDER BY log_id DESC
LIMIT 1;


-- =========================================================
-- DEMO 2: ROLLBACK
-- The lecturer changes the exam score from 20 to 40, which
-- would raise the grade to C. Inside the transaction the
-- change and its log entry are visible. ROLLBACK undoes
-- both: the score returns to F and the log entry is gone.
-- This is atomicity: all of the transaction or none of it.
-- =========================================================
BEGIN;

SELECT set_config('app.user_id',
       (SELECT user_id::TEXT FROM user_account
        WHERE email = 'john@crestfield.edu.ng'), TRUE);
SELECT set_config('app.change_reason', 'Entered by mistake', TRUE);

UPDATE result r
SET exam_score = 40
FROM course_registration cr
JOIN student s ON s.student_id = cr.student_id
JOIN course c  ON c.course_id  = cr.course_id
WHERE r.registration_id = cr.registration_id
  AND s.matric_number = 'CU/2026/001'
  AND c.course_code = 'CSC101'
  AND cr.attempt_number = 1;

-- Check (still inside the transaction): exam 40, total 58,
-- grade C, audit_log_entries = 2

ROLLBACK;
-- Check again: exam back to 20, total 38, F, audit_log_entries = 1


-- =========================================================
-- DEMO 3: AUTOMATIC ROLLBACK AFTER AN ERROR
-- The first INSERT is valid, the second breaks a CHECK
-- constraint. After an error PostgreSQL aborts the whole
-- transaction, so COMMIT turns into ROLLBACK and the valid
-- first row is not saved either.
-- =========================================================
BEGIN;

INSERT INTO course_registration (student_id, course_id, semester_id, attempt_number)
SELECT s.student_id, c.course_id, sem.semester_id, 1
FROM student s, course c, semester sem
JOIN academic_session a ON a.session_id = sem.session_id
WHERE s.matric_number = 'CU/2026/001'
  AND c.course_code = 'MEE101'
  AND a.session_name = '2026/2027'
  AND sem.semester_name = 'Second Semester';

INSERT INTO course_registration (student_id, course_id, semester_id, attempt_number)
SELECT s.student_id, c.course_id, sem.semester_id, 5      -- invalid: attempt 5
FROM student s, course c, semester sem
JOIN academic_session a ON a.session_id = sem.session_id
WHERE s.matric_number = 'CU/2026/001'
  AND c.course_code = 'MEE104'
  AND a.session_name = '2026/2027'
  AND sem.semester_name = 'Second Semester';

COMMIT;   -- PostgreSQL reports ROLLBACK

-- Check: MEE101 was NOT saved (returns 0)
SELECT COUNT(*) AS mee101_registrations
FROM course_registration cr
JOIN student s ON s.student_id = cr.student_id
JOIN course c  ON c.course_id  = cr.course_id
WHERE s.matric_number = 'CU/2026/001' AND c.course_code = 'MEE101';


-- =========================================================
-- DEMO 4: TRIGGER RULES (each statement should FAIL)
-- =========================================================

-- 4a. A lecturer who is NOT assigned to CSC101 tries to
--     change the result -> rejected
BEGIN;
SELECT set_config('app.user_id',
       (SELECT user_id::TEXT FROM user_account
        WHERE email = 'lecturer1@crestfield.edu.ng'), TRUE);
UPDATE result r
SET exam_score = 60
FROM course_registration cr
JOIN student s ON s.student_id = cr.student_id
JOIN course c  ON c.course_id  = cr.course_id
WHERE r.registration_id = cr.registration_id
  AND s.matric_number = 'CU/2026/001'
  AND c.course_code = 'CSC101'
  AND cr.attempt_number = 1;
ROLLBACK;

-- 4b. A change with no identified user -> rejected
UPDATE result r
SET exam_score = 60
FROM course_registration cr
JOIN student s ON s.student_id = cr.student_id
JOIN course c  ON c.course_id  = cr.course_id
WHERE r.registration_id = cr.registration_id
  AND s.matric_number = 'CU/2026/001'
  AND c.course_code = 'CSC101'
  AND cr.attempt_number = 1;

-- 4c. A second attempt at a course never failed -> rejected
INSERT INTO course_registration (student_id, course_id, semester_id, attempt_number)
SELECT s.student_id, c.course_id, sem.semester_id, 2
FROM student s, course c, semester sem
JOIN academic_session a ON a.session_id = sem.session_id
WHERE s.matric_number = 'CU/2026/001'
  AND c.course_code = 'MEE201'
  AND a.session_name = '2026/2027'
  AND sem.semester_name = 'Second Semester';

-- 4d. Level above the programme maximum (BSc Computer
--     Science is a 400-level programme) -> rejected
UPDATE student SET current_level = 500
WHERE matric_number = 'CU/2026/001';


-- =========================================================
-- DEMO 5: GRADE CANNOT DISAGREE WITH THE SCORE
-- In Portfolio 1 the database accepted grade A for a total
-- of 35. Now the trigger recalculates the grade, so trying
-- to set grade A is silently corrected back to F.
-- =========================================================
UPDATE result r
SET grade_id = (SELECT grade_id FROM grade_scale WHERE grade = 'A')
FROM course_registration cr
JOIN student s ON s.student_id = cr.student_id
JOIN course c  ON c.course_id  = cr.course_id
WHERE r.registration_id = cr.registration_id
  AND s.matric_number = 'CU/2026/001'
  AND c.course_code = 'CSC101'
  AND cr.attempt_number = 1;
-- Check: grade is still F (total 38)
