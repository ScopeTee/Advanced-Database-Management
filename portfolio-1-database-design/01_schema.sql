-- =====================================================
-- CRESTFIELD UNIVERSITY
-- STUDENT RESULT PORTAL
-- PostgreSQL Database Schema
-- =====================================================

-- Create the database separately in PostgreSQL:
-- CREATE DATABASE crestfield_university;

-- Connect to crestfield_university before running this schema.


-- =====================================================
-- 1. FACULTY
-- =====================================================

CREATE TABLE faculty (
    faculty_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    faculty_name VARCHAR(100) NOT NULL UNIQUE
);


-- =====================================================
-- 2. DEPARTMENT
-- =====================================================

CREATE TABLE department (
    department_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    faculty_id INTEGER NOT NULL,
    department_name VARCHAR(100) NOT NULL,

    CONSTRAINT fk_department_faculty
        FOREIGN KEY (faculty_id)
        REFERENCES faculty(faculty_id)
);


-- =====================================================
-- 3. PROGRAMME
-- =====================================================

CREATE TABLE programme (
    programme_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_id INTEGER NOT NULL,
    programme_name VARCHAR(150) NOT NULL,
    award_type VARCHAR(50) NOT NULL DEFAULT 'Bachelor',
    maximum_level INTEGER NOT NULL,

    CONSTRAINT fk_programme_department
        FOREIGN KEY (department_id)
        REFERENCES department(department_id),

    CONSTRAINT chk_programme_maximum_level
        CHECK (maximum_level IN (400, 500))
);


-- =====================================================
-- 4. USER ACCOUNT
-- =====================================================

CREATE TABLE user_account (
    user_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    account_status VARCHAR(20) NOT NULL DEFAULT 'Active',
    role VARCHAR(20) NOT NULL,

    CONSTRAINT chk_user_role
        CHECK (role IN ('Student', 'Lecturer', 'Admin')),

    CONSTRAINT chk_account_status
        CHECK (account_status IN ('Active', 'Inactive'))
);


-- =====================================================
-- 5. ACADEMIC SESSION
-- =====================================================

CREATE TABLE academic_session (
    session_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    session_name VARCHAR(20) NOT NULL UNIQUE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,

    CONSTRAINT chk_session_dates
        CHECK (end_date > start_date)
);


-- =====================================================
-- 6. STUDENT
-- =====================================================

CREATE TABLE student (
    student_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    programme_id INTEGER NOT NULL,
    user_id INTEGER UNIQUE,
    entry_session_id INTEGER NOT NULL,
    matric_number VARCHAR(30) NOT NULL UNIQUE,
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    admission_date DATE NOT NULL,
    current_level INTEGER NOT NULL,
    student_status VARCHAR(20) NOT NULL DEFAULT 'Active',

    CONSTRAINT fk_student_programme
        FOREIGN KEY (programme_id)
        REFERENCES programme(programme_id),

    CONSTRAINT fk_student_user
        FOREIGN KEY (user_id)
        REFERENCES user_account(user_id),

    CONSTRAINT fk_student_entry_session
        FOREIGN KEY (entry_session_id)
        REFERENCES academic_session(session_id),

    CONSTRAINT chk_student_level
        CHECK (current_level IN (100, 200, 300, 400, 500)),

    CONSTRAINT chk_student_status
        CHECK (
            student_status IN ('Active', 'Suspended', 'Graduated')
        )
);


-- =====================================================
-- 7. LECTURER
-- =====================================================

CREATE TABLE lecturer (
    lecturer_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_id INTEGER NOT NULL,
    user_id INTEGER UNIQUE,
    staff_number VARCHAR(30) NOT NULL UNIQUE,
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(60) NOT NULL,

    CONSTRAINT fk_lecturer_department
        FOREIGN KEY (department_id)
        REFERENCES department(department_id),

    CONSTRAINT fk_lecturer_user
        FOREIGN KEY (user_id)
        REFERENCES user_account(user_id)
);


-- =====================================================
-- 8. COURSE
-- =====================================================

CREATE TABLE course (
    course_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_id INTEGER NOT NULL,
    assigned_lecturer_id INTEGER,
    course_code VARCHAR(20) NOT NULL UNIQUE,
    course_title VARCHAR(150) NOT NULL,
    credit_unit INTEGER NOT NULL,

    CONSTRAINT fk_course_department
        FOREIGN KEY (department_id)
        REFERENCES department(department_id),

    CONSTRAINT fk_course_lecturer
        FOREIGN KEY (assigned_lecturer_id)
        REFERENCES lecturer(lecturer_id),

    CONSTRAINT chk_course_credit
        CHECK (credit_unit BETWEEN 1 AND 6)
);


-- =====================================================
-- 9. PROGRAMME COURSE
-- =====================================================

CREATE TABLE programme_course (
    programme_course_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    programme_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    study_level INTEGER NOT NULL,
    course_type VARCHAR(20) NOT NULL DEFAULT 'Compulsory',

    CONSTRAINT fk_pc_programme
        FOREIGN KEY (programme_id)
        REFERENCES programme(programme_id),

    CONSTRAINT fk_pc_course
        FOREIGN KEY (course_id)
        REFERENCES course(course_id),

    CONSTRAINT uq_programme_course
        UNIQUE (programme_id, course_id),

    CONSTRAINT chk_pc_level
        CHECK (study_level IN (100, 200, 300, 400, 500)),

    CONSTRAINT chk_pc_type
        CHECK (course_type IN ('Compulsory', 'Elective'))
);


-- =====================================================
-- 10. SEMESTER
-- =====================================================

CREATE TABLE semester (
    semester_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    session_id INTEGER NOT NULL,
    semester_name VARCHAR(20) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,

    CONSTRAINT fk_semester_session
        FOREIGN KEY (session_id)
        REFERENCES academic_session(session_id),

    CONSTRAINT uq_session_semester
        UNIQUE (session_id, semester_name),

    CONSTRAINT chk_semester_dates
        CHECK (end_date > start_date)
);


-- =====================================================
-- 11. COURSE REGISTRATION
-- =====================================================

CREATE TABLE course_registration (
    registration_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    semester_id INTEGER NOT NULL,
    attempt_number INTEGER NOT NULL DEFAULT 1,
    registration_status VARCHAR(20) NOT NULL DEFAULT 'Registered',
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE,

    CONSTRAINT fk_registration_student
        FOREIGN KEY (student_id)
        REFERENCES student(student_id),

    CONSTRAINT fk_registration_course
        FOREIGN KEY (course_id)
        REFERENCES course(course_id),

    CONSTRAINT fk_registration_semester
        FOREIGN KEY (semester_id)
        REFERENCES semester(semester_id),

    CONSTRAINT uq_student_course_attempt
        UNIQUE (student_id, course_id, attempt_number),

    CONSTRAINT uq_student_course_semester
        UNIQUE (student_id, course_id, semester_id),

    CONSTRAINT chk_attempt_number
        CHECK (attempt_number BETWEEN 1 AND 2),

    CONSTRAINT chk_registration_status
        CHECK (
            registration_status IN ('Registered', 'Dropped', 'Completed')
        )
);


-- =====================================================
-- 12. GRADE SCALE
-- =====================================================

CREATE TABLE grade_scale (
    grade_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    grade VARCHAR(2) NOT NULL UNIQUE,
    minimum_score NUMERIC(5,2) NOT NULL,
    maximum_score NUMERIC(5,2) NOT NULL,
    grade_point NUMERIC(3,2) NOT NULL,

    CONSTRAINT chk_grade_score_range
        CHECK (
            minimum_score >= 0
            AND maximum_score <= 100
            AND minimum_score <= maximum_score
        ),

    CONSTRAINT chk_grade_point
        CHECK (grade_point BETWEEN 0 AND 5)
);


-- =====================================================
-- 13. RESULT
-- =====================================================

CREATE TABLE result (
    result_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    registration_id INTEGER NOT NULL UNIQUE,
    ca_score NUMERIC(5,2) NOT NULL,
    exam_score NUMERIC(5,2) NOT NULL,

    total_score NUMERIC(5,2)
        GENERATED ALWAYS AS (ca_score + exam_score) STORED,

    grade_id INTEGER NOT NULL,
    result_date DATE NOT NULL DEFAULT CURRENT_DATE,

    CONSTRAINT fk_result_registration
        FOREIGN KEY (registration_id)
        REFERENCES course_registration(registration_id),

    CONSTRAINT fk_result_grade
        FOREIGN KEY (grade_id)
        REFERENCES grade_scale(grade_id),

    CONSTRAINT chk_ca_score
        CHECK (ca_score BETWEEN 0 AND 40),

    CONSTRAINT chk_exam_score
        CHECK (exam_score BETWEEN 0 AND 60)
);


-- =====================================================
-- 14. LECTURER ASSIGNMENT HISTORY
-- =====================================================

CREATE TABLE lecturer_assignment_history (
    history_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    course_id INTEGER NOT NULL,
    lecturer_id INTEGER NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE,
    changed_by_user_id INTEGER NOT NULL,

    CONSTRAINT fk_history_course
        FOREIGN KEY (course_id)
        REFERENCES course(course_id),

    CONSTRAINT fk_history_lecturer
        FOREIGN KEY (lecturer_id)
        REFERENCES lecturer(lecturer_id),

    CONSTRAINT fk_history_user
        FOREIGN KEY (changed_by_user_id)
        REFERENCES user_account(user_id),

    CONSTRAINT chk_assignment_dates
        CHECK (
            effective_to IS NULL
            OR effective_to >= effective_from
        )
);


-- =====================================================
-- 15. GRADE CHANGE LOG
-- =====================================================

CREATE TABLE grade_change_log (
    log_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    result_id INTEGER NOT NULL,
    changed_by_user_id INTEGER NOT NULL,
    old_ca_score NUMERIC(5,2),
    new_ca_score NUMERIC(5,2),
    old_exam_score NUMERIC(5,2),
    new_exam_score NUMERIC(5,2),
    change_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    change_reason VARCHAR(255),

    CONSTRAINT fk_grade_log_result
        FOREIGN KEY (result_id)
        REFERENCES result(result_id),

    CONSTRAINT fk_grade_log_user
        FOREIGN KEY (changed_by_user_id)
        REFERENCES user_account(user_id)
);
