get_password = function() {
  return(readLines('data/computer.config'))
}


ucd_course_connect = function(username, hostname = 'localhost') {
  con <- dbConnect(RPostgres::Postgres(),
                   dbname = "ucd_courses",
                   host = hostname,
                   port = 5432,
                   user = username,
                   password = get_password())
  
  return(con)
}
