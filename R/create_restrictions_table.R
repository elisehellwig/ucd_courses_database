library('data.table')
library('stringr')

desc = fread('data/course_descriptions.csv')



# Prereqs -----------------------------------------------------------------

pr = desc[Prerequisites!='', .(cn, Prerequisites)]

pr[, prereqs:=tolower(Prerequisites)]

pr[,":="(instructor_consent=grepl('consent', prereqs),
         upper_division=grepl('upper division', prereqs),
         graduate=grepl('graduate', prereqs))]

# Enrollment restrictions -------------------------------------------------

er = desc[, .(cn, Restrictions)]
