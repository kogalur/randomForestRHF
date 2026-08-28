
// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***
#include           "shared/globalCore.h"
#include           "shared/externalCore.h"
#include           "global.h"
#include           "external.h"

// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***

      
    

#include "splitTDC.h"
#include "splitNLS.h"
#include "greedyInfo.h"
#include "splitUtil.h"
#include "augmentationOpsCommon.h"
#include "augmentationOpsSimple.h"
#include "augmentationOps.h"
#include "shared/error.h"
#include "shared/sampling.h"
#include "shared/factorOps.h"
#include "shared/splitInfo.h"
#include "shared/nrutil.h"
char virtuallySplitNodeTDC (uint       treeID,
                            GreedyObj *greedyMembr,
                            char   *localSplitIndicator,
                            uint   *localSplitIndx,
                            double *localSplitValue,
                            uint   *leftSize) {
  Node     *parent;
  NodeBase *baseParent;
  uint  repMembrSize;
  uint *repMembrIndx;
  uint     xvarID;
  uint     xvarCount;
  double  *splitVector;
  uint     splitVectorSize;
  uint   *indxx;
  double **xArray;
  uint priorMembrIter, currentMembrIter;
  uint rghtSize;
  char daughterFlag;
  uint splitLength;
  void *splitVectorPtr;
  double *observation;
  char factorFlag;
  uint mwcpSizeAbsolute;
  char deterministicSplitFlag;
  char result;
  double delta;
  uint i, j, k;
  parent = greedyMembr -> parent;
  baseParent = (NodeBase *) parent;
  AugmentationObjCommon *augmObjCommon = parent -> augm -> common;  
  repMembrSize = baseParent -> repMembrSize;
  repMembrIndx = baseParent -> repMembrIndx;
  xArray = augmObjCommon -> xArray;
  splitVector = dvector(1, repMembrSize);
  DistributionObj *distObj = stackRandomCovariates(treeID, baseParent, RF_mtry);
  double v0, u0, v1, u1, v2, u2, c1, c2, rn1, rn2;
  double max_v1, max_u1, max_v2, max_u2, max_c1, max_c2, max_rn1, max_rn2;  
  v1 = u1 = v2 = u2 = 0;
  delta = RF_nativeNaN;     
  max_v1 = max_u1 = max_v2 = max_u2 = 0;  
  max_c1 = max_c2 = max_rn1 = max_rn2 = 0;  
  SplitInfoMax *infoMax = (SplitInfoMax *) (greedyMembr -> splitInfoDerivedCart);
  double deltaMax;
  uint   indexMax;
  deltaMax = RF_nativeNaN;  
  v0 = parent -> v0;
  u0 = parent -> u0;
  xvarCount = 0;
  result = FALSE;
  while (selectRandomCovariates(treeID,
                                baseParent,
                                distObj,
                                RF_mtry,
                                & factorFlag,
                                & xvarID,
                                & xvarCount)) {
    observation = xArray[xvarID];
    splitVectorSize = stackAndConstructSplitVectorGenericPhase1(treeID,
                                                                baseParent,
                                                                xvarID,
                                                                observation,
                                                                splitVector,
                                                                & indxx);
    if (splitVectorSize >= 2) {
      splitLength = stackAndConstructSplitVectorGenericPhase2(treeID,
                                                              baseParent,
                                                              xvarID,
                                                              splitVector,
                                                              splitVectorSize,
                                                              factorFlag,
                                                              & deterministicSplitFlag,
                                                              & mwcpSizeAbsolute,
                                                              & splitVectorPtr);
      *leftSize = 0;
      priorMembrIter = 0;
      if (factorFlag == FALSE) {
        v2 = v0;
        u2 = u0;
        v1 = 0.0;
        u1 = 0.0;
        for (j = 1; j <= repMembrSize; j++) {
          localSplitIndicator[repMembrIndx[j]] = RIGHT;
        }
      }
      indexMax =  0;
      for (j = 1; j < splitLength; j++) {
        if (factorFlag == TRUE) {
          priorMembrIter = 0;
          *leftSize = 0;
        }
        virtuallySplitNode(treeID,
                           baseParent,
                           factorFlag,
                           mwcpSizeAbsolute,
                           observation,
                           indxx,
                           priorMembrIter,
                           splitVectorPtr,
                           j,
                           localSplitIndicator,                                 
                           leftSize,
                           & currentMembrIter);
        rghtSize = repMembrSize - (*leftSize);
        if (((*leftSize) != 0) && (rghtSize != 0)) {
          if (factorFlag == TRUE) {
            v1 = u1 = v2 = u2 = 0.0;
            for (k = 1; k <= repMembrSize; k++) {
              if (localSplitIndicator[ repMembrIndx[k] ] == LEFT) {
                if (RF_responseIn[RF_statusIndex][repMembrIndx[k]]  > 0) {
                  v1 ++;
                }
                u1 += (RF_responseIn[RF_timeIndex][repMembrIndx[k]] - RF_responseIn[RF_startTimeIndex][repMembrIndx[k]]);
              }
              else {
                if (RF_responseIn[RF_statusIndex][repMembrIndx[k]]  > 0) {
                  v2 ++;
                }
                u2 += (RF_responseIn[RF_timeIndex][repMembrIndx[k]] - RF_responseIn[RF_startTimeIndex][repMembrIndx[k]]);
              }
            } 
          }
          else {
            for (k = priorMembrIter + 1; k < currentMembrIter; k++) {
              if (RF_responseIn[RF_statusIndex][repMembrIndx[indxx[k]]]  > 0) {
                v1 ++;
                v2 --;
              }
              u1 += (RF_responseIn[RF_timeIndex][repMembrIndx[indxx[k]]] - RF_responseIn[RF_startTimeIndex][repMembrIndx[indxx[k]]]);
              u2 -= (RF_responseIn[RF_timeIndex][repMembrIndx[indxx[k]]] - RF_responseIn[RF_startTimeIndex][repMembrIndx[indxx[k]]]);              
            }
          }
          if ( (fabs(u1) < EPSILON2) || (fabs(u2) < EPSILON2) ) {
            delta = RF_nativeNaN;
          }
          else {
            c1 = 0.0;
            if (v1 > 0.0) {
              c1 = log((1.0 + v1) / u1);
            }
            rn1 = v1 * c1;
            c2 = 0.0;
            if (v2 > 0.0) {
              c2 = log((1.0 + v2) / u2);
            }
            rn2 = v2 * c2;
            if ((rn1 == 0) || (rn2 == 0)) {
               delta = RF_nativeNaN;
            }
            else {
              delta = rn1 + rn2;
            }
          }
        }
        else {
          delta = RF_nativeNaN;
        }
        if (!RF_nativeIsNaN(delta)) {
          if(RF_nativeIsNaN(deltaMax)) {
            deltaMax = delta;
            indexMax = j;
            max_v1  = v1;
            max_u1  = u1;
            max_c1  = c1;
            max_rn1 = rn1;
            max_v2  = v2;
            max_u2  = u2;
            max_c2  = c2;
            max_rn2 = rn2;
          }
          else {
            if ((delta - deltaMax) > EPSILON2) {
              deltaMax = delta;
              indexMax = j;
              max_v1  = v1;
              max_u1  = u1;
              max_c1  = c1;
              max_rn1 = rn1;
              max_v2  = v2;
              max_u2  = u2;
              max_c2  = c2;
              max_rn2 = rn2;
            }
            else {
            }
          }
        }
        else {
        }
        if (factorFlag == FALSE) {
          priorMembrIter = currentMembrIter - 1;
        }
      }  
      updateMaximumSplitCart(treeID,
                             parent,
                             deltaMax,
                             xvarID,
                             indexMax,
                             factorFlag,
                             mwcpSizeAbsolute,
                             splitVectorPtr,
                             infoMax);
      unstackSplitVectorGeneric(treeID,
                                baseParent,
                                splitLength,
                                factorFlag,            
                                splitVectorSize,
                                mwcpSizeAbsolute,
                                deterministicSplitFlag,
                                splitVectorPtr,
                                indxx);
    }
  }  
  unstackRandomCovariates(treeID, distObj);
  free_dvector(splitVector, 1, repMembrSize);
  if (!RF_nativeIsNaN(deltaMax)) {
    result = TRUE;
    *localSplitIndx = 0;
    *localSplitValue = RF_nativeNaN;
    Node *left  = makeNode(augmObjCommon -> pSize);
    Node *right = makeNode(augmObjCommon -> pSize);
    left  -> nSize = augmObjCommon -> nSize;
    right -> nSize = augmObjCommon -> nSize;
    greedyMembr -> leftCart  = left;
    greedyMembr -> rightCart = right;
    NodeBase *baseLeft  = (NodeBase *) left;
    NodeBase *baseRight = (NodeBase *) right;
    baseLeft ->  repMembrIndx  = uivector(1, repMembrSize);
    baseRight -> repMembrIndx  = uivector(1, repMembrSize);
    baseLeft  -> repMembrSizeAlloc = repMembrSize;
    baseRight -> repMembrSizeAlloc = repMembrSize;  
    *leftSize = 0;
    rghtSize = 0;
    observation = xArray[infoMax -> splitParameter];
    if (infoMax -> splitValueFactSize > 0) {
      for (i = 1; i <= repMembrSize; i++) {
        daughterFlag = splitOnFactor((uint)  observation[repMembrIndx[i]], infoMax -> splitValueFactPtr);
        if (daughterFlag == LEFT) {
          localSplitIndicator[repMembrIndx[i]] = LEFT;
          (*leftSize) ++;
          baseLeft -> repMembrIndx[*leftSize] = repMembrIndx[i];
        }
        else {
          localSplitIndicator[repMembrIndx[i]] = RIGHT;
          rghtSize ++;
          baseRight -> repMembrIndx[rghtSize] = repMembrIndx[i];
        }
      }
    }
    else {
      for (i = 1; i <= repMembrSize; i++) {
        if ( (infoMax -> splitValueCont - observation[repMembrIndx[i]]) >= 0.0) {
          daughterFlag = LEFT;
        }
        else {
          daughterFlag = RIGHT;
        }
        if (daughterFlag == LEFT) {
          localSplitIndicator[repMembrIndx[i]] = LEFT;
          (*leftSize) ++;
          baseLeft -> repMembrIndx[*leftSize] = repMembrIndx[i];
        }
        else {
          localSplitIndicator[repMembrIndx[i]] = RIGHT;
          rghtSize ++;
          baseRight -> repMembrIndx[rghtSize] = repMembrIndx[i];
        }
      }
    }
    baseLeft  -> repMembrSize = *leftSize;
    baseRight -> repMembrSize =  rghtSize;
    for (k = 1; k <= baseParent -> xSize; k++) {
      baseLeft -> permissible[k] = baseRight -> permissible[k] = baseParent -> permissible[k];
    }
    left  -> augm =  getAugmentationObjGeneric(augmObjCommon, treeID, left);
    right -> augm =  getAugmentationObjGeneric(augmObjCommon, treeID, right);
    saveRisk(treeID, left,  max_v1, max_u1, max_c1, max_rn1);
    saveRisk(treeID, right, max_v2, max_u2, max_c2, max_rn2);
    initializeRiskRaw(treeID, left);
    initializeRiskRaw(treeID, right);
  }
  return result;
}
void initializeRisk(uint treeID, Node *parent) {
  double **yArray;
  uint *repMembrIndx;
  uint  repMembrSize;
  double v0, u0, c0, rn0;
  uint k;
  yArray = parent -> augm -> common -> yArray;
  repMembrIndx = ((NodeBase *) parent) -> repMembrIndx;
  repMembrSize = ((NodeBase *) parent) -> repMembrSize;
  v0 = u0 = 0.0;
  for (k = 1; k <= repMembrSize; k++) {
    if (yArray[RF_statusIndex][repMembrIndx[k]]  > 0) {
      v0 ++;
    }
    u0 += (yArray[RF_timeIndex][repMembrIndx[k]] - yArray[RF_startTimeIndex][repMembrIndx[k]]);
  }
  c0 = 0.0;
  if (fabs(u0) < EPSILON2) {
    RF_nativeError("\nRF-SRC:  *** ERROR *** ");
    RF_nativeError("\nRF-SRC:  Entropy calculation in root node encountered zero value for U0.");
    RF_nativeError("\nRF-SRC:  Please Contact Technical Support.");
    RF_nativeExit();
  }
  if (v0 > 0.0) {
    c0 = log((1.0 + v0) / u0);
  }
  rn0 = v0 * c0;
  parent -> v0 = v0;
  parent -> u0 = u0;
  parent -> c0 = c0;
  parent -> rn0 = rn0;
  parent -> eRiskCart = rn0;
}
void saveRisk(uint treeID, Node *parent, double v0, double u0, double c0, double rn0) {
  parent -> v0 = v0;
  parent -> u0 = u0;
  parent -> c0 = c0;
  parent -> rn0 = rn0;
  parent -> eRiskCart = rn0;
}
