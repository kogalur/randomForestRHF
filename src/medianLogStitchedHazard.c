
// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***
#include           "shared/globalCore.h"
#include           "shared/externalCore.h"
#include           "global.h"
#include           "external.h"

// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***

      
    

#include <R.h>
#include <Rinternals.h>
#include <R_ext/Utils.h>   
#include <math.h>          
#include <string.h>        
static int first_index_gt(const double *x, int n, double value) {
  int lo = 0, hi = n;
  while (lo < hi) {
    int mid = lo + (hi - lo) / 2;
    if (x[mid] <= value) lo = mid + 1;
    else hi = mid;
  }
  return lo;
}
static int bin_index_right_inclusive(const double *t, int q, double value) {
  if (q <= 0) return 0;
  if (value <= t[0]) return 0;
  if (value >= t[q - 1]) return q - 1;
  int idx = first_index_gt(t, q, value); 
  if (idx <= 0) return 0;
  if (idx >= q) return q - 1;
  if (t[idx - 1] == value) return idx - 1;
  return idx;
}
static void swap_double(double *a, double *b) {
  double tmp = *a;
  *a = *b;
  *b = tmp;
}
static int partition(double *arr, int left, int right, int pivotIndex) {
  double pivotValue = arr[pivotIndex];
  swap_double(&arr[pivotIndex], &arr[right]);
  int store = left;
  for (int i = left; i < right; i++) {
    if (arr[i] < pivotValue) {
      swap_double(&arr[store], &arr[i]);
      store++;
    }
  }
  swap_double(&arr[right], &arr[store]);
  return store;
}
static double quickselect(double *arr, int n, int k) {
  int left = 0;
  int right = n - 1;
  while (1) {
    if (left == right) return arr[left];
    int pivotIndex = left + (right - left) / 2;
    pivotIndex = partition(arr, left, right, pivotIndex);
    if (k == pivotIndex) return arr[k];
    if (k < pivotIndex) right = pivotIndex - 1;
    else left = pivotIndex + 1;
  }
}
static double median_inplace(double *arr, int n) {
  if (n <= 0) return NA_REAL;
  if (n == 1) return arr[0];
  if (n % 2 == 1) {
    return quickselect(arr, n, n / 2);
  } else {
    double a = quickselect(arr, n, n / 2 - 1);
    double b = quickselect(arr, n, n / 2);
    return 0.5 * (a + b);
  }
}
SEXP medianLogStitchedHazard(SEXP idSEXP,
                             SEXP startSEXP,
                             SEXP stopSEXP,
                             SEXP timeSEXP,
                             SEXP inbagSEXP,
                             SEXP leafCountSEXP,
                             SEXP timbrCaseCtSEXP,
                             SEXP timbrCaseIdSEXP,
                             SEXP tombrCaseCtSEXP,
                             SEXP tombrCaseIdSEXP,
                             SEXP tHazardSEXP,
                             SEXP targetSEXP,
                             SEXP epsSEXP) {
  if (!isInteger(idSEXP))   error("id must be integer.");
  if (!isReal(startSEXP))   error("start must be numeric (double).");
  if (!isReal(stopSEXP))    error("stop must be numeric (double).");
  if (!isReal(timeSEXP))    error("timeInterest must be numeric (double).");
  if (!isInteger(inbagSEXP))     error("inbag must be an integer matrix.");
  if (!isInteger(leafCountSEXP)) error("leafCount must be integer.");
  if (!isInteger(timbrCaseCtSEXP)) error("timbrCaseCt must be integer.");
  if (!isInteger(timbrCaseIdSEXP)) error("timbrCaseId must be integer.");
  if (!isInteger(tombrCaseCtSEXP)) error("tombrCaseCt must be integer.");
  if (!isInteger(tombrCaseIdSEXP)) error("tombrCaseId must be integer.");
  if (!isNewList(tHazardSEXP)) error("tHazard must be a list of matrices (one per tree).");
  if (!isInteger(targetSEXP) || LENGTH(targetSEXP) != 1) error("target must be an integer scalar.");
  if (!isReal(epsSEXP) || LENGTH(epsSEXP) != 1) error("eps must be a numeric scalar.");
  double eps = REAL(epsSEXP)[0];
  if (!R_finite(eps) || eps <= 0.0) error("eps must be finite and > 0.");
  int target = INTEGER(targetSEXP)[0];
  if (target < 0 || target > 2) error("target must be 0 (oob), 1 (inbag), or 2 (both).");
  int doOo = (target == 0 || target == 2);
  int doIn = (target == 1 || target == 2);
  int N = LENGTH(idSEXP);
  if (LENGTH(startSEXP) != N || LENGTH(stopSEXP) != N) {
    error("id/start/stop must have the same length (N pseudo-records).");
  }
  SEXP dimInbag = getAttrib(inbagSEXP, R_DimSymbol);
  if (dimInbag == R_NilValue || LENGTH(dimInbag) != 2) error("inbag must be a matrix.");
  int nSubj = INTEGER(dimInbag)[0];
  int B     = INTEGER(dimInbag)[1];
  if (LENGTH(leafCountSEXP) != B) error("leafCount length must equal ncol(inbag).");
  if (LENGTH(tHazardSEXP) != B)   error("length(tHazard) must equal number of trees.");
  int q = LENGTH(timeSEXP);
  if (q < 1) error("timeInterest must have positive length.");
  int    *id    = INTEGER(idSEXP);
  double *start = REAL(startSEXP);
  double *stop  = REAL(stopSEXP);
  double *t     = REAL(timeSEXP);
  int    *inbag = INTEGER(inbagSEXP);
  int    *leafCount = INTEGER(leafCountSEXP);
  for (int r = 1; r < q; r++) {
    if (!(t[r] > t[r - 1])) error("timeInterest must be strictly increasing.");
  }
  double maxTime = t[q - 1];
  int totalLeaves = 0;
  for (int b = 0; b < B; b++) {
    if (leafCount[b] < 1) error("leafCount entries must be >= 1.");
    totalLeaves += leafCount[b];
  }
  if (LENGTH(timbrCaseCtSEXP) != totalLeaves) error("length(timbrCaseCt) must equal sum(leafCount).");
  if (LENGTH(tombrCaseCtSEXP) != totalLeaves) error("length(tombrCaseCt) must equal sum(leafCount).");
  int *timbrCt = INTEGER(timbrCaseCtSEXP);
  int *timbrId = INTEGER(timbrCaseIdSEXP);
  int *tombrCt = INTEGER(tombrCaseCtSEXP);
  int *tombrId = INTEGER(tombrCaseIdSEXP);
  long long sumTimbr = 0;
  long long sumTombr = 0;
  for (int g = 0; g < totalLeaves; g++) {
    if (timbrCt[g] < 0) error("timbrCaseCt has negative entry.");
    if (tombrCt[g] < 0) error("tombrCaseCt has negative entry.");
    sumTimbr += (long long) timbrCt[g];
    sumTombr += (long long) tombrCt[g];
  }
  if (sumTimbr != (long long) LENGTH(timbrCaseIdSEXP)) error("sum(timbrCaseCt) must equal length(timbrCaseId).");
  if (sumTombr != (long long) LENGTH(tombrCaseIdSEXP)) error("sum(tombrCaseCt) must equal length(tombrCaseId).");
  double **hazPtr = (double**) R_alloc((size_t) B, sizeof(double*));
  int    *LbArr   = (int*)    R_alloc((size_t) B, sizeof(int));
  for (int b = 0; b < B; b++) {
    SEXP hazMatSEXP = VECTOR_ELT(tHazardSEXP, b);
    if (!isReal(hazMatSEXP) || !isMatrix(hazMatSEXP)) error("tHazard[[b]] must be a numeric matrix.");
    SEXP dimHaz = getAttrib(hazMatSEXP, R_DimSymbol);
    int nrowHaz = INTEGER(dimHaz)[0];
    int ncolHaz = INTEGER(dimHaz)[1];
    if (nrowHaz != leafCount[b]) error("tHazard[[b]] nrow must equal leafCount[b].");
    if (ncolHaz != q)            error("tHazard[[b]] ncol must equal length(timeInterest).");
    hazPtr[b] = REAL(hazMatSEXP);
    LbArr[b]  = nrowHaz;
  }
  int *nTreeIn = (int*) R_alloc((size_t) nSubj, sizeof(int));
  int *nTreeOo = (int*) R_alloc((size_t) nSubj, sizeof(int));
  for (int i = 0; i < nSubj; i++) {
    int cnt = 0;
    for (int b = 0; b < B; b++) {
      if (inbag[i + nSubj * b] != 0) cnt++;
    }
    nTreeIn[i] = cnt;
    nTreeOo[i] = B - cnt;
  }
  int *activeRec = (int*) R_alloc((size_t) nSubj * (size_t) q, sizeof(int));
  for (size_t k = 0; k < (size_t) nSubj * (size_t) q; k++) activeRec[k] = -1;
  for (int m = 0; m < N; m++) {
    int subj = id[m];
    if (subj < 1 || subj > nSubj) error("id out of range 1..nSubj.");
    int subj0 = subj - 1;
    double s = start[m];
    double e = stop[m];
    if (!R_finite(s) || !R_finite(e)) continue;
    if (!(e > s)) continue;
    int hasNext = (m < (N - 1)) && (id[m + 1] == subj);
    double stopPred = hasNext ? start[m + 1] : maxTime;
    if (!R_finite(stopPred) || !(stopPred > s)) continue;
    int rS = first_index_gt(t, q, s);
    int rE = bin_index_right_inclusive(t, q, stopPred);
    if (rS < 0) rS = 0;
    if (rE > q - 1) rE = q - 1;
    if (rS > rE) continue;
    for (int r = rS; r <= rE; r++) {
      activeRec[subj0 + nSubj * r] = m;
    }
  }
  int *leafMap = (int*) R_alloc((size_t) N * (size_t) B, sizeof(int));
  for (size_t k = 0; k < (size_t) N * (size_t) B; k++) leafMap[k] = -1;
  long long posIn = 0;
  long long posOo = 0;
  int gLeaf = 0;
  for (int b = 0; b < B; b++) {
    int Lb = leafCount[b];
    for (int l = 0; l < Lb; l++) {
      if (gLeaf >= totalLeaves) error("Internal error: leaf index exceeded totalLeaves.");
      int cti = timbrCt[gLeaf];
      int cto = tombrCt[gLeaf];
      for (int j = 0; j < cti; j++) {
        int m1 = timbrId[posIn + j];
        if (m1 < 1 || m1 > N) error("timbrCaseId contains out-of-range record index.");
        int m = m1 - 1;
        leafMap[(size_t) m + (size_t) N * (size_t) b] = l;
      }
      for (int j = 0; j < cto; j++) {
        int m1 = tombrId[posOo + j];
        if (m1 < 1 || m1 > N) error("tombrCaseId contains out-of-range record index.");
        int m = m1 - 1;
        leafMap[(size_t) m + (size_t) N * (size_t) b] = l;
      }
      posIn += (long long) cti;
      posOo += (long long) cto;
      gLeaf++;
    }
  }
  if (gLeaf != totalLeaves) error("Internal error: did not consume all leaf nodes.");
  if (posIn != sumTimbr)    error("Internal error: did not consume all timbrCaseId entries.");
  if (posOo != sumTombr)    error("Internal error: did not consume all tombrCaseId entries.");
  SEXP logIn = R_NilValue;
  SEXP logOo = R_NilValue;
  double *outIn = NULL;
  double *outOo = NULL;
  int nProtect = 0;
  if (doIn) {
    logIn = PROTECT(allocMatrix(REALSXP, nSubj, q));
    outIn = REAL(logIn);
    nProtect++;
  }
  if (doOo) {
    logOo = PROTECT(allocMatrix(REALSXP, nSubj, q));
    outOo = REAL(logOo);
    nProtect++;
  }
  double *tmp = (double*) R_alloc((size_t) B, sizeof(double));
  for (int subj0 = 0; subj0 < nSubj; subj0++) {
    int Bi_in = nTreeIn[subj0];
    int Bi_oo = nTreeOo[subj0];
    for (int r = 0; r < q; r++) {
      size_t outIdx = (size_t) subj0 + (size_t) nSubj * (size_t) r;
      int m = activeRec[subj0 + nSubj * r];
      if (m < 0) {
        if (doIn) outIn[outIdx] = NA_REAL;
        if (doOo) outOo[outIdx] = NA_REAL;
        continue;
      }
      if (doIn) {
        if (Bi_in <= 0) {
          outIn[outIdx] = NA_REAL;
        } else {
          int k = 0;
          for (int b = 0; b < B; b++) {
            if (inbag[subj0 + nSubj * b] == 0) continue;
            int leaf = leafMap[(size_t) m + (size_t) N * (size_t) b];
            if (leaf < 0) continue;
            int Lb = LbArr[b];
            double h = hazPtr[b][leaf + Lb * r];
            if (!R_finite(h) || h < 0.0) continue;
            tmp[k++] = log(h + eps);
          }
          outIn[outIdx] = (k == 0) ? NA_REAL : median_inplace(tmp, k);
        }
      }
      if (doOo) {
        if (Bi_oo <= 0) {
          outOo[outIdx] = NA_REAL;
        } else {
          int k = 0;
          for (int b = 0; b < B; b++) {
            if (inbag[subj0 + nSubj * b] != 0) continue;
            int leaf = leafMap[(size_t) m + (size_t) N * (size_t) b];
            if (leaf < 0) continue;
            int Lb = LbArr[b];
            double h = hazPtr[b][leaf + Lb * r];
            if (!R_finite(h) || h < 0.0) continue;
            tmp[k++] = log(h + eps);
          }
          outOo[outIdx] = (k == 0) ? NA_REAL : median_inplace(tmp, k);
        }
      }
    }
    if ((subj0 % 64) == 0) R_CheckUserInterrupt();
  }
  SEXP out = PROTECT(allocVector(VECSXP, 2));
  SET_VECTOR_ELT(out, 0, logIn);
  SET_VECTOR_ELT(out, 1, logOo);
  SEXP nms = PROTECT(allocVector(STRSXP, 2));
  SET_STRING_ELT(nms, 0, mkChar("loghazard.inbag"));
  SET_STRING_ELT(nms, 1, mkChar("loghazard.oob"));
  setAttrib(out, R_NamesSymbol, nms);
  UNPROTECT(nProtect + 2); 
  return out;
}
