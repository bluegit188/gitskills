#ifndef JUNFEI_DAILYRTH_H
#define JUNFEI_DAILYRTH_H

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

#include "/home/jgeng/junfei_lib/JunfUtil.h"

using namespace std;

/* DailyRTH.h
 *
 * This class is to ...
 * 
 * @Junfei Geng, 20150602
 * */


struct DailyRTHUnit
{  
    string sym;
    int date;

    double open;
    double high;
    double low;
    double close;
    double tc;
    int vol;
    int oi;
    string contractYM;
    double spd;
    double cumSpd;

    // other derived
    double FVOO;


    void print (ostream & out) const
    {
        out <<date<<" "
            <<sym<<" "
            <<"open="<<open<<" "
            <<"high="<<high<<" "
            <<"low="<<low<<" "
            <<"close"<<close<<" "
            <<contractYM<<" "
            <<spd<<" "
            <<cumSpd<<endl;
    }

};


class DailyRTH
{
  public:
    DailyRTH();                             // constructor
    DailyRTH(const string filename);        // constructor
    ~DailyRTH();                            // destructor

    // easy access
    const DailyRTHUnit & operator [] ( const int loc );
    int  size() const{return mySize;}        // return size
    void  print();
    bool read(const string filename);
    int findLocOfDate(int date);

    bool insertAtLast(DailyRTHUnit du);
    bool insert(DailyRTHUnit du);          //insert, replace if any

    double getGAP(int loc);
    double getO(int loc);
    double getH(int loc);
    double getL(int loc);
    double getC(int loc);

    double getOOP1D(int loc);

    double getYHC(int loc);
    double getYLC(int loc);
    double getYMC(int loc);

  private:
    double getStd(vector<double>&Xs);
    void computeFVOO();
   
  private:

    int    mySize;                      // number of records

  public:
    vector<DailyRTHUnit> myStorage;

};

#endif

 
