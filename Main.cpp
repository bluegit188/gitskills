#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <ctime>
#include <iostream>
#include <cstring>
#include <stdlib.h>
#include <map>

#include "JunfUtil.h"
#include "Tokenizer.h"
#include "TimeZones.h"


using namespace std;

/*
ostream & operator<< (ostream& out, const TZUnit & s)
{
    s.print(out);
    return out;
}
*/

int main (int argc, char ** argv)
{

   // open file named on the command-line for reading
   if (argc !=3)
   {
       cerr << "usage: " << argv[0] << " <DATE.LT>" <<" <isDictOrder=1/0/2>"<< endl; 
       cerr << "       Compute open/close times in LT and ET for sym univ" << endl;
       cerr << "       isDictOrder: 1=alphabetic order, 0=order by open times" << endl;
       cerr << "                    2=don't change order in file" << endl;
       cerr << "       dtaeLT=local time, e.g, Japan date" << endl;
       cerr << "       output format: SYM dateLT otLT ctLT dateETOpen otET dateETClose clET"<< endl;
       exit(1);
   }

   
   int dateLT=atoi(argv[1]);

   int isDictOrder=atoi(argv[2]);


   //dateLT=20151009;
   TimeZones tz(dateLT);
   //tz.print();

   if(isDictOrder==1)
   {
      tz.printByAlphabetOrder();
   }
   else if (isDictOrder==0 )
   {
      tz.printByOpenTimes();
   }
   else if (isDictOrder==2 )
   {
     tz.printUnsorted(); // based on row order in the file
   }
   else
   {
     // do nothing here
   }

   return EXIT_SUCCESS;

}





   /* //convert local date/time to EST date/time
   //local timezone times
   string tzname="America/Chicago";
   dateLT=20151009;
   int hhmmssLT=83000;

   //convert to ET
   int dateET,hhmmssET;
   tz.convertToETDateTime(dateLT,hhmmssLT,tzname,dateET,hhmmssET);
   cout<<"CT: "<<dateLT<<" "<<hhmmssLT<<endl;
   cout<<"ET: "<<dateET<<" "<<hhmmssET<<endl;
   */
