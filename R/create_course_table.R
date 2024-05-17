library('data.table')
library('DBI')
library('RPostgres')
library('sqldf')

source('R/functions.R')
source('R/db_functions.R')

#import_courses()


# connect to database -----------------------------------------------------

con <- ucd_course_connect('elisehellwig')


# queries -----------------------------------------------------------------

subjq = paste('SELECT subject.id AS subject_id, subject.subject,',
              'department.dept, college.college',
              'FROM college INNER JOIN (department INNER JOIN subject',
              'ON department.id = subject.dept_id)',
              'ON college.id = subject.college_id;')

gradeq = 'SELECT id AS grade_type_id, grade_type FROM grade_type;'

# Constants ---------------------------------------------------------------

course_vars = c('cn', 'subject', 'number', 'effective_term', 'title',
                'long_title', 'units', 'if_variable', 'units_high', 'dept',
                'college')

final_course_vars = c('cn', 'subject_id', 'number', 'title', 'long_title', 'units',
                      'variable_units', 'units_high', 'grade_type_id', 'virtual',
                      'repeatable', 'effective', 'active')

desc_vars = c('cn', 'activities', 'credit_limit', 'prerequisites', 
              'restrictions', 'description')

# Read In -----------------------------------------------------------------

grade_recode = fread('data/grade_recode.csv')
course = fread('data/courses_clean.csv')
desc = fread('data/course_descriptions.csv')

subj = dbGetQuery(con, subjq)
grade_type = dbGetQuery(con, gradeq)


# Standardize grades ------------------------------------------------------

recode_grade = merge(recode_grade, grade_type, by='grade_type')

grade_query <- paste("SELECT desc.cn, recode_grade.grade_type_id",
                     "FROM desc LEFT JOIN recode_grade",
                     "ON LOWER(desc.Grade) LIKE pattern;")

course_grade = sqldf(grade_query) |> data.table()

# create variables --------------------------------------------------------

desc[,":="(virtual=grepl('Web ', activities),
           repeatable = ifelse(is.na(repeat_credit), FALSE, TRUE))]

desc = merge(desc, course_grade, by='cn')

chars = desc[,.(cn, grade_type_id, virtual, repeatable)]

# Course table ------------------------------------------------------------

courses = course[, ..course_vars]

courses[,":="(effective=as.Date(paste0(effective_term , '01'), format='%Y%m%d'),
              variable_units = ifelse(is.na(if_variable), FALSE, TRUE),
              active=TRUE)]

courses = merge(courses, chars, by='cn')
courses = merge(courses, subj, by = c('subject', 'dept', 'college'))



courses = courses[, ..final_course_vars]

setnames(courses, c('cn', 'number'), c('id', 'course_number'), skip_absent = TRUE)

append_table(con, 'course', courses, id_col = NA)

#fwrite(courses, 'data/tables/courses.csv')


# Course description table ------------------------------------------------

course_desc = fread('data/course_descriptions.csv')

course_desc = course_desc[, ..desc_vars]

setnames(course_desc, 'cn', 'course_id')

append_table(con, 'course_description', course_desc, id_col = NA)


# disconnect --------------------------------------------------------------



dbDisconnect(con)