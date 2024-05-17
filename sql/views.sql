-- !preview conn=DBI::dbConnect(RSQLite::SQLite())

-- SUBJECT VIEW
SELECT subject.subject_id, subject.subject, department.dept, college.college
FROM college INNER JOIN (department INNER JOIN subject 
  ON department.dept_id = subject.dept_id)
  ON college.college_id = subject.college_id;
