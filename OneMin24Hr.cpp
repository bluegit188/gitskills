#include "OneMin24Hr.h"



// access operator
const OhlcUnit & OneMinUnit::operator [] ( const int hhmmss )
{
   int minIdx=getMinIdx(hhmmss);
   if(minIdx <0 || minIdx >= 1440)
   {
      cerr<<"MinIdx out of bounds: minIdx="<<minIdx<<endl;
      throw "minIdx out of bound";
   }
   return (*this).ohlcs[minIdx];
}



double OneMinUnit::compute_bwd_ret_A_to_B(int minIdx1, int minIdx2,double cumAdj,double FVOO)
// compute ret from minIdx1 to minIdx2, backward ret
// if minIdx2 is 30 minutes after open, minIdx1 will be set to open if it's pre-open
{
    int THRESHOLD=30; // 30 min
    int openTimeIdx=getMinIdx(openTime);
    if( minIdx2-openTimeIdx >= THRESHOLD &&  minIdx1 < openTimeIdx)
    {
       minIdx1=openTimeIdx;
    }

    if( getHHMMSSFromMinIdx(minIdx1)< openTime)
    {
        return NA_DBL;
    }

    double p1=ohlcs[minIdx1].close;
    double p2=ohlcs[minIdx2].close;
    if(p1==0 || p2==0)
    {
        return NA_DBL;
    }

    double r=( (p2-cumAdj) - (p1-cumAdj) )/FVOO;

    return r;

}



double OneMinUnit::compute_CHGSO(int minIdx, double open,double cumAdj,double FVOO)
// compute chg from open to close of minIdx
{


    double p1=open;
    double p2=ohlcs[minIdx].close;
    if(p1==0 || p2==0)
    {
        return NA_DBL;
    }
    double r=( (p2-cumAdj) - (p1-cumAdj) )/FVOO;
    return r;
}


double OneMinUnit::compute_HSO(int minIdxOpen, int minIdx, double todayOpen, double cumAdj,double FVOO)
// compute chg from open to high as of  minIdx
{

   // loop from open to current minute
   double high=-MAX_DBL;
   // e.g, for 10 min, would be from 8:31 to 8:41(inclusive), not portarar 8:31 is 8:30 open min
   // also, price set to 0 if no prices at the first minutes around open)
   for (int j=minIdxOpen-1;j<=minIdx;j++)
   {
         //int hhmmss=myHHMMSSVec[j];
         int hhmmss=getHHMMSSFromMinIdx(j);
	 OhlcUnit ou=ohlcs[j];
	 if(ou.high != 0 && ou.high >= high)  // if no price at begining, ou.low is set to 0, need to avoid
	 {
	   high=ou.high;
	 }
	 //cout<<" j="<<j<<" hhmmss="<<setw(6)<< setfill('0')<<hhmmss<<" locHigh="<<ou.high<<" highSO="<<high;
	 //cout<<endl;
   }

    //double p1=ohlcs[minIdxOpen-1].open;
    double p1=todayOpen;
    double p2=high;
    //cout<<"p1="<<p1<<" p2="<<high<<endl;
    if(p1==0 || (p2==0 || p2 == -MAX_DBL) )
    {
        return NA_DBL;
    }
    double r=( (p2-cumAdj) - (p1-cumAdj) )/FVOO;
    if(r < 0 )
    {
      r=0; // r should be >=0 by def
    }
    return r;
}


double OneMinUnit::compute_LSO(int minIdxOpen, int minIdx, double todayOpen,double cumAdj,double FVOO)
// compute chg from open to low as of  minIdx
{

   // loop from open to current minute
   double low=MAX_DBL;
   // e.g, for 10 min, would be from 8:31 to 8:41(inclusive), not portarar 8:31 is 8:30 open min
   // also, price set to 0 if no prices at the first minutes around open)
   for (int j=minIdxOpen-1;j<=minIdx;j++)
   {
         //int hhmmss=myHHMMSSVec[j];
         int hhmmss=getHHMMSSFromMinIdx(j);
	 OhlcUnit ou=ohlcs[j];
	 if(ou.low!=0 && ou.low <= low) // if no price at begining, ou.low is set to 0, need to avoid
	 {
	   low=ou.low;
	 }
	 //cout<<" j="<<j<<" hhmmss="<<setw(6)<< setfill('0')<<hhmmss<<" locLow="<<ou.low<<" lowSO="<<low;
	 //cout<<endl;
   }

    //double p1=ohlcs[minIdxOpen-1].open;
    double p1=todayOpen;
    double p2=low;
    //cout<<"p1="<<p1<<" p2="<<low<<endl;
    if(p1==0 || (p2==0 || p2==MAX_DBL))
    {
        return NA_DBL;
    }
    double r=( (p2-cumAdj) - (p1-cumAdj) )/FVOO;
    if(r > 0 )
    {
      r=0; // r should be <=0 by def
    }
    return r;

}

double OneMinUnit::compute_PL2C(int minIdx, double close,double cumAdj,double FVOO)
// compute the open of next min to close
{


    double p1=ohlcs[minIdx+1].open;
    double p2=close;

    if(p1==0 || p2==0)
    {
        return NA_DBL;
    }
    double r=( (p2-cumAdj) - (p1-cumAdj) )/FVOO;
    return r;
}


double OneMinUnit::compute_PL2NO(int minIdx, double cumAdj1, double open2,double cumAdj2,double FVOO)
// compute the open of next min to next open
{


    double p1=ohlcs[minIdx+1].open;
    double p2=open2;

    //cout<<"p1,p2="<<p1<<" "<<p2<<endl; 

    if(p1==0 || p2==0)
    {
        return NA_DBL;
    }
    double r=( (p2-cumAdj2) - (p1-cumAdj1) )/FVOO;
    return r;
}



double OneMinUnit::compute_PLCO(double close, double cumAdj1, double open2,double cumAdj2,double FVOO)
//from today close to next open
{


    double p1=close;
    double p2=open2;

    if(p1==0 || p2==0)
    {
        return NA_DBL;
    }
    double r=( (p2-cumAdj2) - (p1-cumAdj1) )/FVOO;
    return r;
}





double OneMinUnit::compute_fwd_ret_A_to_B(int minIdx1, int minIdx2,double cumAdj,double FVOO)
// compute ret from minIdx1 to minIdx2, fwd ret
// if minIdx1 is 30 minutes before close, minIdx2 will be set to close if it's post-open
{
    int THRESHOLD=30; // 30 min
    int closeTimeIdx=getMinIdx(closeTime);
    if( closeTimeIdx-minIdx1 >= THRESHOLD &&  minIdx2 > closeTimeIdx)
    {
       minIdx2=closeTimeIdx;
    }

    if( getHHMMSSFromMinIdx(minIdx2)> closeTime)
    {
        return NA_DBL;
    }

    double p1=ohlcs[minIdx1].close;
    double p2=ohlcs[minIdx2].close;
    if(p1==0 || p2==0)
    {
        return NA_DBL;
    }

    double r=( (p2-cumAdj) - (p1-cumAdj) )/FVOO;

    return r;

}


double OneMinUnit::compute_fwd_ret_A_to_B_1minOpen(int minIdx1, int minIdx2,double cumAdj,double FVOO)
// compute ret from minIdx1 to minIdx2, fwd ret
// if minIdx1 is 30 minutes before close, minIdx2 will be set to close if it's post-open
// for forward ret, I use 1-min bar open for the left end of the rets -- the purpose of this
// is so that    cross-asset prediction could be made easy in the future
{
    int THRESHOLD=30; // 30 min
    int closeTimeIdx=getMinIdx(closeTime);
    if( closeTimeIdx-minIdx1 >= THRESHOLD &&  minIdx2 > closeTimeIdx)
    {
       minIdx2=closeTimeIdx;
    }

    if( getHHMMSSFromMinIdx(minIdx2)> closeTime)
    {
        return NA_DBL;
    }

    double p1=ohlcs[minIdx1+1].open; // left end is open of next min
    double p2=ohlcs[minIdx2].close;
    if(p1==0 || p2==0)
    {
        return NA_DBL;
    }

    double r=( (p2-cumAdj) - (p1-cumAdj) )/FVOO;

    return r;

}



double OneMinUnit::compute_fwd_ret_A_to_B_clcao(int minIdx1, int minIdx2,double FVOO)
// compute ret from minIdx1 to minIdx2, fwd ret, CLCAO style, can get intra-gap points
// minIdx1/2 must be in the day of 00:00 to 24:00
{

    if( minIdx1<0 || minIdx2>= 1440)
    {
         return NA_DBL;
    }

    double p1=ohlcs[minIdx1].close;
    double cumAdj1=ohlcs[minIdx1].cumAdj;

    double p2=ohlcs[minIdx2].close;
    double cumAdj2=ohlcs[minIdx2].cumAdj;

    if(p1==0 || p2==0)
    {
        return NA_DBL;
    }

    double r=( (p2-cumAdj2) - (p1-cumAdj2) )/FVOO;

    //cout<<"  minIdx1/p1/cumAdj1= "<<minIdx1<<" "<<p1<<" "<<cumAdj1<<endl;
    //cout<<"  minIdx2/p2/cumAdj2= "<<minIdx2<<" "<<p2<<" "<<cumAdj2<<endl;

    return r;

}




/*
double OneMinUnit::compute_fwd_ret_A_to_B(int minIdx1, int minIdx2,double cumAdj,double FVOO)
// compute ret from minIdx1 to minIdx2, fwd ret
// if minIdx1 is 30 minutes before close, minIdx2 will be set to close if it's post-open
{
    int THRESHOLD=30; // 30 min
    int closeTimeIdx=getMinIdx(closeTime);
    if( closeTimeIdx-minIdx1 >= THRESHOLD &&  minIdx2 > closeTimeIdx)
    {
       minIdx2=closeTimeIdx;
    }

    if( getHHMMSSFromMinIdx(minIdx2)> closeTime)
    {
        return NA_DBL;
    }

    double p1=ohlcs[minIdx1].close;
    double p2=ohlcs[minIdx2].close;
    if(p1==0 || p2==0)
    {
        return NA_DBL;
    }

    double r=( (p2-cumAdj) - (p1-cumAdj) )/FVOO;

    return r;

}
*/

double OneMinUnit::compute_fwd_ret_A_to_B_1minOO(int minIdx1, int minIdx2,double cumAdj,double FVOO)
// compute ret from minIdx1 to minIdx2, fwd ret
// open of one min to open of next 1 min
{
    int THRESHOLD=30; // 30 min
    int closeTimeIdx=getMinIdx(closeTime);
    if( closeTimeIdx-minIdx1 >= THRESHOLD &&  minIdx2 > closeTimeIdx)
    {
       minIdx2=closeTimeIdx;
    }

    if( getHHMMSSFromMinIdx(minIdx2)> closeTime)
    {
        return NA_DBL;
    }

    double p1=ohlcs[minIdx1].open; // left end is open of next min
    double p2=ohlcs[minIdx2].open;
    if(p1==0 || p2==0)
    {
        return NA_DBL;
    }

    double r=( (p2-cumAdj) - (p1-cumAdj) )/FVOO;

    return r;

}






OneMin24Hr::OneMin24Hr()
{
    mySize=0;
}


OneMin24Hr::OneMin24Hr(const string filename)
{
  // fill in HHMMSS for hhmmssVec
  for(int i=0;i<60*24;i++)
  {
     int hhmmss=getHHMMSSFromMinIdx(i);
     myHHMMSSVec.push_back(hhmmss);
     //cout<<"hhmmss: "<< setw(6)<< setfill('0')<<hhmmss<<endl;
  }

  read(filename);
}

/*
//old read functon: sunday is discarded

bool OneMin24Hr::read(const string filename)
{
    ifstream input;
    input.open(filename.c_str());
    if(input.fail())
    {
        cerr << "Can't open the file: " << filename << endl;
        exit(-1);
    }

    int date,time,tradeCount,volume,oi;
    double open,high,low,close,adj,cumAdj;
    string sym,contractYM;

    int lastDate=-1;
    int numValidRows=0; // number of valid minutes
    vector<OhlcUnit> ohlcVec(1440); // 1 day has 1440=60*24 minutes
    while(input>>date>>time>>open>>high>>low>>close>>tradeCount>>volume>>oi>>sym>>contractYM>>adj>>cumAdj)
    {
        //cout<<date<<" "<<time<<" "<<sym<<" "<<close<<endl;
        // note portara time is at the end of minute, e.g, 8:31 row means
        // from the minute from 8:30:00 to 8:31:00
        int curHHMMSS=time*100+0; // convert to HHMMSS 
	int minIdx=getMinIdx(curHHMMSS);
	//cout<<date<<" "<<time<<" "<<sym<<" "<<close<<" minIdx="<<minIdx<<endl;
        if(date != lastDate ) ////////////// it's a new date
	{
	    if(lastDate != -1) // last date done, add to storage
	    {
	        OneMinUnit omu;
		omu.sym=sym;
		omu.date=lastDate;

		vector<OhlcUnit> newOhlcVec;
		fillOhlcVec(ohlcVec,newOhlcVec); // for missing minutes, fill last prices 
		omu.ohlcs=newOhlcVec;
		//cout<<omu.date<<" validMins="<<numValidRows<<endl;
		omu.numValidRows=numValidRows;
		if(numValidRows > 10)
		{
		  myStorage.push_back(omu);
		}
	    }
	    // above finish up last one

	    // start a new date
	    ohlcVec.clear();
	    ohlcVec.resize(1440);
	    numValidRows=0;

	    //record this line
            OhlcUnit ou(open,high,low,close,cumAdj);
	    ohlcVec[minIdx]=ou;
	    numValidRows++;
	  
	}
	else                  /////////////////// still in the same date
        {
	    //record this line
	    OhlcUnit ou(open,high,low,close,cumAdj);
	    ohlcVec[minIdx]=ou;
	    numValidRows++;

	}


	lastDate=date;

    }//end while loop

    input.close();

    // add last omu to storage
    OneMinUnit omu;
    omu.sym=sym;
    omu.date=lastDate;

    //////////////////////////////////////////////
    /////// for missing minutes, fill in last prices
    vector<OhlcUnit> newOhlcVec;
    fillOhlcVec(ohlcVec,newOhlcVec); // for missing minutes, fill last prices 
    omu.ohlcs=newOhlcVec;
    omu.numValidRows=numValidRows;
    //cout<<omu.date<<" validMins="<<numValidRows<<endl;
    if(numValidRows > 10)
    {
       myStorage.push_back(omu);
    }

    mySize=myStorage.size();
    mySym=sym;

    /////////////////////////
    //// assign open/close times for each day
    assignOpenCloseTimes();

    ///////////////////////////////////////
    ///////////////////////////////////////
    // intersect with DailyRTH, add daily FVOO
    //string dailyRTHFile="/home/jgeng/RawData/portara/JunfCC/CCFixRTH/"+sym+".txt";
    DailyRTH drth(sym);
    //drth.print();
    //for(int i=0;i<drth.size();i++)
    //{
    //  cout<<"check="<<drth[i].date<<" "<<drth[i].FVOO<<endl;
    //}
    intersectDailyRTH(drth);

    return true;

}
*/




//new read functon: sunday is added into Friday or previous day
 /*
20220916 1656 84.96 84.98 84.96 84.96 24 231143 243343 CL 2022X 0 60.85
20220916 1657 84.95 84.96 84.93 84.95 9 231143 243343 CL 2022X 0 60.85
20220916 1658 84.96 85.03 84.94 85.03 39 231143 243343 CL 2022X 0 60.85
20220916 1659 85.02 85.02 84.98 85.02 34 231143 243343 CL 2022X 0 60.85
20220916 1700 85.01 85.03 84.98 85.03 50 231143 243343 CL 2022X 0 60.85
20220918 1801 84.81 84.99 84.8 84.97 134 231143 243343 CL 2022X 0 60.85
20220918 1802 84.95 85.07 84.91 85.06 78 231143 243343 CL 2022X 0 60.85
20220918 1803 85.09 85.22 85.07 85.12 139 231143 243343 CL 2022X 0 60.85
20220918 1804 85.12 85.15 85.05 85.15 18 231143 243343 CL 2022X 0 60.85
20220918 1805 85.15 85.23 85.13 85.16 94 231143 243343 CL 2022X 0 60.85
20220918 1806 85.16 85.21 85.14 85.19 64 231143 243343 CL 2022X 0 60.85
 */

bool OneMin24Hr::read(const string filename)
{
    ifstream input;
    input.open(filename.c_str());
    if(input.fail())
    {
        cerr << "Can't open the file: " << filename << endl;
        exit(-1);
    }

    int date,time,tradeCount,volume,oi;
    double open,high,low,close,adj,cumAdj;
    string sym,contractYM;

    int lastDate=-1;
    int lastTime=-1;
    int numValidRows=0; // number of valid minutes
    vector<OhlcUnit> ohlcVec(1440); // 1 day has 1440=60*24 minutes
    int dateRaw;
    while(input>>date>>time>>open>>high>>low>>close>>tradeCount>>volume>>oi>>sym>>contractYM>>adj>>cumAdj)
    {

        dateRaw=date;
        //cout<<date<<" "<<time<<" "<<sym<<" "<<close<<endl;
        // note portara time is at the end of minute, e.g, 8:31 row means
        // from the minute from 8:30:00 to 8:31:00
        int curHHMMSS=time*100+0; // convert to HHMMSS 
	int minIdx=getMinIdx(curHHMMSS);
	//cout<<date<<" "<<time<<" "<<sym<<" "<<close<<" minIdx="<<minIdx<<endl;
        if(date != lastDate && time < lastTime ) ////////////// it's a new date, also not days like Sunday
	{

	    if(lastDate != -1) // last date done, add to storage
	    {
	        OneMinUnit omu;
		omu.sym=sym;
		omu.date=lastDate;

		vector<OhlcUnit> newOhlcVec;
		fillOhlcVec(ohlcVec,newOhlcVec); // for missing minutes, fill last prices 
		omu.ohlcs=newOhlcVec;
		//cout<<omu.date<<" validMins="<<numValidRows<<endl;
		omu.numValidRows=numValidRows;
		if(numValidRows > 10)
		{
		  myStorage.push_back(omu);
		}
	    }
	    // above finish up last one

	    // start a new date
	    ohlcVec.clear();
	    ohlcVec.resize(1440);
	    numValidRows=0;

	    //record this line
	    OhlcUnit ou(open,high,low,close,cumAdj,dateRaw);
	    ohlcVec[minIdx]=ou;
	    numValidRows++;
	  
	}
	else                  /////////////////// still in the same date
        {

	    date=lastDate;  // this line to handle Sunday, need to,e.g, reset sunday to Friday

	    //record this line
	    OhlcUnit ou(open,high,low,close,cumAdj,dateRaw);
	    ohlcVec[minIdx]=ou;
	    numValidRows++;

	}


	lastDate=date;
	lastTime=time;

    }//end while loop

    input.close();

    // add last omu to storage
    OneMinUnit omu;
    omu.sym=sym;
    omu.date=lastDate;

    //////////////////////////////////////////////
    /////// for missing minutes, fill in last prices
    vector<OhlcUnit> newOhlcVec;
    fillOhlcVec(ohlcVec,newOhlcVec); // for missing minutes, fill last prices 
    omu.ohlcs=newOhlcVec;
    omu.numValidRows=numValidRows;
    //cout<<omu.date<<" validMins="<<numValidRows<<endl;
    if(numValidRows > 10)
    {
       myStorage.push_back(omu);
    }

    mySize=myStorage.size();
    mySym=sym;

    /////////////////////////
    //// assign open/close times for each day
    assignOpenCloseTimes();

    ///////////////////////////////////////
    ///////////////////////////////////////
    // intersect with DailyRTH, add daily FVOO
    //string dailyRTHFile="/home/jgeng/RawData/portara/JunfCC/CCFixRTH/"+sym+".txt";
    DailyRTH drth(sym);
    //drth.print();
    //for(int i=0;i<drth.size();i++)
    //{
    //  cout<<"check="<<drth[i].date<<" "<<drth[i].FVOO<<endl;
    //}
    intersectDailyRTH(drth);

    return true;

}



void OneMin24Hr::fillOhlcVec(vector<OhlcUnit>& ohlcVec, vector<OhlcUnit>& newOhlcVec)
// for missing minutes, fill in with last close
{

   double NA=std::numeric_limits<double>::max();
   double lastClose=-1;
   double lastCumAdj=NA;
   int lastDateRaw=-1;
   for(unsigned int i=0;i<ohlcVec.size();i++)
   {
       OhlcUnit ou=ohlcVec[i];
       if(ou.open==0 && lastClose != -1)
       {
	   ou.open=lastClose;
	   ou.high=lastClose;
	   ou.low=lastClose;
	   ou.close=lastClose;
	   ou.cumAdj=lastCumAdj;
	   ou.dateRaw=lastDateRaw;
       }

       OhlcUnit newOu=ou;
       newOhlcVec.push_back(newOu);

       lastClose=ou.close;
       lastCumAdj=ou.cumAdj;
       lastDateRaw=ou.dateRaw;
   }


}
    

void OneMin24Hr::assignOpenCloseTimes()
{
     //////////////////////
    // step 1, reads in open/close times
    //string filename="/home/jgeng/projects/OneMin/code/TmpSessionTime/final_sessionTimes.txt";
    //string filename="/home/jgeng/transfer/final_sessionTimes.txt";
    string filename="/home/jgeng/transfer/final_sessionTimes.txt.20240117";
    ifstream input;
    input.open(filename.c_str());
    if(input.fail())
    {
        cerr << "Can't open the file: " << filename << endl;
	exit(-1);
    }

    vector<SessionTimeUnit> sessionTimeVec;
    int date,openTime,closeTime;
    string sym;
    while(input>>sym>>date>>openTime>>closeTime)
    {
        if(sym != mySym)
        {
	    continue;
	}
	SessionTimeUnit stu;
	stu.date=date;
	stu.openTime=openTime;
	stu.closeTime=closeTime;

	sessionTimeVec.push_back(stu);
    }
   

    ///////////////////////
    ///  step 2: for each day in myStorage, assign open/close times
    for(unsigned int i=0;i<myStorage.size();i++)
    {
       OneMinUnit omu=myStorage[i];

       int loc=findLocForSession(sessionTimeVec, omu.date);
       //cout<<omu.sym<<" "<<omu.date<<endl;      
       //cout<<sessionTimeVec[loc].date<<" "<<sessionTimeVec[loc].openTime<<" "<<sessionTimeVec[loc].closeTime<<endl;

       myStorage[i].openTime=sessionTimeVec[loc].openTime*100; // change to hhmmss
       myStorage[i].closeTime=sessionTimeVec[loc].closeTime*100;

    }

}

int OneMin24Hr::findLocForSession(vector<SessionTimeUnit>& stuVec,int date)
//find last session loc where date > sessonDate
// -1 if not found
{
    if(stuVec.size()==0)
    {
      return -1; // empty session time vec
    }
    if(date < stuVec[0].date)
    {
      return -1;  // date is earlier than first session date
    }

    for(int i= stuVec.size()-1;i>=0;i--)
    {
      if(date >= stuVec[i].date)
      {
	return i;
      }
    }

    return -1; // shouldn't reach here
}



void OneMin24Hr::intersectDailyRTH(DailyRTH & df)
//Given 1-min and dailyRTH, intersect and keep only unions
//Assign cumAdj from daily to 1min data
//!!! Note: this step will remove all  Sunday evening prices in the 1-min data !!!
//          If you want to keep that, don't remove (loc=-1&& isSunday) days.
{

    vector<OneMinUnit> tmpStorage;

    /// for each day in myStorage, assign FVOO
    for(unsigned int i=0;i<myStorage.size();i++)
    {
       OneMinUnit omu=myStorage[i];

       //cout<<"test="<<df[1].FVOO<<endl;
       
       int loc=df.findLocOfDate(omu.date);
       //cout<<omu.sym<<" "<<omu.date<<" loc="<<loc<<" "<<df[loc].date<<endl;  
       
       if(loc == -1)  // no match in dailyRTH, skip
       {
	 continue;
       }

       myStorage[i].FVOO=df[loc].FVOO;
       myStorage[i].cumAdj=df[loc].cumSpd;
       myStorage[i].open=df[loc].open;
       myStorage[i].close=df[loc].close;
       myStorage[i].high=df[loc].high;
       myStorage[i].low=df[loc].low;
          
       OneMinUnit newOmu= myStorage[i];
       tmpStorage.push_back(newOmu);
    }

    // assign back
    myStorage=tmpStorage;
    mySize=myStorage.size();

}

OneMin24Hr::~OneMin24Hr()
{
   // to do
}

void OneMin24Hr::print()
{
   for(unsigned int i=0;i<myStorage.size();i++)
   {
       OneMinUnit omu=myStorage[i];
       cout<<omu.sym<<" "<<omu.date<<" oT/cT="<<omu.openTime<<" "<<omu.closeTime<<" cumAdj="<<omu.cumAdj<<" FVOO="<<omu.FVOO<<endl;
       // for all 1440 minutes
       for (int j=0;j<1440;j++)
       {
	 int hhmmss=myHHMMSSVec[j];
	 OhlcUnit ou=omu.ohlcs[j];
	 cout<<"   "<<omu.date<<" "<<setw(6)<< setfill('0')<<hhmmss;
	 cout<<" "<<ou.dateRaw<<" "<<ou.open<<" "<<ou.high<<" "<<ou.low<<" "<<ou.close<<" "<<ou.cumAdj<<endl;
       }
   }
}


// access operator
const OneMinUnit & OneMin24Hr::operator [] ( const int loc )
{

  return (*this).myStorage[loc];

}




double OneMin24Hr::getGAP(int loc)
{
    if(loc<= 0)
    {
      return NA_DBL;
    }
    OneMinUnit du0=myStorage[loc]; 
    OneMinUnit du1=myStorage[loc-1];
    double FVOO=myStorage[loc].FVOO;
    double GAP=(du0.open-du0.cumAdj)-(du1.close-du1.cumAdj);

    GAP/=FVOO;    
    return constrain(GAP,-3,3);
}


double OneMin24Hr::getO(int loc)
//normalized O/H/L/Cs
{
    if(loc<= 1)
    {
      return NA_DBL;
    }
    OneMinUnit du0=myStorage[loc]; 
    OneMinUnit du1=myStorage[loc-1];
    OneMinUnit du2=myStorage[loc-2];

    double FVOO=du0.FVOO;
    double O=(du1.open-du1.cumAdj)-(du2.close-du2.cumAdj);
    O/=FVOO;    
    return constrain(O,-2,2);
}


double OneMin24Hr::getH(int loc)
{
    if(loc<= 1)
    {
      return NA_DBL;
    }
    OneMinUnit du0=myStorage[loc]; 
    OneMinUnit du1=myStorage[loc-1];
    OneMinUnit du2=myStorage[loc-2];

    double FVOO=du0.FVOO;
    double H=(du1.high-du1.cumAdj)-(du2.close-du2.cumAdj);
    H/=FVOO;    
    return constrain(H,-1.5,3.5);
}


double OneMin24Hr::getL(int loc)
{
    if(loc<= 1)
    {
      return NA_DBL;
    }
    OneMinUnit du0=myStorage[loc]; 
    OneMinUnit du1=myStorage[loc-1];
    OneMinUnit du2=myStorage[loc-2];

    double FVOO=du0.FVOO;
    double L=(du1.low-du1.cumAdj)-(du2.close-du2.cumAdj);
    L/=FVOO;    
    return constrain(L,-3.5,1.5); 
}


double OneMin24Hr::getC(int loc)
{
    if(loc<= 1)
    {
      return NA_DBL;
    }
    OneMinUnit du0=myStorage[loc]; 
    OneMinUnit du1=myStorage[loc-1];
    OneMinUnit du2=myStorage[loc-2];

    double FVOO=du0.FVOO;
    double C=(du1.close-du1.cumAdj)-(du2.close-du2.cumAdj);
    C/=FVOO;    
    return constrain(C,-3,3);
}


double OneMin24Hr::getOOP1D(int loc)
{
    if(loc< 1)
    {
      return NA_DBL;
    }
    OneMinUnit du0=myStorage[loc]; 
    OneMinUnit du1=myStorage[loc-1];

    double FVOO=du0.FVOO;
    double OOP1D=(du0.open-du0.cumAdj)-(du1.open-du1.cumAdj);
    OOP1D/=FVOO;    
    return constrain(OOP1D,-3.0,3.0);
}

double OneMin24Hr::getCC1(int loc)
//for CL CC1 type of indicator
{
    if(loc< 1)
    {
      return NA_DBL;
    }
    OneMinUnit du0=myStorage[loc]; 
    OneMinUnit du1=myStorage[loc-1];

    double FVOO=du0.FVOO;
    double CC1=(du0.close-du0.cumAdj)-(du1.close-du1.cumAdj);
    CC1/=FVOO;    
    return constrain(CC1,-3.0,3.0);
}


double OneMin24Hr::getTLC(int loc) //today HC and LC
{
    if(loc< 0)
    {
      return NA_DBL;
    }
    OneMinUnit du0=myStorage[loc]; 
    //OneMinUnit du1=myStorage[loc-1];
    //OneMinUnit du2=myStorage[loc-2];

    double FVOO=du0.FVOO;
    double TLC=(du0.close-du0.cumAdj)-(du0.low-du0.cumAdj);
    TLC/=FVOO;    
    return constrain(TLC,0,2.9); 
}


double OneMin24Hr::getTHC(int loc)
{
    if(loc< 0)
    {
      return NA_DBL;
    }
    OneMinUnit du0=myStorage[loc]; 
    //OneMinUnit du1=myStorage[loc-1];
    //OneMinUnit du2=myStorage[loc-2];

    double FVOO=du0.FVOO;
    double THC=(du0.close-du0.cumAdj)-(du0.high-du0.cumAdj);
    THC/=FVOO;    
    return constrain(THC,-2.9,0); 
}

double OneMin24Hr::getTOC(int loc) //today OC
{
    if(loc< 0)
    {
      return NA_DBL;
    }
    OneMinUnit du0=myStorage[loc]; 
    //OneMinUnit du1=myStorage[loc-1];
    //OneMinUnit du2=myStorage[loc-2];

    double FVOO=du0.FVOO;
    double TOC=(du0.close-du0.cumAdj)-(du0.open-du0.cumAdj);
    TOC/=FVOO;    
    return constrain(TOC,-3,3); 
}


double OneMin24Hr::getYLC(int loc)
{
    if(loc< 1)
    {
      return NA_DBL;
    }
    OneMinUnit du0=myStorage[loc]; 
    OneMinUnit du1=myStorage[loc-1];
    //OneMinUnit du2=myStorage[loc-2];

    double FVOO=du0.FVOO;
    double YLC=(du1.close-du1.cumAdj)-(du1.low-du1.cumAdj);
    YLC/=FVOO;    
    return constrain(YLC,0,2.9); 
}


double OneMin24Hr::getYHC(int loc)
{
    if(loc< 1)
    {
      return NA_DBL;
    }
    OneMinUnit du0=myStorage[loc]; 
    OneMinUnit du1=myStorage[loc-1];
    //OneMinUnit du2=myStorage[loc-2];

    double FVOO=du0.FVOO;
    double YHC=(du1.close-du1.cumAdj)-(du1.high-du1.cumAdj);
    YHC/=FVOO;    
    return constrain(YHC,-2.9,0); 
}

double OneMin24Hr::getYMC(int loc)
{
    if(loc< 1)
    {
      return NA_DBL;
    }
    OneMinUnit du0=myStorage[loc]; 
    OneMinUnit du1=myStorage[loc-1];
    //OneMinUnit du2=myStorage[loc-2];

    double FVOO=du0.FVOO;
    double YMC=(du1.close-du1.cumAdj)-((du1.high-du1.cumAdj)+(du1.low-du1.cumAdj))/2;
    YMC/=FVOO;    
    return constrain(YMC,-1.3,1.3); 
}



double OneMin24Hr::getYOC(int loc)
{
    if(loc< 1)
    {
      return NA_DBL;
    }
    OneMinUnit du0=myStorage[loc]; 
    OneMinUnit du1=myStorage[loc-1];
    //OneMinUnit du2=myStorage[loc-2];

    double FVOO=du0.FVOO;
    double YOC=(du1.close-du1.cumAdj)-(du1.open-du1.cumAdj);
    YOC/=FVOO;    
    return constrain(YOC,-3,3); 
}

double OneMin24Hr::getYHL(int loc)
{
    if(loc< 1)
    {
      return NA_DBL;
    }
    OneMinUnit du0=myStorage[loc]; 
    OneMinUnit du1=myStorage[loc-1];
    //OneMinUnit du2=myStorage[loc-2];

    double FVOO=du0.FVOO;
    double YHL=(du1.high-du1.cumAdj)-(du1.low-du1.cumAdj);
    YHL/=FVOO;    
    return constrain(YHL,-4,4); 
}
