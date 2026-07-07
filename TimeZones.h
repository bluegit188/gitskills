#ifndef JUNFEI_TIMEZONES_H
#define JUNFEI_TIMEZONES_H

#include <vector>
#include <string>
#include <cmath>
#include <map>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <algorithm>
#include <cassert>

#include "Tokenizer.h"



using namespace std;

/* TimeZones.h
 *
 * This class is to ...
 * 
 * @Junfei Geng, 20151009
 * */



struct TZUnit
{  
    string sym;
    int otLT;
    int ctLT;
    int dateLT;
    string tzname;
    //derived 
    int otET;
    int ctET;
    int dateETOpen;
    int dateETClose;



    void print (ostream & out) const
    {
        out <<sym<<" "
            <<"openLT="<<setfill('0') << setw(4)<<otLT<<" "
            <<"closeLT="<<setfill('0') << setw(4)<<ctLT<<" "
            <<"tzname="<<tzname<<" "
            <<"dateLT="<<dateLT<<" "
            <<"otET="<<setfill('0') << setw(4)<<otET<<" "
            <<"ctET="<<setfill('0') << setw(4)<<ctET<<" "
            <<"dateETOpen="<<dateETOpen<<" "
            <<"dateETClose="<<dateETClose;

    }

    friend ostream & operator<< (ostream& out,const TZUnit & s);

};

//sort by alphabetic order
struct less_than_str
{
    inline bool operator() (const TZUnit& tu1, const TZUnit tu2)
    {
        return (tu1.sym < tu2.sym);
    }
};


class TimeZones
{
  public:
    TimeZones();                             // constructor
    TimeZones(int dateLT);                   // constructor

    ~TimeZones();                            // destructor

    bool loadTimeZoneFile();

    int  size() const{return mySize;}        // return size
    void  print();

    void  printByAlphabetOrder();
    void printByOpenTimes();
    void printUnsorted();

    void convertToETDateTime(int dateLT, int timeLT, string tzname,int&dateET,int&timeET);


    
    void computeAllETTimesAtDateLT(int dateLT);



    time_t secsFromEpoch(int date, int time, string tzname);
    string changeTimeZone (const string &tzname);



  private:

    int    mySize;                      // number of records
    vector<TZUnit> myStorage;

};



//sort by open time
struct less_than_ot
{
    inline bool operator() (const TZUnit& tu1, const TZUnit tu2)
    {
        TimeZones tz;
	time_t t1=tz.secsFromEpoch(tu1.dateETOpen, tu1.otET,"America/New_York");
	time_t t2=tz.secsFromEpoch(tu2.dateETOpen, tu2.otET,"America/New_York");
	double dif=difftime(t2,t1); //elpased secs from t1 to t2
	//cout<<"t1,t2,dif "<<t1<<" "<<t2<<" "<<dif<<endl;
        return (dif > 0);
    }
};


#endif

 
