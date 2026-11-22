-- =========================================================
-- CRESTFIELD UNIVERSITY - STUDENT RESULT PORTAL
-- PORTFOLIO 2: QUERY PROCESSING AND OPTIMISATION
-- File: 03_indexes.sql
-- Database: PostgreSQL 18
--
-- Indexes created after capturing the baseline execution
-- plans for Queries 1-3 in 02_queries.sql.
-- Run each statement once, then re-run the queries with
-- EXPLAIN (ANALYZE, BUFFERS) to compare.
-- =========================================================

-- Demonstration 1 (Query 1): composite index for class lists
CREATE INDEX idx_reg_course_semester ON course_registration (course_id, semester_id);

-- Demonstration 2 (Query 2): low-selectivity test on grade
CREATE INDEX idx_result_grade ON result (grade_id);

-- Demonstration 3 (Query 3): surname search
CREATE INDEX idx_student_last_name ON student (last_name);

-- Refresh planner statistics so the new indexes are considered
ANALYZE;
