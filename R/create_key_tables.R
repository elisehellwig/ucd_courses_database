# ges, learning activities, grade_type, restriction type
library('data.table')
library('stringr')
library('DBI')
library('RPostgres')


source('R/functions.R')
source('R/db_functions.R')


# Connect to database -----------------------------------------------------

con <- ucd_course_connect('elisehellwig')


# Load Data ---------------------------------------------------------------

recode_grade = fread('data/grade_recode.csv')
restr_type = fread('data/tables/restriction_type.csv', sep=',')
course = fread('data/courses_clean.csv')
desc = fread('data/course_descriptions.csv')

# Grade Type --------------------------------------------------------------

grade_desc = desc[, .(cn, grade)]

grades = recode_grade[, 'grade_type'] |>
  unique() 

grades = grades[order(grade_type)]

grades[, is_letter := grepl('Letter', grade_type)]

append_table(con, 'grade_type', grades)


# Restriction Type --------------------------------------------------------

append_table(con, 'restriction_type', restr_type)



# GEs ---------------------------------------------------------------------


ge_replace = data.table(string=c('\\),', ' or '), replacement=c('\\);', '; '))

GEs = desc$gen_ed[!is.na(desc$gen_ed)] |>
  str_multi_replace(ge_replace) |>
  strsplit_vector(';') |>
  str_replace_all('\\.', '') |>
  trimws() |>
  unique() |>
  str_replace_all('\\)', '') |>
  str_split_fixed(' \\(', 2) |>
  data.table()

setnames(GEs, names(GEs), c('ge_name', 'ge_code'))

GEs = GEs[ge_code !='']

setorderv(GEs, cols='ge_name')

append_table(con, 'gen_ed', GEs)



# Learning Activities -----------------------------------------------------

act_remove = c('hour\\(s\\)', 'hour\\(s\\(', 'hour \\(s\\)', 'hours\\(s\\)',
               '[0-9,\\.\\-]')

act_replace = data.table(string=c(act_remove, '\\s\\s+'), 
                         replacement = c(rep('', length(act_remove)), ' '))

acts = desc$activities[!is.na(desc$activities)] |>
  tolower() |>
  strsplit_vector('[,;\\] ') |>
  strsplit_vector('/') |>
  str_multi_replace(act_replace) |>
  str_replace_all('[\\s]', ' ') |>
  trimws() |>
  unique()

good_acts =  acts!='' & !grepl('\\)', acts) & !grepl('consent', acts) 

acts = acts[good_acts]

acts = remove_duplicates(acts) |> sort()

learning_activity = data.table(activity = acts)

append_table(con, 'learning_activity', learning_activity)

#dbSendQuery(con, 'DELETE FROM learning_activity WHERE activity_id > 26;')


# Disconnect --------------------------------------------------------------


dbDisconnect(con)
