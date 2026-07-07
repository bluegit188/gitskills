#ifndef _JUNFUTIL_H
#define _JUNFUTIL_H

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
#include <limits>
#include <ctime>

using namespace std;

const double NA_DBL=std::numeric_limits<double>::max();


inline int getMinIdx(int hhmmss)
// from HHMMSS to idx in minute, from midnight
{
   int hh=int(hhmmss/10000);
   int mmss=hhmmss%10000;
   int mm=int(mmss/100);
   //my $ss=$mmss%100;
   return hh*60+mm;
}

inline int getHHMMSSFromMinIdx(int minIdx)
// minIdx= 83
// out: 1:23:00 AM
// minIdx=0 is 00:00:00
{
   int hh=minIdx/60;
   int mm=minIdx-60*hh;
   int ss=0;
   return hh*10000+mm*100+ss;
}


inline int getDateIdx(int date)
// Rata Die date index, similar to Gregory date
// day 1 is 0001-01-01
{

   int YYYY=int(date/10000);
   int MMDD=date%10000;
   int MM=int(MMDD/100);
   int DD=MMDD%100;
   

   int y=YYYY;
   int m=MM;
   int d=DD;
   if(m<3)
   {
     y--;
     m+=12;
   }

   //cout<<"y/m/d"<<y<<" "<<m<<" "<<d<<endl;
   return 365*y+y/4-y/100+y/400+(153*m-457)/5+d-306;
}

inline int dateDif(int date1, int date2)
{
   //cout<<getDateIdx(date2)<<" "<< getDateIdx(date1)<<" dif="<<getDateIdx(date2)- getDateIdx(date1)<<endl;
   return getDateIdx(date2)- getDateIdx(date1);
}



inline double constrain(double x, double LB, double UB)
{
    if(x<LB)
    {
      x=LB;
    }
    if(x>UB)
    {
      x=UB;
    }
    return x;
}

inline int getDOW(int date)
//20150213
// return DOW: Sun=0, Mon=1, Tue=2, ...
{
   int YYYY=int(date/10000);
   int MMDD=date%10000;
   int MM=int(MMDD/100);
   int DD=MMDD%100;

   int k=DD;
   int m=MM-2;
   if(m<=0){m+=12;}

   //cout<<"YYYY,MMDD,MM,DD="<<YYYY<<" "<<MMDD<<" "<<MM<<" "<<DD<<endl;

   //# order of below 2 steps are important, otherwise, 2000 won't work.
   if(MM==1 || MM==2)
   {
     YYYY-=1;
   }
   int Y=YYYY%100; 

   int C=int(YYYY/100);
   //cout<<"k,m,YYYY,Y,C="<<k<<" "<<m<<" "<<YYYY<<" "<<" "<<Y<<" "<<C<<endl;

   int result= ( k+int(2.6*m-0.2)-2*C+Y+int(Y/4)+int(C/4) )%7;
   //in C, above could be -ive(perl always returns +ive if use interger not set)
   return ( result + 7 )%7;

}

inline double sigmoid(double x) 
{
  return 1.0 / ( 1.0 + exp(-x) );
}

inline double vectorSubsetSum(vector<double>& vec,int locStart, int locEnd) 
//start from 0, inclusive
{
    double sum=0;
    for(int i=locStart;i<=locEnd;i++)
    {
        sum+=vec[i];
    }
    return sum;
}

inline double nearest_junf(int pow10, double x)
//# emulate Math::Round's nearest function, but elimiate extra zeros from $.4f notation
//# input: -4, 3.56789 (max to 4th decimal digits
//# output: 3.568
//#
//#more examples: first argu=-4
//#0         -> 0
//#0.1       -> 0.1
//#0.11      -> 0.11
//#0.111     -> 0.111
//#0.1111111 -> 0.1111
{

   double a = pow(10,pow10);
   return (int(x / a + ((x < 0) ? -0.5 : 0.5)) * a);
}


inline int sign( double x)
{

   if(x>0)
   {
     return 1;
   }
   else if(x<0)
   {
     return -1;
   }
   else
   {
     return 0;
   }
}


inline string getTimeStampStr()
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



/*
struct appointment
{
    int day; //0-4 represents monday ... friday
    int hourStart;
    int minuteStart;
    int hourEnd;
    int minuteEnd;
    string descr;
    string color;
    appointment*next; //the pointer to next appointment

    appointment(const int date, const int startHour, const int
		startMin, const int endHour, const int endMin, const
		string des,  const string col, appointment* link=0)
	:day(date),hourStart(startHour),minuteStart(startMin),hourEnd(endHour),
	 minuteEnd(endMin),descr(des), color(col), next(link)
	{
	    
	}
        
};


struct rawAppointment
{
    string day;
    string time;
    string descr;
    string color;
   

    rawAppointment(const string date, const string hour,const string
		   describe, const string col ="\"pink\"")
	:day(date),time(hour),descr(describe), color(col)
	{
	    
	}
        
};
*/

#endif
