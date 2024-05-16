library('readxl')
library('data.table')

source('functions.R')
#import_courses()

# Constants ---------------------------------------------------------------

course_vars = c('cn', 'subject', 'effective_term', 'title', 'long_title',
                'units', 'if_variable', 'units_high')

final_course_vars = c('cn', 'subject', 'title', 'long_title', 'units',
                      'variable_units', 'units_high', 'effective', 'active')

# Read In -----------------------------------------------------------------

course_fn = 'data/Banner_ActiveCourses_descriptions_20240510.xlsx'

course = import_courses(course_fn)

# Course table ------------------------------------------------------------

courses = course[, ..course_vars]

courses[,":="(effective=as.Date(paste0(effective_term , '01'), format='%Y%m%d'),
              variable_units = ifelse(is.na(if_variable), FALSE, TRUE),
              active=TRUE)]

courses = courses[, ..final_course_vars]

fwrite(courses, 'data/tables/courses.csv')

