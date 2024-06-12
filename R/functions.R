import_courses = function(fn, var_names, sheet=1) {
  require('readxl')
  require('data.table')
  
  
  df = read_xlsx(fn, sheet=sheet)
  setDT(df)
  
  setnames(df, names(df), var_names)
  
  #df[, cn:=paste0(subject, number)]
  
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

is.duplicated = function(v, dup_num=2) {
  tab = table(v)
  
  dups = names(tab)[which(tab>=dup_num)]
  
  return(dups)
}

is.duplicated.df = function(df, var, dup_num=2) {
  
  setnames(df, var, 'var')
  
  dups = is.duplicated(df[, var], dup_num)
  
  df = df[var %in% dups]
  
  setnames(df, 'var', var)
  
  return(df)
  
}


multi_grepl = function(v, regexes, fun='any') {
  tf_mat = sapply(regexes, function(r) {
    grepl(r, v)
  })
  
  tf = apply(tf_mat, 1, fun)
  
  return(tf)
}

multi_gsub = function(v, strings) {
  for (i in 1:length(strings)) {
    v = gsub(names(strings)[i], strings[i], v)
  }
  
  return(v)
}
