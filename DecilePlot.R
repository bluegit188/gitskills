DecilePlot <- function(model, dataTable,startDate=0,endDate=29990101,isVerbose=0) 
## usage:DecilePlot(ooF1D~GAP-1,regdata,isVerbose=0)
## model: y ~ x -1, specify as no intercept
## compute meanY for each X decile,
## and make a plot
{                                                                                                          
    # Check inputs  
    if (missing(dataTable)) 
        stop("Need to specify the data table.")
    if (!any("DATE" == colnames(dataTable))) {
       stop("dataTable need DATE column!!") 
    }
    #print("MODEL:")
    #print(deparse(model))  
    yname <- all.vars(model)[1]
    xnames <- all.vars(model)[-1]

    #get subset
    dataTable2<- dataTable[dataTable$DATE>= startDate &dataTable$DATE<= endDate,]

    mf <- model.frame(formula=model, data=dataTable2)
    y <- model.response(mf)                         
    x <- model.matrix(attr(mf, "terms"), data=mf) 

    ### cmpute decile mean
    dataTable2$X <- (x)
    dataTable2$XQtr <- cut(dataTable2$X, c(min(dataTable2$X)-0.0000001, quantile(dataTable2$X, c(10,20,30,40,50,60,70,80,90,100)/100, na.rm =T) ))
    table( dataTable2$XQtr)

   dataTable2$Y=(y)


   dt <- data.table(dataTable2)
   setkey(dt,XQtr) # this will sort by X invisibly
   avgs=dt[,list(Y=mean(Y),count=.N),by=XQtr]
   #avgs


   # get interval mid point
   labs <- levels(dataTable2$XQtr)
   LB_UB=cbind(lower = as.numeric( sub("\\((.+),.*", "\\1", labs) ),
           upper = as.numeric( sub("[^,]*,([^]]*)\\]", "\\1", labs) ))
   mid=(as.data.frame(LB_UB)$lower+as.data.frame(LB_UB)$upper)/2

   par(mfrow=c(2, 1))
   # plot Y ~ X
   plot(mid,avgs$Y,type="b",pch=1,lty=1,col="red")
   # plot Y ~ idx
   plot(avgs$Y,type="b",pch=1,lty=1,col="red")
   par(mfrow=c(1, 1))

   dateRange=range(dataTable2$DATE)
   #title(paste(yname,"~",xnames,"|",paste(dateRange,collapse="-")))
   title(paste("MODEL:",deparse(model),":",paste(dateRange,collapse="-")))

   if(isVerbose)
   {
     print(paste("MODEL:",deparse(model),":",paste(dateRange,collapse="-")))
     print(avgs)
   }
  # return(avgs)
}



DecilePlotByYear <- function(model, dataTable,yearStep=1,isVerbose=0)
# DecilePlotByYear(ooF1D~OO1-1,regdata,yearStep=1,isVerbose=0)
# DecilePlotByYear(ooF1D~GAP-1,regdata,1) # last agrument can be 1 or 2, 2 last 2 years
{
                                                                                                       
    # Check inputs  
    if (missing(dataTable)) 
        stop("Need to specify the data table.")
    if (!any("DATE" == colnames(dataTable))) {
       stop("dataTable need DATE column!!") 
    }

    dataTable$MMDD=dataTable$DATE%%10000
    dataTable$YYYY=(dataTable$DATE-dataTable$MMDD) /10000

    years=sort(unique(dataTable$YYYY))

    # n row, 1 col plot
    #par(mfrow=c(length(years), 1),  oma = c(5,4,0,0) + 0.1, mar = c(0,0,1,1) + 0.1)
    #par(mfrow=c(3, 3))

    numYears=length(years)

    if(numYears <=4)
    {
       par(mfrow=c(2, 2))
    }
    else if (numYears <=9)
    {
      par(mfrow=c(3, 3))
    }
    else
    {
       par(mfrow=c(5, 5))
    }  

    for ( n  in 1:numYears)
    {
       YYYY=years[n];
       startDate=YYYY*10000+1*100+1

       locEnd=n+yearStep-1;
       if(locEnd>numYears)
       {
         locEnd=numYears
       }
       YYYYEnd=years[locEnd]
       endDate=YYYYEnd*10000+12*100+31
       if(isVerbose)
       {
          print(paste(YYYY,startDate,endDate))
       }
       DecilePlot(model,dataTable,startDate,endDate,isVerbose)
    }  

    #print("MODEL:")
    #print(deparse(model))  
    #yname <- all.vars(model)[1]
    #xnames <- all.vars(model)[-1] 
    par(mfrow=c(1, 1))
}
