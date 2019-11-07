#include"SymbolTableEntry.h"
#include<iostream>

void SymbolTableEntry::print()
{
    std::cout<<getAddress()<<"\t"<<getName()<<"\t";
}

bool SymbolTableEntry::isEqual(SymbolTableEntry &ste)
{
    return ( (this->getName() == ste.getName()) &&
             (this->getType() == ste.getType()) );
}
