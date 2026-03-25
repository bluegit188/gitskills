## put something like this is your .Rprofile to customize the defaults
setHook(packageEvent("grDevices", "onLoad"), 
function(...) grDevices::X11.options(type="Xlib"))

.onLoad <- function(...) {
  if (requireNamespace("ggthemes", quietly = TRUE)) {
    ggplot2::theme_set(ggthemes::theme_tufte(base_family = "Times New Roman"))
  }
}

#wide column width for displaying
options(width=200)
#for fread fast read
library(data.table)
#for cumpnl plot
library(ggplot2)

#below for fixing up lbox8 R text display
library(showtext,quietly=TRUE)
#par(family  = "Times") 
showtext_auto()

scaleZero2One <- function(x)
#array scaled 
{
  #scale y to be 0-1
  min=min(x)
  max=max(x)
  scale=max-min
  x<- (x -min)/scale
}


# add transformed X1, X2 and absX2
sigmoid <- function(x) 
{
 1 / ( 1 + exp(-x) )
}


asigmoid <- function(x) 
{
  log(x/(1-x))
}





constrainByPct <- function(x,pct)
#pct=0.01 
{
  min=quantile(x,prob=pct)
  max=quantile(x,prob=(1-pct))
  x=ifelse(x<min, min, x)
  x=ifelse(x>max, max, x)
}


constrain <- function(x,min,max)
#pct=0.01 
{
  x=ifelse(x<min, min, x)
  x=ifelse(x>max, max, x)
}


DOW <- function(DATE)
#date=20180711 
# sun=0, mon=1, tue=2,...
{
   MMDD=DATE%%10000
   YYYY=(DATE-MMDD) /10000
   DD=DATE%%10000%%100
   YYMM=(DATE-DD) /100
   MM=(MMDD-DD)/100

   year=YYYY
   month=MM
   day=DD

  # Implementation of the Gaussian algorithm to get weekday 0 - Sunday, ... , 7 - Saturday
  Y <- year
  Y[month<3] <- (Y[month<3] - 1)

  d <- day
  m <- ((month + 9)%%12) + 1
  c <- floor(Y/100)
  y <- Y-c*100
  dayofweek <- (d + floor(2.6*m - 0.2) + y + floor(y/4) + floor(c/4) - 2*c) %% 7
  return(dayofweek)
}



createIdx <- function(DATE, X)
# based on key=DATE, and x
# create idx of X, and output dataframe: (DATE, idxX, count)
### how to use
# dfIdx=createIdx(regdata$DATE,regdata$OC1)
# names(dfIdx)=c("DATE","idx.OC1.jf","count")
# regdata=merge(regdata,  dfIdx, by="DATE")
####
{ 
   df= as.data.frame(cbind(DATE,X))
   names(df)=c("DATE","X")

   # step 2: create idx for x
   # data table util is very fast
   dt <- data.table(df)
   setkey(dt,DATE) # this will sort by DATE invisibly
   dfIdx<-dt[,list(idx=mean(X),count=.N),by=DATE]
   #names(dfIdx)=c("DATE","idx.OC1.jf","count")

   return(dfIdx)
}



# compute corr without demean
corrwodm <- function(x,y) 
{
   sdx_wodm=sqrt(sum((x)*(x))/(length(x)-1))
   sdy_wodm=sqrt(sum((y)*(y))/(length(y)-1))
   sum((x)*(y))/(sdx_wodm*sdy_wodm)/(length(x)-1)
}

# beta with non-intercept OLD, same as above case, note the input order for x and y
beta_nointer <- function(x,y) 
{
   sum(x*y)/sum(x*x)
}

# compute corr with demean
corrorig <- function(x,y) 
{
   sdx=sd(x)
   sdy=sd(y)
   sum((x-mean(x))*(y-mean(y)))/(sdx*sdy)/(length(x)-1)
}




plotCumPPL<- function(DATE, y,x, titleStr="CumuPnl")
#usage: plotCumPPL(regdata$DATE,regdata$ooF1D, fcst,titleStr="cumpnl")
{ 
   # disable warning tempororily
   #defaultW <- getOption("warn")
   #options(warn = -1)

   pnl=y*x
   cor=cor(y,x)
   corZM=corrwodm(y,x)

   df= as.data.frame(cbind(DATE,pnl))
   names(df)=c("DATE","pnl")

   # step 2: create idx for x
   # data table util is very fast
   dt <- data.table(df)
   setkey(dt,DATE) # this will sort by DATE invisibly
   dfPort<-dt[,list(ppl=sum(pnl),count=.N),by=DATE]
   names(dfPort)=c("DATE","ppl","count")

   #plot(cumsum(dfPort$ppl))

   dfPort$cumppl=cumsum(dfPort$ppl);
   #use Date
   dfPort$Date <- as.Date(strptime(dfPort$DATE, "%Y%m%d"))

   #base plot
   #plot(cumppl ~ Date,dfPort, xaxt = "n", type = "l") 
   #title("cumpnl plot")
   #axis(1, dfPort$Date, format(dfPort$Date, "%Y%m%d"), cex.axis = 1) 
 
   mean=mean(dfPort$ppl)
   sd=sd(dfPort$ppl)
   shp=mean/sd*sqrt(252)
   print(paste("pplShp= ",round(shp,digits=5), "mean= ",round(mean,digits=5)," std= ",round(sd,digits=5)))

   # turn warning back on
   #options(warn = defaultW)


   #ggplot
   #require(ggplot2)
   #ggplot( data = dfPort, aes( Date, cumppl )) + geom_line()+ggtitle("cumpnl plot")+labs(title = "New plot title")
   m<- ggplot( data = dfPort, aes( Date, cumppl )) + geom_line()
   m<- m + labs(title = paste(titleStr,
                              "|cor=",as.character(round(cor,digits=6)),
                              " corZM=", as.character(round(corZM,digits=6)), 
                              " shp=", as.character(round(shp,digits=6)) 
                              ))
   m

}





plotCumPPL2<- function(DATE, y,x1,x2)
#usage: plotCumPPL2(regdata$DATE,regdata$ooF1D, fcst1,fcst2)
{
    pnl1 = y * x1
    pnl2 = y * x2
    df = as.data.frame(cbind(DATE, pnl1,pnl2))
    names(df) = c("DATE", "pnl1","pnl2")
    dt <- data.table(df)
    setkey(dt, DATE)

    dfPort1 <- dt[, list(ppl = sum(pnl1), count = .N), by = DATE]
    names(dfPort1) = c("DATE", "ppl", "count")
    dfPort1$cumppl = cumsum(dfPort1$ppl)

    dfPort2 <- dt[, list(ppl = sum(pnl2), count = .N), by = DATE]
    names(dfPort2) = c("DATE", "ppl", "count")
    dfPort2$cumppl = cumsum(dfPort2$ppl)


    dfPort1$Date <- as.Date(strptime(dfPort1$DATE, "%Y%m%d"))
    mean1 = mean(dfPort1$ppl)
    sd1 = sd(dfPort1$ppl)
    shp1 = mean1/sd1 * sqrt(252)
    mdd1 =mdd(dfPort1$ppl)

    dfPort2$Date <- as.Date(strptime(dfPort2$DATE, "%Y%m%d"))
    mean2 = mean(dfPort2$ppl)
    sd2 = sd(dfPort2$ppl)
    shp2 = mean2/sd2 * sqrt(252)
    mdd2 =mdd(dfPort2$ppl)

    print(paste("Black: pplShp1= ", round(shp1, digits = 5), "mean1= ", 
        round(mean1, digits = 5), " std1= ", round(sd1, digits = 5), " mdd1= ", round(mdd1, digits = 5)   ))
    print(paste("Red: pplShp2= ", round(shp2, digits = 5), "mean2= ", 
        round(mean2, digits = 5), " std2= ", round(sd2, digits = 5), " mdd2= ", round(mdd2, digits = 5)))
    #ggplot(data = dfPort, aes(Date, cumppl)) 
    #   + geom_line() + 
    #    ggtitle("cumpnl plot")


    p = ggplot() + 
        geom_line(data = dfPort1, aes(x = Date, y = cumppl), color = "black", size=1.5) +
        geom_line(data = dfPort2, aes(x = Date, y = cumppl), color = "red") +
        xlab('Date') +
        ylab('cumppl')+ggtitle("cumpnl plot")
       # +scale_color_manual(name = "AA", values = c("fcst1" = "black", "fcst2" = "red"))

    print(p)

}



plotCumPPL2Dif<- function(DATE, y,x1,x2)
#usage: plotCumPPL2Dif(regdata$DATE,regdata$ooF1D, fcst1,fcst2)
#       cum dif between ppl2 and ppl1
{

   pnl= y * x2 - y * x1

   df= as.data.frame(cbind(DATE,pnl))
   names(df)=c("DATE","pnl")

   # step 2: create idx for x
   # data table util is very fast
   dt <- data.table(df)
   setkey(dt,DATE) # this will sort by DATE invisibly
   dfPort<-dt[,list(ppl=sum(pnl),count=.N),by=DATE]
   names(dfPort)=c("DATE","ppl","count")

   #plot(cumsum(dfPort$ppl))

   dfPort$cumppl=cumsum(dfPort$ppl);
   #use Date
   dfPort$Date <- as.Date(strptime(dfPort$DATE, "%Y%m%d"))

   #base plot
   #plot(cumppl ~ Date,dfPort, xaxt = "n", type = "l") 
   #title("cumpnl plot")
   #axis(1, dfPort$Date, format(dfPort$Date, "%Y%m%d"), cex.axis = 1) 
 
   mean=mean(dfPort$ppl)
   sd=sd(dfPort$ppl)
   shp=mean/sd*sqrt(252)
   print(paste("pplDifShp= ",round(shp,digits=5), "mean= ",round(mean,digits=5)," std= ",round(sd,digits=5)))

   # turn warning back on
   #options(warn = defaultW)


   #ggplot
   #require(ggplot2)
   ggplot( data = dfPort, aes( Date, cumppl )) + geom_line()+ggtitle("cumPPLDif plot")


}




YYYY<- function(DATE)
{ 
   ## by year for this period
   MMDD=DATE%%10000
   YYYY=(DATE-MMDD) /10000
}

