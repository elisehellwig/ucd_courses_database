library('readxl')
library('data.table')
library('stringr')
library('sqldf')

source('functions.R')
#import_courses
#parse_description

# read in -----------------------------------------------------------------

groups = fread('data/description_categories.csv')
recode_cats = fread('data/label_recode.csv')

course = import_courses()

# Parse Description -------------------------------------------------------


desc_long = parse_description(course, groups$pattern)
desc_long = merge(desc_long, recode_cats, by='raw_label', all.x = TRUE)


desc = dcast(desc_long, cn ~ label, value.var = 'content')


# write description data --------------------------------------------------

fwrite(desc, 'data/course_descriptions.csv')


