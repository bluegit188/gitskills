#include "DailyRTH.h"


ostream & operator<< (ostream & out, const DailyRTHUnit & s)
{
    s.print(out);
    return out;
}


DailyRTH::DailyRTH()
{
    mySize=0;
}


DailyRTH::DailyRTH(const string sym)
{
  read(sym);
}


DailyRTH::~DailyRTH()
{
   // to do
}


bool DailyRTH::read(const string symbol)
{
    ifstream input;
    string filename="/home/jgeng/RawData/portara/JunfCC/CCFixRTH/"+symbol+".txt";

    input.open(filename.c_str());
    if(input.fail())
    {
        cerr << "Can't open the file: " << filename << endl;
        exit(-1);
    }

    int date,tradeCount,volume,oi;
    double open,high,low,close,spd,cumSpd;
    string sym,contractYM;

    while(input>>date>>open>>high>>low>>close>>tradeCount>>volume>>oi>>sym>>contractYM>>spd>>cumSpd)
    {
         
        DailyRTHUnit du;
	du.sym=sym;
	du.date=date;
	du.open=open;
	du.high=high;
	du.low=low;
	du.close=close;
	du.contractYM=contractYM;
	du.cumSpd=cumSpd;

	myStorage.push_back(du);
	
    }//end while loop

    input.close();

    computeFVOO();
    mySize=myStorage.size();

    return true;

}


void DailyRTH::print()
{
   for(unsigned int i=0;i<myStorage.size();i++)
   {
       DailyRTHUnit du=myStorage[i];
       cout<<du.sym<<" "<<du.date<<" "<<du.open<<" "<<du.high<<" "<<du.low<<" "<<du.close<<" "<<du.cumSpd<<" FVOO="<<du.FVOO<<endl;
       
   }

}


void DailyRTH::computeFVOO()
// see this perl code: /home/jgeng/bin/portara_get_FVOO.pl
{

    //1). regular std
    vector<double> OOs;
    //regular std
    //0=today, 1=yest
    for (unsigned int i=1;i<myStorage.size();i++)
    {
        DailyRTHUnit du0=myStorage[i];
        DailyRTHUnit du1=myStorage[i-1];

        // ajust cumSpd
        double open0=du0.open-du0.cumSpd;
        double open1=du1.open-du1.cumSpd;
	double OO=open0 - open1;
	OOs.push_back(OO);
    }
    double std=getStd(OOs);
    //cout<<"std="<<std<<endl;

    //2). compute FVOO
    //0=today, 1=yest,
    double a=0.975;
    double ema0=std;
    double ema=ema0;

    vector<DailyRTHUnit> tmpStorage;

    for (unsigned int i=1;i<myStorage.size();i++)
    {

        DailyRTHUnit du0=myStorage[i];
        DailyRTHUnit du1=myStorage[i-1];

	//double OO=(du0.open-du0.cumSpd)-(du1.open-du1.cumSpd);
	// HILO=yest high - yest low
        double HILO=(du1.high-du1.low);

	//   GAP=open today - close yest
	double GAP=(du0.open-du0.cumSpd)-(du1.close-du1.cumSpd);
	double AGAP=abs(GAP);
        //#HILOADJ=0.453*(HILO+1.17*AGAP)
	//# 1.29 is to adjust FV such that sd(ooP1D)=1
        double HILOADJ=(0.45*HILO+0.55*AGAP)*(1.29);

	ema=a*ema+(1-a)*HILOADJ;

        double FVOO=ema;
	myStorage[i].FVOO=FVOO;

	DailyRTHUnit duNew=myStorage[i];
	tmpStorage.push_back(duNew);
    }

    myStorage=tmpStorage;
    mySize=myStorage.size();


}

double DailyRTH::getStd(vector<double>&Xs)
//compute std in onepass
{

   int count=Xs.size();
   if(count<1){return 0;}

   //#print "count=$count\n";
   double xsum=0;
   double x2sum=0;
   for(int i=0;i<count;i++)
   {
     double x=Xs[i];
     xsum+=x;
     x2sum+=(x*x);
   }
   double var=0; // count=1
   if(count >1)
   {
     var=(x2sum-xsum*xsum/count)/(count-1);
   }
   return sqrt(var);
}


// access operator
const DailyRTHUnit & DailyRTH::operator [] ( const int loc )
{

  return (*this).myStorage[loc];

}



int DailyRTH::findLocOfDate(int date)
// Given date, find location in dailyRTH
{

    if(mySize==0)
    {
      return -1; // empty  vec
    }
    if(date < myStorage[0].date ||date > myStorage[mySize-1].date  )
    {
      return -1;  // date is earlier than first session date
    }

    int loc=-1;
    for(int i=0;i< mySize;i++)
    {
      if(date == myStorage[i].date)
      {
	loc=i;
      }
    }

    return loc;

}



bool DailyRTH::insertAtLast(DailyRTHUnit du)
// insert at the end of the data, if date exists, replace it
{

    int lastDate=myStorage[mySize-1].date;
    int todayDate=du.date; 
    if(todayDate < lastDate)
    {
        cerr<<"Input date is earlier than last data date: "<<todayDate<<" < "<<lastDate<<endl;
        exit(1);
    }

    if(todayDate == lastDate)
    {
       myStorage[mySize-1]=du;
    }

    if(todayDate > lastDate)
    {
        //check date not too stale
        if(dateDif(lastDate, todayDate) >10 )
        {
	  cout<<"Warning: last valid data date is 10 days old, check"<<endl;
	}
	myStorage.push_back(du);
    }
    

    // after insert or replacement, recompute FVOO
    computeFVOO();
    mySize=myStorage.size();

    return true; 

}


bool DailyRTH::insert(DailyRTHUnit du)
// insert anywhere, replace if the date exists
{
    if(myStorage.size()< 40)
    {
       cerr<<"Don't insert if data history is < 40 days, FVOO not accurate"<<endl;
       return false; 
    }

    int firstDate=myStorage[0].date;
    int lastDate=myStorage[mySize-1].date;
    int todayDate=du.date; 
    if(todayDate < firstDate)
    {
       myStorage.insert(myStorage.begin(),du);
       computeFVOO();
       mySize=myStorage.size();
       return true; 
    }

    if(todayDate > lastDate)
    {
        //check date not too stale
        if(dateDif(lastDate, todayDate) >10 )
        {
	  cout<<"Warning: last valid data date is 10 days old, check"<<endl;
	}
        myStorage.insert(myStorage.end(),du);
        computeFVOO();
        mySize=myStorage.size();
        return true; 
    }


    int loc=-1;
    for(int i=0;i< mySize;i++)
    {
      if(todayDate == myStorage[i].date)
      {
	loc=i;
      }
    }

    if(loc != -1)
    {
       myStorage[loc]=du;
       computeFVOO();
       //mySize=myStorage.size();
       return true;
    }

    vector<DailyRTHUnit> newStorage;
    for(int i=0;i< mySize;i++)
    {	
      newStorage.push_back(myStorage[i]);
      if(todayDate > myStorage[i].date && todayDate < myStorage[i+1].date)
      {
	newStorage.push_back(du);
      }
    }
    myStorage=newStorage;
    computeFVOO();
    mySize=myStorage.size();
    return true;


}




double DailyRTH::getGAP(int loc)
{
    if(loc<= 0)
    {
      return NA_DBL;
    }
    DailyRTHUnit du0=myStorage[loc]; 
    DailyRTHUnit du1=myStorage[loc-1];
    double FVOO=myStorage[loc].FVOO;
    double GAP=(du0.open-du0.cumSpd)-(du1.close-du1.cumSpd);

    GAP/=FVOO;    
    return constrain(GAP,-2,2);
}


double DailyRTH::getO(int loc)
//normalized O/H/L/Cs
{
    if(loc<= 1)
    {
      return NA_DBL;
    }
    DailyRTHUnit du0=myStorage[loc]; 
    DailyRTHUnit du1=myStorage[loc-1];
    DailyRTHUnit du2=myStorage[loc-2];

    double FVOO=du0.FVOO;
    double O=(du1.open-du1.cumSpd)-(du2.close-du2.cumSpd);
    O/=FVOO;    
    return constrain(O,-2,2);
}


double DailyRTH::getH(int loc)
{
    if(loc<= 1)
    {
      return NA_DBL;
    }
    DailyRTHUnit du0=myStorage[loc]; 
    DailyRTHUnit du1=myStorage[loc-1];
    DailyRTHUnit du2=myStorage[loc-2];

    double FVOO=du0.FVOO;
    double H=(du1.high-du1.cumSpd)-(du2.close-du2.cumSpd);
    H/=FVOO;    
    return constrain(H,-1.5,3.5);
}


double DailyRTH::getL(int loc)
{
    if(loc<= 1)
    {
      return NA_DBL;
    }
    DailyRTHUnit du0=myStorage[loc]; 
    DailyRTHUnit du1=myStorage[loc-1];
    DailyRTHUnit du2=myStorage[loc-2];

    double FVOO=du0.FVOO;
    double L=(du1.low-du1.cumSpd)-(du2.close-du2.cumSpd);
    L/=FVOO;    
    return constrain(L,-3.5,1.5); 
}


double DailyRTH::getC(int loc)
{
    if(loc<= 1)
    {
      return NA_DBL;
    }
    DailyRTHUnit du0=myStorage[loc]; 
    DailyRTHUnit du1=myStorage[loc-1];
    DailyRTHUnit du2=myStorage[loc-2];

    double FVOO=du0.FVOO;
    double C=(du1.close-du1.cumSpd)-(du2.close-du2.cumSpd);
    C/=FVOO;    
    return constrain(C,-3,3);
}


double DailyRTH::getOOP1D(int loc)
{
    if(loc< 1)
    {
      return NA_DBL;
    }
    DailyRTHUnit du0=myStorage[loc]; 
    DailyRTHUnit du1=myStorage[loc-1];

    double FVOO=du0.FVOO;
    double OOP1D=(du0.open-du0.cumSpd)-(du1.open-du1.cumSpd);
    OOP1D/=FVOO;    
    return constrain(OOP1D,-3.0,3.0);
}



double DailyRTH::getYLC(int loc)
{
    if(loc< 1)
    {
      return NA_DBL;
    }
    DailyRTHUnit du0=myStorage[loc]; 
    DailyRTHUnit du1=myStorage[loc-1];
    //DailyRTHUnit du2=myStorage[loc-2];

    double FVOO=du0.FVOO;
    double YLC=(du1.close-du1.cumSpd)-(du1.low-du1.cumSpd);
    YLC/=FVOO;    
    return constrain(YLC,0,2.9); 
}


double DailyRTH::getYHC(int loc)
{
    if(loc< 1)
    {
      return NA_DBL;
    }
    DailyRTHUnit du0=myStorage[loc]; 
    DailyRTHUnit du1=myStorage[loc-1];
    //DailyRTHUnit du2=myStorage[loc-2];

    double FVOO=du0.FVOO;
    double YHC=(du1.close-du1.cumSpd)-(du1.high-du1.cumSpd);
    YHC/=FVOO;    
    return constrain(YHC,-2.9,0); 
}

double DailyRTH::getYMC(int loc)
{
    if(loc< 1)
    {
      return NA_DBL;
    }
    DailyRTHUnit du0=myStorage[loc]; 
    DailyRTHUnit du1=myStorage[loc-1];
    //DailyRTHUnit du2=myStorage[loc-2];

    double FVOO=du0.FVOO;
    double YMC=(du1.close-du1.cumSpd)-((du1.high-du1.cumSpd)+(du1.low-du1.cumSpd))/2;
    YMC/=FVOO;    
    return constrain(YMC,-1.3,1.3); 
}
