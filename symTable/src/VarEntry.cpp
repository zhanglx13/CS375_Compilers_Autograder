#include "VarEntry.h"
#include<iostream>

void VAREntry::print()
{
    SymbolTableEntry::print();
    if ( (SymbolTableEntry::getType() == std::string("integer")) ||
         (SymbolTableEntry::getType() == std::string("real")))
        std::cout<<"VAR\t"<<getBasicdt()<<"\t"<<SymbolTableEntry::getType()<<"\t"<<getSize()<<"\t"<<getOffset()<<"\n";
    else {
        std::cout<<"VAR\t"<<getBasicdt()<<"\t"<<getSize()<<"\t"<<getOffset()<<"\n";
        std::cout<<SymbolTableEntry::getType()<<"\n";
    }
}

// When comparing two VAR entries, offset can be different
bool VAREntry::isEqual(VAREntry& te)
{
    return  ( this->SymbolTableEntry::isEqual(te) &&
              (this->getSize() == te.getSize()) &&
              (this->getBasicdt() == te.getBasicdt()));
}
