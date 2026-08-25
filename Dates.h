#ifndef JUNFEI_DATES_H
#define JUNFEI_DATES_H

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


using namespace std;

/* Dates.h
 *
 * This class is to ...
 * 
 * @Junfei Geng, 20160720
 * */



class Dates
{
  public:
    Dates();                             // constructor
    ~Dates();                            // destructor

    
    int  size() const{return mySize;}        // return size
    void  print();

    vector<int> getDatesVec(int startDate, int endDate);
    vector<int> getBizDatesVec(int startDate, int endDate);
    vector<int> getBizDatesVecExUSHolidays(int startDate, int endDate);

    void initDOMB();
    int getDOMB(int date);
    int getDOMBB(int date);
    int findDOMLocByDate(int DD, vector<int> domVec); // find the loc of a day in the DOM vec


    int getMOY(int date);
    int getDOM(int date);

    int getDateIdx(int date);
    int dateDif(int date1, int date2);
    int bizDateDif(int date1, int date2);

    int getDOWFast(int date);

    int isLeapYear(int year) ;
    int getNextDate(int date); 
    string itoa(int a);

    


  private:

    int    mySize;                      // number of records
 
    map< int, vector<int> > myYMMap;       //YM-> vec of biz dates, for DOMB calcs

};

#endif

 
