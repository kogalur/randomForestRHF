
// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***
#include           "shared/globalCore.h"
#include           "shared/externalCore.h"
#include           "global.h"
#include           "external.h"

// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***

      
    

#include "termOps.h"
#include "node.h"
#include "augmentationOpsCommon.h"
#include "augmentationOpsSimple.h"
#include "augmentationOps.h"
#include "survivalTDC.h"
#include "shared/termBaseOps.h"
#include "shared/nrutil.h"
#include "terminal.h"
#include "shared/error.h"
void *makeTerminalDerived(void) {
  Terminal *parent = (Terminal*) gblock((size_t) sizeof(Terminal));
  preInitTerminalBase((TerminalBase *) parent);
  parent -> mean = 0.0;
  parent -> repMembrCount = 0;
  parent -> oobMembrCount = 0;
  parent -> ibgMembrCount = 0;
  parent -> tstMembrCount = 0;
  parent -> allMembrSize  = 0;
  parent -> repMembrIndx  = NULL;
  parent -> ibgMembrIndx  = NULL;
  parent -> oobMembrIndx  = NULL;
  parent -> tstMembrIndx  = NULL;
  parent -> ratio         = NULL;
  parent -> nodeU         = NULL;
  parent -> nodeV         = NULL;
  parent -> coeHazard     = NULL;
  parent -> coeCHF        = NULL;
  return parent;
}
void freeTerminalDerived(void *parent) {
  unstackRatio((Terminal *) parent);
  unstackCOEObjects((Terminal *) parent);
  deinitTerminalBase((TerminalBase *) parent);
  if (((Terminal *) parent) -> allMembrSize > 0) {
    free_uivector(((Terminal *) parent) -> oobMembrIndx,  1, ((Terminal *) parent) -> allMembrSize);
    free_uivector(((Terminal *) parent) -> repMembrIndx,  1, ((Terminal *) parent) -> allMembrSize);
    free_uivector(((Terminal *) parent) -> ibgMembrIndx,  1, ((Terminal *) parent) -> allMembrSize);
  }
  if (((Terminal *) parent) -> tstMembrCount > 0) {
    free_uivector(((Terminal *) parent) -> tstMembrIndx,  1, ((Terminal *) parent) -> tstMembrCount);
  }
  free_gblock(parent, (size_t) sizeof(Terminal));
}
void stackRatio(Terminal *tTerm) {
  TerminalSurvival *sTerm;
  sTerm = ((TerminalBase *) tTerm) -> survivalBase;
  tTerm -> ratio = dvector(1, sTerm -> sTimeSize);
}
void unstackRatio(Terminal *tTerm) {
  TerminalSurvival *sTerm;
  sTerm = ((TerminalBase *) tTerm) -> survivalBase;
  if (tTerm -> ratio != NULL) {
    free_dvector(tTerm -> ratio, 1, sTerm -> sTimeSize);
    tTerm -> ratio = NULL;
  }
}
void stackCOEObjects(Terminal *tTerm) {
  TerminalSurvival *sTerm;
  sTerm = ((TerminalBase *) tTerm) -> survivalBase;
  tTerm -> nodeU = dvector(1, sTerm -> sTimeSize);
  tTerm -> nodeV = dvector(1, sTerm -> sTimeSize);
  tTerm -> coeHazard = dvector(1, sTerm -> sTimeSize);
  tTerm -> coeCHF    = dvector(1, sTerm -> sTimeSize);
}
void unstackCOEObjects(Terminal *tTerm) {
  TerminalSurvival *sTerm;
  sTerm = ((TerminalBase *) tTerm) -> survivalBase;
  if (tTerm -> nodeU != NULL) {
    free_dvector(tTerm -> nodeU, 1, sTerm -> sTimeSize);
    tTerm -> nodeU = NULL;
  }
  if (tTerm -> nodeV != NULL) {
    free_dvector(tTerm -> nodeV, 1, sTerm -> sTimeSize);
    tTerm -> nodeV = NULL;
  }
  if (tTerm -> coeHazard != NULL) {
    free_dvector(tTerm -> coeHazard, 1, sTerm -> sTimeSize);
    tTerm -> coeHazard = NULL;
  }
  if (tTerm -> coeCHF != NULL) {
    free_dvector(tTerm -> coeCHF, 1, sTerm -> sTimeSize);
    tTerm -> coeCHF = NULL;
  }
}
