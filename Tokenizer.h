#ifndef JUNFEI_TOKENIZER_H
#define JUNFEI_TOKENIZER_H

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

/* Tokenizer.h
 *
 * This class is to ...
 * 
 * @Junfei Geng, 20151003
 * */


// default delimiter string (space, tab, newline, carriage return, form feed)
const string DEFAULT_DELIMITER = " \t\v\n\r\f";

class Tokenizer
{
public:
    // ctor/dtor
    Tokenizer();
    Tokenizer(const string& str, const string& delimiter=DEFAULT_DELIMITER);
    ~Tokenizer();

    // set string and delimiter
    void set(const string& str, const string& delimiter=DEFAULT_DELIMITER);
    void setString(const string& str);             // set source string only
    void setDelimiter(const string& delimiter);    // set delimiter string only

    string next();                                 // return the next token, return "" if it ends

    vector<string> split();                   // return array of tokens from current cursor

protected:


private:
    void skipDelimiter();                               // ignore leading delimiters
    bool isDelimiter(char c);                           // check if the current char is delimiter

    string buffer;                                 // input string
    string token;                                  // output string
    string delimiter;                              // delimiter string
    string::const_iterator currPos;                // string iterator pointing the current position

};


#endif

 
