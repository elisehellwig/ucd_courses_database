library('readxl')
library('data.table')
library('stringr')

source('R/functions.R')


# Read In -----------------------------------------------------------------

groups = fread('data/description_categories.csv')
recode_cats = fread('data/label_recode.csv')

course = import_courses()

# Department issues -------------------------------------------------------

course[dept_name == 'Biological & Agricultural Engr', dept:='DBAE']
course[dept_name == 'Psychology', dept:='PSYC']

course[dept == 'ENGL', ":=" (dept='ENGH', dept_name='English')]


# Parse Course Description ------------------------------------------------

desc_long = parse_description(course, groups$pattern)
desc_long = merge(desc_long, recode_cats, by='raw_label', all.x = TRUE)

desc = dcast(desc_long, cn ~ label, value.var = 'content')
setnames(desc, names(desc), tolower(names(desc)))

# write -------------------------------------------------------------------

fwrite(course, 'data/courses_clean.csv', na=NA)
fwrite(desc, 'data/course_descriptions.csv', na=NA)

