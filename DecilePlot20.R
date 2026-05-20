DecilePlot20 <- function(model, dataTable,startDate=0,endDate=29990101,isVerbose=0) 
## usage:DecilePlot20(ooF1D~GAP-1,regdata,isVerbose=0)
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
    dataTable2$XQtr <- cut(dataTable2$X, c(min(dataTable2$X)-0.0000001, quantile(dataTable2$X, c(5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100)/100, na.rm =T) ))
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


