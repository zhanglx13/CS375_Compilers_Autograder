#include "ConstEntry.h"
#include<iostream>

void CONSTEntry::print()
{
    SymbolTableEntry::print();
    if (SymbolTableEntry::getType() == std::string("INTEGER"))
        std::cout<<"CONST  INTEGER  "<<getInt()<<"\n";
    else
        std::cout<<"CONST  REAL     "<<getReal()<<"\n";
}

bool CONSTEntry::isEqual(CONSTEntry& te)
{
    if (! this->SymbolTableEntry::isEqual(te)) return false;

    if (SymbolTableEntry::getType() == std::string("INTEGER"))
        return this->getInt() == te.getInt();
    else
        return this->getReal() == te.getReal();
}
