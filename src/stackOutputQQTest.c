
// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***
#include           "shared/globalCore.h"
#include           "shared/externalCore.h"
#include           "global.h"
#include           "external.h"

// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***

      
    

#include "stackOutputQQTest.h"
#include "terminal.h"
#include "sexpOutgoing.h"
#include "shared/error.h"
#include "shared/nativeUtil.h"
#include "shared/nrutil.h"
void stackTNQualitativeObjectsTest(char      mode,
                                   uint    **pSG_ombrTNodeCT_,
                                   uint   ***pSG_ombrTNodeCT_ptr,
                                   uint    **pSG_ombrTNodeID_) {
  ulong localSize;
  if (RF_optHigh & OPT_TERM_OUTG) {
    localSize = RF_totalTermCount;
    *pSG_ombrTNodeCT_ = (uint*) stackAndProtect(RF_auxDimConsts,
                                                mode,
                                                &RF_nativeIndex,
                                                NATIVE_TYPE_INTEGER,
                                                SG_OMBR_TN_CT,
                                                localSize,
                                                0,
                                                SG_sexpStringOutgoing,
                                                pSG_ombrTNodeCT_ptr,
                                                2,
                                                (const AuxiliaryDimension[]) {
                                                  [1] = {RF_AUX_DIM_FIXED, RF_ntree},
                                                  [2] = {RF_AUX_DIM_LEAF_COUNT, 0}
                                                });
    localSize = RF_ntree * RF_fobservationSize;
    *pSG_ombrTNodeID_ = (uint*) stackAndProtect(RF_auxDimConsts,
                                                mode,
                                                &RF_nativeIndex,
                                                NATIVE_TYPE_INTEGER,
                                                SG_OMBR_TN_ID,
                                                localSize,
                                                0,
                                                SG_sexpStringOutgoing,
                                                NULL,
                                                1,
                                                (const AuxiliaryDimension[]) {[1] = {RF_AUX_DIM_FIXED, localSize}});
    (*pSG_ombrTNodeID_) --;
  }
}
void stackTNQualitativeObjectsForestPtrTest(char     mode,
                                            uint    *sexp_ombrTNodeID_,
                                            uint ****pSG_ombrTNodeID_ptr) {
  TerminalBase *tTermBase;
  Terminal     *tTerm;
  uint treeID;
  uint termCount;
  ulong offsetID_ombr;
  ulong localSize;
  uint k;
  tTerm = NULL;  
  if (RF_optHigh & OPT_TERM_OUTG) {
    *pSG_ombrTNodeID_ptr = (uint ***) new_vvector(1, RF_ntree, NRUTIL_UPTR2);
    offsetID_ombr = 0;
    localSize = 0;
    for (treeID = 1; treeID <= RF_ntree; treeID ++) {
      termCount = RF_tLeafCount[treeID];
      (*pSG_ombrTNodeID_ptr)[treeID] = (uint **) new_vvector(1, termCount, NRUTIL_UPTR);
      for (k = 1; k <= termCount; k++) {
        tTermBase = RF_tTermList[treeID][k];
        tTerm     = (Terminal *) tTermBase; 
        (*pSG_ombrTNodeID_ptr)[treeID][k] = sexp_ombrTNodeID_ + offsetID_ombr;
        offsetID_ombr += tTerm -> tstMembrCount;
      }
      localSize += RF_fobservationSize;
    }
    if ((offsetID_ombr) != localSize) {
      RF_nativeError("\nRF-SRC:  *** ERROR *** ");
      RF_nativeError("\nRF-SRC:  Inconsistent total test data (ombr) count during aux qualitative pointering:  ");
      RF_nativeError("\nRF-SRC:  Offset versus total was:  %10llu, %10llu", (unsigned long long) offsetID_ombr, (unsigned long long) localSize);
      RF_nativeError("\nRF-SRC:  Please Contact Technical Support.");
      RF_nativeExit();
    }
  }
}
void unstackTNQualitativeObjectsForestPtrTest(char mode,
                                              uint ***ombrTNodeID_ptr) {
  uint treeID;
  uint termCount;
  if (RF_optHigh & OPT_TERM_OUTG) {
    for (treeID = 1; treeID <= RF_ntree; treeID ++) {
      termCount = RF_tLeafCount[treeID];
      free_new_vvector(ombrTNodeID_ptr[treeID], 1, termCount, NRUTIL_UPTR);
    }
    free_new_vvector(ombrTNodeID_ptr, 1, RF_ntree, NRUTIL_UPTR2);
  }
}
void writeTNQualitativeObjectsOutputTest(char mode,
                                         uint  **ombrTNodeCT,
                                         uint ***ombrTNodeID) {
  Terminal *tTerm;
  uint treeID;
  uint j, k;
  if (RF_optHigh & OPT_TERM_OUTG) {
    for (treeID = 1; treeID <= RF_ntree; treeID ++) {
      for (k = 1; k <= RF_tLeafCount[treeID]; k++) {
        tTerm = (Terminal *) RF_tTermList[treeID][k];
        ombrTNodeCT[treeID][k] = tTerm -> tstMembrCount;
        for (j = 1; j <= tTerm -> tstMembrCount; j++) {
          ombrTNodeID[treeID][k][j] = tTerm -> tstMembrIndx[j];
        }
      }
    }
  }
}
