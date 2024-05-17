library('readxl')
library('data.table')
library('stringr')
library('sqldf')

source('R/functions.R')
#import_courses
#str_multi_replace
#strsplit_vector
#remove_duplicates

desc = fread('data/course_descriptions.csv')

course = import_courses()

# Create GE course table --------------------------------------------------


desc_ge = desc[ , .(cn, gen_ed)]

ge_query <- paste("SELECT cn, ge_id FROM desc_ge INNER JOIN GEs",
                  "ON gen_ed LIKE CONCAT('%', ge_name, '%');")

ge_course = sqldf(ge_query) |> data.table()

ge_course[,course_ge_id:= 1:nrow(ge_course)]

fwrite(ge_course, 'data/tables/course_ge.csv')

# ge_course = fuzzy_join(desc_ge, GEs, by= c('Gen_Ed' = 'ge_name'), 
#                        match_fun = str_detect, mode='inner') 
# 
# ge_course = ge_course[, c('cn', 'ge_id')]


# Correct Misspellings ----------------------------------------------------

act_misspell = data.table(string=c('Discusson', 'Intership'), 
                          replacement=c('Discussion', 'Internship'))

desc[, activities:= str_multi_replace(activities, act_misspell)]

# Create Learning Activities Table ----------------------------------------


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

learning_activity = data.table(activity_id = 1:length(acts),
                               activity = acts)

fwrite(learning_activity, 'data/tables/learning_activity.csv')


# Create course activity table --------------------------------------------


act_query <- paste("SELECT cn, activity_id ",
                   "FROM desc INNER JOIN learning_activity",
                   "ON LOWER(activities) LIKE CONCAT('%', activity, '%');")

act_course = sqldf(act_query) |> data.table()

setorderv(act_course)

act_course[, course_activity_id:=1:nrow(act_course)]

fwrite(act_course, 'data/tables/course_activity.csv')

# Create crosslisting -----------------------------------------------------

cl_replace = data.table(string=c(';', '\\.$'), replacement=c(', ', ''))

cl_wide = desc[cross_listing!='', .(cn, cross_listing)]

cl_wide[, cross_listing:=toupper(cross_listing)]

cl_wide[, cross_listing:=str_multi_replace(cross_listing, cl_replace)]

cl = lapply(1:nrow(cl_wide), function(i) {
  cn_vec = str_split_1(cl_wide$cross_listing[i], ', ')
  
  data.table(cn=cl_wide$cn[i], crosslisted_cn = cn_vec)
}) |> rbindlist()

cl[, crosslisted_cn:=gsub(' ', '', crosslisted_cn)]

setorderv(cl)

cl[, crosslist_id:= 1:nrow(cl)]

setcolorder(cl, 'crosslist_id')

fwrite(cl, 'data/tables/course_crosslist.csv')

# Prerequisities Table ----------------------------------------------------

course[, c_n:= paste(subject, number)]
cns = course[, .(cn, c_n)]
setnames(cns, names(cns), paste0('prereq_', names(cns)))

desc_prereq = desc[prerequisites!='', .(cn, prerequisites)]

prereq_query = paste("SELECT cn, prereq_cn FROM desc_prereq INNER JOIN cns",
                     "ON prerequisites LIKE CONCAT('%', prereq_c_n, '%');")

course_prereq = sqldf(prereq_query) |> data.table()

setorderv(course_prereq)

course_prereq[, prereq_id:=1:nrow(course_prereq)]

setcolorder(course_prereq, 'prereq_id')

fwrite(course_prereq, 'data/tables/course_prerequisite.csv')

