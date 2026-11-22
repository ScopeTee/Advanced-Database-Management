-- =========================================================
-- CRESTFIELD UNIVERSITY - STUDENT RESULT PORTAL
-- PORTFOLIO 3: TRANSACTIONS AND CONCURRENCY
-- File: 01_triggers.sql
-- Database: PostgreSQL 18
--
-- Business rules from Portfolio 1 that CHECK constraints
-- could not enforce, implemented as triggers:
--   1. grade_id is always derived from the scores
--   2. Only the assigned lecturer may change a result,
--      and every change is written to grade_change_log
--   3. Maximum 24 credit units per student per semester
--      (with row locking to prevent a race condition)
--   4. A second attempt requires a failed first attempt
--   5. current_level may not exceed the programme maximum
--
-- Run once, after Portfolios 1 and 2.
-- =========================================================


-- ---------------------------------------------------------
-- 1. AUTOMATIC GRADE ASSIGNMENT
-- Fixes the Portfolio 1 limitation where a result could
-- be stored with a grade that did not match its score.
-- total_score is a generated column and is not yet
-- available in a BEFORE trigger, so the sum is computed.
-- ---------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_set_grade()
RETURNS TRIGGER AS $$
BEGIN
    SELECT gs.grade_id
    INTO NEW.grade_id
    FROM grade_scale gs
    WHERE (NEW.ca_score + NEW.exam_score)
          BETWEEN gs.minimum_score AND gs.maximum_score;

    IF NEW.grade_id IS NULL THEN
        RAISE EXCEPTION 'No grade defined for total score %',
            NEW.ca_score + NEW.exam_score;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER result_set_grade
BEFORE INSERT OR UPDATE OF ca_score, exam_score, grade_id ON result
FOR EACH ROW
EXECUTE FUNCTION trg_set_grade();


-- ---------------------------------------------------------
-- 2. LECTURER-ONLY GRADE CHANGES WITH AUDIT LOG
-- The application identifies the user for the current
-- transaction with:
--   SET LOCAL app.user_id = '<user_id>';
--   SET LOCAL app.change_reason = '<reason>';
-- The change is rejected unless that user is the lecturer
-- currently assigned to the course.
-- ---------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_audit_grade_change()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id      INTEGER;
    v_is_assigned  BOOLEAN;
BEGIN
    v_user_id := NULLIF(current_setting('app.user_id', TRUE), '')::INTEGER;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Grade change rejected: no user identified (set app.user_id)';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM course_registration cr
        JOIN course c   ON c.course_id   = cr.course_id
        JOIN lecturer l ON l.lecturer_id = c.assigned_lecturer_id
        WHERE cr.registration_id = NEW.registration_id
          AND l.user_id = v_user_id
    ) INTO v_is_assigned;

    IF NOT v_is_assigned THEN
        RAISE EXCEPTION 'Grade change rejected: user % is not the lecturer assigned to this course',
            v_user_id;
    END IF;

    INSERT INTO grade_change_log (
        result_id, changed_by_user_id,
        old_ca_score, new_ca_score,
        old_exam_score, new_exam_score,
        change_reason
    )
    VALUES (
        NEW.result_id, v_user_id,
        OLD.ca_score, NEW.ca_score,
        OLD.exam_score, NEW.exam_score,
        NULLIF(current_setting('app.change_reason', TRUE), '')
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER result_audit_change
AFTER UPDATE OF ca_score, exam_score ON result
FOR EACH ROW
WHEN (OLD.ca_score IS DISTINCT FROM NEW.ca_score
      OR OLD.exam_score IS DISTINCT FROM NEW.exam_score)
EXECUTE FUNCTION trg_audit_grade_change();


-- ---------------------------------------------------------
-- 3. MAXIMUM 24 CREDIT UNITS PER SEMESTER
-- SELECT ... FOR UPDATE locks the student's row, so two
-- registrations for the same student cannot be checked at
-- the same time. Without this lock, two concurrent
-- transactions could each see 21 units, each add 3, and
-- leave the student with 27 (see 03_concurrency_demo.sql).
-- ---------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_check_unit_limit()
RETURNS TRIGGER AS $$
DECLARE
    v_current_units INTEGER;
    v_new_units     INTEGER;
BEGIN
    -- Concurrency control: serialise registrations per student
    PERFORM 1 FROM student WHERE student_id = NEW.student_id FOR UPDATE;

    SELECT COALESCE(SUM(c.credit_unit), 0)
    INTO v_current_units
    FROM course_registration cr
    JOIN course c ON c.course_id = cr.course_id
    WHERE cr.student_id  = NEW.student_id
      AND cr.semester_id = NEW.semester_id
      AND cr.registration_status <> 'Dropped';

    SELECT credit_unit INTO v_new_units
    FROM course WHERE course_id = NEW.course_id;

    IF v_current_units + v_new_units > 24 THEN
        RAISE EXCEPTION 'Registration rejected: % units already registered, adding % would exceed the 24-unit limit',
            v_current_units, v_new_units;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER registration_unit_limit
BEFORE INSERT ON course_registration
FOR EACH ROW
EXECUTE FUNCTION trg_check_unit_limit();


-- ---------------------------------------------------------
-- 4. SECOND ATTEMPT ONLY AFTER A FAILED FIRST ATTEMPT
-- ---------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_check_carry_over()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.attempt_number = 2 AND NOT EXISTS (
        SELECT 1
        FROM course_registration cr
        JOIN result r       ON r.registration_id = cr.registration_id
        JOIN grade_scale gs ON gs.grade_id       = r.grade_id
        WHERE cr.student_id     = NEW.student_id
          AND cr.course_id      = NEW.course_id
          AND cr.attempt_number = 1
          AND gs.grade          = 'F'
    ) THEN
        RAISE EXCEPTION 'Registration rejected: a second attempt requires a failed (F) first attempt';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER registration_carry_over
BEFORE INSERT ON course_registration
FOR EACH ROW
EXECUTE FUNCTION trg_check_carry_over();


-- ---------------------------------------------------------
-- 5. CURRENT LEVEL WITHIN PROGRAMME MAXIMUM
-- ---------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_check_level()
RETURNS TRIGGER AS $$
DECLARE
    v_max INTEGER;
BEGIN
    SELECT maximum_level INTO v_max
    FROM programme WHERE programme_id = NEW.programme_id;

    IF NEW.current_level > v_max THEN
        RAISE EXCEPTION 'Level % exceeds the programme maximum of %',
            NEW.current_level, v_max;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER student_level_check
BEFORE INSERT OR UPDATE OF current_level, programme_id ON student
FOR EACH ROW
EXECUTE FUNCTION trg_check_level();
