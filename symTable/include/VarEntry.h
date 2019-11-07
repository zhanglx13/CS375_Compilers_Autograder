#ifndef _VARENTRY_H_
#define _VARENTRY_H_

#include "SymbolTableEntry.h"

class VAREntry : public SymbolTableEntry{
private:
    int _size;
    int _offset;
    int _basicdt;
public:
    VAREntry(std::string addr, std::string name, std::string type, std::string tAddr, int size, int offset, int basicdt): SymbolTableEntry(addr, name, type, tAddr){
        _size=size;
        _offset=offset;
        _basicdt=basicdt;
    }
    void print();
    int getSize() {return _size;}
    int getOffset() {return _offset;}
    int getBasicdt() {return _basicdt;}
    bool isEqual(VAREntry &te);
};

#endif
