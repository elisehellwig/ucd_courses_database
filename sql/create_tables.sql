-- !preview conn=DBI::dbConnect(RSQLite::SQLite())
-- brew services start postgresql@14
-- psql postgres
-- \c ucd_courses
-- DROP TABLE table_name;

ALTER TABLE department
ADD CONSTRAINT dept_unique UNIQUE (dept, dept_name);


CREATE database ucd_courses

CREATE TABLE college_type(
   college_type_id INT GENERATED ALWAYS AS IDENTITY,
   college_type VARCHAR(255) UNIQUE NOT NULL,
   PRIMARY KEY(college_type_id)
);

CREATE TABLE college (
	college_id INT GENERATED ALWAYS AS IDENTITY,
  college VARCHAR(5) NOT NULL,
	college_name VARCHAR(255) NOT NULL,
	college_type_id INT REFERENCES college_type(college_type_id) NOT NULL,
	PRIMARY KEY(college_id),
	CONSTRAINT college_unique UNIQUE (college, college_name)
);


CREATE TABLE department (
	dept_id INT GENERATED ALWAYS AS IDENTITY,
  dept VARCHAR(6) NOT NULL,
	dept_name VARCHAR(255) NOT NULL,
	grad_group Boolean NOT NULL,
	PRIMARY KEY(dept_id),
	CONSTRAINT dept_unique UNIQUE (dept, dept_name)
);

CREATE TABLE subject (
	subject_id INT GENERATED ALWAYS AS IDENTITY,
  subject VARCHAR(5) NOT NULL,
	dept_id INT REFERENCES department(dept_id) NOT NULL,
	college_id INT REFERENCES college(college_id) NOT NULL,
	PRIMARY KEY(subject_id)
);


CREATE TABLE restriction_type (
	restriction_type_id INT GENERATED ALWAYS AS IDENTITY,
	restriction_type VARCHAR(255) UNIQUE NOT NULL,
	PRIMARY KEY(restriction_type_id)
);

CREATE TABLE grade_type (
	grade_type_id INT GENERATED ALWAYS AS IDENTITY,
	grade_type VARCHAR(255) UNIQUE NOT NULL,
	is_letter Boolean NOT NULL,
	PRIMARY KEY(grade_type_id)
);


CREATE TABLE gen_ed (
	ge_id INT GENERATED ALWAYS AS IDENTITY,
  ge_name VARCHAR(255) UNIQUE NOT NULL,
	ge_code VARCHAR(5) UNIQUE NOT NULL,
	PRIMARY KEY(ge_id)
);

CREATE TABLE learning_activity (
	activity_id INT GENERATED ALWAYS AS IDENTITY,
	activity VARCHAR(255) UNIQUE NOT NULL,
	PRIMARY KEY(activity_id)
);

CREATE TABLE course (
	course_id VARCHAR() PRIMARY KEY,
  subj_id VARCHAR(5) NOT NULL,
  course_number VARCHAR(5) NOT NULL,
	title VARCHAR(255) UNIQUE NOT NULL,
	long_title VARCHAR(255) UNIQUE NOT NULL,
	variable_units Boolean DEFAULT False,
	units_high INT DEFAULT NULL,
	grade_id INT NOT NULL,
	virtual Boolean DEFAULT False,
	repeatable Boolean DEFAULT False,
	effective DATE,
	active Boolean DEFAULT True
);