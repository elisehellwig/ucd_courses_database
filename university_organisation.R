library('readxl')
library('data.table')


# Read In -----------------------------------------------------------------

colleges = fread('data/tables/colleges.csv')

course = read_xlsx('data/Banner_ActiveCourses_descriptions_20240510.xlsx')
setDT(course)

df_names = c('Subject', 'Number', 'Status', 'Effective_Term', 'Dept', 
             'Dept_Name', 'College', 'Title', 'Long_Title', 'Units',
             'If_variable', 'Units_High', 'Description') |> tolower()

setnames(course, names(course), df_names)



# Departments -------------------------------------------------------------

depts = course[, .(dept, dept_name )] |>
  unique()

setorderv(depts, cols='dept')

depts[, dept_id := 1:nrow(depts)]

setcolorder(depts, 'dept_id')

fwrite(depts, 'data/tables/department.csv')

# Subjects ----------------------------------------------------------------

subj0 = course[, .(college, dept, subject)] |> unique()

subj_dept = merge(depts[, dept, dept_id], subj0, by = 'dept')

subj_col = merge(colleges, subj_dept, by = 'college')

setorderv(subj_col, cols='subject')

subj_col[, subj_id := 1:nrow(subj_col)]

subj = subj_col[, .(subj_id, subject, dept_id, college_id)]

fwrite(subj, 'data/tables/subject.csv')

