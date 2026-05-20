MSIntra <- function(model, dataTable, sizeX=0.03,tcost = 0.03) {
    # Check inputs
    if (missing(dataTable))
        stop("Need to specify the data table.")
    if (!any("DATE" == colnames(dataTable))) {
        stop("dataTable need DATE column!!")
    }
    
    print("MODEL:")
    print(deparse(model))


    
    mf <- model.frame(formula=model, data=dataTable)
    y <- model.response(mf)
    x <- model.matrix(attr(mf, "terms"), data=mf)
    


    len <- length(unique(dataTable$DATE))
    qtrLen <- dim(x)[2]
    SiMat <- matrix(, len, qtrLen)
    dataTable$y <- y
    for (i in c(1:qtrLen)) {
        tempName <- paste0('tempMS_x',i)
        dataTable[[tempName]] <- x[,i]
        tempTable <- dataTable %>%
            dplyr::group_by(DATE) %>%
            dplyr::summarise(temp = sum(y*get(tempName)))
        SiMat[,i] <- tempTable$temp
    }


    


    M <- colMeans(SiMat)
    Stemp <- SiMat - matrix(rep(M, len), len, qtrLen, byrow = T)
    S <- 1/(len-1)* t(Stemp) %*% Stemp
    
    L <- chol(S)
    A <- t(solve(L)) %*% t(t(M)) %*% t(M) %*% solve(L)
    
    A <- eigen(A)$vectors %*% diag(eigen(A)$values) %*% t(eigen(A)$vectors)
    lmCoefs <- solve(t(eigen(A)$vectors) %*% L, c(1, rep(0, qtrLen-1)))

    


    yhat <- x %*% lmCoefs
    # rescale
    tempLM <- lm(y~yhat)
    lmCoefs <- tempLM$coefficients['yhat']* lmCoefs
    yhat <- x %*% lmCoefs

    if (sum(y*yhat) < 0) {
         yhat <- -yhat
         lmCoefs <- -lmCoefs
    }


    printResults <- printSharpeRatioIntra(dataTable, y, yhat)
    


    #-- add maxShp coefs
    # printResults[['Model']] <- deparse(model)
    printResults[['sep3']] ="---------- maxShp coefs ------------"

    #printResults[['Coefficients']] <- printResults$linearRegression$coefficients[1] + 
    #printResults$linearRegression$coefficients[2]*lmCoefs
    printResults[['Coefficients']] <- lmCoefs
    names(printResults[['Coefficients']]) <- attr(x, 'dimnames')[[2]]
    
    # coefs printed vertically
    MSCoefs=data.table(cbind(names(printResults$Coef),round(printResults$Coef,digits=7)))
    names(MSCoefs)=c("indicator", "coef")
    printResults[['MSCoefs']] =  MSCoefs
    printResults[['Coefficients']] <- NULL	

    #print(printResults)
    #cat( 'Tips \n[1]You can get MS fcst by: *$lmfit$model$indepVar' )

    return(printResults)
}
