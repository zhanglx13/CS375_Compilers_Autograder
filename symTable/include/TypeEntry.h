#ifndef _TYPEENTRY_H_
#define _TYPEENTRY_H_

#include "SymbolTableEntry.h"

class TYPEEntry : public SymbolTableEntry {
private:
    int _size;
    int _offset;
public:
    TYPEEntry(std::string addr, std::string name, std::string type, std::string tAddr, int size, int offset): SymbolTableEntry(addr, name, type, tAddr){
        _size=size;
        _offset=offset;
    }
    void print();
    int getSize() {return _size;}
    int getOffset() {return _offset;}
    bool isEqual(TYPEEntry &te);
    //void readFromString(std::string &);
};

#endif
