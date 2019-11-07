#include "TypeEntry.h"

#include<iostream>

void TYPEEntry::print()
{
    SymbolTableEntry::print();
    std::cout<<"TYPE\t"<<getSize()<<"\t"<<getOffset()<<"\n";
    std::cout<<SymbolTableEntry::getType()<<"\n";
}

bool TYPEEntry::isEqual(TYPEEntry& te)
{
    return ( this->SymbolTableEntry::isEqual(te) &&
             (this->getSize() == te.getSize()) &&
             (this->getOffset() == te.getOffset()));
}
