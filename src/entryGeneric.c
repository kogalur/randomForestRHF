
// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***
#include           "shared/globalCore.h"
#include           "shared/externalCore.h"
#include           "global.h"
#include           "external.h"

// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***

      
    

#include "entryGeneric.h"
#include "shared/error.h"
char processDefaultGrow(void) {
  RF_opt = RF_opt | OPT_LEAF;
  if ( !(RF_opt & OPT_BOOT_TYP1) && !(RF_opt & OPT_BOOT_TYP2)) {
    RF_optHigh = RF_optHigh & (~OPT_BOOT_SWOR);
    RF_opt                  = RF_opt & (~OPT_OENS);
    RF_opt                  = RF_opt & (~OPT_PERF);
  }
  if (RF_opt & OPT_TREE) {
    RF_opt = RF_opt | OPT_SEED;
  }
  else {
    RF_opt = RF_opt & (~OPT_SEED);
  }
  RF_opt = RF_opt | OPT_EMPR_RISK;
  if ((RF_opt & OPT_OENS) || (RF_opt & OPT_IENS)) {
  }
  else {
    RF_optHigh = RF_optHigh & (~OPT_TERM_OUTG);
  }
  if (!(RF_opt & OPT_OENS)) {
    RF_opt = RF_opt & (~OPT_PERF);
  }
  RF_getTree              = NULL;
  RF_yWeight = RF_xWeightStat = NULL;  
  return RF_GROW;
}
char processDefaultPredict(void) {
  char mode;
  RF_opt = RF_opt & (~OPT_TREE);
  RF_opt = RF_opt & (~OPT_SEED);
  RF_opt = RF_opt | OPT_LEAF;
  RF_opt = RF_opt & (~OPT_EMPR_RISK);
  if(RF_fobservationSize > 0) {
    mode = RF_PRED;
  }
  else if (SG_optLocal & SG_OPT_REAL_TIME){
    mode = RF_REAL;
  }
  else {
    mode = RF_REST;
  }
  switch (mode) {
  case RF_PRED:
    RF_opt = RF_opt & (~OPT_OENS);
    if (RF_frSize == 0) {
      RF_opt                  = RF_opt & (~OPT_PERF);
    }
    break;
  case RF_REAL:
    RF_frSize = RF_fobservationSize = 0;
    RF_opt = RF_opt & (~OPT_OENS);
    RF_opt = RF_opt & (~OPT_PERF);
    RF_optHigh = RF_optHigh & (~OPT_MEMB_USER);
    break;
  case RF_REST:
    RF_frSize = RF_fobservationSize = 0;
    if (!(RF_opt & OPT_OENS)) {
      RF_opt = RF_opt & (~OPT_PERF);
    }
    break;
  }
  RF_xWeight = RF_yWeight = RF_xWeightStat = NULL;  
  return mode;
}
