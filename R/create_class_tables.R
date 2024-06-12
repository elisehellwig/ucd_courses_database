library(data.table)
library(stringr)
library(tidyr)
library(sqldf)

source('R/db_functions.R')


con <- ucd_course_connect('elisehellwig')


sis = fread('data/sisweb_class_clean.csv') |> unique()
course = read_table(con, 'course')


# CN corrections ----------------------------------------------------------

(miss = sort(setdiff(sis$cn, course$id)))

sis['BIS134'==cn, cn:= 'SSB134']
sis['ART101'==cn, cn:= 'ART101A']
sis['ART103A'==cn, cn:= 'ART103AN']
sis['ART103B'==cn, cn:= 'ART103AN']
sis['ART105B'==cn, cn:= 'ART105A']
sis['ART121'==cn, cn:= 'ART101E']
sis['CTS012'==cn, cn:= 'ECS012']
sis['CTS041B'==cn, cn:= 'CTS040B']
sis['CTS150'==cn, cn:= 'STS151']
sis['CTS172'==cn, cn:= 'STS172']
sis['DES128'==cn, cn:= 'DES128A']
sis['DES150A'==cn, cn:= 'DES150']
sis['DES150B'==cn, cn:= 'DES150']
sis['DES157'==cn, cn:= 'DES157A']
sis['EAE141'==cn, cn:= 'EAE143B']
sis['ECH158A'==cn, cn:= 'ECH158AN']
sis['ECH158B'==cn, cn:= 'ECH158BN']
sis['ECH161B'==cn, cn:= 'ECH161AN']
sis['ECH161A'==cn, cn:= 'ECH161BN']
sis['ECI140D'==cn, cn:= 'ECI140CN']
sis['ECI149'==cn, cn:= 'ECI149N']
sis['ECI211'==cn, cn:= 'ECI211A']
sis['EEC150A'==cn, cn:= 'EEC150']
sis['EEC150B'==cn, cn:= 'EEC150']
sis['EMS188A'==cn, cn:= 'EMS188AH']
sis['EMS188B'==cn, cn:= 'EMS188BH']
sis['ENT214'==cn, cn:= 'PMI214']

(miss = sort(setdiff(sis$cn, course$id)))

# Create schedule table ---------------------------------------------------

sis[is.na(instructor), instructor:='Unknown']

schedule = unique(sis[,.(cn, term)])

setorder(schedule, term, cn)

setnames(schedule, 'cn', 'course_id')

append_table(con, 'course_schedule', schedule)


# Create Instructor Schedule Table ----------------------------------------


teach = separate_longer_delim(sis, instructor, delim=' | ')
setDT(teach)

teach = teach[, .(cn, term, instructor)]

teach[, instructor:=gsub(', \\.', '', instructor)]

n = table(teach[,.(cn, term)]) |> data.table()
nmax = n[,.SD[which.max(N)], by=.(cn)]

various = nmax[N>4, "cn"]
various[,instructor:='Various']
is_var = merge(schedule[,.(cn, term)], various, by='cn')

not_var_q = paste("SELECT teach.cn, teach.term, teach.instructor",
                  "FROM teach LEFT JOIN various",
                  "ON teach.cn = various.cn",
                  "WHERE various.cn IS NULL;")

not_var = sqldf(not_var_q)
setDT(not_var)

instructor_schedule = rbind(not_var, is_var)


# Create instructor table -------------------------------------------------


instruct = unique(instructor_schedule[,"instructor"])
setnames(instruct, 'instructor', 'name')

one_name = c('The Staff', 'Unknown', 'Various')

instruct[,":="(first=ifelse(name %in% one_name, NA, str_split_i(name, ', ', 2)),
               last=ifelse(name %in% one_name, name, str_split_i(name, ', ', 1)))]

instructor = instruct[, .(first, last)]
setnames(instructor, names(instructor), paste0(names(instructor), "_name"))


# Sort instructor table ---------------------------------------------------

one_name_ids = sapply(one_name, function(s) which(instructor$last_name==s))
other_ids = setdiff(1:nrow(instructor), one_name_ids)

instructor = instructor[c(one_name_ids, other_ids)]

append_table(con, 'instructor', instructor)

