printSharpeRatioIntra <- function(dataTable, depVar, indepVar, printDetails = T,sizeX=0.03,tcost = 0.03) 
    # depVar= yvar vector                                     
    # indepVar =xvar vector                                   
{    

                                                      
    lmfit <- lm(formula = depVar ~ indepVar,data=dataTable) 
    


    dataTable$x <- indepVar
    dataTable$y <- depVar
    dataTable$sizeX <- sizeX # entry threshold
    dataTable$tcost <- tcost # 0.03
    
    dataTable <- dataTable %>%
        dplyr::group_by(SYM) %>%
        dplyr::mutate( pos = sign(x) * (abs(x) - sizeX) * (abs(x) >= sizeX) ) %>%
        dplyr::mutate( posZeroCost = x ) %>%
        #dplyr::mutate( pnl = y*pos - tcost * abs(pos - dplyr::lag(pos, default = 0, order_by = DATE)) ) %>%
        # for intra method
        dplyr::mutate( pnl = y*pos - tcost * abs(pos) ) %>%
        dplyr::mutate( pnlZeroCost = y*x ) # this will ignore netFcst reduction
        #dplyr::mutate( pnlZeroCost = y*pos ) # this will factor in netFcst reduction       


    # ----------------------
    # Without Cost 
    pnlStdZeroCost <- sd(dataTable$pnlZeroCost)
    contractSharpeRatioZeroCost <- mean(dataTable$pnlZeroCost) / pnlStdZeroCost
    #contractSharpeRatioZeroCost                                
    contractSharpeRatioPAZeroCost <- contractSharpeRatioZeroCost*sqrt(252)
    


    groupDataZeroCost <- dataTable %>%
        dplyr::group_by(DATE) %>%
        dplyr::summarise(ppnlZeroCost = sum(pnlZeroCost))
    
    ppnlStdZeroCost <- sd(groupDataZeroCost$ppnlZeroCost)
    portfolioSharpeRatioZeroCost <- mean(groupDataZeroCost$ppnlZeroCost) / ppnlStdZeroCost
    portfolioSharpeRatioZeroCost
    portfolioSharpeRatioPAZeroCost <- portfolioSharpeRatioZeroCost*sqrt(252)
    



    # Max Drawdown
    MDDZeroCost <- tseries::maxdrawdown(cumsum(groupDataZeroCost$ppnlZeroCost))$maxdrawdown / ppnlStdZeroCost / sqrt(252)




    divNum0ZeroCost <- portfolioSharpeRatioZeroCost / contractSharpeRatioZeroCost
  
    skew=skewness(dataTable$pnlZeroCost)
    kurt=kurtosis(dataTable$pnlZeroCost)

    contractPnlZeroCost <- round(c(summary(dataTable$pnlZeroCost),pnlStdZeroCost,skew,kurt,contractSharpeRatioZeroCost,contractSharpeRatioPAZeroCost),digits=7)
    names(contractPnlZeroCost) <- c("min","Q1","median","mean","Q3","max","std","skew","kurt","pcShp","pcShp.pa");
    

    skewPort=skewness(groupDataZeroCost$ppnlZeroCost)
    kurtPort=kurtosis(groupDataZeroCost$ppnlZeroCost)

    portfolioPnlZeroCost <- round(c(summary(groupDataZeroCost$ppnlZeroCost),ppnlStdZeroCost, skewPort,kurtPort,portfolioSharpeRatioZeroCost, portfolioSharpeRatioPAZeroCost,MDDZeroCost),digits=7)
    names(portfolioPnlZeroCost) <- c("min","Q1","median","mean","Q3","max","std","skew","kurt","portShp","portShp.pa","MDD");
    
    divNumZeroCost <- c(portfolioSharpeRatioPAZeroCost,contractSharpeRatioPAZeroCost,divNum0ZeroCost)
    names(divNumZeroCost) <- c("portShp.pa","pcShp.pa","divNum")
    



    # ----------------------
    # With T cost
    pnlStd <- sd(dataTable$pnl)
    contractSharpeRatio <- mean(dataTable$pnl) / pnlStd
    contractSharpeRatio                                
    contractSharpeRatioPA <- contractSharpeRatio*sqrt(252)
    
    groupData <- dataTable %>%
        dplyr::group_by(DATE) %>%
        dplyr::summarise(pnl = sum(pnl))
    
    ppnlStd <- sd(groupData$pnl)
    portfolioSharpeRatio <- mean(groupData$pnl) / ppnlStd
    portfolioSharpeRatio
    portfolioSharpeRatioPA <- portfolioSharpeRatio*sqrt(252)
    




    # Max Drawdown
    MDD <- tseries::maxdrawdown(cumsum(groupData$pnl))$maxdrawdown / ppnlStd / sqrt(252)



    divNum0 <- portfolioSharpeRatio / contractSharpeRatio
    


    skew=skewness(dataTable$pnl)
    kurt=kurtosis(dataTable$pnl)

    contractPnl <- round(c(summary(dataTable$pnl),pnlStd,skew,kurt,contractSharpeRatio,contractSharpeRatioPA),digits=7)
    names(contractPnl) <- c("min","Q1","median","mean","Q3","max","std","skew","kurt","pcShp","pcShp.pa");
    

    skewPort=skewness(groupData$pnl)
    kurtPort=kurtosis(groupData$pnl)

    portfolioPnl <- round(c(summary(groupData$pnl),ppnlStd, skewPort,kurtPort,portfolioSharpeRatio, portfolioSharpeRatioPA,MDD),digits=7)
    names(portfolioPnl) <- c("min","Q1","median","mean","Q3","max","std","skew","kurt","portShp","portShp.pa","MDD");
    
    divNum <- c(portfolioSharpeRatioPA,contractSharpeRatioPA,divNum0)
    names(divNum) <- c("portShp.pa","pcShp.pa","divNum")
    



    # turnover meansurement
    
    concatTable <- dataTable %>% 
        group_by(SYM) %>%
        dplyr::summarise(concatValueX = sum(abs(x - dplyr::lag(x, default = 0, order_by = DATE))), concatValueY = sum(abs(x)))
    turnover <- round(sum(concatTable$concatValueX) / sum(concatTable$concatValueY, na.rm = T), digits = 7)
    # turnoverData <- dataTable %>%
    #     group_by(SYM) %>%
    #     summarise( turnover = sum(abs(x - dplyr::lag(x, default = 0)) / sum(abs(x)), na.rm = T))
    
    # return results
    results <- list(depVar = deparse(substitute(depVar)),
                    indepVar = deparse(substitute(indepVar)),
                    linearRegression = summary(lmfit),
                    lmfit = lmfit,
                    sep1="---------- No Tcost ------------",
                    contractPnlZeroCost = contractPnlZeroCost,
                    portfolioPnlZeroCost = portfolioPnlZeroCost,
                    divNumZeroCost = divNumZeroCost,
                    sep2="---------- With Tcost, optXTIntra ------------",
                    contractPnl = contractPnl ,
                    portfolioPnl = portfolioPnl,
                    divNum = divNum,
                    turnover = turnover )
    # if (printDetails) {
    #     print( results )
    # }
    


    return( results )
    


}
