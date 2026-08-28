
// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***
#include           "shared/globalCore.h"
#include           "shared/externalCore.h"
#include           "global.h"
#include           "external.h"

// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***

      
    

#include "entry.h"
#include "shared/nrutil.h"
#include "shared/stackForestObjects.h"
#include "shared/nativeUtil.h"
#include "shared/error.h"
#include "rhfMain.h"
#include "rhfMainRT.h"
#include "entryGeneric.h"
#include "stackOutput.h"
SEXP entryGrow(SEXP traceFlag,
               SEXP seedPtr,
               SEXP optLow,
               SEXP optHigh,
               SEXP optLocal,
               SEXP ntree,
               SEXP observationSize,
               SEXP sampleInfo,
               SEXP splitRule,
               SEXP nsplit,
               SEXP mtry,
               SEXP nodeSize,
               SEXP lot,
               SEXP yTarget,
               SEXP yInfo,
               SEXP yLevels,
               SEXP yData,
               SEXP timeInterest,
               SEXP xInfo,
               SEXP xLevels,
               SEXP xData,
               SEXP xWeight,
               SEXP augmxInfo,
               SEXP perfBlock,
               SEXP coeTrim,
               SEXP numThreads) {
  char mode;
  char result;
  result = TRUE;
  struct timespec start;
  struct timespec end;
  double elapsed;
  clock_gettime(CLOCK_MONOTONIC, &start);
  setUserTraceFlag(INTEGER(traceFlag)[0]);
  setNativeGlobalEnv(&RF_nativeIndex, &RF_stackCount);
  int seedValue           = INTEGER(seedPtr)[0];
  RF_opt                  = INTEGER(optLow)[0];
  RF_optHigh              = INTEGER(optHigh)[0];
  SG_optLocal             = INTEGER(optLocal)[0];
  RF_ntree                = INTEGER(ntree)[0];
  RF_observationSize      = INTEGER(observationSize)[0];
  RF_subjSize             = 0;
  RF_subjWeight           = NULL;
  RF_bootstrapSize        = 0;
  RF_bootstrapIn          = NULL;
  if(VECTOR_ELT(sampleInfo, 0) != R_NilValue) {
    RF_subjSize = INTEGER(VECTOR_ELT(sampleInfo, 0))[0];
    if(VECTOR_ELT(sampleInfo, 1) != R_NilValue) {
      RF_subjWeight = REAL(VECTOR_ELT(sampleInfo, 1)); RF_subjWeight--;
    }
    if(VECTOR_ELT(sampleInfo, 2) != R_NilValue) {  
      RF_bootstrapSize = INTEGER(VECTOR_ELT(sampleInfo, 2))[0];
      if(VECTOR_ELT(sampleInfo, 3) != R_NilValue) {
        RF_bootstrapIn = (uint **) copy2DObject(VECTOR_ELT(sampleInfo, 3), NATIVE_TYPE_INTEGER, TRUE, RF_ntree, RF_subjSize);
      }
    }
    else {
      RF_bootstrapSize        = RF_subjSize;
    }
  }
  SG_splitRule            = INTEGER(splitRule)[0];
  RF_nsplit               = INTEGER(nsplit)[0];  
  RF_mtry                 = INTEGER(mtry)[0];  
  RF_nodeSize             = INTEGER(nodeSize)[0];
  SG_hcut         = 1;
  SG_lotSize      = 0;
  SG_lotLag       = 0;
  SG_lotStrikeout = 0;
  if (VECTOR_ELT(lot, 0) != R_NilValue) {
    SG_hcut = INTEGER(VECTOR_ELT(lot, 0))[0];
  }
  if (VECTOR_ELT(lot, 1) != R_NilValue) {
    SG_lotSize = INTEGER(VECTOR_ELT(lot, 1))[0];
  }
  if (VECTOR_ELT(lot, 2) != R_NilValue) {
    SG_lotLag          = INTEGER(VECTOR_ELT(lot, 2))[0];
  }
  if (VECTOR_ELT(lot, 3) != R_NilValue) {
    SG_lotStrikeout    = INTEGER(VECTOR_ELT(lot, 3))[0];
  }
  RF_rTargetCount         = INTEGER(VECTOR_ELT(yTarget, 0))[0];
  if (VECTOR_ELT(yTarget, 1) != R_NilValue) {
    RF_rTarget         = (uint *) INTEGER(VECTOR_ELT(yTarget, 1));
    RF_rTarget --;
  }
  else {
    RF_rTarget = NULL;
  }
  RF_ySize                = INTEGER(VECTOR_ELT(yInfo, 0))[0];
  if(VECTOR_ELT(yInfo, 1) != R_NilValue) {
    RF_rType = (char *) copy1DObject(VECTOR_ELT(yInfo, 1), NATIVE_TYPE_CHARACTER, RF_ySize, TRUE);
  }
  else {
    RF_rType = NULL;
  }
  if(VECTOR_ELT(yInfo, 2) != R_NilValue) {
    RF_rLevelsMax         = (uint *) INTEGER(VECTOR_ELT(yInfo, 2)); RF_rLevelsMax--;
  }
  else {
    RF_rLevelsMax         = NULL;
  }
  if(VECTOR_ELT(yInfo, 3) != R_NilValue) {
    RF_rLevelsCnt         = (uint *) INTEGER(VECTOR_ELT(yInfo, 3)); RF_rLevelsCnt--;
  }
  else {
    RF_rLevelsCnt = NULL;
  }
  if(VECTOR_ELT(yInfo, 4) != R_NilValue) {
    RF_subjIn             =  (uint *) INTEGER(VECTOR_ELT(yInfo, 4));  RF_subjIn --;
  }
  else {
    RF_subjIn             = NULL;
  }
  RF_eventTypeSize      =  INTEGER(VECTOR_ELT(yInfo, 5))[0];
  RF_eventType        = NULL;
  if (RF_eventTypeSize > 0) {
    RF_eventType        =  (uint *) INTEGER(VECTOR_ELT(yInfo, 6));  RF_eventType --;
  }
  RF_rLevelsSEXP = yLevels;
  RF_rLevels = NULL;
  if(RF_ySize > 0) {
    RF_responseIn           = (double **) copy2DObject(yData, NATIVE_TYPE_NUMERIC, TRUE, RF_ySize, RF_observationSize);
  }
  else {
    RF_responseIn = NULL;
  }
  RF_timeInterest = NULL;
  RF_timeInterestSize = INTEGER(VECTOR_ELT(timeInterest, 0))[0];
  if (RF_timeInterestSize > 0) {
    RF_timeInterest = (double *) REAL(VECTOR_ELT(timeInterest, 1));
    RF_timeInterest --;
  }
  RF_xSize                 = INTEGER(VECTOR_ELT(xInfo, 0))[0];
  if(VECTOR_ELT(xInfo, 1) != R_NilValue) {
    RF_xType                = (char *) copy1DObject(VECTOR_ELT(xInfo, 1), NATIVE_TYPE_CHARACTER, RF_xSize, TRUE);
  }
  else {
    RF_xType = NULL;
  }
  if(VECTOR_ELT(xInfo, 2) != R_NilValue) {  
    RF_xLevelsMax           = (uint *) INTEGER(VECTOR_ELT(xInfo, 2)); RF_xLevelsMax--;
  }
  else {
    RF_xLevelsMax = NULL;
  }
  if(VECTOR_ELT(xInfo, 3) != R_NilValue) {
    RF_xLevelsCnt           = (uint *) INTEGER(VECTOR_ELT(xInfo, 3)); RF_xLevelsCnt --;
  }
  else {
    RF_xLevelsCnt = NULL;
  }
  RF_xtType = NULL;
  RF_stType = NULL;
  if(VECTOR_ELT(xInfo, 4) != R_NilValue) {
    RF_xtType             = (uint *) INTEGER(VECTOR_ELT(xInfo, 4)); RF_xtType --;
  }
  if(VECTOR_ELT(xInfo, 5) != R_NilValue) {
    RF_stType             = (uint *) INTEGER(VECTOR_ELT(xInfo, 5)); RF_stType --;
  }
  RF_xLevelsSEXP = xLevels;
  RF_xLevels = NULL;
  if (xData != R_NilValue) {
    RF_observationIn      = (double **) copy2DObject(xData, NATIVE_TYPE_NUMERIC, TRUE, RF_xSize, RF_observationSize);
  }
  else {
    RF_observationIn = NULL;
  }
  RF_xWeight = REAL(xWeight);  RF_xWeight--;
  SG_xSizeAugm = 0;
  SG_observationInAugm = NULL;
  if (augmxInfo != R_NilValue) {
    if(VECTOR_ELT(augmxInfo, 0) != R_NilValue) {
      SG_xSizeAugm = (uint) INTEGER(VECTOR_ELT(augmxInfo, 0))[0];
      if(VECTOR_ELT(augmxInfo, 1) != R_NilValue) {
        SG_observationInAugm = (double **) copy2DObject(VECTOR_ELT(augmxInfo, 1), NATIVE_TYPE_NUMERIC, TRUE, SG_xSizeAugm, RF_observationSize);
      }
      else {
        SG_xSizeAugm = 0;
      }
    }
  }
  RF_perfBlock            = INTEGER(perfBlock)[0];
  SG_coeTrimSize          = (uint) XLENGTH(coeTrim);
  if (SG_coeTrimSize < 1) {
    RF_nativeError("\nRF-SRC:  *** ERROR *** ");
    RF_nativeError("\nRF-SRC:  coe.trim must contain at least one value.");
    RF_nativeExit();
  }
  SG_coeTrim              = REAL(coeTrim);  SG_coeTrim --;
  SG_coeTrimIndex         = 1;
  RF_numThreads           = INTEGER(numThreads)[0];
  mode = processDefaultGrow();
  if (result) {
    result = rhfMain(mode, seedValue);
  }
  free_1DObject(RF_rType, NATIVE_TYPE_CHARACTER, RF_ySize);
  free_1DObject(RF_xType, NATIVE_TYPE_CHARACTER, RF_xSize);
  if (RF_responseIn != NULL) free_2DObject(RF_responseIn, NATIVE_TYPE_NUMERIC, RF_ySize > 0, RF_ySize, RF_observationSize);
  if (RF_observationIn != NULL) free_2DObject(RF_observationIn, NATIVE_TYPE_NUMERIC, TRUE, RF_xSize, RF_observationSize);
  if (SG_observationInAugm != NULL) free_2DObject(SG_observationInAugm, NATIVE_TYPE_NUMERIC, TRUE, SG_xSizeAugm, RF_observationSize);
  if (RF_nativeIndex != RF_stackCount) {
    RF_nativeError("\nRF-SRC:  *** ERROR *** ");
    RF_nativeError("\nRF-SRC:  Stack imbalance in PROTECT/UNPROTECT:  %10d versus %10d  ", RF_nativeIndex, RF_stackCount);
    RF_nativeError("\nRF-SRC:  Please Contact Technical Support.");
    RF_nativeExit();
  }
  if (result && (RF_stackCount > 0)) {
    clock_gettime(CLOCK_MONOTONIC, &end);
    elapsed = (double) (end.tv_sec - start.tv_sec)
      + (double) (end.tv_nsec - start.tv_nsec) * 1e-9;
    SG_cpuTime_[1] = elapsed;
    R_ReleaseObject(RF_sexpVector[RF_OUTP_ID]);
    R_ReleaseObject(RF_sexpVector[RF_STRG_ID]);
    return RF_sexpVector[RF_OUTP_ID];
  }
  else {
    SG_cpuTime_[1] = 0;    
    return NULL;
  }
}
SEXP entryPred(SEXP traceFlag,
               SEXP seedPtr,
               SEXP optLow,
               SEXP optHigh,
               SEXP optLocal,
               SEXP ntree,
               SEXP observationSize,
               SEXP sampleInfo,
               SEXP hcut,
               SEXP splitRule,
               SEXP yTarget,
               SEXP yInfo,
               SEXP yLevels,
               SEXP yData,
               SEXP timeInterest,
               SEXP xInfo,
               SEXP xLevels,
               SEXP xData,
               SEXP augmxInfo,
               SEXP fobservationSize,
               SEXP fsubj,
               SEXP fyData,
               SEXP fxData,
               SEXP totalNodeCount,
               SEXP tLeafCount,
               SEXP seedInfo,
               SEXP treeID,
               SEXP nodeID,
               SEXP nodeSZ,
               SEXP brnodeID,
               SEXP hc_zero,
               SEXP rmbrCT,
               SEXP imbrCT,
               SEXP ombrCT,
               SEXP rmbrID,
               SEXP imbrID,
               SEXP ombrID,
               SEXP getTree,
               SEXP perfBlock,
               SEXP coeTrim,
               SEXP coeTrimIndex,
               SEXP realTimeOpt,
               SEXP numThreads) {
  char mode;
  char result;
  result = TRUE;
  struct timespec start;
  struct timespec end;
  double elapsed;
  clock_gettime(CLOCK_MONOTONIC, &start);
  setUserTraceFlag(INTEGER(traceFlag)[0]);
  setNativeGlobalEnv(&RF_nativeIndex, &RF_stackCount);
  int seedValue           = INTEGER(seedPtr)[0];
  RF_opt                  = INTEGER(optLow)[0];
  RF_optHigh              = INTEGER(optHigh)[0];
  SG_optLocal             = INTEGER(optLocal)[0];
  RF_ntree                = INTEGER(ntree)[0];
  RF_observationSize      = INTEGER(observationSize)[0];
  RF_subjSize             = RF_observationSize;
  RF_subjWeight           = NULL;
  RF_bootstrapSize        = RF_observationSize;
  RF_bootstrapIn          = NULL;
  if(VECTOR_ELT(sampleInfo, 0) != R_NilValue) {
    RF_subjSize = INTEGER(VECTOR_ELT(sampleInfo, 0))[0];
    if(VECTOR_ELT(sampleInfo, 1) != R_NilValue) {
      RF_subjWeight = REAL(VECTOR_ELT(sampleInfo, 1)); RF_subjWeight--;
    }
    if(VECTOR_ELT(sampleInfo, 2) != R_NilValue) {  
      RF_bootstrapSize = INTEGER(VECTOR_ELT(sampleInfo, 2))[0];
      if(VECTOR_ELT(sampleInfo, 3) != R_NilValue) {
        RF_bootstrapIn = (uint **) copy2DObject(VECTOR_ELT(sampleInfo, 3), NATIVE_TYPE_INTEGER, TRUE, RF_ntree, RF_subjSize);
      }
    }
    else {
      RF_bootstrapSize        = RF_subjSize;
    }
  }
  SG_hcut = INTEGER(hcut)[0];
  SG_splitRule = INTEGER(splitRule)[0];
  RF_rTargetCount         = INTEGER(VECTOR_ELT(yTarget, 0))[0];
  if (VECTOR_ELT(yTarget, 1) != R_NilValue) {
    RF_rTarget         = (uint *) INTEGER(VECTOR_ELT(yTarget, 1));
    RF_rTarget --;
  }
  else {
    RF_rTarget = NULL;
  }
  RF_ySize                = INTEGER(VECTOR_ELT(yInfo, 0))[0];
  if(VECTOR_ELT(yInfo, 1) != R_NilValue) {
    RF_rType = (char *) copy1DObject(VECTOR_ELT(yInfo, 1), NATIVE_TYPE_CHARACTER, RF_ySize, TRUE);
  }
  else {
    RF_rType = NULL;
  }
  if(VECTOR_ELT(yInfo, 2) != R_NilValue) {
    RF_rLevelsMax         = (uint *) INTEGER(VECTOR_ELT(yInfo, 2)); RF_rLevelsMax--;
  }
  else {
    RF_rLevelsMax         = NULL;
  }
  if(VECTOR_ELT(yInfo, 3) != R_NilValue) {
    RF_rLevelsCnt         = (uint *) INTEGER(VECTOR_ELT(yInfo, 3)); RF_rLevelsCnt--;
  }
  else {
    RF_rLevelsCnt = NULL;
  }
  if(VECTOR_ELT(yInfo, 4) != R_NilValue) {
    RF_subjIn             =  (uint *) INTEGER(VECTOR_ELT(yInfo, 4));  RF_subjIn --;
  }
  else {
    RF_subjIn             = NULL;
  }
  RF_eventTypeSize      =  INTEGER(VECTOR_ELT(yInfo, 5))[0];
  RF_eventType        = NULL;
  if (RF_eventTypeSize > 0) {
    RF_eventType        =  (uint *) INTEGER(VECTOR_ELT(yInfo, 6));  RF_eventType --;
  }
  RF_rLevelsSEXP = yLevels;
  RF_rLevels = NULL;
  if(RF_ySize > 0) {
    RF_responseIn           = (double **) copy2DObject(yData, NATIVE_TYPE_NUMERIC, TRUE, RF_ySize, RF_observationSize);
  }
  else {
    RF_responseIn = NULL;
  }
  RF_timeInterest = NULL;
  RF_timeInterestSize = INTEGER(VECTOR_ELT(timeInterest, 0))[0];
  if (RF_timeInterestSize > 0) {
    RF_timeInterest = (double *) REAL(VECTOR_ELT(timeInterest, 1));
    RF_timeInterest --;
  }
  RF_xSize                 = INTEGER(VECTOR_ELT(xInfo, 0))[0];
  if(VECTOR_ELT(xInfo, 1) != R_NilValue) {
    RF_xType                = (char *) copy1DObject(VECTOR_ELT(xInfo, 1), NATIVE_TYPE_CHARACTER, RF_xSize, TRUE);
  }
  else {
    RF_xType = NULL;
  }
  if(VECTOR_ELT(xInfo, 2) != R_NilValue) {
    RF_xLevelsMax           = (uint *) INTEGER(VECTOR_ELT(xInfo, 2)); RF_xLevelsMax--;
  }
  else {
    RF_xLevelsMax = NULL;
  }
  if(VECTOR_ELT(xInfo, 3) != R_NilValue) {
    RF_xLevelsCnt           = (uint *) INTEGER(VECTOR_ELT(xInfo, 3)); RF_xLevelsCnt --;
  }
  else {
    RF_xLevelsCnt = NULL;
  }
  RF_xtType = NULL;
  RF_stType = NULL;
  RF_xLevelsSEXP = xLevels;
  RF_xLevels = NULL;
  if (xData != R_NilValue) {
    RF_observationIn      = (double **) copy2DObject(xData, NATIVE_TYPE_NUMERIC, TRUE, RF_xSize, RF_observationSize);
  }
  else {
    RF_observationIn = NULL;
  }
  SG_xSizeAugm = 0;
  SG_observationInAugm = NULL;
  if (augmxInfo != R_NilValue) {
    if(VECTOR_ELT(augmxInfo, 0) != R_NilValue) {
      SG_xSizeAugm = (uint) INTEGER(VECTOR_ELT(augmxInfo, 0))[0];
      if(VECTOR_ELT(augmxInfo, 1) != R_NilValue) {
        SG_observationInAugm = (double **) copy2DObject(VECTOR_ELT(augmxInfo, 1), NATIVE_TYPE_NUMERIC, TRUE, SG_xSizeAugm, RF_observationSize);
      }
    }
  }
  RF_fobservationSize      = INTEGER(fobservationSize)[0];
  RF_frSize = 0;
  RF_fresponseIn = NULL;
  RF_fobservationIn = NULL;
  if(RF_fobservationSize > 0) {
    SG_fsubjIn = NULL;
    RF_fresponseIn = NULL;
    RF_frSize = 0;
    if (fsubj != R_NilValue) {
      SG_fsubjIn = (uint *) INTEGER(fsubj);  SG_fsubjIn --;
    }
    if (fyData != R_NilValue) {    
      RF_fresponseIn           = (double **) copy2DObject(fyData, NATIVE_TYPE_NUMERIC, TRUE, RF_ySize, RF_fobservationSize);
      RF_frSize = RF_ySize;
    }
    RF_fobservationIn      = (double **) copy2DObject(fxData, NATIVE_TYPE_NUMERIC, TRUE, RF_xSize, RF_fobservationSize);
  }
  RF_totalNodeCount       = INTEGER(totalNodeCount)[0];
  RF_tLeafCount           = (uint *) INTEGER(tLeafCount); RF_tLeafCount --;
  RF_seed_                = (int *) INTEGER(seedInfo); RF_seed_ --;
  SG_treeID_              = (uint *) INTEGER(treeID);   SG_treeID_   --;
  SG_nodeID_              = (uint *) INTEGER(nodeID);   SG_nodeID_   --;
  SG_nodeSZ_              = (uint *) INTEGER(nodeSZ);   SG_nodeSZ_   --;
  SG_brnodeID_            = (uint *) INTEGER(brnodeID); SG_brnodeID_ --;
  SG_parmID_              = (uint *)   INTEGER(VECTOR_ELT(hc_zero, 0)); SG_parmID_  --;
  SG_contPT_              = (double *) REAL(VECTOR_ELT(hc_zero, 1)); SG_contPT_  --;
  SG_mwcpSZ_              = (uint *)   INTEGER(VECTOR_ELT(hc_zero, 2)); SG_mwcpSZ_  --;
  SG_fsrecID_             = (uint *)   INTEGER(VECTOR_ELT(hc_zero, 3)); SG_fsrecID_ --;
  if (VECTOR_ELT(hc_zero, 4) != R_NilValue) {
    SG_mwcpPT_            = (uint *)   INTEGER(VECTOR_ELT(hc_zero, 4));  SG_mwcpPT_ --;
  }
  else {
    SG_mwcpPT_ = NULL;
  }
  SG_rmbrTNodeCT_ = (uint *) INTEGER(rmbrCT); SG_rmbrTNodeCT_ --;
  SG_imbrTNodeCT_ = (uint *) INTEGER(imbrCT); SG_imbrTNodeCT_ --;
  SG_ombrTNodeCT_ = (uint *) INTEGER(ombrCT); SG_ombrTNodeCT_ --;
  SG_rmbrTNodeID_ = (uint *) INTEGER(rmbrID); SG_rmbrTNodeID_ --;
  SG_imbrTNodeID_ = (uint *) INTEGER(imbrID); SG_imbrTNodeID_ --;
  SG_ombrTNodeID_ = (uint *) INTEGER(ombrID); SG_ombrTNodeID_ --;
  RF_perfBlock            = INTEGER(perfBlock)[0];
  SG_coeTrimSize          = (uint) XLENGTH(coeTrim);
  if (SG_coeTrimSize < 1) {
    RF_nativeError("\nRF-SRC:  *** ERROR *** ");
    RF_nativeError("\nRF-SRC:  coe.trim must contain at least one value.");
    RF_nativeExit();
  }
  SG_coeTrim              = REAL(coeTrim);  SG_coeTrim --;
  SG_coeTrimIndex         = (uint) INTEGER(coeTrimIndex)[0];
  if ( (SG_coeTrimIndex > SG_coeTrimSize) ||
       ((SG_coeTrimIndex == 0) && ((SG_optLocal & SG_OPT_SWTCH_FIVE) == 0)) ) {
    RF_nativeError("\nRF-SRC:  *** ERROR *** ");
    RF_nativeError("\nRF-SRC:  Invalid selected coe.trim index:  %10d", SG_coeTrimIndex);
    RF_nativeExit();
  }
  RF_getTree = (uint *) INTEGER(getTree);  RF_getTree --;
  RF_numThreads           = INTEGER(numThreads)[0];
  SG_tcpPort = 0;
  SG_tcpTimeOut = 0;
  if(realTimeOpt != R_NilValue) {
    SG_tcpPort = (uint) INTEGER(VECTOR_ELT(realTimeOpt, 0))[0];
    SG_tcpTimeOut = (uint) INTEGER(VECTOR_ELT(realTimeOpt, 1))[0];
  }
  mode = processDefaultPredict();
  if (mode == RF_REAL) {
    result = rhfMainRT(mode, seedValue);
  }
  else {
    result = rhfMain(mode, seedValue);
  }
  free_1DObject(RF_rType, NATIVE_TYPE_CHARACTER, RF_ySize);
  free_1DObject(RF_xType, NATIVE_TYPE_CHARACTER, RF_xSize);
  if (RF_responseIn != NULL) free_2DObject(RF_responseIn, NATIVE_TYPE_NUMERIC, RF_ySize > 0, RF_ySize, RF_observationSize);
  if (RF_observationIn != NULL) free_2DObject(RF_observationIn, NATIVE_TYPE_NUMERIC, TRUE, RF_xSize, RF_observationSize);
  if (SG_observationInAugm != NULL) free_2DObject(SG_observationInAugm, NATIVE_TYPE_NUMERIC, TRUE, SG_xSizeAugm, RF_observationSize);
  if (mode != RF_REAL) {
    if (RF_fresponseIn != NULL) free_2DObject(RF_fresponseIn, NATIVE_TYPE_NUMERIC, RF_ySize > 0, RF_ySize, RF_fobservationSize);  
    if (RF_fobservationIn != NULL) free_2DObject(RF_fobservationIn, NATIVE_TYPE_NUMERIC, TRUE, RF_xSize, RF_fobservationSize);
    if (SG_fobservationInAugm != NULL) free_2DObject(SG_fobservationInAugm, NATIVE_TYPE_NUMERIC, TRUE, SG_xSizeAugm, RF_fobservationSize);
  }
  if (RF_nativeIndex != RF_stackCount) {
    RF_nativeError("\nRF-SRC:  *** ERROR *** ");
    RF_nativeError("\nRF-SRC:  Stack imbalance in PROTECT/UNPROTECT:  %10d versus %10d  ", RF_nativeIndex, RF_stackCount);
    RF_nativeError("\nRF-SRC:  Please Contact Technical Support.");
    RF_nativeExit();
  }
  if (result && (RF_stackCount > 0)) {
    clock_gettime(CLOCK_MONOTONIC, &end);
    elapsed = (double) (end.tv_sec - start.tv_sec)
      + (double) (end.tv_nsec - start.tv_nsec) * 1e-9;
    SG_cpuTime_[1] = elapsed;
    R_ReleaseObject(RF_sexpVector[RF_OUTP_ID]);
    R_ReleaseObject(RF_sexpVector[RF_STRG_ID]);
    return RF_sexpVector[RF_OUTP_ID];
  }
  else {
    SG_cpuTime_[1] = 0;
    return NULL;
  }
}
