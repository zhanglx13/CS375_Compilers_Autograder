#ifndef _CONSTENTRY_H_
#define _CONSTENTRY_H_

#include "SymbolTableEntry.h"

class CONSTEntry : public SymbolTableEntry{
private:
    int   _intnum;
    double _realnum;
public:
    CONSTEntry(std::string addr, std::string name, std::string type, int intnum, double realnum): SymbolTableEntry(addr, name, type, type){
        _intnum=intnum;
        _realnum=realnum;
    }
    void print();
    int getInt() {return _intnum;}
    double getReal() {return _realnum;}
    bool isEqual(CONSTEntry &te);
};

#endif
