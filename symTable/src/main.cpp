// On MacOS, remember to add export CPATH=`xcrun --show-sdk-path`/usr/include in .bash_profile so that clang can find the necessary headers

#include "SymbolTable.h"
#include<iostream>

int main(int argc, char *argv[])
{
    SymbolTable st, myST;

    if (argc < 4)
        std::cout<<"please specify 2 symbol table files and 1 align file\n";
    else{
        //std::cout<<"Reading symbol table from file\n\n";
        std::string correctSTFile(argv[1]);
        st.buildFromFile(correctSTFile);
        std::string mySTFile(argv[2]);
        myST.buildFromFile(mySTFile);
        std::string alignFile(argv[3]);
        st.setupAlignMap(alignFile);
        //std::cout<<"print out correct symbol table:\n";
        //st.printTable();
        //std::cout<<"\n\n";
        st.establishMap();
#if 0
        std::map<std::string, std::string> mapVT = st.getMap();
        for (auto& mi : mapVT){
            std::cout<<mi.first<<" ---> "<<mi.second<<"\n";
        }
        auto mapA = st.getAlign();
        for (auto& ai : mapA){
            std::cout<<ai.first<<" ---> "<<ai.second<<"\n";
        }
        std::cout<<"\nComparing two tables\n";
#endif
        myST.isEqual(st);
    }
    return 0;
}
