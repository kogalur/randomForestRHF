
// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***
#include           "shared/globalCore.h"
#include           "shared/externalCore.h"
#include           "global.h"
#include           "external.h"

// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***

      
    

#include "rhfMainRT.h"
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
#include "treeOps.h"
#include "treeOpsRT.h"
#include "nodeOps.h"
#include "termOps.h"
#include "sexpOutgoing.h"
#include "stackOutput.h"
#include "splitUtil.h"
#include "processEnsemble.h"
#include "server.h"
#include "descriptor.h"
#include "shared/stackMembershipVectors.h"
char rhfMainRT(char mode, int seedValue) {
  uint b, bb;
  uint seedValueLC;
  char result;
  result = TRUE;
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
                                             RF_holdBLKptr,
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
          uint ranChainCnt;
          ranChainCnt = RF_ntree;
          ran1A = &randomChainParallelA;
          ran1B = &randomChainParallelB;
          randomSetChainA    = &randomSetChainParallelA;
          randomSetChainB    = &randomSetChainParallelB;
          randomGetChainA    = &randomGetChainParallelA;
          randomGetChainB    = &randomGetChainParallelB;
          stackRandom(ranChainCnt, ranChainCnt, 0, 0);
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
          char *perm = cvector(1, RF_xSize);
          for (uint i = 1; i <= RF_xSize; i++) {
            perm[i] = TRUE;
          }
          getAugmentationObjCommonGeneric =  getAugmentationObjCommon;
          freeAugmentationObjCommonGeneric =  freeAugmentationObjCommon;
          getAugmentationObjGeneric =  getAugmentationObjSimple;
          getAugmentationObjCommonGenericTest = getAugmentationObjCommonTest;
          SG_augmObjCommon = getAugmentationObjCommonGeneric(RF_observationSize,
                                                             RF_xSize,
                                                             RF_observationIn,
                                                             perm,
                                                             RF_responseIn);
          free_cvector(perm, 1, RF_xSize);
          stackForestObjectsAuxOnlySGT();
#ifdef _OPENMP
#pragma omp parallel for num_threads(RF_numThreads)
#endif
          for (bb = 1; bb <= RF_getTreeCount; bb++) {
            acquireTreeRT(mode, RF_getTreeIndex[bb]);
          }
          SG_headDO = makeDescriptorObj(0, 0, 0, SG_SOCK_STATE_OPN);
#ifdef _OPENMP
#pragma omp parallel for num_threads(RF_numThreads)
#endif
          for (bb = 1; bb <= 2; bb++) {
            sgtWorkRT(bb);
          }
          freeDescriptorObj(SG_headDO);
          for (bb = 1; bb <= RF_getTreeCount; bb++) {
            unstackMembershipVectors(RF_subjSize,
                                     RF_bootMembershipFlag[bb],
                                     RF_oobMembershipFlag[bb],
                                     RF_bootMembershipCount[bb],
                                     RF_ibgMembershipIndex[bb],
                                     RF_oobMembershipIndex[bb]);
            freeTree(bb, RF_root[bb]);
          }
          unstackForestObjectsAuxOnlySGT();
          freeAugmentationObjCommonGeneric(SG_augmObjCommon);
          stackRandom(ranChainCnt, ranChainCnt, 0, 0);
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
        }
        if ((RF_timeIndex > 0) && (RF_statusIndex > 0)) {
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
        }
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
    }
    unstackIncomingArrays(mode,
                          RF_ySize,
                          RF_yIndex,
                          RF_yIndexZero);
  }
  return result;
}
void sgtWorkRT(uint threadID) {
  uint hcutCntProxy;
  hcutCntProxy = RF_xSize;
#ifdef _OPENMP  
  if (threadID == 1) {
    omp_init_lock(&SG_lockDO);
    server(SG_tcpPort, SG_tcpTimeOut, RF_xSize, hcutCntProxy, SG_headDO);
    omp_destroy_lock(&SG_lockDO);
  }
  else if (threadID == 2) {
    predictForestRT(SG_headDO);
  }
#else
  if (threadID == 1) {  
    server(SG_tcpPort, SG_tcpTimeOut, RF_xSize, hcutCntProxy, SG_headDO);
  }
  else {
  }
  #endif
}
