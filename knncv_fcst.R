library(kknn)
library(data.table)

knncv_fcst = function(formula, data, nfold, k, SYM_col, DATE_col, scale = TRUE,dist=2){
  yvar <- all.vars(formula)[1]
  xvars <- all.vars(formula)[-1]
  if(missing(DATE_col)==T){  # if no Date, treat each row as an individual date

    DATE_col = seq(1, length(data[[yvar]]), 1)
  }
  data$sortid = seq(0, length(SYM_col)-1, 1)    # makes note of the data order; will sort by sortid at the end
  ### NOTE: if there are NA's in the data, the sort will not be 1 to 1 with the original dataset
  data$DATE = DATE_col
  data$SYM = SYM_col
  data = data[!is.na(data[[yvar]]),]
  for(i in seq(1, length(xvars))){
    data = data[!is.na(data[[xvars[i]]]),]
  }
  
  datelist = unique(DATE_col)
  datelist = sort(datelist)
  if(nfold=="L1O"){
    fold_size=1
    nfold2 = length(datelist)-1
  }else{
    fold_size = max(1, ceiling(length(datelist)/nfold))
    nfold2 = nfold
  }
  
  cv_set = data.frame()
  for(n in c(0:(nfold2-1))){
    start_index = n*fold_size +1
    end_index = min(start_index + fold_size, length(datelist))
    
    if(n==0){
      cv_trainset = data[data$DATE<datelist[start_index] | data$DATE>=datelist[end_index],]
      cv_validset = data[data$DATE>=datelist[start_index] & data$DATE<datelist[end_index],]
    }else if(n==nfold2-1){
      cv_trainset = data[data$DATE<datelist[start_index] | data$DATE>datelist[end_index],]
      cv_validset = data[data$DATE>=datelist[start_index] & data$DATE<=datelist[end_index],]
    }else{
      cv_trainset = data[data$DATE<datelist[start_index] | data$DATE>=datelist[end_index],]
      cv_validset = data[data$DATE>=datelist[start_index] & data$DATE<datelist[end_index],]
    }
    #print(paste(n, length(cv_trainset$x), length(cv_validset$x), fold_size, start_index, end_index, datelist[start_index], datelist[end_index]))
    
    lmcv = lm(formula, data=cv_trainset)
    cv_validset$yhat_lm = predict(lmcv, newdata=cv_validset)
    knncv = kknn(formula, train=cv_trainset, test=cv_validset, k=k, kernel="rectangular",scale=scale,distance=dist)
    cv_validset$yhat_knn = knncv$fitted.values
    
    col_names = c("y", "yhat_lm", "yhat_knn", "SYM", "DATE", "sortid")
    append_df = data.frame(cv_validset[[yvar]], cv_validset$yhat_lm, cv_validset$yhat_knn, cv_validset$SYM, cv_validset$DATE, cv_validset$sortid)
    for(i in seq(1, length(xvars))){
      append_df = cbind(append_df, cv_validset[[xvars[i]]])
      col_names = c(col_names, xvars[i])
    }
    names(append_df) = col_names
    cv_set = rbind(cv_set, append_df)
  }
  
  #cv_set
  #return(cv_set)

  cv_set = cv_set[order(cv_set$sortid),]
  cv_set = within(cv_set, rm("sortid"))
  cv_set
  return(cv_set)

}
