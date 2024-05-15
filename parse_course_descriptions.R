library('readxl')
library('data.table')
library('stringr')
library('sqldf')
library('fuzzyjoin')

# Functions ---------------------------------------------------------------

strsplit_vector = function(v, pattern) {
  split_v = strsplit(v, pattern) |> unlist(use.names = FALSE)
  return(split_v)
}

str_multi_replace = function(v, replace_df) {
  for (i in 1:nrow(replace_df)) {
    v = gsub(replace_df$string[i], replace_df$replacement[i], v)
  }
  
  return(v)
}

remove_duplicates = function(v) {
  unique_matrix = sapply(v, function(act) !(grepl(act, v) & v != act))
  is_unique = apply(unique_matrix, 1, all)
  
  v[is_unique]
}

desc_to_df = function(v, cn, label_patterns, split_pattern=':') {
  df = str_split_fixed(v, split_pattern, 2) |>
    str_replace_all('[<>]', '') |>
    trimws() |>
    matrix(ncol=2) |>
    data.table()
  
  setnames(df, names(df), c('raw_label', 'content'))
  
  df$cn = cn
  
  df = df[content!='']
                        
  double_label = sapply(label_patterns, grepl, df$content) |>
    apply(1, any)
  
  df = df[double_label==FALSE]
  
  
  return(df)
}


parse_description = function(course_df, label_patterns) {
  desc_groups = strsplit(course_df$Description, '<>\r\n', fixed=TRUE)

  df_list = lapply(1:nrow(course_df), function(i) {
    desc_to_df(desc_groups[[i]], course_df$cn[i], label_patterns)
    })
  desc_df = rbindlist(df_list)
  
  return(desc_df)
}

# read in -----------------------------------------------------------------

groups = fread('data/description_categories.csv')
recode_cats = fread('data/label_recode.csv')
recode_grade = fread('data/grade_recode.csv')

course = read_xlsx('data/Banner_ActiveCourses_descriptions_20240510.xlsx')
setDT(course)

df_names = c('Subject', 'Number', 'Status', 'Effective_Term', 'Dept', 
             'Dept_Name', 'College', 'Title', 'Long_Title', 'Units',
             'If_variable', 'Units_High', 'Description')

setnames(course, names(course), df_names)


# Formatting --------------------------------------------------------------

course[,Effective_Date:=as.Date(paste0(Effective_Term , '01'), format='%Y%m%d')]


course[,":="(variable_units = ifelse(is.na(If_variable), FALSE, TRUE),
             cn = paste0(Subject, Number))]


desc_long = parse_description(course, groups$pattern)
desc_long = merge(desc_long, recode_cats, by='raw_label', all.x = TRUE)


desc = dcast(desc_long, cn ~ label, value.var = 'content')
desc[,Virtual:=grepl('Web ', Activities)]

# Parse GEs ---------------------------------------------------------------

ge_replace = data.table(string=c('\\),', ' or '), replacement=c('\\);', '; '))

GEs = desc$Gen_Ed[!is.na(desc$Gen_Ed)] |>
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

GEs = GEs[order(GEs$ge_name)]
GEs[,ge_id:= 1:nrow(GEs)]


desc_ge = desc[ , .(cn, Gen_Ed)]

ge_query <- paste("SELECT cn, ge_id FROM desc_ge INNER JOIN GEs",
                  "ON Gen_Ed LIKE CONCAT('%', ge_name, '%');")

ge_course = sqldf(ge_query) |> data.table()

# ge_course = fuzzy_join(desc_ge, GEs, by= c('Gen_Ed' = 'ge_name'), 
#                        match_fun = str_detect, mode='inner') 
# 
# ge_course = ge_course[, c('cn', 'ge_id')]


# Parse Learning Activities -----------------------------------------------

act_remove = c('hour\\(s\\)', 'hour\\(s\\(', 'hour \\(s\\)', 'hours\\(s\\)',
              '[0-9,\\.\\-]')

act_replace = data.table(string=c(act_remove, '\\s\\s+'), 
                         replacement = c(rep('', length(act_remove)), ' '))

acts = desc$Activities[!is.na(desc$Activities)] |>
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

activity = data.table(act_id = 1:length(acts),
                      Activity = acts)

act_query <- paste("SELECT cn, act_id FROM desc INNER JOIN activity",
                  "ON LOWER(Activities) LIKE CONCAT('%', Activity, '%');")

act_course = sqldf(act_query) |> data.table()

# Create crosslisting -----------------------------------------------------

cl_replace = data.table(string=c(';', '\\.$'), replacement=c(', ', ''))

cl_wide = desc[!is.na(Cross_Listing), .(cn, Cross_Listing)]

cl_wide[, Cross_Listing:=toupper(Cross_Listing)]

cl_wide[, Cross_Listing:=str_multi_replace(Cross_Listing, cl_replace)]

cl = lapply(1:nrow(cl_wide), function(i) {
  cn_vec = str_split_1(cl_wide$Cross_Listing[i], ', ')
  
  data.table(cn=cl_wide$cn[i], Cross_Listing = cn_vec)
}) |> rbindlist()

cl[, Cross_Listing:=gsub(' ', '', Cross_Listing)]



# Create Grade tables -----------------------------------------------------

grade_desc = desc[, .(cn, Grade)]
setnames(grade_desc, 'Grade', 'grade_raw')

grades = recode_grade[, 'grade'] |>
  unique() 

grades = grades[order(grade)]

grades[, ":="(grade_id = 1:nrow(grades),
              is_letter = grepl('Letter', grade))]

recode_grade = merge(recode_grade, grades, by='grade')

grade_query <- paste("SELECT desc.cn, recode_grade.grade_id",
                     "FROM desc LEFT JOIN recode_grade",
                     "ON LOWER(desc.Grade) LIKE pattern;")

course_grade = sqldf(grade_query) |> data.table()

# Prerequisities Table ----------------------------------------------------

course[, c_n:= paste(Subject, Number)]
cns = course[, .(cn, c_n)]
setnames(cns, names(cns), paste0('pr_', names(cns)))

desc_prereq = desc[!is.na(Prerequisites), .(cn, Prerequisites)]

desc_prereq[, prereqs:=tolower(Prerequisites)]

desc_prereq[, ":="(instructor_consent = grepl('consent', prereqs),
                   upper_division = grepl('upper division', prereqs),
                   graduate =  grepl('graduate', prereqs))]


prereq_query = paste("SELECT cn, pr_cn, Prerequisites FROM desc_prereq INNER JOIN cns",
                     "ON Prerequisites LIKE CONCAT('%', pr_c_n, '%');")

course_prereq = sqldf(prereq_query) |> data.table()





