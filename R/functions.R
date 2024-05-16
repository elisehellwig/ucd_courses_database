import_courses = function(fn) {
  require(readxl)
  require(data.table)
  
  df_names = c('subject', 'number', 'status', 'effective_term', 'dept', 
               'dept_name', 'college', 'title', 'long_title', 'units',
               'if_variable', 'units_high', 'description')
  
  
  df = read_xlsx(fn)
  setDT(df)
  
  setnames(df, names(df), df_names)
  
  df[, cn:=paste0(subject, number)]
  
  return(df)
}


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

.desc_to_df = function(v, cn, label_patterns, split_pattern=':') {
  require(stringr)
  require(data.table)
  
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
  require(data.table)
  
  desc_groups = strsplit(course_df$description, '<>\r\n', fixed=TRUE)
  
  df_list = lapply(1:nrow(course_df), function(i) {
    .desc_to_df(desc_groups[[i]], course_df$cn[i], label_patterns)
  })
  desc_df = rbindlist(df_list)
  
  return(desc_df)
}