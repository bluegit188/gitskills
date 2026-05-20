turnover <- function(dataTable, indepVar, printDetails = T) 
    # depVar= yvar vector                                     
    # indepVar =xvar vector                                   
{                                                         
    
    
    dataTable$x <- indepVar
    
    # turnover meansurement
    
    concatTable <- dataTable %>% 
        group_by(SYM) %>%
        dplyr::summarise(concatValueX = sum(abs(x - dplyr::lag(x, default = 0, order_by = DATE))), concatValueY = sum(abs(x)))
    turnover <- round(sum(concatTable$concatValueX) / sum(concatTable$concatValueY, na.rm = T), digits = 7)
    
    # return results
    results <- list(turnover = turnover )
    return(results)
}
