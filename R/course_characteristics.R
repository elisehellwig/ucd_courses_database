library('readxl')
library('data.table')
library('stringr')
library('sqldf')

source('functions.R')

course_fn = 'data/Banner_ActiveCourses_descriptions_20240510.xlsx'

# read in -----------------------------------------------------------------

recode_grade = fread('data/grade_recode.csv')

desc = fread('data/course_descriptions.csv')


# Create Grade table ------------------------------------------------------

grade_desc = desc[, .(cn, Grade)]
setnames(grade_desc, 'Grade', 'grade_raw')

grades = recode_grade[, 'grade'] |>
  unique() 

grades = grades[order(grade)]

grades[, ":="(grade_id = 1:nrow(grades),
              is_letter = grepl('Letter', grade))]

setcolorder(grades, 'grade_id')

fwrite(grades, 'data/tables/grade.csv')


# Standardize grades ------------------------------------------------------

recode_grade = merge(recode_grade, grades, by='grade')

grade_query <- paste("SELECT desc.cn, recode_grade.grade_id",
                     "FROM desc LEFT JOIN recode_grade",
                     "ON LOWER(desc.Grade) LIKE pattern;")

course_grade = sqldf(grade_query) |> data.table()

# create variables --------------------------------------------------------

desc[,":="(virtual=grepl('Web ', Activities),
           repeatable = ifelse(Repeat_Credit=='', FALSE, TRUE))]

desc = merge(desc, course_grade, by='cn')


# Subset and write --------------------------------------------------------

chars = desc[,.(cn, grade_id, virtual, repeatable)]

fwrite(chars, 'data/course_characteristics.csv')
