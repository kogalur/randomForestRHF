
// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***
#include           "shared/globalCore.h"
#include           "shared/externalCore.h"
#include           "global.h"
#include           "external.h"

// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***

      
    

#include "rhfMain.h"
#include "augmentationOps.h"
#include "augmentationOpsCommon.h"
#include "augmentationOpsSimple.h"
#include "shared/error.h"
#include "shared/random.h"
#include "shared/stackPreDefined.h"
#include "shared/stackAuxiliaryInfo.h"
#include "shared/preprocessForestRecord.h"
#include "shared/stackIncoming.h"
#include "shared/nrutil.h"
#include "shared/nativeUtil.h"
#include "shared/sexpIO.h"
#include "shared/stack.h"
#include "shared/stackParallel.h"
#include "survivalTDC.h"
#include "splitUtil.h"
#include "splitTDC.h"
#include "treeOps.h"
#include "nodeOps.h"
#include "termOps.h"
#include "sexpOutgoing.h"
#include "stackOutput.h"
#include "splitUtil.h"
#include "processEnsemble.h"
#include "processEnsembleCOE.h"
#include "stackOutputQQ.h"
#include "stackOutputQQTest.h"
#include "stackSubjectInfo.h"
char rhfMain(char mode, int seedValue) {
  uint b, bb;
  uint seedValueLC;
  char coeOOBRiskPrecomputed;
  char result;
  result = TRUE;
  coeOOBRiskPrecomputed = FALSE;
  seedValueLC    = 0; 
  if (seedValue >= 0) {
    RF_nativeError("\nRF-SRC:  *** ERROR *** ");
    RF_nativeError("\nRF-SRC:  Parameter verification failed.");
    RF_nativeError("\nRF-SRC:  Random seed must be less than zero.  \n");
    result = FALSE;
  }
  if (RF_observationSize < 1) {
    RF_nativeError("\nRF-SRC:  *** ERROR *** ");
    RF_nativeError("\nRF-SRC:  Parameter verification failed.");
    RF_nativeError("\nRF-SRC:  Number of individuals must be greater than one:  %10d \n", RF_observationSize);
    result = FALSE;
  }
  if (RF_xSize < 1) {
    RF_nativeError("\nRF-SRC:  *** ERROR *** ");
    RF_nativeError("\nRF-SRC:  Parameter verification failed.");
    RF_nativeError("\nRF-SRC:  Number of parameters must be greater than zero:  %10d \n", RF_xSize);
    result = FALSE;
  }
  if ((RF_perfBlock < 1) || (RF_perfBlock > RF_ntree)) {
    RF_nativeError("\nRF-SRC:  *** ERROR *** ");
    RF_nativeError("\nRF-SRC:  Parameter verification failed.");
    RF_nativeError("\nRF-SRC:  Invalid value specified for error block count:  %10d \n", RF_perfBlock);
    result = FALSE;
  }
#ifdef _OPENMP
  if (RF_numThreads < 0) {
    RF_numThreads = omp_get_max_threads();
  }
  else if (RF_numThreads == 0) {
    RF_nativeError("\nRF-SRC:  *** ERROR *** ");
    RF_nativeError("\nRF-SRC:  Parameter verification failed.");
    RF_nativeError("\nRF-SRC:  Number of threads must not be zero:  %10d \n", RF_numThreads);
    result = FALSE;
  }
  else {
    RF_numThreads = (RF_numThreads < omp_get_max_threads()) ? (RF_numThreads) : (omp_get_max_threads());
  }
#endif
  if (result) {
    result =  stackIncomingArrays(mode,
                                  RF_ntree,
                                  RF_timeInterestSize,
                                  RF_ytry,
                                  RF_mtry,
                                  RF_xWeight,
                                  RF_yWeight,
                                  RF_subjSize,
                                  RF_subjWeight,
                                  RF_xWeightStat,
                                  RF_nodeSize,
                                  RF_bootstrapSize,
                                  RAND_SPLIT,  
                                  RF_quantileSize,
                                  RF_quantile,
                                  RF_ySize,
                                  RF_rType,
                                  RF_frSize,
                                  RF_subjIn,
                                  RF_observationSize,
                                  RF_responseIn,
                                  RF_fresponseIn,
                                  RF_xSize,
                                  RF_xType,
                                  RF_fobservationSize,
                                  RF_observationIn,
                                  RF_fobservationIn,
                                  &RF_yIndex,
                                  &RF_yIndexZero,
                                  &RF_timeIndex,
                                  &RF_startTimeIndex,
                                  &RF_statusIndex,
                                  &RF_masterTime,
                                  &RF_masterTimeSize,
                                  &RF_sortedTimeInterestSize,
                                  &RF_startMasterTimeIndexIn,
                                  &RF_masterTimeIndexIn,
                                  &RF_ptnCount,
                                  &RF_ySizeProxy,
                                  &RF_yIndexZeroSize);
    if (result) {
      if (mode == RF_GROW) {
        if (RF_xWeight != NULL) {
          stackWeights(RF_xWeight,
                       RF_xSize,
                       &RF_xWeightType,
                       &RF_xWeightSorted,
                       &RF_xWeightDensitySize);
          stackRandomCovariates   = & stackRandomCovariatesDefault;
          unstackRandomCovariates = & unstackRandomCovariatesDefault;
          selectRandomCovariates  = & selectRandomCovariatesDefault;
        }
        else {
          stackRandomCovariates   = & stackRandomCovariatesSimple;
          unstackRandomCovariates = & unstackRandomCovariatesSimple;
          selectRandomCovariates  = & selectRandomCovariatesSimple;
        }
      }
      result = stackPreDefinedCommonArrays(mode,
                                           RF_ntree,
                                           RF_subjWeight,
                                           RF_timeIndex,
                                           RF_startTimeIndex,
                                           RF_statusIndex,
                                           RF_bootstrapSize,
                                           RF_bootstrapIn,
                                           RF_subjSize,
                                           RF_ptnCount,
                                           RF_getTree,
                                           RF_observationSize,
                                           &RF_nodeMembership,
                                           &RF_tTermMembership,
                                           &RF_pNodeMembership,
                                           &RF_pTermMembership,
                                           &RF_hTermMembership,
                                           &RF_tTermList,
                                           &RF_pNodeList,
                                           &RF_pTermList,
                                           &RF_bootMembershipFlag,
                                           &RF_oobMembershipFlag,
                                           &RF_bootMembershipCount,
                                           &RF_ibgMembershipIndex,
                                           &RF_oobMembershipIndex,
                                           &RF_oobSize,
                                           &RF_ibgSize,
                                           &RF_bootMembershipIndex,
                                           &RF_maxDepth,
                                           &RF_orderedTreeIndex,
                                           &RF_serialTreeIndex,
                                           &RF_root,
                                           &RF_nodeCount,
                                           &RF_leafLinkedObjHead,
                                           &RF_leafLinkedObjTail,
                                           &RF_pLeafCount,
                                           &RF_getTreeIndex,
                                           &RF_getTreeCount,
                                           &RF_subjWeightType,
                                           &RF_subjWeightSorted,
                                           &RF_subjWeightDensitySize,
                                           &RF_identityMembershipIndexSize,
                                           &RF_identityMembershipIndex);
      switch (mode) {
      case RF_PRED:
        stackPreDefinedPredictArrays(RF_ntree,
                                     RF_fobservationSize,
                                     & RF_fidentityMembershipIndexSize,
                                     & RF_fidentityMembershipIndex,
                                     & RF_fnodeMembership,
                                     &RF_ftTermMembership);
        break;
      case RF_REST:
        break;
      default:
        break;
      }
      if (result) {
        stackAndInitializeTimeAndSubjectArrays(mode,
                                               RF_startTimeIndex,
                                               RF_observationSize,
                                               RF_responseIn,
                                               RF_timeIndex,
                                               RF_timeInterestSize,
                                               RF_subjIn,
                                               &RF_subjSize,
                                               &RF_masterTime,
                                               &RF_masterTimeIndexIn,
                                               &RF_startMasterTimeIndexIn,
                                               &RF_timeInterest,
                                               &RF_masterTimeSize,
                                               &RF_sortedTimeInterestSize,
                                               &RF_masterToInterestTimeMap,
                                               &RF_subjSlot,
                                               &RF_subjSlotCount,
                                               &RF_subjList,
                                               &RF_caseMap,
                                               &RF_subjMap,
                                               &RF_subjCount);
        if (mode == RF_PRED) {
          if (SG_fsubjIn != NULL) {
            SG_fsubjSize = 0;
            stackSubjectArraysOnly(mode,
                                   RF_timeIndex,
                                   RF_statusIndex,
                                   RF_startTimeIndex,
                                   RF_fobservationSize,
                                   SG_fsubjIn,
                                   &SG_fsubjSize,
                                   &SG_fsubjSlot,
                                   &SG_fsubjSlotCount,
                                   &SG_fsubjList,
                                   &SG_fcaseMap,
                                   &SG_fsubjMap,
                                   &SG_fsubjCount);
            RF_fsubjIn = SG_fsubjIn;
            RF_fsubjSize = SG_fsubjSize;
            if (RF_fresponseIn != NULL) {
              stackSubjectTimeInterestIndex(mode,
                                            RF_timeIndex,
                                            RF_statusIndex,
                                            RF_startTimeIndex,
                                            RF_fobservationSize,
                                            RF_fresponseIn,
                                            SG_fsubjCount,
                                            SG_fsubjIn,
                                            SG_fsubjMap,
                                            SG_fsubjSlot,
                                            RF_sortedTimeInterestSize,
                                            RF_timeInterest,
                                            &SG_ftimeInterestIntervalCount,
                                            &SG_ftimeInterestIntervalIndex,
                                            &SG_ftimeInterestSubjTailIndex,
                                            &SG_fsubjTailCaseMap);
            }
          }
        }
        stackSubjectTimeInterestIndex(mode,
                                      RF_timeIndex,
                                      RF_statusIndex,
                                      RF_startTimeIndex,
                                      RF_observationSize,
                                      RF_responseIn,
                                      RF_subjCount,
                                      RF_subjIn,
                                      RF_subjMap,
                                      RF_subjSlot,
                                      RF_sortedTimeInterestSize,
                                      RF_timeInterest,
                                      &SG_timeInterestIntervalCount,
                                      &SG_timeInterestIntervalIndex,
                                      &SG_timeInterestSubjTailIndex,
                                      &SG_subjTailCaseMap);
        SG_timeInterestDelta = dvector(1, RF_sortedTimeInterestSize);
        getVectorDelta(RF_sortedTimeInterestSize, RF_timeInterest, SG_timeInterestDelta);
        if (result) {
          stackFactorArrays(mode,
                            RF_rType,
                            RF_xType,
                            RF_ySize,
                            RF_xSize,
                            RF_xLevelsCnt,
                            RF_rTarget,
                            RF_rTargetCount,
                            RF_timeIndex,
                            RF_statusIndex,
                            &RF_rFactorCount,
                            &RF_xFactorCount,
                            &RF_rFactorMap,
                            &RF_xFactorMap,
                            &RF_rFactorIndex,
                            &RF_xFactorIndex,
                            &RF_rFactorSize,
                            &RF_xFactorSize,
                            &RF_rNonFactorCount,
                            &RF_xNonFactorCount,
                            &RF_rNonFactorMap,
                            &RF_xNonFactorMap,
                            &RF_rNonFactorIndex,
                            &RF_xNonFactorIndex,
                            &RF_rTargetFactor,
                            &RF_rTargetNonFactor,
                            &RF_rTargetFactorCount,
                            &RF_rTargetNonFactorCount,
                            &RF_xLevels);
          initializeFactorArrays(mode,
                                 RF_rFactorCount,
                                 RF_xFactorCount,
                                 RF_rFactorIndex,
                                 RF_xFactorIndex,
                                 RF_rLevelsMax,
                                 RF_xLevelsMax,
                                 RF_rLevelsCnt,
                                 RF_xLevelsCnt,
                                 RF_ntree,
                                 RF_rFactorSize,
                                 RF_xFactorSize,
                                 &RF_rMaxFactorLevel,
                                 &RF_xMaxFactorLevel,
                                 &RF_maxFactorLevel,
                                 &RF_factorList);
          stackTrainingDataArraysWithPass(mode,
                                          RF_ySize,
                                          RF_ntree,
                                          RF_responseIn,
                                          RF_startTimeIndex,
                                          RF_statusIndex,
                                          RF_timeIndex,
                                          RF_startMasterTimeIndexIn,
                                          RF_masterTimeIndexIn,
                                          RF_observationSize,
                                          RF_observationIn,
                                          & RF_response,
                                          & RF_time,
                                          & RF_startTime,
                                          & RF_startMasterTimeIndex,
                                          & RF_masterTimeIndex,
                                          & RF_status,
                                          & RF_observation,
                                          & RF_mStatusFlag,
                                          & RF_mTimeFlag,
                                          & RF_mResponseFlag,
                                          & RF_mPredictorFlag,
                                          & RF_mRecordSize,
                                          & RF_mRecordMap);
          stackTestDataArraysWithPass(mode,
                                      RF_frSize,
                                      RF_ntree,
                                      RF_fresponseIn,
                                      RF_fobservationSize,
                                      RF_fobservationIn,
                                      & RF_fresponse,
                                      & RF_fobservation);
          if ((RF_timeIndex > 0) && (RF_statusIndex > 0)) {
            stackCompetingArrays(mode,
                                 RF_statusIndex,
                                 RAND_SPLIT,  
                                 RF_eventTypeSize,
                                 RF_eventType,
                                 RF_crWeightSize,
                                 RF_crWeight,
                                 RF_frSize,
                                 RF_observationSize,
                                 RF_fobservationSize,
                                 RF_responseIn,
                                 RF_fresponseIn,
                                 RF_mRecordMap,
                                 RF_fmRecordMap,
                                 RF_mRecordSize,
                                 RF_fmRecordSize,
                                 RF_mpSign,
                                 RF_fmpSign,
                                 &RF_eventTypeIndex,
                                 &RF_feventTypeSize,
                                 &RF_mStatusSize,
                                 &RF_eIndividualSize,
                                 &RF_eIndividualIn);
          }
          if (RF_rFactorCount > 0) {
            stackClassificationArrays(mode,
                                      RF_rFactorSize,
                                      RF_rLevelsCnt,
                                      RF_rFactorCount,
                                      RF_observationSize,
                                      RF_responseIn,
                                      RF_rFactorIndex,
                                      RF_frSize,
                                      RF_fresponseIn,
                                      RF_fobservationSize,
                                      &RF_rLevels,
                                      &RF_classLevelSize,
                                      &RF_classLevel,
                                      &RF_classLevelIndex,
                                      &RF_rFactorThreshold,
                                      &RF_rFactorMinority,
                                      &RF_rFactorMajority,
                                      &RF_rFactorMinorityFlag);
          }
          RF_auxDimConsts = makeAuxDimConsts(RF_rFactorSize,
                                             RF_rFactorCount,
                                             RF_rFactorMap,
                                             RF_rTargetFactor,
                                             RF_rTargetFactorCount,
                                             RF_tLeafCount_,  
                                             NULL);  
          for(b = 1; b <= RF_ntree; b++) {
            RF_serialTreeIndex[b] = 0;
          }
          RF_serialTreeID = 0;
          RF_ensembleUpdateCount = 0;
          RF_serialBlockID = 0;
          RF_perfBlockCount = (uint) floor(((double) RF_ntree) / RF_perfBlock);
          RF_incomingStackCount = 0;
          RF_stackCount = 0;
          RF_incomingAuxiliaryInfoList = NULL;
          stackDefinedOutputObjects(mode);
          RF_auxDimConsts -> tLeafCount = RF_tLeafCount;
          uint ranChainCnt;
          ranChainCnt = RF_ntree;
          ran1A = &randomChainParallelA;
          ran1B = &randomChainParallelB;
          randomSetChainA    = &randomSetChainParallelA;
          randomSetChainB    = &randomSetChainParallelB;
          randomGetChainA    = &randomGetChainParallelA;
          randomGetChainB    = &randomGetChainParallelB;
          stackRandom(ranChainCnt, ranChainCnt, 0, 0);
          if (mode == RF_GROW) {
            seedValueLC = abs(seedValue);
            lcgenerator(&seedValueLC, TRUE);
            for (b = 1; b <= ranChainCnt; b++) {
              lcgenerator(&seedValueLC, FALSE);
              lcgenerator(&seedValueLC, FALSE);
              while(seedValueLC == 0) {
                lcgenerator(&seedValueLC, FALSE);
              }
              randomSetChainA(b, -seedValueLC);
              if (RF_opt & OPT_SEED) {
                RF_seed_[b] = randomGetChainA(b);
              }
            }
            for (b = 1; b <= ranChainCnt; b++) {
              lcgenerator(&seedValueLC, FALSE);
              lcgenerator(&seedValueLC, FALSE);
              while(seedValueLC == 0) {
                lcgenerator(&seedValueLC, FALSE);
              }
              randomSetChainB(b, -seedValueLC);
            }
          }  
          else {
            for (b = 1; b <= ranChainCnt; b++) {
              randomSetChainA(b , RF_seed_[b]);
            }
            seedValueLC = abs(seedValue);
            lcgenerator(&seedValueLC, TRUE);
            for (b = 1; b <= ranChainCnt; b++) {
              lcgenerator(&seedValueLC, FALSE);
              lcgenerator(&seedValueLC, FALSE);
              while(seedValueLC == 0) {
                lcgenerator(&seedValueLC, FALSE);
              }
              randomSetChainB(b, -seedValueLC);
            }
          }
#ifdef _OPENMP
          stackLocksOpenMP(mode);
#endif
#ifdef NOT_HAVE_PTHREAD
          stackLocksPosix(mode);
#endif
          makeNode = & makeNodeDerived;
          freeNode = & freeNodeDerived;
          makeTerminal = & makeTerminalDerived;
          freeTerminal = & freeTerminalDerived;
          getVariance = & getVarianceSinglePass;
          calculateAllTerminalNodeOutcomes = & calculateAllTerminalNodeOutcomesTDC;
          assignAllTerminalNodeOutcomes    = & assignAllTerminalNodeOutcomesTDC;
          char *perm = cvector(1, RF_xSize);
          for (uint i = 1; i <= RF_xSize; i++) {
            perm[i] = TRUE;
          }
          if (mode == RF_GROW) {
            getAugmentationObjCommonGeneric =  getAugmentationObjCommon;
            freeAugmentationObjCommonGeneric =  freeAugmentationObjCommon;
            getAugmentationObjGeneric =  getAugmentationObj;
          }
          else {
            getAugmentationObjCommonGeneric =  getAugmentationObjCommon;
            freeAugmentationObjCommonGeneric =  freeAugmentationObjCommon;
            getAugmentationObjGeneric =  getAugmentationObjSimple;
            getAugmentationObjCommonGenericTest = getAugmentationObjCommonTest;
          }
          SG_augmObjCommon = getAugmentationObjCommonGeneric(RF_observationSize,
                                                             RF_xSize,
                                                             RF_observationIn,
                                                             perm,
                                                             RF_responseIn);
          free_cvector(perm, 1, RF_xSize);
          if (mode == RF_PRED) {
            getAugmentationObjCommonGenericTest(SG_augmObjCommon,
                                                RF_fobservationSize,
                                                RF_fobservationIn,
                                                (RF_fresponseIn == NULL) ? NULL: RF_fresponseIn);
          }
          if (mode == RF_GROW) {
            if (RF_opt & OPT_TREE) {
              stackForestObjectsPtrOnly(mode);
            }
          }
          else {
            stackForestObjectsAuxOnlySGT();
          }
#ifdef _OPENMP
#pragma omp parallel for num_threads(RF_numThreads)
#endif
          for (bb = 1; bb <= RF_getTreeCount; bb++) {
            acquireTree(mode, RF_getTreeIndex[bb]);
          }
          if (SG_optLocal &
              (SG_OPT_SWTCH_FOUR |
               SG_OPT_SWTCH_FIVE |
               SG_OPT_SWTCH_SIX)) {
            uint coeSubjCount;
            uint supportedSubjectCount;
            uint optimizedTrimIndex;
            coeSubjCount = (mode == RF_PRED) ? SG_fsubjCount : RF_subjCount;
#ifdef _OPENMP
#pragma omp parallel for num_threads(RF_numThreads)
#endif
            for (bb = 1; bb <= coeSubjCount; bb++) {
              populateCOEEnsembleSupport(mode, bb);
            }
            if ((SG_optLocal & SG_OPT_SWTCH_FIVE) &&
                (mode != RF_PRED) &&
                (RF_opt & OPT_OENS) &&
                (SG_coeTrimSize > 1)) {
              if ((SG_coeTrimRiskOOB_ == NULL) || (SG_oobRisk_ == NULL)) {
                RF_nativeError("\nRF-SRC:  *** ERROR *** ");
                RF_nativeError("\nRF-SRC:  Missing native storage for batched coe.trim OOB selection.");
                RF_nativeExit();
              }
              optimizedTrimIndex =
                selectCOETrimByOOBRiskAllTrim(SG_coeTrimRiskOOB_,
                                              &supportedSubjectCount,
                                              SG_oobRisk_);
              if (SG_coeTrim[optimizedTrimIndex] >=
                  SG_COE_TRIM_MEDIAN_FALLBACK_THRESHOLD) {
                SG_coeTrimIndex = SG_COE_TRIM_INDEX_MEDIAN_FALLBACK;
                coeOOBRiskPrecomputed = FALSE;
              }
              else {
                SG_coeTrimIndex = optimizedTrimIndex;
                coeOOBRiskPrecomputed = TRUE;
              }
            }
            else if ((SG_optLocal & SG_OPT_SWTCH_FIVE) &&
                     (mode != RF_PRED) &&
                     (RF_opt & OPT_OENS) &&
                     (SG_coeTrimSize == 1)) {
              SG_coeTrimIndex = 1;
            }
            if ((SG_coeTrimIndex > SG_coeTrimSize) ||
                ((SG_coeTrimIndex == SG_COE_TRIM_INDEX_MEDIAN_FALLBACK) &&
                 ((SG_optLocal & SG_OPT_SWTCH_FIVE) == 0))) {
              RF_nativeError("\nRF-SRC:  *** ERROR *** ");
              RF_nativeError("\nRF-SRC:  Invalid selected coe.trim index:  %10d",
                             SG_coeTrimIndex);
              RF_nativeExit();
            }
            if (SG_coeTrimIndex_ != NULL) {
              SG_coeTrimIndex_[1] = SG_coeTrimIndex;
            }
            getCOEEnsembleAggregateAllSubjects(mode,
                                               coeSubjCount,
                                               SG_coeTrimIndex);
          }
          if ((RF_opt & OPT_PERF) ||
              (RF_opt & OPT_OENS) ||
              (RF_opt & OPT_IENS) ||
              (RF_opt & OPT_FENS)) {
            if ( (SG_optLocal & (SG_OPT_SWTCH_FOUR | SG_OPT_SWTCH_FIVE | SG_OPT_SWTCH_SIX)) == 0) {
              normalizeEnsembleEstimates(mode);
            }
            populateEnsembleIds(mode);
            calculateRiskCore(mode,
                              (SG_optLocal & SG_OPT_WMODE) >> 16,
                              SG_coeTrimIndex,
                              coeOOBRiskPrecomputed);
            if ((SG_optLocal & SG_OPT_SWTCH_FIVE) &&
                (mode != RF_PRED) &&
                (RF_opt & OPT_OENS) &&
                (SG_coeTrimSize == 1)) {
              double scalarRisk;
              scalarRisk = getCOEOOBRiskObjective(NULL);
              if (SG_coeTrimRiskOOB_ != NULL) {
                SG_coeTrimRiskOOB_[1] = scalarRisk;
              }
            }
            if ((SG_optLocal &
                 (SG_OPT_SWTCH_FOUR |
                  SG_OPT_SWTCH_FIVE |
                  SG_OPT_SWTCH_SIX)) == 0) {
              calculateRiskRaw(mode);
            }
            finalizePathDomainOutputs(mode);
          }
          RF_totalNodeCount = 0;
          RF_totalTermCount = 0;
          for (b = 1; b <= RF_ntree; b++) {
            RF_totalNodeCount += RF_nodeCount[b];
            RF_totalTermCount += RF_tLeafCount[b];
          }
          if ((mode == RF_GROW) || (mode == RF_REST)) {
            if (RF_opt & OPT_TREE) {    
              stackForestObjectsOutput(mode);
              writeForestObjectsOutput(mode);
            }
            stackTNQualitativeObjects(mode,
                                      &SG_rmbrTNodeCT_,
                                      &SG_imbrTNodeCT_,
                                      &SG_ombrTNodeCT_,
                                      &SG_rmbrTNodeCT_ptr,
                                      &SG_imbrTNodeCT_ptr,
                                      &SG_ombrTNodeCT_ptr,
                                      &SG_rmbrTNodeID_,
                                      &SG_imbrTNodeID_,
                                      &SG_ombrTNodeID_,
                                      &SG_OOB_SZ_CASE_,
                                      &SG_IBG_SZ_CASE_);
            stackTNQualitativeObjectsForestPtr(mode,
                                               SG_rmbrTNodeID_,
                                               SG_imbrTNodeID_,
                                               SG_ombrTNodeID_,
                                               &SG_rmbrTNodeID_ptr,
                                               &SG_imbrTNodeID_ptr,
                                               &SG_ombrTNodeID_ptr);
            writeTNQualitativeObjectsOutput(mode,
                                            RF_tLeafCount,
                                            RF_tTermList,
                                            SG_oobSizeCase,
                                            SG_ibgSizeCase,
                                            SG_rmbrTNodeCT_ptr,
                                            SG_imbrTNodeCT_ptr,
                                            SG_ombrTNodeCT_ptr,
                                            SG_rmbrTNodeID_ptr,
                                            SG_imbrTNodeID_ptr,
                                            SG_ombrTNodeID_ptr,
                                            SG_OOB_SZ_CASE_,
                                            SG_IBG_SZ_CASE_);
            stackTNQuantitativeObjects(mode,
                                       &SG_termNelsonAalen_,
                                       &SG_termHazard_,
                                       &SG_termNelsonAalen_ptr,
                                       &SG_termHazard_ptr);
            writeTNQuantitativeObjectsOutput(mode,
                                             SG_termNelsonAalen_ptr,
                                             SG_termHazard_ptr);
            if ( (SG_optLocal & (SG_OPT_SWTCH_FOUR | SG_OPT_SWTCH_FIVE | SG_OPT_SWTCH_SIX)) != 0) {
              stackTNNodeTimeObjects(mode,
                                     &SG_nodeU_,
                                     &SG_nodeV_,
                                     &SG_nodeCOE_,
                                     &SG_nodeCumulativeCOE_,
                                     &SG_nodeU_ptr,
                                     &SG_nodeV_ptr,
                                     &SG_nodeCOE_ptr,
                                     &SG_nodeCumulativeCOE_ptr);
              writeTNNodeTimeObjects(mode,
                                     SG_nodeU_ptr,
                                     SG_nodeV_ptr,
                                     SG_nodeCOE_ptr,
                                     SG_nodeCumulativeCOE_ptr);
            }
            unstackTNQualitativeObjectsForestPtr(mode,
                                                 SG_rmbrTNodeID_ptr,
                                                 SG_imbrTNodeID_ptr,
                                                 SG_ombrTNodeID_ptr);
            if (RF_opt & OPT_TREE) {    
              unstackForestObjectsPtrOnly(mode);
            }
            if (mode == RF_REST) {
              unstackForestObjectsAuxOnlySGT();
            }
          }
          else {
            stackTNQualitativeObjectsTest(mode,
                                          &SG_ombrTNodeCT_,
                                          &SG_ombrTNodeCT_ptr,
                                          &SG_ombrTNodeID_);
            stackTNQualitativeObjectsForestPtrTest(mode,
                                                   SG_ombrTNodeID_,
                                                   &SG_ombrTNodeID_ptr);
            writeTNQualitativeObjectsOutputTest(mode,
                                                SG_ombrTNodeCT_ptr,
                                                SG_ombrTNodeID_ptr);
            if ( (SG_optLocal & (SG_OPT_SWTCH_FOUR | SG_OPT_SWTCH_FIVE | SG_OPT_SWTCH_SIX)) != 0) {
              stackTNNodeTimeObjects(mode,
                                     &SG_nodeU_,
                                     &SG_nodeV_,
                                     &SG_nodeCOE_,
                                     &SG_nodeCumulativeCOE_,
                                     &SG_nodeU_ptr,
                                     &SG_nodeV_ptr,
                                     &SG_nodeCOE_ptr,
                                     &SG_nodeCumulativeCOE_ptr);
              writeTNNodeTimeObjects(mode,
                                     SG_nodeU_ptr,
                                     SG_nodeV_ptr,
                                     SG_nodeCOE_ptr,
                                     SG_nodeCumulativeCOE_ptr);
            }
            unstackTNQualitativeObjectsForestPtrTest(mode, SG_ombrTNodeID_ptr);
            unstackForestObjectsAuxOnlySGT();
          }
          freeAugmentationObjCommonGeneric(SG_augmObjCommon);
          unstackDefinedOutputObjects(mode);
          unstackRandom(ranChainCnt, ranChainCnt, 0, 0);
#ifdef _OPENMP
          unstackLocksOpenMP(mode);
#endif
#ifdef NOT_HAVE_PTHREAD
          unstackLocksPosix(mode);
#endif
          for (uint bb = 1; bb <= RF_getTreeCount; bb++) {
            if(RF_tTermList[RF_getTreeIndex[bb]] != NULL) {
              free_new_vvector(RF_tTermList[RF_getTreeIndex[bb]], 1, RF_tLeafCount_[RF_getTreeIndex[bb]], NRUTIL_TPTR);
            }
            if (RF_leafLinkedObjHead[RF_getTreeIndex[bb]] != NULL) {
              freeLeafLinkedObjList(RF_leafLinkedObjHead[RF_getTreeIndex[bb]]);
            }
            free_new_vvector(RF_tTermMembership[RF_getTreeIndex[bb]], 1, RF_observationSize, NRUTIL_TPTR);
          }
          unstackAuxiliaryInfoAndList(RF_auxDimConsts,
                                      (mode == RF_GROW) ? FALSE : TRUE,
                                      RF_snpAuxiliaryInfoList,
                                      RF_stackCount);
          freeAuxDimConsts(RF_auxDimConsts);
          if (RF_rFactorCount > 0) {
            unstackClassificationArrays(mode,
                                        RF_rFactorSize,
                                        RF_rFactorCount,
                                        RF_rLevels,
                                        RF_classLevelSize,
                                        RF_classLevel,
                                        RF_classLevelIndex,
                                        RF_rFactorThreshold,
                                        RF_rFactorMinority,
                                        RF_rFactorMajority,
                                        RF_rFactorMinorityFlag);
          }
          if ((RF_timeIndex > 0) && (RF_statusIndex > 0)) {
            unstackCompetingArrays(mode,
                                   RF_statusIndex,
                                   RF_eventTypeSize,
                                   RF_eventType,
                                   RF_feventTypeSize,
                                   RF_eventTypeIndex,
                                   RF_mStatusSize,
                                   RF_eIndividualSize,
                                   RF_eIndividualIn);
          }
          unstackFactorArrays(mode,
                              RF_ntree,
                              RF_ySize,
                              RF_xSize,
                              RF_rTarget,
                              RF_rTargetCount,
                              RF_rTargetFactor,
                              RF_rTargetNonFactor,
                              RF_timeIndex,
                              RF_statusIndex,
                              RF_rFactorCount,
                              RF_xFactorCount,
                              RF_rFactorMap,
                              RF_xFactorMap,
                              RF_rFactorIndex,
                              RF_xFactorIndex,
                              RF_rFactorSize,
                              RF_xFactorSize,
                              RF_rNonFactorCount,
                              RF_xNonFactorCount,
                              RF_rNonFactorMap,
                              RF_xNonFactorMap,
                              RF_rNonFactorIndex,
                              RF_xNonFactorIndex,
                              RF_xLevels,
                              RF_factorList);
          unstackTrainingDataArraysWithPass(mode,
                                            RF_ySize,
                                            RF_ntree,
                                            RF_timeIndex,
                                            RF_statusIndex,
                                            RF_startTimeIndex,
                                            RF_response,
                                            RF_time,
                                            RF_masterTimeIndex,
                                            RF_startTime,
                                            RF_startMasterTimeIndex,
                                            RF_status,
                                            RF_observation);
          unstackTestDataArraysWithPass(mode,
                                        RF_ntree,
                                        RF_fresponse,
                                        RF_fobservation);
        }
        free_dvector(SG_timeInterestDelta, 1, RF_sortedTimeInterestSize);
        unstackSubjectTimeInterestIndex(mode,
                                        RF_observationSize,
                                        RF_subjCount,
                                        SG_timeInterestIntervalCount,
                                        SG_timeInterestIntervalIndex,
                                        SG_timeInterestSubjTailIndex,
                                        SG_subjTailCaseMap);
        unstackTimeAndSubjectArrays(mode,
                                    RF_startTimeIndex,
                                    RF_observationSize,
                                    RF_masterTime,
                                    RF_masterTimeIndexIn,
                                    RF_masterTimeSize,
                                    RF_startMasterTimeIndexIn,
                                    RF_masterToInterestTimeMap,
                                    RF_subjSlot,
                                    RF_subjSlotCount,
                                    RF_subjList,
                                    RF_caseMap,
                                    RF_subjMap,
                                    RF_subjCount);
        if (mode == RF_PRED) {
          if (RF_fresponseIn != NULL) {
            unstackSubjectTimeInterestIndex(mode,
                                            RF_fobservationSize,
                                            SG_fsubjCount,
                                            SG_ftimeInterestIntervalCount,
                                            SG_ftimeInterestIntervalIndex,
                                            SG_ftimeInterestSubjTailIndex,
                                            SG_fsubjTailCaseMap);
            if (SG_fsubjIn != NULL) {
              unstackSubjectArraysOnly(mode,
                                       RF_timeIndex,
                                       RF_statusIndex,
                                       RF_startTimeIndex,
                                       RF_fobservationSize,
                                       SG_fsubjCount,
                                       SG_fsubjSlot,
                                       SG_fsubjSlotCount,
                                       SG_fsubjList,
                                       SG_fcaseMap,
                                       SG_fsubjMap);
            }
          }
        }
      }
      switch (mode) {
      case RF_PRED:
        unstackPreDefinedPredictArrays(RF_ntree,
                                       RF_fobservationSize,
                                       RF_fidentityMembershipIndexSize,
                                       RF_fidentityMembershipIndex,
                                       RF_fnodeMembership,
                                       RF_ftTermMembership);
        break;
      case RF_REST:
        break;
      default:
        break;
      }
      unstackPreDefinedCommonArrays(mode,
                                    RF_ntree,
                                    RF_timeIndex,
                                    RF_startTimeIndex,
                                    RF_statusIndex,
                                    RF_subjSize,
                                    RF_ptnCount,
                                    RF_nodeMembership,
                                    RF_tTermMembership,
                                    RF_pNodeMembership,
                                    RF_pTermMembership,
                                    RF_hTermMembership,
                                    RF_tTermList,
                                    RF_pNodeList,
                                    RF_pTermList,
                                    RF_bootMembershipFlag,
                                    RF_oobMembershipFlag,
                                    RF_bootMembershipCount,
                                    RF_ibgMembershipIndex,
                                    RF_oobMembershipIndex,
                                    RF_oobSize,
                                    RF_ibgSize,
                                    RF_bootMembershipIndex,
                                    RF_maxDepth,
                                    RF_orderedTreeIndex,
                                    RF_serialTreeIndex,
                                    RF_root,
                                    RF_nodeCount,
                                    RF_leafLinkedObjHead,
                                    RF_leafLinkedObjTail,
                                    RF_pLeafCount,
                                    RF_getTreeIndex,
                                    RF_subjWeightType,
                                    RF_subjWeightSorted,
                                    RF_identityMembershipIndexSize,
                                    RF_identityMembershipIndex);
      if (mode == RF_GROW) {
        if (RF_xWeight != NULL) {
          unstackWeights(RF_xWeightType,
                         RF_xSize,
                         RF_xWeightSorted); 
        }
      }
    }
    unstackIncomingArrays(mode,
                          RF_ySize,
                          RF_yIndex,
                          RF_yIndexZero);
  }
  return result;
}
