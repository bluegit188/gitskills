#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <ctime>
#include <iostream>
#include <cstring>
#include <stdlib.h>

#include "DailyRTH.h"
#include "KSVM.h"
#include "NN.h"
#include "AssetSession.h"
#include "OO22t252Fcst.h"
#include "Dates.h"
#include "VXInds.h"
#include "KSVMD1.h"
#include "KSVMD2.h"
#include "KSVMF1.h"
#include "KNN.h"
#include "DF.h"
#include "Config.h"
#include "Tokenizer.h"
#include "DF.h"
#include "TW.h"
#include "SCDTW.h"
#include "NNN.h"
#include "NNN2D.h"
#include "NNN5D.h"


using namespace std;


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

/* usage
    string oldzone = changeTimeZone("US/New York");
    char* tzold;
    tzold=getenv("TZ");
    string a(tzold);
    cout<<"a="<<a<<endl;
    //change back
    changeTimeZone(oldzone);
*/


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

// this must be in main??
ostream & operator<< (ostream & out, const DailyRTHUnit & s)
{
    s.print(out);
    return out;
}


//execute a command with popen and returning its output:
char* exec(const char* command) {
  FILE* fp;
  char* line = NULL;
  // Following initialization is equivalent to char* result = ""; and just
  // initializes result to an empty string, only it works with
  // -Werror=write-strings and is so much less clear.
  char* result = (char*) calloc(1, 1);
  size_t len = 0;

  fflush(NULL);
  fp = popen(command, "r");
  if (fp == NULL) {
    printf("Cannot execute command:\n%s\n", command);
    return NULL;
  }

  while(getline(&line, &len, fp) != -1) {
    // +1 below to allow room for null terminator.
    result = (char*) realloc(result, strlen(result) + strlen(line) + 1);
    // +1 below so we copy the final null terminator.
    strncpy(result + strlen(result), line, strlen(line) + 1);
    free(line);
    line = NULL;
  }

  fflush(fp);
  if (pclose(fp) != 0) {
    perror("Cannot close stream.\n");
  }
  return result;
}



// checkExpDate
void checkExpDate(string filename)
{
   int to=getTodayDate();
   int tgt=201710228;

   int dif=dateDif(to,tgt);
   //cout<<"today="<<to<<" tgt="<<tgt<<" dif="<<dif<<endl;

   if(dif <= 5 && dif > 0)
   {

     //cout<< "dif<=5 now: "<<dif<<endl;
     char cmd[400];
     sprintf(cmd, "echo \"Code= %s, todayDate=%i tgtDate=%i dif=%i, expiring...\"|myAddHeader.sh \"Subject: code expiring\"  >/tmp/a;sendmail junfei.geng@gmail.com  < /tmp/a",filename.c_str(),to,tgt,dif);
     //cout<<string(cmd)<<endl;
     system(cmd);
   }

   if(dif<= 0)
   {
    //cout<< "dif<=0 now: "<<dif<<endl;
     char cmd[400];
     sprintf(cmd, "echo \"Code= %s, todayDate=%i tgtDate=%i dif=%i, deleting...\"|myAddHeader.sh \"Subject: code expired/deleted\"  >/tmp/a;sendmail junfei.geng@gmail.com  < /tmp/a",filename.c_str(),to,tgt,dif);
     //cout<<string(cmd)<<endl;
     system(cmd);

     // find out full name, and delete
     char cmd2[400];
     sprintf(cmd2, "which %s",filename.c_str());
     char* fullname;
     fullname=exec(cmd2);
     //cout<<"fullname="<<string(fullname)<<endl;
     //unlink(string(fullname).c_str());

     char cmd3[400];
     sprintf(cmd3, "rm -f %s",fullname);
     system(cmd3);
     exit(1);
   }

   return;
}


void load_cfile_and_DF_knn15agg(Config& cfile, DF& df, string sym, AssetSession &as)
{

   int DEBUG=0;
   string cfileName;

   // for IDX+BOND
   if(as.isStock()  || as.isBond() )
   {
       //knn15 for IB
       cfileName="/home/jgeng/transfer/Prod/config_knn15agg_cv.txt.IB";

       if( sym =="VX")
       {
	 //knn15 for IB
	 cfileName="/home/jgeng/transfer/Prod/config_knn15agg_cv.txt.IB";
       }

   }
   else if( as.isPhy())
   {
       //knn15 for phy
       cfileName="/home/jgeng/transfer/Prod/config_knn15_cv.txt.phy";
   }
   else if( as.isCurr())
   {

       //knn15 for all currs
       cfileName="/home/jgeng/transfer/Prod/config_knn15agg_cv.txt.curr";

   }
   else
   {
     
       //knn15 for IB
       cfileName="/home/jgeng/transfer/Prod/config_knn15agg_cv.txt.IB";
   }

   cfile.init(cfileName);
   if(DEBUG)
   {
     cfile.print();
   }

   ///////////////////////////////////
   /// load datafile into dataframe
   string dfile=cfile.getCU().dfile; //datafile
   int colDate=cfile.getCU().colDate; 
   int colSym=cfile.getCU().colSym; 
   vector<int> colYs=cfile.getCU().colYs;
   vector<int> colXs=cfile.getCU().colXs; //note colX starts from 1

   bool isSuccess=df.read(dfile, colDate, colSym, colYs, colXs);
   if(! isSuccess)
   {
     cerr<<"Error: reading file "<<dfile<<endl;
     exit(0);
   }
   if(DEBUG)
   {
     cout<<"No of obs for data= "<<df.size()<<endl;
   }

}   



void load_cfile_and_DF_knngo(Config& cfile, DF& df, string sym, AssetSession &as)
{

   int DEBUG=0;
   string cfileName;

   // for IDX+BOND
   if(as.isStock()  || as.isBond() || as.isCurr())
   {

       //knngo for IB
       cfileName="/home/jgeng/transfer/Prod/config_knngo_cv.txt.IBC";

       /*
       if( sym =="VX")
       {
	 //knngo for IB
	 cfileName="/home/jgeng/transfer/Prod/config_knngo_cv.txt.IBC";
       }
       */

   }
   else if( as.isPhy())
   {
       //knngo for phy
       cfileName="/home/jgeng/transfer/Prod/config_knngo_cv.txt.phyExMetal";

       // for certain phy syms, use IBC univ
       if(sym=="HG" ||sym=="GC"||sym=="SI"  ||sym=="BC" ||sym=="CL")
       {
	  cfileName="/home/jgeng/transfer/Prod/config_knngo_cv.txt.IBC";
       }

   }
   else
   {
     
       //knngo for IBC
        cfileName="/home/jgeng/transfer/Prod/config_knngo_cv.txt.IBC";
   }

   cfile.init(cfileName);
   if(DEBUG)
   {
     cfile.print();
   }

   ///////////////////////////////////
   /// load datafile into dataframe
   string dfile=cfile.getCU().dfile; //datafile
   int colDate=cfile.getCU().colDate; 
   int colSym=cfile.getCU().colSym; 
   vector<int> colYs=cfile.getCU().colYs;
   vector<int> colXs=cfile.getCU().colXs; //note colX starts from 1

   bool isSuccess=df.read(dfile, colDate, colSym, colYs, colXs);
   if(! isSuccess)
   {
     cerr<<"Error: reading file "<<dfile<<endl;
     exit(0);
   }
   if(DEBUG)
   {
     cout<<"No of obs for data= "<<df.size()<<endl;
   }

}   




void load_cfile_and_DF_knngoo3(Config& cfile, DF& df, string sym, AssetSession &as)
{

   int DEBUG=0;
   string cfileName;

   // for IDX+BOND
   if(as.isStock()  || as.isBond() || as.isCurr())
   {

       //knngoo3 for IB
       cfileName="/home/jgeng/transfer/Prod/config_knngoo3_cv.txt.IB";

       /*
       if( sym =="VX")
       {
	 //knngo for IB
	 cfileName="/home/jgeng/transfer/Prod/config_knngo_cv.txt.IBC";
       }
       */

   }
   else if( as.isPhy())
   {
       //knngoo3 for phy
        cfileName="/home/jgeng/transfer/Prod/config_knngoo3_cv.txt.IB";

   }
   else
   {
     
       //knngoo3 for IBC
       cfileName="/home/jgeng/transfer/Prod/config_knngoo3_cv.txt.IB";
   }

   cfile.init(cfileName);
   if(DEBUG)
   {
     cfile.print();
   }

   ///////////////////////////////////
   /// load datafile into dataframe
   string dfile=cfile.getCU().dfile; //datafile
   int colDate=cfile.getCU().colDate; 
   int colSym=cfile.getCU().colSym; 
   vector<int> colYs=cfile.getCU().colYs;
   vector<int> colXs=cfile.getCU().colXs; //note colX starts from 1

   bool isSuccess=df.read(dfile, colDate, colSym, colYs, colXs);
   if(! isSuccess)
   {
     cerr<<"Error: reading file "<<dfile<<endl;
     exit(0);
   }
   if(DEBUG)
   {
     cout<<"No of obs for data= "<<df.size()<<endl;
   }

}   





void load_cfile_and_DF_knngap(Config& cfile, DF& df, string sym, AssetSession &as)
{

   int DEBUG=0;
   string cfileName;

   // for IDX+BOND
   if(as.isStock()  || as.isBond() || as.isCurr())
   {

       //knngap for IB
       cfileName="/home/jgeng/transfer/Prod/config_knngap_cv.txt.all";

       /*
       if( sym =="VX")
       {
	 //knngo for IB
	 cfileName="/home/jgeng/transfer/Prod/config_knngo_cv.txt.IBC";
       }
       */

   }
   else if( as.isPhy())
   {
       //knngap for phy
       cfileName="/home/jgeng/transfer/Prod/config_knngap_cv.txt.all";

       /*
       // for certain phy syms, use IBC univ
       if(sym=="HG" ||sym=="GC"||sym=="SI"  ||sym=="BC" ||sym=="CL")
       {
	  cfileName="/home/jgeng/transfer/Prod/config_knngo_cv.txt.IBC";
       }
       */


   }
   else
   {
     
       //knngo for IBC
        cfileName="/home/jgeng/transfer/Prod/config_knngap_cv.txt.all";
   }

   cfile.init(cfileName);
   if(DEBUG)
   {
     cfile.print();
   }

   ///////////////////////////////////
   /// load datafile into dataframe
   string dfile=cfile.getCU().dfile; //datafile
   int colDate=cfile.getCU().colDate; 
   int colSym=cfile.getCU().colSym; 
   vector<int> colYs=cfile.getCU().colYs;
   vector<int> colXs=cfile.getCU().colXs; //note colX starts from 1

   bool isSuccess=df.read(dfile, colDate, colSym, colYs, colXs);
   if(! isSuccess)
   {
     cerr<<"Error: reading file "<<dfile<<endl;
     exit(0);
   }
   if(DEBUG)
   {
     cout<<"No of obs for data= "<<df.size()<<endl;
   }

}   





void load_cfile_and_DF_scd(Config& cfile, DF& df, string sym, AssetSession &as)
{

   int DEBUG=0;
   string cfileName;


   cfileName="/home/jgeng/transfer/Prod/config_edm_cv.txt.SCD";


   cfile.init(cfileName);
   if(DEBUG)
   {
     cfile.print();
   }

   ///////////////////////////////////
   /// load datafile into dataframe
   string dfile=cfile.getCU().dfile; //datafile
   int colDate=cfile.getCU().colDate; 
   int colSym=cfile.getCU().colSym; 
   vector<int> colYs=cfile.getCU().colYs;
   vector<int> colXs=cfile.getCU().colXs; //note colX starts from 1

   bool isSuccess=df.read(dfile, colDate, colSym, colYs, colXs);
   if(! isSuccess)
   {
     cerr<<"Error: reading file "<<dfile<<endl;
     exit(0);
   }
   if(DEBUG)
   {
     cout<<"No of obs for data= "<<df.size()<<endl;
   }

}   




int main (int argc, char ** argv)
{

   // open file named on the command-line for reading
   if (argc !=5 && argc !=6)
   {
       cerr << "usage: " << argv[0] << " <DATE> <SYM> <openPrice_raw> <spd> [opt: insertAtLast=1/0]" << endl; 
       cerr << "       Compute BT1 fcst (v95, 2018/10/08) for given symbol and date" << endl;
       cerr << "       spd=0 if no roll; on roll date, use spd=second-front at prev. close" << endl;
       cerr << "       then this spd is added to last cumSpd to get roll day's cumSprd" << endl;
       cerr << "       Optional: insertAtLast=1 by default, can be 0 to insert at any spots." << endl;
       exit(1);
   }

   int todayDate=atoi(argv[1]);
   string sym(argv[2]);
   double open=atof(argv[3]);
   double spd=atof(argv[4]);

   int isInsertAtLast=1;
   if(argc ==6)
   {
     isInsertAtLast=atoi(argv[5]);
   }


   checkExpDate(string(argv[0]));


   //cout<<todayDate<<" "<<sym<<" "<<open<<" "<<cumSpd<<endl;

   DailyRTH rth(sym);
   //rth.print();
   if(rth.size()<252*2)
   {
     cout<<"Warning: the history is less than 2 years old"<<endl;
   }

   cout<<"LOG: "<<sym<<" "<<todayDate<<" timestamp= "<<getTimeStampStr()<<endl;
   int preDate=rth[rth.size()-1].date;

   //last row before insert
   DailyRTHUnit duPre=rth[rth.size()-1];
   

   // add new date
   DailyRTHUnit du;

   // make some modifications
   du.sym=sym;
   du.date=todayDate;
   du.open=open;
   du.high=open;
   du.low=open;
   du.close=open;
   du.spd=spd;
   //du.cumSpd=cumSpd; //cumSpd will be corrected based on given spd

   du.contractYM="NA"; //not needed for now


   //bool isSuccess=rth.insertAtLast(du);
   bool isSuccess;
   if(isInsertAtLast)
   {
     isSuccess=rth.insertAtLast(du);
   }
   else
   {
     isSuccess=rth.insert(du);
   }

   if(!isSuccess)
   {
     exit(0);
   }
   //rth.print();

   int todayLoc=rth.findLocOfDate(todayDate);
   double cumSpd=rth[todayLoc].cumSpd; // this is corrected cumSpd

   Dates dater;
   /*
   vector<int> datesVec=dater.getBizDatesVecExUSHolidays(19800101,20200101);
   for(int i=0;i<datesVec.size();i++)
   {
     cout<<datesVec[i];
     int DOMB=dater.getDOMB(datesVec[i]);
     int DOMBB=dater.getDOMBB(datesVec[i]);
     cout<<" DOMB/B= "<<DOMB<<" "<<DOMBB<<endl;
   }
   */

   /////////// svm fcst ///////////////////////////////////
   string svmFile="/home/jgeng/transfer/Prod/SVMFile_20160201.txt";
   KSVM svm(svmFile);
   //svm.print();



   // OO22t252Fcst: V9 
   string OO22t252GridFile="/home/jgeng/transfer/Prod/LTGridNew_20170803.txt";
   OO22t252Fcst OO22t252FcstObj(OO22t252GridFile);
   //OO22t252FcstObj.print();

   AssetSession as;
   as.setSymbol(sym); // set current sym
   //as.print();
   //as.isPhy();


   int isPhy=as.isPhy();
   int isBond=as.isBond();
   int isStock=as.isStock();
   int isCurr=as.isCurr();

   //int isAmerica=as.isAmerica();
   int isAsia=as.isAsia();
   int isEurope=as.isEurope();

   int isEurIdx=0;
   if(isEurope==1 && isStock==1)
   {
     isEurIdx=1;
   }

   int isAsiaIdx=0;
   if(isAsia==1 && isStock==1)
   {
     isAsiaIdx=1;
   }


   int isNonAsiaIdx=0;
   if(isAsia==0 && isStock==1)
   {
     isNonAsiaIdx=1;
   }



   double svmFcst=svm.computeFcst(rth,todayDate,as);
   cout<<"LOG: SVM "<<todayDate<<" "<<sym<<" open= "<<open<<" Spd= "<<spd<<" cumSpd= "<<cumSpd<<" svmFcst= "<<svmFcst<<endl;


   // D1SVM
   string d1svmFile="/home/jgeng/transfer/Prod/SVMFile_D1SVM_20180404.txt";
   KSVMD1 d1svm(d1svmFile);
   double d1svmFcst=d1svm.computeFcst(rth,todayDate,as,dater);
   cout<<"LOG: D1SVM "<<todayDate<<" "<<sym<<" open= "<<open<<" Spd= "<<spd<<" cumSpd= "<<cumSpd<<" d1svmFcst= "<<d1svmFcst<<endl;


   // D2SVM
   string d2svmFile="/home/jgeng/transfer/Prod/SVMFile_D2SVM_20180404.txt";
   KSVMD2 d2svm(d2svmFile);
   double d2svmFcst=d2svm.computeFcst(rth,todayDate,as,dater);
   cout<<"LOG: D2SVM "<<todayDate<<" "<<sym<<" open= "<<open<<" Spd= "<<spd<<" cumSpd= "<<cumSpd<<" d2svmFcst= "<<d2svmFcst<<endl;



   // F1SVM
   string f1svmFile="/home/jgeng/transfer/Prod/SVMFile_F1SVM_20180404.txt";
   KSVMF1 f1svm(f1svmFile);
   double f1svmFcst=f1svm.computeFcst(rth,todayDate,as,dater);
   cout<<"LOG: F1SVM "<<todayDate<<" "<<sym<<" open= "<<open<<" Spd= "<<spd<<" cumSpd= "<<cumSpd<<" f1svmFcst= "<<f1svmFcst<<endl;



   /////////// nn fcst ///////////////////////////////////
   NN nn;
   double nnFcst=nn.computeFcst(rth,todayDate,as);
   cout<<"LOG: NN "<<todayDate<<" "<<sym<<" open= "<<open<<" Spd= "<<spd<<" cumSpd= "<<cumSpd<<" nnFcst= "<<nnFcst<<endl;




   /////////// nnn fcst ///////////////////////////////////
   NNN nnn;
   double nnnFcst=nnn.computeFcst(rth,todayDate,as);
   cout<<"LOG: NNN "<<todayDate<<" "<<sym<<" open= "<<open<<" Spd= "<<spd<<" cumSpd= "<<cumSpd<<" nnnFcst= "<<nnnFcst<<endl;



   /////////// nnn2D fcst ///////////////////////////////////
   NNN2D nnn2D;
   double nnn2DFcst=nnn2D.computeFcst(rth,todayDate,as);
   cout<<"LOG: NNN2D "<<todayDate<<" "<<sym<<" open= "<<open<<" Spd= "<<spd<<" cumSpd= "<<cumSpd<<" nnn2DFcst= "<<nnn2DFcst<<endl;

  /////////// nnn5D fcst ///////////////////////////////////
   NNN5D nnn5D;
   double nnn5DFcst=nnn5D.computeFcst(rth,todayDate,as);
   cout<<"LOG: NNN5D "<<todayDate<<" "<<sym<<" open= "<<open<<" Spd= "<<spd<<" cumSpd= "<<cumSpd<<" nnn5DFcst= "<<nnn5DFcst<<endl;


   nnnFcst=constrain(nnnFcst,-0.13,0.13);   
   nnn2DFcst=constrain(nnn2DFcst,-0.3,0.3);   
   nnn5DFcst=constrain(nnn5DFcst,-0.5,0.5);   



   /////// oo22t252Fcst: spline smoother /////////
   double fcstLTSS=0;
   double OO22t252N=0;

   //TWN price history is too short for this indicator
   if(sym != "TWN")
   {
       fcstLTSS=OO22t252FcstObj.computeFcst(rth,todayDate,dater);
       OO22t252N=OO22t252FcstObj.getCurOO22t252N();
   }

   //cout<<"LOG_MAIN: OO22t252Fcst "<<todayDate<<" "<<sym<<" open= "<<open<<" Spd= "<<spd<<" cumSpd= "<<cumSpd<<" OO22t252Fcst= "<<fcstLTSS<<endl;


   DailyRTH rthDX("DX"); //for curr fcst, for knn use
    //rthDX.print();

   /////////////
   //knn15agg
   Config cfile3;
   DF df3;
   load_cfile_and_DF_knn15agg(cfile3,df3,sym,as); // load corresponding model/datafile based on sym/asset

   int isVerbose=0;
   KNN knn15agg(df3,cfile3,rthDX, isVerbose);

   int KNN_TYPE=3;
   YhatUnit yu3=knn15agg.computeFcst(rth,todayDate,as,dater,KNN_TYPE,0);
   double knn15aggFcst=yu3.yhats[0];
   double knn15aggFcstStd=yu3.stds[0];

   double knn15aggFcstOC=yu3.yhats[1];
   double knn15aggFcstCO=yu3.yhats[2];
   double knn15aggFcstD2=yu3.yhats[3];

   double knn15aggFcst3D=yu3.yhats[4];

   cout<<"LOG: KNNAGGFcst "<<todayDate<<" "<<sym<<" open= "<<open<<" Spd= "<<spd<<" cumSpd= "<<cumSpd<<" knn15Fcst= "<<knn15aggFcst<<" knn15FcstaggStd= "<<knn15aggFcstStd<<" knn15aggFcstOC= "<<knn15aggFcstOC<<" knn15aggFcstCO= "<<knn15aggFcstCO<<" knn15aggFcstD2= "<<knn15aggFcstD2<<" knn15aggFcst3D= "<<knn15aggFcst3D<<endl;




   /////////////
   //knngo
   Config cfile5;
   DF df5;
   load_cfile_and_DF_knngo(cfile5,df5,sym,as); // load corresponding model/datafile based on sym/asset

   KNN knngo(df5,cfile5, rthDX, isVerbose);

   KNN_TYPE=5;
   YhatUnit yu5=knngo.computeFcst(rth,todayDate,as,dater,KNN_TYPE,0);
   double knngoFcst=yu5.yhats[0];
   double knngoFcstStd=yu5.stds[0];

   double knngoFcstOC=yu5.yhats[1];
   double knngoFcstCO=yu5.yhats[2];
   double knngoFcstD2=yu5.yhats[3];

   double knngoFcst3D=yu5.yhats[4];

   cout<<"LOG: KNNGOFcst "<<todayDate<<" "<<sym<<" open= "<<open<<" Spd= "<<spd<<" cumSpd= "<<cumSpd<<" knngoFcst= "<<knngoFcst<<" knngoFcstStd= "<<knngoFcstStd<<" knngoFcstOC= "<<knngoFcstOC<<" knngoFcstCO= "<<knngoFcstCO<<" knngoFcstD2= "<<knngoFcstD2<<" knngoFcst3D= "<<knngoFcst3D<<endl;


   /////////////
   //knngoo3
   Config cfile51;
   DF df51;
   load_cfile_and_DF_knngoo3(cfile51,df51,sym,as); // load corresponding model/datafile based on sym/asset

   KNN knngoo3(df51,cfile51, rthDX, isVerbose);

   KNN_TYPE=51;
   YhatUnit yu51=knngoo3.computeFcst(rth,todayDate,as,dater,KNN_TYPE, constrain(knngoFcst,-0.12,0.12));
   double knngoo3Fcst=yu51.yhats[0];
   double knngoo3FcstStd=yu51.stds[0];

   double knngoo3FcstOC=yu51.yhats[1];
   double knngoo3FcstCO=yu51.yhats[2];
   double knngoo3FcstD2=yu51.yhats[3];

   double knngoo3Fcst3D=yu51.yhats[4];

   cout<<"LOG: KNNGOO3Fcst "<<todayDate<<" "<<sym<<" open= "<<open<<" Spd= "<<spd<<" cumSpd= "<<cumSpd<<" knngoo3Fcst= "<<knngoo3Fcst<<" knngoo3FcstStd= "<<knngoo3FcstStd<<" knngoo3FcstOC= "<<knngoo3FcstOC<<" knngoo3FcstCO= "<<knngoo3FcstCO<<" knngoo3FcstD2= "<<knngoo3FcstD2<<" knngoo3Fcst3D= "<<knngoo3Fcst3D<<endl;



   /////////////
   //knngap
   Config cfile6;
   DF df6;
   load_cfile_and_DF_knngap(cfile6,df6,sym,as); // load corresponding model/datafile based on sym/asset

   KNN knngap(df6,cfile6, rthDX, isVerbose);

   KNN_TYPE=6;
   YhatUnit yu6=knngap.computeFcst(rth,todayDate,as,dater,KNN_TYPE,0);
   double knngapFcst=yu6.yhats[0];
   double knngapFcstStd=yu6.stds[0];

   double knngapFcstOC=yu6.yhats[1];
   double knngapFcstCO=yu6.yhats[2];
   double knngapFcstD2=yu6.yhats[3];

   double knngapFcst3D=yu6.yhats[4];

   cout<<"LOG: KNNGAPFcst "<<todayDate<<" "<<sym<<" open= "<<open<<" Spd= "<<spd<<" cumSpd= "<<cumSpd<<" knngapFcst= "<<knngapFcst<<" knngapFcstStd= "<<knngapFcstStd<<" knngapFcstOC= "<<knngapFcstOC<<" knngapFcstCO= "<<knngapFcstCO<<" knngapFcstD2= "<<knngapFcstD2<<" knngapFcst3D= "<<knngapFcst3D<<endl;


   /////////////
   //scd: sakoe-chiba band
   Config cfile7;
   DF df7;
   load_cfile_and_DF_scd(cfile7,df7,sym,as); // load corresponding model/datafile based on sym/asset

   TW tw(df7,cfile7, isVerbose);

      
   int DIST_TYPE=4;
   YhatUnit2 yu7=tw.computeFcst(rth,todayDate,as,dater,DIST_TYPE);


   double scdFcstStd=yu7.stds[0];

   //if std is 0, set to 1
   if(scdFcstStd==0)
   {
     scdFcstStd=1.0;
   }
   double scdFcst=yu7.yhats[0]/scdFcstStd;

   // I'll scale oc/co fcsts by ooF1D's std, see 20190310 report
   double scdFcstOC=yu7.yhats[1]/scdFcstStd;
   double scdFcstCO=yu7.yhats[2]/scdFcstStd;
   double scdFcstD2=yu7.yhats[3]/scdFcstStd;
   double scdFcst2D=yu7.yhats[4]/scdFcstStd;
   double scdFcst3D=yu7.yhats[5]/scdFcstStd;

   double scdFcstD3=scdFcst3D-scdFcst-scdFcstD2;

   cout<<"LOG: SCDFcst "<<todayDate<<" "<<sym<<" open= "<<open<<" Spd= "<<spd<<" cumSpd= "<<cumSpd<<" scdFcst= "<<scdFcst<<" scdFcstStd= "<<scdFcstStd<<" scdFcstOC= "<<scdFcstOC<<" scdFcstCO= "<<scdFcstCO<<" scdFcstD2= "<<scdFcstD2<<" scdFcst2D= "<<scdFcst2D<<" scdFcst3D= "<<scdFcst3D<<" scdFcstD3= "<<scdFcstD3<<endl;





   //output a few ooP1Ds
   double OO1=rth.getOOP1D(todayLoc);
   double OO2=rth.getOOP1D(todayLoc-1);
   double OO3=rth.getOOP1D(todayLoc-2);
   double OO4=rth.getOOP1D(todayLoc-3);
   double OO5=rth.getOOP1D(todayLoc-4);
   double GAP=rth.getGAP(todayLoc);
   double GAP2=rth.getGAP(todayLoc-1);
   double YOC=rth.getYOC(todayLoc);

   double AEMAOO=rth.getAEMAOO(todayLoc);
   double AEO2=rth.getAEMAOO2(todayLoc);
   double OO7t20=rth.getOO7t20(todayLoc);

   double OOMA26t40=rth.getOO26t40(todayLoc)/15;
   double OOMA7t40=rth.getOO7t40(todayLoc)/34;
   double OOMA7t40Adj=rth.getOO7t40Adj(todayLoc)/29;


   cout<<"LOG: OO1/2/3/4/5= "<<OO1<<" "<<OO2<<" "<<OO3<<" "<<OO4<<" "<<OO5<<endl;

   cout<<"LOG: lastRow before insert= "<<duPre<<endl;
   cout<<"LOG: lastRow after insert= "<<rth[int(rth.size()-1)]<<endl;
    
   int dateDist=dateDif(preDate, todayDate);
   cout<<"LOG: DateDif= "<<dateDist<<" preDate: "<<preDate<<" today: "<<todayDate<<endl;

  

   svmFcst=constrain(svmFcst,-0.32,0.39);
   nnFcst=constrain(nnFcst,-0.18,0.22);   



   //knn15Fcst=constrain(knn15Fcst,-0.12,0.12);   
   
   //knn15ooFcst=constrain(knn15ooFcst,-0.12,0.12);   
   
   knn15aggFcst=constrain(knn15aggFcst,-0.12,0.12);   

   knngoFcst=constrain(knngoFcst,-0.12,0.12);   

   knngoo3Fcst=constrain(knngoo3Fcst,-0.12,0.12);   



   knngapFcst=constrain(knngapFcst,-0.12,0.12);   

   scdFcst=constrain(scdFcst,-0.12,0.15);   

   scdFcstD2=constrain(scdFcstD2,-0.15,0.15);   
   scdFcstD3=constrain(scdFcstD3,-0.15,0.15);   


   double svmFcstRaw=svmFcst;
   // for non phy, replace svmFcst by svmFcst*AEMAOO
   // see 20180627 report
   if(!isPhy )
   {
      svmFcst= (svmFcst*(AEMAOO/0.266)/1.8);
      svmFcst=constrain(svmFcst,-0.28,0.4);
   }


   double bt1Fcst=0.0044172+ 0.365242*svmFcst+0.43664*nnFcst;
   bt1Fcst=constrain(bt1Fcst,-0.2,0.22);
   double bt1FcstDM=bt1Fcst-0.01; // this V2 fcst, used as input for v9
   double bt1DMV2=bt1FcstDM;


   d1svmFcst=constrain(d1svmFcst,-0.33,0.43);
   d2svmFcst=constrain(d2svmFcst,-0.25,0.25);
   f1svmFcst=constrain(f1svmFcst,-0.3,0.4);
   //D1SVM: -0.33 0.43
   //D2SVM: -0.25 0.25
   //F1SVM: -0.27 0.37

   /* V9

(Intercept)                                            -0.008387   0.003143  -2.669  0.00761 ** 
BT1FcstDMV2                                             0.990029   0.047486  20.849  < 2e-16 ***
fcstLTSSJF:isNonMOY3t8                                  1.052283   0.163438   6.438 1.21e-10 ***
fcstLTSSJF:isDec                                        0.441199   0.369367   1.194  0.23230    
GAP.1:isPhy:isNonMon                                    0.096754   0.009438  10.252  < 2e-16 ***
BT1FcstDMV2:isBond:isTue                               -0.623189   0.232532  -2.680  0.00736 ** 
BT1FcstDMV2:isBond:isMon:ifelse(BT1FcstDMV2 > 0, 1, 0)  1.002176   0.317376   3.158  0.00159 ** 
GAP.1:isBond:isMon:ifelse(GAP.1 < 0, 1, 0)             -0.202514   0.040431  -5.009 5.48e-07 ***
   */

   int DOW=dater.getDOWFast(todayDate);
   int isMon=0;
   if(DOW==1)
   {
     isMon=1;
   }
   int isTue=0;
   if(DOW==2)
   {
     isTue=1;
   }

   int isFri=0;
   if(DOW==5)
   {
     isFri=1;
   }

   int isNonMon=0;
   if(DOW!=1)
   {
     isNonMon=1;
   }

   GAP=constrain(GAP,-2,2);

   int MOY=dater.getMOY(todayDate);
   int isDec=0;
   if(MOY==12)
   {
     isDec=1;
   }
   int isNonMOY3t8=0;
   if(MOY < 3 || MOY > 8)
   {
     isNonMOY3t8=1;
   }

   int isBT1DMPos=0;
   if(bt1FcstDM >0)
   {
     isBT1DMPos=1;
   }
   int isGapNeg=0;
   if(GAP <0 )
   {
     isGapNeg=1;
   }


   double knngapFcstAdj=knngapFcst*((DOW == 1)? -0.5:1);


   double bt1FcstV9 = -0.008387
                      +bt1FcstDM*0.990029
                      +fcstLTSS*isNonMOY3t8*1.052283 //Feb 27, added x2, removed 
                      +fcstLTSS*isDec*0.441199
                      //+GAP*isPhy*isNonMon* 0.096754
                      //+GAP*isPhy*((DOW == 1)? 0.5:1)* 0.096754
                      +constrain(GAP,-1.3,1.3)*isPhy*isGapNeg*0.056
                      +constrain(GAP,-1.3,1.3)*isPhy*(1-isGapNeg)*((DOW == 5)? 1.4:1)* 0.056 // see 20180727 report, 20181005
                      //+bt1FcstDM*isBond*isTue*(-0.623189) //removed, Feb 5, 2018
                      // added x0.5 multipler on bond:mon, Jan 9, 2018
                      // added x0.2 multipler on bond:mon, Feb 5, 2018
                      +bt1FcstDM*isBond*isMon*isBT1DMPos*1.002176*0.2
                      +GAP*isBond*isMon*isGapNeg*( -0.202514)*0.2;

   bt1FcstV9=constrain(bt1FcstV9,-0.3,0.3);
   double bt1FcstV9DM=bt1FcstV9-0.007 +0.006; //add back 0.006, see 20180611


   // V91 model
   //

   double isNonIdxCurr=0;
   if( isStock==0 && isCurr==0)
   {
     isNonIdxCurr=1;
   }

   int isHG=0;
   if(sym == "HG")
   {
     isHG=1;
   }



   double comboFcstOrigExIdxCurr = -0.008387
                                   +bt1FcstDM*0.990029*isNonIdxCurr
                                   +fcstLTSS*isNonMOY3t8*1.052283 
                                   +fcstLTSS*isDec*0.441199
                                   +fcstLTSS*(1-isNonMOY3t8)*((fcstLTSS > 0)? 1:0)*0.4 // see 20180723 report
                                  //+GAP*isPhy*isNonMon* 0.096754
                                   +constrain(GAP,-1.3,1.3)*isPhy*isGapNeg*(1-isHG)*0.056
                                   +constrain(GAP,-1.3,1.3)*isPhy*(1-isGapNeg)*((DOW == 5)? 1.4:1)*(1-isHG)* 0.056 // see 20180727, 20181004 report
                                   //+bt1FcstDM*isBond*isTue*(-0.623189) //removed, Feb 5, 2018
                                   // added x0.5 multipler on bond:mon, Jan 9, 2018
                                   // added x0.2 multipler on bond:mon, Feb 5, 2018
                                   +bt1FcstDM*isBond*isMon*isBT1DMPos*1.002176*0.2
                                   +GAP*isBond*isMon*isGapNeg*( -0.202514)*0.2;

   //added MOY3t8 fcstLTSS at 0.5 wgt// removed
   comboFcstOrigExIdxCurr+= fcstLTSS*(1-isNonMOY3t8)*1.052283*0; 



    double fcstLTCombo=   fcstLTSS*isNonMOY3t8*1.052283 
                          +fcstLTSS*isDec*0.441199
                          +fcstLTSS*(1-isNonMOY3t8)*1.052283*0.5*0;
 
    double YHC=rth.getYHC(todayLoc);
    double HC2=rth.getYHC(todayLoc-1);
    double HC3=rth.getYHC(todayLoc-2);
    double HC4=rth.getYHC(todayLoc-3);

    double HCAvg=(YHC+HC2+HC3+HC4)/4;
    double HCAvgAbs=constrain(abs(HCAvg),0,1.5);


    double YLC=rth.getYLC(todayLoc);
    double LC2=rth.getYLC(todayLoc-1);
    double LC3=rth.getYLC(todayLoc-2);
    double LC4=rth.getYLC(todayLoc-3);

    double LCAvg=(YLC+LC2+LC3+LC4)/4;
    double LCAvgAbs=constrain(abs(LCAvg),0,1.5);

    int DOWIdxWgt=1;
    if(DOW==2){DOWIdxWgt=2;}
    if(DOW==5){DOWIdxWgt=0;}



    ///////////////////////////
    // indicator related to SP
    DailyRTH rthES("SP");
    //rthES.print();
    if(rthES.size()<252*2)
    {
      cout<<"Warning: the ES history is less than 2 years old"<<endl;
    }
    int locMRecentES=rthES.findLocOfMRecentDateEx(todayDate);

    double ESCC1=0;
    double ES2t15NAbs=0;
    double ESCC1x2t15Abs=0;
    int MRecentDateES=-1;
    int bizDateDifES=-999;

    if( locMRecentES !=-1)
    {
        MRecentDateES=rthES[locMRecentES].date;
        bizDateDifES=dater.bizDateDif(MRecentDateES, todayDate);
        //cout<<"LOG: DateDif= "<<dateDist<<" preDate: "<<preDate<<" today: "<<todayDate<<endl;
	if(bizDateDifES ==1 )
	{
	   vector<double> CCs;
	   for(unsigned int i=0;i<15;i++)
	   {
	     double x=rthES.getCCP1DNoLag(locMRecentES-i,-3,3);
	     if(x==NA_DBL )
	     {
	       cerr<<"Error: One of the CCs is NA"<<endl;
	       exit(1);
	     }
	     CCs.push_back(x);
	   }

	   ESCC1=CCs[0];
	   double ESCC2t15=vectorSubsetSum(CCs,1,14);
	   ES2t15NAbs=constrain(abs(ESCC2t15)/2.681,0,3);
	   ESCC1x2t15Abs=constrain(ESCC1*ES2t15NAbs,-4.5,4.5);
        }
    }




    ///////////////////////////
    // indicator related to VX
    DailyRTH rthVX("VX");
    //rthVX.print();
    if(rthVX.size()<252*2)
    {
      cout<<"Warning: the VX history is less than 2 years old"<<endl;
    }




    int locMRecentVX=rthVX.findLocOfMRecentDateEx(todayDate);
    double VXNow=-1;
    double VXRatio=-1;
    int MRecentDateVX=-1;
    int bizDateDifVX=-999;

    double vxCCEmaEx1=0;

    if( locMRecentVX !=-1)
    {
        MRecentDateVX=rthVX[locMRecentVX].date;
        bizDateDifVX=dater.bizDateDif(MRecentDateVX, todayDate);
        //cout<<"LOG: DateDif= "<<dateDist<<" preDate: "<<preDate<<" today: "<<todayDate<<endl;
	if(bizDateDifVX ==1 )
	{
	   vector<double> closes;
	   for(unsigned int i=0;i<252;i++)
	   {
	     double x=rthVX.getCloseNoLag(locMRecentVX-i);
	     if(x==NA_DBL )
	     {
	       cerr<<"Error: One of the closes is NA"<<endl;
	       exit(1);
	     }
	     closes.push_back(x);
	   }

	   VXNow=closes[0];
	   double VXMA=vectorSubsetSum(closes,0,251)/252;
           //cout<<"VXNow= "<<VXNow<<" VXMA="<<VXMA<<endl;
	   VXRatio=VXNow/VXMA;



           //compute vxCCEmaEx1
	   vector<double> CCs;
	   for(unsigned int i=504;i>=2;i--)
	   {
	     double x=rthVX.getCCP1DNoLag(locMRecentVX-i,-5,5); //yesterday excluded
	     if(x==NA_DBL )
	     {
	       cerr<<"Error: One of the CCs is NA"<<endl;
	       exit(1);
	     }
	     CCs.push_back(x);
	   }

	   vxCCEmaEx1=vectorEma(CCs,0.92);
	   vxCCEmaEx1=constrain(vxCCEmaEx1,-0.4,0.5);


        }
    }





   /* V91
-- final BT1 V91 model, a mix of OLS and MS coefs.
  final       OLS         MS        avg
  0.008560   0.008560  0.0147767  0.0116684 (Intercept)
  1.130108   1.130108  1.21099    1.17055   comboFcstOrigExIdxCurr 
 *0.6365118  1.203296  0.6365118  0.919904  bt1DMV2:isCurrency:ifelse(bt1DMV2 < 0, 1.65, 0.55)
  0.091170   0.091170  0.1291486  0.110159  isCurrency:I(YHC * HCAvgAbs):ifelse(DOW >= 3, 1, 0)   
 *0.0522149  0.078888  0.0255417  0.0522149 ifelse(DOW >= 3, 1, 0):isIndex:GAP.2   
 *0.4439025  0.706452  0.4439025  0.575177  bt1DMV2:isIndex:DOWIdxWgt:ifelse(bt1DMV2 > 0, 0.6, 1.5)  
*-0.0380713 -0.062708 -0.0134346 -0.0380713 isIndex:ES.CC.1:ES2t15NAbs:ifelse(DOW <= 3, 1, 0):ifelse((-ES.CC.1) > 0, 0.4, 1) 
Note: * means coef is difference from OLS.
# interceptAdjusted= 0.008560  -0.002247 = 0.006313


regdata$comboFcstOrigExIdxCurr =  -0.008387 + bt1DMV2*ifelse(ASSET != "Currency" & ASSET != "Index", 1, 0) * 0.990029   +fcstLTSS*isNonMOY3t8    *  1.052283   +fcstLTSS*isDec * ( 0.44119 ) +GAP*isPhy*isNonMon *   0.096754 +bt1DMV2*isBond*isTue * (-0.623189 )  +bt1DMV2*isBond*isMon*ifelse(bt1DMV2 > 0, 1, 0) *  1.002176  +GAP*isBond*isMon*ifelse(GAP < 0, 1, 0) * (-0.202514);


   */


	  /* roll back some over optimization
regdata$comboFcstV91New = 0.008560 + regdata$comboFcstOrigExIdxCurr* 1.130108+ bt1DMV2*isCurrency*ifelse(bt1DMV2 < 0, 1.65, 0.55)*0.5+ isCurrency*I(YHC * HCAvgAbs)*ifelse(DOW >= 2, 1, 0)*  0.091170+  ifelse(DOW >= 3, 1, 0)*isIndex*GAP.2* 0.0522149+ bt1DMV2*isIndex*1*ifelse(bt1DMV2 > 0, 1, 1) *0.667  + fcstLTSS*isMOY3t8  * 1.052283*0.5 
#+ isIndex*ES.CC.1*ES2t15NAbs*ifelse(DOW <= 4, 1, 0)*ifelse((-ES.CC.1) > 0, 1, 1) *( -0.0380713 )*0
	  */

    double bt1FcstV91 = 0.003933//0.008560
                       + comboFcstOrigExIdxCurr*1.130108
                       //+ bt1DMV2*isCurr*((bt1DMV2 < 0) ? 1.65:0.55)*0.5
                       + bt1DMV2*isCurr*((bt1DMV2 < 0) ? 1:0.4)*1.05 // modified Jan 08, 2018
                       + isCurr*YHC * HCAvgAbs*((DOW >= 2)? 1:0)*0.091170*0.5 //modified 20180611
                       + ((DOW >= 3)? 1: 0)*isStock*GAP2*0.0522149*0.33 //reduce to 0.33 Feb 10, 2018 
                       //+ bt1DMV2*isStock*1*((bt1DMV2 > 0)? 1:1)*0.667
                       //+ bt1DMV2*isStock*1*((bt1DMV2 > 0)? 0.85:1)*0.667*1.25 // modified Jan 30, 2018
	               + bt1DMV2*isStock*1*((bt1DMV2 > 0)? 0.85:1) // remove x0.737 factor above, move to riskMult, 20180606
                       //+ 0*isStock*ESCC1*ES2t15NAbs*((DOW <= 5)? 1:0)*(((-ESCC1)>0)? 1:1)*(-0.0380713);
                       -0.0164392*isStock*constrain(ESCC1,-2,0); //see 20180822 report


    //if(isStock==1){bt1FcstV91+=0.12;}
    //if(sym =="CL"|| sym=="BC"){bt1FcstV91+=0.05;}


   bt1FcstV91=constrain(bt1FcstV91,-0.2,0.2);
   double bt1FcstV91DM=bt1FcstV91-0.004+0.006; // add back 0.006, see 20180611

   // some diagonosis terms
   double fcstComboExIdxCurr=comboFcstOrigExIdxCurr*1.130108;
   //double fcstBT1V2CurrAdj = bt1DMV2*isCurr*((bt1DMV2 < 0) ? 1.65:0.55)*0.5;
   double fcstBT1V2CurrAdj = bt1DMV2*isCurr*((bt1DMV2 < 0) ? 1:0.4)*1.05;
   double fcstYHCCurr= isCurr*YHC * HCAvgAbs*((DOW >= 2)? 1:0)*0.091170;
   double fcstIdxGAP2= ((DOW >= 3)? 1: 0)*isStock*GAP2*0.0522149*0.33; //reduce to 0.33 Feb 10, 2018 
   //double fcstBT1V2IdxAdj= bt1DMV2*isStock*1*((bt1DMV2 > 0)? 1:1)*0.667;
   double fcstBT1V2IdxAdj= bt1DMV2*isStock*1*((bt1DMV2 > 0)? 0.85:1)*0.667*1.25; 
   double fcstESCC1Idx= isStock*ESCC1*ES2t15NAbs*((DOW <= 5)? 1:0)*(((-ESCC1)>0)? 1:1)*(-0.0380713);



   if(sym == "LEU" || sym == "ED" || sym == "S" ||  sym == "HS")
   {
     bt1FcstV91DM=0;
   }


   //  double VXRatio=0;
   //VXRatio=1.29; // as of Feb 05, 2018
   double VXReduc=1;//0.6 is default; 
   if(VXRatio >=1.25 && (isStock==1 || sym =="CL"|| sym=="BC" || sym =="EC"|| sym=="CD" ) ) // drop Idx and CL/BC wgt only for now, Feb 10, 2018; add CD/EC, see Feb 13 study
   {
     VXReduc=0.8;
     bt1FcstV91DM=bt1FcstV91DM*VXReduc;
   }

   if(isStock && sym != "VX")
   {
     bt1FcstV91DM=constrain(bt1FcstV91DM,-0.2,0.09); // blind constraint
   }

      //regdata$fcstSTW=  0.003058+regdata$bt1FcstDM*0.903582+regdata$GAP*0.141889+regdata$GAP2*0.060823+regdata$ESCC1*regdata$ES2t15NAbs*( -0.062032)
   double stwFcstAdj=0;
   double stwFcstAdj2=0;
   if(sym == "STW" )
   {
     stwFcstAdj=0.1418*GAP+0.06082*GAP2+(-0.06203)*ESCC1*ES2t15NAbs;
     //see 20200213 and 14  report
     stwFcstAdj2=0.1574*GAP*((DOW != 2)? 1:0)+(-0.0829)*ESCC1*ES2t15NAbs*((DOW != 1)? 1:0);
     stwFcstAdj2=constrain(stwFcstAdj2,-0.25,0.25);
     bt1FcstV91DM= bt1FcstV91DM*0.9035+0.5*stwFcstAdj;
   }




   ///////////////////////
   // VX fcst
   ///////////////////////
   double ctgDifAvg=0;
   int MRecentDateCtg=-1;
   double DTR=0;
   double vxFcst=0;
   if(sym == "VX" )
   {
     //bt1FcstV91DM=0.14;


     VXInds vxi;
     //vxi.printCtgs();
     //vxi.printDTRs();

     // get DTR
     int locDTR=vxi.findLocDTR(todayDate);
     //double DTR=0;
     if(locDTR != -1)
     {
       DTR=vxi.getDTRByLoc(locDTR);
     }


     //get ctgDifAvg
     int locMRecentCtg=vxi.findLocOfMRecentDateExCtg(todayDate);
     //int MRecentDateCtg=-1;
     int bizDateDifCtg=-999;

     //double ctgDifAvg=0;

     if( locMRecentCtg !=-1)
     {
        MRecentDateCtg=vxi.getCtgDateByLoc(locMRecentCtg);
        bizDateDifCtg=dater.bizDateDif(MRecentDateCtg, todayDate);
        //cout<<"LOG: DateDif= "<<dateDist<<" preDate: "<<preDate<<" today: "<<todayDate<<endl;
	if(bizDateDifCtg <= 3 )
	{
	  ctgDifAvg=vxi.getCtgByLoc(locMRecentCtg);
        }
     }

     // fcst v3
     //regdata$VXFcstMS.v3=0.06+ -0.0077703 -0.00555*constrain(I(regdata$F1.portara - 20), -20, 20)-0.0236869*constrain(regdata$ctgDifAvg, -10, 10)+0.0301647*constrain(regdata$vxGAP, -3, 3) +(-0.00)*ifelse(regdata$DTR >= 5 & regdata$DTR < 15, 1, 0)+(-0.1) *ifelse(regdata$DTR >= 15, 1, 0)
     // fcst v4.B
     //regdata$VXFcstMS.v4B=0.04+( -0.0136302)-0.0053364*constrain(I(regdata$F1.portara - 20), -20, 20)-0.0217813*constrain(regdata$ctgDifAvg, -10, 10)+0.0198477*constrain(regdata$vxGAP, -3, 3) + (-0.00)*ifelse(regdata$DTR >= 5 & regdata$DTR < 15, 1, 0)+(-0.0738118) *ifelse(regdata$DTR >= 15, 1, 0)  

     vxFcst= 0.04 + (-0.013630)
                  - 0.0053364*constrain((open - 20), -20, 20)
                  - 0.0217813*constrain(ctgDifAvg, -10, 10)
                  + 0.0198477*constrain(GAP, -3, 3) //vxGAP
                  + (-0.0738118) *((DTR  >= 15)?1:0.333);
     vxFcst=constrain(vxFcst,-0.25,0.2);
     bt1FcstV91DM=vxFcst;

   }




   //risky symbols, use vxCCEmaEx1
   if(sym =="CL"|| sym=="BC" || sym =="EC"|| sym=="CD" || sym=="HG"  )
   {
       bt1FcstV91DM=bt1FcstV91DM-0.098*vxCCEmaEx1;
   }



   // see 20180605 report
   // see 20180626, change OO1 to GAP
   double OO1IdxFcst=0;
   double OO1AEMAIdxFcst=0;

   OO1IdxFcst=  0.08*GAP;
   OO1AEMAIdxFcst= -0.12*constrain(GAP*AEMAOO,-1.5,1.5);

   if(isStock==1 &&  isEurope ==0 && sym != "VX") // nonEur stocks, exclude VX
   {
	 // betas: 0.0909/1.24=0.07330645, -0.1972/1.24=-0.1590323
         // refited model

	 bt1FcstV91DM+=0.66*(OO1IdxFcst+OO1AEMAIdxFcst);
	 bt1FcstV91DM=constrain(bt1FcstV91DM,-0.2,0.09);
   }



   /*
4:                                    OO1:ifelse(ASSET4 == "Index", 1, 0):ifelse(SESSION != "Europe", 1, 0)  0.0696007
5:     ifelse(ASSET4 == "Index", 1, 0):ifelse(SESSION != "Europe", 1, 0):constrain(OO1 * AEMAOO, -1.5, 1.5) -0.1350182 # stcok
6:                                OO1:ifelse(ASSET4 == "Financial", 1, 0):ifelse(SESSION == "Europe", 1, 0)  0.0905781
7: constrain(OO1 * AEMAOO, -1.5, 1.5):ifelse(ASSET4 == "Financial", 1, 0):ifelse(SESSION == "Europe", 1, 0) -0.2160145 # bond
   */

   // see 20180605 report
   double OO1BondFcst=0;
   double OO1AEMABondFcst=0;
   OO1BondFcst=  0.08*GAP;
   OO1AEMABondFcst= -0.2*constrain(GAP*AEMAOO,-1.5,1.5);

   int isEurBond=0;

   if(isBond==1 &&  isEurope ==1 ) // eurBonds
   {
         isEurBond=1;
         // refited model, use the same coefs as stocks

	 bt1FcstV91DM+=0.66*(OO1BondFcst+OO1AEMABondFcst);
	 bt1FcstV91DM=constrain(bt1FcstV91DM,-0.2,0.2);
   }




   if(sym == "KC" ||sym == "SB" )
   {
      bt1FcstV91DM=constrain(bt1FcstV91DM,-0.15,0.15); // see 20180606 report
   }


   if(sym != "VX")
   {
     bt1FcstV91DM+=0.005; // see 20180503 report
   }




   // for V92 fcst

   //regdata$svmFcst2=0.540963*(regdata$d1svmFcst+regdata$f1svmFcst)/2+0.3*regdata$d2svmFcst
   //regdata$svmFcst2=ifelse(regdata$ASSET4 == "Currency",0.45*regdata$d2svmFcst,regdata$svmFcst2)
   //regdata$bt1FcstDMV92=(0.96*regdata$bt1FcstDM+0.44*regdata$svmFcst2)

   double wf1=0.5;
   double wd1=0.5;
   if(isStock && sym != "VX")
   {
     wf1=0.7;
     wd1=0.3;
   }
   double svmFcst2=0.540963*(wf1*f1svmFcst+wd1*d1svmFcst)+0.3*d2svmFcst;
   if(isCurr)
   {
     svmFcst2=0.5*d2svmFcst;
   }
   svmFcst2= constrain(svmFcst2,-0.2,0.2);


   double bt1FcstV92DM=0.96*bt1FcstV91DM+0.44*svmFcst2;


   if(isPhy) // don't change phy too much
   {
       bt1FcstV92DM=0.96*bt1FcstV91DM+0.33*0.44*svmFcst2; //changed from 0.5 to 0.33, 20180808
   }



   if(isBond) // add more V2 wgt to bond
   {
      double svmFcstC=constrain(svmFcst,-0.25,0.25);
      //0.65 is to size svmFcst to same std as V91
      bt1FcstV92DM=0.96*(bt1FcstV91DM+0.65*svmFcstC)/2+0.44*svmFcst2;
   }

   if(isCurr) // add more V2 wgt to curr
   {
      bt1FcstV92DM=0.96*(0.3*bt1FcstV91DM+0.7*bt1DMV2)+0.44*svmFcst2;
   }

   bt1FcstV92DM= constrain(bt1FcstV92DM,-0.2,0.2);

   //deal with special symbols
   if(sym == "VX")
   {
     bt1FcstV92DM=vxFcst;
   }
   if(sym == "LEU" || sym == "ED" || sym == "S" ||  sym == "HS")
   {
     bt1FcstV92DM=0;
   }
   if(isStock && sym != "VX")
   {
     //if(DOW==5)
     //{
     //  bt1FcstV92DM=bt1FcstV92DM*0.5; // see 20180904 report
     //}
     bt1FcstV92DM=constrain(bt1FcstV92DM,-0.2,0.09); // blind constraint
   }
   if(sym == "KC" ||sym == "SB" )
   {
      bt1FcstV92DM=constrain(bt1FcstV92DM,-0.15,0.15); // see 20180606 report
   }


   /*
   double hgFcstAdj=0; // see 20180728
   if(sym == "HG" )
   {
     double OC2=OO2-GAP2;
     OC2=constrain(OC2,-2,2);
     double OC=OO1-GAP;
     OC=constrain(OC,-2,2);
     hgFcstAdj=0.013856
               +0.039108 *OC2 
               -0.112894*isMon
               -0.100813*OC*((OC < 0)? 1:0.5);
     hgFcstAdj=constrain(hgFcstAdj,-0.2,0.2);
     bt1FcstV92DM= bt1FcstV92DM*0.636108+hgFcstAdj*0.787912;
   }
   */
   

   double OC2=OO2-GAP2;
   //hgFcstAdj, see 20180830 report, this needs to exit at close
   double hgFcstAdj=0; // see 20180728
   if(sym == "HG" )
   {

     OC2=constrain(OC2,-2,2);
     double OC=OO1-GAP;
     OC=constrain(OC,-2,2);
     hgFcstAdj=-0.04114
               +0.039108 *OC2 
               +0.18570 *GAP 
               -0.54958 *constrain(GAP*AEMAOO,-1.5,1.5)
               -0.14554*OC*((OC < 0)? 1:0);
     hgFcstAdj=constrain(hgFcstAdj*0.85,-0.2,0.2); //x0.85 is from cvFcst
     bt1FcstV92DM= bt1FcstV92DM*0.311+hgFcstAdj*0.725;
     bt1FcstV92DM=constrain( bt1FcstV92DM,-0.15,0.15);
   }


    // see 20180808
   if(sym == "KC" )
   {
     bt1FcstV92DM= bt1FcstV92DM*0.53+0.1*GAP*(GAP < 0? 1:0);
     bt1FcstV92DM=constrain( bt1FcstV92DM,-0.15,0.15);
   }

   // see 20180808
   if(sym == "SB" )
   {
     bt1FcstV92DM= bt1FcstV92DM*0.6+0.4*constrain(svmFcst,-0.15,0.15);
     bt1FcstV92DM=constrain( bt1FcstV92DM,-0.15,0.15);
   }


   bt1FcstV92DM=constrain( bt1FcstV92DM,-0.165,0.165);





   /////////////////////////////////////////////////
   //// V95 fcsts
   //////////////////////////////////////////

   double bt1FcstV95DM=bt1FcstV92DM;


  double f1svmFcstNew=f1svmFcst;
  if(sym=="LFT"|| sym=="SNI")
  {
    f1svmFcstNew=svmFcst;
  }
  if(sym =="STW")
  {
    f1svmFcstNew=stwFcstAdj;
  }

  // see 20181231 report
  //regdata$SYM=="JY" |regdata$SYM=="TY"|regdata$SYM=="US"|regdata$SYM=="CGB"|regdata$SYM=="BC"|regdata$SYM=="SNI"|regdata$SYM=="STW"|regdata$SYM=="LC"|regdata$SYM=="NQ"|regdata$SYM=="C" ,1,0 )
  // in fact, nnFcst on all univ seem to be ok too, so inlcude as much as possible for now
  int isNNSelect=0;
  if(  sym=="JY"|| sym=="EC" 
      ||sym=="TY"||sym=="US"||sym=="CGB"
      ||sym=="ESX"||sym=="DAX"||sym=="SNI"||sym=="STW"||sym=="NQ"
      ||sym=="BC"||sym=="CL"||sym=="C"||sym=="W"||sym=="KC"||sym=="CT" ||sym=="LC"||sym=="GC"||sym=="SB")
  {
     isNNSelect=1;
  }






/*
# stock model
Coefficients:
                           Estimate Std. Error t value Pr(>|t|)    
(Intercept)                -0.03556    0.01128  -3.152 0.001623 ** 
f1svmFcstNew                0.45453    0.09384   4.844 1.29e-06 ***
knn15aggFcst                0.27376    0.18376   1.490 0.136295    
knngoFcst                   0.74143    0.19953   3.716 0.000203 ***
knn15aggFcstD2              0.21715    0.18755   1.158 0.246935    
ifelse(MMDD >= 1216, 1, 0)  0.22876    0.04575   5.000 5.80e-07 ***
ifelse(DD == 1, 1, 0)       0.11123    0.05017   2.217 0.026627 *  
---
Signif. codes:  0 -F¡***¢ 0.001 ¡**¢ 0.01 ¡*¢ 0.05 ¡.¢ 0.1 ¡ ¢ 1-A

Residual standard error: 1.033 on 15258 degrees of freedom
Multiple R-squared:  0.007416,  Adjusted R-squared:  0.007026 
F-statistic:    19 on 6 and 15258 DF,  p-value: < 2.2e-16


regdata$fcstIdx= -0.02646+0.007 +regdata$f1svmFcstNew*0.43080*1.3+ regdata$knn15aggFcst*0.25637+regdata$knngoFcst * 0.92376*0.33+regdata$knn15aggFcstD2*0.18951

# f1 beta= ( 0.44069*15258+ 0.92058*5347)/(15258+5347)= 0.5652215


 summary(regdata$fcstIdx)
    Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
-0.41213 -0.02188  0.01287  0.01145  0.04626  0.31513 

 sd(regdata$fcstIdx)
[1] 0.06944715

ifelse(DD == 1, 1, 0):ifelse(OO7t20 > 0.5 & OO7t20 < 4.5, 1, 0)  0.273687   0.080158   3.414 0.000641 ***
ifelse(DD >= 2 & DD <= 7, 1, 0):f1svmFcst                       -0.456169   0.199602  -2.285 0.022303 *  



# stock model 2

#pre
                                                   Estimate Std. Error t value Pr(>|t|)    
(Intercept)                                       -0.022509   0.009418  -2.390 0.016865 *  
f1svmFcst                                          0.438482   0.093619   4.684 2.84e-06 ***
knngoFcst                                          0.749998   0.198981   3.769 0.000164 ***
svmFcst:ifelse(SYM == "LFT" | SYM == "SNI", 1, 0)  0.278560   0.155376   1.793 0.073023 .  
stwFcstAdj                                         0.987678   0.271378   3.639 0.000274 ***

OO1:ifelse(DD >= 2 & DD <= 7, 1, 0)                0.026316   0.019143   1.375 0.169240  
ifelse(MMDD >= 1216, 1, 0)                         0.226887   0.045734   4.961 7.09e-07 ***
ifelse(DD == 1, 1, 0):OO7t20UP                     0.267992   0.080164   3.343 0.000831 ***
  
---
Signif. codes:  0 ~***~ 0.001 ~**~ 0.01 ~*~ 0.05 ~.~ 0.1 ~ ~ 1

Residual standard error: 1.033 on 15257 degrees of freedom
Multiple R-squared:  0.008278,  Adjusted R-squared:  0.007823 
F-statistic: 18.19 on 7 and 15257 DF,  p-value: < 2.2e-16

summary(fit2$fitted)
    Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
-0.72560 -0.03299  0.01053  0.01622  0.05306  0.70056 

 sd(fit2$fitted)
[1] 0.09430868




*/



   int DOM=dater.getDOM(todayDate);
   int DOMB=dater.getDOMB(todayDate);
   int DEC=(MOY ==12) ? 1:0;

   int DOM2t7=(DOM>=2 && DOM <=7)?1:0;

   //make them consistent
   if(DOMB==1 && DOM2t7==1)
   {
      DOM2t7=0;
   }


   // stock fcst
   if(isStock && sym != "VX")
   {

     /*

       if(!isAsia)
       {
	   //#nonAsia
	 bt1FcstV95DM=0.53*0.5*f1svmFcst+0.28*0.5*d1svmFcst+0.4*0.75*knn15aggFcst+0.5*0.5*knn15aggFcstD2;
       }

       if(isAsia)
       {
	   //#Asia
	   bt1FcstV95DM= 0.53*bt1DMV2+0.28*0.5*d1svmFcst+0.4*0.75*knn15aggFcst+0.5*0.5*knn15aggFcstD2;
	   if(sym =="STW")
	   {
	     bt1FcstV95DM+=0.5*stwFcstAdj;
	   }
       }
     */
     /*
       if(sym=="ESX"|| sym=="NQ"||sym=="ES"||sym=="DAX")
       {
	 bt1FcstV95DM=0.9*0.5*f1svmFcst+0.2*0.75*knn15aggFcst+0.25*0.25*knn15aggFcstD2;
       }

       if(sym=="LFT"|| sym=="SNI")
       {
	   bt1FcstV95DM= 0.6*svmFcst+0.2*0.75*knn15aggFcst+0.25*0.5*knn15aggFcstD2;

       }
       if(sym =="STW")
       {
	   bt1FcstV95DM= 0.5*stwFcstAdj+0.25*0.5*knn15aggFcstD2;
       }
     */

     /*
       bt1FcstV95DM=  -0.0246 +0.007
                      + 1.3*0.45453*f1svmFcst //up wgt due to higher in post
	              //- 0.5*0.3*f1svmFcstNew*DOM2t7 //see 2018/12/07 report
	              + 0.0263*OO1*DOM2t7 //see 2018/12/11 report
	              //+ 0.27376*knn15aggFcst
                      + 0.5*0.74143*knngoFcst
	              //+ 0.21715*knn15aggFcstD2          
	              + 0.03*DEC*(DOM >= 16?1:0) 
	              + 0.03*(DOMB ==1?1:0)*((OO7t20 >=0.5 && OO7t20< 4.5)?1:0) ;
     */

       bt1FcstV95DM=  -0.021                   // see 20190104 report for intercept issue
                      + 1.4*0.45453*f1svmFcst*(sym!="STW"?1:0) //up wgt due to higher in post, f1 bad for STW
                      + 0.4*0.74143*knngoFcst
	              + 0.2785*svmFcst*((sym=="LFT"||sym=="SNI")?1:0)
                      + 0.98*stwFcstAdj
	              + 0.0263*OO1*DOM2t7 //see 2018/12/11 report
	              + 0.03*DEC*(DOM >= 16?1:0) *0.5
	              + 0.03*(DOMB ==1?1:0)*((OO7t20 >=0.5 && OO7t20< 4.5)?1:0) 
                      +0.4*isNNSelect*nnFcst;

       bt1FcstV95DM=bt1FcstV95DM*0.85;
       bt1FcstV95DM=constrain(bt1FcstV95DM,-0.12,0.1);
   }



  /*
--bond model 3
regdata$OO1D=regdata$OO1*ifelse(regdata$OO1<0,1,0)
regdata$OO1U=regdata$OO1*ifelse(regdata$OO1>0,1,0)

# pre

                            Estimate Std. Error t value Pr(>|t|)    
(Intercept)                  0.08392    0.01420   5.910 3.51e-09 ***
svmFcst                      0.60694    0.11179   5.429 5.76e-08 ***
f1svmFcst                    0.23516    0.10261   2.292  0.02194 *  
OO1D:ifelse(DOW != 1, 1, 0)  0.13433    0.01881   7.141 9.76e-13 ***
OO1U                        -0.05584    0.01717  -3.251  0.00115 ** 
OO1D:ifelse(DOW == 1, 1, 0) -0.08460    0.02928  -2.889  0.00387 ** 
---
Signif. codes:  0 ~***~ 0.001 ~**~ 0.01 ~*~ 0.05 ~.~ 0.1 ~ ~ 1

Residual standard error: 0.9849 on 13340 degrees of freedom
Multiple R-squared:  0.009645,  Adjusted R-squared:  0.009274 
F-statistic: 25.98 on 5 and 13340 DF,  p-value: < 2.2e-16

ifelse(DD >= 24, 1, 0):ifelse(MM != 12, 1, 0)  0.09612    0.02037   4.720 2.38e-06 ***

> summary(fit2$fitted)
     Min.   1st Qu.    Median      Mean   3rd Qu.      Max. 
-0.409058  0.003712  0.053989  0.049794  0.094539  0.686689 
> sd(fit2$fitted)
[1] 0.09717992

a). (-0.02361*OO1U+0.01): when OO1 is up
similarly:
b). -0.136*OO1D:ifelse(DOW == 1, 1, 0) -0.008 when OO1 is down and Monday
c).  0.12476* OO1D:ifelse(DOW != 1, 1, 0) + 0.029726 when OO1 is down and nonMonday

> summary(-0.05584*regdata$OO1U)
     Min.   1st Qu.    Median      Mean   3rd Qu.      Max.
-0.167520 -0.037340 -0.004031 -0.022583  0.000000  0.000000

> summary( I(regdata$OO1D)*ifelse(regdata$DOW != 1, 1, 0) * 0.13433)
    Min.  1st Qu.   Median     Mean  3rd Qu.     Max.
-0.40299 -0.05380  0.00000 -0.03786  0.00000  0.00000

> summary(I(regdata$OO1D)*ifelse(regdata$DOW == 1, 1, 0) *(-0.08460))
    Min.  1st Qu.   Median     Mean  3rd Qu.     Max.
0.000000 0.000000 0.000000 0.006155 0.000000 0.253800


  */

   double GAPD=GAP<0?GAP:0;
   double GAPU=GAP>=0?GAP:0;
   double OO1D=OO1<0?OO1:0;
   double OO1U=OO1>=0?OO1:0;

   double YOCD=YOC<0?YOC:0;
   double YOCU=YOC>=0?YOC:0;

   //bond fcst
   if(isBond )
   {

         // see 20190104 for motivation of separating fcst components 1/2/3 out
	 double fc1= - 0.05*constrain(OO1U,-2,2);
         double fc2= 0.67*0.134*constrain(OO1D,-2,2)*(1-isMon); //reduce 1/3
	 double fc3= - 0.085*constrain(OO1D,-2,2)*isMon;

	 if(abs(fc1) > 0)
	 {
	   fc1+=0.02;
	 }
	 if(abs(fc2)> 0)
	 {
	   fc2+=0.025;
	 }

	 if(abs(fc3)> 0)
	 {
	   fc3-=0.01;
	 }

         bt1FcstV95DM=  0.049 -0.029 // bond mean 0.02, see 20190104 report
                      + 0.25*f1svmFcst
                      + 0.606*svmFcst
	              //+ 0.16*knn15aggFcst
	              //+ 0.326*knn15aggFcstD2
	              //- 0.05* constrain(GAPD,-1,0)*isMon;
                      + fc1
                      + fc2
                      + fc3
	              + 0.03*(DOM>=24?1:0)*(MOY!=12?1:0)
                      + 0.4*isNNSelect*nnFcst;

       bt1FcstV95DM=bt1FcstV95DM*0.85;
       bt1FcstV95DM=constrain(bt1FcstV95DM,-0.1,0.16);
   }



  /*
# curr model 4/5
added YHC for JY

                                      Estimate Std. Error t value Pr(>|t|)
(Intercept)                           -0.01640    0.01063  -1.542  0.12313
GAP                                   -0.03445    0.02005  -1.718  0.08582 .
svmFcstRaw:ifelse(DOW == 2, 0.33, 1)   0.42963    0.10950   3.924 8.77e-05 ***
svmFcstRaw:ifelse(SYM == "DXE", 1, 0) -0.26589    0.21956  -1.211  0.22593
ifelse(SYM == "DXE", 1, 0):f1svmFcst   0.27183    0.23941   1.135  0.25623
fcstYHCCurr:ifelse(SYM == "JY", 1, 0)  1.25055    0.40378   3.097  0.00196 **
---
Signif. codes:  0 ~***~ 0.001 ~**~ 0.01 ~*~ 0.05 ~.~ 0.1 ~ ~ 1

Residual standard error: 0.9906 on 11296 degrees of freedom
Multiple R-squared:  0.003076,  Adjusted R-squared:  0.002635
F-statistic: 6.972 on 5 and 11296 DF,  p-value: 1.642e-06

nnFcst:ifelse(SYM == "JY", 1, 0)       0.30748    0.31968   0.962 0.336149 # see 2018/12/31 report


 summary(fit2$fitted)
     Min.   1st Qu.    Median      Mean   3rd Qu.      Max. 
-0.637974 -0.031050 -0.006016 -0.007529  0.018925  0.220056 
  */




   //curr fcst, 20181105
   if(isCurr )
   {
     /*
     double tmpFcst1=   -0.005
                      + 0.25 * svmFcstRaw
                      + bt1FcstV92DM
                      + 0.6*fcstYHCCurr;

     double tmpFcst2= -0.02 
                      + 1 * knn15aggFcst 
                      + 1 * knn15aggFcstD2 
                      + 1 * (knn15aggFcst3D - knn15aggFcst - knn15aggFcstD2);

     bt1FcstV95DM= 0.85*(0.5*tmpFcst1+0.5*tmpFcst2);
     bt1FcstV95DM=constrain(bt1FcstV95DM,-0.12,0.12);
     */

     //added 20181130

       bt1FcstV95DM=  -0.01640 + 0.014
                      -0.03445*GAP*(sym =="DX"||sym =="EC"?1:0)
                      + 0.42963*svmFcstRaw*(DOW==2?0.33:1)
                      - 0.26589*svmFcstRaw*(sym =="DX"?1:0)
	              + 0.27183 *f1svmFcst*(sym =="DX"||sym =="EC"?1:0)
                      //+ 1.250*0.5*fcstYHCCurr*(sym =="JY"?1:0); //see 20181130 note, could be overfitting
	              //+ 0.30748*nnFcst*(sym =="JY"?1:0) //see 20181231 note
                      +0.3*isNNSelect*nnFcst;

       bt1FcstV95DM=constrain(bt1FcstV95DM,-0.12,0.12);


   }

   /*
# phy model 2

#pre


Coefficients:
                                           Estimate Std. Error t value Pr(>|t|)    
(Intercept)                               -0.021123   0.006768  -3.121 0.001804 ** 
knngoFcst                                  0.624820   0.136070   4.592 4.41e-06 ***
svmFcst                                    0.621701   0.069043   9.005  < 2e-16 ***
GAP                                        0.069808   0.012582   5.548 2.91e-08 ***
knn15aggFcstD2                             0.467056   0.143264   3.260 0.001115 ** 
svmFcst:ifelse(DOW == 2, 1, 0)            -0.500812   0.133521  -3.751 0.000177 *** // to -0.4
GAP:ifelse(DOW == 1, 1, 0):isCLBCHGGC     -0.185878   0.041937  -4.432 9.36e-06 ***
svmFcst:ifelse(DOW == 1, 1, 0):isCLBCKCSB -0.475373   0.198309  -2.397 0.016531 *  
---
Signif. codes:  0 -F¡***¢ 0.001 ¡**¢ 0.01 ¡*¢ 0.05 ¡.¢ 0.1 ¡ ¢ 1-A

Residual standard error: 1.004 on 24487 degrees of freedom
Multiple R-squared:  0.01027,   Adjusted R-squared:  0.009985 
F-statistic: 36.29 on 7 and 24487 DF,  p-value: < 2.2e-16
(-0.500812 *24487  -0.15751* 8365)/(24487 +8365)
[1] -0.4133981
> summary(fit2$fitted)
     Min.   1st Qu.    Median      Mean   3rd Qu.      Max. 
-0.433934 -0.068870 -0.002173 -0.006455  0.059400  0.558938 

sd(fit2$fitted)
[1] 0.1022713



# phy model 2.1, 

# remove go and aggD2 for now, 
# svm:tue is not that strong: clear in pre, not so much post

# pre

                                          Estimate Std. Error t value Pr(>|t|)    
(Intercept)                               -0.00969    0.00643  -1.507 0.131818    
svmFcst                                    0.73475    0.06497  11.309  < 2e-16 ***
GAP                                        0.08405    0.01228   6.847 7.72e-12 ***
svmFcst:ifelse(DOW == 2, 1, 0)            -0.47691    0.13351  -3.572 0.000355 ***
GAP:ifelse(DOW == 1, 1, 0):isCLBCHGGC     -0.22021    0.04147  -5.309 1.11e-07 ***
svmFcst:ifelse(DOW == 1, 1, 0):isCLBCKCSB -0.51266    0.19818  -2.587 0.009691 ** 
---
Signif. codes:  0 ~***~ 0.001 ~**~ 0.01 ~*~ 0.05 ~.~ 0.1 ~ ~ 1

Residual standard error: 1.005 on 24489 degrees of freedom
Multiple R-squared:  0.008933,  Adjusted R-squared:  0.00873 
F-statistic: 44.14 on 5 and 24489 DF,  p-value: < 2.2e-16

> summary(fit2$fitted)
     Min.   1st Qu.    Median      Mean   3rd Qu.      Max. 
-0.412914 -0.062011 -0.004453 -0.006455  0.051574  0.549182 



*/

      int isCLBCHGGC=0;
      if(sym=="CL"|| sym=="BC"||sym=="HG"||sym=="GC")
      {
	isCLBCHGGC=1;
      }

      int isCLBCKCSB=0;
      if(sym=="CL"|| sym=="BC"||sym=="KC"||sym=="SB")
      {
	isCLBCKCSB=1;
      }


   // phy fcst
   if(isPhy )
   {

      bt1FcstV95DM= -0.00969+0.006455
	            //+0.667*0.6248*knngoFcst //reduce 1/3
                    +0.735*svmFcst 
                    +0.6*0.0841*GAP
	            //+0.467*knn15aggFcstD2 
	            -0.5*0.477*svmFcst*(DOW == 2?1:0) //reduced 1/2
	            -0.667*0.22*GAP*isCLBCHGGC*(DOW == 1?1:0) //reduce 1/3
                    -0.513*svmFcst*isCLBCKCSB*(DOW == 1?1:0)
	            +0.3*isNNSelect*nnFcst;

      //cout<<"what="<<bt1FcstV95DM<<endl;


      // add this temporarily for GC/HG, 20190220
      //if(sym=="HG"|| sym=="GC")
      //{
      //bt1FcstV95DM= 0.5*bt1FcstV95DM +0.5*d2svmFcst;
      //}



      bt1FcstV95DM=constrain(0.85*bt1FcstV95DM,-0.14,0.14);
   }


   //see rep.txt.20181028
   double vxFcstNew=vxFcst;
   if(sym == "VX") //vxFcst
   {
      vxFcstNew= 0.6*vxFcst 
	         + 0.2* svmFcstRaw
	         +0.026*ES2t15NAbs
	         +0.58*knn15aggFcst
	         +0.4*knn15aggFcstD2;

     vxFcstNew=constrain(vxFcstNew,-0.14,0.1);
     //bt1FcstV95DM=vxFcstNew;
   }



   /*
regdata$fcstVX3=0.0008781+1.2*0.3559512*regdata$f1svmFcst+0.2657143*regdata$svmFcst+0.0160121*regdata$OO7t20

>  summary(regdata$fcstVX3)
    Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
-0.28175 -0.07881 -0.03209 -0.02142  0.01920  0.45056 
   */

   //see rep.txt.20181125
   double vxFcstNew2=0;
   if(sym == "VX") //vxFcst
   {
      vxFcstNew2=  0.0008781
                  +1.2*0.3559512*f1svmFcst
                  +0.2657143*svmFcst
	          +0.75*0.0160121*OO7t20;
      vxFcstNew2=constrain(vxFcstNew2,-0.14,0.1);
      bt1FcstV95DM=vxFcstNew2;
   }



   //VXReduc for extreme risk increases
   if(VXRatio >=1.25 && (( isStock==1 && sym !="VX") || sym =="CL"|| sym=="BC" || sym =="EC"|| sym=="CD" ) ) // drop Idx and CL/BC wgt only for now, Feb 10, 2018; add CD/EC, see Feb 13 study
   {
     VXReduc=0.85;
     bt1FcstV95DM=bt1FcstV95DM*VXReduc;
   }





   /// -------  V96 models
     /*
(Intercept)                   -0.03805    0.00465  -8.181 2.86e-16 ***
svmnnFcst                      0.72304    0.06574  10.998  < 2e-16 ***
d2svmFcst                      0.07092    0.05367   1.321  0.18639    
knngoFcst                      0.50986    0.08569   5.950 2.69e-09 ***
scdFcst                        0.27422    0.09248   2.965  0.00303 ** 
scdFcstD2                      0.68120    0.12788   5.327 1.00e-07 ***
scdFcstD3                      0.31640    0.12148   2.605  0.00920 ** 
knngapFcst.v2                  0.43498    0.08569   5.076 3.86e-07 ***
I(svmnnFcst * isBond * isTue) -1.51594    0.27535  -5.505 3.69e-08 ***


## B). best ZA methods
$SMCoefs
                       indicator       coef
1:                   (Intercept) -0.0406177
2:                     svmnnFcst  0.6123545
3:                     knngoFcst  0.6399196
4:                       scdFcst  0.1322455
5:                     scdFcstD2  0.9826826
6:                     scdFcstD3  0.2753151
7:                 knngapFcst.v2   0.472159
8: I(svmnnFcst * isBond * isTue) -1.4947015



              indicator      coef
1:          (Intercept) 0.0003395
2:               fcstZA 0.9720922
3:     GAP2:isTue:isPhy 0.1605817
4: GAP:isCLBCHGGC:isMon -0.145701


     */


    //  2020/10/07 stockFcsts
    //    OO2Fcst     *  0.333*0.78426
    //    OO3Fcst     *  0.333*1.00492
    //    OO7t20xFcst *  0.333*0.52839;
  
    // downward trending stromg
    double OO2Fcst= 0.02019 +  0.14215* constrain(OO2, -1, 1)*(OO2 < 0?1:0.25)*isEurope;
    double OO3Fcst= 0.008128  + 0.074798* constrain(OO3, -1.5, 1.5)*(DOW != 1? 1:-0.5);
    double OO7t20xFcst=  0.022249 + 0.017931* OO7t20*(OO7t20 < 0? 1: 0.333);




   double svmnnFcst=-0.0034942+0.5411356*svmFcst+0.320045*nnFcst;
    //# added Mar 3, 2020
   svmnnFcst= constrain(svmnnFcst,-0.2,0.2);


   // see 2020/10/16 study on make bonds tigher for svm and nn
   double svmrawnnFcst=-0.0034942+0.5411356*svmFcstRaw+0.320045*nnFcst;
   svmrawnnFcst= constrain(svmrawnnFcst,-0.1,0.1);


  //ver 1
   double bt1V96OLS = -0.03805
                         +0.72304* svmnnFcst
                         +0.07092*d2svmFcst                    
                         +0.50986* knngoFcst                    
                         +0.27422* scdFcst                     
                         +0.68120* scdFcstD2                   
                         +0.31640*scdFcstD3                     
                         +0.43498* knngapFcst    
                         //-1.51594*svmnnFcst*isBond * isTue;// see Mar 03, 2020 report
                         -0.72304*0.667*svmnnFcst*isBond * isTue;

   bt1V96OLS=bt1V96OLS*0.9;
   bt1V96OLS=constrain(bt1V96OLS,-0.16,0.16);

   //ver 2, ZAFcst, for comparison purpose
   double bt1V96ZA = -0.0406177
                         + 0.6123545* svmnnFcst
                         + 0.6399196* knngoFcst                    
                         + 0.132245* scdFcst                     
                         + 0.9826826* scdFcstD2                   
                         + 0.2753151*scdFcstD3                     
                         + 0.472159* knngapFcst               
                        - 0.6123545*0.667*svmnnFcst*isBond * isTue;

   bt1V96ZA=bt1V96ZA*0.9;
   bt1V96ZA=constrain(bt1V96ZA,-0.16,0.16);


    
   //ver 3, ZAFcst adj
   /*
   double bt1FcstV96DM = -0.0406177
                         + 0.8*0.6123545* svmnnFcst
                         + 0.6399196* knngoFcst                    
                         + 0.3306125* scdFcst  // see 20190813 report on adj= 2.5*0.132245                   
                         + 0.9826826* scdFcstD2                   
                         + 0.2753151*scdFcstD3                     
                         + 0.472159* knngapFcst               
                         - 0.667*1.4947015*svmnnFcst*isBond * isTue //reduce 1/3
                         // extra
                         +0.5*0.1606*constrain(GAP2,-1.8,1.8)*isPhy*(DOW == 2?1:0) //reduce 1/2
                         -0.5*0.1457*constrain(GAP,-1.8,1.8)*isCLBCHGGC*(DOW == 1?1:0); //reduce 1/2

   */

   /* accurate as of Nov 8, 2020
   double bt1FcstV96DM = -0.0406177
                         + 0.8*0.6123545* svmrawnnFcst
                         + 0.6399196* knngoFcst                    
                         + 0.3306125* scdFcst  // see 20190813 report on adj= 2.5*0.132245                   
                         + 0.9826826* scdFcstD2                   
                         + (1.667*0.2753151)*scdFcstD3  //see 20200827 report, wgt up 67%        
                         + 0.472159* knngapFcst               
                         - 0.667*0.8*0.6123545*svmrawnnFcst*isBond * isTue //reduce 1/3, Mar 03, 20 repor
                         // extra
                         //+0.5*0.1606*constrain(GAP2,-1.8,1.8)*isPhy*(DOW == 2?1:0) //reduce 1/2
                         -0.33*0.1457*constrain(GAP,-1.8,1.8)*isCLBCHGGC*(DOW == 1?1:0); //reduce 1/2

   */

   // weak perf. Oct 2020, reduce weights for the following:
   // scdFcst -> reduce 80%
   // scdFcstD2 -> 50%
   // scdFcstD3 -> leave as is
   // svmFcstRaw -> ok ( for nonAsia stocks)
   // nn -> 80%
   // knngap -> 50%
   // double svmrawnnFcst=-0.0034942+0.5411356*svmFcstRaw+0.320045*nnFcst;

   double bt1FcstV96DM = -0.0406177
                         + 0.8*0.6123545*0.5411356*constrain(svmFcstRaw,-0.12,0.12)*(isAsia==0?1:0)
                         + 0.2*0.8*0.6123545*0.320045*constrain(nnFcst,-0.12,0.12)
                         + 0.6399196* knngoFcst                    
                         + 0.2*0.3306125* scdFcst  // see 20190813 report on adj= 2.5*0.132245                   
                         + 0.5*0.9826826* scdFcstD2                   
                         + (1.667*0.2753151)*scdFcstD3  //see 20200827 report, wgt up 67%        
                         + 0.5*0.472159* knngapFcst               
                         //- 0.667*0.8*0.6123545*svmrawnnFcst*isBond * isTue //reduce 1/3, Mar 03, 20 repor
                         // extra
                         //+0.5*0.1606*constrain(GAP2,-1.8,1.8)*isPhy*(DOW == 2?1:0) //reduce 1/2
                         -0.33*0.1457*constrain(GAP,-1.8,1.8)*isCLBCHGGC*(DOW == 1?1:0); //reduce 1/2




   if(isPhy) // see 2019/11/13 report, 11/25 report
   {
     bt1FcstV96DM=   bt1FcstV96DM
                  + 0.5*(0.8*0.6123545* constrain(svmFcst,-0.1,0.1))*(DOW == 2?0.5:1) // add more svm to phy
                  - 0.5*(1.667*0.2753151)*scdFcstD3                     
                  - 0.5*0.5*0.472159* knngapFcst;

   }

   /*
   if(isStock && sym != "VX") // see 2020/03/23
   {
     bt1FcstV96DM=    bt1FcstV96DM
                     -0.6667*0.8*0.6123545* svmnnFcst;
   }
   */

   // save old V96StockFcst, 2020/10
   double bt1V96FcstIdxOld=0; 
   if(isStock && sym != "VX") // see 2020/03/23
   {
     bt1FcstV96DM=    bt1FcstV96DM
                     -0.6667*0.8*0.6123545* svmrawnnFcst;

     bt1FcstV96DM=bt1FcstV96DM*0.9;
     bt1FcstV96DM=constrain(bt1FcstV96DM,-0.16,0.16);

     bt1V96FcstIdxOld=bt1FcstV96DM;
   }


   // create a new stock fcst, see 2020/10/07 report
   if(isStock && sym != "VX") // see 2020/10/07
   {
     bt1FcstV96DM= -0.04760
                   +knngoFcst   *  0.64330 
                   +scdFcst     *  0.3 *0.2
                   +scdFcstD2   *  0.3 *0.5 
                   +scdFcstD3   *  0.667*2.44386
                   +knngapFcst  *  0.15814 * 0.5
                   +OO2Fcst     *  0.333*0.78426
                   +OO3Fcst     *  0.333*1.00492
                   +OO7t20xFcst *  0.333*0.52839
                   +constrain(svmFcstRaw,-0.12,0.12)  * 0.3*0.5411356*(isAsia==0?1:0)
                   +constrain(nnFcst,-0.12,0.12)     * 0.3*0.320045*0.2 ;

   }
   //double svmrawnnFcst=-0.0034942+0.5411356*svmFcstRaw+0.320045*nnFcst;

   //for asia stocks
   double  bt1V96FcstAsiaIdxOld=0;
   if(sym == "CN" ||sym == "STW"||sym == "SNI" ||sym == "BTP"  ) // see 2020/10/15
   {
     bt1FcstV96DM=bt1FcstV96DM*0.9;
     bt1FcstV96DM=constrain(bt1FcstV96DM,-0.16,0.16);

     bt1V96FcstAsiaIdxOld=bt1FcstV96DM;
   }

   double scdComboA= -0.03094
                     +scdFcst   * 0.27739  
                     +scdFcstD2 * 1.84859
                     +scdFcstD3 * 0.62651;

   if(sym == "CN" ||sym == "STW"||sym == "SNI" ||sym == "BTP" ) // see 2020/10/15
   {
     bt1FcstV96DM=scdComboA;


   }

   if(sym == "HG" ) //see 2020/02/19  report,
   {
       // take out extra svm for HG
       bt1FcstV96DM=  0.5* (bt1FcstV96DM-0.5*(0.8*0.6123545* constrain(svmFcst,-0.1,0.1))*(DOW == 2?0.5:1) )
                      +0.5*knngapFcst;
   }

   if(sym == "BC" ) //see 2020/02/19  report,
   {
        bt1FcstV96DM=  0.5*bt1FcstV96DM
 	               +0.5*knngapFcst;
   }



   if(sym == "CD" ) //see 2020/02/26  report,
   {
	 bt1FcstV96DM=  0.333*bt1FcstV96DM
 	               +0.333*knngapFcst   
	               +0.333*knngoFcst;
   }



   double stwFcst2=0;
   if(sym == "STW" ) //see 2020/02/13  report,
   {
     /* removed on 2020/10/16
	    bt1FcstV96DM=  0.00776 
 	                  + 0.8832*scdFcst
                          + 0.367*scdFcstD2                     
                          + 0.3061*nnFcst
	                  + 0.7*1.0146*stwFcstAdj2;
     */

	    stwFcst2=     0.00776 
 	                  + 0.8832*scdFcst
                          + 0.367*scdFcstD2                     
                          + 0.3061*nnFcst
	                  + 0.7*1.0146*stwFcstAdj2;
   }



   bt1FcstV96DM=bt1FcstV96DM*0.9;
   //bt1FcstV96DM=constrain(bt1FcstV96DM,-0.16,0.16);
   double bt1FcstV96DMNoCons=bt1FcstV96DM;
   bt1FcstV96DM=constrain(bt1FcstV96DM,-0.105,0.105); // see 2020/10/16 report, I use 0.105 as best constraints



   /*
ooF2D ~ svmnnFcst + d2svmFcst + knngoFcst + scdFcst + 
    scdFcstD2 + scdFcstD3 + knngapFcst.v2 + I(svmnnFcst * isBond * 
    isTue), data = regdata)

Residuals:
     Min       1Q   Median       3Q      Max 
-15.1428  -0.8441   0.0436   0.8794  12.2739 

Coefficients:
                               Estimate Std. Error t value Pr(>|t|)    
(Intercept)                   -0.039117   0.006531  -5.989 2.12e-09 ***
svmnnFcst                      0.516263   0.092332   5.591 2.26e-08 ***
d2svmFcst                      0.124375   0.075374   1.650 0.098927 .  
knngoFcst                      0.636167   0.120344   5.286 1.25e-07 ***
scdFcst                        0.314733   0.129883   2.423 0.015387 *  
scdFcstD2                      0.852194   0.179601   4.745 2.09e-06 ***
scdFcstD3                      0.680041   0.170607   3.986 6.73e-05 ***
knngapFcst.v2                  0.534042   0.120341   4.438 9.10e-06 ***
I(svmnnFcst * isBond * isTue) -1.488084   0.386707  -3.848 0.000119 ***

   */

   double bt1FcstV96F2DDM = -0.03911
                         +0.516263* svmnnFcst
                         +0.124375*d2svmFcst                    
                         +0.636167* knngoFcst                    
                         +0.31473* scdFcst                     
                         +0.85219* scdFcstD2                   
                         +0.68004*scdFcstD3                     
                         +0.53404* knngapFcst               
			 -0.516263*0.667*svmnnFcst*isBond * isTue;  //reduce 1/3



   bt1FcstV96F2DDM=bt1FcstV96F2DDM*0.9;
   bt1FcstV96F2DDM=constrain(bt1FcstV96F2DDM,-0.19,0.19);


   // added 20190528
   double bt1V96BA =     -0.0323685
                         +0.9405474* knngoFcst                    
                         +0.691344* scdFcst                     
                         +0.4484505* scdFcstD2                   
                         +0.2691614*scdFcstD3;
                     
   bt1V96BA=bt1V96BA*0.9;
   bt1V96BA=constrain(bt1V96BA,-0.16,0.16);



   // added 20210923
   double bt1V96BA2 =    -0.0323685+0.004
                         +0.9405474* knngoFcst                    
                         +0.691344* scdFcst                  
                         +0.4484505* scdFcstD2;
                     
   bt1V96BA2=bt1V96BA2*0.9;
   bt1V96BA2=constrain(bt1V96BA2,-0.16,0.16);


 
    /////////////////////////////////////////////////
    //////////  V97 

   /// -------  V97 models, see 20201207 for IB model and 12/09 for phy model
     /*
---- V97 model ----
---------SrMdd2 model 1:
$portfolioSharpeRatio
[1] 1.782332
$MDD
[1] 0.7213347


$SMCoefs
                                                                                      indicator      coef
1:                                                                                  (Intercept) -0.039562
2:                                                           constrain(knngoFcstAdj, -0.1, 0.1) 0.6890589
3:                                                                constrain(scdFcst, -0.1, 0.1) 0.1363862
4:                                                              constrain(scdFcstD2, -0.1, 0.1)  0.611298
5:                                                                        constrain(OO3, -1, 1) 0.0174115
6: constrain(scdFcstD3, -0.1, 0.1):ifelse(SESSION == "Europe" & ASSET4 == "Financial", 0.33, 1) 1.0686374
7:                             constrain(svmFcstRaw, -0.1, 0.1):ifelse(SESSION != "Asia", 1, 0) 0.4135309

manual adj , v3

regdataPostX$fcstNew= -0.012-0.039562+ constrain(regdataPostX$knngoFcstAdj, -0.1, 0.1)* 0.6890589*1.25+ constrain(regdataPostX$scdFcst, -0.1, 0.1)* 0.1363862+ constrain(regdataPostX$scdFcstD2, -0.1, 0.1)*0.611298*0.75+ constrain(regdataPostX$OO3, -1, 1) *0.0174115*0.75+constrain(regdataPostX$scdFcstD3, -0.1, 0.1)*ifelse(regdataPostX$isEurBond == 1, 0.33, 1)* 1.0686374*0.75+  constrain(regdataPostX$svmFcstRaw, -0.1, 0.1)*ifelse(regdataPostX$SESSION != "Asia", 1, 0)* 0.4135309



     */

   // knngo -> 1.25
   // scdFcstD2 ->  75%
   // scdFcstD3 -> 75%
   // svmFcstRaw -> ok ( for nonAsia stocks)
   // OO3 -> 75%

	/* see 20201228 report for GAPD:HCAvgAbs ind
$SMCoefs
                                                               indicator       coef
1:                                                           (Intercept)  0.0091628
2:                                    constrain(bt1FcstV96DM, -0.1, 0.1)  1.1909325
3:            constrain(GAPD, -1.5, 0):ifelse(SESSION == "Europe", 1, 0) -0.1760805
4: constrain(GAPD * HCAvgAbs, -1.5, 0):ifelse(SESSION == "Europe", 1, 0)  0.2247978
$portfolioSharpeRatio
[1] 2.057079
$MDD
[1] 0.7720921
	*/

   double bt1FcstV97DM = bt1FcstV96DM;
   double knngoFcstAdj=(isStock==1?knngoo3Fcst:knngoFcst);

   // use same wgts for cur YHC
   double GAPDxHCAvgFcst=constrain(GAPD, -1.5, 0)* (-0.19)
                         + constrain(GAPD * HCAvgAbs, -1.5, 0)* 0.29;


   // create a IB model, see 2020/12/07 report
   // expected idx mean=0.0156, bond mean=0.0175
   if( ( isStock==1 ||  isBond==1 ) && sym != "VX")
   {

       // for svmraw nonAsia idx
       double f1dow=1;
       if(DOW==2)
       {
	 f1dow=1.25;
       }
       if(DOW==4)
       {
	 f1dow=0.5;
       }

       bt1FcstV97DM =  -0.012-0.039562
                       + constrain(knngoFcstAdj, -0.1, 0.1)* 0.6890589*1.25
      	               - 0.6* constrain(knngoFcstAdj, -0.1, 0.1)* (isEurIdx==1?1:0)* 0.6890589*1.25 //Eur idx wgt cut 40% 
	               + constrain(scdFcst, -0.1, 0.1)* 0.1363862
                       + constrain(scdFcstD2, -0.1, 0.1)*0.611298*0.75
                       + constrain(scdFcstD3, -0.1, 0.1)*(isEurBond==1?0.33:1)* 1.0686374*0.75
  	               + constrain(OO3, -1, 1) *0.0174115*0.75 // +/- 1 constraints on OO3
                       + constrain(svmFcstRaw, -0.1, 0.1)* isBond* 0.4135309
                       + constrain(svmFcstRaw, -0.1, 0.1)* isNonAsiaIdx* f1dow*0.4135309// see 20210517 report
 	               + constrain(svmFcst, -0.1, 0.1)* isAsiaIdx*isTue*0.4135309 // see 20210517 report
                       + constrain(svmFcst, -0.1, 0.1)* isAsiaIdx*isFri*0.4135309*0.333
	               + constrain(GAPDxHCAvgFcst,-0.1,0.1)*isEurope*0.667;

   }



    // phy fcst
   /* V97

-- V97 phy models
-- candidate 2:

$SMCoefs
                                                                indicator      coef
1:                                                            (Intercept) -0.038802
2:                                     constrain(svmFcstPhyJF, -0.1, 0.1) 0.9166792
3:                                        constrain(knngoFcst, -0.1, 0.1) 0.1966818
4:                                        constrain(scdFcstD2, -0.1, 0.1) 0.5439082
5:                                        constrain(scdFcstD3, -0.1, 0.1) 0.9562375
6: constrain(GAP, -1, 1):ifelse(SYM == "HG", 1, 0):ifelse(DOW == 1, 1, 0) -0.523279

$portfolioSharpeRatio
[1] 2.619541
$MDD
[1] 0.6542388
   */

    // manually adjusted svmFcst for phy
    double svmFcstPhyJF=constrain(svmFcstRaw,-0.105,0.105);

    double tf=(DOW==2?0.5:1); //Tue low wgt for svm, see 20210415 report
    double svmFcstRawxTue=constrain(svmFcstRaw,-0.105,0.105)*tf; //this is basically svm with Tue half wgt

    if(isPhy)
    {
      // for some phys: see 2020/11/16 report
      if(sym== "GC" || sym== "HG"|| sym== "KC"|| sym== "CT")
      {
 	 double tmpX=0.7*constrain(bt1V96BA,-0.105,0.105)+0.3*constrain(svmFcstRaw,-0.105,0.105)*tf;
	 svmFcstPhyJF=constrain(tmpX,-0.105,0.105);
      }
      if(sym== "SB")
      {
	 double tmpX=0.7*constrain(svmFcstRaw,-0.105,0.105)*tf+0.3*constrain(knngoFcst,-0.105,0.105);
	 svmFcstPhyJF=constrain(tmpX,-0.105,0.105);
      }
      if(sym== "LC"||sym== "BC")
      {
	 double tmpX= 0.5*constrain(svmFcstRaw,-0.105,0.105)*tf
                     +0.25*constrain(knngoFcst,-0.105,0.105)
                     +0.25*constrain(knngapFcst,-0.105,0.105);
	 svmFcstPhyJF=constrain(tmpX,-0.105,0.105);
      }
      if(sym== "CL")
      {
	 double tmpX= 0.5*constrain(svmFcstRaw,-0.105,0.105)*tf
                     +0.5*constrain(knngapFcst,-0.105,0.105);
	 svmFcstPhyJF=constrain(tmpX,-0.105,0.105);
      }
    }

   if(isPhy )
   {

        bt1FcstV97DM = 0.015-0.038802+0.005
                       + constrain(svmFcstPhyJF, -0.1, 0.1)*0.9166792
                       + constrain(knngoFcst, -0.1, 0.1)* 0.1966818
                       + constrain(scdFcstD2, -0.1, 0.1)* 0.5439082*0.75
                       + constrain(scdFcstD3, -0.1, 0.1)*  0.9562375*0.75 
    	               + constrain(GAP, -1, 1)*(sym=="HG"?1:0)*isMon* (-0.1)
	               + 0.667*0.2*constrain(knn15aggFcst, -0.1, 0.1); // see 20210308, 0712 report
   }

   /* V97 curr model, see 20201218 report
### SrMdd model:

$SMCoefs
                            indicator       coef
1:                        (Intercept)  0.0151267
2: constrain(bt1FcstV96DM, -0.1, 0.1)  0.7319521
3:            constrain(YHC, -1.5, 0) -0.0147051
4: constrain(YHC * HCAvgAbs, -1.5, 0)  0.0940094
5:              constrain(GAP, -2, 2)  -0.051582

#updated curr V97, see 20201223 report
                                                  (Intercept) -0.0247987
2:                           constrain(bt1FcstV96DM, -0.1, 0.1)  0.8333583
4:            constrain(YHC, -1.5, 0):ifelse(SYM != "DX", 1, 0) -0.1832343
5: constrain(YHC * HCAvgAbs, -1.5, 0):ifelse(SYM != "DX", 1, 0)  0.2436271
6:             constrain(YLC, 0, 1.5):ifelse(SYM == "DX", 1, 0) -0.1944492
7:  constrain(YLC * LCAvgAbs, 0, 1.5):ifelse(SYM == "DX", 1, 0)  0.2910218
3:                             constrain(GAP * AEO2, -0.5, 0.5) -0.0734638
   */


   int isDX=0;
   int isNonDX=0;
   if(sym == "DX")
   {
     isDX=1;
   }
   else
   {
     isNonDX=1;
   }


   if(isCurr )
   {

        bt1FcstV97DM = -0.024798
                       + constrain(bt1FcstV96DM, -0.1, 0.1)*0.8333583
 	               + isNonDX*constrain(YHC, -1.5, 0)* (-0.1832343)
                       + isNonDX*constrain(YHC * HCAvgAbs, -1.5, 0)* 0.2436271
 	               + isDX*constrain(YLC,0,1.5)* ( -0.1944492)
                       + isDX*constrain(YLC * LCAvgAbs, 0,1.5)* 0.291021
    	               + constrain(GAP*AEO2, -0.5,0.5)*(-0.0734638);
   }


   bt1FcstV97DM=bt1FcstV97DM*0.9;
   bt1FcstV97DM=constrain(bt1FcstV97DM,-0.105,0.105);





 
    /////////////////////////////////////////////////
    //////////  V98 fcst, see 20210923 report
    // just STW/SNI/TWN and USStock used BAFcst, all else are bt1Fcst
    double bt1FcstV98DM=bt1FcstV97DM;

    if(  sym == "SNI" || sym == "STW" ||sym == "TWN"||sym == "ES" || sym == "NQ" ||sym == "YM"||sym == "MES" || sym == "MNQ" ||sym == "MYM")
    {
       bt1FcstV98DM=bt1V96BA;
    }
    bt1FcstV98DM=constrain(bt1FcstV98DM,-0.105,0.105);


    /////////////////////////////////////////////////
    //////////  V99 fcst, see 20240116 report
    double bt1FcstV99DM=bt1FcstV98DM+0.2*constrain(nnn2DFcst,-0.13,0.13);
    bt1FcstV99DM=constrain(bt1FcstV99DM,-0.13,0.13);





   // see 20210628 report for LT fcst
   //#best model 1
   //regdata$newFcst11=  regdata$bt1FcstDM+0.05*constrain(regdata$OOX1.MA25t40,-0.4,0.4);
   double bt1FcstST=bt1FcstV98DM;
   double bt1FcstLT=bt1FcstV98DM+0.05*constrain(OOMA26t40,-0.4,0.4);;
   //bt1FcstLT=bt1FcstLT*0.9;
   bt1FcstLT=constrain(bt1FcstLT,-0.105,0.105);

   /*
   //see rep.txt.20181125
   double vxFcstNew3=0;
   if(sym == "VX") //vxFcst
   {
      vxFcstNew3=  0.0008781
                  +1.2*0.3559512*f1svmFcst
                  +0.2657143*svmFcst
	          +0.75*0.0160121*OO7t20;
      vxFcstNew3=constrain(vxFcstNew2,-0.14,0.1);
      bt1FcstV96DM=vxFcstNew3;
   }
   */



   //VXReduc for extreme risk increases
   if(VXRatio >=1.25 && (( isStock==1 && sym !="VX") || sym =="CL"|| sym=="BC" || sym =="EC"|| sym=="CD" ) ) // drop Idx and CL/BC wgt only for now, Feb 10, 2018; add CD/EC, see Feb 13 study
   {
     VXReduc=0.85;
     bt1FcstV96DM=bt1FcstV96DM*VXReduc;
     bt1FcstV97DM=bt1FcstV97DM*VXReduc;
     bt1FcstV98DM=bt1FcstV98DM*VXReduc;
     bt1FcstV99DM=bt1FcstV99DM*VXReduc;
   }

   if(sym == "LEU" || sym == "ED" )
   {
     bt1FcstV96DM=0;
     bt1V96OLS=0;
     bt1FcstV96F2DDM=0;
     bt1V96ZA=0;
     bt1FcstV97DM=0;
     bt1FcstV98DM=0;
     bt1FcstV99DM=0;
   }


   // see Nov 13, 2020 report, from now to year end, trade svmFcst
   int isUseSVM=0;


   vector<string> vec=getTimeStampDateTimeVec();
   string tsDate=vec[0];
   string tsTime=vec[1];
   double FVOO=rth.getFVOO(todayLoc);
   double FVOO2=rth.getFVOO2(todayLoc);
   cout<<"Timestamp: "<<tsDate<<" "<<tsTime<<" ";
   cout<<todayDate<<" "
       <<sym
       <<" open= "<<open
       <<" spd= "<<spd
       <<" cumSpd= "<<cumSpd
       //<<" bt1Fcst.dm= "<<bt1FcstV96DM
       <<" bt1Fcst.dm= "<<bt1FcstV99DM
     // <<" bt1Fcst.dm= "<<bt1Fcst+0.015 //added 0.025 for the year end
       <<" bt1Fcst= "<<bt1FcstV99DM
       <<" svmFcst= "<<svmFcst
       <<" nnFcst= "<<nnFcst
       <<" FVOO= "<<FVOO
       // other stuff for debug
       <<" DateDif= "<<dateDist
       <<" preDate= "<<preDate
       <<" today= "<<todayDate
       <<" preOpen= "<<duPre.open
       <<" GAP= "<<GAP
       <<" OO1= "<<OO1
       <<" OO2= "<<OO2
       <<" OO3= "<<OO3
       <<" OO4= "<<OO4
       <<" OO5= "<<OO5
       <<" OO22t252N= "<<OO22t252N
       <<" fcstLTSS= "<<fcstLTSS
       <<" bt1DMV2= "<<bt1DMV2
       <<" bt1DMV9= "<<bt1FcstV9DM
       <<" ESCC1= "<<ESCC1
       <<" ES2t15NAbs= "<<ES2t15NAbs
       <<" ESMRecntDate= "<< MRecentDateES
       <<" bizDateDifES= "<< bizDateDifES
       <<" GAP2= "<< GAP2
       <<" YHC= "<< YHC
       <<" HCAvgAbs= "<< HCAvgAbs
       <<" DOW= "<< DOW
       <<" fcstLTCombo= "<<fcstLTCombo
       <<" fcstComboExIdxCurr= "<<fcstComboExIdxCurr
       <<" fcstBT1V2CurrAdj= "<< fcstBT1V2CurrAdj
       <<" fcstYHCCurr= "<< fcstYHCCurr
       <<" fcstIdxGAP2= "<< fcstIdxGAP2
       <<" fcstBT1V2IdxAdj= "<< fcstBT1V2IdxAdj
       <<" fcstESCC1Idx= "<< fcstESCC1Idx
       <<" VXRatio= "<< VXRatio
       <<" VXReduc= "<< VXReduc
       <<" VXMRecntDate= "<< MRecentDateVX
       <<" bizDateDifVX= "<< bizDateDifVX
       <<" stwFcstAdj= "<< stwFcstAdj
       <<" vxCCEmaEx1= "<< vxCCEmaEx1
       <<" vxDTR= "<< DTR
       <<" vxCtgAvgDif= "<< ctgDifAvg
       <<" vxCtgDate= "<< MRecentDateCtg
       <<" vxFcst= "<< vxFcst
       <<" AEMAOO= "<< AEMAOO
       <<" OO1IdxFcst= "<< OO1IdxFcst
       <<" OO1AEMAIdxFcst= "<< OO1AEMAIdxFcst
       <<" OO1BondFcst= "<< OO1BondFcst
       <<" OO1AEMABondFcst= "<< OO1AEMABondFcst
       <<" d1svmFcst= "<< d1svmFcst
       <<" d2svmFcst= "<< d2svmFcst
       <<" f1svmFcst= "<< f1svmFcst
       <<" svmFcst2= "<< svmFcst2
       <<" bt1FcstV91DM= "<<  bt1FcstV91DM
       <<" bt1FcstV92DM= "<<  bt1FcstV92DM
       <<" svmFcstRaw= "<<  svmFcstRaw
       <<" hgFcstAdj= "<<  hgFcstAdj
       <<" YOC= "<<  YOC
       <<" knn15aggFcst= "<<  knn15aggFcst
       <<" knn15aggFcstStd= "<<  knn15aggFcstStd
       <<" knn15aggFcstOC= "<<  knn15aggFcstOC
       <<" knn15aggFcstCO= "<<  knn15aggFcstCO
       <<" knn15aggFcstD2= "<<  knn15aggFcstD2
       <<" bt1FcstV95DM= "<<  bt1FcstV95DM
       <<" vxFcstNew= "<<  vxFcstNew
       <<" knn15aggFcst3D= "<<  knn15aggFcst3D
       <<" f1svmFcstNew= "<<  f1svmFcstNew

       <<" knngoFcst= "<<  knngoFcst
       <<" knngoFcstStd= "<<  knngoFcstStd
       <<" knngoFcstOC= "<<  knngoFcstOC
       <<" knngoFcstCO= "<<  knngoFcstCO
       <<" knngoFcstD2= "<<  knngoFcstD2
       <<" knngoFcst3D= "<<  knngoFcst3D
       <<" AEO2= "<<  AEO2
       <<" OO7t20x= "<<  OO7t20
       <<" vxFcstNew2= "<<  vxFcstNew2
       <<" GAPU= "<<  GAPU
       <<" GAPD= "<<  GAPD
       <<" DOMB= "<<  DOMB
       <<" OO1U= "<<  OO1U
       <<" OO1D= "<<  OO1D
       <<" FVOO2= "<<  FVOO2
       <<" isNNSelect= "<<  isNNSelect
       <<" nnFcstSel= "<<  isNNSelect*nnFcst

       <<" scdFcst= "<<  scdFcst
       <<" scdFcstStd= "<<  scdFcstStd
       <<" scdFcstOC= "<<  scdFcstOC
       <<" scdFcstCO= "<<  scdFcstCO
       <<" scdFcstD2= "<<  scdFcstD2
       <<" scdFcst2D= "<<  scdFcst2D
       <<" scdFcst3D= "<<  scdFcst3D
       <<" scdFcstD3= "<<  scdFcstD3
       <<" knngapFcst= "<<  knngapFcst
       <<" knngapFcstStd= "<<  knngapFcstStd
       <<" knngapFcstOC= "<<  knngapFcstOC
       <<" knngapFcstCO= "<<  knngapFcstCO
       <<" knngapFcstD2= "<<  knngapFcstD2
       <<" knngapFcst3D= "<<  knngapFcst3D
       <<" svmnnFcst= "<<  svmnnFcst
       <<" bt1V96OLS= "<<  bt1V96OLS
       <<" bt1FcstV96DM= "<<  bt1FcstV96DM
       <<" bt1FcstV96F2DDM= "<<  bt1FcstV96F2DDM
       <<" bt1V96ZA= "<<  bt1V96ZA
       <<" bt1V96BA= "<<  bt1V96BA
       <<" YOCU= "<<  YOCU
       <<" YOCD= "<<  YOCD
       <<" stwFcstAdj2= "<< stwFcstAdj2
       <<" ESCC1x2t15Abs= "<< ESCC1x2t15Abs
       <<" OC2= "<<  OC2
       <<" OO2Fcst= "<<  OO2Fcst
       <<" OO3Fcst= "<<  OO3Fcst
       <<" OO7t20xFcst= "<<  OO7t20xFcst
       <<" bt1V96FcstIdxOld= "<<  bt1V96FcstIdxOld
       <<" scdComboA= "<<  scdComboA
       <<" bt1V96FcstAsiaIdxOld= "<<  bt1V96FcstAsiaIdxOld
       <<" svmrawnnFcst= "<<  svmrawnnFcst
       <<" stwFcst2= "<<  stwFcst2
       <<" bt1FcstV96DMNoCons= "<<  bt1FcstV96DMNoCons
       <<" isUseSVM= "<<  isUseSVM
       <<" knngoo3Fcst= "<<  knngoo3Fcst
       <<" knngoo3FcstStd= "<<  knngoo3FcstStd
       <<" knngoo3FcstOC= "<<  knngoo3FcstOC
       <<" knngoo3FcstCO= "<<  knngoo3FcstCO
       <<" knngoo3FcstD2= "<<  knngoo3FcstD2
       <<" knngoo3Fcst3D= "<<  knngoo3Fcst3D
       <<" knngoFcstAdj= "<<  knngoFcstAdj
       <<" svmFcstPhyJF= "<<  svmFcstPhyJF
       <<" bt1FcstV97DM= "<<  bt1FcstV97DM
       <<" YLC= "<< YLC
       <<" LCAvgAbs= "<< LCAvgAbs
       <<" GAPDxHCAvgFcst= "<<GAPDxHCAvgFcst
       <<" svmFcstRawxTue= "<<svmFcstRawxTue
       <<" OOMA26t40= "<<OOMA26t40
       <<" bt1FcstST= "<<  bt1FcstST
       <<" bt1FcstLT= "<<  bt1FcstLT
       <<" OOMA7t40= "<<OOMA7t40
       <<" OOMA7t40Adj= "<<OOMA7t40Adj
       <<" bt1FcstV98DM= "<<  bt1FcstV98DM
       <<" bt1V96BA2= "<<  bt1V96BA2
       <<" knngapFcstAdj= "<<  knngapFcstAdj
       <<" nnnFcst= "<<nnnFcst
       <<" nnn2DFcst= "<<nnn2DFcst
       <<" nnn5DFcst= "<<nnn5DFcst
       <<" bt1FcstV99DM= "<<  bt1FcstV99DM
       <<endl;

   /*
   int idx1=getDateIdx(20150930);
   int idx2=getDateIdx(20151002);
   cout<<"idx1,2,dif= "<<idx1<<" "<<idx2<<" "<<idx2-idx1<<endl;
   */

   return EXIT_SUCCESS;

}




/*
       double a1 =  -0.012-0.039562
                       + constrain(knngoFcstAdj, -0.1, 0.1)* 0.6890589*1.25
      	               - 0.6* constrain(knngoFcstAdj, -0.1, 0.1)* (isEurIdx==1?1:0)* 0.6890589*1.25 //Eur idx wgt cut 40% 
	               + constrain(scdFcst, -0.1, 0.1)* 0.1363862
                       + constrain(scdFcstD2, -0.1, 0.1)*0.611298*0.75
                       + constrain(scdFcstD3, -0.1, 0.1)*(isEurBond==1?0.33:1)* 1.0686374*0.75
	 + constrain(OO3, -1, 1) *0.0174115*0.75;

      double a2= constrain(svmFcstRaw, -0.1, 0.1)* (!isAsia?1:0)* 0.4135309
	               + constrain(GAPDxHCAvgFcst,-0.1,0.1)*isEurope*0.667;

      double l1= constrain(knngoFcstAdj, -0.1, 0.1)* 0.6890589*1.25;
      double l2=              - 0.6* constrain(knngoFcstAdj, -0.1, 0.1)* (isEurIdx==1?1:0)* 0.6890589*1.25 ;//Eur idx wgt cut 40% 
      double l3= 	               + constrain(scdFcst, -0.1, 0.1)* 0.1363862;
      double l4=                   + constrain(scdFcstD2, -0.1, 0.1)*0.611298*0.75;
      double l5=               + constrain(scdFcstD3, -0.1, 0.1)*(isEurBond==1?0.33:1)* 1.0686374*0.75;
      double l6=                  + constrain(OO3, -1, 1) *0.0174115*0.75;


       cout<<"V97="<<bt1FcstV97DM<<endl;
       cout<<"a1= "<<a1<<", a2= "<<a2<<endl;
       cout<<"l1= "<<l1<<", l2= "<<l2<<" l3= "<<l3<<endl;
       cout<<"l4= "<<l4<<", l5= "<<l5<<" l6= "<<l6<<endl;
       cout<<"knngoFcstAdj="<<knngoFcstAdj<<endl;
       cout<<"scdFcst="<<scdFcst<<endl;
       cout<<"scdFcstD2="<<scdFcstD2<<endl;
       cout<<"scdFcstD3="<<scdFcstD3<<endl;
       cout<<"OO3="<<OO3<<endl;
       cout<<"isEurIdx="<<isEurIdx<<endl;
       cout<<"isEurBond="<<isEurBond<<endl;
       cout<<"isAsia="<<isAsia<<endl;
       cout<<"isEurope="<<isEurope<<endl;

*/
