
// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***
#include           "shared/globalCore.h"
#include           "shared/externalCore.h"
#include           "global.h"
#include           "external.h"

// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***

      
    

#include "stackOutputQQ.h"
#include "terminal.h"
#include "sexpOutgoing.h"
#include "shared/error.h"
#include "shared/nativeUtil.h"
#include "shared/nrutil.h"
void stackTNQualitativeObjects(char     mode,
                               uint   **pSG_rmbrTNodeCT_,
                               uint   **pSG_imbrTNodeCT_,
                               uint   **pSG_ombrTNodeCT_,
                               uint   ***pSG_rmbrTNodeCT_ptr,
                               uint   ***pSG_imbrTNodeCT_ptr,
                               uint   ***pSG_ombrTNodeCT_ptr,
                               uint   **pSG_rmbrTNodeID_,
                               uint   **pSG_imbrTNodeID_,
                               uint   **pSG_ombrTNodeID_,
                               uint   **pOOB_SZ_,
                               uint   **pIBG_SZ_) {
  ulong localSize;
  uint treeID;
  if (RF_optHigh & OPT_TERM_OUTG) {
    localSize = RF_totalTermCount;
    *pSG_rmbrTNodeCT_ = (uint*) stackAndProtect(RF_auxDimConsts,
                                                mode,
                                                &RF_nativeIndex,
                                                NATIVE_TYPE_INTEGER,
                                                SG_RMBR_TN_CT,
                                                localSize,
                                                0,
                                                SG_sexpStringOutgoing,
                                                pSG_rmbrTNodeCT_ptr,
                                                2,
                                                RF_ntree,
                                                -2);
    *pSG_imbrTNodeCT_ = (uint*) stackAndProtect(RF_auxDimConsts,
                                                mode,
                                                &RF_nativeIndex,
                                                NATIVE_TYPE_INTEGER,
                                                SG_IMBR_TN_CT,
                                                localSize,
                                                0,
                                                SG_sexpStringOutgoing,
                                                pSG_imbrTNodeCT_ptr,
                                                2,
                                                RF_ntree,
                                                -2);
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
                                                RF_ntree,
                                                -2);
    localSize = 0;
    for (treeID = 1; treeID <= RF_ntree; treeID++) {
      localSize += SG_bootstrapSizeCase[treeID];
    }
    *pSG_rmbrTNodeID_ = (uint*) stackAndProtect(RF_auxDimConsts,
                                                mode,
                                                &RF_nativeIndex,
                                                NATIVE_TYPE_INTEGER,
                                                SG_RMBR_TN_ID,
                                                localSize,
                                                0,
                                                SG_sexpStringOutgoing,
                                                NULL,
                                                1,
                                                localSize);
    (*pSG_rmbrTNodeID_) --;
    localSize = 0;
    for (treeID = 1; treeID <= RF_ntree; treeID++) {
      localSize += SG_ibgSizeCase[treeID];
    }
    *pSG_imbrTNodeID_ = (uint*) stackAndProtect(RF_auxDimConsts,
                                                mode,
                                                &RF_nativeIndex,
                                                NATIVE_TYPE_INTEGER,
                                                SG_IMBR_TN_ID,
                                                localSize,
                                                0,
                                                SG_sexpStringOutgoing,
                                                NULL,
                                                1,
                                                localSize);
    (*pSG_imbrTNodeID_) --;
    localSize = 0;
    for (treeID = 1; treeID <= RF_ntree; treeID++) {
      localSize += SG_oobSizeCase[treeID];
    }
    if (localSize > 0) {
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
                                                  localSize);
      (*pSG_ombrTNodeID_) --;
    }
    else {
      localSize = 0;
      for (uint treeID = 1; treeID <= RF_ntree; treeID++) {
        localSize += RF_tLeafCount[treeID];
      }
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
                                                  localSize);
      (*pSG_ombrTNodeID_) --;
    }
    localSize = RF_ntree;
    *pOOB_SZ_ = (uint*) stackAndProtect(RF_auxDimConsts,
                                        mode,
                                        &RF_nativeIndex,
                                        NATIVE_TYPE_INTEGER,
                                        SG_OOB_SZ_CASE,
                                        localSize,
                                        0,
                                        SG_sexpStringOutgoing,
                                        NULL,
                                        1,
                                        localSize);
    (*pOOB_SZ_) --;
    *pIBG_SZ_ = (uint*) stackAndProtect(RF_auxDimConsts,
                                        mode,
                                        &RF_nativeIndex,
                                        NATIVE_TYPE_INTEGER,
                                        SG_IBG_SZ_CASE,
                                        localSize,
                                        0,
                                        SG_sexpStringOutgoing,
                                        NULL,
                                        1,
                                        localSize);
    (*pIBG_SZ_) --;
  }
}
void stackTNQualitativeObjectsForestPtr(char mode,
                                        uint *sexp_rmbrTNodeID_,
                                        uint *sexp_imbrTNodeID_,
                                        uint *sexp_ombrTNodeID_,
                                        uint ****pSG_rmbrTNodeID_ptr,
                                        uint ****pSG_imbrTNodeID_ptr,
                                        uint ****pSG_ombrTNodeID_ptr) {
  TerminalBase *tTermBase;
  Terminal     *tTerm;
  uint treeID;
  uint termCount;
  ulong offsetID_rmbr, offsetID_imbr, offsetID_ombr;
  ulong localSize;
  uint k;
  tTerm = NULL;  
  if (RF_optHigh & OPT_TERM_OUTG) {
    *pSG_rmbrTNodeID_ptr = (uint ***) new_vvector(1, RF_ntree, NRUTIL_UPTR2);
    offsetID_rmbr = 0; 
    localSize = 0;
    for (treeID = 1; treeID <= RF_ntree; treeID ++) {
      termCount = RF_tLeafCount[treeID];
      (*pSG_rmbrTNodeID_ptr)[treeID] = (uint **) new_vvector(1, termCount, NRUTIL_UPTR);
      for (k = 1; k <= termCount; k++) {
        tTermBase = RF_tTermList[treeID][k];
        tTerm     = (Terminal *) tTermBase; 
        (*pSG_rmbrTNodeID_ptr)[treeID][k] = sexp_rmbrTNodeID_ + offsetID_rmbr;
        offsetID_rmbr += tTerm -> repMembrCount;
      }
      localSize += SG_bootstrapSizeCase[treeID];
    }
    if ((offsetID_rmbr) != localSize) {
      RF_nativeError("\nRF-SRC:  *** ERROR *** ");
      RF_nativeError("\nRF-SRC:  Inconsistent total rmbr count during aux qualitative pointering:  ") ;
      RF_nativeError("\nRF-SRC:  Offset versus total was:  %10d, %10d", offsetID_rmbr, localSize);
      RF_nativeError("\nRF-SRC:  Please Contact Technical Support.");
      RF_nativeExit();
    }
    *pSG_imbrTNodeID_ptr = (uint ***) new_vvector(1, RF_ntree, NRUTIL_UPTR2);
    offsetID_imbr = 0; 
    localSize = 0;
    for (treeID = 1; treeID <= RF_ntree; treeID ++) {
      termCount = RF_tLeafCount[treeID];
      (*pSG_imbrTNodeID_ptr)[treeID] = (uint **) new_vvector(1, termCount, NRUTIL_UPTR);
      for (k = 1; k <= termCount; k++) {
        tTermBase = RF_tTermList[treeID][k];
        tTerm     = (Terminal *) tTermBase; 
        (*pSG_imbrTNodeID_ptr)[treeID][k] = sexp_imbrTNodeID_ + offsetID_imbr;
        offsetID_imbr += tTerm -> ibgMembrCount;
      }
      localSize += SG_ibgSizeCase[treeID];
    }
    if ((offsetID_imbr) != localSize) {
      RF_nativeError("\nRF-SRC:  *** ERROR *** ");
      RF_nativeError("\nRF-SRC:  Inconsistent total imbr count during aux qualitative pointering:  ") ;
      RF_nativeError("\nRF-SRC:  Offset versus total was:  %10d, %10d", offsetID_imbr, localSize);
      RF_nativeError("\nRF-SRC:  Please Contact Technical Support.");
      RF_nativeExit();
    }
    if (RF_opt & OPT_OENS) {
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
          offsetID_ombr += tTerm -> oobMembrCount;
        }
        localSize += SG_oobSizeCase[treeID];
      }
      if ((offsetID_ombr) != localSize) {
        RF_nativeError("\nRF-SRC:  *** ERROR *** ");
        RF_nativeError("\nRF-SRC:  Inconsistent total ombr count during aux qualitative pointering:  ");
        RF_nativeError("\nRF-SRC:  Offset versus total was:  %10d, %10d", offsetID_ombr, localSize);
        RF_nativeError("\nRF-SRC:  Please Contact Technical Support.");
        RF_nativeExit();
      }
    }
  }
}
void unstackTNQualitativeObjectsForestPtr(char mode,
                                          uint ***rmbrTNodeID_ptr,
                                          uint ***imbrTNodeID_ptr,
                                          uint ***ombrTNodeID_ptr) {
  uint treeID;
  uint termCount;
  if (RF_optHigh & OPT_TERM_OUTG) {
    for (treeID = 1; treeID <= RF_ntree; treeID ++) {
      termCount = RF_tLeafCount[treeID];
      free_new_vvector(rmbrTNodeID_ptr[treeID], 1, termCount, NRUTIL_UPTR);
      free_new_vvector(imbrTNodeID_ptr[treeID], 1, termCount, NRUTIL_UPTR);
    }
    free_new_vvector(rmbrTNodeID_ptr, 1, RF_ntree, NRUTIL_UPTR2);
    free_new_vvector(imbrTNodeID_ptr, 1, RF_ntree, NRUTIL_UPTR2);
    if (RF_opt & OPT_OENS) {
      for (treeID = 1; treeID <= RF_ntree; treeID ++) {
        termCount = RF_tLeafCount[treeID];
        free_new_vvector(ombrTNodeID_ptr[treeID], 1, termCount, NRUTIL_UPTR);
      }
      free_new_vvector(ombrTNodeID_ptr, 1, RF_ntree, NRUTIL_UPTR2);
    }
  }
}
void writeTNQualitativeObjectsOutput(char mode,
                                     uint           *tLeafCount,
                                     TerminalBase ***tTermList,
                                     uint           *oobSizeCase,
                                     uint           *ibgSizeCase,
                                     uint  **rmbrTNodeCT,
                                     uint  **imbrTNodeCT,
                                     uint  **ombrTNodeCT,
                                     uint ***rmbrTNodeID,
                                     uint ***imbrTNodeID,
                                     uint ***ombrTNodeID,
                                     uint   *OOB_SZ,
                                     uint   *IBG_SZ) {
  Terminal *tTerm;
  uint treeID;
  uint j, k;
  if (RF_optHigh & OPT_TERM_OUTG) {
    for (treeID = 1; treeID <= RF_ntree; treeID ++) {
      for (k = 1; k <= RF_tLeafCount[treeID]; k++) {
        tTerm = (Terminal *) RF_tTermList[treeID][k];
        rmbrTNodeCT[treeID][k] = tTerm -> repMembrCount;
        imbrTNodeCT[treeID][k] = tTerm -> ibgMembrCount;
        for (j = 1; j <= tTerm -> repMembrCount; j++) {
          rmbrTNodeID[treeID][k][j] = tTerm -> repMembrIndx[j];
        }
        for (j = 1; j <= tTerm -> ibgMembrCount; j++) {
          imbrTNodeID[treeID][k][j] = tTerm -> ibgMembrIndx[j];
        }
      }
    }
    if (RF_opt & OPT_OENS) {
      for (treeID = 1; treeID <= RF_ntree; treeID ++) {
        for (k = 1; k <= RF_tLeafCount[treeID]; k++) {
          tTerm = (Terminal *) RF_tTermList[treeID][k];
          ombrTNodeCT[treeID][k] = tTerm -> oobMembrCount;
          for (j = 1; j <= tTerm -> oobMembrCount; j++) {
            ombrTNodeID[treeID][k][j] = tTerm -> oobMembrIndx[j];
          }
        }
      }
    }
    for (treeID = 1; treeID <= RF_ntree; treeID ++) {
      OOB_SZ[treeID] = oobSizeCase[treeID];
      IBG_SZ[treeID] = ibgSizeCase[treeID];
    }
  }
}
void restoreTNQualitativeObjectsInput(char mode,
                                      uint treeID,
                                      uint  **rmbrTNodeCT,
                                      uint  **imbrTNodeCT,
                                      uint  **ombrTNodeCT,
                                      uint ***rmbrTNodeID,
                                      uint ***imbrTNodeID,
                                      uint ***ombrTNodeID) {
  Terminal *tTerm;
  uint k;
  if (RF_optHigh & OPT_TERM_INCG) {
    for (k = 1; k <= RF_tLeafCount[treeID]; k++) {
      tTerm = (Terminal *) RF_tTermList[treeID][k];
      tTerm -> repMembrCount = SG_rmbrTNodeCT_[SG_offsetCT[treeID]];
      tTerm -> ibgMembrCount = SG_imbrTNodeCT_[SG_offsetCT[treeID]];
      tTerm -> oobMembrCount = SG_ombrTNodeCT_[SG_offsetCT[treeID]];
      SG_offsetCT[treeID] ++;
      tTerm -> repMembrIndx = SG_rmbrTNodeID_ + SG_offsetID_rmbr[treeID];
      SG_offsetID_rmbr[treeID] += tTerm -> repMembrCount;
      tTerm -> ibgMembrIndx = SG_imbrTNodeID_ + SG_offsetID_imbr[treeID];
      SG_offsetID_imbr[treeID] += tTerm -> ibgMembrCount;
      tTerm -> oobMembrIndx = SG_ombrTNodeID_ + SG_offsetID_ombr[treeID];
      SG_offsetID_ombr[treeID] += tTerm -> oobMembrCount;
    }
  }
}
void stackTNQuantitativeObjects(char mode,
                                double **pSG_termNelsonAalen_,
                                double **pSG_termHazard_,
                                double ****pSG_termNelsonAalen_ptr,
                                double ****pSG_termHazard_ptr) {
  ulong localSize;
  uint tnDimOne;
  if (RF_optHigh & OPT_TERM_OUTG) {
    tnDimOne = RF_totalTermCount;
    localSize = (ulong) tnDimOne * RF_sortedTimeInterestSize;
    *pSG_termNelsonAalen_ = (double*) stackAndProtect(RF_auxDimConsts,
                                                      mode,
                                                      &RF_nativeIndex,
                                                      NATIVE_TYPE_NUMERIC,
                                                      SG_NLSN_TN,
                                                      localSize,
                                                      RF_nativeNaN,
                                                      SG_sexpStringOutgoing,
                                                      pSG_termNelsonAalen_ptr,
                                                      3,
                                                      RF_ntree,
                                                      -2,
                                                      RF_sortedTimeInterestSize);
    *pSG_termHazard_ = (double*) stackAndProtect(RF_auxDimConsts,
                                                 mode,
                                                 &RF_nativeIndex,
                                                 NATIVE_TYPE_NUMERIC,
                                                 SG_HAZR_TN,
                                                 localSize,
                                                 RF_nativeNaN,
                                                 SG_sexpStringOutgoing,
                                                 pSG_termHazard_ptr,
                                                 3,
                                                 RF_ntree,
                                                 -2,
                                                 RF_sortedTimeInterestSize);
  }
}
void writeTNQuantitativeObjectsOutput(char mode,
                                      double ***termNelsonAalenPtr,
                                      double ***termHazardPtr) {
  TerminalBase *tTermBase;
  TerminalSurvival *sTerm;
  uint treeID;
  uint j, k;
  if (RF_optHigh & OPT_TERM_OUTG) {
    for (treeID = 1; treeID <= RF_ntree; treeID ++) {
      for (k = 1; k <= RF_tLeafCount[treeID]; k++) {
        tTermBase = RF_tTermList[treeID][k];
        sTerm = tTermBase -> survivalBase;
        for (j = 1; j <= sTerm -> sTimeSize; j++) {
          termNelsonAalenPtr[treeID][k][j] = sTerm -> nelsonAalen[j];
        }
        for (j = 1; j <= sTerm -> sTimeSize; j++) {
          termHazardPtr[treeID][k][j] = sTerm -> hazard[j];
        }
      }
    }
  }
}
void stackTNNodeTimeObjects(char mode,
                            double **pSG_nodeU_,
                            double **pSG_nodeV_,
                            double **pSG_nodeCOE_,
                            double **pSG_nodeCumulativeCOE_,
                            double ****pSG_nodeU_ptr,
                            double ****pSG_nodeV_ptr,
                            double ****pSG_nodeCOE_ptr,
                            double ****pSG_nodeCumulativeCOE_ptr) {
  ulong localSize;
  if (RF_optHigh & OPT_TERM_OUTG) {
    localSize = (ulong) RF_totalTermCount * RF_sortedTimeInterestSize;
    *pSG_nodeU_ = (double*) stackAndProtect(RF_auxDimConsts,
                                            mode,
                                            &RF_nativeIndex,
                                            NATIVE_TYPE_NUMERIC,
                                            SG_NODE_U,
                                            localSize,
                                            0.0,
                                            SG_sexpStringOutgoing,
                                            pSG_nodeU_ptr,
                                            3,
                                            RF_ntree,
                                            -2,
                                            RF_sortedTimeInterestSize);
    *pSG_nodeV_ = (double*) stackAndProtect(RF_auxDimConsts,
                                            mode,
                                            &RF_nativeIndex,
                                            NATIVE_TYPE_NUMERIC,
                                            SG_NODE_V,
                                            localSize,
                                            0.0,
                                            SG_sexpStringOutgoing,
                                            pSG_nodeV_ptr,
                                            3,
                                            RF_ntree,
                                            -2,
                                            RF_sortedTimeInterestSize);
    *pSG_nodeCOE_ = (double*) stackAndProtect(RF_auxDimConsts,
                                              mode,
                                              &RF_nativeIndex,
                                              NATIVE_TYPE_NUMERIC,
                                              SG_NODE_COE,
                                              localSize,
                                              RF_nativeNaN,
                                              SG_sexpStringOutgoing,
                                              pSG_nodeCOE_ptr,
                                              3,
                                              RF_ntree,
                                              -2,
                                              RF_sortedTimeInterestSize);
    *pSG_nodeCumulativeCOE_ = (double*) stackAndProtect(RF_auxDimConsts,
                                                      mode,
                                                      &RF_nativeIndex,
                                                      NATIVE_TYPE_NUMERIC,
                                                      SG_NODE_CUMULATIVE_COE,
                                                      localSize,
                                                      0.0,
                                                      SG_sexpStringOutgoing,
                                                      pSG_nodeCumulativeCOE_ptr,
                                                      3,
                                                      RF_ntree,
                                                      -2,
                                                      RF_sortedTimeInterestSize);
  }
}
void writeTNNodeTimeObjects(char mode,
                            double ***nodeUPtr,
                            double ***nodeVPtr,
                            double ***nodeCOEPtr,
                            double ***nodeCumulativeCOEPtr) {
  Terminal *tTerm;
  TerminalBase *tTermBase;
  TerminalSurvival *sTerm;
  uint treeID;
  uint termID;
  uint timeIndex;
  if (RF_optHigh & OPT_TERM_OUTG) {
    for (treeID = 1; treeID <= RF_ntree; treeID++) {
      for (termID = 1; termID <= RF_tLeafCount[treeID]; termID++) {
        tTerm = (Terminal *) RF_tTermList[treeID][termID];
        tTermBase = RF_tTermList[treeID][termID];
        sTerm = tTermBase -> survivalBase;
        for (timeIndex = 1; timeIndex <= sTerm -> sTimeSize; timeIndex++) {
          nodeVPtr[treeID][termID][timeIndex] = tTerm -> nodeV[timeIndex]; 
          nodeUPtr[treeID][termID][timeIndex] = tTerm -> nodeU[timeIndex]; 
          nodeCOEPtr[treeID][termID][timeIndex] = tTerm -> coeHazard[timeIndex]; 
          nodeCumulativeCOEPtr[treeID][termID][timeIndex] = tTerm -> coeCHF[timeIndex];
        }
      }
    }
  }
}
