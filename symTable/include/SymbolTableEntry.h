#ifndef _STE_H_
#define _STE_H_

#include<string>

class SymbolTableEntry {
private:
    std::string _address;
    std::string _symbolName;
    std::string _type;
    std::string _typeAddr;
public:
    SymbolTableEntry(std::string addr, std::string name, std::string type, std::string tAddr){
        _address = addr;
        _symbolName=name;
        _type=type;
        _typeAddr = tAddr;
    }
    std::string getAddress() {return _address;}
    std::string getType() {return _type;}
    std::string getName() {return _symbolName;}
    std::string getTypeAddress() {return _typeAddr;}
    void print();
    bool isEqual(SymbolTableEntry &ste);
};

#endif
