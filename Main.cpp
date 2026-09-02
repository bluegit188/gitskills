#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <ctime>
#include <iostream>
#include <cstring>
#include <stdlib.h>
#include <map>
#include <sstream>
#include <sys/stat.h>


#include "JunfUtil.h"
#include "RiskPara.h"
#include "Tokenizer.h"
#include "ForexNG.h"
#include "AssetSession.h"
#include "Dates.h"

using namespace std;

map<string,RiskParaUnit>  POINTVALUE_MAP;


template <typename T> string tostr(const T& t) 
{ 
   ostringstream os; 
   os<<t; 
   return os.str(); 
} 

string changeTimeZone (const string &tzname)
{
    char *tzptr = getenv ("TZ");
    std::string  tzold;
 
    if (tzptr)
        tzold = tzptr;
    if (tzname.empty())
        unsetenv ("TZ");
    else
        setenv ("TZ", tzname.c_str(), 1);
    tzset();
    return tzold;
}


string getTimeStampStr()
{
    time_t now=time(0); //sec from epoch
    struct tm *timeptr=localtime(&now);

    static char result[26];
    int YYYY= 1900 + timeptr->tm_year;
    int MM=timeptr->tm_mon+1;
    int DD=timeptr->tm_mday;

    //note tm_zone here is 3-letter abbr.
    sprintf(result, "%4d%02d%02d %02d:%02d:%02d %s",
	    YYYY,MM,DD,
	    timeptr->tm_hour,
	    timeptr->tm_min, 
	    timeptr->tm_sec,timeptr->tm_zone );
    string timeStampStr(result);

    return timeStampStr;
}


vector<string> getTimeStampDateTimeVec()
{
    time_t now=time(0); //sec from epoch
    struct tm *timeptr=localtime(&now);

    static char result1[26];
    static char result2[26];
    int YYYY= 1900 + timeptr->tm_year;
    int MM=timeptr->tm_mon+1;
    int DD=timeptr->tm_mday;

    //note tm_zone here is 3-letter abbr.
    sprintf(result1, "%4d%02d%02d",YYYY,MM,DD);
    sprintf(result2, "%02d%02d%02d",
	    timeptr->tm_hour,
	    timeptr->tm_min, 
	    timeptr->tm_sec);

    string str1(result1);
    string str2(result2);
    vector<string> vec;
    vec.push_back(str1);
    vec.push_back(str2);
    return vec;
}


/*
// this must be in main??
ostream & operator<< (ostream & out, const DailyRTHUnit & s)
{
    s.print(out);
    return out;
}
*/

	     
void load_risk_global(map<string,double>&risk_global_map, string riskFile)
{

    ifstream input;
    //string filename="/home/jgeng/transfer/Prod/risk_global.conf";
    string filename=riskFile;

    input.open(filename.c_str());
    if(input.fail())
    {
        cerr << "Can't open the file: " << filename << endl;
        exit(-1);
    }

    string line;
    while (!input.eof()) 
    {
	getline(input,line);

	if (line.length() == 0 || line[0] == '#') //skip empty and # lines
	{
       	    continue;
	}

	//process
	Tokenizer s(line," ="); //split at = and remove space
	string token;

	// Tokenizer::next() returns a next available token from source string
	// If it reaches EOS, it returns zero-length string, "".
	/*       	
	while((token = s.next()) != "")
        {
  	    cout <<" |"<< token<<"|";
	}
	cout<<endl;
	*/

	
	vector<string> v=s.split();
	//cout<<v[0]<<" "<<v[1]<<endl;
	risk_global_map.insert(  make_pair(v[0],atof(v[1].c_str())) );
	
    } //end of line


}

void load_point_values(map<string,RiskParaUnit>&pvMap)
//load point value file
{

    ifstream input;
    string filename="/home/jgeng/transfer/Prod/pvUSD_prod.txt";

    input.open(filename.c_str());
    if(input.fail())
    {
        cerr << "Can't open the file: " << filename << endl;
        exit(-1);
    }

    string line;
    while (!input.eof()) 
    {
	getline(input,line);

	if (line.length() == 0 || line[0] == '#') //skip empty and # lines
	{
       	    continue;
	}

	//process
	Tokenizer s(line); //split at space and remove space
	string token;

	// Tokenizer::next() returns a next available token from source string
	// If it reaches EOS, it returns zero-length string, "".
	/*	       	
	while((token = s.next()) != "")
        {
  	    cout <<" |"<< token<<"|";
	}
	cout<<endl;
	*/

		
	vector<string> v=s.split();
	//cout<<v[0]<<" "<<v[1]<<endl;
	//#SYM Currency  PointValue       fx    pvUSD
	RiskParaUnit rpu;
	rpu.sym=v[0];
	rpu.curr=v[1];
	rpu.pvLoc=atof(v[2].c_str());
	pvMap.insert(  make_pair(v[0],rpu) );

    } //end of line


}

	     
void load_netMgn_adjFactor(map<string,double>&netMgn_map, int local)
{

    ifstream input;
    string filename="/roottransfer/jgeng/Prod/fcsts/fcstSum.txt";
    if(local==1) // read from local fcstSum file
    {
       filename="fcstSum.txt";
    }

    input.open(filename.c_str());
    if(input.fail())
    {
        //cerr << "Can't open the file: " << filename << endl;
        //exit(-1);
      return;  // this is optional, so don't exit
    }

    string line;
    while (!input.eof()) 
    {
	getline(input,line);

	if (line.length() == 0 || line[0] == '#') //skip empty and # lines
	{
       	    continue;
	}

	//process
	Tokenizer s(line," ="); //split at = and remove space
	string token;

	// Tokenizer::next() returns a next available token from source string
	// If it reaches EOS, it returns zero-length string, "".
	/*       	
	while((token = s.next()) != "")
        {
  	    cout <<" |"<< token<<"|";
	}
	cout<<endl;
	*/

	
	vector<string> v=s.split();
	//cout<<v[0]<<" "<<v[1]<<endl;
	netMgn_map.insert(  make_pair(v[0],atof(v[1].c_str())) );
	
    } //end of line


}

void get_cvxChg_today(int todayDate,string sym, double & cvxChg, Dates& dater)
{

    ifstream input;
    string filename="/roottransfer/jgeng/Prod/cvxChg/cvxChgs.txt";

    input.open(filename.c_str());
    if(input.fail())
    {
        //cerr << "Can't open the file: " << filename << endl;
        //exit(-1);
      return;  // this is optional, so don't exit
    }

    string line;
    while (!input.eof()) 
    {
	getline(input,line);

	if (line.length() == 0 || line[0] == '#') //skip empty and # lines
	{
       	    continue;
	}

	//process
	Tokenizer s(line," "); //split at = and remove space
	string token;

	// Tokenizer::next() returns a next available token from source string
	// If it reaches EOS, it returns zero-length string, "".
	/*       	
	while((token = s.next()) != "")
        {
  	    cout <<" |"<< token<<"|";
	}
	cout<<endl;
	*/
	
	vector<string> v=s.split();
	//cout<<v[0]<<" "<<v[1]<<" "<<v[2]<<endl;
	string curSym=v[0];
	int curDate=atoi(v[1].c_str());
	double curCvxChg=atof(v[2].c_str());

        int bizDateDif=-999;
        bizDateDif=dater.bizDateDif(curDate, todayDate);
	//cout<<"dateDif="<< bizDateDif<<endl;
        //if(curSym == sym && bizDateDif==1)
	// less than 7 days old is ok (some holidays)
	// 20240408, after Chinming holidays, should cut AG risk despite holiday
	if(curSym == sym && bizDateDif<= 7) 
	{
	    cvxChg= curCvxChg;
	}

	
    } //end of line

}


double optTradesNaive(double prevPos, double targetPos)
{
    return targetPos - prevPos;
}





double optXT(double sizeX, double newFcst)
//given X and currentFcst, return netFcst
{
   double fcstNetSize=abs(newFcst)-sizeX;
   double fcstNet;
   if(fcstNetSize < 0)
   {
     fcstNet=0;
   }
   else
   {
     fcstNet=sign(newFcst)*fcstNetSize;
   }

   return fcstNet;

}


double optZA(double sizeX, double prevFcst, double newFcst)
//given X and currentFcst, return netFcst
{

   double fcstNet;

   if(newFcst > prevFcst)
   { 
      fcstNet=newFcst-sizeX;
      if(fcstNet < prevFcst)
      {
	fcstNet=prevFcst;
      }
   }

   if(newFcst <= prevFcst)
   { 
      fcstNet=newFcst+sizeX;
      if(fcstNet > prevFcst)
      {
	fcstNet=prevFcst;
      }
   }

   // small fix, see 20221217 report
   if(fcstNet*newFcst < 0 || abs(newFcst)< 0.001)
   //if(fcstNet*newFcst < 0)
   {
     fcstNet=0;
   }

   return fcstNet;
}



double optZAY(double sizeX, double sizeY,double prevFcst, double newFcst)
//given X and currentFcst, return netFcst
{

   double fcstNet;

   //#if ( abs($prevPos)!=0 && $prevPos*$newFcst >=0 && abs($newFcst)< abs($prevPos) && abs($newFcst)>0.001 ) # if reduce in same direction

   if ( abs(prevFcst)!=0 && prevFcst*newFcst >=0 && abs(newFcst)< abs(prevFcst) && abs(newFcst)>0.001 ) // if reduce in same direction

   {
      if(prevFcst >0) //reduce a prev long
      {
          fcstNet=newFcst+sizeY;
          if(fcstNet > prevFcst)
          {
            fcstNet=prevFcst;
          }
      }
      if(prevFcst <0) //reduce a prev short
      {
          fcstNet=newFcst-sizeY;
          if(fcstNet < prevFcst)
          {
            fcstNet=prevFcst;
          }
      }

   }
   else                                                     // otherwise, same as optZA
   {
      fcstNet=optZA(sizeX,prevFcst,newFcst);
   }

   return fcstNet;

}


inline bool file_exists (const std::string& name) 
{
  struct stat buffer;   
  return (stat (name.c_str(), &buffer) == 0); 
}

int main (int argc, char ** argv)
{

   // open file named on the command-line for reading
   if (argc !=8)
   {
       cerr << "usage: " << argv[0] << " <DATE> <SYM> prevPos fcst FVOO_pts FVOO2 [opt=main/bwt3]" << endl; 
       cerr << "       Compute BT1 target position and trades for given symbol and date" << endl; 
       cerr << "       opt: for risk_file location for that acct: /home/jgeng/transfer/Prod/risk_global_bwt2.conf" << endl; 
       exit(1);
   }

   int todayDate=atoi(argv[1]);
   string sym(argv[2]);
   double prevPos=atof(argv[3]);
   double fcst=atof(argv[4]);
   double FVOO=atof(argv[5]);

   double FVOO2=atof(argv[6]);

   string actStr(argv[7]);


   cout<<"LOG: "<<sym<<" "<<todayDate<<" timestamp= "<<getTimeStampStr()<<endl;
   cout<<"LOG: "<<"prevPos= "<<prevPos<<" fcst="<<fcst<<endl;
   
   string riskFile="/home/jgeng/transfer/Prod/risk_global.conf";
   if(actStr != "main")
   {
     riskFile="/home/jgeng/transfer/Prod/risk_global_"+actStr+".conf";
   }
   cout<<"LOG: "<<"riskFile= "<<riskFile<<endl;

   //###################################
   //### load global risk paras
   //###################################

   // sym and asset multipliers
   double SYM_MULT=1.0;
   //double ASSET_MULT=1.0;
   double ASSET_MULT=1.12; //this seems to be in the code since inception, so I just keep it as is.

   double NUDGE_MULT=1.0; //adjust factor for misc reasons

   double FVOO2_MULT=1.0; // for now, just adj risk down by 20% if FVOO2> 1.5

   /*
   if(FVOO2>=1.85) // see 20211013 report
   {
       FVOO2_MULT=0.6;
   }
   */
   // new method for fvoo2_mult, see 20211014 report
   double alpha=0.5;
   double FVOO2Shrink=(constrain(FVOO2,0.4,3.0)-1)*alpha+1;
   double fcstOrig=fcst;
   
   int adjFcstByFvoo2=1;
   if(adjFcstByFvoo2==1)
   {
       fcst=fcst/FVOO2Shrink; // adjust fcst by the shrink fvoo2
   }
   fcst=constrain(fcst,-0.11,0.13);


   //double fcstPreMgnAdj=fcst; //this is pre netMgn adjustment


   //netMgn adjust factor; if netMgn > 1.6, adjFactor=1.6/netMgn
   double netMgnAdjFactor=1.0; //0.55 for 20220610 //usually no adjustment


   // set up netMgn parameters: 2-threshold methods
   //see 20220615: netMgn, mean=0.95, median=0.8
   Dates dater;
   int DOW=dater.getDOWFast(todayDate);
   double netMgnThresh=1.55; // see 20220824 report
   if(DOW==5)
   {
     //netMgnThresh=1.8;
     //netMgnThresh=1.55;

     // netMgnThresh=1.65;

   }
   double netMgnAbs=0;

   ////////////////////////////
   //////////////////////
   // load netMgn adjFactor

   // /* turn it off if not needed by commenting it out

   int local=0;  //default reads fcstSum from fcsts dir
   //if local file exists, reads from local dir
   string filename="fcstSum.txt";
   if(file_exists(filename))
   {
      local=1;
   }

   map<string,double>netMgnMap;
   load_netMgn_adjFactor(netMgnMap, local);
   map<string,double>::iterator it1,it2;
   it1 = netMgnMap.find("tradeDate");
   it2 = netMgnMap.find("netMgnAbs");
   //don't access map with [""] operator 
   // very slow, as it increase trees
   if (it1 != netMgnMap.end() && it2 != netMgnMap.end()  )
   {
      if ( int(it1->second)==todayDate)
      {

	// extract netMgnAbs for scaling
	 netMgnAbs=it2->second;

	 if(netMgnAbs >netMgnThresh )
	 {
	   netMgnAdjFactor=netMgnThresh/netMgnAbs;
	 }
      }
   }


   // */


   // if you want to force a netMgnAdj, uncomment below line
   // netMgnAdjFactor=1.0; //usually no adjustment
 
   

   fcst=fcst* netMgnAdjFactor;



   // asset multiplers
   AssetSession as;
   as.setSymbol(sym); // set current sym
   //as.print();
   //as.isPhy();


   /////////////////////
   /// ASSET multiplers
   ///////////////////

   // all CN symbols are counted as phy



   /////////////////////
   /// Sector multiplers
   ///////////////////

   double SECTOR_MULT=1.0;
   string sectorStr="NA";
   if(sym =="CNC"|| sym=="CNCS"|| sym=="CNA"|| sym=="CNJD"|| sym=="CNM"|| sym=="CNY"|| sym=="CNP"|| sym=="CNCF"|| sym=="CNOI"|| sym=="CNSR"|| sym=="CNRM")
   {
      sectorStr="agri";
      SECTOR_MULT=1.0;
      //SECTOR_MULT=0.8;
      //SECTOR_MULT=1;
      //SECTOR_MULT=0.7;
      //SECTOR_MULT=0.85;
      //SECTOR_MULT=0.85;
   }

   if(sym=="CNCU"||sym=="CNAL"||sym=="CNZN"||sym=="CNPB"||sym=="CNNI"||sym=="CNSN"||sym=="CNAU"||sym=="CNAG")
   {
      sectorStr="nfmetal";
      SECTOR_MULT=1.0;
      //SECTOR_MULT=0.6667; //20210606 adj
      //SECTOR_MULT=0.8; //20210617 adj
      //SECTOR_MULT=1.0; //20210621, back to 1
      //SECTOR_MULT=1; //20210621, back to 1
      //SECTOR_MULT=0.85; //20210621, back to 1

   }

   if(sym=="CNJM"||sym=="CNJ"||sym=="CNI"||sym=="CNHC"||sym=="CNRB"||sym=="CNZC"||sym=="CNSF"||sym=="CNSM"||sym=="CNFG")
   {
      sectorStr="coalsteel";
      SECTOR_MULT=1.0;
      //SECTOR_MULT=0.6; //see 2021/03/01 report
      //SECTOR_MULT=1.0; //see 2021/03/04 report
      //SECTOR_MULT=0.5;  //see 2021/05/19 report
      //SECTOR_MULT=0.56; //see 2021/08/01 report
      //SECTOR_MULT=1; //see 2021/08/04, all asset AUM to 60% risk
      //SECTOR_MULT=0.85; //see 2021/08/04, all asset AUM to 60% risk
      //SECTOR_MULT=0.85; //see 2021/08/04, all asset AUM to 60% risk
   }

   if(sym=="CNL"||sym=="CNV"||sym=="CNPP"||sym=="CNMA"||sym=="CNTA"||sym=="CNBU"||sym=="CNRU")
   {
      sectorStr="petro";
      //SECTOR_MULT=1.0;

      //SECTOR_MULT=0.6; //20210617 adj
      SECTOR_MULT=0.25; //20210620 adj
   }




   // sym multiplier
   // as of 20210923
   //if(sym=="CNJM"||sym=="CNZC"||sym=="CNSF"||sym=="CNSM")
   //{
   //    SYM_MULT=0.7;
   //}


   // see 20230505 report, 2024022 rep
   if(sym=="CNAU"||sym=="CNCU")
   {
       SYM_MULT=0;
   }

   if(sym=="CNSR")
   {
     SYM_MULT=0.25;
   }
   if(sym=="CNSM")
   {
     SYM_MULT=0.25;
   }
   if(sym=="CNCF")
   {
     SYM_MULT=0.4;
   }

   // 20231116 
   // AFBI has no J, so increase JM slightly
   // 20231206, from 1.2 to 1.33
   if(sym=="CNJM" && actStr == "bwt7")
   {
       SYM_MULT=1.33;
   }


   /*
   if(sym=="CNA")
   {
       SYM_MULT=0.75;
   }
   */

   

   map<string,double>RISK_GLOBAL_MAP;
   load_risk_global(RISK_GLOBAL_MAP, riskFile);
   map<string,double>::iterator it;

   double RPF=RISK_GLOBAL_MAP.find("RPF")->second;
   double AUM_NOW=RISK_GLOBAL_MAP.find("AUM_NOW")->second;
   double AUM_TARGET=RISK_GLOBAL_MAP.find("AUM_TARGET")->second;
   double FCST_CUTOFF_L=RISK_GLOBAL_MAP.find("FCST_CUTOFF_L")->second;
   double FCST_CUTOFF_H=RISK_GLOBAL_MAP.find("FCST_CUTOFF_H")->second;

   double NAV_FACTOR=1.0;
   it = RISK_GLOBAL_MAP.find("NAV_FACTOR");
   if (it != RISK_GLOBAL_MAP.end())
   {
     NAV_FACTOR=it->second; //RISK_GLOBAL_MAP["NAV_FACTOR"];
   }

   double RPF_ADJ=RPF*(AUM_NOW/AUM_TARGET)*NAV_FACTOR;



   //cvxChg
   double cvxChg=0;
   get_cvxChg_today(todayDate,sym,cvxChg,dater);
   //cout<<"cvxChg= "<<cvxChg<<endl;
   int CVX_CHG_MULT=1;
   //if( cvxChg < -0.2 || cvxChg > 0.21) //95% cutoff
   if( cvxChg < -0.23 || cvxChg > 0.254) //92.5% cutoff
   {
      CVX_CHG_MULT=0;
   }


   // for holiday adjustment
   //double HOLIDAY_MULT=1.0;
   //double HOLIDAY_MULT=0.25;
   //double HOLIDAY_MULT=0.667;
   //double HOLIDAY_MULT_AFBI=0.85;  // for AFBI/bwt7, use its own risk adj factor

   //for fri
   // double HOLIDAY_MULT=0.5;
   //double HOLIDAY_MULT_AFBI=0.6;  // for AFBI/bwt7, use its own risk adj factor
   //double HOLIDAY_MULT=0.65;
   //HOLIDAY_MULT has 2 components: first is for riskAdj, 2nd is for mktFvooAdj
   double MKT_FVOO_ADJ=1.2;
   double HOLIDAY_MULT=0.75*MKT_FVOO_ADJ;
   double HOLIDAY_MULT_AFBI=0.75*MKT_FVOO_ADJ;  // for AFBI/bwt7, use its own risk adj factor




   // due to frequent margin ejections
   if(actStr == "bwt13" )
   {
     HOLIDAY_MULT=0.75*MKT_FVOO_ADJ;
   }

   // Qube acct
   if(actStr == "bwt5")
   {
     //HOLIDAY_MULT=0.5;
      HOLIDAY_MULT=0.75*MKT_FVOO_ADJ*1.2;
   }



   //was 0.75 for all, 0.7 for 13, Mar 19

   //double HOLIDAY_MULT=0.5;
   //double HOLIDAY_MULT=0.667;
   // these symbols have very large vol recently, reduce further during Oct 1 holidays
   //if(sym=="CNZC"||sym=="CNJM"||sym=="CNJ"||sym=="CNSF"||sym=="CNSM"||sym=="CNV"||sym=="CNPP"||sym=="CNMA"||sym=="CNL"||sym=="CNCF")
   //{
   //    HOLIDAY_MULT=0.667;
   //}


   //****** apply sym and asset multipliers
   // for AFBI, use HOLIDAY_MULT_AFBI=1.0 instead of HOLIDAY_MULT
   if(actStr == "bwt7" )
   {
       RPF_ADJ=RPF_ADJ*SYM_MULT*ASSET_MULT*NUDGE_MULT*FVOO2_MULT*SECTOR_MULT*HOLIDAY_MULT_AFBI;
   }
   else
   {
       RPF_ADJ=RPF_ADJ*SYM_MULT*ASSET_MULT*NUDGE_MULT*FVOO2_MULT*SECTOR_MULT*HOLIDAY_MULT;
   }


   // dollar unit risk
   double DUR=AUM_NOW*0.00087*0.7; // for 1MM AUM, about $870 dollars, x0.7 change to $600
  
   cout<<"LOG: "<<"RPF="<<RPF;
   cout<<" AUM_NOW="<<AUM_NOW;
   cout<<" AUM_TARGET="<<AUM_TARGET;
   cout<<" RPF_ADJ="<<RPF_ADJ;
   cout<<" SYM_MULT="<<SYM_MULT;
   cout<<" ASSET_MULT="<<ASSET_MULT;
   cout<<" NUDGE_MULT="<<NUDGE_MULT;
   cout<<" FVOO2_MULT="<<FVOO2_MULT;
   cout<<" SECTOR_MULT="<<SECTOR_MULT;
   cout<<" HOLIDAY_MULT="<<HOLIDAY_MULT;
   cout<<" NAV_FACTOR="<<NAV_FACTOR;
   cout<<" HOLIDAY_MULT_AFBI="<<HOLIDAY_MULT_AFBI;
   cout<<" MKT_FVOO_ADJ="<<MKT_FVOO_ADJ<<endl;

   //################################
   //###  load fx exchange rate
   //################################


   map<string,RiskParaUnit>::iterator itpv;

   load_point_values(POINTVALUE_MAP);
   string denom=(POINTVALUE_MAP.find(sym)->second).curr;
   //for CN fut, force denom as USD(actually RMB)
   denom="USD";
   cout<<"LOG: "<<"Denom="<<denom<<endl;
   double pointValue=(POINTVALUE_MAP.find(sym)->second).pvLoc;
   double exchangeRate=1.0;
   int fxDate=-1;
   if(denom != "USD") // will never go here with CN futs
   {
      string fxSym=denom+"USD"; // EURUSD
      ForexNG fx(fxSym);      
      //fx.print();
      double lastClose=fx[fx.size()-1].close;
      int lastDate=fx[fx.size()-1].date;
      cout<<"LOG: "<<fxSym<<" fx close, date="<<lastClose<<" "<<lastDate<<endl;
      exchangeRate=lastClose;
      fxDate=lastDate;
   }

   double FVOOD=FVOO*pointValue*exchangeRate;
   cout<<"LOG: "<<"FVOO, exchangeRate, FVOOD="<<FVOO<<" "<<exchangeRate<<" "<<FVOOD<<endl;


   //##############################################
   //### target position
   //##############################################
 

   ///?? needs to load in min tick, divide by say past 3M MA of price chg to get 
   // an estimation of tcost
   // for now, just a very rough approx
   //  double tcost=0.04; //change to 0.03 for now, Mar 22,2018// 0.04
                         //back to 0.04 from 0.025, 2018/08/26
                         // chg from 0.04 to 0.035, 2018/10/25
                         // back 0.03, 2019/04/27


   //double tcost=0.04; //scd2DXFXBT1 needs smaller tcost

   double tcost=0.03; //scd2DXFXBT1 needs smaller tcost


   double sizeX=tcost;
   double sizeY=tcost;

   double fcstNet;


   double prevFcst=prevPos*FVOOD/RPF_ADJ;

   // 20211020: when we reduce risk, a given pos can be translated into a fcst that is
   // is very big, which we don't want it to happen
   prevFcst=constrain(prevFcst,-0.1,0.13);


   //  default changes to ZAs, 20190524 (used to default to XTs)
   //  best to add each sym into its catogory for clarity
   int isOptZA=1;


   
   // test sizeX=0.025 on bwt20 and bwt39
   if(actStr == "bwt20" || actStr == "bwt39") //close Jun 29, 2023
   {
      sizeX=0.03;//sizeX=0.025;
      isOptZA=1; //optZA method

   }

   //test out optZAY on C and HC
   //if(sym=="CNC"||sym=="CNHC"||sym=="CNM"||sym=="CNSF") // try C and HC first
   if(actStr == "bwt3" && (sym=="CNC"||sym=="CNHC"||sym=="CNM"||sym=="CNSF")) // try C and HC first
   {
      sizeX=0.04;
      sizeY=0.02;
      isOptZA=2; //optZAY method, see 20240108 rep
   }
  
   //for AFBI, use sizeX=0.06 for now due to its high tcost
   // also need to up risk multipler to match
   if(actStr == "bwt7" )
   {
      sizeX=0.06;
      sizeY=0.06;
   }
  

   // for Qube/bwt5, for 5bps symbol, use higher sizeX, see 20240108 rep
   int isQube5bps=0;
   if(actStr == "bwt5" && (sym=="CNV"||sym=="CNSF"||sym=="CNPP"||sym=="CNRU"||sym=="CNSM"||sym=="CNJD"||sym=="CNBU"||sym=="CNPB"||sym=="CNNI"||sym=="CNFG"||sym=="CNJ"||sym=="CNCF"||sym=="CNC"||sym=="CNSN"||sym=="CNCS"||sym=="CNJM"))
   {
       isQube5bps=1;
       sizeX=0.06;
       sizeY=0.06;

       SYM_MULT=SYM_MULT*0.85; // see 20240425 rep
   }
   else //2bps univ
   {
       SYM_MULT=SYM_MULT*1.15;
   }


   //sizeX_riks_mult adjustment here


   /*
        shp.XT      shp.ZA   ZA/XT
 STW   0.840245   0.924541  1.10032 #
  BC   0.983367    1.10524  1.12393 #
  CL   0.634244   0.753139  1.18746 #
 SNI   0.846206     1.0533  1.24473 #
 ESX   0.633476   0.802011  1.26605 #
  VX    1.04379    1.33901  1.28283 #
  GC   0.397307   0.555803  1.39893 #
 GBM   0.672454   0.998258   1.4845 #
 GBL   0.503861    0.85888   1.7046 #
   */

   if(isOptZA==0) // optXT method
   { 
     fcstNet=optXT(sizeX,fcst);
   }



   //MAX_FCSTNET: this makes pos change more smooth when RISKADJ changes
   double MAX_FCSTNET=abs(0.13-sizeX); // 0.09=0.13 - 0.04 tcost


   if(isOptZA==1) // optZA method
   { 
      double tmpPrevFcst=prevPos*FVOOD/RPF_ADJ;
      //tmpPrevFcst=constrain(tmpPrevFcst,-0.1,0.13);
      tmpPrevFcst= constrain( tmpPrevFcst,-MAX_FCSTNET,MAX_FCSTNET);
      fcstNet=optZA(sizeX,tmpPrevFcst,fcst);
   }


   if(isOptZA==2) // optZAY method
   { 
      double tmpPrevFcst=prevPos*FVOOD/RPF_ADJ;
      //tmpPrevFcst=constrain(tmpPrevFcst,-0.1,0.13);
      tmpPrevFcst= constrain( tmpPrevFcst,-MAX_FCSTNET,MAX_FCSTNET);
      fcstNet=optZAY(sizeX,sizeY,tmpPrevFcst,fcst);
   }





   // double fcstNet=fcst;
   double posFrac=RPF_ADJ*fcstNet/FVOOD;
   double posRound=nearest_junf(0,posFrac);

   double posRoundAdj=posRound;

   /*
   // I remove this line for CN trade, no need to force one lot if fcst is large
   if(posRound==0 && ( fcstNet <= FCST_CUTOFF_L || fcstNet >= FCST_CUTOFF_H ) )
   {
       posRoundAdj=sign(fcstNet)*1;
   }
   */

   // max pos constraint
   double MAX_LOT_LONG=1000; // set this for now, determine when AUM is large
   double MAX_LOT_SHORT=-1000; 
   // for VX, use small size for testing
   if(sym =="VX")
   {
     MAX_LOT_LONG=3;
     MAX_LOT_SHORT= -3;

   }
   double posRoundAdjRaw=posRoundAdj;




   //20190220, if riskd< unit risk, put on unit risk
   int belowDUR=0;

   //DUR=$800 seems to be large after some observation in prod
   // this is originaly to fix up large FVOOD issue, so for small AUM,
   // SNI (1000 FVOOD) doesn't exit too frequently,e.g, when fcst changes from 0.1 to 0.02
   // for small FVOOD contracts, I think in fact not needed
   if(FVOOD < 1000 ) // when AUM is small like 1MM; in the future with larger AUM, can get rid of DUR
   {
     DUR=0;
   }


   double posFracAdj=posFrac;

   /*
   // remove this section, as of 20210825
   if( posRoundAdj !=0 && abs(posRoundAdjRaw)*FVOOD < DUR)
   {
        posFracAdj=DUR/FVOOD*sign(fcstNet);
        posRoundAdj=nearest_junf(0,posFracAdj);
	belowDUR=1;
	
	// possible after roundoff under unit risk, lots is still the same
	if(posRoundAdj != posRoundAdjRaw)
	{
	  belowDUR=1;
	}
   }
   */

   // this is a double safety measure: maxDolRisk per sym
   // fcst cap at +/-0.16 should be good, but cap in dollar term just in case
   //maxDolRiskPerSym
   // for US
   //double MAX_DRISK_SYM=AUM_NOW*0.0022; //$1650 for 750K AUM
   //for CN
   double MAX_DRISK_SYM=AUM_NOW*0.0017; //$11K for 6.5MM RMB AUM, ie 2.5xplStd

   double MAX_LOT_SYM=floor(MAX_DRISK_SYM/FVOOD); //this is max lot per sym
   //allow at least one lot for our univ, DAX replaced now by miniDAX
   if(MAX_LOT_SYM<1)
   {
       MAX_LOT_SYM=1;
   }

   posRoundAdj=constrain(posRoundAdj,-MAX_LOT_SYM, MAX_LOT_SYM);

   // this max log/short for later participation limits
   posRoundAdj=constrain(posRoundAdj,MAX_LOT_SHORT, MAX_LOT_LONG);


   // for manual adjusting lots
   double manualAdjLot=0;
   /*
   if(sym=="C")
   {
     manualAdjLot=-4; // a play on 200B tariff
   }

   if(sym=="CD") // a play on nafta success
   {
     manualAdjLot=3;
   }
   */

   if(sym=="VX") // high uncertainty for June
   {
     manualAdjLot=1;
   }
   posRoundAdj+= manualAdjLot;



   cout<<"LOG: "<<"posFrac= "<<posFrac<<" posRound= "<<posRound<<" posRoundAdj= "<<posRoundAdj<<" posRoundAdjRaw= "<<posRoundAdjRaw<<" MAX_LOT_LONG= "<<MAX_LOT_LONG<<" MAX_LOT_SHORT= "<<MAX_LOT_SHORT<<" DUR= "<<DUR<<" belowDUR= "<<belowDUR<<" posFracAdj= "<<posFracAdj<<" MAX_DRISK_SYM= "<<MAX_DRISK_SYM<<" MAX_LOT_SYM= "<<MAX_LOT_SYM<<endl;
   cout<<"LOG: "<<"fcst= "<<fcst<<" fcstNet= "<<fcstNet<<" tcost= "<<tcost<<" RPF_ADJ= "<<RPF_ADJ<<" FVOOD= "<<FVOOD<<endl;
   //##############################################
   //### trades
   //##############################################
   //double prevFcst=prevPos*FVOOD/RPF_ADJ;


   // recycled for AFBI
   // for liquidating bwt7 positions, set its targetPos as zeros
   //if(actStr == "bwt7")
   //{
   //  posRoundAdj=0;
   //}

   if(actStr == "bwt9") //close Jun 1, 2021
   {
     posRoundAdj=0;
   }

   if(actStr == "bwt8") //close Jun 21, 2021
   {
     posRoundAdj=0;
   }

   if(actStr == "bwt6") //close Jan 21, 2022
   {
     posRoundAdj=0;
   }


   if(actStr == "bwt4") //close Jan 21, 2022
   {
     posRoundAdj=0;
   }

   //if(actStr == "bwt5") //close Jun 23, 2021
   //{
   //  posRoundAdj=0;
   //}
   // recyce bwt5 for Qube, Dec 1, 2021


   //Qube don't trade JD, AU and RU, set to zero
   // seems no such limits anymore (2022/05/16)
   /*
   if(actStr == "bwt5")
   {
      if(sym=="CNAU"||sym=="CNJD"||sym=="CNRU")
      {
	 posRoundAdj=0;
       }
   }
   */

   //AFBI/bwt7 doesn't trade DCE products, set to zero, 2022/04/11
   // AFBI/bwt7 allow DCEs now(only J and JM not allowed), switch DCE on, added 9 new symbols, 20220518
   int isDCE=0;
   if(actStr == "bwt7")
   {

       // note that CNI(Iron ore) and CNP(palm oil) from DCE are internationalized, so still ok to tade, 202205
       // 20230807, JM is available now, J is still not
       if(sym=="CNB"||sym=="CNBB"||sym=="CNEB"||sym=="CNEG"||sym=="CNFB"||sym=="CNJ"||sym=="CNLH"||sym=="CNPG"||sym=="CNRR")
       {
	 isDCE=1;
	 posRoundAdj=0;
       }

       //MACQ/AFBI not trading NI now
       //if(sym=="CNNI")
       //{
       //   posRoundAdj=0;
       //}



       //RM can only short now for AFBI
       //if(sym=="CNRM"&& posRoundAdj>0)
       //{
       //   posRoundAdj=0;
       //}


       //RU/rubber  can only take longs for AFBI as of 20220602
       //if(sym=="CNRU"&& posRoundAdj<0)
       //{
       // posRoundAdj=0;
       //}

       //JD/egg  can only take longs for AFBI as of 20220602
       //if(sym=="CNJD"&& posRoundAdj<0)
       //{
       // posRoundAdj=0;
       //}


       //CS  can only take longs for AFBI as of 20220602
       //if(sym=="CNCS"&& posRoundAdj<0)
       //{
       //	 posRoundAdj=0;
       //}



   }


   /*
   if(actStr == "bwt7" && sym=="CNI") //set AFBI Iron Ore to zero now, 20231117,MACQ request
   {
     posRoundAdj=0;
   }
   */

   if(actStr == "bwt11") //pending to open, Sep 19, 2021
   {
     posRoundAdj=0;
   }

   if(actStr == "bwt10") //closed Mar 3, 2022
   {
     posRoundAdj=0;
   }

   //if(actStr == "bwt19") //Jiazhi, close acct as of 06/23,2022; resume 20220706
   //{
   //  posRoundAdj=0;
   //}

   /*
   if(actStr == "bwt7") //AFBI paused at 06/28/2022
                        // AFBI restarted at Aug 9, 2023
   {
     posRoundAdj=0;
   }
   */

   if(actStr == "bwt23") //Olymus stopped bwt23 for 20220826
   {
     posRoundAdj=0;
   }

   if(actStr == "bwt33") //pasue as of 2022/11/15
   {
     posRoundAdj=0;
   }

   if(actStr == "bwt35") //35/36 close all quant accts with nav<1
   {
     posRoundAdj=0;
   }

   if(actStr == "bwt36") //
   {
     posRoundAdj=0;
   }

   if(actStr == "bwt21") // 20221216 
   {
     posRoundAdj=0;
   }

   if(actStr == "bwt37") // 20221219 
   {
     posRoundAdj=0;
   }

   if(actStr == "bwt38") // 20221220
   {
     posRoundAdj=0;
   }


   if(actStr == "bwt34") // 20230119, huatian
   {
     posRoundAdj=0;
   }


   if(actStr == "bwt17") // 20230215, olympus fund
   {
     posRoundAdj=0;
   }

   if(actStr == "bwt31") // 20230223, changan
   {
     posRoundAdj=0;
   }

   if(actStr == "bwt28") // 20230301, Toujia, pause
   {
     posRoundAdj=0;
   }


   if(actStr == "bwt16") // 20230327, Baoxin
   {
     posRoundAdj=0;
   }

   if(actStr == "bwt18") // 20230327, Mingce
   {
     posRoundAdj=0;
   }


   if(actStr == "bwt30") // 20230405, wenyifuxi
   {
     posRoundAdj=0;
   }

   if(actStr == "bwt26") // 20230410, mingce
   {
     posRoundAdj=0;
   }



   if(actStr == "bwt19") // 20230508, Jiazhi
   {
     posRoundAdj=0;
   }

   if(actStr == "bwt29") // 20230612, Toujia
   {
     posRoundAdj=0;
   }


   
   if(actStr == "bwt24") // 20230619 Chengkai
   {
     posRoundAdj=0;
   }

   if(actStr == "bwt25") // 20230619 Chengkai2
   {
     posRoundAdj=0;
   }

   if(actStr == "bwt27") // 20230619 Chengkai3
   {
     posRoundAdj=0;
   }

   
   if(actStr == "bwt2") // 20230621 huachang2
   {
     posRoundAdj=0;
   }

   
   
   if(actStr == "bwt12") // 20230719 Shuanglong PFM
   {
     posRoundAdj=0;
   }

   
   if(actStr == "bwt14") // 20230807 Huatian, acct redemption, not due to perf.
   {
     posRoundAdj=0;
   }

      
   if(actStr == "bwt7" ) // 20240116  AFBI closed due to NH pulling out
   {
     posRoundAdj=0;
   }
  
   if(actStr == "bwt22" ) // 20240129 mulan pasued for now
   {
     posRoundAdj=0;
   }
  



   //if(actStr == "bwt5") // 20221222, qube holiday, set 1/3 risk
   //{
   //  posRoundAdj=int(posRoundAdj/3+0.5);
   //}

   // for holidays
   // if(actStr != "bwt2") // 20221222, qube holiday, set 1/3 risk
   // {
   //   posRoundAdj=int(posRoundAdj*0.5+0.5);
   // }


   // 20210606, set these two as 0 pos due to weak perf., review later
   //if(sym=="CNTA")
   //{
   //   posRoundAdj=0;
   //}

   // see 20210913 report
   int FVOODTOOHIGH=0;
   //if(FVOOD > 7000)
   if(FVOOD > 8000)
   {
     FVOODTOOHIGH=1;
   }

   if(FVOODTOOHIGH ==1)
   {
     posRoundAdj=0;
   }

   // 20211020, set these two as 0 pos due to weak perf., review later
   //if(sym=="CNJ"||sym=="CNJM"||sym=="CNZC"||sym=="CNSM"||sym=="CNMA"||sym=="CNSF")
   // SF restarted on 20211119.
   //if(sym=="CNJ"||sym=="CNZC"||sym=="CNSM")
   //if(sym=="CNJ"||sym=="CNZC")
   if(sym=="CNZC")
   {
      posRoundAdj=0;
   }

   /*
   if(sym=="CNNI")
   {
      posRoundAdj=0;
   }
   */
   
   /*
   if(sym=="CNAG")
   {
     //posRoundAdj=0;
     posRoundAdj=int(posRoundAdj*0.75+0.5*sign(posRoundAdj));
   }
   */

   /*
   if(sym=="CNSM")
   {
      posRoundAdj=0;
   }
   */




   //set to zero temporalily
   //if(sym=="CNBU")
   //{
   //   posRoundAdj=0;
   //}
   // set NI to zero for CNY holiday
   //if(sym=="CNNI")
   //{
   //   posRoundAdj=0;
   //}



   //NI up over 50% due to war, abnormal, Mar 7, 2022

   //NI restarted 20220605
   //if(sym=="CNNI")
   //{
   //   posRoundAdj=0;
   //}

   //if(sym=="CNSR"||sym=="CNPP"||sym=="CNRU"||sym=="CNAU")
   //if(sym=="CNSR"||sym=="CNRU"||sym=="CNAU")
   //if(sym=="CNSR"||sym=="CNRU")
   // Ru allowed 2022/06/02
   //if(sym=="CNRU")
   //{
   //   posRoundAdj=0;
   //}


   //if(actStr == "bwt3" && sym=="CNFG") //LC asks to exit ZC/FG, 20211031
   //{
   //  posRoundAdj=0;
   //}

   /*
   if(sym=="CNSR") // 20230308, too high vol, reduce risk by half
   {
     posRoundAdj=int(posRoundAdj*0.667+0.5*sign(posRoundAdj));
   }
   */

   /*
   if(sym=="CNNI") // 
   {
     posRoundAdj=int(posRoundAdj*0.667+0.5*sign(posRoundAdj));
   }
   */

   /*
   if(sym=="CNJD") // 
   {
     posRoundAdj=int(posRoundAdj*0.5+0.5*sign(posRoundAdj));
   }
   */

   //tmrw is NFP, reduce risk by 1/3
   //posRoundAdj=int(posRoundAdj*0.667+0.5*sign(posRoundAdj));

   /*
   if(sym=="CNSM") // weak fcst, set to 1/2 risk, see 20230522 report
   {
     posRoundAdj=int(posRoundAdj*0.5+0.5*sign(posRoundAdj));
   }
   */


   /*
   if(sym=="CNSM") // 2024/05/17 set to zero, extreme price moves
   {
     posRoundAdj=0;
   }
   */

   /*
   if(sym=="CNSN") // Dec 27, 2023 large price rise
   {
     posRoundAdj=int(posRoundAdj*0.5+0.5*sign(posRoundAdj));
   }
   */


   /*   
   if(sym=="CNCF") // after large price rise
   {
     posRoundAdj=int(posRoundAdj*0.667+0.5*sign(posRoundAdj));
   }
   */



   //if(sym=="CNJ"||sym=="CNJM"||sym=="CNSF") // weak fcst, set to 1/2 risk, see 20230522 report
   //{
   //  posRoundAdj=0;
   //}


   //CVX_CHG_MULT
   //if cvxChg in top or bot 10%, set pos to 1/2
   double CVX_CHG_MULT_VAL=1;
   if(CVX_CHG_MULT==0)
   {
     //if(abs(posRoundAdj)==1) // if 1 lot, set to 0
      if(abs(posRoundAdj)==1 && FVOOD > 4000) // if 1 lot and big fvood, set to 0
      {
	  CVX_CHG_MULT_VAL=0;
	  posRoundAdj=0;
      }
      else  // else, set to 1/3
      {
	  // chg from 0.333 to 0.75
 	  CVX_CHG_MULT_VAL=0.4;//66;//0.5; //0.75
	  posRoundAdj=int(posRoundAdj*CVX_CHG_MULT_VAL+0.5*sign(posRoundAdj));
      }
   }

   /*
   if(sym=="CNSM"||sym=="CNSF") // set to zero to roll
   {
     posRoundAdj=0;
   }
   */

   
   //set everything to zero 2023/08/01
   //posRoundAdj=0;


   // for (int a=-20;a<=20;a++)
   // {
   //   cout<<"a= "<<a;
   //   //cout<<"  orig adj ="<<int(a*0.667+0.5)<<" "<<int(a*0.667+0.5*sign(a))<<endl;
   // }

   string SLDeltaStr="0";
   string SLType="NA";
   double SLDelta=0;
   //long=2.5 and short=1.75 cutoffs
   if(posRoundAdj>0)
   {
      SLDelta=-2.5*FVOO;
      SLDeltaStr=tostr(nearest_junf(0,SLDelta));
      SLType="SLSell";
   }
   else if(posRoundAdj< 0)
   {
      SLDelta=1.75*FVOO;
      SLDeltaStr=tostr(nearest_junf(0,SLDelta));
      SLType="SLBuy";
   }
   else
   {
      SLDelta=0;
      SLDeltaStr="0";
      SLType="NA";
   }

   double trades=optTradesNaive(prevPos,posRoundAdj);
   int tradesInt=int(trades);
   cout<<"LOG: "<<"prevPos="<<prevPos<<" prevFcst="<<prevFcst<<" trades="<<tradesInt<<endl;




   vector<string> vec=getTimeStampDateTimeVec();
   string tsDate=vec[0];
   string tsTime=vec[1];

   cout<<"Timestamp: "<<tsDate<<" "<<tsTime<<" ";
   cout<<todayDate<<" "
       <<sym
       <<" prePos= "<<prevPos
       <<" targetPos= "<<posRoundAdj
       <<" trades= "<<trades
       <<" absTrades= "<<abs(trades)
       <<" signTrades= "<<sign(trades)
       <<" fcst= "<<fcst
       <<" fcstNet= "<<fcstNet
       <<" tcost= "<<tcost         
       <<" FVOO= "<<FVOO
       <<" FVOOD= "<<FVOOD
       <<" pointValue= "<<pointValue
       <<" denom= "<<denom
       <<" fxRate= "<<exchangeRate
       <<" fxDate= "<<fxDate         
       <<" RPF= "<<RPF
       <<" RPFAdj= "<<RPF_ADJ
       <<" SYMMult= "<<SYM_MULT
       <<" ASSETMULT= "<<ASSET_MULT
       <<" NUDGEMULT= "<<NUDGE_MULT
       <<" targetPosRaw= "<<posRoundAdjRaw
       <<" MAXLOT_LONG= "<<MAX_LOT_LONG
       <<" MAXLOT_SHORT= "<<MAX_LOT_SHORT
       <<" isOptZA= "<<isOptZA
       <<" prevFcst= "<<prevFcst
       <<" manualAdjLot= "<<manualAdjLot
       <<" FVOO2= "<<FVOO2
       <<" FVOO2_MULT= "<<FVOO2_MULT
       <<" sizeX= "<<sizeX
       <<" AUM_NOW= "<<AUM_NOW
       <<" sizeY= "<<sizeY
       <<" fcstCutoffL= "<<FCST_CUTOFF_L
       <<" fcstCutoffH= "<<FCST_CUTOFF_H
       <<" DUR= "<<DUR
       <<" belowDUR= "<<belowDUR
       <<" MAX_DRISK_SYM= "<<MAX_DRISK_SYM
       <<" MAX_LOT_SYM= "<<MAX_LOT_SYM
       <<" sectorStr= "<<sectorStr
       <<" SECTTORMULT= "<<SECTOR_MULT
       <<" FVOODTOOHIGH= "<<FVOODTOOHIGH
       <<" HOLIDAYMULT= "<<HOLIDAY_MULT
       <<" fcstOrig= "<<fcstOrig
       <<" fvoo2Alpha= "<<alpha
       <<" FVOO2Shrink= "<<FVOO2Shrink
       <<" adjFcstByFvoo2= "<<adjFcstByFvoo2
       <<" NAV_FACTOR= "<<NAV_FACTOR
       <<" SLDelta= "<<SLDeltaStr
       <<" SLType= "<<SLType
       <<" isDCE= "<<isDCE
       <<" HOLIDAYMULTAFBI= "<<HOLIDAY_MULT_AFBI
       <<" netMgnAdjFactor= "<<netMgnAdjFactor
       <<" netMgnThresh= "<<netMgnThresh
       <<" netMgnAbs= "<<netMgnAbs
       <<" cvxChg= "<<cvxChg
       <<" CVX_CHG_MULT= "<<CVX_CHG_MULT  
       <<" CVX_CHG_MULT_VAL= "<<CVX_CHG_MULT_VAL  
       <<" isQube5bps= "<<isQube5bps
       <<" MKT_FVOO_ADJ="<<MKT_FVOO_ADJ
       <<" MAX_FCSTNET= "<<MAX_FCSTNET
       <<endl;


   return EXIT_SUCCESS;

}


/*
Chg log:

#2017/05/07
Entry algo is changed from 0.01 to 0.04


Current AssetMult:
       curr     new(as of 20170517)
stock  1.1       1.1*0.8= 0.88
VX     1                  0.88
bond   1.24      1.24*0.8=0.992
curr   0.8904    0.88*0.8=0.704
phy    1.24      1.24*0.9=1.12

*/





