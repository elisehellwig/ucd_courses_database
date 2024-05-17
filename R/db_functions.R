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


append_table = function(conn, tablename, df, id_col='id') {
  
  if (!is.na(id_col)) {
    q = paste('SELECT', id_col,'AS id FROM', tablename, ';')
    
    tbl = dbGetQuery(conn, q)
    
    ids = tbl$id
    
    if (length(ids)==0) {
      max_id = 0
    } else {
      max_id = max(ids)
    }
    
    df[, id_col] = (max_id + 1):(max_id + nrow(df))
    
  } else {
    
    q = paste('SELECT * FROM', tablename, ' LIMIT 10;')
    
    tbl = dbGetQuery(conn, q)
    
  }
  
  
  setcolorder(df, names(tbl))
  
  dbAppendTable(conn, tablename, df)
  
  
}

read_table = function(con, tablename, cols='*', limit=NA, dt=TRUE) {
  
  cols = paste0(cols, collapse = ', ')
  
  query = paste('SELECT', cols, 'FROM', tablename)
  
  if (!is.na(limit)) {
    query = paste0(query, ' LIMIT ', limit, ';')
  } else {
    query = paste0(query, ';')
  }
  
  df = dbGetQuery(con, query)
  
  if (dt) {
    setDT(df)
  }
  
  return(df)
}



