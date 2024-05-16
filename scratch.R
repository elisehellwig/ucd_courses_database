library(httr)
library(jsonlite)
library(xml2)
library(rvest)
library(stringr)

toggle_names = c('Activities', 'Restriction', 'Credit', 'Grade', 'Education')

# Functions ---------------------------------------------------------------


create_xpath = function(type, contains, label='class', current=TRUE) {
  
  xpath_str = paste0("//", type, "[contains(@", label, ", '", contains, "')]")
  
  if (current) {
    xpath_str = paste0('.', xpath_str)
  }
  
  return(xpath_str)
}

  

extract_info = function(x, start=">", end="<") {
  x = as.character(x) 
  
  x = str_split_i(x, start, i=2)
  
  x = str_split_i(x, end, i=1)
  
  return(x)
  
}


strip = function(x, start, end) {
  
  chr = as.character(x)
  
  n = length(chr)
  
  start_loc = str_locate(chr, start)
  end_loc = str_locate(chr, end)
  
  locs = cbind(start_loc[,1], end_loc[,2])
  colnames(locs) = c('start', 'end')
  
  str_sub(chr, locs) <- ""
  
  return(chr)
  
}

strip_all = function(x, start='<', end='>') {
  
  chr = as.character(x)
  
  nstart = str_locate_all(chr, start) |> 
    sapply(nrow)
  
  nend = str_locate_all(chr, end) |>
    sapply(nrow)
  

  if (!identical(nstart,nend)) {
    stop("There are a different number of start strings than end strings.")
  }
  
  for (i in 1:length(chr)) {
    for (j in 1:nstart[i]) {
      chr[i] = strip(chr[i], start, end)
    }
  }
  
  return(chr)
}


toggle_groups = function(x, grp_names) {
  
  grps_list = lapply(x, function(block) {
    html_elements(block, css='em') |>
      strip_all(start='<', end='>') 
  })
  
  mat = sapply(grp_names, function(name) {
    sapply(grps_list, function(gl) {
      any(str_detect(gl, name))
    })
  })
  
  df = data.frame(mat)
  
  return(df)
}

extract_text = function(x, key) {
  
  chr = as.character(x) 
  
  chr = str_split_1(chr, key)
  
  chr = str_split_1(chr[2], '</span> ')
  chr = str_split_1(chr[2], ".</li>")
  chr = str_replace_all(chr[1], 'amp;', '')
  
  return(chr)
  
}


parse_toggle = function(x, group_names) {
  
  n = length(x)
  
  grps = toggle_groups(x, group_names)
  

  text = sapply(group_names, function(col_name) {
    
    sapply(1:n, function(i) {
      if (grps[[col_name]][i]) {
        x = extract_text(x[i], col_name) 
        
        ifelse(grepl('<', x), strip_all(x), x)
      } else {
        NA
      }
    })
    
  })
  
  return(data.frame(text))
  
}

parse_activities = function(chr, activity) {
  activities = str_split(chr, ',')
  
  
  ids = sapply(activities, function(vec) {
    grep(activity, )
  })
  
  hrs = str_sub(chr, start+2, start+2) |> as.numeric()
  
  hrs[is.na(hrs)] = 0
  
  return(hrs)
}

parse_prereqs = function(x, course) {
  
  chr = strip_all(x, '<', '>') |>
    str_replace_all(' C- or better', '')
  
  chr = gsub("Prerequisite(s): ", "", chr, fixed=TRUE)
  
  course_vec = str_split_1(chr, ";") |>
    trimws() |>
    
  
  concurrent = grepl('concurrent', course_vec)
  
  course_list = lapply(course_vec, function(vec) {
    str_split_1(vec, 'or')
  })
}

# Extract general info ----------------------------------------------------


catalog_url = "https://catalog.ucdavis.edu/courses-subject-code/"

doc = read_html(catalog_url)

links = html_elements(doc, "a") |> 
  as.character()
  
x = "courses-subject-code//[a-z][a-z][a-z]//"

is_dept = grepl("courses-subject-code/[a-z][a-z][a-z]/", links) 

dept_strings = links[is_dept] |>
  str_split_i('>', i=2) 

dept_names = str_split_i(dept_strings, " \\(", i=1)|>
  str_replace("amp;", "")

dept_abbr = str_split_i(dept_strings, " \\(", i=2) |>
  str_replace_all("[^A-Z]", "")


# Extract course info -----------------------------------------------------

url =  "https://catalog.ucdavis.edu/courses-subject-code/phy/"

pg = read_html(url)

#college

college = xml_find_all(pg, "//span[contains(@class, 'title-college')]") |>
  extract_info() |>
  str_replace_all('amp;', '')

#courses

divs = html_elements(pg, css='div') 

'tgl6'

num_xpath = create_xpath('span', 'courseblockdetail detail-code') 
title_xpath = create_xpath('span', 'courseblockdetail detail-title')
units_xpath = create_xpath('span', 'courseblockdetail detail-hours')
desc_xpath = create_xpath('p', 'courseblockextra')
prereq_xpath = create_xpath('p', 'detail-prerequisite')
prereq_xpath = create_xpath('p', 'detail-prerequisite')
tgl_xpath = create_xpath('div', 'notinpdf')

#html block with course information in it
courses = html_elements(pg, xpath="//div[@class='courseblock']")

#extract course number (ex ABC 001)
nums = html_elements(courses, xpath=num_xpath) |>
  html_elements(css='b') |>
  extract_info()

#extract course title
titles = html_elements(pg, xpath=title_xpath) |>
  html_elements(css='b') |>
  extract_info() |>
  str_replace("^[^a-zA-Z]+", "") |>
  str_replace_all("amp;", "")

#extract number of units
units = html_elements(pg, xpath=units_xpath) |>
  html_elements(css='b') |>
  extract_info() |>
  str_replace_all("[^0-9\\-]", "") 

#extract course description
desc = html_elements(pg, xpath=desc_xpath) |>
  #extract_info("</em> ", "</p>") |>
  strip_all('<', '>')

prereqs = sapply(courses, function(course) {
  x = html_elements(course, xpath=prereq_xpath)
  
  if (length(x)==0) NA else x
}) 


tgls = html_elements(courses, xpath=tgl_xpath) |>
  html_elements(xpath=".//div[contains(@class, 'courseblockextra')]")|>
  html_elements('ul') 


tgl_df = parse_toggle(tgls, toggle_names)

tgl_df$Lab = parse_activities(tgl_df$Activities, 'Laboratory')
tgl_df$Lecture = parse_activities(tgl_df$Activities, 'Lecture')
tgl_df$Discussion = parse_activities(tgl_df$Activities, 'Discussion')


la2 = xml_find_all(pg, "//p[contains(@class, 'courseblockextra')]")

html_attrs(pg)



