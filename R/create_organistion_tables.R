library('readxl')
library('data.table')
library('DBI')
library('RPostgres')


source('R/functions.R')
source('R/db_functions.R')


# Connect to database -----------------------------------------------------

con <- ucd_course_connect('elisehellwig')

dbDisconnect(con)

# Read In -----------------------------------------------------------------

colleges = fread('data/tables/colleges.csv')
college_type = fread('data/tables/college_type.csv')

course = fread('data/courses_clean.csv')

# add data to college_type ------------------------------------------------

append_table(con, 'college_type', college_type)


# Add college Data --------------------------------------------------------

ct = dbGetQuery(con, 'SELECT * FROM college_type;')
setnames(ct, 'id', 'college_type_id')


colleges = merge(colleges, ct, by = 'college_type', all=TRUE) |>
  subset(select = -college_type)

append_table(con, 'college', colleges)

# Departments -------------------------------------------------------------

depts = course[, .(dept, dept_name )] |>
  unique()

setorderv(depts, cols='dept')

depts[, grad_group:= grepl('GG$', dept_name)]

append_table(con, 'department', depts)


# Subjects ----------------------------------------------------------------

subj0 = course[, .(college, dept, subject)] |> unique()

dp = dbGetQuery(con, 'SELECT dept, id AS dept_id FROM department;')
co = dbGetQuery(con, 'SELECT college, id AS college_id FROM college;')

subj_dept = merge(subj0, dp,  by = 'dept')

subj_col = merge( subj_dept, co, by = 'college')

setorderv(subj_col, cols='subject')

subj = subj_col[, .(subject, dept_id, college_id)]

append_table(con, 'subject', subj)


