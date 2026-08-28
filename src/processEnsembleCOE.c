
// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***
#include           "shared/globalCore.h"
#include           "shared/externalCore.h"
#include           "global.h"
#include           "external.h"

// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***

      
    

#include "processEnsembleCOE.h"
#include "terminal.h"
#include "shared/nrutil.h"
#include "shared/error.h"
#define SG_COE_AGG_MEDIAN 0x01
#define SG_COE_AGG_WINSOR 0x02
#define SG_COE_AGG_MEAN   0x03
static char coeGetAggregateType(uint trimIndex) {
  char aggregateType;
  aggregateType = 0;
  if (SG_optLocal & SG_OPT_SWTCH_FOUR) {
    aggregateType = SG_COE_AGG_MEDIAN;
  }
  else if (SG_optLocal & SG_OPT_SWTCH_FIVE) {
    if (trimIndex == SG_COE_TRIM_INDEX_MEDIAN_FALLBACK) {
      aggregateType = SG_COE_AGG_MEDIAN;
    }
    else {
      aggregateType = SG_COE_AGG_WINSOR;
    }
  }
  else if (SG_optLocal & SG_OPT_SWTCH_SIX) {
    aggregateType = SG_COE_AGG_MEAN;
  }
  else {
    RF_nativeError("\nRF-SRC:  *** ERROR *** ");
    RF_nativeError("\nRF-SRC:  COE ensemble aggregate type undefined:  %10d", aggregateType);
    RF_nativeExit();
  }
  return aggregateType;
}
uint firstTimeInterestGreater(double value) {
  int low, high, mid, result;
  low = 1;
  high = (int) RF_sortedTimeInterestSize;
  result = high + 1;
  while (low <= high) {
    mid = low + ((high - low) >> 1);
    if ((RF_timeInterest[mid] - value) > EPSILON2) {
      result = mid;
      high = mid - 1;
    }
    else {
      low = mid + 1;
    }
  }
  return (uint) result;
}
uint firstTimeInterestGreaterOrEqual(double value) {
  int low, high, mid, result;
  low = 1;
  high = (int) RF_sortedTimeInterestSize;
  result = high + 1;
  while (low <= high) {
    mid = low + ((high - low) >> 1);
    if ((RF_timeInterest[mid] - value) >= -EPSILON2) {
      result = mid;
      high = mid - 1;
    }
    else {
      low = mid + 1;
    }
  }
  return (uint) result;
}
static int coeCompareDoubles(const void *a, const void *b) {
  double x = *((const double *) a);
  double y = *((const double *) b);
  if (x < y) {
    return -1;
  }
  else if (x > y) {
    return 1;
  }
  else {
    return 0;
  }
}
static double coeMeanValues(double *value, uint count) {
  double sum;
  uint i;
  if (count == 0) {
    return RF_nativeNaN;
  }
  sum = 0.0;
  for (i = 1; i <= count; i++) {
    sum += value[i];
  }
  return sum / ((double) count);
}
static double coeMedianSorted(double *value, uint count) {
  uint mid;
  if (count == 0) {
    return RF_nativeNaN;
  }
  mid = count / 2;
  if ((count % 2) == 1) {
    return value[mid + 1];
  }
  else {
    return 0.5 * (value[mid] + value[mid + 1]);
  }
}
static double coeQuantileType8Sorted(double *value, uint count, double probability) {
  double h;
  double gamma;
  uint j;
  if (count == 0) {
    return RF_nativeNaN;
  }
  if (probability <= 0.0) {
    return value[1];
  }
  if (probability >= 1.0) {
    return value[count];
  }
  h = (((double) count) + (1.0 / 3.0)) * probability + (1.0 / 3.0);
  if (h <= 1.0) {
    return value[1];
  }
  if (h >= ((double) count)) {
    return value[count];
  }
  j = (uint) floor(h);
  gamma = h - ((double) j);
  return (1.0 - gamma) * value[j] + gamma * value[j + 1];
}
static double coeWinsorizedMeanValues(double *value, uint count, uint trimIndex) {
  double lower;
  double upper;
  double clipped;
  double sum;
  double trim;
  uint i;
  if (count == 0) {
    return RF_nativeNaN;
  }
  trim = SG_coeTrim[trimIndex];
  if (trim <= 0.0) {
    return coeMeanValues(value, count);
  }
  if (trim > 0.5) {
    trim = 0.5;
  }
  qsort(value + 1, count, sizeof(double), coeCompareDoubles);
  lower = coeQuantileType8Sorted(value, count, trim);
  upper = coeQuantileType8Sorted(value, count, 1.0 - trim);
  sum = 0.0;
  for (i = 1; i <= count; i++) {
    clipped = value[i];
    if (clipped < lower) {
      clipped = lower;
    }
    else if (clipped > upper) {
      clipped = upper;
    }
    sum += clipped;
  }
  return sum / ((double) count);
}
static void coeWinsorizedMeanAllTrimSorted(double *value,
                                           uint count,
                                           double zeroTrimMean,
                                           double *aggregate) {
  double lower;
  double upper;
  double clipped;
  double sum;
  double trim;
  uint i;
  uint trimIndex;
  if (count == 0) {
    for (trimIndex = 1; trimIndex <= SG_coeTrimSize; trimIndex++) {
      aggregate[trimIndex] = RF_nativeNaN;
    }
    return;
  }
  for (trimIndex = 1; trimIndex <= SG_coeTrimSize; trimIndex++) {
    trim = SG_coeTrim[trimIndex];
    if (trim <= 0.0) {
      aggregate[trimIndex] = zeroTrimMean;
      continue;
    }
    if (trim > 0.5) {
      trim = 0.5;
    }
    lower = coeQuantileType8Sorted(value, count, trim);
    upper = coeQuantileType8Sorted(value, count, 1.0 - trim);
    sum = 0.0;
    for (i = 1; i <= count; i++) {
      clipped = value[i];
      if (clipped < lower) {
        clipped = lower;
      }
      else if (clipped > upper) {
        clipped = upper;
      }
      sum += clipped;
    }
    aggregate[trimIndex] = sum / ((double) count);
  }
}
static double coeAggregateValues(double *value, uint count, char aggregateType, uint trimIndex) {
  if (count == 0) {
    return RF_nativeNaN;
  }
  switch (aggregateType) {
  case SG_COE_AGG_MEDIAN:
    qsort(value + 1, count, sizeof(double), coeCompareDoubles);
    return coeMedianSorted(value, count);
  case SG_COE_AGG_WINSOR:
    return coeWinsorizedMeanValues(value, count, trimIndex);
  case SG_COE_AGG_MEAN:
    return coeMeanValues(value, count);
  default:
    return RF_nativeNaN;
  }
}
static uint getCOEOOBSubjectTreeIndex(uint subjIndex, uint *treeIndex) {
  double marker;
  uint b;
  uint treeID;
  uint count;
  count = 0;
  for (b = 1; b <= RF_getTreeCount; b++) {
    treeID = RF_getTreeIndex[b];
    marker =
      SG_coeCHFTreeOOB_ptr[treeID][RF_sortedTimeInterestSize][subjIndex];
    if (!RF_nativeIsNaN(marker)) {
      treeIndex[++count] = treeID;
    }
  }
  return count;
}
static uint coeCollectOOBCaseHazardValues(uint caseID,
                                          uint subjIndex,
                                          uint timeIndex,
                                          uint *treeIndex,
                                          uint treeCount,
                                          double *value) {
  Terminal *tTerm;
  double localValue;
  uint b;
  uint treeID;
  uint count;
  count = 0;
  for (b = 1; b <= treeCount; b++) {
    treeID = treeIndex[b];
    tTerm = (Terminal *) RF_tTermMembership[treeID][caseID];
    if (tTerm == NULL) {
      RF_nativeError("\nRF-SRC:  *** ERROR *** ");
      RF_nativeError("\nRF-SRC:  Missing row-specific terminal membership while calculating OOB COE risk.");
      RF_nativeError("\nRF-SRC:  tree=%10d case=%10d subject=%10d timeIndex=%10d",
                     treeID,
                     caseID,
                     subjIndex,
                     timeIndex);
      RF_nativeExit();
    }
    localValue = tTerm -> coeHazard[timeIndex];
    if ((!RF_nativeIsNaN(localValue)) && isfinite(localValue)) {
      value[++count] = localValue;
    }
  }
  return count;
}
static double getCOEOOBCaseHazardAggregate(uint caseID,
                                           uint subjIndex,
                                           uint timeIndex,
                                           uint *treeIndex,
                                           uint treeCount,
                                           double *value,
                                           uint trimIndex) {
  char aggregateType;
  uint count;
  aggregateType = coeGetAggregateType(trimIndex);
  count = coeCollectOOBCaseHazardValues(caseID,
                                        subjIndex,
                                        timeIndex,
                                        treeIndex,
                                        treeCount,
                                        value);
  return coeAggregateValues(value, count, aggregateType, trimIndex);
}
static void getCOEOOBCaseHazardAggregateAllTrim(uint caseID,
                                                uint subjIndex,
                                                uint timeIndex,
                                                uint *treeIndex,
                                                uint treeCount,
                                                double *value,
                                                double *aggregate) {
  double zeroTrimMean;
  char aggregateType;
  uint count;
  uint trimIndex;
  aggregateType = coeGetAggregateType(1);
  if (aggregateType != SG_COE_AGG_WINSOR) {
    RF_nativeError("\nRF-SRC:  *** ERROR *** ");
    RF_nativeError("\nRF-SRC:  Batched coe.trim evaluation requires winsorized-mean aggregation.");
    RF_nativeExit();
  }
  count = coeCollectOOBCaseHazardValues(caseID,
                                        subjIndex,
                                        timeIndex,
                                        treeIndex,
                                        treeCount,
                                        value);
  if (count == 0) {
    for (trimIndex = 1; trimIndex <= SG_coeTrimSize; trimIndex++) {
      aggregate[trimIndex] = RF_nativeNaN;
    }
    return;
  }
  zeroTrimMean = coeMeanValues(value, count);
  qsort(value + 1, count, sizeof(double), coeCompareDoubles);
  coeWinsorizedMeanAllTrimSorted(value,
                                 count,
                                 zeroTrimMean,
                                 aggregate);
}
void updateCOEObjectsGrow(char mode, uint treeID) {
  LeafLinkedObj *leafLinkedPtr;
  uint subj, subjIndex;
  uint i, ii, jj;
  uint timeIndex;
  Terminal     *tTerm;
  TerminalBase *tTermBase;
  if (!((mode == RF_GROW) || (mode == RF_REST))) {
    return;
  }
  if (!((RF_opt & OPT_IENS) ||
        (RF_opt & OPT_FENS) ||
        (RF_opt & OPT_OENS))) {
    return;
  }
  leafLinkedPtr = RF_leafLinkedObjHead[treeID] -> fwdLink;
  while (leafLinkedPtr != NULL) {
    tTermBase = leafLinkedPtr -> termPtr;
    tTerm = (Terminal *) tTermBase;
    if ((tTerm -> coeHazard == NULL) || (tTerm -> coeCHF == NULL)) {
      RF_nativeError("\nRF-SRC:  *** ERROR *** ");
      RF_nativeError("\nRF-SRC:  COE terminal-node curves were not initialized before stitching.");
      RF_nativeError("\nRF-SRC:  tree=%10d terminal=%10d", treeID, tTermBase -> nodeID);
      RF_nativeExit();
    }
    if ((RF_opt & OPT_IENS) || (RF_opt & OPT_FENS)) {
      for (i = 1; i <= tTerm -> ibgMembrCount; i++) {
        ii = tTerm -> ibgMembrIndx[i];
        subj = RF_subjIn[ii];
        subjIndex = RF_subjMap[subj];
        for (jj = 1; jj <= SG_timeInterestIntervalCount[ii]; jj++) {
          timeIndex = SG_timeInterestIntervalIndex[ii][jj];
          SG_coeHazardTreeIBG_ptr[treeID][timeIndex][subjIndex] = tTerm -> coeHazard[timeIndex];
          SG_coeCHFTreeIBG_ptr[treeID][timeIndex][subjIndex]    = tTerm -> coeCHF[timeIndex];
        }
      }
    }
    if (RF_opt & OPT_OENS) {
      for (i = 1; i <= tTerm -> oobMembrCount; i++) {
        ii = tTerm -> oobMembrIndx[i];
        subj = RF_subjIn[ii];
        subjIndex = RF_subjMap[subj];
        for (jj = 1; jj <= SG_timeInterestIntervalCount[ii]; jj++) {
          timeIndex = SG_timeInterestIntervalIndex[ii][jj];
          SG_coeHazardTreeOOB_ptr[treeID][timeIndex][subjIndex] = tTerm -> coeHazard[timeIndex];
          SG_coeCHFTreeOOB_ptr[treeID][timeIndex][subjIndex]    = tTerm -> coeCHF[timeIndex];
        }
      }
    }
    leafLinkedPtr = leafLinkedPtr -> fwdLink;
  }
}
void updateCOEObjectsPred(char mode, uint treeID) {
  LeafLinkedObj *leafLinkedPtr;
  uint subj, subjIndex;
  uint i, ii, jj;
  uint timeIndex;
  Terminal     *tTerm;
  TerminalBase *tTermBase;
  if (mode != RF_PRED) {
    return;
  }
  if (!(RF_opt & OPT_FENS)) {
    return;
  }
  leafLinkedPtr = RF_leafLinkedObjHead[treeID] -> fwdLink;
  while (leafLinkedPtr != NULL) {
    tTermBase = leafLinkedPtr -> termPtr;
    tTerm = (Terminal *) tTermBase;
    if ((tTerm -> coeHazard == NULL) || (tTerm -> coeCHF == NULL)) {
      RF_nativeError("\nRF-SRC:  *** ERROR *** ");
      RF_nativeError("\nRF-SRC:  COE terminal-node curves were not initialized before prediction stitching.");
      RF_nativeError("\nRF-SRC:  tree=%10d terminal=%10d", treeID, tTermBase -> nodeID);
      RF_nativeExit();
    }
    for (i = 1; i <= tTerm -> tstMembrCount; i++) {
      ii = tTerm -> tstMembrIndx[i];
      subj = SG_fsubjIn[ii];
      subjIndex = SG_fsubjMap[subj];
      for (jj = 1; jj <= SG_ftimeInterestIntervalCount[ii]; jj++) {
        timeIndex = SG_ftimeInterestIntervalIndex[ii][jj];
        SG_coeHazardTreeIBG_ptr[treeID][timeIndex][subjIndex] = tTerm -> coeHazard[timeIndex];
        SG_coeCHFTreeIBG_ptr[treeID][timeIndex][subjIndex]    = tTerm -> coeCHF[timeIndex];
      }
    }
    leafLinkedPtr = leafLinkedPtr -> fwdLink;
  }
}
static double coeOOBRiskObjectiveFromVector(double *riskVector,
                                            uint riskCount,
                                            uint *subjectCount) {
  double risk;
  double sum;
  double compensation;
  double adjusted;
  double updated;
  char positiveInfinity;
  char negativeInfinity;
  uint i;
  uint count;
  sum = 0.0;
  compensation = 0.0;
  positiveInfinity = FALSE;
  negativeInfinity = FALSE;
  count = 0;
  for (i = 1; i <= riskCount; i++) {
    risk = riskVector[i];
    if (isnan(risk)) {
      continue;
    }
    count++;
    if (isinf(risk)) {
      if (risk > 0.0) {
        positiveInfinity = TRUE;
      }
      else {
        negativeInfinity = TRUE;
      }
      continue;
    }
    adjusted = risk - compensation;
    updated = sum + adjusted;
    compensation = (updated - sum) - adjusted;
    sum = updated;
  }
  if (subjectCount != NULL) {
    *subjectCount = count;
  }
  if (count == 0) {
    return RF_nativeNaN;
  }
  if (positiveInfinity && negativeInfinity) {
    return RF_nativeNaN;
  }
  if (negativeInfinity) {
    return -INFINITY;
  }
  if (positiveInfinity) {
    return INFINITY;
  }
  return sum / ((double) count);
}
double getCOEOOBRiskObjective(uint *subjectCount) {
  return coeOOBRiskObjectiveFromVector(SG_oobRisk_,
                                       RF_subjCount,
                                       subjectCount);
}
double getCOEOOBRiskObjectiveForTrim(uint trimIndex,
                                     uint *subjectCount) {
  double objective;
  double *subjectRisk;
  double *treeValue;
  uint *oobTreeIndex;
  uint subjIndex;
  subjectRisk = dvector(1, RF_subjCount);
  treeValue = dvector(1, RF_getTreeCount);
  oobTreeIndex = uivector(1, RF_getTreeCount);
  for (subjIndex = 1; subjIndex <= RF_subjCount; subjIndex++) {
    subjectRisk[subjIndex] =
      getCOEOOBSubjectRiskExactOverlap(subjIndex,
                                       trimIndex,
                                       oobTreeIndex,
                                       treeValue);
  }
  objective = coeOOBRiskObjectiveFromVector(subjectRisk,
                                            RF_subjCount,
                                            subjectCount);
  free_uivector(oobTreeIndex, 1, RF_getTreeCount);
  free_dvector(treeValue, 1, RF_getTreeCount);
  free_dvector(subjectRisk, 1, RF_subjCount);
  return objective;
}
static void getCOEOOBCaseRiskExactOverlapAllTrim(uint    caseID,
                                                 uint    subjIndex,
                                                 double  left,
                                                 double  right,
                                                 char    eventFlag,
                                                 uint   *oobTreeIndex,
                                                 uint    oobTreeCount,
                                                 double *treeValue,
                                                 double *cellAggregate,
                                                 double *caseExposureRisk,
                                                 double *caseEventRisk) {
  double gridLeft;
  double gridRight;
  double overlapLeft;
  double overlapRight;
  double overlap;
  uint idx1;
  uint idx2;
  uint k;
  uint eventTimeIndex;
  uint trimIndex;
  for (trimIndex = 1; trimIndex <= SG_coeTrimSize; trimIndex++) {
    caseExposureRisk[trimIndex] = 0.0;
    caseEventRisk[trimIndex] = 0.0;
  }
  if (!(left < right)) {
    return;
  }
  idx1 = firstTimeInterestGreater(left);
  if (idx1 > RF_sortedTimeInterestSize) {
    return;
  }
  idx2 = firstTimeInterestGreaterOrEqual(right);
  if (idx2 > RF_sortedTimeInterestSize) {
    idx2 = RF_sortedTimeInterestSize;
  }
  eventTimeIndex = 0;
  if (eventFlag == TRUE) {
    eventTimeIndex = firstTimeInterestGreaterOrEqual(right);
    if (eventTimeIndex > RF_sortedTimeInterestSize) {
      eventTimeIndex = 0;
    }
  }
  gridLeft = (idx1 > 1) ? RF_timeInterest[idx1 - 1] : 0.0;
  for (k = idx1; k <= idx2; k++) {
    gridRight = RF_timeInterest[k];
    overlapLeft = (left > gridLeft) ? left : gridLeft;
    overlapRight = (right < gridRight) ? right : gridRight;
    if (overlapRight > overlapLeft) {
  getCOEOOBCaseHazardAggregateAllTrim(caseID,
                                           subjIndex,
                                           k,
                                           oobTreeIndex,
                                           oobTreeCount,
                                           treeValue,
                                           cellAggregate);
      overlap = overlapRight - overlapLeft;
      for (trimIndex = 1; trimIndex <= SG_coeTrimSize; trimIndex++) {
        caseExposureRisk[trimIndex] +=
          cellAggregate[trimIndex] * overlap;
        if (eventTimeIndex == k) {
          caseEventRisk[trimIndex] +=
            -log(cellAggregate[trimIndex]);
        }
      }
    }
    gridLeft = gridRight;
  }
}
static void getCOEOOBSubjectRiskAllTrim(uint subjIndex,
                                        double *riskByTrim,
                                        uint *oobTreeIndex,
                                        double *treeValue,
                                        double *cellAggregate,
                                        double *eventRisk,
                                        double *caseExposureRisk,
                                        double *caseEventRisk) {
  double caseLeft;
  double caseRight;
  uint caseID;
  uint j;
  uint oobTreeCount;
  uint trimIndex;
  for (trimIndex = 1; trimIndex <= SG_coeTrimSize; trimIndex++) {
    riskByTrim[trimIndex] = 0.0;
    eventRisk[trimIndex] = 0.0;
  }
  if (RF_oobEnsembleDen[subjIndex] <= 0) {
    for (trimIndex = 1; trimIndex <= SG_coeTrimSize; trimIndex++) {
      riskByTrim[trimIndex] = RF_nativeNaN;
    }
    return;
  }
  oobTreeCount = getCOEOOBSubjectTreeIndex(subjIndex,
                                           oobTreeIndex);
  for (j = 1; j <= RF_subjSlotCount[subjIndex]; j++) {
    caseID = RF_subjList[subjIndex][j];
    caseLeft = RF_responseIn[RF_startTimeIndex][caseID];
    caseRight = RF_responseIn[RF_timeIndex][caseID];
  getCOEOOBCaseRiskExactOverlapAllTrim(caseID,
                                         subjIndex,
                                         caseLeft,
                                         caseRight,
                                         (RF_responseIn[RF_statusIndex][caseID] == 1),
                                         oobTreeIndex,
                                         oobTreeCount,
                                         treeValue,
                                         cellAggregate,
                                         caseExposureRisk,
                                         caseEventRisk);
    for (trimIndex = 1; trimIndex <= SG_coeTrimSize; trimIndex++) {
      riskByTrim[trimIndex] += caseExposureRisk[trimIndex];
      eventRisk[trimIndex] += caseEventRisk[trimIndex];
    }
  }
  for (trimIndex = 1; trimIndex <= SG_coeTrimSize; trimIndex++) {
    riskByTrim[trimIndex] += eventRisk[trimIndex];
  }
}
uint selectCOETrimByOOBRiskAllTrim(double *objective,
                                   uint *supportedSubjectCount,
                                   double *selectedSubjectRisk) {
  double **allSubjectRisk;
  double bestRisk;
  char bestRiskFound;
  uint candidateSubjectCount;
  uint referenceSubjectCount;
  uint selectedTrimIndex;
  uint subjIndex;
  uint trimIndex;
  if (objective == NULL) {
    RF_nativeError("\nRF-SRC:  *** ERROR *** ");
    RF_nativeError("\nRF-SRC:  Missing coe.trim OOB-risk objective storage.");
    RF_nativeExit();
  }
  allSubjectRisk = dmatrix(1,
                           SG_coeTrimSize,
                           1,
                           RF_subjCount);
#ifdef _OPENMP
#pragma omp parallel num_threads(RF_numThreads)
  {
    double *riskByTrim;
    double *treeValue;
    double *cellAggregate;
    double *eventRisk;
    double *caseExposureRisk;
    double *caseEventRisk;
    uint *oobTreeIndex;
    uint localTrimIndex;
    riskByTrim = dvector(1, SG_coeTrimSize);
    treeValue = dvector(1, RF_getTreeCount);
    cellAggregate = dvector(1, SG_coeTrimSize);
    eventRisk = dvector(1, SG_coeTrimSize);
    caseExposureRisk = dvector(1, SG_coeTrimSize);
    caseEventRisk = dvector(1, SG_coeTrimSize);
    oobTreeIndex = uivector(1, RF_getTreeCount);
#pragma omp for
    for (subjIndex = 1; subjIndex <= RF_subjCount; subjIndex++) {
  getCOEOOBSubjectRiskAllTrim(subjIndex,
                                  riskByTrim,
                                  oobTreeIndex,
                                  treeValue,
                                  cellAggregate,
                                  eventRisk,
                                  caseExposureRisk,
                                  caseEventRisk);
      for (localTrimIndex = 1;
           localTrimIndex <= SG_coeTrimSize;
           localTrimIndex++) {
        allSubjectRisk[localTrimIndex][subjIndex] =
          riskByTrim[localTrimIndex];
      }
    }
    free_uivector(oobTreeIndex, 1, RF_getTreeCount);
    free_dvector(caseEventRisk, 1, SG_coeTrimSize);
    free_dvector(caseExposureRisk, 1, SG_coeTrimSize);
    free_dvector(eventRisk, 1, SG_coeTrimSize);
    free_dvector(cellAggregate, 1, SG_coeTrimSize);
    free_dvector(treeValue, 1, RF_getTreeCount);
    free_dvector(riskByTrim, 1, SG_coeTrimSize);
  }
#else
  {
    double *riskByTrim;
    double *treeValue;
    double *cellAggregate;
    double *eventRisk;
    double *caseExposureRisk;
    double *caseEventRisk;
    uint *oobTreeIndex;
    riskByTrim = dvector(1, SG_coeTrimSize);
    treeValue = dvector(1, RF_getTreeCount);
    cellAggregate = dvector(1, SG_coeTrimSize);
    eventRisk = dvector(1, SG_coeTrimSize);
    caseExposureRisk = dvector(1, SG_coeTrimSize);
    caseEventRisk = dvector(1, SG_coeTrimSize);
    oobTreeIndex = uivector(1, RF_getTreeCount);
    for (subjIndex = 1; subjIndex <= RF_subjCount; subjIndex++) {
  getCOEOOBSubjectRiskAllTrim(subjIndex,
                                  riskByTrim,
                                  oobTreeIndex,
                                  treeValue,
                                  cellAggregate,
                                  eventRisk,
                                  caseExposureRisk,
                                  caseEventRisk);
      for (trimIndex = 1; trimIndex <= SG_coeTrimSize; trimIndex++) {
        allSubjectRisk[trimIndex][subjIndex] = riskByTrim[trimIndex];
      }
    }
    free_uivector(oobTreeIndex, 1, RF_getTreeCount);
    free_dvector(caseEventRisk, 1, SG_coeTrimSize);
    free_dvector(caseExposureRisk, 1, SG_coeTrimSize);
    free_dvector(eventRisk, 1, SG_coeTrimSize);
    free_dvector(cellAggregate, 1, SG_coeTrimSize);
    free_dvector(treeValue, 1, RF_getTreeCount);
    free_dvector(riskByTrim, 1, SG_coeTrimSize);
  }
#endif
  bestRisk = RF_nativeNaN;
  bestRiskFound = FALSE;
  referenceSubjectCount = 0;
  selectedTrimIndex = 1;
  for (trimIndex = 1; trimIndex <= SG_coeTrimSize; trimIndex++) {
    objective[trimIndex] =
      coeOOBRiskObjectiveFromVector(allSubjectRisk[trimIndex],
                                    RF_subjCount,
                                    &candidateSubjectCount);
    if (trimIndex == 1) {
      referenceSubjectCount = candidateSubjectCount;
    }
    else if (candidateSubjectCount != referenceSubjectCount) {
      RF_nativeError("\nRF-SRC:  *** ERROR *** ");
      RF_nativeError("\nRF-SRC:  coe.trim candidates produced inconsistent OOB support:  %10d versus %10d",
                     referenceSubjectCount,
                     candidateSubjectCount);
      RF_nativeExit();
    }
    if (!isnan(objective[trimIndex])) {
      if ((!bestRiskFound) || (objective[trimIndex] < bestRisk)) {
        bestRisk = objective[trimIndex];
        selectedTrimIndex = trimIndex;
        bestRiskFound = TRUE;
      }
    }
  }
  if (!bestRiskFound) {
    selectedTrimIndex = 1;
  }
  if (supportedSubjectCount != NULL) {
    *supportedSubjectCount = referenceSubjectCount;
  }
  if (selectedSubjectRisk != NULL) {
    for (subjIndex = 1; subjIndex <= RF_subjCount; subjIndex++) {
      selectedSubjectRisk[subjIndex] =
        allSubjectRisk[selectedTrimIndex][subjIndex];
    }
  }
  free_dmatrix(allSubjectRisk,
               1,
               SG_coeTrimSize,
               1,
               RF_subjCount);
  return selectedTrimIndex;
}
static char coeOOBRiskObjectiveEqual(double reference, double shadow) {
  double referenceAbs;
  double shadowAbs;
  double scale;
  double tolerance;
  if (isnan(reference) || isnan(shadow)) {
    return (isnan(reference) && isnan(shadow));
  }
  if (isinf(reference) || isinf(shadow)) {
    return ((reference == shadow) ? TRUE : FALSE);
  }
  referenceAbs = fabs(reference);
  shadowAbs = fabs(shadow);
  scale = (referenceAbs > shadowAbs) ? referenceAbs : shadowAbs;
  tolerance = EPSILON2 * (1.0 + scale);
  return ((fabs(reference - shadow) <= tolerance) ? TRUE : FALSE);
}
void validateCOEOOBRiskObjectiveAllTrim(double *batchedObjective,
                                        uint batchedSubjectCount,
                                        uint batchedTrimIndex) {
  double bestRisk;
  double referenceObjective;
  char bestRiskFound;
  uint referenceSubjectCount;
  uint referenceTrimIndex;
  uint trimIndex;
  bestRisk = RF_nativeNaN;
  bestRiskFound = FALSE;
  referenceTrimIndex = 1;
  for (trimIndex = 1; trimIndex <= SG_coeTrimSize; trimIndex++) {
  referenceObjective =
      getCOEOOBRiskObjectiveForTrim(trimIndex,
                                    &referenceSubjectCount);
    if (referenceSubjectCount != batchedSubjectCount) {
      RF_nativeError("\nRF-SRC:  *** ERROR *** ");
      RF_nativeError("\nRF-SRC:  Phase 7 batched coe.trim support mismatch at index %10d:  batched=%10d one-trim=%10d",
                     trimIndex,
                     batchedSubjectCount,
                     referenceSubjectCount);
      RF_nativeExit();
    }
    if (!coeOOBRiskObjectiveEqual(batchedObjective[trimIndex],
                                  referenceObjective)) {
      RF_nativeError("\nRF-SRC:  *** ERROR *** ");
      RF_nativeError("\nRF-SRC:  Phase 7 batched coe.trim objective mismatch at index %10d:  batched=%20.12f one-trim=%20.12f",
                     trimIndex,
                     batchedObjective[trimIndex],
                     referenceObjective);
      RF_nativeExit();
    }
    if (!isnan(referenceObjective)) {
      if ((!bestRiskFound) || (referenceObjective < bestRisk)) {
        bestRisk = referenceObjective;
        referenceTrimIndex = trimIndex;
        bestRiskFound = TRUE;
      }
    }
  }
  if (!bestRiskFound) {
    referenceTrimIndex = 1;
  }
  if (referenceTrimIndex != batchedTrimIndex) {
    RF_nativeError("\nRF-SRC:  *** ERROR *** ");
    RF_nativeError("\nRF-SRC:  Phase 7 batched coe.trim selected-index mismatch:  batched=%10d one-trim=%10d",
                   batchedTrimIndex,
                   referenceTrimIndex);
    RF_nativeExit();
  }
  {
    double referenceSubjectRisk;
    double *treeValue;
    uint *oobTreeIndex;
    uint subjIndex;
    treeValue = dvector(1, RF_getTreeCount);
    oobTreeIndex = uivector(1, RF_getTreeCount);
    for (subjIndex = 1; subjIndex <= RF_subjCount; subjIndex++) {
      referenceSubjectRisk =
        getCOEOOBSubjectRiskExactOverlap(subjIndex,
                                         batchedTrimIndex,
                                         oobTreeIndex,
                                         treeValue);
      if (!coeOOBRiskObjectiveEqual(SG_oobRisk_[subjIndex],
                                    referenceSubjectRisk)) {
        RF_nativeError("\nRF-SRC:  *** ERROR *** ");
        RF_nativeError("\nRF-SRC:  Phase 8 batched coe.trim subject-risk mismatch:  subject=%10d batched=%20.12f one-trim=%20.12f",
                       subjIndex,
                       SG_oobRisk_[subjIndex],
                       referenceSubjectRisk);
        RF_nativeExit();
      }
    }
    free_uivector(oobTreeIndex, 1, RF_getTreeCount);
    free_dvector(treeValue, 1, RF_getTreeCount);
  }
  RF_nativePrint("\nPhase 7-9 batched coe.trim production validation passed: candidates=%10d selected=%10d",
                 SG_coeTrimSize,
                 batchedTrimIndex);
}
static uint coeCollectTreeValues(double ***treeValue,
                                 uint subjIndex,
                                 uint timeIndex,
                                 double *value) {
  uint treeID;
  uint b;
  double localValue;
  uint count;
  count = 0;
  for (b = 1; b <= RF_getTreeCount; b++) {
    treeID = RF_getTreeIndex[b];
    localValue = treeValue[treeID][timeIndex][subjIndex];
    if ((!RF_nativeIsNaN(localValue)) && isfinite(localValue)) {
      value[++count] = localValue;
    }
  }
  return count;
}
static void coeAggregateTarget(double ***hazardTree,
                               double ***chfTree,
                               double **hazardOut,
                               double **chfOut,
                               uint subjIndex,
                               char aggregateType,
                               uint trimIndex,
                               double *value) {
  uint timeIndex;
  uint count;
  for (timeIndex = 1; timeIndex <= RF_sortedTimeInterestSize; timeIndex++) {
    count = coeCollectTreeValues(hazardTree, subjIndex, timeIndex, value);
    hazardOut[timeIndex][subjIndex] = coeAggregateValues(value, count, aggregateType, trimIndex);
    count = coeCollectTreeValues(chfTree, subjIndex, timeIndex, value);
    chfOut[timeIndex][subjIndex] = coeAggregateValues(value, count, aggregateType, trimIndex);
  }
}
static uint getCOESubjectTreeCount(double ***hazardTree,
                                   uint subjIndex) {
  uint b;
  uint treeID;
  uint timeIndex;
  uint count;
  double value;
  count = 0;
  for (b = 1; b <= RF_getTreeCount; b++) {
    treeID = RF_getTreeIndex[b];
    for (timeIndex = 1;
         timeIndex <= RF_sortedTimeInterestSize;
         timeIndex++) {
      value = hazardTree[treeID][timeIndex][subjIndex];
      if ((!RF_nativeIsNaN(value)) && isfinite(value)) {
        count++;
        break;  
      }
    }
  }
  return count;
}
void populateCOEEnsembleSupport(char mode, uint subjIndex) {
  if ((mode == RF_GROW) || (mode == RF_REST)) {
    if ((RF_opt & OPT_IENS) || (RF_opt & OPT_FENS)) {
      RF_fullEnsembleDen[subjIndex] =
        getCOESubjectTreeCount(SG_coeHazardTreeIBG_ptr, subjIndex);
    }
    if (RF_opt & OPT_OENS) {
      RF_oobEnsembleDen[subjIndex] =
        getCOESubjectTreeCount(SG_coeHazardTreeOOB_ptr, subjIndex);
    }
  }
  else {
    if (RF_opt & OPT_FENS) {
      RF_fullEnsembleDen[subjIndex] =
        getCOESubjectTreeCount(SG_coeHazardTreeIBG_ptr, subjIndex);
    }
  }
}
static void getCOEEnsembleAggregate(char mode,
                                    uint subjIndex,
                                    uint trimIndex,
                                    char aggregateType,
                                    double *value) {
  if ((mode == RF_GROW) || (mode == RF_REST)) {
    if ((RF_opt & OPT_IENS) || (RF_opt & OPT_FENS)) {
      coeAggregateTarget(SG_coeHazardTreeIBG_ptr,
                         SG_coeCHFTreeIBG_ptr,
                         SG_fullEnsembleKHZptr,
                         SG_fullEnsembleCHFptr,
                         subjIndex,
                         aggregateType,
                         trimIndex,
                         value);
    }
    if (RF_opt & OPT_OENS) {
      coeAggregateTarget(SG_coeHazardTreeOOB_ptr,
                         SG_coeCHFTreeOOB_ptr,
                         SG_oobEnsembleKHZptr,
                         SG_oobEnsembleCHFptr,
                         subjIndex,
                         aggregateType,
                         trimIndex,                         
                         value);
    }
  }
  else {
    if (RF_opt & OPT_FENS) {
      coeAggregateTarget(SG_coeHazardTreeIBG_ptr,
                         SG_coeCHFTreeIBG_ptr,
                         SG_fullEnsembleKHZptr,
                         SG_fullEnsembleCHFptr,
                         subjIndex,
                         aggregateType,
                         trimIndex,                         
                         value);
    }
  }
}
void getCOEEnsembleAggregateAllSubjects(char mode, uint subjCount, uint trimIndex) {
  uint subjIndex;
  char aggregateType = coeGetAggregateType(trimIndex);
#ifdef _OPENMP
#pragma omp parallel num_threads(RF_numThreads)
  {
    double *value;
    value = dvector(1, RF_getTreeCount);
#pragma omp for
    for (subjIndex = 1; subjIndex <= subjCount; subjIndex++) {
      getCOEEnsembleAggregate(mode,
                              subjIndex,
                              trimIndex,
                              aggregateType,
                              value);
    }
    free_dvector(value, 1, RF_getTreeCount);
  }
#else
  {
    double *value;
    value = dvector(1, RF_getTreeCount);
    for (subjIndex = 1; subjIndex <= subjCount; subjIndex++) {
      getCOEEnsembleAggregate(mode,
                              subjIndex,
                              trimIndex,
                              aggregateType,
                              value);
    }
    free_dvector(value, 1, RF_getTreeCount);
  }
#endif
}
static double getCOEOOBCaseRiskExactOverlap(uint    caseID,
                                            uint    subjIndex,
                                            double  left,
                                            double  right,
                                            char    eventFlag,
                                            double *eventRisk,
                                            uint   *oobTreeIndex,
                                            uint    oobTreeCount,
                                            double *treeValue,
                                            uint    trimIndex) {
  double result;
  double caseHazard;
  double gridLeft, gridRight;
  double overlapLeft, overlapRight;
  uint idx1, idx2, k;
  uint eventTimeIndex;
  result = 0.0;
  *eventRisk = 0.0;
  if (!(left < right)) {
    return result;
  }
  idx1 = firstTimeInterestGreater(left);
  if (idx1 > RF_sortedTimeInterestSize) {
    return result;
  }
  idx2 = firstTimeInterestGreaterOrEqual(right);
  if (idx2 > RF_sortedTimeInterestSize) {
    idx2 = RF_sortedTimeInterestSize;
  }
  eventTimeIndex = 0;
  if (eventFlag == TRUE) {
    eventTimeIndex = firstTimeInterestGreaterOrEqual(right);
    if (eventTimeIndex > RF_sortedTimeInterestSize) {
      eventTimeIndex = 0;
    }
  }
  gridLeft = (idx1 > 1) ? RF_timeInterest[idx1 - 1] : 0.0;
  for (k = idx1; k <= idx2; k++) {
    gridRight = RF_timeInterest[k];
    overlapLeft  = (left  > gridLeft)  ? left  : gridLeft;
    overlapRight = (right < gridRight) ? right : gridRight;
    if (overlapRight > overlapLeft) {
      caseHazard = getCOEOOBCaseHazardAggregate(caseID,
                                                subjIndex,
                                                k,
                                                oobTreeIndex,
                                                oobTreeCount,
                                                treeValue,
                                                trimIndex);
      result += caseHazard * (overlapRight - overlapLeft);
      if (eventTimeIndex == k) {
        *eventRisk += -log(caseHazard);
      }
    }
    gridLeft = gridRight;
  }
  return result;
}
double getCOEOOBSubjectRiskExactOverlap(uint subjIndex,
                                        uint trimIndex,
                                        uint *oobTreeIndex,
                                        double *treeValue) {
  double exposureRisk;
  double eventRisk;
  double caseExposureRisk;
  double caseEventRisk;
  double caseLeft;
  double caseRight;
  uint caseID;
  uint j;
  uint oobTreeCount;
  if (RF_oobEnsembleDen[subjIndex] <= 0) {
    return RF_nativeNaN;
  }
  oobTreeCount = getCOEOOBSubjectTreeIndex(subjIndex,
                                           oobTreeIndex);
  exposureRisk = 0.0;
  eventRisk = 0.0;
  for (j = 1; j <= RF_subjSlotCount[subjIndex]; j++) {
    caseID = RF_subjList[subjIndex][j];
    caseLeft = RF_responseIn[RF_startTimeIndex][caseID];
    caseRight = RF_responseIn[RF_timeIndex][caseID];
  caseExposureRisk =
      getCOEOOBCaseRiskExactOverlap(caseID,
                                    subjIndex,
                                    caseLeft,
                                    caseRight,
                                    (RF_responseIn[RF_statusIndex][caseID] == 1),
                                    &caseEventRisk,
                                    oobTreeIndex,
                                    oobTreeCount,
                                    treeValue,
                                    trimIndex);
    exposureRisk += caseExposureRisk;
    eventRisk += caseEventRisk;
  }
  return exposureRisk + eventRisk;
}
