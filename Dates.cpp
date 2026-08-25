#include "Dates.h"



Dates::Dates()
{
    mySize=0;

    initDOMB();

}


Dates::~Dates()
{
   // to do
}

void Dates::print()
{
    // to do
}

void Dates::initDOMB()
// do some prep work so DOMb calcs can be faster
{

   vector<int> datesVec=getBizDatesVecExUSHolidays(19800101,20200101);

   // create a YMMap: YM-> vec of dates in the month, to make DOMB cals faster   
   map<int,vector<int> >::iterator iter;
   for (size_t i=0;i<datesVec.size();i++)
   {
      int date=datesVec[i];
      //cout<<date<<endl;


       //int YYYY=int(date/10000);
       int MMDD=date%10000;
       //int MM=int(MMDD/100);
       int DD=MMDD%100;
       int YM=int(date/100);

       iter = myYMMap.find(YM);
       if( iter != myYMMap.end())
       {
	  iter->second.push_back(DD); // pos for this sym
       }
       else
       {
	  vector<int>vec;
	  vec.push_back(DD);
	  myYMMap.insert(make_pair(YM,vec));
       }

   }

}


int Dates::getDOMB(int date)
// get DOM in biz dates
// if something wrong, return -1
{

    //int YYYY=int(date/10000);
    int MMDD=date%10000;
    //int MM=int(MMDD/100);
    int DD=MMDD%100;
    int YM=int(date/100);

    map<int,vector<int> >::iterator iter = myYMMap.find(YM);

    if( iter == myYMMap.end())
    {
      return -1;
    }

    vector<int> domVec=iter->second; // pos for this sym

    /*    
    cout<<"domVec= "<<YM<<", ";
    for(int i=0;i<domVec.size();i++)
    {
       cout<<domVec[i]<<" ";
    }
    cout<<endl;
    */

    int loc=findDOMLocByDate(DD,domVec);

    //#print "loc=$loc\n";

    int DOMB=-1;
    if(loc != -1)
    {
       DOMB=loc+1;
    }
    return DOMB;

}



int Dates::getDOMBB(int date)
// get DOM in biz dates
// if something wrong, return -1
{

    //int YYYY=int(date/10000);
    int MMDD=date%10000;
    //int MM=int(MMDD/100);
    int DD=MMDD%100;
    int YM=int(date/100);

    map<int,vector<int> >::iterator iter = myYMMap.find(YM);

    if( iter == myYMMap.end())
    {
      return -1;
    }

    vector<int> domVec=iter->second; // pos for this sym

    /*    
    cout<<"domVec= "<<YM<<", ";
    for(int i=0;i<domVec.size();i++)
    {
       cout<<domVec[i]<<" ";
    }
    cout<<endl;
    */

    int loc=findDOMLocByDate(DD,domVec);

    //#print "loc=$loc\n";

    int size=domVec.size();

    //cout<<"size="<<size<<endl;

    int DOMBB=-1;
    if(loc != -1)
    {
       //DOMB=loc+1;
       DOMBB=size-loc;
    }
    return DOMBB;

}



int Dates::findDOMLocByDate(int DD, vector<int> domVec)
// find the loc of a day in the DOM vec
// input: xvar and a vecRef
// output: loc of first occurance with date matching
// if not found, ret -1
{

    // scan from front to back
    int loc=-1;


    int last=domVec[domVec.size()-1];
    if(DD >= last)
    {
      return domVec.size()-1;
    }

    for(unsigned int k=0;k<=domVec.size()-1;k++)
    {
       int entry=domVec[k];
       int entryNext=domVec[k+1];

       int x=entry;
       //#print "value=$value, x=$x\n";
       if(DD >= x && DD < entryNext)
       {
          return k;
       }
    }

    return loc;

}

vector<int> Dates::getDatesVec(int startDate, int endDate)
{

    int date=startDate;
    vector<int> dateVec;
    while(date<= endDate)
    {
       dateVec.push_back(date);
       date=getNextDate(date);
    }

    return dateVec;
}


vector<int> Dates::getBizDatesVec(int startDate, int endDate)
{

    int date=startDate;
    vector<int> dateVec;
    while(date<= endDate)
    {

       int dow=getDOWFast(date);

       if(dow !=0 && dow !=6)
       {
	 dateVec.push_back(date);
       }

       date=getNextDate(date);
    }

    return dateVec;
}


vector<int> Dates::getBizDatesVecExUSHolidays(int startDate, int endDate)
{

    int date=startDate;
    vector<int> dateVec;
    while(date<= endDate)
    {

       int dow=getDOWFast(date);

       //int YYYY=int(date/10000);
       int MMDD=date%10000;
       //int MM=int(MMDD/100);
       //int DD=MMDD%100;
   
       if(dow !=0 && dow !=6)
       {

          if(MMDD != 101 &&
             //$MMDD != "0704" &&
             MMDD != 1225 )
	  {
	    dateVec.push_back(date);
	  }
       }

       date=getNextDate(date);
    }

    return dateVec;
}



int Dates::getDateIdx(int date)
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


int Dates::dateDif(int date1, int date2)
{
   //cout<<getDateIdx(date2)<<" "<< getDateIdx(date1)<<" dif="<<getDateIdx(date2)- getDateIdx(date1)<<endl;
   return getDateIdx(date2)- getDateIdx(date1);
}




int Dates::bizDateDif(int date1, int date2)
// don't count weekends
{
     if(date1<=date2)
     {
          vector<int> datesVec=getBizDatesVec(date1 , date2);
	  return datesVec.size()-1;  
     }
     else
     {
          vector<int> datesVec=getBizDatesVec(date2 , date1);
	  return datesVec.size()-1;  

     }

     return -999; // won't reach here
}







int days_in_month[] = { 0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };


int Dates::isLeapYear(int year) 
{
    return ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0);
}


int Dates::getNextDate(int date) 
{

   int YYYY=int(date/10000);
   int MMDD=date%10000;
   int MM=int(MMDD/100);
   int DD=MMDD%100;
   
   int eomDates[] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };

   int eomDate=eomDates[MM-1];
   if(MM==2 && isLeapYear(YYYY))
   {
     eomDate=29;
   }

   int newDD=DD+1;
   int newMM=MM;
   int newYYYY=YYYY;

   if(newDD > eomDate)
   {
     newDD=1;
     newMM+=1;

     if(newMM==13)
     {
       newMM=1;
       newYYYY+=1;
     }
   }

    // dateET
    static char result[8];
    sprintf(result, "%4d%02d%02d",newYYYY,newMM,newDD);
    return atoi(result);

}


string Dates::itoa(int a)
{
    string ss="";   //create empty string
    while(a)
    {
        int x=a%10;
        a/=10;
        char i='0';
        i=i+x;
        ss=i+ss;      //append new character at the front of the string!
    }
    return ss;
}


int Dates::getDOWFast(int date)
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



int Dates::getMOY(int date)
// get MOY
// if something wrong, return -1
{

    //int YYYY=int(date/10000);
    int MMDD=date%10000;
    int MM=int(MMDD/100);
    //int DD=MMDD%100;
    //int YM=int(date/100);
    return MM;
}

int Dates::getDOM(int date)
// get DOM
// if something wrong, return -1
{

    //int YYYY=int(date/10000);
    int MMDD=date%10000;
    //int MM=int(MMDD/100);
    int DD=MMDD%100;
    //int YM=int(date/100);

    return DD;


}
