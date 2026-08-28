
// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***
#include           "shared/globalCore.h"
#include           "shared/externalCore.h"
#include           "global.h"
#include           "external.h"

// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***

      
    

#include "stackOutput.h"
#include "terminal.h"
#include "shared/nrutil.h"
#include "shared/error.h"
#include "shared/nativeUtil.h"
#include "sexpOutgoing.h"
#include "shared/stackAuxiliaryInfo.h"
void stackDefinedOutputObjects(char mode) {
  uint  sexpIdentity;
  uint localSize;
  uint  subjSize, obsSize;
  uint  membershipObsSize;
  double **ensembleDen;
  double   **ensembleKHZ;
  double  ***ensembleKHZptr;
  double  ***ensembleKHZnum;
  double   **ensembleCHF;
  double  ***ensembleCHFptr;
  double  ***ensembleCHFnum;
  double   **ensembleHRW;
  double  ***ensembleHRWptr;
  double  ***ensembleHRWnum;
  double    **coeHazardTree;
  double  ****coeHazardTreePtr;
  double    **coeCHFTree;
  double  ****coeCHFTreePtr;
  double   **riskPtr;
  double   **riskRawPtr;
  double   **integralHazardPtr;
  char oobFlag, fullFlag;
  uint i, j, k;
  sexpIdentity = 0;
  if ((mode == RF_GROW) || (mode == RF_REST)) {
    if (RF_opt & OPT_LEAF) {
      RF_stackCount += 1;
    }
    if (RF_optHigh & OPT_TERM_OUTG) {
      RF_stackCount += 4;
      RF_stackCount += 2;
      RF_stackCount += 2;
      if ( (SG_optLocal & (SG_OPT_SWTCH_FOUR | SG_OPT_SWTCH_FIVE | SG_OPT_SWTCH_SIX)) != 0) {
        RF_stackCount += 4;
        if ((RF_opt & OPT_IENS) || (RF_opt & OPT_FENS)) {
          RF_stackCount += 2;
        }
        if (RF_opt & OPT_OENS) {
          RF_stackCount += 2;
        }
      }
      RF_stackCount += 2;          
      RF_stackCount += 2;
    }
    if ((RF_opt & OPT_IENS) || (RF_opt & OPT_FENS)) {
      RF_stackCount += 3;
      RF_stackCount += 1;
      RF_stackCount += 1;
      RF_stackCount += 1;
      RF_stackCount += 2;
      RF_stackCount += 1;
    }
    if (RF_opt & OPT_OENS) {
      RF_stackCount += 3;
      RF_stackCount += 1;
      RF_stackCount += 1;
      RF_stackCount += 1;
    }
    if (RF_opt & OPT_TREE) {
      if (RF_opt & OPT_SEED) {
        RF_stackCount += 1;
      }
      RF_stackCount += 1;
      RF_stackCount += 13;
      RF_stackCount +=2;
    }
    if (RF_opt & OPT_EMPR_RISK) {
      RF_stackCount += 2;
      RF_stackCount += 2;
    }
  }
  else {
    if (RF_opt & OPT_LEAF) {
      RF_stackCount += 1;  
    }
    if (RF_optHigh & OPT_TERM_OUTG) {
      RF_stackCount += 2; 
      if ( (SG_optLocal & (SG_OPT_SWTCH_FOUR | SG_OPT_SWTCH_FIVE | SG_OPT_SWTCH_SIX)) != 0) {
        RF_stackCount += 4;
        if (RF_opt & OPT_FENS) {
          RF_stackCount += 2;
        }
      }
      if (RF_frSize > 0) {
        RF_stackCount += 2;
      }
    }
    if (RF_opt & OPT_FENS) {
      RF_stackCount += 3; 
      RF_stackCount += 1;  
      RF_stackCount += 1; 
      RF_stackCount += 1;
      RF_stackCount += 2;
      RF_stackCount += 1; 
    }
  }
  if (SG_optLocal & SG_OPT_SWTCH_FIVE) {
    RF_stackCount += 1;  
    if ((mode != RF_PRED) && (RF_opt & OPT_OENS)) {
      RF_stackCount += 1;  
    }
  }
  if (RF_optHigh & OPT_MEMB_USER) {
    RF_stackCount += 2;  
  }
  RF_stackCount +=1;  
  initProtect(RF_stackCount);
  stackAuxiliaryInfoList(&RF_snpAuxiliaryInfoList, RF_stackCount);
  oobFlag = fullFlag = FALSE;
  if ((RF_opt & OPT_OENS) || (RF_opt & OPT_IENS) || (RF_opt & OPT_FENS)) {
    if (mode != RF_PRED) {
      subjSize = RF_subjCount;
      obsSize  = RF_observationSize;
    }
    else {
      subjSize = SG_fsubjCount;
      obsSize  = RF_fobservationSize;      
    }
    switch (mode) {
    case RF_PRED:
      if (RF_opt & OPT_FENS) {
        fullFlag = TRUE;
      }
      break;
    default:
      if (RF_opt & OPT_OENS) {
        oobFlag = TRUE;
      }
      if (RF_opt & OPT_IENS) {
        fullFlag = TRUE;
      }
      break;
    }
    sexpIdentity = SG_ENSB_ID;
    localSize = subjSize;
    SG_ensembleID_ = (uint*) stackAndProtect(RF_auxDimConsts,
                                             mode,
                                             &RF_nativeIndex,
                                             NATIVE_TYPE_INTEGER,
                                             sexpIdentity,
                                             localSize,
                                             0,
                                             SG_sexpStringOutgoing,
                                             NULL,
                                             1,
                                             localSize);
    SG_ensembleID_ --;
    sexpIdentity = SG_WCASE_LEFT_ABS;
    localSize = obsSize;
    SG_absWCaseTimeLeft_ = (double*) stackAndProtect(RF_auxDimConsts,
                                                     mode,
                                                     &RF_nativeIndex,
                                                     NATIVE_TYPE_NUMERIC,
                                                     sexpIdentity,
                                                     localSize,
                                                     RF_nativeNaN,
                                                     SG_sexpStringOutgoing,
                                                     NULL,
                                                     1,
                                                     localSize);
    SG_absWCaseTimeLeft_ --;
    sexpIdentity = SG_WCASE_RIGHT_ABS;
    localSize = obsSize;
    SG_absWCaseTimeRight_ = (double*) stackAndProtect(RF_auxDimConsts,
                                                      mode,
                                                      &RF_nativeIndex,
                                                      NATIVE_TYPE_NUMERIC,
                                                      sexpIdentity,
                                                      localSize,
                                                      RF_nativeNaN,
                                                      SG_sexpStringOutgoing,
                                                      NULL,
                                                      1,
                                                      localSize);
    SG_absWCaseTimeRight_ --;
    while ((oobFlag == TRUE) || (fullFlag == TRUE)) {
      ensembleDen    = NULL;
      ensembleKHZ    = NULL;
      ensembleKHZptr = NULL;
      ensembleKHZnum = NULL;
      ensembleCHF    = NULL;
      ensembleCHFptr = NULL;
      ensembleCHFnum = NULL;
      ensembleHRW    = NULL;
      ensembleHRWptr = NULL;
      ensembleHRWnum = NULL;
      coeHazardTree    = NULL;
      coeHazardTreePtr = NULL;
      coeCHFTree       = NULL;
      coeCHFTreePtr    = NULL;
      if (oobFlag == TRUE) {
        ensembleDen     = &RF_oobEnsembleDen;
        ensembleKHZ    = &SG_oobEnsembleKHZ_;
        ensembleKHZptr = &SG_oobEnsembleKHZptr;
        ensembleKHZnum = &SG_oobEnsembleKHZnum;
        ensembleCHF    = &SG_oobEnsembleCHF_;
        ensembleCHFptr = &SG_oobEnsembleCHFptr;
        ensembleCHFnum = &SG_oobEnsembleCHFnum;
        ensembleHRW    = &SG_oobEnsembleHRW_;
        ensembleHRWptr = &SG_oobEnsembleHRWptr;
        ensembleHRWnum = &SG_oobEnsembleHRWnum;
        coeHazardTree    = &SG_coeHazardTreeOOB_;
        coeHazardTreePtr = &SG_coeHazardTreeOOB_ptr;
        coeCHFTree       = &SG_coeCHFTreeOOB_;
        coeCHFTreePtr    = &SG_coeCHFTreeOOB_ptr;
        riskPtr         = &SG_oobRisk_;
        riskRawPtr      = &SG_oobRiskRaw_;                
        integralHazardPtr = &SG_oobWCase_;
      }
      else {
        ensembleDen    = &RF_fullEnsembleDen;
        ensembleKHZ    = &SG_fullEnsembleKHZ_;
        ensembleKHZptr = &SG_fullEnsembleKHZptr;
        ensembleKHZnum = &SG_fullEnsembleKHZnum;
        ensembleCHF    = &SG_fullEnsembleCHF_;
        ensembleCHFptr = &SG_fullEnsembleCHFptr;
        ensembleCHFnum = &SG_fullEnsembleCHFnum;
        ensembleHRW    = &SG_fullEnsembleHRW_;
        ensembleHRWptr = &SG_fullEnsembleHRWptr;
        ensembleHRWnum = &SG_fullEnsembleHRWnum;
        coeHazardTree    = &SG_coeHazardTreeIBG_;
        coeHazardTreePtr = &SG_coeHazardTreeIBG_ptr;
        coeCHFTree       = &SG_coeCHFTreeIBG_;
        coeCHFTreePtr    = &SG_coeCHFTreeIBG_ptr;
        riskPtr         = &SG_fullRisk_;
        riskRawPtr      = &SG_fullRiskRaw_;
        integralHazardPtr = &SG_fullWCase_;
      }
      *ensembleDen = dvector(1, subjSize);
      for (i = 1; i <= subjSize; i++) {
        (*ensembleDen)[i] = 0;
      }
      (oobFlag == TRUE) ? (sexpIdentity = SG_HAZR_OOB) : ((fullFlag == TRUE) ? sexpIdentity = SG_HAZR_IBG : 0);
      localSize = RF_sortedTimeInterestSize * subjSize;
      *ensembleKHZ = (double*) stackAndProtect(RF_auxDimConsts,
                                               mode,
                                               &RF_nativeIndex,
                                               NATIVE_TYPE_NUMERIC,
                                               sexpIdentity,
                                               localSize,
                                               0,
                                               SG_sexpStringOutgoing,
                                               ensembleKHZptr,
                                               2,
                                               RF_sortedTimeInterestSize,
                                               subjSize);
      (*ensembleKHZnum) = (double **) new_vvector(1, RF_sortedTimeInterestSize, NRUTIL_DPTR);
      for (j = 1; j <= RF_sortedTimeInterestSize; j++) {
        (*ensembleKHZnum)[j] = dvector(1, subjSize);
        for (k = 1; k <= subjSize; k ++) { 
          (*ensembleKHZnum)[j][k] = 0.0;
        }
      }
      (oobFlag == TRUE) ? (sexpIdentity = SG_NLSN_OOB) : ((fullFlag == TRUE) ? sexpIdentity = SG_NLSN_IBG: 0);
      localSize = RF_sortedTimeInterestSize * subjSize;
      *ensembleCHF = (double*) stackAndProtect(RF_auxDimConsts,
                                               mode,
                                               &RF_nativeIndex,
                                               NATIVE_TYPE_NUMERIC,
                                               sexpIdentity,
                                               localSize,
                                               0,
                                               SG_sexpStringOutgoing,
                                               ensembleCHFptr,
                                               2,
                                               RF_sortedTimeInterestSize,
                                               subjSize);
      (*ensembleCHFnum) = (double **) new_vvector(1, RF_sortedTimeInterestSize, NRUTIL_DPTR);
      for (j = 1; j <= RF_sortedTimeInterestSize; j++) {
        (*ensembleCHFnum)[j] = dvector(1, subjSize);
        for (k = 1; k <= subjSize; k ++) { 
          (*ensembleCHFnum)[j][k] = 0.0;
        }
      }
      (oobFlag == TRUE) ? (sexpIdentity = SG_HAZR_RAW_OOB) : ((fullFlag == TRUE) ? sexpIdentity = SG_HAZR_RAW_IBG: 0);
      localSize = RF_sortedTimeInterestSize * subjSize;
      *ensembleHRW = (double*) stackAndProtect(RF_auxDimConsts,
                                               mode,
                                               &RF_nativeIndex,
                                               NATIVE_TYPE_NUMERIC,
                                               sexpIdentity,
                                               localSize,
                                               0,
                                               SG_sexpStringOutgoing,
                                               ensembleHRWptr,
                                               2,
                                               RF_sortedTimeInterestSize,
                                               subjSize);
      (*ensembleHRWnum) = (double **) new_vvector(1, RF_sortedTimeInterestSize, NRUTIL_DPTR);
      for (j = 1; j <= RF_sortedTimeInterestSize; j++) {
        (*ensembleHRWnum)[j] = dvector(1, subjSize);
        for (k = 1; k <= subjSize; k ++) { 
          (*ensembleHRWnum)[j][k] = 0.0;
        }
      }
      (oobFlag == TRUE) ? (sexpIdentity = SG_RISK_OOB) : ((fullFlag == TRUE) ? sexpIdentity = SG_RISK_IBG: 0);
      localSize = subjSize;
      (*riskPtr) = (double*) stackAndProtect(RF_auxDimConsts,
                                             mode,
                                             &RF_nativeIndex,
                                             NATIVE_TYPE_NUMERIC,
                                             sexpIdentity,
                                             localSize,
                                             RF_nativeNaN,
                                             SG_sexpStringOutgoing,
                                             NULL,
                                             1,
                                             localSize);
      (*riskPtr) --;
      (oobFlag == TRUE) ? (sexpIdentity = SG_RISK_RAW_OOB) : ((fullFlag == TRUE) ? sexpIdentity = SG_RISK_RAW_IBG: 0);
      localSize = subjSize;
      (*riskRawPtr) = (double*) stackAndProtect(RF_auxDimConsts,
                                                mode,
                                                &RF_nativeIndex,
                                                NATIVE_TYPE_NUMERIC,
                                                sexpIdentity,
                                                localSize,
                                                RF_nativeNaN,
                                                SG_sexpStringOutgoing,
                                                NULL,
                                                1,
                                                localSize);
      (*riskRawPtr) --;
      (oobFlag == TRUE) ? (sexpIdentity = SG_WCASE_OOB) : ((fullFlag == TRUE) ? sexpIdentity = SG_WCASE_IBG: 0);
      localSize = obsSize;
      (*integralHazardPtr) = (double*) stackAndProtect(RF_auxDimConsts,
                                                       mode,
                                                       &RF_nativeIndex,
                                                       NATIVE_TYPE_NUMERIC,
                                                       sexpIdentity,
                                                       localSize,
                                                       RF_nativeNaN,
                                                       SG_sexpStringOutgoing,
                                                       NULL,
                                                       1,
                                                       localSize);
      (*integralHazardPtr) --;
      if ( (SG_optLocal & (SG_OPT_SWTCH_FOUR | SG_OPT_SWTCH_FIVE | SG_OPT_SWTCH_SIX)) != 0) {
        (oobFlag == TRUE) ? (sexpIdentity = SG_COE_HAZR_TREE_OOB) : ((fullFlag == TRUE) ? sexpIdentity = SG_COE_HAZR_TREE_IBG : 0);
        localSize = RF_ntree * RF_sortedTimeInterestSize * subjSize;
        *coeHazardTree = (double*) stackAndProtect(RF_auxDimConsts,
                                                   mode,
                                                   &RF_nativeIndex,
                                                   NATIVE_TYPE_NUMERIC,
                                                   sexpIdentity,
                                                   localSize,
                                                   RF_nativeNaN,
                                                   SG_sexpStringOutgoing,
                                                   coeHazardTreePtr,
                                                   3,
                                                   RF_ntree,
                                                   RF_sortedTimeInterestSize,
                                                   subjSize);
        (oobFlag == TRUE) ? (sexpIdentity = SG_COE_CHF_TREE_OOB) : ((fullFlag == TRUE) ? sexpIdentity = SG_COE_CHF_TREE_IBG : 0);
        localSize = RF_ntree * RF_sortedTimeInterestSize * subjSize;
        *coeCHFTree = (double*) stackAndProtect(RF_auxDimConsts,
                                                mode,
                                                &RF_nativeIndex,
                                                NATIVE_TYPE_NUMERIC,
                                                sexpIdentity,
                                                localSize,
                                                RF_nativeNaN,
                                                SG_sexpStringOutgoing,
                                                coeCHFTreePtr,
                                                3,
                                                RF_ntree,
                                                RF_sortedTimeInterestSize,
                                                subjSize);
      }
      if (oobFlag == TRUE) {
        oobFlag = FALSE;
      }
      else {
        fullFlag = FALSE;
      }
    }  
  }
  if (RF_optHigh & OPT_TERM_OUTG) {
    if ((mode == RF_GROW) || (mode == RF_REST)) {
      localSize = RF_observationSize;
      SG_termHazardTimeCount_ = (uint*) stackAndProtect(RF_auxDimConsts,
                                                        mode,
                                                        &RF_nativeIndex,
                                                        NATIVE_TYPE_INTEGER,
                                                        SG_T_HAZ_TM_CNT,
                                                        localSize,
                                                        0,
                                                        SG_sexpStringOutgoing,
                                                        NULL,
                                                        1,
                                                        localSize);
      SG_termHazardTimeCount_ --;
      for (i = 1; i <= RF_observationSize; i++) {
        SG_termHazardTimeCount_[i] = SG_timeInterestIntervalCount[i];
      }
      localSize = 0;
      for (i = 1; i <= RF_observationSize; i++) {
        localSize += SG_timeInterestIntervalCount[i];
      }
      SG_termHazardTimeIndex_ = (uint*) stackAndProtect(RF_auxDimConsts,
                                                        mode,
                                                        &RF_nativeIndex,
                                                        NATIVE_TYPE_INTEGER,
                                                        SG_T_HAZ_TM_IDX,
                                                        localSize,
                                                        0,
                                                        SG_sexpStringOutgoing,
                                                        NULL,
                                                        1,
                                                        localSize);
      SG_termHazardTimeIndex_ --;
      k = 0;
      for (i = 1; i <= RF_observationSize; i++) {
        for (j = 1; j <= SG_timeInterestIntervalCount[i]; j++) {
          SG_termHazardTimeIndex_[++k] = SG_timeInterestIntervalIndex[i][j];
        }
      }
    }
    else {
      if (RF_frSize > 0) {
        localSize = RF_fobservationSize;
        SG_termHazardTimeCount_ = (uint*) stackAndProtect(RF_auxDimConsts,
                                                          mode,
                                                          &RF_nativeIndex,
                                                          NATIVE_TYPE_INTEGER,
                                                          SG_T_HAZ_TM_CNT,
                                                          localSize,
                                                          0,
                                                          SG_sexpStringOutgoing,
                                                          NULL,
                                                          1,
                                                          localSize);
        SG_termHazardTimeCount_ --;
        for (i = 1; i <= RF_fobservationSize; i++) {
          SG_termHazardTimeCount_[i] = SG_ftimeInterestIntervalCount[i];
        }
        localSize = 0;
        for (i = 1; i <= RF_fobservationSize; i++) {
          localSize += SG_ftimeInterestIntervalCount[i];
        }
        SG_termHazardTimeIndex_ = (uint*) stackAndProtect(RF_auxDimConsts,
                                                          mode,
                                                          &RF_nativeIndex,
                                                          NATIVE_TYPE_INTEGER,
                                                          SG_T_HAZ_TM_IDX,
                                                          localSize,
                                                          0,
                                                          SG_sexpStringOutgoing,
                                                          NULL,
                                                          1,
                                                          localSize);
        SG_termHazardTimeIndex_ --;
        k = 0;
        for (i = 1; i <= RF_fobservationSize; i++) {
          for (j = 1; j <= SG_ftimeInterestIntervalCount[i]; j++) {
            SG_termHazardTimeIndex_[++k] = SG_ftimeInterestIntervalIndex[i][j];
          }
        }
      }
    }
  }
  SG_coeTrimIndex_ = NULL;
  SG_coeTrimRiskOOB_ = NULL;
  if (SG_optLocal & SG_OPT_SWTCH_FIVE) {
    SG_coeTrimIndex_ = (uint *) stackAndProtect(
      RF_auxDimConsts,
      mode,
      &RF_nativeIndex,
      NATIVE_TYPE_INTEGER,
      SG_COE_TRIM_INDEX,
      1,
      0,
      SG_sexpStringOutgoing,
      NULL,
      1,
      1);
    SG_coeTrimIndex_ --;
    SG_coeTrimIndex_[1] = SG_coeTrimIndex;
    if ((mode != RF_PRED) && (RF_opt & OPT_OENS)) {
      SG_coeTrimRiskOOB_ = (double *) stackAndProtect(
        RF_auxDimConsts,
        mode,
        &RF_nativeIndex,
        NATIVE_TYPE_NUMERIC,
        SG_COE_TRIM_RISK_OOB,
        SG_coeTrimSize,
        RF_nativeNaN,
        SG_sexpStringOutgoing,
        NULL,
        1,
        SG_coeTrimSize);
      SG_coeTrimRiskOOB_ --;
    }
  }
  if (RF_opt & OPT_LEAF) {
    localSize = RF_ntree;
    RF_tLeafCount_ = (uint*) stackAndProtect(RF_auxDimConsts,
                                             mode,
                                             &RF_nativeIndex,
                                             NATIVE_TYPE_INTEGER,
                                             SG_LEAF_CT,
                                             localSize,
                                             0,
                                             SG_sexpStringOutgoing,
                                             NULL,
                                             1,
                                             localSize);
    RF_tLeafCount_ --;
    if (mode == RF_GROW) {
      RF_tLeafCount = RF_tLeafCount_;
    }
    else {
      for (i = 1; i <= RF_ntree; i++) {
        RF_tLeafCount_[i] = RF_tLeafCount[i];
      }
    }
  }
  if (RF_opt & OPT_SEED) {
    localSize = RF_ntree;
    RF_seed_ = (int*) stackAndProtect(RF_auxDimConsts,
                                      mode,
                                      &RF_nativeIndex,
                                      NATIVE_TYPE_INTEGER,
                                      SG_SEED_ID,
                                      localSize,
                                      0,
                                      SG_sexpStringOutgoing,
                                      NULL,
                                      1,
                                      localSize);
    RF_seed_ --;
    for (i = 1; i <= RF_ntree; i++) {
      RF_seed_[i] = -1;
    }
  }
  if (RF_opt & OPT_TREE) {
    RF_optLoGrow_ = (uint*) stackAndProtect(RF_auxDimConsts,
                                            mode,
                                            &RF_nativeIndex,
                                            NATIVE_TYPE_INTEGER,
                                            SG_OPT_LO_GROW,
                                            1,
                                            0,
                                            SG_sexpStringOutgoing,
                                            NULL,
                                            1,
                                            1);
    RF_optLoGrow_ --;
    RF_optLoGrow_[1] = RF_optLoGrow = RF_opt;
  }
  if (RF_opt & OPT_EMPR_RISK) {
    localSize = RF_ntree * SG_lotSize;
    SG_ibg_tree_risk_  = (double*) stackAndProtect(RF_auxDimConsts, mode, &RF_nativeIndex, NATIVE_TYPE_NUMERIC, SG_TREE_RISK_IBG, localSize, RF_nativeNaN, SG_sexpStringOutgoing, &SG_ibg_tree_risk_ptr, 2, RF_ntree, SG_lotSize);
    SG_oob_tree_risk_  = (double*) stackAndProtect(RF_auxDimConsts, mode, &RF_nativeIndex, NATIVE_TYPE_NUMERIC, SG_TREE_RISK_OOB, localSize, RF_nativeNaN, SG_sexpStringOutgoing, &SG_oob_tree_risk_ptr, 2, RF_ntree, SG_lotSize);
    SG_ibg_tree_risk_raw_  = (double*) stackAndProtect(RF_auxDimConsts, mode, &RF_nativeIndex, NATIVE_TYPE_NUMERIC, SG_TREE_RISK_RAW_IBG, localSize, RF_nativeNaN, SG_sexpStringOutgoing, &SG_ibg_tree_risk_raw_ptr, 2, RF_ntree, SG_lotSize);
    SG_oob_tree_risk_raw_  = (double*) stackAndProtect(RF_auxDimConsts, mode, &RF_nativeIndex, NATIVE_TYPE_NUMERIC, SG_TREE_RISK_RAW_OOB, localSize, RF_nativeNaN, SG_sexpStringOutgoing, &SG_oob_tree_risk_raw_ptr, 2, RF_ntree, SG_lotSize);
  }
  if (RF_optHigh & OPT_MEMB_USER) {
    membershipObsSize = (mode == RF_PRED) ? RF_fobservationSize : RF_observationSize;
    localSize = RF_ntree * membershipObsSize;
    SG_MEMB_ID_ = (uint*) stackAndProtect(RF_auxDimConsts, mode, &RF_nativeIndex, NATIVE_TYPE_INTEGER, SG_MEMB_ID, localSize, 0, SG_sexpStringOutgoing, &SG_MEMB_ID_ptr, 2, RF_ntree, membershipObsSize);
    localSize = RF_ntree * RF_subjCount;
    SG_BOOT_CT_ = (uint*) stackAndProtect(RF_auxDimConsts, mode, &RF_nativeIndex, NATIVE_TYPE_INTEGER, SG_BOOT_CT, localSize, 0, SG_sexpStringOutgoing, &SG_BOOT_CT_ptr, 2, RF_ntree, RF_subjCount);
  }
  SG_bootstrapSizeCase = uivector(1, RF_ntree);
  SG_bootMembershipFlagCase = (char **) new_vvector(1, RF_ntree, NRUTIL_CPTR);
  SG_oobMembershipFlagCase = (char **) new_vvector(1, RF_ntree, NRUTIL_CPTR);
  SG_oobSizeCase = uivector(1, RF_ntree);
  SG_ibgSizeCase = uivector(1, RF_ntree);
  SG_oobMembershipIndexCase = (uint **) new_vvector(1, RF_ntree, NRUTIL_UPTR);
  SG_ibgMembershipIndexCase = (uint **) new_vvector(1, RF_ntree, NRUTIL_UPTR);
  SG_cpuTime_ = (double*) stackAndProtect(RF_auxDimConsts,
                                          mode,
                                          &RF_nativeIndex,
                                          NATIVE_TYPE_NUMERIC,
                                          SG_CPU_TIME,
                                          1,
                                          0,
                                          SG_sexpStringOutgoing,
                                          NULL,
                                          1,
                                          1);
  SG_cpuTime_ --;
}
void unstackDefinedOutputObjects(char mode) {
  uint obsSize;
  char oobFlag, fullFlag;
  double **ensembleDen;
  double ***ensembleKHZnum;
  double ***ensembleCHFnum;
  double ***ensembleHRWnum;
  uint j;
  oobFlag = fullFlag = FALSE;
  if ((RF_opt & OPT_OENS) || (RF_opt & OPT_IENS) || (RF_opt & OPT_FENS)) {
    if (mode != RF_PRED) {
      obsSize = RF_subjCount;
    }
    else {
      obsSize = SG_fsubjCount;
    }
    switch (mode) {
    case RF_PRED:
      if (RF_opt & OPT_FENS) {
        fullFlag = TRUE;
      }
      break;
    default:
      if (RF_opt & OPT_OENS) {
        oobFlag = TRUE;
      }
      if (RF_opt & OPT_IENS) {
        fullFlag = TRUE;
      }
      break;
    }
    while ((oobFlag == TRUE) || (fullFlag == TRUE)) {
      if (oobFlag == TRUE) {
        ensembleDen    = &RF_oobEnsembleDen;
        ensembleKHZnum = &SG_oobEnsembleKHZnum;
        ensembleCHFnum = &SG_oobEnsembleCHFnum;
        ensembleHRWnum = &SG_oobEnsembleHRWnum;
      }
      else {
        ensembleDen    = &RF_fullEnsembleDen;
        ensembleKHZnum = &SG_fullEnsembleKHZnum;
        ensembleCHFnum = &SG_fullEnsembleCHFnum;
        ensembleHRWnum = &SG_fullEnsembleHRWnum;
      }
      free_dvector(*ensembleDen, 1, obsSize);
      for (j = 1; j <= RF_sortedTimeInterestSize; j++) {
        free_dvector((*ensembleKHZnum)[j], 1, obsSize);
      }
      free_new_vvector((*ensembleKHZnum), 1, RF_sortedTimeInterestSize, NRUTIL_DPTR);        
      for (j = 1; j <= RF_sortedTimeInterestSize; j++) {
        free_dvector((*ensembleCHFnum)[j], 1, obsSize);
      }
      free_new_vvector((*ensembleCHFnum), 1, RF_sortedTimeInterestSize, NRUTIL_DPTR);        
      for (j = 1; j <= RF_sortedTimeInterestSize; j++) {
        free_dvector((*ensembleHRWnum)[j], 1, obsSize);
      }
      free_new_vvector((*ensembleHRWnum), 1, RF_sortedTimeInterestSize, NRUTIL_DPTR);        
      if (oobFlag == TRUE) {
        oobFlag = FALSE;
      }
      else {
        fullFlag = FALSE;
      }
    }  
  }
  free_uivector(SG_bootstrapSizeCase, 1, RF_ntree);
  free_new_vvector(SG_bootMembershipFlagCase, 1, RF_ntree, NRUTIL_CPTR);
  free_new_vvector(SG_oobMembershipFlagCase, 1, RF_ntree, NRUTIL_CPTR);
  free_uivector(SG_oobSizeCase, 1, RF_ntree);
  free_uivector(SG_ibgSizeCase, 1, RF_ntree);
  free_new_vvector(SG_oobMembershipIndexCase, 1, RF_ntree, NRUTIL_UPTR);
  free_new_vvector(SG_ibgMembershipIndexCase, 1, RF_ntree, NRUTIL_UPTR);
}
void stackForestObjectsPtrOnly(char mode) {
  uint i;
  SG_treeID_ptr     = (uint **) new_vvector(1, RF_ntree, NRUTIL_UPTR);
  SG_nodeID_ptr     = (uint **) new_vvector(1, RF_ntree, NRUTIL_UPTR);
  SG_nodeSZ_ptr     = (uint **) new_vvector(1, RF_ntree, NRUTIL_UPTR);
  SG_brnodeID_ptr   = (uint **) new_vvector(1, RF_ntree, NRUTIL_UPTR);
  SG_prnodeID_ptr   = (uint **) new_vvector(1, RF_ntree, NRUTIL_UPTR);
  SG_parmID_ptr     = (uint **) new_vvector(1, RF_ntree, NRUTIL_UPTR);
  SG_contPT_ptr     = (double **) new_vvector(1, RF_ntree, NRUTIL_DPTR);
  SG_mwcpSZ_ptr     = (uint **) new_vvector(1, RF_ntree, NRUTIL_UPTR);
  SG_mwcpCT_ptr     =              uivector(1, RF_ntree);
  SG_mwcpPT_ptr     = (uint **) new_vvector(1, RF_ntree, NRUTIL_UPTR);
  SG_fsrecID_ptr    = (uint **) new_vvector(1, RF_ntree, NRUTIL_UPTR);
  SG_nodeStat_ptr   = (double **) new_vvector(1, RF_ntree, NRUTIL_DPTR);
  SG_bsf_ptr   = (uint **) new_vvector(1, RF_ntree, NRUTIL_UPTR);
  for (i = 1; i <= RF_ntree; i++) {
    SG_mwcpCT_ptr[i] = 0;
  }
  SG_node_risk_ptr      = (double **) new_vvector(1, RF_ntree, NRUTIL_DPTR);
  SG_node_risk_raw_ptr   = (double **) new_vvector(1, RF_ntree, NRUTIL_DPTR);
}
void unstackForestObjectsPtrOnly(char mode) {
  uint treeID;
  for (treeID = 1; treeID <= RF_ntree; treeID++) {
    unstackTreeObjectsPtrOnly(treeID);
  }
  free_new_vvector(SG_treeID_ptr,   1, RF_ntree, NRUTIL_UPTR);
  free_new_vvector(SG_nodeID_ptr,   1, RF_ntree, NRUTIL_UPTR);
  free_new_vvector(SG_nodeSZ_ptr,   1, RF_ntree, NRUTIL_UPTR);
  free_new_vvector(SG_brnodeID_ptr, 1, RF_ntree, NRUTIL_UPTR);
  free_new_vvector(SG_prnodeID_ptr, 1, RF_ntree, NRUTIL_UPTR);
  free_new_vvector(SG_parmID_ptr,   1, RF_ntree, NRUTIL_UPTR);
  free_new_vvector(SG_contPT_ptr,   1, RF_ntree, NRUTIL_DPTR);
  free_new_vvector(SG_mwcpSZ_ptr,   1, RF_ntree, NRUTIL_UPTR);
  free_uivector   (SG_mwcpCT_ptr,   1, RF_ntree);
  free_new_vvector(SG_mwcpPT_ptr,   1, RF_ntree, NRUTIL_UPTR);
  free_new_vvector(SG_fsrecID_ptr,  1, RF_ntree, NRUTIL_UPTR);
  free_new_vvector(SG_nodeStat_ptr,   1, RF_ntree, NRUTIL_DPTR);
  free_new_vvector(SG_bsf_ptr,        1, RF_ntree, NRUTIL_UPTR);
  free_new_vvector(SG_node_risk_ptr,     1, RF_ntree, NRUTIL_DPTR);
  free_new_vvector(SG_node_risk_raw_ptr, 1, RF_ntree, NRUTIL_DPTR);
}
void stackTreeObjectsPtrOnly(char mode, uint treeID) {
  uint nodeCount, termCount;
  uint mwcpSize, mwcpCount;
  nodeCount = RF_nodeCount[treeID];
  termCount = RF_tLeafCount[treeID];
  if (RF_xFactorCount > 0) {
    mwcpSize = (RF_xMaxFactorLevel >> (3 + ulog2(sizeof(uint)))) + ((RF_xMaxFactorLevel & (MAX_EXACT_LEVEL - 1)) ? 1 : 0);
  }
  else {
    mwcpSize = 0;
  }
  mwcpCount = mwcpSize * nodeCount;
  SG_treeID_ptr[treeID]    = uivector(1, nodeCount);
  SG_nodeID_ptr[treeID]    = uivector(1, nodeCount);
  SG_nodeSZ_ptr[treeID]    = uivector(1, nodeCount);
  SG_brnodeID_ptr[treeID]  = uivector(1, nodeCount);
  SG_prnodeID_ptr[treeID]  = uivector(1, nodeCount);
  SG_parmID_ptr[treeID]    = uivector(1, nodeCount);
  SG_contPT_ptr[treeID]    =  dvector(1, nodeCount);
  SG_mwcpSZ_ptr[treeID]    = uivector(1, nodeCount);
  if (mwcpCount > 0) {
    SG_mwcpPT_ptr[treeID]  = uivector(1, mwcpCount);
  }
  SG_fsrecID_ptr[treeID]   = uivector(1, nodeCount);
  SG_nodeStat_ptr[treeID]   = dvector(1, nodeCount);
  SG_bsf_ptr[treeID]        = uivector(1, nodeCount);
  RF_tTermList[treeID] = (TerminalBase **) new_vvector(1, termCount, NRUTIL_TPTR);
  SG_node_risk_ptr[treeID]    = dvector(1, nodeCount);
  SG_node_risk_raw_ptr[treeID] = dvector(1, nodeCount);
}
void unstackTreeObjectsPtrOnly(uint treeID) {
  uint nodeCount, termCount;
  uint mwcpSize, mwcpCount;
  nodeCount = RF_nodeCount[treeID];
  termCount = RF_tLeafCount[treeID];  
  if (RF_xFactorCount > 0) {
    mwcpSize = (RF_xMaxFactorLevel >> (3 + ulog2(sizeof(uint)))) + ((RF_xMaxFactorLevel & (MAX_EXACT_LEVEL - 1)) ? 1 : 0);
  }
  else {
    mwcpSize = 0;
  }
  mwcpCount = mwcpSize * nodeCount;
  free_uivector(SG_treeID_ptr[treeID],   1, nodeCount);
  free_uivector(SG_nodeID_ptr[treeID],   1, nodeCount);
  free_uivector(SG_nodeSZ_ptr[treeID],   1, nodeCount);
  free_uivector(SG_brnodeID_ptr[treeID], 1, nodeCount);
  free_uivector(SG_prnodeID_ptr[treeID], 1, nodeCount);
  free_uivector(SG_parmID_ptr[treeID],   1, nodeCount);
  free_dvector (SG_contPT_ptr[treeID],   1, nodeCount);  
  free_uivector(SG_mwcpSZ_ptr[treeID],   1, nodeCount);
  if (mwcpCount > 0) {
    free_uivector(SG_mwcpPT_ptr[treeID], 1, mwcpCount);
  }
  free_uivector(SG_fsrecID_ptr[treeID],  1, nodeCount);
  free_dvector(SG_nodeStat_ptr[treeID],    1, nodeCount);
  free_uivector(SG_bsf_ptr[treeID],        1, nodeCount);
  free_new_vvector(RF_tTermList[treeID], 1, termCount, NRUTIL_TPTR);
  RF_tTermList[treeID] = NULL;
  free_dvector(SG_node_risk_ptr[treeID],     1, nodeCount);
  free_dvector(SG_node_risk_raw_ptr[treeID], 1, nodeCount);
}
void stackForestObjectsOutput(char mode) {
  uint totalNodeCount;
  uint totalMWCPCount;
  uint treeID;
  totalMWCPCount = 0;
  for (treeID = 1; treeID <= RF_ntree; treeID++) {
    totalMWCPCount += SG_mwcpCT_ptr[treeID];
  }
  totalNodeCount = RF_totalNodeCount;
  SG_treeID_   =   (uint*)  stackAndProtect(RF_auxDimConsts, mode, &RF_nativeIndex, NATIVE_TYPE_INTEGER, SG_TREE_ID,    totalNodeCount, 0, SG_sexpStringOutgoing, NULL, 1, totalNodeCount);
  SG_nodeID_   =   (uint*)  stackAndProtect(RF_auxDimConsts, mode, &RF_nativeIndex, NATIVE_TYPE_INTEGER, SG_NODE_ID,    totalNodeCount, 0, SG_sexpStringOutgoing, NULL, 1, totalNodeCount);
  SG_nodeSZ_   =   (uint*)  stackAndProtect(RF_auxDimConsts, mode, &RF_nativeIndex, NATIVE_TYPE_INTEGER, SG_NODE_SZ,    totalNodeCount, 0, SG_sexpStringOutgoing, NULL, 1, totalNodeCount);
  SG_brnodeID_ =   (uint*)  stackAndProtect(RF_auxDimConsts, mode, &RF_nativeIndex, NATIVE_TYPE_INTEGER, SG_BR_NODE_ID, totalNodeCount, 0, SG_sexpStringOutgoing, NULL, 1, totalNodeCount);
  SG_prnodeID_ =   (uint*)  stackAndProtect(RF_auxDimConsts, mode, &RF_nativeIndex, NATIVE_TYPE_INTEGER, SG_PR_NODE_ID, totalNodeCount, 0, SG_sexpStringOutgoing, NULL, 1, totalNodeCount);
  SG_treeID_   --;
  SG_nodeID_   --;
  SG_nodeSZ_   --;
  SG_brnodeID_ --;
  SG_prnodeID_ --;
  SG_parmID_   =   (uint*)  stackAndProtect(RF_auxDimConsts, mode, &RF_nativeIndex, NATIVE_TYPE_INTEGER, SG_PARM_ID,    totalNodeCount, 0, SG_sexpStringOutgoing, NULL, 1, totalNodeCount);
  SG_contPT_   = (double*)  stackAndProtect(RF_auxDimConsts, mode, &RF_nativeIndex, NATIVE_TYPE_NUMERIC, SG_CONT_PT,    totalNodeCount, 0, SG_sexpStringOutgoing, NULL, 1, totalNodeCount);
  SG_mwcpSZ_   =   (uint*)  stackAndProtect(RF_auxDimConsts, mode, &RF_nativeIndex, NATIVE_TYPE_INTEGER, SG_MWCP_SZ,    totalNodeCount, 0, SG_sexpStringOutgoing, NULL, 1, totalNodeCount);
  if (totalMWCPCount > 0) {
    SG_mwcpPT_   =   (uint*)  stackAndProtect(RF_auxDimConsts, mode, &RF_nativeIndex, NATIVE_TYPE_INTEGER, SG_MWCP_PT,    totalMWCPCount, 0, SG_sexpStringOutgoing, NULL, 1, totalMWCPCount);
    SG_mwcpPT_  --;
  }
  else {
    SG_mwcpPT_   =   (uint*)  stackAndProtect(RF_auxDimConsts, mode, &RF_nativeIndex, NATIVE_TYPE_INTEGER, SG_MWCP_PT,    1, 0, SG_sexpStringOutgoing, NULL, 1, 1);
  }
  SG_mwcpCT_  =    (uint*)  stackAndProtect(RF_auxDimConsts, mode, &RF_nativeIndex, NATIVE_TYPE_INTEGER, SG_MWCP_CT,    RF_ntree, 0, SG_sexpStringOutgoing, NULL, 1, RF_ntree);
  SG_fsrecID_  =   (uint*)  stackAndProtect(RF_auxDimConsts, mode, &RF_nativeIndex, NATIVE_TYPE_INTEGER, SG_FS_REC_ID,  totalNodeCount, 0, SG_sexpStringOutgoing, NULL, 1, totalNodeCount);
  SG_parmID_  --;
  SG_contPT_  --;
  SG_mwcpSZ_  --;
  SG_mwcpCT_  --;
  SG_fsrecID_ --;
  SG_nodeStat_ = (double*)  stackAndProtect(RF_auxDimConsts, mode, &RF_nativeIndex, NATIVE_TYPE_NUMERIC, SG_NODE_STAT, totalNodeCount, RF_nativeNaN, SG_sexpStringOutgoing, NULL, 1, totalNodeCount);
  SG_nodeStat_ --;
  SG_bsf_ = (uint*)  stackAndProtect(RF_auxDimConsts, mode, &RF_nativeIndex, NATIVE_TYPE_INTEGER, SG_BSF_ORD, totalNodeCount, 0, SG_sexpStringOutgoing, NULL, 1, totalNodeCount);
  SG_bsf_ --;
  SG_node_risk_ = (double*)  stackAndProtect(RF_auxDimConsts, mode, &RF_nativeIndex, NATIVE_TYPE_NUMERIC, SG_NODE_RISK, totalNodeCount, RF_nativeNaN, SG_sexpStringOutgoing, NULL, 1, totalNodeCount);
  SG_node_risk_ --;
  SG_node_risk_raw_ = (double*)  stackAndProtect(RF_auxDimConsts, mode, &RF_nativeIndex, NATIVE_TYPE_NUMERIC, SG_NODE_RISK_RAW, totalNodeCount, RF_nativeNaN, SG_sexpStringOutgoing, NULL, 1, totalNodeCount);
  SG_node_risk_raw_ --;
}
void writeForestObjectsOutput(char mode) {
  uint totalMWCPCount;
  uint offset;
  uint treeID;
  uint j, k;
  offset   = 0;
  for (treeID = 1; treeID <= RF_ntree; treeID++) {
    SG_mwcpCT_[treeID] = SG_mwcpCT_ptr[treeID];
    for (k = 1; k <= RF_nodeCount[treeID]; k++) {
      offset ++;
      SG_treeID_[offset]   = SG_treeID_ptr[treeID][k];
      SG_nodeID_[offset]   = SG_nodeID_ptr[treeID][k];
      SG_nodeSZ_[offset]   = SG_nodeSZ_ptr[treeID][k];
      SG_brnodeID_[offset] = SG_brnodeID_ptr[treeID][k];
      SG_prnodeID_[offset] = SG_prnodeID_ptr[treeID][k];
      SG_parmID_[offset] = SG_parmID_ptr[treeID][k];
      SG_contPT_[offset] = SG_contPT_ptr[treeID][k];
      SG_mwcpSZ_[offset] = SG_mwcpSZ_ptr[treeID][k];
      SG_fsrecID_[offset] = SG_fsrecID_ptr[treeID][k];
      SG_node_risk_[offset] = SG_node_risk_ptr[treeID][k];
      SG_node_risk_raw_[offset] = SG_node_risk_raw_ptr[treeID][k];
      SG_nodeStat_[offset] = SG_nodeStat_ptr[treeID][k];
      SG_bsf_[offset]      = SG_bsf_ptr[treeID][k];          
    }
  }
  if (offset != RF_totalNodeCount) {
    RF_nativeError("\nRF-SRC:  *** ERROR *** ");
    RF_nativeError("\nRF-SRC:  Inconsistent total node count encountered during writing of forest topology.");
    RF_nativeError("\nRF-SRC:  Offset versus total was:  %20lu, %20lu", offset, RF_totalNodeCount);
    RF_nativeError("\nRF-SRC:  Please Contact Technical Support.");
    RF_nativeExit();
  }
  totalMWCPCount = 0;
  for (treeID = 1; treeID <= RF_ntree; treeID++) {
    totalMWCPCount += SG_mwcpCT_[treeID];
  }
  offset = 0;
  for (treeID = 1; treeID <= RF_ntree; treeID++) {
    for (j = 1; j <= SG_mwcpCT_[treeID]; j++) {
      offset ++;
      SG_mwcpPT_[offset] = SG_mwcpPT_ptr[treeID][j];
    }
  }
  if (offset != totalMWCPCount) {
    RF_nativeError("\nRF-SRC:  *** ERROR *** ");
    RF_nativeError("\nRF-SRC:  Inconsistent MWCP count encountered during writing of forest topology.");
    RF_nativeError("\nRF-SRC:  Offset versus total MWCP count for hdim %10d was:  %20lu, %20lu", 1, offset, totalMWCPCount);
    RF_nativeError("\nRF-SRC:  Please Contact Technical Support.");
    RF_nativeExit();
  }
}
void stackForestObjectsAuxOnlySGT(void) {
  uint previousTreeID;
  uint i, b;
  ulong offset;
  RF_restoreTreeID = uivector(1, RF_ntree);
  SG_offsetTree = ulvector(1, RF_ntree);
  SG_offsetCT   = ulvector(1, RF_ntree);
  SG_offsetID_rmbr = ulvector(1, RF_ntree);
  SG_offsetID_imbr = ulvector(1, RF_ntree);
  SG_offsetID_ombr = ulvector(1, RF_ntree);
  previousTreeID = b = 0;
  for (ulong ui = 1; ui <= RF_totalNodeCount; ui++) {
    if ((SG_treeID_[ui] > 0) && (SG_treeID_[ui] <= RF_ntree)) {
      if (SG_treeID_[ui] != previousTreeID) {
        previousTreeID = RF_restoreTreeID[++b] = SG_treeID_[ui];
        SG_offsetTree[SG_treeID_[ui]] = ui;
      }
      RF_nodeCount[SG_treeID_[ui]] ++;
    }
    else {
      RF_nativeError("\nRF-SRC:  Diagnostic Trace of Tree Record:  \n");
      RF_nativeError("\nRF-SRC:      treeID     nodeID ");
      RF_nativeError("\nRF-SRC:  %10d %10d \n", SG_treeID_[ui], SG_nodeID_[ui]);
      RF_nativeError("\nRF-SRC:  *** ERROR *** ");
      RF_nativeError("\nRF-SRC:  Invalid forest input record at line:  %20lu", ui);
      RF_nativeError("\nRF-SRC:  Please Contact Technical Support.");
      RF_nativeExit();
    }
  }
  for (b = 1; b <= RF_ntree; b++) {
    SG_offsetCT[b] = 0;
    if (b == 1) {
      SG_offsetCT[b] = 1;
    }
    else {
      SG_offsetCT[b] = SG_offsetCT[b-1] + RF_tLeafCount[b-1];
    }
  }
  offset = 0;
  for (b = 1; b <= RF_ntree; b++) {
    SG_offsetID_rmbr[b] = 0;
    SG_offsetID_imbr[b] = 0;    
    SG_offsetID_ombr[b] = 0;
    if (b == 1) {
    }
    else {
      for (i = 1; i <= RF_tLeafCount[b-1]; i++) {
        ++offset;
        SG_offsetID_rmbr[b] += SG_rmbrTNodeCT_[offset];
        SG_offsetID_imbr[b] += SG_imbrTNodeCT_[offset];
        SG_offsetID_ombr[b] += SG_ombrTNodeCT_[offset];
      }
      SG_offsetID_rmbr[b] += SG_offsetID_rmbr[b-1];
      SG_offsetID_imbr[b] += SG_offsetID_imbr[b-1];
      SG_offsetID_ombr[b] += SG_offsetID_ombr[b-1];
    }
  }
}
void unstackForestObjectsAuxOnlySGT(void) {
  free_uivector(RF_restoreTreeID, 1, RF_ntree);
  free_ulvector(SG_offsetTree, 1, RF_ntree);
  free_ulvector(SG_offsetCT, 1, RF_ntree);
  free_ulvector(SG_offsetID_rmbr, 1, RF_ntree);
  free_ulvector(SG_offsetID_imbr, 1, RF_ntree);
  free_ulvector(SG_offsetID_ombr, 1, RF_ntree);
}
