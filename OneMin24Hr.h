#ifndef JUNFEI_ONEMIN24HR_H
#define JUNFEI_ONEMIN24HR_H

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
#include "DailyRTH.h"


using namespace std;

/* OneMin24Hr.h
 *
 * This class is to read and process onemin/24Hr data from Portara
 * 
 * @Junfei Geng, 20150601
 * */

struct OhlcUnit
{
  double open;
  double high;
  double low;
  double close; 
  double cumAdj; // e.g, CL 20220914 cumAdj change at 1AM

  int dateRaw; // for 24hr data, I add Sunday data to Fri, keep rawDate for verification
               //

  OhlcUnit() :open(0),high(0),low(0),close(0),cumAdj(0),dateRaw(0)
  {
  }

  OhlcUnit(double o,double h,double l,double c,double cumAdj,int dateR) :open(o),high(h),low(l),close(c),cumAdj(cumAdj),dateRaw(dateR)
  {
  }


};

struct SessionTimeUnit
{
  int date;
  int openTime;
  int closeTime;
};

struct OneMinUnit
{  
  string sym;
  int date;
  //int time; // HHMMSS
  vector<OhlcUnit> ohlcs;
  int numValidRows; // number of valid minutes
  int openTime;
  int closeTime;
  double FVOO;      //FVOO and cumAdj from dailyRTH
  double cumAdj;  
  double open;
  double high;
  double low;
  double close;

  //string contractYM;
  //double cumAdj;
  //tc vol oi sym ym adj cumAdj
  const OhlcUnit & operator [] ( const int hhmmss );


  double  compute_bwd_ret_A_to_B(int minIdx1, int minIdx2,double cumAdj,double FVOO);
  double  compute_fwd_ret_A_to_B(int minIdx1, int minIdx2,double cumAdj,double FVOO);
  double  compute_fwd_ret_A_to_B_1minOpen(int minIdx1, int minIdx2,double cumAdj,double FVOO);

  double compute_fwd_ret_A_to_B_1minOO(int minIdx1, int minIdx2,double cumAdj,double FVOO);

  double  compute_CHGSO(int minIdx, double open, double cumAdj,double FVOO);

  double compute_PL2C(int minIdx, double close,double cumAdj,double FVOO);
  double compute_PL2NO(int minIdx, double cumAdj1, double open2,double cumAdj2,double FVOO);
  double compute_PLCO(double close, double cumAdj1, double open2,double cumAdj2,double FVOO);


  double  compute_HSO(int minIdxOpen,int minIdx, double todayOpen,double cumAdj,double FVOO);
  double  compute_LSO(int minIdxOpen,int minIdx, double todayOpen,double cumAdj,double FVOO);

  //CLCAO style, can get intra-gap point
  double  compute_fwd_ret_A_to_B_clcao(int minIdx1, int minIdx2,double FVOO);

};

class OneMin24Hr
{
  public:
    OneMin24Hr();                             // constructor
    OneMin24Hr(const string filename);             // constructor
    ~OneMin24Hr();                            // destructor

    
    int  size() const{return mySize;}        // return size
    void print();
    bool read(const string filename);
   
    // access operator
    const OneMinUnit & operator [] ( const int loc );
    vector<int> getHHMMSSVec(){return myHHMMSSVec; }

    double getGAP(int loc);
    double getO(int loc);
    double getH(int loc);
    double getL(int loc);
    double getC(int loc);

    double getOOP1D(int loc);

    double getYHC(int loc);
    double getYLC(int loc);
    double getYMC(int loc);
    double getYOC(int loc);
    double getYHL(int loc);


    double getTHC(int loc); //today HC and LC
    double getTLC(int loc);
    double getTOC(int loc);


    double getCC1(int loc); // for CL CC1 type of indicator


  private:
    void fillOhlcVec(vector<OhlcUnit>& ohlcVec, vector<OhlcUnit>& newOhlcVec);
    void assignOpenCloseTimes();
    int  findLocForSession(vector<SessionTimeUnit>& stuVec,int date);

    void intersectDailyRTH(DailyRTH & df);


  private:

    int    mySize;                      // number of records
    string mySym;
    
 public:
    vector<OneMinUnit> myStorage;
    vector<int> myHHMMSSVec;              // hhmmss for each minute

};

#endif

 
