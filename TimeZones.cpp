#include "TimeZones.h"

ostream & operator<< (ostream& out, const TZUnit & s)
{
    s.print(out);
    return out;
}


TimeZones::TimeZones()
{
    mySize=0;
}

TimeZones::TimeZones(int dateLT)
{
    mySize=0;
    loadTimeZoneFile();
    //print();
    mySize=myStorage.size();

    computeAllETTimesAtDateLT(dateLT);
    //cout<<endl<<endl;
    //print();
    //cout<<"done 2nd print\n";
}

TimeZones::~TimeZones()
{
   // to do
}

bool TimeZones::loadTimeZoneFile()
{

    ifstream input;
    //string filename="/home/jgeng/transfer/Prod/timezones.txt";
    //string filename="/home/jgeng/transfer/Prod/timezones_alt.txt";
    // added 20180322
    string filename="/home/jgeng/transfer/Prod/timezones_newUniv.txt";


    input.open(filename.c_str());
    if(input.fail())
    {
        cerr << "Can't open the file: " << filename << endl;
        exit(-1);
    }

    //int openLT,closeLT;
    string sym,tzname;

    string line;
    while (!input.eof()) 
    {
	getline(input,line);

	if (line.length() == 0 || line[0] == '#') //skip empty and # lines
	{
       	    continue;
	}

	//process
	Tokenizer s(line); //split at space
	
	vector<string> v=s.split();
	
	//cout<<v[0]<<" "<<v[1]<<" "<<v[2]<<" "<<v[3]<<endl;
	TZUnit tu;
	tu.sym=v[0];
	tu.otLT=atoi(v[1].c_str()); //format: 830
	tu.ctLT=atoi(v[2].c_str());
	tu.tzname=v[3];

	//risk_global_map.insert(  make_pair(v[0],atof(v[1].c_str())) );
	myStorage.push_back(tu);
    }

    input.close();

    mySize=myStorage.size();

    return true;

}


void TimeZones::print()
{
   for(unsigned int i=0;i<myStorage.size();i++)
   {
       TZUnit tu=myStorage[i];
       cout<<tu<<endl;
   }
}


void TimeZones::convertToETDateTime(int dateLT, int timeLT, string tzname,int&dateET,int&timeET)
//e.g, dateLT=20151009 time=HHMMSS=083000 tzname=Chicago
// output: 20151009 time=093000
{


    ////////////////////////////////////
    // step1: get elapsed sec in local zone
    ///////
    string oldzone = changeTimeZone(tzname);
    string currTZ1(getenv("TZ"));
    //cout<<"currTZ1="<<currTZ1<<" oldzone="<<oldzone<<endl;
    time_t secFromEpoch=secsFromEpoch(dateLT, timeLT, currTZ1); //since UTC epoch
    //cout<<"elpa="<< secFromEpoch<<endl;
    //change back to old zone
    changeTimeZone(oldzone);


    //////////////////////////////////////
    // setp2: now in ET zone, check time for the same elpased time
    ////////
    string ET="America/New_York";
    oldzone = changeTimeZone(ET);
    //time in ET
    string currTZ(getenv("TZ"));
    //cout<<"currTZ="<<currTZ<<endl;

    struct tm *timeptr=localtime(&secFromEpoch);


    int YYYY= 1900 + timeptr->tm_year;
    int MM=timeptr->tm_mon+1;
    int DD=timeptr->tm_mday;
    int HH=timeptr->tm_hour;
    int MM2=timeptr->tm_min;
    int SS=timeptr->tm_sec;

    // dateET
    static char result[26];
    sprintf(result, "%4d%02d%02d",YYYY,MM,DD);
    string dateETStr(result);
    dateET=atoi(dateETStr.c_str());

    //timeET
    static char result2[26];
    sprintf(result2, "%02d%02d%02d",HH,MM2,SS);
    string timeETStr(result2);
    timeET=atoi(timeETStr.c_str());
    //cout<<"timeET="<<timeET<<endl;

    //change back to ET
    changeTimeZone(oldzone);


}


void TimeZones::computeAllETTimesAtDateLT(int dateLT)
{
    for(size_t i=0;i< myStorage.size();i++)
    {
       TZUnit tu=myStorage[i];

       //cout<<"######## "<<tu.sym<<endl;
       //local timezone times
       string tzname=tu.tzname; //eg."America/Chicago";
       //dateLT=20151009;
       int hhmmssLT_open=tu.otLT*100; //from: 930 to 93000
       int hhmmssLT_close=tu.ctLT*100;

       //convert to ET
       int dateET_open,dateET_close,hhmmssET_open,hhmmssET_close;
       convertToETDateTime(dateLT,hhmmssLT_open,tzname,dateET_open,hhmmssET_open);
       convertToETDateTime(dateLT,hhmmssLT_close,tzname,dateET_close,hhmmssET_close);
       //if(dateET_open !=dateET_close)
       //{
       //	 cout<<"dateET open != close"<<endl; // for Asia contracts
       //}

       myStorage[i].dateLT=dateLT;

       myStorage[i].otET=hhmmssET_open/100;
       myStorage[i].ctET=hhmmssET_close/100;
       myStorage[i].dateETOpen=dateET_open;
       myStorage[i].dateETClose=dateET_close;

       
       //cout<<"convert: "<<tu.sym<<" "<<dateLT<<" "<<hhmmssLT_open/100<<" "<<hhmmssLT_close/100
       //   <<" "<<dateET_open<<" "<<hhmmssET_open/100<<" " <<dateET_close<<" "<<hhmmssET_close/100<<endl;


    }
}



void TimeZones::printByAlphabetOrder()
{

   vector<TZUnit> tmpVec=myStorage;

   std::sort(tmpVec.begin(), tmpVec.end(), less_than_str());
   
   for(unsigned int i=0;i<tmpVec.size();i++)
   {
       TZUnit tu=tmpVec[i];

       cout<<left<<setfill(' ')<<setw(4)<<tu.sym<<" ";
       cout<<right<<setfill(' ')<<setw(8)<<tu.dateLT<<" "
	     <<setfill('0') << setw(4)<<tu.otLT<<" "
	     <<setfill('0') << setw(4)<<tu.ctLT<<" "
	     <<tu.dateETOpen<<" "
	     <<setfill('0') << setw(4)<<tu.otET<<" "
	     <<tu.dateETClose<<" "
	     <<setfill('0') << setw(4)<<tu.ctET<<endl;



   }

}
  

void TimeZones::printByOpenTimes()
{

   vector<TZUnit> tmpVec=myStorage;

   std::sort(tmpVec.begin(), tmpVec.end(), less_than_ot());
   
   for(unsigned int i=0;i<tmpVec.size();i++)
   {
       TZUnit tu=tmpVec[i];


       cout<<left<<setfill(' ')<<setw(4)<<tu.sym<<" ";
       cout<<right<<setfill(' ')<<setw(8)<<tu.dateLT<<" "
	     <<setfill('0') << setw(4)<<tu.otLT<<" "
	     <<setfill('0') << setw(4)<<tu.ctLT<<" "
	     <<tu.dateETOpen<<" "
	     <<setfill('0') << setw(4)<<tu.otET<<" "
	     <<tu.dateETClose<<" "
	     <<setfill('0') << setw(4)<<tu.ctET<<endl;

   }

}
  

void TimeZones::printUnsorted()
{

   vector<TZUnit> tmpVec=myStorage;

   
   for(unsigned int i=0;i<tmpVec.size();i++)
   {
       TZUnit tu=tmpVec[i];


       cout<<left<<setfill(' ')<<setw(4)<<tu.sym<<" ";
       cout<<right<<setfill(' ')<<setw(8)<<tu.dateLT<<" "
	     <<setfill('0') << setw(4)<<tu.otLT<<" "
	     <<setfill('0') << setw(4)<<tu.ctLT<<" "
	     <<tu.dateETOpen<<" "
	     <<setfill('0') << setw(4)<<tu.otET<<" "
	     <<tu.dateETClose<<" "
	     <<setfill('0') << setw(4)<<tu.ctET<<endl;

   }

}
  


string TimeZones::changeTimeZone (const string &tzname)
{
    char *tzptr = getenv ("TZ");
    std::string  tzold;
 
    if (tzptr)
      tzold = string(tzptr);
    else
      tzold="";
    if (tzname.empty())
        unsetenv ("TZ");
    else
        setenv ("TZ", tzname.c_str(), 1);
    tzset();
    return tzold;
}


time_t TimeZones::secsFromEpoch(int date, int time, string tzname)
//20151009, 93000, local zone(e,g, America/New_York)
// date/time are on local time
{

    int YYYY=int(date/10000);
    int MMDD=date%10000;
    int MM=int(MMDD/100);
    int DD=MMDD%100;

    int HH=int(time/10000);
    int MMSS=time%10000;
    int MM2=int(MMSS/100);
    int SS=MMSS%100;


    string oldzone = changeTimeZone(tzname);

    string currTZ1(getenv("TZ"));
    //cout<<"currTZ1="<<currTZ1<<" oldzone="<<oldzone<<endl;

    //cout<<"tzname="<<tzname<<endl;
    struct tm t;
    t.tm_year=YYYY-1900;
    t.tm_mon=MM-1;
    t.tm_mday=DD;
    t.tm_hour=HH;
    t.tm_min=MM2;
    t.tm_sec=SS;

    t.tm_isdst=-1;
    // Must set isdst to -1 so it will figure out dst automatically
    // otherwise, the time will not be correct

    //cout<<"isdst_0="<<t.tm_isdst<<endl;
    time_t secFromEpoch=mktime(&t);
    //cout<<"secFromEpoch_0="<<secFromEpoch<<endl;
    //cout<<"isdst_1="<<t.tm_isdst<<endl;

    changeTimeZone(oldzone);

    return secFromEpoch;
}

