#ifndef MOD_PARAGON_DATA_H
#define MOD_PARAGON_DATA_H

#include "Common.h"
#include <map>

struct ParagonData {
    uint32 level = 0;
    uint32 prestigeCount = 0;
};

extern std::map<uint32, ParagonData> ParagonMap;

#endif