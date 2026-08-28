
// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***
#include           "shared/globalCore.h"
#include           "shared/externalCore.h"
#include           "global.h"
#include           "external.h"

// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***

      
    

#include "treeOps.h"
#include "terminal.h"
#include "node.h"
#include "stackOutput.h"
#include "stackOutputQQ.h"
#include "rhfMain.h"
#include "termOps.h"
#include "greedyInfo.h"
#include "greedyOps.h"
#include "splitGreedy.h"
#include "splitTDC.h"
#include "splitNLS.h"
#include "survivalTDC.h"
#include "processEnsemble.h"
#include "shared/stackMembershipVectors.h"
#include "shared/stackPreDefined.h"
#include "shared/terminalBase.h"
#include "shared/nrutil.h"
#include "shared/restoreTree.h"
#include "shared/bootstrap.h"
#include "shared/nodeBaseOps.h"
#include "shared/termBaseOps.h"
#include "shared/polarityNew.h"
#include "shared/error.h"
void acquireTree(char mode, uint treeID) {
  Node     *root;
  NodeBase *rootBase;
  TerminalBase *termBase;
  uint  nSize, xSize;
  uint *bootMembrIndx;
  uint  bootMembrSize;
  char  bootResult;
  ulong offsetTree;
  ulong offsetCT, offsetID_rmbr, offsetID_imbr, offsetID_ombr;
  uint  i, j, k;
#ifdef _OPENMP
#endif
  nSize = SG_augmObjCommon -> nSize;
  xSize = SG_augmObjCommon -> pSize;
  stackMembershipVectors(RF_subjCount,
                         &RF_bootMembershipFlag[treeID],
                         &RF_oobMembershipFlag[treeID],
                         &RF_bootMembershipCount[treeID],
                         &RF_ibgMembershipIndex[treeID],
                         &RF_oobMembershipIndex[treeID]);
  stackFactorInSitu(treeID,
                    RF_rFactorCount,
                    RF_xFactorCount,
                    RF_maxFactorLevel,
                    RF_rFactorSize,
                    RF_xFactorSize,
                    RF_factorList);
  RF_nodeMembership[treeID] = (NodeBase **) new_vvector(1, nSize, NRUTIL_NPTR);
  RF_tTermMembership[treeID] = (TerminalBase **) new_vvector(1, nSize, NRUTIL_TPTR);
  RF_leafLinkedObjHead[treeID] = RF_leafLinkedObjTail[treeID] = makeLeafLinkedObj();
  for (i = 1; i <= nSize; i++) {
    RF_tTermMembership[treeID][i] = NULL;
  }
  root = makeNode(xSize);
  root -> nSize = nSize;
  rootBase = (NodeBase *) root;
  RF_root[treeID] = rootBase;
  rootBase -> parent = NULL;
  rootBase -> nodeID = 1;
  for (k = 1; k <= rootBase -> xSize; k++) {
    rootBase -> permissible[k] = TRUE;
  }
  rootBase -> allMembrSizeAlloc = rootBase -> allMembrSize = nSize;
  rootBase -> allMembrIndx = uivector(1, rootBase -> allMembrSizeAlloc);
  for (i = 1; i <= nSize; i++) {
    rootBase -> allMembrIndx[i] = i;
  }
  SG_bsfOrder = 0;
  if ( (RF_opt & OPT_BOOT_TYP1) || (RF_opt & OPT_BOOT_TYP2)) {
    bootMembrSize = RF_bootstrapSize;
  }
  else {
    bootMembrSize = RF_subjCount;
  }
  bootMembrIndx  = uivector(1, bootMembrSize);
  bootResult = bootstrap (mode,
                          treeID,
                          rootBase,              
                          RF_identityMembershipIndex,  
                          RF_subjCount,                
                          bootMembrSize,         
                          RF_bootstrapIn,        
                          RF_subjCount,           
                          RF_subjWeight,         
                          RF_subjWeightType,
                          RF_subjWeightSorted,
                          RF_subjWeightDensitySize,
                          nSize,                 
                          bootMembrIndx,         
                          RF_bootMembershipFlag,
                          RF_oobMembershipFlag,
                          RF_bootMembershipCount,
                          RF_oobSize,
                          RF_ibgSize,
                          RF_ibgMembershipIndex,
                          RF_oobMembershipIndex,
                          SG_BOOT_CT_ptr);
  if (bootResult) {
    if (mode == RF_GROW) {
      rootBase -> repMembrSizeAlloc = 0;
      for (i = 1; i <= bootMembrSize; i++) {
        k = bootMembrIndx[i];
        rootBase -> repMembrSizeAlloc += RF_subjSlotCount[k];
      }
      rootBase -> repMembrIndx = uivector(1, rootBase -> repMembrSizeAlloc);
      rootBase -> repMembrSize = 0;
      for (i = 1; i <= bootMembrSize; i++) {
        k = bootMembrIndx[i];
        for (j = 1; j <= RF_subjSlotCount[k]; j++) {
          rootBase -> repMembrIndx[++(rootBase -> repMembrSize)] = RF_subjList[k][j];
        }
      }
      SG_bootstrapSizeCase[treeID] = rootBase -> repMembrSize;
      SG_bootMembershipFlagCase[treeID] = cvector(1, nSize);
      SG_oobMembershipFlagCase[treeID] = cvector(1, nSize);
      for (i = 1; i <= nSize; i++) {
        SG_bootMembershipFlagCase[treeID][i]  = FALSE;
        SG_oobMembershipFlagCase[treeID][i]   = TRUE;
      }
      SG_ibgMembershipIndexCase[treeID] = uivector(1, nSize);
      SG_oobMembershipIndexCase[treeID] = uivector(1, nSize);
      for (i = 1; i <= rootBase -> repMembrSize; i++) {
        SG_bootMembershipFlagCase[treeID][rootBase -> repMembrIndx[i]] =  TRUE;
        SG_oobMembershipFlagCase[treeID][rootBase -> repMembrIndx[i]] =  FALSE;
      }
      SG_oobSizeCase[treeID] = 0;
      SG_ibgSizeCase[treeID] = 0;
      for (i = 1; i <= nSize; i++) {
        if (SG_bootMembershipFlagCase[treeID][i] == FALSE) {
          SG_oobMembershipIndexCase[treeID][++SG_oobSizeCase[treeID]] = i;
        }
        else {
          SG_ibgMembershipIndexCase[treeID][++SG_ibgSizeCase[treeID]] = i;
        }
      }
      growTreeLOT(treeID, root);
    }
    else {
      rootBase -> repMembrSizeAlloc = 0;
      for (i = 1; i <= bootMembrSize; i++) {
        k = bootMembrIndx[i];
        rootBase -> repMembrSizeAlloc += RF_subjSlotCount[k];
      }
      rootBase -> repMembrIndx = uivector(1, rootBase -> repMembrSizeAlloc);
      rootBase -> repMembrSize = 0;
      for (i = 1; i <= bootMembrSize; i++) {
        k = bootMembrIndx[i];
        for (j = 1; j <= RF_subjSlotCount[k]; j++) {
          rootBase -> repMembrIndx[++(rootBase -> repMembrSize)] = RF_subjList[k][j];
        }
      }
      SG_bootstrapSizeCase[treeID] = rootBase -> repMembrSize;
      SG_bootMembershipFlagCase[treeID] = cvector(1, nSize);
      SG_oobMembershipFlagCase[treeID] = cvector(1, nSize);
      for (i = 1; i <= nSize; i++) {
        SG_bootMembershipFlagCase[treeID][i]  = FALSE;
        SG_oobMembershipFlagCase[treeID][i]   = TRUE;
      }
      SG_ibgMembershipIndexCase[treeID] = uivector(1, nSize);
      SG_oobMembershipIndexCase[treeID] = uivector(1, nSize);
      for (i = 1; i <= rootBase -> repMembrSize; i++) {
        SG_bootMembershipFlagCase[treeID][rootBase -> repMembrIndx[i]] =  TRUE;
        SG_oobMembershipFlagCase[treeID][rootBase -> repMembrIndx[i]] =  FALSE;
      }
      SG_oobSizeCase[treeID] = 0;
      SG_ibgSizeCase[treeID] = 0;
      for (i = 1; i <= nSize; i++) {
        if (SG_bootMembershipFlagCase[treeID][i] == FALSE) {
          SG_oobMembershipIndexCase[treeID][++SG_oobSizeCase[treeID]] = i;
        }
        else {
          SG_ibgMembershipIndexCase[treeID][++SG_ibgSizeCase[treeID]] = i;
        }
      }
      root -> augm = getAugmentationObjGeneric(SG_augmObjCommon, treeID, root);
      RF_tTermList[treeID] = (TerminalBase **) new_vvector(1, RF_tLeafCount[treeID], NRUTIL_TPTR);
      restoreTreeLOT(treeID, root, SG_offsetTree);
      restoreTNQualitativeObjectsInput(mode, treeID, NULL, NULL, NULL, NULL, NULL, NULL);
      for (k = 1; k <= RF_tLeafCount[treeID]; k++) {
        termBase = RF_tTermList[treeID][k];
        Terminal *tTerm = (Terminal *) termBase;
        for (i = 1; i <= tTerm -> ibgMembrCount; i++) {
          RF_tTermMembership[treeID][tTerm -> ibgMembrIndx[i]] = termBase;
          if ((mode == RF_REST) && (RF_optHigh & OPT_MEMB_USER)) {
            SG_MEMB_ID_ptr[treeID][tTerm -> ibgMembrIndx[i]] = termBase -> nodeID;
          }
        }
        for (i = 1; i <= tTerm -> oobMembrCount; i++) {
          RF_tTermMembership[treeID][tTerm -> oobMembrIndx[i]] = termBase;
          if ((mode == RF_REST) && (RF_optHigh & OPT_MEMB_USER)) {
            SG_MEMB_ID_ptr[treeID][tTerm -> oobMembrIndx[i]] = termBase -> nodeID;
          }
        }
      }
      for (k = 1; k <= RF_tLeafCount[treeID]; k++) {
        termBase = RF_tTermList[treeID][k];
        assignAllTerminalNodeOutcomes(RF_REST, treeID, termBase);
      }
      if (mode == RF_PRED) {
        root -> tstMembrSize = root -> tstMembrSizeAlloc = RF_fobservationSize;
        root -> tstMembrIndx = RF_fidentityMembershipIndex;
        getTestMembershipLOT(treeID, root);
      }
    }
  }
  else {
  }
  if (bootResult) {
      RF_nodeCount[treeID]  = (RF_tLeafCount[treeID] << 1) - 1;
      processEnsembleInSitu(mode, treeID);
  }
  else {
    RF_nodeCount[treeID] = 1;
    RF_tLeafCount[treeID] = 1;
  }
  if (mode == RF_GROW) {
    if (RF_opt & OPT_TREE) {
      offsetTree = offsetCT = offsetID_rmbr = offsetID_imbr = offsetID_ombr = 0;
      stackTreeObjectsPtrOnly(mode, treeID);
      saveTree(treeID, rootBase, & offsetTree, & offsetCT, & offsetID_rmbr, & offsetID_imbr, & offsetID_ombr);
    }
  }
  if (bootResult) {
    free_uivector(rootBase -> repMembrIndx, 1, rootBase -> repMembrSizeAlloc);
    rootBase -> repMembrIndx = NULL;
    rootBase -> repMembrSize = rootBase -> repMembrSizeAlloc = 0;
    if (mode == RF_GROW) {
    }
    else {
      if (mode == RF_PRED) {
        root -> tstMembrIndx = NULL;
        root -> tstMembrSize = root -> tstMembrSizeAlloc = 0;
      }
    }
  }
  free_uivector(bootMembrIndx, 1, bootMembrSize);
  free_cvector(SG_bootMembershipFlagCase[treeID], 1, nSize);
  free_cvector(SG_oobMembershipFlagCase[treeID], 1, nSize);
  free_uivector(SG_oobMembershipIndexCase[treeID], 1, nSize);
  free_uivector(SG_ibgMembershipIndexCase[treeID], 1, nSize);
  free_new_vvector(RF_nodeMembership[treeID], 1, nSize, NRUTIL_NPTR);
  unstackFactorInSitu(treeID,
                      RF_rFactorCount,
                      RF_xFactorCount,
                      RF_maxFactorLevel,
                      RF_factorList);
  unstackMembershipVectors(RF_subjCount,
                           RF_bootMembershipFlag[treeID],
                           RF_oobMembershipFlag[treeID],
                           RF_bootMembershipCount[treeID],
                           RF_ibgMembershipIndex[treeID],
                           RF_oobMembershipIndex[treeID]);
  freeTree(treeID, rootBase);
}
void freeTree(uint treeID, NodeBase *parent) {
  if (parent != NULL) {
    if ((parent -> left != NULL) && (parent -> right != NULL)) {
      freeTree(treeID, ((NodeBase *) parent) -> left);
      freeTree(treeID, ((NodeBase *) parent) -> right);
    }
    freeNode((Node *) parent);
  }
}
char growTreeLOT (uint treeID, Node *root) {
  Node     *parent;
  NodeBase *parentBase;
  Node     *left;
  Node     *right;
  uint *allMembrIndx;
  uint  allMembrSize;
  char  splitResult;
  char  result;
  GreedyObj *greedyHead, *greedyMembr;
  GreedyObj *greedyBest;
  double dropBest, dropCurrent;
  LatOptTreeObj *lotObj;
  double delta;
  char   updateFlag;
  char   growFlag;
  double v0, u0, c0, rn0;
  uint i;
  RF_tLeafCount[treeID] = 1;
  greedyHead = makeGreedyObj(NULL, NULL);
  result = FALSE;
  greedyHead -> head = greedyHead;
  greedyMembr = makeGreedyObj(root, greedyHead);
  greedyHead -> fwdLink = greedyMembr;
  greedyMembr -> bakLink = greedyHead;
  root -> augm = getAugmentationObjGeneric(SG_augmObjCommon, treeID, root);
  parent = root;
  parentBase = (NodeBase *) root;
  lotObj = makeLatOptTreeObj(SG_lotLag);
  allMembrIndx = parentBase -> allMembrIndx;
  allMembrSize = parentBase -> allMembrSize;
  initializeRisk(treeID, root);
  initializeRiskRaw(treeID, root);
  if (RF_opt & OPT_EMPR_RISK) {
    SG_ibg_tree_risk_ptr[treeID][lotObj -> treeSize] = parent -> eRiskCart;
    SG_ibg_tree_risk_raw_ptr[treeID][lotObj -> treeSize] = parent -> eRiskRaw;
  }
  v0 = u0 = 0.0;
  for (i = 1; i <= allMembrSize; i++) {
    if (SG_oobMembershipFlagCase[treeID][allMembrIndx[i]]) {
      if (RF_responseIn[RF_statusIndex][allMembrIndx[i]]  > 0) {
        v0 ++;
      }
      u0 += (RF_responseIn[RF_timeIndex][allMembrIndx[i]] - RF_responseIn[RF_startTimeIndex][allMembrIndx[i]]);
    }
  }
  c0 = 0.0;
  if (v0 > 0.0) {
    c0 = log(v0/u0);
  }
  rn0 = v0 * c0;
  parent -> eRiskCartOOB = rn0;
  insertRisk(treeID, lotObj, parent -> eRiskCart);
  growFlag = TRUE;
  while (growFlag) {
    greedyMembr = greedyHead -> fwdLink;
    while (greedyMembr != NULL) {
      if ((greedyMembr -> leafFlag == FALSE) && (greedyMembr -> splitInfoDerivedCart == NULL)) {
        if (lotObj -> treeSize < (uint) SG_lotSize) {
          splitResult = getBestSplit(treeID, lotObj, greedyMembr);
          if (splitResult) {
          }
          else {
            parent = greedyMembr -> parent;
            parentBase = (NodeBase*) parent;
            parentBase -> splitFlag = FALSE;
            parent -> splitInfoDerived = NULL;
            greedyMembr -> leafFlag = TRUE;
          }
        }
        else {
        }
      }
      else {
      }
      greedyMembr = greedyMembr -> fwdLink;
    }  
    greedyBest = NULL;
    dropBest = RF_nativeNaN;
    if (lotObj -> treeSize < (uint) SG_lotSize) {
      greedyMembr = greedyHead -> fwdLink;
      while (greedyMembr != NULL) {
        if (greedyMembr -> leafFlag == FALSE) {
          if ((greedyMembr -> splitInfoDerivedCart != NULL)) {
            if (RF_nativeIsNaN(greedyMembr -> eRiskLossCart)) {
              RF_nativeError("\nRF-SRC:  *** ERROR *** ");
              RF_nativeError("\nRF-SRC:  Greedy member has abnormal undefined risk loss:  %10x", greedyMembr);
              RF_nativeError("\nRF-SRC:  Please Contact Technical Support.");
              RF_nativeExit();
            }
            if (greedyBest == NULL) {
              greedyBest = greedyMembr;
              dropBest = greedyMembr -> eRiskLossCart;
            }
            else {
              dropCurrent = greedyMembr -> eRiskLossCart;
              delta = dropCurrent - dropBest;
              if (delta > 0.0) {
                updateFlag = TRUE;
              }
              else if (delta < 0.0) {
                updateFlag = FALSE;
              }
              else {
                if (ran1B(treeID) <= 0.5) {
                  updateFlag = TRUE;
                }
                else {
                  updateFlag = FALSE;
                }
              }
              if (updateFlag) {
                greedyBest = greedyMembr;
                dropBest = dropCurrent;
              }
              else {
              }
            }
          }
          else {
              RF_nativeError("\nRF-SRC:  *** ERROR *** ");
              RF_nativeError("\nRF-SRC:  Greedy member is naked and not a leaf:  %10x", greedyMembr);
              RF_nativeError("\nRF-SRC:  Please Contact Technical Support.");
              RF_nativeExit();
          }
        }
        else {
        }
        greedyMembr = greedyMembr -> fwdLink;
      }  
    }  
    if (greedyBest != NULL) {
      result = forkAndUpdate(treeID,
                             greedyBest,
                             &RF_tLeafCount[treeID],
                             RF_nodeMembership[treeID]);
      if (result == TRUE) {
        parent = greedyBest -> parent;
        left   = (Node *)  (((NodeBase *) parent) -> left);
        right  = (Node *)  (((NodeBase *) parent) -> right);
        (lotObj -> treeSize) ++;
        if (RF_opt & OPT_EMPR_RISK) {
          double parentRisk, leftRisk, rightRisk;
          parentRisk = parent -> eRiskCart;
          leftRisk = left -> eRiskCart;
          rightRisk = right -> eRiskCart;
          SG_ibg_tree_risk_ptr[treeID][lotObj -> treeSize] = SG_ibg_tree_risk_ptr[treeID][(lotObj -> treeSize) - 1] 
            - parentRisk + leftRisk + rightRisk;
          parentRisk = parent -> eRiskRaw;
          leftRisk = left -> eRiskRaw;
          rightRisk = right -> eRiskRaw;
          SG_ibg_tree_risk_raw_ptr[treeID][lotObj -> treeSize] = SG_ibg_tree_risk_raw_ptr[treeID][(lotObj -> treeSize) - 1] 
            - parentRisk + leftRisk + rightRisk;
          if (SG_splitRule == SG_SURV_TDC) {
            insertRisk(treeID, lotObj, SG_ibg_tree_risk_ptr[treeID][lotObj -> treeSize]);
          }
          else if (SG_splitRule == SG_SURV_NLS) {
            insertRisk(treeID, lotObj, SG_ibg_tree_risk_raw_ptr[treeID][lotObj -> treeSize]);
          }
        }
        GreedyObj *greedyNakedLeft  = makeGreedyObj(left,  greedyHead);
        GreedyObj *greedyNakedRight = makeGreedyObj(right,  greedyHead);
        (greedyBest -> bakLink) -> fwdLink = greedyNakedLeft;
        greedyNakedLeft -> bakLink = greedyBest -> bakLink;
        greedyNakedLeft -> fwdLink = greedyNakedRight;
        greedyNakedRight -> bakLink = greedyNakedLeft;
        greedyNakedRight -> fwdLink = greedyBest -> fwdLink;
        if (greedyBest -> fwdLink != NULL) {
          (greedyBest -> fwdLink) -> bakLink = greedyNakedRight;
        }
        if ((greedyBest -> splitInfoDerivedCart != NULL)) {
          RF_nativeError("\nRF-SRC:  *** ERROR *** ");
          RF_nativeError("\nRF-SRC:  Error in deletion of best greedy object from list, that represents the split actual node.");
          RF_nativeError("\nRF-SRC:  The split information object is non-null:  %10x", greedyBest -> splitInfoDerivedCart);
          RF_nativeError("\nRF-SRC:  Please Contact Technical Support.");
          RF_nativeExit();          
        }
        freeGreedyObj(greedyBest);
      }
      else {
        RF_nativeError("\nRF-SRC:  *** ERROR *** ");
        RF_nativeError("\nRF-SRC:  forkAndUpdate(%10d) failed.", treeID);
        RF_nativeError("\nRF-SRC:  Please Contact Technical Support.");
        RF_nativeExit();
      }
    }  
    else {
      growFlag = FALSE;
    }
    if (lotObj -> strikeout >= SG_lotStrikeout) {
      growFlag = FALSE;
    }
  }  
  greedyMembr = greedyHead -> fwdLink;
  while (greedyMembr != NULL) {
    parent = greedyMembr -> parent;
    parentBase = (NodeBase*) parent;
    RF_leafLinkedObjTail[treeID] = makeAndSpliceLeafLinkedObj(RF_leafLinkedObjTail[treeID]);
    RF_leafLinkedObjTail[treeID] -> nodePtr = parentBase;
    RF_leafLinkedObjTail[treeID] -> termPtr = (TerminalBase *) makeTerminal();
    parentBase -> mate = RF_leafLinkedObjTail[treeID] -> termPtr;
    (RF_leafLinkedObjTail[treeID] -> termPtr) -> mate = parentBase;
    RF_leafLinkedObjTail[treeID] -> nodeID = (RF_leafLinkedObjTail[treeID] -> termPtr) -> nodeID = parentBase -> nodeID;
    for (i = 1; i <= parentBase -> allMembrSize; i++) {
      RF_tTermMembership[treeID][parentBase -> allMembrIndx[i]] = RF_leafLinkedObjTail[treeID] -> termPtr;
    }
    if (RF_optHigh & OPT_MEMB_USER) {
      for (i = 1; i <= parentBase -> allMembrSize; i++) {
        SG_MEMB_ID_ptr[treeID][parentBase -> allMembrIndx[i]] = parentBase -> nodeID;
      }
    }
    initTerminalBase(RF_leafLinkedObjTail[treeID] -> termPtr,
                     RF_eventTypeSize,
                     RF_masterTimeSize,
                     SG_allTimeInterestSize,
                     RF_sortedTimeInterestSize,
                     0,      
                     NULL,   
                     0,      
                     NULL,   
                     NULL);  
    calculateAllTerminalNodeOutcomes(RF_GROW, treeID, RF_leafLinkedObjTail[treeID] -> termPtr);
    greedyMembr = greedyMembr -> fwdLink;
  }
  if (RF_opt & OPT_EMPR_RISK) {        
    for (i = 1; i <= lotObj -> treeSize; i++) {
      SG_ibg_tree_risk_ptr[treeID][i] = SG_ibg_tree_risk_ptr[treeID][i] / RF_bootstrapSize;
      SG_ibg_tree_risk_raw_ptr[treeID][i] = SG_ibg_tree_risk_raw_ptr[treeID][i] / RF_bootstrapSize;
    }
  }
  freeGreedyObjList(greedyHead);
  freeLatOptTreeObj(lotObj);
  return result;
}
char forkAndUpdate (uint treeID, GreedyObj *greedyMembr, uint *leafCount, NodeBase **nodeMembership) {
  Node *parent, *left, *right;
  NodeBase *parentBase, *leftBase, *rightBase;
  uint *allMembrIndx;
  uint  allMembrSize;
  double **xArray;
  uint i;
  left = right = NULL;
  parent = greedyMembr -> parent;
  parentBase = (NodeBase*) parent;
  AugmentationObjCommon *augmObjCommon = parent -> augm -> common;
  left = greedyMembr -> leftCart;
  right = greedyMembr -> rightCart;
  parent -> splitInfoDerived = greedyMembr -> splitInfoDerivedCart;
  leftBase  = (NodeBase*) left;
  rightBase = (NodeBase*) right;
  setParent(leftBase, parentBase);
  setParent(rightBase, parentBase);
  setLeftDaughter(leftBase, parentBase);
  setRightDaughter(rightBase, parentBase);
  leftBase -> splitFlag = rightBase -> splitFlag = TRUE;
  parentBase -> splitFlag = FALSE;
  greedyMembr -> leftCart = greedyMembr -> rightCart = NULL;
  greedyMembr -> splitInfoDerivedCart = NULL;
  (*leafCount) ++;
  ((parentBase -> left) -> nodeID) = (parentBase -> nodeID);
  ((parentBase -> left) -> depth) = (parentBase -> depth) + 1;
  ((parentBase -> right) -> nodeID) = *leafCount;
  ((parentBase -> right) -> depth) = (parentBase -> depth) + 1;
  allMembrIndx = parentBase -> allMembrIndx;
  allMembrSize = parentBase -> allMembrSize; 
  uint *leftAllMembrIndx, *rghtAllMembrIndx;
  uint  leftAllMembrSize,  rghtAllMembrSize;
  leftAllMembrSize = rghtAllMembrSize = 0;
  leftBase  -> allMembrIndx = leftAllMembrIndx  = uivector(1, allMembrSize);
  rightBase -> allMembrIndx = rghtAllMembrIndx  = uivector(1, allMembrSize);
  leftBase  -> allMembrSizeAlloc = allMembrSize;
  rightBase -> allMembrSizeAlloc = allMembrSize;
  char *indicator = ((SplitInfoMax *) (parent -> splitInfoDerived)) -> indicator;
  char  polarity;
  parent -> splitInfoDerived -> bsf = (++SG_bsfOrder);
  xArray = augmObjCommon -> xArray;
  for (i = 1; i <= allMembrSize; i++) {
    if (indicator[allMembrIndx[i]] == NEITHER) {
      polarity = getDaughterPolarityNew(treeID, (SplitInfoMax *) (parent -> splitInfoDerived), allMembrIndx[i], xArray);
      if(polarity == LEFT) {
        leftAllMembrIndx[++leftAllMembrSize] = allMembrIndx[i];
        nodeMembership[allMembrIndx[i]] = leftBase;
      }
      else {
        rghtAllMembrIndx[++rghtAllMembrSize] = allMembrIndx[i];
        nodeMembership[allMembrIndx[i]] = rightBase;
      }
      if (polarity == LEFT) {
      }
      else {
      }
    }  
    else {
      if (indicator[allMembrIndx[i]] == LEFT) {
        leftAllMembrIndx[++leftAllMembrSize] = allMembrIndx[i];
        nodeMembership[allMembrIndx[i]] = leftBase;
      }
      else {
        rghtAllMembrIndx[++rghtAllMembrSize] = allMembrIndx[i];
        nodeMembership[allMembrIndx[i]] = rightBase;
      }
    }
  }  
  leftBase  -> allMembrSize = leftAllMembrSize;
  rightBase -> allMembrSize = rghtAllMembrSize;
  if ((leftBase -> repMembrSize == 0) || (rightBase -> repMembrSize == 0)) {
    RF_nativeError("\nRF-SRC:  *** ERROR *** ");
    RF_nativeError("\nRF-SRC:  Left or Right Daughter of size zero:  (%10d, %10d)", leftBase -> repMembrSize, rightBase -> repMembrSize);
    RF_nativeError("\nRF-SRC:  Please Contact Technical Support.");
    RF_nativeExit();
  }
  return TRUE;
}
void saveTree(uint treeID, NodeBase *parent, ulong *offset, ulong *offsetCT, ulong *offsetID_rmbr, ulong *offsetID_imbr, ulong *offsetID_ombr) {
  uint i;
  (*offset) ++;
  parent -> brnodeID = *offset;
  SG_prnodeID_ptr[treeID][*offset] = parent -> pnodeID;
  SG_treeID_ptr[treeID][*offset] = treeID;
  SG_nodeID_ptr[treeID][*offset] = parent -> nodeID;
  SG_nodeSZ_ptr[treeID][*offset] = parent -> repMembrSize;
  if (((Node *) parent) -> splitInfoDerived == NULL) {
    SG_parmID_ptr[treeID][*offset] = 0;
    SG_contPT_ptr[treeID][*offset] = RF_nativeNaN;
    SG_mwcpSZ_ptr[treeID][*offset] = 0;
    SG_fsrecID_ptr[treeID][*offset] = 0;
    SG_nodeStat_ptr[treeID][*offset] = RF_nativeNaN;
    SG_bsf_ptr[treeID][*offset] = 0;
  }
  else {
    SG_parmID_ptr[treeID][*offset] = ((SplitInfoMax *) (((Node *) parent) -> splitInfoDerived)) -> splitParameter;
    SG_mwcpSZ_ptr[treeID][*offset] = ((SplitInfoMax *) (((Node *) parent) -> splitInfoDerived)) -> splitValueFactSize;
    if (SG_mwcpSZ_ptr[treeID][*offset] > 0) {
      SG_fsrecID_ptr[treeID][*offset] = SG_mwcpCT_ptr[treeID] + 1;
      for (i = 1; i <= SG_mwcpSZ_ptr[treeID][*offset]; i++) {
        SG_mwcpCT_ptr[treeID] ++;
        SG_mwcpPT_ptr[treeID][SG_mwcpCT_ptr[treeID]] = ((SplitInfoMax *) (((Node *) parent) -> splitInfoDerived)) -> splitValueFactPtr[i];
      }
      SG_contPT_ptr[treeID][*offset] = RF_nativeNaN;
    }
    else {
      SG_fsrecID_ptr[treeID][*offset] = 0;
      SG_contPT_ptr[treeID][*offset] = ((SplitInfoMax *) (((Node *) parent) -> splitInfoDerived)) -> splitValueCont;
    }
    SG_nodeStat_ptr[treeID][*offset] = ((SplitInfoMax *) (((Node *) parent) -> splitInfoDerived)) -> delta;
    SG_bsf_ptr[treeID][*offset] = ((Node *) parent) -> splitInfoDerived -> bsf;
  }
  SG_node_risk_ptr[treeID][*offset]     = ((Node *) parent) -> eRiskCart;
  SG_node_risk_raw_ptr[treeID][*offset] = ((Node *) parent) -> eRiskRaw;
  if (((parent -> left) != NULL) && ((parent -> right) != NULL)) {
    parent -> left -> pnodeID = *offset;
    parent -> right -> pnodeID = *offset;
    saveTree(treeID, parent ->  left, offset, offsetCT, offsetID_rmbr, offsetID_imbr, offsetID_ombr);
    saveTree(treeID, parent -> right, offset, offsetCT, offsetID_rmbr, offsetID_imbr, offsetID_ombr);
    SG_brnodeID_ptr[treeID][parent -> brnodeID] = (parent -> right) -> brnodeID;
  }
  else {
    SG_brnodeID_ptr[treeID][parent -> brnodeID] = 0;
    RF_tTermList[treeID][parent -> nodeID] = parent -> mate;
  }
}
void restoreTreeLOT(uint treeID, Node *parent, ulong *offsetTree) {
  NodeBase *parentBase;
  SplitInfoMax *info;
  ulong *offset;
  offset = & offsetTree[treeID];
  if (treeID != SG_treeID_[*offset]) {
    RF_nativeError("\nRF-SRC:  Diagnostic Trace of Tree Record:  \n");
    RF_nativeError("\nRF-SRC:      treeID     nodeID ");
    RF_nativeError("\nRF-SRC:  %10d %10d \n", SG_treeID_[*offset], SG_nodeID_[*offset]);
    RF_nativeError("\nRF-SRC:  *** ERROR *** ");
    RF_nativeError("\nRF-SRC:  Invalid forest input record in tree:  %10d", treeID);
    RF_nativeError("\nRF-SRC:  Please Contact Technical Support.");
    RF_nativeExit();
  }
  parentBase = (NodeBase *) parent;
  if (parentBase -> parent != NULL) {
    parentBase -> depth = (parentBase -> parent) -> depth + 1;
  }
  parentBase -> left  = NULL;
  parentBase -> right = NULL;
  parentBase -> splitFlag = FALSE;
  parentBase -> nodeID = SG_nodeID_[*offset];
  parentBase -> repMembrSize = SG_nodeSZ_[*offset];
  AugmentationObjCommon *augmObjCommon = SG_augmObjCommon;
  if (SG_brnodeID_[*offset] != 0) {
    parent -> splitInfoDerived = makeSplitInfoDerived(augmObjCommon);
    info = (SplitInfoMax *) (((Node *) parent) -> splitInfoDerived);
    info -> splitParameter = SG_parmID_[*offset];
    info -> splitValueFactSize = SG_mwcpSZ_[*offset];
    if (info -> splitValueFactSize > 0) {
    }
    else {
      info -> splitValueCont = SG_contPT_[*offset];
    }
  }
  else {
    parent -> splitInfoDerived = NULL;
    RF_leafLinkedObjTail[treeID] = makeAndSpliceLeafLinkedObj(RF_leafLinkedObjTail[treeID]);
    RF_leafLinkedObjTail[treeID] -> nodePtr = parent;
    Terminal *termPtr = makeTerminal();
    TerminalBase *termBasePtr = (TerminalBase *) termPtr;
    RF_leafLinkedObjTail[treeID] -> termPtr = termBasePtr;
    initTerminalBase(termBasePtr,
                     RF_eventTypeSize,
                     RF_masterTimeSize,
                     0,
                     RF_sortedTimeInterestSize,
                     0,      
                     NULL,   
                     0,      
                     NULL,   
                     NULL);  
    parentBase -> mate = termBasePtr;
    termBasePtr -> mate = parentBase;
    RF_leafLinkedObjTail[treeID] -> nodeID = (RF_leafLinkedObjTail[treeID] -> termPtr) -> nodeID = parentBase -> nodeID;
    RF_tTermList[treeID][parentBase -> nodeID] = termBasePtr;
  }
  (*offset) ++;
  if (parent -> splitInfoDerived != NULL) {
    Node *left = makeNode(augmObjCommon -> pSize);
    left  -> nSize = augmObjCommon -> nSize;
    NodeBase *leftBase   = (NodeBase *) left;
    setParent(leftBase, parentBase);
    setLeftDaughter(leftBase, parentBase);
    left -> augm = getAugmentationObjGeneric(SG_augmObjCommon, treeID, left);
    restoreTreeLOT(treeID, left, offsetTree);
    Node *right = makeNode(augmObjCommon -> pSize);
    right -> nSize = augmObjCommon -> nSize;
    NodeBase *rightBase   = (NodeBase *) right;
    setParent(rightBase, parentBase);
    setRightDaughter(rightBase, parentBase);
    right -> augm = getAugmentationObjGeneric(SG_augmObjCommon, treeID, right);
    restoreTreeLOT(treeID, right, offsetTree);
  }
}
void getTestMembershipLOT(uint treeID, Node *parent) {
  NodeBase *parentBase;
  NodeBase *leftBase;
  NodeBase *rightBase;
  Node *left;
  Node *right;
  SplitInfoMax *info;
  double **fxArray;
  char daughterFlag;
  Terminal *termPtr;
  TerminalBase *termBasePtr;
  uint tstMembrSize, leftTestMembrSize, rghtTestMembrSize;
  uint *tstMembrIndx, *leftTestMembrIndx, *rghtTestMembrIndx;
  uint i;
  parentBase = (NodeBase *) parent;
  tstMembrIndx = parent -> tstMembrIndx;
  tstMembrSize = parent -> tstMembrSize;
  leftTestMembrSize = rghtTestMembrSize = 0;
  if (parent -> splitInfoDerived != NULL) {
    leftBase  = parentBase -> left;
    rightBase = parentBase -> right;
    left  = (Node *) leftBase;
    right = (Node *) rightBase;
    left  -> tstMembrIndx = leftTestMembrIndx   = uivector(1, tstMembrSize);
    right -> tstMembrIndx = rghtTestMembrIndx  = uivector(1, tstMembrSize);
    left  -> tstMembrSizeAlloc = tstMembrSize;
    right -> tstMembrSizeAlloc = tstMembrSize;
    AugmentationObjCommon *augmObjCommon =  parent -> augm -> common;
    fxArray = augmObjCommon -> fxArray;
    info = (SplitInfoMax *) (parent -> splitInfoDerived);
    for (i = 1; i <= tstMembrSize; i++) {
      daughterFlag = getDaughterPolarityNew(treeID,
                                            info,
                                            tstMembrIndx[i],
                                            fxArray);
      if (daughterFlag == LEFT) {
        leftTestMembrIndx[++leftTestMembrSize] = tstMembrIndx[i];
      }
      else {
        rghtTestMembrIndx[++rghtTestMembrSize] = tstMembrIndx[i];
      }
    }
    left -> tstMembrSize = leftTestMembrSize;
    right -> tstMembrSize = rghtTestMembrSize;
  }
  else {
    termBasePtr = parentBase -> mate;
    termPtr = (Terminal *) termBasePtr;
    termPtr -> tstMembrCount = parent -> tstMembrSize;
    termPtr -> tstMembrIndx = uivector(1, termPtr -> tstMembrCount);
     for (i = 1; i <= termPtr -> tstMembrCount; i++) {
       termPtr -> tstMembrIndx[i] = parent -> tstMembrIndx[i];
      if (RF_optHigh & OPT_MEMB_USER) {
        SG_MEMB_ID_ptr[treeID][termPtr -> tstMembrIndx[i]] = parentBase -> nodeID;
      }
    }
  }
  if (parent -> splitInfoDerived != NULL) {
    if (leftTestMembrSize > 0) {
      getTestMembershipLOT(treeID, (Node*) (((NodeBase*) parent) -> left));
    }
    if (rghtTestMembrSize > 0) {
      getTestMembershipLOT(treeID, (Node*) (((NodeBase*) parent) -> right));
    }
  }
}
