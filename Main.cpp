#include <stdlib.h>
#include <string>
//#include "globals.h"
#include <vector>
  
#include "/home/jgeng/junfei_lib/Base/DailyRTH.h"
#include "/home/jgeng/junfei_lib/Base/OneMin24Hr.h"
#include "/home/jgeng/junfei_lib/Base/Tokenizer.h"
//#include "/home/jgeng/junfei_lib/Base/TimeZones.h"



bool isRoundMinute(int hhmmss,int interval)
//e.g, hhmmss=8:20, interval=10, return yes
//     hhmmss=8:23. interval=10, return no
{
   int minIdx=getMinIdx(hhmmss);
   if( minIdx%interval==0)
   {
     return true;
   }
   return false;
}


int isOpenMinute(int hhmmss,int hhmmssOpen)
//e.g, hhmmssOpen=83000
//     hhmmss=83100, return yes ( 8:31 in portara is for 8:30:00 to 8:31:00; no else
{
   int minIdxOpen=getMinIdx(hhmmssOpen);
   int minIdx=getMinIdx(hhmmss);
   if( minIdx-minIdxOpen ==1)
   {
     return 1;
   }
   return 0;
}

int isCloseMinute(int hhmmss,int hhmmssClose)
//e.g, hhmmssClose=151500
//     hhmmss=151500, return yes ( 15:15 in portara is for 15:14:00 to 8:15:00; no else
{
   int minIdxClose=getMinIdx(hhmmssClose);
   int minIdx=getMinIdx(hhmmss);
   if( minIdx-minIdxClose ==0)
   {
     return 1;
   }
   return 0;
}



//double NA_DBL=std::numeric_limits<double>::max();

int main(int argc, char * argv[])
{

  
    //check if it's the right command
    if(argc != 2)
    {
        cerr <<"usage: onemin_24hr_ooF1D_ex5_2hr SYM"<<endl;
	cerr <<"       Based on portara 1min-24Hr file, compute ooF1DEx5Min rets(up to 2 hrs after open)"<<endl;
	cerr <<"       "<<endl;
	exit(-1);
    }

    string sym(argv[1]);
    int interval=1;//20 min atoi(argv[2]);

    string filename="/home/jgeng/RawData/portara/JunfCC/CCFix1MIN24HR/"+sym+".txt";
    //string filename="/home/jgeng/RawData/portara/JunfCC/CCFix1MIN24HR/"+sym+"Sht.txt";
    OneMin24Hr onemin(filename); 
    // internally, it reads dailyRTH/sessionTimes, and assigns open/close times, FVOO and cumAdj from daily
    //onemin.print();


    // hhmmss for each min of the day
    vector<int>HHMMSSVec=onemin.getHHMMSSVec();
    //lags, in minutes
    vector<int> lags{1,2,5,10,15,30,45,60,90,120};


    //TimeZones tz;
    //tz.print();

    //header
    cout<<"DATE SYM TIME ivl isOpenMin oT cT open close lastPrice cumAdj FVOO nextOpen";
    cout<<" GAP YOC ooP1D YHC YLC YMC YHL";
    cout<<" PL2C PL2NO PL2NC PLCO";
    cout<<" PL2NOEx1 PL2NOEx2 PL2NOEx5 PL2NOEx10 PL2NOEx15 PL2NOEx30 PL2NOEx45 PL2NOEx60 PL2NOEx90 PL2NOEx120";
    cout<<" F1M F2M F5M F10M F15M F30M F45M F60M F90M F120M";
    cout<<" CHGSO1M CHGSO2M CHGSO5M CHGSO10M CHGSO15M CHGSO30M CHGSO45M CHGSO60M CHGSO90M CHGSO120M";
    cout<<" HSO1M HSO2M HSO5M HSO10M HSO15M HSO30M HSO45M HSO60M HSO90M HSO120M";
    cout<<" LSO1M LSO2M LSO5M LSO10M LSO15M LSO30M LSO45M LSO60M LSO90M LSO120M";
    cout<<" THC TLC TOC";
    cout<<endl;
    // other terms
    //  cout<<" F1M F5M F10M F15M F30M F45M F60M F90M F120M F240M";


    ///////////////////////
    ////// loop each day 
    for(int i=1;i< onemin.size()-1;i++)
    {
        OneMinUnit omu=onemin[i];
        OneMinUnit omuTmrw=onemin[i+1];
        OneMinUnit omuYest=onemin[i-1];
	int oT=omu.openTime;
	int cT=omu.closeTime;
	double FVOO=omu.FVOO;
	double cumAdj=omu.cumAdj;

	//cout<<omu.date<<" "<<omu.sym<<" oT/cT="<<omu.openTime<<" "<<omu.closeTime<<" cumAdj="<<omu.cumAdj<<" FVOO="<<omu.FVOO<<endl;


        //int locOpen=getMinIdx(oT);
        //int locClose=getMinIdx(cT);
        //int distO2C=locClose-locOpen;

        //e.g, below, if open is 8:00:00, locOpen=480, minIdx=481 and the corresponding hhmmss=80100(portara convention)
	int minIdxOpen=getMinIdx(oT)+1;
	//cout<<"minIdxOpen="<<minIdxOpen<<" hhmmssOpen="<<getHHMMSSFromMinIdx(minIdxOpen)<<endl;


	// some daily xvars
	double GAP=onemin.getGAP(i);
	double YOC=onemin.getYOC(i);
	double ooP1D=onemin.getOOP1D(i);
	double YHC=onemin.getYHC(i);
	double YLC=onemin.getYLC(i);
	double YMC=onemin.getYMC(i);
	double YHL=onemin.getYHL(i);

	double todayOpen=omu.open;
	double todayClose=omu.close;
	double tmrwOpen=omuTmrw.open;
	double tmrwCumAdj=omuTmrw.cumAdj;
	double tmrwClose=omuTmrw.close;

	double THC=onemin.getTHC(i);
	double TLC=onemin.getTLC(i);
	double TOC=onemin.getTOC(i);


	int ivl=0;
	//////////////////////////
	// loop all 1440 minutes,
	for (int j=0;j<1440;j++)
        {
	    int hhmmss=HHMMSSVec[j];
	    OhlcUnit ou=omu.ohlcs[j];
	    int minIdx=getMinIdx(hhmmss);


	    int isOpenMin= isOpenMinute(hhmmss,oT);
	    //bool isRoundMin=isRoundMinute(hhmmss,interval);

	    // // skip empty minutes at the begining, minutes out of oT/cT, only sample round minutes
	    // 06/22: don't use last min, as I use next min open for Pl2C
	    if( !(isOpenMin==1)  ) 
               //|| (!isRoundMin && !(isOpenMin==1) ) )
	    {
	      continue; 
	    }

	    //cout<<"Now, minIdxOpen(2)="<<minIdx<<endl; // now minIdxOpen should be 511 or 8:31 for ES

	    //cout<<"   "<<omu.date<<" "<<setw(6)<< setfill('0')<<hhmmss;
	    //cout<<" "<<ou.open<<" "<<ou.high<<" "<<ou.low<<" "<<ou.close<<" "<<ou.cumAdj<<endl;    
	    //e.g, below, if open is 8:00:00, locOpen=480, minIdx=481 and hhmmss=80100
	    //cout<<"locOpen, minIdx, hhmmss="<<locOpen<<" "<<minIdx<<" "<<hhmmss<<endl;



	    int hhmmssPre=HHMMSSVec[j-1]; //prev minute, for displaying
	    //e.g, below, if open is 8:00:00, locOpen=480, minIdx=481 and hhmmss=80100

	    //compute PL2C/NO/CO
	    double PL2C=omu.compute_PL2C(minIdx-1,todayClose,cumAdj,FVOO);

	    double PL2NO=omu.compute_PL2NO(minIdx-1,cumAdj,tmrwOpen, tmrwCumAdj, FVOO);
	    double PL2NC=omu.compute_PL2NO(minIdx-1,cumAdj,tmrwClose, tmrwCumAdj, FVOO);
	    double PLCO=omu.compute_PLCO(todayClose,cumAdj,tmrwOpen, tmrwCumAdj, FVOO);



	    double PL2NOEx1=omu.compute_PL2NO(minIdx-1+1,cumAdj,tmrwOpen, tmrwCumAdj, FVOO);
	    double PL2NOEx2=omu.compute_PL2NO(minIdx-1+2,cumAdj,tmrwOpen, tmrwCumAdj, FVOO);
	    double PL2NOEx5=omu.compute_PL2NO(minIdx-1+5,cumAdj,tmrwOpen, tmrwCumAdj, FVOO);
	    double PL2NOEx10=omu.compute_PL2NO(minIdx-1+10,cumAdj,tmrwOpen, tmrwCumAdj, FVOO);
	    double PL2NOEx15=omu.compute_PL2NO(minIdx-1+15,cumAdj,tmrwOpen, tmrwCumAdj, FVOO);
	    double PL2NOEx30=omu.compute_PL2NO(minIdx-1+30,cumAdj,tmrwOpen, tmrwCumAdj, FVOO);
	    double PL2NOEx45=omu.compute_PL2NO(minIdx-1+45,cumAdj,tmrwOpen, tmrwCumAdj, FVOO);
	    double PL2NOEx60=omu.compute_PL2NO(minIdx-1+60,cumAdj,tmrwOpen, tmrwCumAdj, FVOO);
	    double PL2NOEx90=omu.compute_PL2NO(minIdx-1+90,cumAdj,tmrwOpen, tmrwCumAdj, FVOO);
	    double PL2NOEx120=omu.compute_PL2NO(minIdx-1+120,cumAdj,tmrwOpen, tmrwCumAdj, FVOO);

	    //compute ET date/time
	    //int dateET, timeET;
	    //tz.convertToETDateTimeGivenSym(omu.date,hhmmss, omu.sym,dateET,timeET);

	    //////////compute lagged and fwd rets
	    ivl++;


	    /*
    //header
    cout<<"DATE SYM TIME ivl isOpenMin oT cT open close lastPrice cumAdj FVOO nextOpen";
    cout<<" GAP YOC ooP1D YHC YLC YMC YHL";
    cout<<" PL2C PL2NO PL2NC PLCO";
    cout<<" F1M F2M F5M F10M F15M F30M"<<endl;
	    */

	    cout<<omu.date;
	    cout<<" "<<omu.sym;
	    cout<<" "<<setw(6)<< setfill('0')<<hhmmssPre;
	    cout<<" "<<ivl<<" "<<isOpenMin<<" "<<omu.openTime<<" "<<omu.closeTime;
	    cout<<" "<<omu.open<<" "<<omu.close<<" "<<ou.close<<" "<<cumAdj<<" "<<FVOO<<" "<<tmrwOpen;
	    cout<<" "<<GAP<<" "<<YOC<<" "<<ooP1D<<" "<<YHC<<" "<<YLC<<" "<<YMC<<" "<<YHL;
	    cout<<" "<<PL2C<<" "<<PL2NO<<" "<<PL2NC<<" "<<PLCO;
	    cout<<" "<<PL2NOEx1<<" "<<PL2NOEx2<<" "<<PL2NOEx5<<" "<<PL2NOEx10<<" "<<PL2NOEx15<<" "<<PL2NOEx30<<" "<<PL2NOEx45<<" "<<PL2NOEx60<<" "<<PL2NOEx90<<" "<<PL2NOEx120;
	    //cout<<" | ";
            //ou.open<<" "<<ou.high<<" "<<ou.low<<" "<<ou.close<<" "<<ou.cumAdj<<endl;



	    //cout<<" | ";
	    //C). FxM
	    // forward rets
	    for (unsigned int k=0;k<lags.size();k++)
	    {

	        int horizon=lags[k];
	        int idxNext=minIdx+horizon;

		double ret=omu.compute_fwd_ret_A_to_B_1minOO(minIdx,idxNext,cumAdj,FVOO);
		//cout<<" F"<<horizon<<"M";
		if(ret ==NA_DBL)
		{
		  cout<<" NA";
		}
		else
		{
		  cout<<" "<<ret;
		}
	    }



	    // compute CHGSO.X at end of ith minutes: close at ith min minus open
	    for (unsigned int k=0;k<lags.size();k++)
	    {
 	        int horizon=lags[k]; //1,2,5,10, etc
	        double ret=omu.compute_CHGSO(minIdx+horizon-1,todayOpen,cumAdj,FVOO);
		//cout<<" F"<<horizon<<"M";
		if(ret ==NA_DBL)
		{
		  cout<<" NA";
		}
		else
		{
		  cout<<" "<<ret;
		}
	    }

       
            // compute HSO.X, high since open as of X min
	    for (unsigned int k=0;k<lags.size();k++)
	    {
 	        int horizon=lags[k]; //1,2,5,10, etc
	        double ret=omu.compute_HSO(minIdxOpen,minIdx+horizon-1,todayOpen,cumAdj,FVOO);
		//cout<<" F"<<horizon<<"M";
		if(ret ==NA_DBL)
		{
		  cout<<" NA";
		}
		else
		{
		  cout<<" "<<ret;
		}
	    }


            // compute LSO.X low since open as of X min
	    for (unsigned int k=0;k<lags.size();k++)
	    {
 	        int horizon=lags[k]; //1,2,5,10, etc
	        double ret=omu.compute_LSO(minIdxOpen,minIdx+horizon-1,todayOpen,cumAdj,FVOO);
		//cout<<" F"<<horizon<<"M";
		if(ret ==NA_DBL)
		{
		  cout<<" NA";
		}
		else
		{
		  cout<<" "<<ret;
		}
	    }

	    cout<<" "<<THC<<" "<<TLC<<" "<<TOC;
	    cout<<endl;

	}
       
   }






  
    return EXIT_SUCCESS;

}





/*
Some notes on timing of 1-min data:

--  portara time is at the end of minute, e.g, 8:31 row (from the CCFix1MIN24HR file) means
   from the minute from 8:30:00 to 8:31:00

-- for backward rets, e.g, if I sample at open min as well, e.g, if open is 8:30, my first sample
point is at 8:31:00 (ie, at the end of first minute), then next is 8:40 if sampled every 20 minutes

-- for backwrd ret, I use 1-min bar close for computing rets,
   for forward ret, I use 1-min bar open for the left end of the rets -- the purpose of this is so that
   cross-asset prediction could be made easy in the future


*/
