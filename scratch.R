library(httr)
library(jsonlite)
library(xml2)
library(rvest)
library(stringr)

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

strip_all = function(x, start, end) {
  
  chr = as.character(x)
  
  nstart = str_locate_all(chr, start) |> 
    sapply(nrow) |>
    unique()
  
  nend = str_locate_all(chr, end) |>
    sapply(nrow) |>
    unique()
  
  if (length(nstart) > 1 | length(nend) > 1) {
    stop("there must be the same number of start/end strings in each character.")
  }

  if (nstart!=nend) {
    stop("There are a different number of start strings than end strings.")
  }
  
  for (i in 1:nstart) {
    chr = strip(chr, start, end)
  }

  
  return(chr)
}

parse_toggle = function(x, pattern, start, end, na_value=NA) {
  
  grps = html_elements(x, css='em')
  
  x = as.character(x)
  
  is_present = str_detect(x, pattern)
  
  ifelse(is_present, extract_info(x, start , end), na_value)
}


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


url =  "https://catalog.ucdavis.edu/courses-subject-code/eae/"

pg = read_html(url)

#college

college = xml_find_all(pg, "//span[contains(@class, 'title-college')]") |>
 extract_info()


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
  extract_info("</em> ", "</p>")

prereqs = sapply(courses, function(course) {
  x = html_elements(course, xpath=prereq_xpath)
  
  if (length(x)==0) NA else x
}) 


tgls = html_elements(courses, xpath=tgl_xpath) |>
  html_elements(xpath=".//div[contains(@class, 'courseblockextra')]")|>
  html_elements('ul') 


test = html_elements(tgls[14], css='em') |>
  strip_all(start='<', end='>')

lab_hrs = parse_toggle(tgls, 'Laboratory', ' Laboratory', ' hour', 0) |>
  as.integer() 

gen_ed = parse_toggle(tgls, 'General Education', ' Education:</em></span> ', 
                      '.</li>', NA) |>
  str_replace('amp;', '')


html_elements(test, xpath="//span[contains(@class, 'detail-code')]")


la2 = xml_find_all(pg, "//p[contains(@class, 'courseblockextra')]")

html_attrs(pg)



