
// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***
#include           "shared/globalCore.h"
#include           "shared/externalCore.h"
#include           "global.h"
#include           "external.h"

// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***

      
    

#include "survivalTDC.h"
#include "termOps.h"
#include "shared/termBaseOps.h"
#include "shared/nrutil.h"
#include "shared/error.h"
void calculateAllTerminalNodeOutcomesTDC(char mode,
                                         uint treeID,
                                         TerminalBase  *term) {
  Terminal         *termSuper;
  NodeBase         *termMate;
  TerminalSurvival *parent;
  uint  allMembrSize;
  uint *allMembrIndx;
  uint *oobMembrIndx;
  uint *repMembrIndx;
  uint *ibgMembrIndx;
  uint  i;
  termSuper = (Terminal *) term;
  termMate  = term -> mate;
  parent = term -> survivalBase;
  termSuper -> repMembrCount = term -> membrCount = termMate -> repMembrSize;
  allMembrSize = termMate -> allMembrSize;
  allMembrIndx = termMate -> allMembrIndx;
  termSuper -> allMembrSize = allMembrSize;
  termSuper -> oobMembrCount = 0;
  termSuper -> ibgMembrCount = 0;
  termSuper -> oobMembrIndx = uivector(1, allMembrSize);
  termSuper -> repMembrIndx = uivector(1, allMembrSize);
  termSuper -> ibgMembrIndx = uivector(1, allMembrSize);
  oobMembrIndx = termSuper -> oobMembrIndx;
  repMembrIndx = termSuper -> repMembrIndx;
  ibgMembrIndx = termSuper -> ibgMembrIndx;
  for (i = 1; i <= allMembrSize; i++) {
    if (SG_oobMembershipFlagCase[treeID][allMembrIndx[i]]) {
      oobMembrIndx[++ (termSuper -> oobMembrCount)] = allMembrIndx[i];
    }
    else {
      ibgMembrIndx[++ (termSuper -> ibgMembrCount)] = allMembrIndx[i];
    }
  }
  for (i = 1; i <= termSuper -> repMembrCount; i++) {
    repMembrIndx[i] = termMate -> repMembrIndx[i];
  }
  getAtRiskAndEventCount(treeID, parent);
  getLocalRatio(treeID, parent);
  getLocalHazard(treeID, parent);
  getLocalNelsonAalen(treeID, parent);
  getNelsonAalen(treeID, parent);
  getRatio(treeID, parent);
  if ( (SG_optLocal & (SG_OPT_SWTCH_FOUR | SG_OPT_SWTCH_FIVE | SG_OPT_SWTCH_SIX)) != 0) {
    if ((RF_optHigh & OPT_TERM_OUTG) ||
        (RF_opt & OPT_IENS) ||
        (RF_opt & OPT_OENS) ||
        (RF_opt & OPT_FENS)) {
      getCOEObjects(treeID, parent);
    }
  }
  if (!(SG_optLocal & SG_OPT_SWTCH_ZERO)  &&
      !(SG_optLocal & SG_OPT_SWTCH_ONE)   &&
      !(SG_optLocal & SG_OPT_SWTCH_TWO)   &&
      !(SG_optLocal & SG_OPT_SWTCH_THREE)) {  
    getPseudoHazard5(treeID, parent);
  }
  else {
    if (SG_optLocal & SG_OPT_SWTCH_ZERO) {
      getPseudoHazard5(treeID, parent);
      if(SG_optLocal & SG_OPT_SWTCH_TWO) {
        getHeadCorrections(treeID, parent);
      }
      if(SG_optLocal & SG_OPT_SWTCH_THREE) {
        getTailCorrections(treeID, parent);
      }
    }
    else if (SG_optLocal & SG_OPT_SWTCH_ONE) {
      getPseudoHazard2(treeID, parent);
      getNelsonAalenSmooth(treeID, parent);
      if(SG_optLocal & SG_OPT_SWTCH_THREE) {
        getTailCorrections(treeID, parent);
      }
    }
  }
  unstackLocalHazard(parent);
  unstackLocalNelsonAalen(parent);
  unstackLocalRatio(parent);
  unstackAtRiskAndEventCount(parent);
  unstackEventTimeIndex(parent);
}
void getAtRiskAndEventCount(uint treeID, TerminalSurvival *parent) {
  double  *statusPtr;
  uint *membrIndx;
  uint  membrSize;
  uint  mtime;
  uint i, j, k;
  uint ii;
  char eventFlag;
  stackAtRiskAndEventCount(parent);
  for (j = 1; j <= parent -> mTimeSize; j++) {
    (parent -> atRiskCount)[j] = 0;
    for (k = 1; k <= parent -> eTypeSize; k++) {
      (parent -> eventCount)[k][j] = 0;
    }
  }
  membrSize = ((Terminal *) (parent -> base)) -> repMembrCount;
  membrIndx = ((Terminal *) (parent -> base)) -> repMembrIndx;
  statusPtr = ((Node *) (parent -> base -> mate)) -> augm -> common -> yArray[RF_statusIndex];
  for (i = 1; i <= membrSize; i++) {
    ii = membrIndx[i];
    if (TRUE) {
      mtime = RF_masterTimeIndex[treeID][ii];
      if (mtime < 1 || mtime > parent-> mTimeSize) {
        RF_nativeError("\nBAD masterTimeIndex: tree=%u leaf=%u ii=%u mt=%u mTimeSize=%u repMembrSize=%u",
                       treeID,
                       parent -> base -> nodeID,
                       ii,
                       mtime,
                       parent -> mTimeSize,
                       membrSize);
        RF_nativeExit();
      }
    }
    for (j = 1; j <= RF_masterTimeIndex[treeID][ii]; j++) {
      (parent -> atRiskCount)[j] ++;
    }
    if (statusPtr[ii] > 0) {
      if (parent -> eTypeSize > 1) {
        k = RF_eventTypeIndex[(uint) statusPtr[ii]];
      }
      else {
        k = 1;
      }
      (parent -> eventCount)[k][RF_masterTimeIndex[treeID][ii]] ++;
    }
  }
  uint *tempEventTimeIndex = uivector(1, parent -> mTimeSize);
  parent -> eTimeSize = 0;
  i = 0;    
  for (j = 1; j <= parent -> mTimeSize; j++) {
    eventFlag = FALSE;
    for (k = 1; k <= parent -> eTypeSize; k++) {
      if ((parent -> eventCount)[k][j] > 0) {
        eventFlag = TRUE;
        k = parent -> eTypeSize;
      }
    }
    if (eventFlag == TRUE) {
      tempEventTimeIndex[++i] = j;        
      (parent -> eTimeSize)++;
    }
  }
  stackEventTimeIndex(parent);
  for (j = 1; j <= parent -> eTimeSize; j++) {
    (parent -> eventTimeIndex)[j] = tempEventTimeIndex[j];
  }
  free_uivector(tempEventTimeIndex, 1, parent -> mTimeSize);
}
void getLocalRatio(uint treeID, TerminalSurvival *parent) {
  uint q;
  if(parent -> eTimeSize > 0) {
    stackLocalRatio(parent);
    for (q = 1; q <= parent -> eTimeSize; q++) {
      if ((parent -> eventCount)[1][(parent -> eventTimeIndex)[q]] > 0) {
        if ((parent -> atRiskCount)[(parent -> eventTimeIndex)[q]] >= 1) {
          (parent -> localRatio)[1][q] = (double) ((parent -> eventCount)[1][(parent -> eventTimeIndex)[q]]) / (parent -> atRiskCount)[(parent -> eventTimeIndex)[q]];
        }
        else {
          RF_nativeError("\nRF-SRC:  *** ERROR *** ");
          RF_nativeError("\nRF-SRC:  Zero At Risk Count encountered in local ratio calculation for (tree, leaf) = (%10d, %10d)", treeID, parent -> base -> nodeID);
          RF_nativeError("\nRF-SRC:  Please Contact Technical Support.");
          RF_nativeExit();
        }
      }
      else {
        (parent -> localRatio)[1][q] = 0.0;
      }
    }
  }
}
void getLocalHazard(uint treeID, TerminalSurvival *parent) {
  uint q;
  if (parent -> eTimeSize > 0) {
    stackLocalHazard(parent);
    (parent -> localHazard)[1] = (parent -> localRatio)[1][1] / RF_masterTime[(parent -> eventTimeIndex)[1]];
    for (q = 2; q <= parent -> eTimeSize; q++) {
      (parent -> localHazard)[q] = (parent -> localRatio)[1][q] / (RF_masterTime[(parent -> eventTimeIndex)[q]] - RF_masterTime[(parent -> eventTimeIndex)[q-1]]);
    }
  }
}
void getRatio(uint treeID, TerminalSurvival *parent) {
  Terminal *tTerm;
  uint k;
  tTerm = (Terminal *) (parent -> base);
  stackRatio(tTerm);
  for (k = 1; k <= parent -> sTimeSize; k++) {
    (tTerm -> ratio)[k] = 0.0;
  }
  if (parent -> eTimeSize > 0) {  
    mapLocalToTimeInterestRaw(treeID,
                              parent,
                              parent -> localRatio[1],
                              tTerm  -> ratio);
  }
}
void getLocalNelsonAalen(uint treeID, TerminalSurvival *parent) {
  uint q;
  if (parent -> eTimeSize > 0) {
    stackLocalNelsonAalen(parent);
    for (q = 1; q <= parent -> eTimeSize; q++) {
      (parent -> localNelsonAalen)[q] = (parent -> localRatio)[1][q];
    }
    for (q = 2; q <= parent -> eTimeSize; q++) {
      (parent -> localNelsonAalen)[q] += (parent -> localNelsonAalen)[q-1];
    }
  }
}
void getNelsonAalen(uint treeID, TerminalSurvival *parent) {
  uint k;
  stackNelsonAalen(parent);
  for (k = 1; k <= parent -> sTimeSize; k++) {
    (parent -> nelsonAalen)[k] = 0.0;
  }
  mapLocalToTimeInterest(treeID,
                         parent,
                         parent -> localNelsonAalen,
                         parent -> nelsonAalen);
}
void getHazard(uint treeID, TerminalSurvival *parent) {
  uint k;
  stackHazard(parent);
  for (k = 1; k <= parent -> sTimeSize; k++) {
    parent -> hazard[k] = 0.0;
  }
  if (parent -> eTimeSize > 0) {  
    mapLocalToTimeInterestRaw(treeID,
                              parent,
                              parent -> localHazard,
                              parent -> hazard);
  }
}
void getPseudoHazard2(uint treeID, TerminalSurvival *parent) {
  double stepValue;
  uint lookBackIndex;
  uint j, k, l;
  stackHazard(parent);
  if (parent -> eTimeSize > 0) {
    for (k = 1; k <= parent -> sTimeSize; k++) {
      (parent -> hazard)[k] = 0.0;
    }
    j = 0;
    for (k = 1; k <= parent -> sTimeSize; k++) {
      if (parent -> nelsonAalen[k] <= EPSILON2) {
      }
      else {
        j = k;
        break;
      }
    }
    if (j != 0) {
      parent -> hazard[j] = parent -> nelsonAalen[j] / RF_timeInterest[j];
      for (k = 1; k < j; k++) {
        parent -> hazard[k] = parent -> hazard[j];
      }
      lookBackIndex = j;
      for (k = j+1; k <= parent -> sTimeSize; k++) {
        stepValue = (parent -> nelsonAalen[k] - parent -> nelsonAalen[k-1]);
        if (stepValue > EPSILON2) {
          parent -> hazard[k] = stepValue / (RF_timeInterest[k] - RF_timeInterest[lookBackIndex]);
          for (l = lookBackIndex + 1; l < k; l++) {
            parent -> hazard[l] = parent -> hazard[k];
          }
          lookBackIndex = k;
        }
        else {
        }
      }
    }
  }
}
void getPseudoHazard5(uint treeID, TerminalSurvival *parent) {
  double stepValue;
  uint j, k;
  stackHazard(parent);
  if (parent -> eTimeSize > 0) {
    for (k = 1; k <= parent -> sTimeSize; k++) {
      (parent -> hazard)[k] = 0.0;
    }
    j = 0;
    for (k = 1; k <= parent -> sTimeSize; k++) {
      if (parent -> nelsonAalen[k] <= EPSILON2) {
      }
      else {
        j = k;
        break;
      }
    }
    if (j != 0) {
      parent -> hazard[j] = parent -> nelsonAalen[j] / RF_timeInterest[j];
      for (k = j+1; k <= parent -> sTimeSize; k++) {
        stepValue = (parent -> nelsonAalen[k] - parent -> nelsonAalen[k-1]);
        if (stepValue > EPSILON2) {
          parent -> hazard[k] = stepValue / SG_timeInterestDelta[k];
        }
        else {
          parent -> hazard[k] = 0.0;
        }
      }
    }
  }
}
static uint firstNodeTimeInterestGreater(double value) {
  int low, high, mid, result;
  low = 1;
  high = (int) RF_sortedTimeInterestSize;
  result = high + 1;
  while (low <= high) {
    mid = low + ((high - low) >> 1);
    if (RF_timeInterest[mid] > value) {
      result = mid;
      high = mid - 1;
    }
    else {
      low = mid + 1;
    }
  }
  return (uint) result;
}
static uint firstNodeTimeInterestGreaterOrEqual(double value) {
  int low, high, mid, result;
  low = 1;
  high = (int) RF_sortedTimeInterestSize;
  result = high + 1;
  while (low <= high) {
    mid = low + ((high - low) >> 1);
    if (RF_timeInterest[mid] >= value) {
      result = mid;
      high = mid - 1;
    }
    else {
      low = mid + 1;
    }
  }
  return (uint) result;
}
void getCOEObjects(uint treeID, TerminalSurvival *parent) {
  Terminal *tTerm;
  double *fullIntervalDiff;
  double fullIntervalCount;
  double left, right;
  double intervalLeft, intervalRight;
  double overlapLeft, overlapRight;
  double cumulativeCOE;
  uint memberID;
  uint caseID;
  uint firstIndex;
  uint lastIndex;
  uint eventIndex;
  uint timeIndex;
  uint k;
  tTerm = (Terminal *) (parent -> base);
  stackCOEObjects(tTerm);
  for (k = 1; k <= parent -> sTimeSize; k++) {
    (tTerm -> nodeU)[k] = 0.0;
    (tTerm -> nodeV)[k] = 0.0;
    (tTerm -> coeHazard)[k] = RF_nativeNaN;
    (tTerm -> coeCHF)[k] = 0.0;
  }
  fullIntervalDiff = dvector(1, parent -> sTimeSize + 1);
  for (timeIndex = 1; timeIndex <= parent -> sTimeSize + 1; timeIndex++) {
    fullIntervalDiff[timeIndex] = 0.0;
  }
  for (memberID = 1; memberID <= tTerm -> repMembrCount; memberID++) {
    caseID = tTerm -> repMembrIndx[memberID];
    left = RF_responseIn[RF_startTimeIndex][caseID];
    right = RF_responseIn[RF_timeIndex][caseID];
    if (!(right > left)) {
      continue;
    }
    firstIndex = firstNodeTimeInterestGreater(left);
    if (firstIndex <= parent -> sTimeSize) {
      lastIndex = firstNodeTimeInterestGreaterOrEqual(right);
      if (lastIndex > parent -> sTimeSize) {
        lastIndex = parent -> sTimeSize;
      }
      if (lastIndex >= firstIndex) {
        intervalLeft = (firstIndex > 1) ? RF_timeInterest[firstIndex - 1] : 0.0;
        if (firstIndex == lastIndex) {
          intervalRight = RF_timeInterest[firstIndex];
          overlapLeft = (left > intervalLeft) ? left : intervalLeft;
          overlapRight = (right < intervalRight) ? right : intervalRight;
          if (overlapRight > overlapLeft) {
            tTerm -> nodeU[firstIndex] += overlapRight - overlapLeft;
          }
        }
        else {
          intervalRight = RF_timeInterest[firstIndex];
          overlapLeft = (left > intervalLeft) ? left : intervalLeft;
          if (intervalRight > overlapLeft) {
            tTerm -> nodeU[firstIndex] += intervalRight - overlapLeft;
          }
          intervalLeft = (lastIndex > 1) ? RF_timeInterest[lastIndex - 1] : 0.0;
          intervalRight = RF_timeInterest[lastIndex];
          overlapRight = (right < intervalRight) ? right : intervalRight;
          if (overlapRight > intervalLeft) {
            tTerm -> nodeU[lastIndex] += overlapRight - intervalLeft;
          }
          fullIntervalDiff[firstIndex + 1] += 1.0;
          fullIntervalDiff[lastIndex] -= 1.0;
        }
      }
    }
    if (RF_responseIn[RF_statusIndex][caseID] > 0) {
      eventIndex = firstNodeTimeInterestGreaterOrEqual(right);
      if (eventIndex <= parent -> sTimeSize) {
        intervalLeft = (eventIndex > 1) ? RF_timeInterest[eventIndex - 1] : 0.0;
        if ((intervalLeft < right) && (right <= RF_timeInterest[eventIndex])) {
          tTerm -> nodeV[eventIndex] += 1.0;
        }
      }
    }
  }        
  fullIntervalCount = 0.0;
  for (timeIndex = 1; timeIndex <= parent -> sTimeSize; timeIndex++) {
    fullIntervalCount += fullIntervalDiff[timeIndex];
    if (fullIntervalCount > 0.0) {
      intervalLeft = (timeIndex > 1) ? RF_timeInterest[timeIndex - 1] : 0.0;
      intervalRight = RF_timeInterest[timeIndex];
      tTerm -> nodeU[timeIndex] += fullIntervalCount * (intervalRight - intervalLeft);
    }
  }
  cumulativeCOE = 0.0;
  for (timeIndex = 1; timeIndex <= parent -> sTimeSize; timeIndex++) {
    if (tTerm -> nodeU[timeIndex] > 0.0) {
      tTerm -> coeHazard[timeIndex] =
        tTerm -> nodeV[timeIndex] / tTerm -> nodeU[timeIndex];
      intervalLeft = (timeIndex > 1) ? RF_timeInterest[timeIndex - 1] : 0.0;
      intervalRight = RF_timeInterest[timeIndex];
      cumulativeCOE += (intervalRight - intervalLeft) * tTerm -> coeHazard[timeIndex];
    }
    else {
      if (tTerm -> nodeV[timeIndex] > 0.0) {
        RF_nativeError("\nRF-SRC:  *** ERROR *** ");
        RF_nativeError("\nRF-SRC:  COE node-time cell has zero exposure and positive event count.");
        RF_nativeError("\nRF-SRC:  tree=%10d terminal=%10d timeIndex=%10d U=%12.6f V=%12.6f",
                       treeID,
                       parent -> base -> nodeID,
                       timeIndex,
                       tTerm -> nodeU[timeIndex],
                       tTerm -> nodeV[timeIndex]);
        RF_nativeExit();
      }
      tTerm -> coeHazard[timeIndex] = RF_nativeNaN;
    }
    tTerm -> coeCHF[timeIndex] = cumulativeCOE;
  }
  free_dvector(fullIntervalDiff, 1, parent -> sTimeSize + 1);
}
void getHeadCorrections(uint treeID, TerminalSurvival *parent) {
  uint j, k;
  if (parent -> eTimeSize > 0) {
    j = 0;
    for (k = 1; k <= parent -> sTimeSize; k++) {
      if (parent -> nelsonAalen[k] <= EPSILON2) {
      }
      else {
        j = k;
        break;
      }
    }
    if (j != 0) {
      parent -> hazard[j] = parent -> nelsonAalen[j] / RF_timeInterest[j];
      for (k = 1; k < j; k++) {
        parent -> hazard[k] = parent -> hazard[j];
      }
      parent -> nelsonAalen[1] = parent -> hazard[1] * RF_timeInterest[1];
      for (k = 2; k < j; k++) {
        parent -> nelsonAalen[k] = parent -> nelsonAalen[k-1] + (parent -> hazard[k] * (RF_timeInterest[k] - RF_timeInterest[k-1]));
      }
    }
  }
}
void getTailCorrections(uint treeID, TerminalSurvival *parent) {
  double stepValue;
  double stepHazard;
  uint j, k;
  stepHazard = 0;  
  if (parent -> eTimeSize > 0) {
    if ( ( RF_masterTime[parent -> eventTimeIndex[parent -> eTimeSize]] - RF_timeInterest[parent -> sTimeSize]) > EPSILON2) {
      for (k = parent -> sTimeSize; k >= 1; k--) {
        if ((parent -> nelsonAalen[parent -> sTimeSize] - parent -> nelsonAalen[k]) > EPSILON2) {
          if (k == parent -> sTimeSize - 1) {
          }
          else {
            break;
          }
        }
      }
      stepValue = parent -> localNelsonAalen[parent -> eTimeSize] - parent -> nelsonAalen[k];
      if (stepValue > EPSILON2) {
        stepHazard = stepValue / (RF_timeInterest[parent -> sTimeSize] - RF_timeInterest[k]);
      }
      else {
        RF_nativeError("\nRF-SRC:  *** ERROR *** ");
        RF_nativeError("\nRF-SRC:  Zero step value encountered in tail of Nelson-Aaalen for (tree, leaf) = (%10d, %10d)", treeID, parent -> base -> nodeID);
        RF_nativeError("\nRF-SRC:  Please Contact Technical Support.");
        RF_nativeExit();
      }
      if (parent -> sTimeSize == 1) {
        RF_nativeError("\nRF-SRC:  *** ERROR *** ");
        RF_nativeError("\nRF-SRC:  Single grid value encountered for time interest vector in tail of Nelson-Aaalen for (tree, leaf) = (%10d, %10d)", treeID, parent -> base -> nodeID);
        RF_nativeError("\nRF-SRC:  Degeneracy not yet supported.");
        RF_nativeError("\nRF-SRC:  Please Contact Technical Support.");
        RF_nativeExit();
      }
      for (j = k + 1; j <= parent -> sTimeSize; j++) {
        parent -> hazard[j] = stepHazard;
        parent -> nelsonAalen[j] = parent -> nelsonAalen[j-1] + (parent -> hazard[j] * (RF_timeInterest[j] - RF_timeInterest[j-1]));
      }
    }
  }
}
void getNelsonAalenSmooth(uint treeID, TerminalSurvival *parent) {
  uint k;
  if (parent -> eTimeSize > 0) {
    parent -> nelsonAalen[1] = parent -> hazard[1] * RF_timeInterest[1];
    for (k = 2; k <= parent -> sTimeSize; k++) {
      parent -> nelsonAalen[k] = parent -> nelsonAalen[k-1] + (parent -> hazard[k] * SG_timeInterestDelta[k]);
    }
  }
}
void mapLocalToTimeInterest(uint              treeID,
                            TerminalSurvival *parent,
                            double   *genericLocal,
                            double   *genericGlobal) {
  uint itIndex, etIndex, lookAheadIndex;
  char mapFlag, transitFlag;
  if ((parent -> eTimeSize) > 0) {
    itIndex = 1;
    etIndex = 1;
    mapFlag = TRUE;
    while(mapFlag) {
      if ((RF_masterTime[(parent -> eventTimeIndex)[etIndex]] - RF_timeInterest[itIndex]) > EPSILON2) {
        if (itIndex > 1) {
          genericGlobal[itIndex] = genericGlobal[itIndex-1];
        }
        itIndex++;
      }
      else {
        lookAheadIndex = etIndex;
        transitFlag = TRUE;
        while (transitFlag) {
          if ((RF_timeInterest[itIndex] - RF_masterTime[(parent -> eventTimeIndex)[lookAheadIndex]] ) > -EPSILON2) {
            genericGlobal[itIndex] = genericLocal[lookAheadIndex];
            lookAheadIndex++;
            if (lookAheadIndex > (parent -> eTimeSize)) {
              transitFlag = FALSE;
            }
          }
          else {
            transitFlag = FALSE;
          }
        }
        itIndex++;
        etIndex = lookAheadIndex;
      }
      if(etIndex > (parent -> eTimeSize)) {
        while(itIndex <= parent -> sTimeSize) {
          genericGlobal[itIndex] = genericGlobal[itIndex-1];
          itIndex++;
        }
      }
      if(itIndex > parent -> sTimeSize) {
        mapFlag = FALSE;
      }
    }
  }
}
void mapLocalToTimeInterestRaw(uint              treeID,
                               TerminalSurvival *parent,
                               double   *genericLocal,
                               double   *genericGlobal) {
  uint itIndex, etIndex;
  char mapFlag;
  if ((parent -> eTimeSize) > 0) {
    itIndex = 1;
    etIndex = 1;
    mapFlag = TRUE;
    while(mapFlag) {
      if ((RF_masterTime[(parent -> eventTimeIndex)[etIndex]] - RF_timeInterest[itIndex]) > EPSILON2) {
        itIndex++;
      }
      else {
        genericGlobal[itIndex] = genericLocal[etIndex];
        etIndex ++;
      }
      if((etIndex > parent -> eTimeSize) || (itIndex > parent -> sTimeSize)) {
        mapFlag = FALSE;
      }
    }
  }
}
void getVectorDelta(uint size, double *inValue, double *outValue) {
  uint i;
  outValue[1] = inValue[1];
  for (i = 2; i <= size; i++) {
    outValue[i] = inValue[i] - inValue[i-1];
  }
}
void assignAllTerminalNodeOutcomesTDC(char mode,
                                      uint treeID,
                                      TerminalBase  *term) {
  TerminalSurvival *parent;
  parent = term -> survivalBase;
  getAtRiskAndEventCount(treeID, parent);
  getLocalRatio(treeID, parent);
  getLocalHazard(treeID, parent);
  getLocalNelsonAalen(treeID, parent);
  getNelsonAalen(treeID, parent);
  getRatio(treeID, parent);
  if ( (SG_optLocal & (SG_OPT_SWTCH_FOUR | SG_OPT_SWTCH_FIVE | SG_OPT_SWTCH_SIX)) != 0) {
    if ((RF_optHigh & OPT_TERM_OUTG) ||
        (RF_opt & OPT_IENS) ||
        (RF_opt & OPT_OENS) ||
        (RF_opt & OPT_FENS)) {
      getCOEObjects(treeID, parent);
    }
  }
  if (!(SG_optLocal & SG_OPT_SWTCH_ZERO)  &&
      !(SG_optLocal & SG_OPT_SWTCH_ONE)   &&
      !(SG_optLocal & SG_OPT_SWTCH_TWO)   &&
      !(SG_optLocal & SG_OPT_SWTCH_THREE)) {
    getPseudoHazard5(treeID, parent);
  }
  else {
    if (SG_optLocal & SG_OPT_SWTCH_ZERO) {
      getPseudoHazard5(treeID, parent);
      if(SG_optLocal & SG_OPT_SWTCH_TWO) {
        getHeadCorrections(treeID, parent);
      }
      if(SG_optLocal & SG_OPT_SWTCH_THREE) {
        getTailCorrections(treeID, parent);
      }
    }
    else if (SG_optLocal & SG_OPT_SWTCH_ONE) {
      getPseudoHazard2(treeID, parent);
      getNelsonAalenSmooth(treeID, parent);
      if(SG_optLocal & SG_OPT_SWTCH_THREE) {
        getTailCorrections(treeID, parent);
      }
    }
  }
  unstackLocalHazard(parent);
  unstackLocalNelsonAalen(parent);
  unstackLocalRatio(parent);
  unstackAtRiskAndEventCount(parent);
  unstackEventTimeIndex(parent);
}
