-- =========================================================
-- CRESTFIELD UNIVERSITY - STUDENT RESULT PORTAL
-- PORTFOLIO 3: TRANSACTIONS AND CONCURRENCY
-- File: 03_concurrency_demo.sql
-- Database: PostgreSQL 18
--
-- This demo needs TWO pgAdmin Query Tool tabs on
-- crestfield_university, side by side. Each tab is a
-- separate database connection, acting as two users.
-- Steps are labelled TAB A / TAB B: run them in the order
-- shown, one block at a time, and screenshot each step.
--
-- Scenario: Adaeze (CU/2026/001) has 21 units registered
-- for 2026/2027 Second Semester. Two registrations of a
-- 3-unit course arrive at the same moment. Only one should
-- succeed: 21 + 3 = 24 is allowed, 21 + 3 + 3 = 27 is not.
-- =========================================================


-- =========================================================
-- SETUP (run once, in either tab)
-- Registers six 3-unit courses. With her CSC101 carry-over
-- (3 units) this brings her to 21 units.
-- =========================================================
INSERT INTO course_registration (student_id, course_id, semester_id, attempt_number)
SELECT s.student_id, c.course_id, sem.semester_id, 1
FROM student s, course c, semester sem
JOIN academic_session a ON a.session_id = sem.session_id
WHERE s.matric_number = 'CU/2026/001'
  AND c.course_code IN ('MEE101','MEE104','MEE201','MEE204','MEE301','MEE304')
  AND a.session_name = '2026/2027'
  AND sem.semester_name = 'Second Semester';

-- UNIT CHECK QUERY (re-run whenever a step says "check")
SELECT SUM(c.credit_unit) AS units_registered,
       COUNT(*)           AS courses
FROM course_registration cr
JOIN student s          ON s.student_id   = cr.student_id
JOIN course c           ON c.course_id    = cr.course_id
JOIN semester sem       ON sem.semester_id = cr.semester_id
JOIN academic_session a ON a.session_id   = sem.session_id
WHERE s.matric_number = 'CU/2026/001'
  AND a.session_name = '2026/2027'
  AND sem.semester_name = 'Second Semester';
-- Check: 21 units, 7 courses


-- =========================================================
-- PART A: THE CONCURRENCY PROBLEM (race condition)
-- Temporarily replace the unit-limit trigger with a version
-- WITHOUT the row lock, to show what goes wrong.
-- =========================================================

-- A0 (either tab): install the UNSAFE version
CREATE OR REPLACE FUNCTION trg_check_unit_limit()
RETURNS TRIGGER AS $$
DECLARE
    v_current_units INTEGER;
    v_new_units     INTEGER;
BEGIN
    -- No FOR UPDATE lock here (deliberately unsafe)
    SELECT COALESCE(SUM(c.credit_unit), 0) INTO v_current_units
    FROM course_registration cr
    JOIN course c ON c.course_id = cr.course_id
    WHERE cr.student_id = NEW.student_id
      AND cr.semester_id = NEW.semester_id
      AND cr.registration_status <> 'Dropped';

    SELECT credit_unit INTO v_new_units FROM course WHERE course_id = NEW.course_id;

    IF v_current_units + v_new_units > 24 THEN
        RAISE EXCEPTION 'Registration rejected: % units already registered, adding % would exceed the 24-unit limit',
            v_current_units, v_new_units;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- A1 (TAB A): start a transaction and register EEE101 (3 units)
BEGIN;
INSERT INTO course_registration (student_id, course_id, semester_id, attempt_number)
SELECT s.student_id, c.course_id, sem.semester_id, 1
FROM student s, course c, semester sem
JOIN academic_session a ON a.session_id = sem.session_id
WHERE s.matric_number = 'CU/2026/001' AND c.course_code = 'EEE101'
  AND a.session_name = '2026/2027' AND sem.semester_name = 'Second Semester';
-- Succeeds: the trigger saw 21 + 3 = 24. Do NOT commit yet.

-- A2 (TAB B): start a transaction and register EEE104 (3 units)
BEGIN;
INSERT INTO course_registration (student_id, course_id, semester_id, attempt_number)
SELECT s.student_id, c.course_id, sem.semester_id, 1
FROM student s, course c, semester sem
JOIN academic_session a ON a.session_id = sem.session_id
WHERE s.matric_number = 'CU/2026/001' AND c.course_code = 'EEE104'
  AND a.session_name = '2026/2027' AND sem.semester_name = 'Second Semester';
-- ALSO succeeds: Tab A's row is not committed, so Tab B's
-- trigger cannot see it and also calculates 21 + 3 = 24.

-- A3 (TAB A):
COMMIT;

-- A4 (TAB B):
COMMIT;

-- A5 (either tab): run the UNIT CHECK QUERY
-- Result: 27 units - the 24-unit rule has been broken.

-- A6 (either tab): clean up before Part B
DELETE FROM course_registration cr
USING student s, course c
WHERE cr.student_id = s.student_id AND cr.course_id = c.course_id
  AND s.matric_number = 'CU/2026/001'
  AND c.course_code IN ('EEE101', 'EEE104');


-- =========================================================
-- PART B: THE CONTROL MECHANISM (row-level locking)
-- Re-install the SAFE version: it locks the student's row
-- with SELECT ... FOR UPDATE before counting units.
-- =========================================================

-- B0 (either tab): install the SAFE version
CREATE OR REPLACE FUNCTION trg_check_unit_limit()
RETURNS TRIGGER AS $$
DECLARE
    v_current_units INTEGER;
    v_new_units     INTEGER;
BEGIN
    -- Concurrency control: serialise registrations per student
    PERFORM 1 FROM student WHERE student_id = NEW.student_id FOR UPDATE;

    SELECT COALESCE(SUM(c.credit_unit), 0) INTO v_current_units
    FROM course_registration cr
    JOIN course c ON c.course_id = cr.course_id
    WHERE cr.student_id = NEW.student_id
      AND cr.semester_id = NEW.semester_id
      AND cr.registration_status <> 'Dropped';

    SELECT credit_unit INTO v_new_units FROM course WHERE course_id = NEW.course_id;

    IF v_current_units + v_new_units > 24 THEN
        RAISE EXCEPTION 'Registration rejected: % units already registered, adding % would exceed the 24-unit limit',
            v_current_units, v_new_units;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- B1 (TAB A): same as A1 - BEGIN and register EEE101
BEGIN;
INSERT INTO course_registration (student_id, course_id, semester_id, attempt_number)
SELECT s.student_id, c.course_id, sem.semester_id, 1
FROM student s, course c, semester sem
JOIN academic_session a ON a.session_id = sem.session_id
WHERE s.matric_number = 'CU/2026/001' AND c.course_code = 'EEE101'
  AND a.session_name = '2026/2027' AND sem.semester_name = 'Second Semester';
-- Succeeds, and Tab A now holds a lock on Adaeze's row.

-- B2 (TAB B): same as A2 - BEGIN and register EEE104
BEGIN;
INSERT INTO course_registration (student_id, course_id, semester_id, attempt_number)
SELECT s.student_id, c.course_id, sem.semester_id, 1
FROM student s, course c, semester sem
JOIN academic_session a ON a.session_id = sem.session_id
WHERE s.matric_number = 'CU/2026/001' AND c.course_code = 'EEE104'
  AND a.session_name = '2026/2027' AND sem.semester_name = 'Second Semester';
-- Tab B WAITS (the query keeps running): it cannot get the
-- lock until Tab A finishes. Screenshot the running query.

-- B3 (TAB A):
COMMIT;
-- Tab B immediately continues, now sees 24 units, and fails:
-- "Registration rejected: 24 units already registered, adding 3
--  would exceed the 24-unit limit". Screenshot Tab B.

-- B4 (TAB B):
ROLLBACK;

-- B5 (either tab): run the UNIT CHECK QUERY
-- Result: 24 units - the rule held.


-- =========================================================
-- PART C: ISOLATION LEVELS
-- Shows how the isolation level changes what a transaction
-- sees when another user commits a change in the middle.
-- =========================================================

-- READ THE SCORE (used by Tab A below)
SELECT r.exam_score
FROM result r
JOIN course_registration cr ON cr.registration_id = r.registration_id
JOIN student s ON s.student_id = cr.student_id
JOIN course c  ON c.course_id  = cr.course_id
WHERE s.matric_number = 'CU/2026/001' AND c.course_code = 'CSC101'
  AND cr.attempt_number = 1;

-- C1 (TAB A): READ COMMITTED (PostgreSQL's default)
BEGIN ISOLATION LEVEL READ COMMITTED;
-- run READ THE SCORE -> note the value (e.g. 20)

-- C2 (TAB B): the lecturer changes the exam score and commits
BEGIN;
SELECT set_config('app.user_id',
       (SELECT user_id::TEXT FROM user_account WHERE email = 'john@crestfield.edu.ng'), TRUE);
SELECT set_config('app.change_reason', 'Isolation demo (read committed)', TRUE);
UPDATE result r SET exam_score = r.exam_score + 1
FROM course_registration cr
JOIN student s ON s.student_id = cr.student_id
JOIN course c  ON c.course_id  = cr.course_id
WHERE r.registration_id = cr.registration_id
  AND s.matric_number = 'CU/2026/001' AND c.course_code = 'CSC101'
  AND cr.attempt_number = 1;
COMMIT;

-- C3 (TAB A): run READ THE SCORE again -> the NEW value
-- (e.g. 21). The same query gave a different answer inside
-- one transaction: a "non-repeatable read".
COMMIT;

-- C4 (TAB A): now REPEATABLE READ
BEGIN ISOLATION LEVEL REPEATABLE READ;
-- run READ THE SCORE -> note the value (e.g. 21)

-- C5 (TAB B): repeat the C2 block (score +1 and COMMIT),
-- changing the reason to 'Isolation demo (repeatable read)'

-- C6 (TAB A): run READ THE SCORE again -> STILL the old value
-- (e.g. 21). The transaction works on a snapshot taken at
-- its first query, so other users' commits are not seen.
COMMIT;
-- run READ THE SCORE once more -> now the new value (e.g. 22)
