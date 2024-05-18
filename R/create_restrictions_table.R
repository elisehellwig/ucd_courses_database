library('data.table')
library('stringr')
library('DBI')
library('RPostgres')

source('R/functions.R')
source('R/db_functions.R')

#import_courses
#str_multi_replace
#strsplit_vector
#remove_duplicates

con = ucd_course_connect('elisehellwig')

# Constants ---------------------------------------------------------------

restr_types = c('prerequisite', 'enrollment restriction')

restriction_type = data.table(restriction_type_id = 1:length(restr_types),
                              restriction_type = restr_types)



# Read In -----------------------------------------------------------------

restriction_recode = fread('data/restriction_recode.csv')

desc = read_table(con, 'course_description')


# Restriction table -------------------------------------------------------

restr_table = restriction_recode[, "restriction"]

append_table(con, 'restriction', restr_table)

# Prereqs -----------------------------------------------------------------

pr = desc[!is.na(prerequisites), .(course_id, prerequisites)]

pr[, prereqs:=tolower(prerequisites)]

pr[,":="(instructor_consent=grepl('consent', prereqs),
         upper_division=grepl('upper division', prereqs) | grepl('senior', prereqs),
         graduate=grepl('graduate', prereqs),
         pass_one=grepl('pass one', prereqs),
         major=grepl('major', prereqs) | grepl('program', prereqs),
         medical = (grepl('medical', prereqs) | grepl('medicine', prereqs)) &!
            grepl('ngineer', prereqs))]

pr_wide = subset(pr, select=c(1, 4:ncol(pr)))
pr_long = melt(pr_wide, id.vars = 'course_id')

pr_long = pr_long[value==TRUE]

pr_long[, restriction_type_id:=1]

# Enrollment restrictions -------------------------------------------------

er = desc[!is.na(restrictions), .(course_id, restrictions)]
er[, restrs:=tolower(restrictions)]


er[,":="(instructor_consent=grepl('consent', restrs),
         upper_division=grepl('upper division', restrs),
         graduate=grepl('graduate', restrs),
         limited_enrollment=grepl('limited', restrs),
         major=grepl('major', restrs) | grepl('program', restrs),
         pass_one=grepl('pass one', restrs),
         medical = (grepl('medical', restrs) | grepl('medicine', restrs)) &!
           grepl('ngineer', restrs))]


er_wide = subset(er, select=c(1, 4:ncol(er)))
er_long = melt(er_wide, id.vars = 'course_id')

er_long = er_long[value==TRUE]

er_long[, restriction_type_id:=2]


# combine and format ------------------------------------------------------

restr = read_table(con, 'restriction')
setnames(restr, 'id', 'restriction_id')

course_restr = rbind(pr_long, er_long) |>
  merge(restriction_recode, by='variable') |>
  merge(restr, by='restriction')

course_restr = course_restr[,.(course_id, restriction_id, restriction_type_id)]

append_table(con, 'course_restriction', course_restr)


# disconnect --------------------------------------------------------------

dbDisconnect(con)
