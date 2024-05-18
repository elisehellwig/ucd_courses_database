-- !preview conn=DBI::dbConnect(RSQLite::SQLite())
-- brew services start postgresql@14
-- psql postgres
-- \c ucd_courses

-- DROP TABLE table_name;

-- DELTE FROM department;

-- DROP DATABASE ucd_courses WITH (FORCE);


--ALTER TABLE department ADD CONSTRAINT dept_unique UNIQUE (dept, dept_name);


CREATE DATABASE ucd_courses;

CREATE TABLE college_type(
   id INT PRIMARY KEY,
   college_type VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE college (
	id INT UNIQUE PRIMARY KEY,
  college VARCHAR(5) UNIQUE NOT NULL,
	college_name VARCHAR(255) UNIQUE NOT NULL,
	college_type_id INT REFERENCES college_type(id) NOT NULL
);


CREATE TABLE department (
	id INT UNIQUE PRIMARY KEY,
  dept VARCHAR(6) NOT NULL,
	dept_name VARCHAR(255) NOT NULL,
	grad_group Boolean NOT NULL,
	CONSTRAINT dept_unique UNIQUE (id, dept, dept_name)
);

CREATE TABLE subject (
	id INT UNIQUE PRIMARY KEY,
  subject VARCHAR(5) NOT NULL,
	dept_id INT REFERENCES department(id) NOT NULL,
	college_id INT REFERENCES college(id) NOT NULL
);


CREATE TABLE restriction_type (
	id INT UNIQUE PRIMARY KEY,
	restriction_type VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE grade_type (
	id INT UNIQUE PRIMARY KEY,
	grade_type VARCHAR(255) UNIQUE NOT NULL,
	is_letter Boolean NOT NULL
);


CREATE TABLE gen_ed (
	id INT UNIQUE PRIMARY KEY,
  ge_name VARCHAR(255) UNIQUE NOT NULL,
	ge_code VARCHAR(5) UNIQUE NOT NULL
);

CREATE TABLE learning_activity (
	id INT UNIQUE PRIMARY KEY,
	activity VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE course (
	id VARCHAR(10) UNIQUE PRIMARY KEY,
  subject_id INT REFERENCES subject(id) NOT NULL,
  course_number VARCHAR(5) NOT NULL,
	title VARCHAR(255) NOT NULL,
	long_title VARCHAR(255) NOT NULL,
	units REAL,
	variable_units Boolean DEFAULT False,
	units_high REAL DEFAULT NULL,
	grade_type_id INT REFERENCES grade_type(id) DEFAULT 2,
	virtual Boolean DEFAULT False,
	repeatable Boolean DEFAULT False,
	effective DATE,
	active Boolean DEFAULT True
);


CREATE TABLE course_description (
  course_id VARCHAR(10) PRIMARY KEY REFERENCES course(id),
  activities TEXT,
  credit_limit TEXT,
  prerequisites TEXT,
  restrictions TEXT,
  description TEXT
);

CREATE TABLE course_gen_ed (
  id INT PRIMARY KEY,
  course_id VARCHAR(10) REFERENCES course(id),
  ge_id INT REFERENCES gen_ed(id)
);


CREATE TABLE course_activity (
  id INT PRIMARY KEY,
  course_id VARCHAR(10) REFERENCES course(id),
  activity_id INT REFERENCES learning_activity(id)
);

CREATE TABLE course_crosslist (
  id INT PRIMARY KEY,
  course_id VARCHAR(10) REFERENCES course(id),
  crosslist_course_id VARCHAR(10) 
);

CREATE TABLE course_prerequisite (
  id INT PRIMARY KEY,
  course_id VARCHAR(10) REFERENCES course(id),
  prerequisite_course_id VARCHAR(10) 
);

CREATE TABLE course_restriction (
  id INT PRIMARY KEY,
  course_id VARCHAR(10) REFERENCES course(id),
  restriction VARCHAR(10), 
  restriction_type_id INT REFERENCES restriction_type(id)
);

