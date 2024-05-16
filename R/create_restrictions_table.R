library('data.table')
library('stringr')

desc = fread('data/course_descriptions.csv')

restriction_recode = fread('data/restriction_recode.csv')

restr_types = c('prerequisite', 'enrollment restriction')

restriction_type = data.table(restriction_type_id = 1:length(restr_types),
                              restriction_type = restr_types)

# Prereqs -----------------------------------------------------------------

pr = desc[prerequisites!='', .(cn, prerequisites)]

pr[, prereqs:=tolower(prerequisites)]

pr[,":="(instructor_consent=grepl('consent', prereqs),
         upper_division=grepl('upper division', prereqs) | grepl('senior', prereqs),
         graduate=grepl('graduate', prereqs),
         pass_one=grepl('pass one', prereqs),
         major=grepl('major', prereqs) | grepl('program', prereqs),
         medical = (grepl('medical', prereqs) | grepl('medicine', prereqs)) &!
            grepl('ngineer', prereqs))]

pr_wide = subset(pr, select=c(1, 4:ncol(pr)))
pr_long = melt(pr_wide, id.vars = 'cn')

pr_long = pr_long[value==TRUE]

pr_long[, restriction_type_id:=1]

# Enrollment restrictions -------------------------------------------------

er = desc[restrictions!='', .(cn, restrictions)]
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
er_long = melt(er_wide, id.vars = 'cn')

er_long = er_long[value==TRUE]

er_long[, restriction_type_id:=2]


# combine and format ------------------------------------------------------

course_restr = rbind(pr_long, er_long) |>
  merge(restriction_recode, by='variable') 

course_restr = course_restr[,.(cn, restriction_id, restriction_type_id)]

restr = restriction_recode[, .(restriction_id, restriction)]

# write tables ------------------------------------------------------------

fwrite(restriction_type, 'data/tables/restriction_type.csv')
fwrite(restr, 'data/tables/restriction.csv')
fwrite(course_restr, 'data/tables/course_restriction.csv')


