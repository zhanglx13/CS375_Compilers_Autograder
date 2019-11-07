//===-- SymbolTable.h - Symbol Table class definition -------*- C++ -*-===//
#ifndef _ST_H_
#define _ST_H_

#include "TypeEntry.h"
#include "VarEntry.h"
#include "ConstEntry.h"
#include<vector>
#include<map>


class SymbolTable {
private:
    std::vector<TYPEEntry> _types;
    std::vector<CONSTEntry> _consts;
    std::vector<VAREntry> _vars;
    std::map<std::string, std::string> _mapVARToTYPE;
    std::map<std::string, int> _mapAlign;
public:
    /*
     * Construct a symbol table instance from a file.
     *
     * This function fills _types, _consts, and _vars by
     * calling other member functions such as addType()
     */
    void buildFromFile(std::string&);
    void setupAlignMap(std::string&);
    /*
     * Print the symbol table to stdout
     */
    void printTable();
    /*
     * The following three member functions are helpers
     * used by buildFromFile
     */
    void addType(TYPEEntry &te){_types.push_back(te);}
    void addVar(VAREntry &ve){_vars.push_back(ve);}
    void addConst(CONSTEntry &ce){_consts.push_back(ce);}
    /*
     * get functions
     */
    std::vector<TYPEEntry> getTypes(){return _types;}
    std::vector<VAREntry> getVars(){return _vars;}
    std::vector<CONSTEntry> getConsts(){return _consts;}
    std::map<std::string, std::string> getMap() {return _mapVARToTYPE;}
    std::map<std::string, int> getAlign() {return _mapAlign;}
    /*
     * Insert the mapping of a VAR to its TYPE into the map
     */
    void mapVarToType(VAREntry &ve, TYPEEntry &te) {_mapVARToTYPE.insert(std::pair<std::string, std::string>(ve.getName(), te.getName()));}
    /*
     * After the symbol table is constructed, go over its vars and types and
     * insert all pair of VAR->TYPE mappings by calling mapVarToType()
     *
     * Note that this function should only be called by the instance that
     * represents the correct symbol table
     */
    void establishMap();
    /*
     * Check if a line in the symbol table belongs to a type definition
     */
    bool isTypeLine(std::string&);
    /*
     * Compare the current symbol table with the correct one.
     *
     * Note that this function should be called by the instance that represents
     * the student's input symbol table
     */
    bool isEqual(SymbolTable &);
    /*
     * Check if the type address of the given two symbols are the same
     *
     * Note that the first argument is the name of VAR symbol and
     * the second argument is the name of the TYPE symbol
     */
    bool checkTypeAddress(std::string&, std::string&);
};

#endif
