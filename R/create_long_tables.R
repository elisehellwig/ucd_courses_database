library('data.table')
library('stringr')
library('sqldf')
library('DBI')
library('RPostgres')

source('R/functions.R')
source('R/db_functions.R')

#import_courses
#str_multi_replace
#strsplit_vector
#remove_duplicates

con = ucd_course_connect('elisehellwig')

pre_q = paste('SELECT subject, course_id, course_number, prerequisites',
              'FROM subject INNER JOIN (course_description INNER JOIN course',
              'ON course_description.course_id = course.id)',
              'ON subject.id = course.subject_id;')

# Read In -----------------------------------------------------------------

desc = fread('data/course_descriptions.csv')
setnames(desc, 'cn', 'course_id')

ge = read_table(con, 'gen_ed')
setnames(ge, 'id', 'ge_id')

learning_activites = read_table(con, 'learning_activity')
setnames(learning_activites, 'id', 'activity_id')

prereq = dbGetQuery(con, pre_q)
setDT(prereq)

# Create GE course table --------------------------------------------------

desc_ge = desc[ , .(course_id, gen_ed)]

ge_query <- paste("SELECT course_id, ge_id FROM desc_ge INNER JOIN ge",
                  "ON gen_ed LIKE CONCAT('%', ge_name, '%');")

ge_course = sqldf(ge_query) |> data.table()

append_table(con, 'course_gen_ed', ge_course)


# Create course activity table --------------------------------------------

act_query <- paste("SELECT course_id, activity_id ",
                   "FROM desc INNER JOIN learning_activites",
                   "ON LOWER(activities) LIKE CONCAT('%', activity, '%');")

act_course = sqldf(act_query) |> data.table()

setorderv(act_course)

append_table(con, 'course_activity', act_course)

# Create crosslisting -----------------------------------------------------

cl_replace = data.table(string=c(';', '\\.$'), replacement=c(', ', ''))

cl_wide = desc[!is.na(cross_listing), .(course_id, cross_listing)]

cl_wide[, cross_listing:=toupper(cross_listing)]

cl_wide[, cross_listing:=str_multi_replace(cross_listing, cl_replace)]

cl = lapply(1:nrow(cl_wide), function(i) {
  cn_vec = str_split_1(cl_wide$cross_listing[i], ', ')
  
  data.table(course_id=cl_wide$course_id[i], crosslist_course_id = cn_vec)
}) |> rbindlist()

cl[, crosslist_course_id:=gsub(' ', '', crosslist_course_id)]

cl = cl[!crosslist_course_id %in% c("CTS012", "PSC12Y")]

setorderv(cl)

append_table(con, 'course_crosslist', cl)

# Prerequisities Table ----------------------------------------------------

prereq[, c_n:= paste(subject, course_number)]

cns = prereq[, .(course_id, c_n)]
setnames(cns, names(cns), paste0('prerequisite_', names(cns)))

prereqs = prereq[!is.na(prerequisites), .(course_id, prerequisites)]

prereq_query = paste("SELECT course_id, prerequisite_course_id",
                     "FROM prereqs INNER JOIN cns",
                     "ON prerequisites LIKE CONCAT('%', prerequisite_c_n, '%');")

course_prereq = sqldf(prereq_query) |> data.table()

setorderv(course_prereq)

append_table(con, 'course_prerequisite', course_prereq)

