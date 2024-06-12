library('readxl')
library('data.table')
library('stringr')
library('sqldf')

source('R/functions.R')



# Strings -----------------------------------------------------------------

course_fn = 'data/Banner_ActiveCourses_descriptions_20240510.xlsx'
enroll_fn = 'data/DR7238.xlsx'

course_vars = c('subject', 'number', 'status', 'effective_term', 'dept', 
                'dept_name', 'college', 'title', 'long_title', 'units',
                'if_variable', 'units_high', 'description')

enroll_vars = c('term', 'subject_name', 'college_name', 'department_name',
                'subject', 'number', 'crn', 'current_title', 'past_title',
                'instructor', 'enrollment')

# Read In -----------------------------------------------------------------

groups = fread('data/description_categories.csv')
recode_cats = fread('data/label_recode.csv')

course = import_courses(course_fn, course_vars)
enroll0 = import_courses(enroll_fn, enroll_vars, sheet='Data')
enroll = enroll0[enrollment>0]

# Fixing Typos ------------------------------------------------------------

course[dept_name == 'Biological & Agricultural Engr', dept:='DBAE']
course[dept_name == 'Psychology', dept:='PSYC']

course[dept == 'ENGL', ":=" (dept='ENGH', dept_name='English')]

course[subject=='ECS' & number=='119', 
       ":="(dept='CSCI', dept_name='Computer Science')]

recode_subjs = c(WMSW = 'WMS', POLW='POL')

enroll[ ,subject:=multi_gsub(subject, recode_subjs)]


# Create Course numbers ---------------------------------------------------

course[, cn:= paste0(subject, number)]
enroll[, cn:= paste0(subject, number)]


# Parse Course Description ------------------------------------------------

desc_long = parse_description(course, groups$pattern)
desc_long = merge(desc_long, recode_cats, by='raw_label', all.x = TRUE)

desc = dcast(desc_long, cn ~ label, value.var = 'content')
setnames(desc, names(desc), tolower(names(desc)))

# Not courses -------------------------------------------------------------

not_courses = c('0000', #Inter-campus visitor or inter-campus exchange
                'EAPE',  #Study abroad
                '^WLD',  #Extra work for intro level courses??? 
                'XXX',   #Test course
                'PHE',  #PE courses that were last taught in 2020
                '99' #Research
)

enroll = enroll[multi_grepl(cn, not_courses) == FALSE]

# Missing CNs -------------------------------------------------------------

current = enroll[,.SD[which.max(term)], by=cn][,.(cn, subject, term, current_title, number)]

miss_q = paste("SELECT current.cn, current.term, current.current_title,",
               "current.subject, current.number",
               "FROM current LEFT JOIN course",
               "ON current.cn LIKE '%' || course.cn || '%' ",
               "WHERE course.cn IS NULL",
               "ORDER BY current.cn ASC;")

missing = sqldf(miss_q)
miss_subj = table(missing$subject) |> data.table()
#miss_subj[order(N, decreasing=TRUE)]

#fwrite(missing, 'data/missing_cns.csv')

enroll[,cn:=ifelse(cn %in% missing$cn & grepl('^WMS\\d', cn),
                   gsub('WMS', 'GSW', cn), 
                   cn)]



# Extracting codes --------------------------------------------------------

enroll[, ":="(college = str_split_i(college_name, ' - ', 1),
              dept = str_split_i(department_name, ' - ', 1))]


# Separating data ---------------------------------------------------------

enroll_course = enroll[,.(cn, college, dept)] |> unique()

enroll_class = enroll[, .(cn, term, current_title, instructor)] |> unique()


# write -------------------------------------------------------------------

fwrite(course, 'data/courses_clean.csv', na=NA)
fwrite(desc, 'data/course_descriptions.csv', na=NA)

fwrite(enroll_course, 'data/sisweb_course_clean.csv', na=NA)
fwrite(enroll_class, 'data/sisweb_class_clean.csv', na=NA)

