#include "SymbolTable.h"
#include<iostream>
#include<fstream> // read from files
#include <sstream>
#include <iterator>
#include <ios>
// for sleep
//#include <thread>
//#include <chrono>

// Helper functions
/*
 * Split a space delimited string into a vector of strings
 */
std::vector<std::string> splitStringWithSpace(std::string &str)
{
    std::stringstream ss(str);
    std::istream_iterator<std::string> begin(ss);
    std::istream_iterator<std::string> end;
    std::vector<std::string> vstrings(begin, end);
    return vstrings;
}

/*
 * Compare two vectors va and vb
 *
 * 1. Exact match: va and vb have the exactly same set of elements
 * 2. Element not found: va has some extra elements or vb has some extra elements
 * 3. Element not match: va and vb both have an element, but some property of the
 *    element do not match
 *
 * Elements are identified by their names (_symbolName)
 *
 * Note that vec0 is assumed to be the correct vector
 */
#define ISEQUAL(entryT)                                                 \
    bool isEqual##entryT (std::vector<entryT>& vec0, std::vector<entryT>& vec1) \
    {                                                                   \
        bool rflag = true;                                              \
        bool found = false;                                             \
        std::vector<int> visited(vec0.size(), 0);                       \
        for (auto& v1i : vec1){                                         \
            found = false;                                              \
            for (unsigned long i=0 ; i< vec0.size(); ++i){              \
                if (v1i.getName() == vec0.at(i).getName()){             \
                    if (!v1i.isEqual(vec0.at(i))){                      \
                        std::cout<<"Symbol " <<v1i.getName()<<" has incorrect field(s)\n"; \
                        std::cout<<"Sample: "; vec0.at(i).print();      \
                        std::cout<<"Yours:  "; v1i.print();             \
                        rflag = false;                                  \
                    }                                                   \
                    visited[i]=1;                                       \
                    found = true;                                       \
                }                                                       \
            }                                                           \
            if (!found){                                                \
                std::cout<<"Extra symbol "<<v1i.getName()<<"\n";        \
                rflag = false;                                          \
            }                                                           \
        }                                                               \
        for (unsigned long i=0 ; i< vec0.size(); ++i)                   \
            if (visited[i] == 0){                                       \
                std::cout<<"Missing symbol "<<vec0.at(i).getName()<<"\n"; \
                rflag=false;                                            \
            }                                                           \
        return rflag;                                                   \
    }                                                                   \

ISEQUAL(VAREntry);
ISEQUAL(TYPEEntry);
ISEQUAL(CONSTEntry);

// Member function definitions
bool SymbolTable::isTypeLine(std::string& line)
{
    std::vector<std::string> vstrings = splitStringWithSpace(line);
    /*
     * Not enough fields => must be a type line
     */
    if ( vstrings.size() < 3)
        return true;
    /*
     * When the third field is either TYPE, CONST, or VAR
     * return false
     */
    if ( (vstrings[2]==std::string("TYPE")) ||
         (vstrings[2]==std::string("CONST")) ||
         (vstrings[2]==std::string("VAR")))
        return false;
    return true;
}


void SymbolTable::printTable()
{
    // Print types
    for (auto& ti : getTypes())
        ti.print();

    // Print consts
    for (auto& ci : getConsts())
        ci.print();

    // Print vars
    for (auto& vi : getVars())
        vi.print();
}

void SymbolTable::buildFromFile(std::string &filename)
{
    std::ifstream ifs;
    ifs.open(filename, std::ifstream::in);
    std::string line;
    std::vector<std::string> vstrings;
    if (ifs.is_open()){
        while (getline(ifs, line)){
            /*
             * Algorithm:
             *   It is assumed that the first line of the symbol
             *   table is an entry.
             *   For each entry line, we first determine what kind
             *   of symbol it is and process each kind accordingly.
             *   Note that for each kind, we also call getline()
             *   several times to consume the symbol's type if
             *   the type is a user defined type. Therefore,
             *   the getline in the while loop condition will
             *   always get an entry line.
             *
             * When we need to call getline() multiple times to
             * to consume the user defined type?
             *   - If the entry is a TYPE
             *   - If the entry is a VAR and its vstrings[5] is
             *     something other than "integer" or "real"
             *
             * How to implement peek?
             *   By using tellg() and seekg(), see details below.
             */
            vstrings=splitStringWithSpace(line);
            if (vstrings[2] == std::string("TYPE")){
                /*
                 * When the entry is a TYPE, the type field is always
                 * a user defined type, so we can safely call getline()
                 * again before get into the while loop
                 *
                 * Note that line can be reused here to get each line
                 * of the type
                 */
                getline(ifs, line); // <--- first line of type
                std::string type=line;
                /*
                 * Now before we call getline again, we need to
                 * save the position in case we need to roll back
                 */
                int curPos = ifs.tellg();
                getline(ifs, line); // <--- second line of type
                /*
                 * We can continue to consume line if
                 *   1. the line is a type line and
                 *   2. we are NOT reaching EOF
                 */
                while(!ifs.eof() && isTypeLine(line)){
                    /*
                     * When the line is a type, concatenate it to type,
                     * save the position, and getline again.
                     */
                    type = type + "\n" + line;
                    curPos = ifs.tellg();
                    getline(ifs, line);
                }
                /*
                 * When we get out of the loop here, the got line
                 * is not a type line. Therefore, we need to roll back
                 * to the previous saved position
                 */
                if (!ifs.eof())
                    ifs.seekg(curPos, std::ios_base::beg);
                /*
                 * Now we are ready to create an instance of TYPEEntry
                 */
                TYPEEntry te(vstrings[0], vstrings[1], type, vstrings[4], std::stoi(vstrings[8]), std::stoi(vstrings[10]));
                addType(te);
            }
            else if (vstrings[2] == std::string("CONST")){
                /*
                 * For const symbols, we do not need to check its type.
                 * The only trick is to determine the basicdt of the constant
                 *
                 * Note that we assume that a constant is either an integer or
                 * or a double. We do not consider a string constant here.
                 */
                if (vstrings[4] == std::string("INTEGER")){
                    CONSTEntry ce(vstrings[0], vstrings[1], vstrings[4], std::stoi(vstrings[6]), 0.0);
                    addConst(ce);
                }
                else {
                    CONSTEntry ce(vstrings[0], vstrings[1], vstrings[4], 0, std::stod(vstrings[6]));
                    addConst(ce);
                }
            }
            else if (vstrings[2] == std::string("VAR")){
                /*
                 * Processing VAR is very similar to TYPE except that
                 * for a VAR we need to check if the VAR's type is
                 * user defined or not. This can be done by checking
                 * vstrings[5]
                 */
                if ( (vstrings[5] == std::string("integer")) ||
                     (vstrings[5] == std::string("real"))){
                    VAREntry ve(vstrings[0], vstrings[1], vstrings[5], vstrings[5], std::stoi(vstrings[9]), std::stoi(vstrings[11]), std::stoi(vstrings[3]));
                    addVar(ve);
                }
                else {
                    getline(ifs, line); // <--- first line of type
                    std::string type=line;
                    int curPos = ifs.tellg();
                    getline(ifs, line); // <--- second line of type
                    while(!ifs.eof() && isTypeLine(line)){
                        type = type + "\n" + line;
                        curPos = ifs.tellg();
                        getline(ifs, line);
                    }
                    if (!ifs.eof())
                        ifs.seekg(curPos, std::ios_base::beg);
                    VAREntry ve(vstrings[0], vstrings[1], type, vstrings[5], std::stoi(vstrings[9]), std::stoi(vstrings[11]), std::stoi(vstrings[3]));
                    addVar(ve);
                }
            }
            else
                std::cout<<"!!! unprocessed line: "<<line<<" !!!\n";
        }
        ifs.close();
    }
    else
        std::cout<<"Unable to open file "<<filename<<"\n";
}


void SymbolTable::establishMap()
{
    if (getTypes().size() > 0)
        for (auto& vi : getVars()){
            for (auto& ti : getTypes()){
                if (vi.getType() == ti.getType())
                    mapVarToType(vi,ti);
            }
        }
}

bool SymbolTable::isEqual(SymbolTable &correctST)
{
    /*
     * First check if symbols have incorrect fields
     *
     * Note that at this phase, we do not check
     * type address matching
     */
    bool rflag = true;
    auto correctVars = correctST.getVars();
    auto myVars = getVars();
    bool varsEqual = isEqualVAREntry(correctVars, myVars);
    auto correctTypes = correctST.getTypes();
    auto myTypes = getTypes();
    bool typesEqual = isEqualTYPEEntry(correctTypes,myTypes);
    auto correctConsts = correctST.getConsts();
    auto myConsts = getConsts();
    bool constsEqual = isEqualCONSTEntry(correctConsts,myConsts);
    if ( !varsEqual || !typesEqual || !constsEqual)
        rflag = false;
    /*
     * Second, we check if the offset of vars are correct
     *
     * 1. Get the alignment table from the correct st
     * 2. For each VAR
     *    - Get its alignment
     *    - Compute its correct offset according to the alignment
     *    - Compare the correct offset with its shown offset
     */
    /*
     * Third, we check if some VAR's type are correctly set
     *
     * 1. Get the correct VAR->TYPE map from the correct st
     * 2. For each VAR, if it is in the map
     *    - check if its type address equals to the TYPE's type address
     */
    int correctOff = 0;
    int myOff = 0;
    int align = 0;
    auto aMap = correctST.getAlign();
    auto tMap = correctST.getMap();
    std::string vName;
    int typeDefined = correctST.getTypes().size();
    for (auto & vi : myVars){
        myOff = vi.getOffset();
        vName = vi.getName();
        /*
         * Checking for offset
         */
        auto mi = aMap.find(vName);
        if (mi != aMap.end()){
            align = mi->second;
        }
        else
            std::cout<<"Cannot find the VAR\n";
        correctOff = ((correctOff+align-1)/align)*align;
        if (myOff != correctOff){
            std::cout<<"Incorrect offset for \""<<vName<<"\"\n";
            rflag = false;
        }
        correctOff += vi.getSize();
        /*
         * Checking for type address
         *
         * Note that we do NOT need to check types
         * if no user defined types are found
         */
        if (typeDefined){
            auto tmi = tMap.find(vName);
            if (tmi != tMap.end()){
                // vi.getName()
                // tmi->second
                if (!checkTypeAddress(vName,tmi->second)){
                    std::cout<<vName<<"'s type address does not match "<<tmi->second<<"'s\n";
                    rflag = false;
                }
            }
            else{
                /*
                 * When var is not found in the type map,
                 * it is not defined as a user defined type.
                 * Then nothing needs to be done.
                 */
            }
        }
    }
    return rflag;
}

void SymbolTable::setupAlignMap(std::string& filename){
    std::ifstream ifs;
    ifs.open(filename, std::ifstream::in);
    std::string line;
    std::vector<std::string> vstrings;
    if (ifs.is_open()){
        while (getline(ifs, line)){
            vstrings=splitStringWithSpace(line);
            _mapAlign.insert(std::pair<std::string, int>(vstrings[0], std::stoi(vstrings[1])));
        }
        ifs.close();
    }
}

bool SymbolTable::checkTypeAddress(std::string& vName, std::string& tName)
{
    std::string vTypeAddr, tTypeAddr;
    for (auto & vi : getVars()){
        if (vi.getName() == vName){
            vTypeAddr = vi.getTypeAddress();
            break;
        }
    }
    for (auto & ti : getTypes()){
        if (ti.getName() == tName){
            tTypeAddr = ti.getTypeAddress();
            break;
        }
    }
    return vTypeAddr == tTypeAddr;
}
