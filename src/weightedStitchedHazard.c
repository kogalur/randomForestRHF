
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
static int first_index_gt(const double *x, int n, double value) {
  int lo = 0, hi = n;
  while (lo < hi) {
    int mid = lo + (hi - lo) / 2;
    if (x[mid] <= value) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return lo;
}
static int last_index_le(const double *x, int n, double value) {
  int lo = 0, hi = n;
  while (lo < hi) {
    int mid = lo + (hi - lo) / 2;
    if (x[mid] <= value) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return lo - 1;
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
static inline double bin_left(const double *t, int r) {
  return (r <= 0) ? 0.0 : t[r - 1];
}
static inline double overlap_len(double s, double e, double left, double right) {
  double a = (s > left) ? s : left;
  double b = (e < right) ? e : right;
  double d = b - a;
  return (d > 0.0) ? d : 0.0;
}
SEXP weightedStitchedHazard(SEXP idSEXP,
                            SEXP startSEXP,
                            SEXP stopSEXP,
                            SEXP eventSEXP,
                            SEXP timeSEXP,
                            SEXP inbagSEXP,
                            SEXP leafCountSEXP,
                            SEXP timbrCaseCtSEXP,
                            SEXP timbrCaseIdSEXP,
                            SEXP tombrCaseCtSEXP,
                            SEXP tombrCaseIdSEXP,
                            SEXP tHazardSEXP,
                            SEXP weightModeSEXP,
                            SEXP betaScaleSEXP) {
  if (!isInteger(idSEXP))    error("id must be integer.");
  if (!isReal(startSEXP))    error("start must be numeric (double).");
  if (!isReal(stopSEXP))     error("stop must be numeric (double).");
  if (!isInteger(eventSEXP)) error("event must be integer.");
  if (!isReal(timeSEXP))     error("timeInterest must be numeric (double).");
  if (!isInteger(inbagSEXP))     error("inbag must be an integer matrix.");
  if (!isInteger(leafCountSEXP)) error("leafCount must be integer.");
  if (!isInteger(timbrCaseCtSEXP)) error("timbrCaseCt must be integer.");
  if (!isInteger(timbrCaseIdSEXP)) error("timbrCaseId must be integer.");
  if (!isInteger(tombrCaseCtSEXP)) error("tombrCaseCt must be integer.");
  if (!isInteger(tombrCaseIdSEXP)) error("tombrCaseId must be integer.");
  if (!isNewList(tHazardSEXP)) error("tHazard must be a list of matrices (one per tree).");
  if (!isInteger(weightModeSEXP) || LENGTH(weightModeSEXP) != 1) {
    error("weightMode must be an integer scalar (0=uniform, 1=eb.hazard).");
  }
  int weightMode = INTEGER(weightModeSEXP)[0];
  if (!(weightMode == 0 || weightMode == 1)) {
    error("weightMode must be 0 (uniform) or 1 (eb.hazard).");
  }
  if (!isReal(betaScaleSEXP) || LENGTH(betaScaleSEXP) != 1) {
    error("beta.scale must be a numeric scalar.");
  }
  double betaScale = REAL(betaScaleSEXP)[0];
  if (!R_finite(betaScale) || betaScale < 0.0) {
    error("beta.scale must be a single finite number >= 0.");
  }
  int N = LENGTH(idSEXP);
  if (LENGTH(startSEXP) != N || LENGTH(stopSEXP) != N || LENGTH(eventSEXP) != N) {
    error("id/start/stop/event must all have same length (N pseudo-records).");
  }
  SEXP dimInbag = getAttrib(inbagSEXP, R_DimSymbol);
  if (dimInbag == R_NilValue || LENGTH(dimInbag) != 2) error("inbag must be a matrix.");
  int nSubj = INTEGER(dimInbag)[0];
  int B     = INTEGER(dimInbag)[1];
  if (LENGTH(leafCountSEXP) != B) error("leafCount length must equal ncol(inbag).");
  if (LENGTH(tHazardSEXP) != B)   error("length(tHazard) must equal number of trees (B).");
  int q = LENGTH(timeSEXP);
  if (q < 1) error("timeInterest must have positive length.");
  int    *id    = INTEGER(idSEXP);
  double *start = REAL(startSEXP);
  double *stop  = REAL(stopSEXP);
  int    *event = INTEGER(eventSEXP);
  double *t     = REAL(timeSEXP);
  int *inbag     = INTEGER(inbagSEXP);
  int *leafCount = INTEGER(leafCountSEXP);
  double *dt = (double*) R_alloc(q, sizeof(double));
  dt[0] = t[0] - 0.0;
  if (dt[0] < 0.0) error("timeInterest[1] must be >= 0.");
  for (int r = 1; r < q; r++) {
    if (t[r] <= t[r - 1]) error("timeInterest must be strictly increasing.");
    dt[r] = t[r] - t[r - 1];
    if (dt[r] <= 0.0) error("Non-positive grid spacing encountered.");
  }
  double maxTime = t[q - 1];
  int totalLeaves = 0;
  int maxLeaves = 0;
  for (int b = 0; b < B; b++) {
    if (leafCount[b] < 1) error("leafCount entries must be >= 1.");
    totalLeaves += leafCount[b];
    if (leafCount[b] > maxLeaves) maxLeaves = leafCount[b];
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
  int *nTreeIn = (int*) R_alloc(nSubj, sizeof(int));
  int *nTreeOo = (int*) R_alloc(nSubj, sizeof(int));
  for (int i = 0; i < nSubj; i++) {
    int cnt = 0;
    for (int b = 0; b < B; b++) {
      int flag = inbag[i + nSubj * b];
      if (flag) cnt++;
    }
    nTreeIn[i] = cnt;
    nTreeOo[i] = B - cnt;
  }
  double *stopTrainArr = (double*) R_alloc(N, sizeof(double));
  int *rStartTrain = (int*) R_alloc(N, sizeof(int));
  int *rEndTrain   = (int*) R_alloc(N, sizeof(int));
  int *rStartPred  = (int*) R_alloc(N, sizeof(int));
  int *rEndPred    = (int*) R_alloc(N, sizeof(int));
  for (int m = 0; m < N; m++) {
    int subj = id[m];
    if (subj < 1 || subj > nSubj) error("id out of range 1..nSubj.");
    double s = start[m];
    double e = stop[m];
    stopTrainArr[m] = 0.0;
    rStartTrain[m]  = 1;
    rEndTrain[m]    = 0;
    rStartPred[m]   = 1;
    rEndPred[m]     = 0;
    if (!(e > s)) continue;
    int hasNext = (m < (N - 1)) && (id[m + 1] == subj);
    double stopTrain = hasNext ? start[m + 1] : e;
    if (stopTrain < e) stopTrain = e;  
    if (stopTrain > maxTime) stopTrain = maxTime;
    double stopPred = hasNext ? start[m + 1] : maxTime;
    if (stopPred < e) stopPred = e;
    if (stopPred > maxTime) stopPred = maxTime;
    int rsT = first_index_gt(t, q, s);
    int reT = bin_index_right_inclusive(t, q, stopTrain);
    int rsP = first_index_gt(t, q, s);
    int reP = last_index_le(t, q, stopPred);
    rStartTrain[m] = rsT;
    rEndTrain[m]   = reT;
    rStartPred[m]  = rsP;
    rEndPred[m]    = reP;
    stopTrainArr[m] = stopTrain;
  }
  int doEB = (weightMode == 1 && betaScale > 0.0);
  double *alpha = NULL;
  double *beta  = NULL;
  if (doEB) {
    double *U0 = (double*) R_alloc(q, sizeof(double));
    int    *D0 = (int*)    R_alloc(q, sizeof(int));
    int    *fullDiff0 = (int*) R_alloc(q + 1, sizeof(int));
    for (int r = 0; r < q; r++) {
      U0[r] = 0.0;
      D0[r] = 0;
      fullDiff0[r] = 0;
    }
    fullDiff0[q] = 0;
    for (int m = 0; m < N; m++) {
      double s = start[m];
      double e = stopTrainArr[m];
      if (!(e > s)) continue;
      int rS = rStartTrain[m];
      int rE = rEndTrain[m];
      if (!(rS <= rE)) continue;
      if (rS < 0) rS = 0;
      if (rE > q - 1) rE = q - 1;
      if (rS == rE) {
        U0[rS] += overlap_len(s, e, bin_left(t, rS), t[rS]);
      } else {
        U0[rS] += overlap_len(s, e, bin_left(t, rS), t[rS]);
        U0[rE] += overlap_len(s, e, bin_left(t, rE), t[rE]);
        int fs = rS + 1;
        int fe = rE - 1;
        if (fs <= fe) {
          fullDiff0[fs] += 1;
          fullDiff0[fe + 1] -= 1;  
        }
      }
    }
    int run = 0;
    for (int r = 0; r < q; r++) {
      run += fullDiff0[r];
      if (run > 0) U0[r] += ((double) run) * dt[r];
    }
    for (int m = 0; m < N; m++) {
      if (event[m] != 1) continue;
      double te = stop[m];
      if (!R_finite(te)) continue;
      int rEvt = bin_index_right_inclusive(t, q, te);
      if (rEvt < 0) rEvt = 0;
      if (rEvt > q - 1) rEvt = q - 1;
      D0[rEvt] += 1;
    }
    alpha = (double*) R_alloc(q, sizeof(double));
    beta  = (double*) R_alloc(q, sizeof(double));
    for (int r = 0; r < q; r++) {
      double lam0 = (U0[r] > 0.0) ? ((double) D0[r] / U0[r]) : 0.0;
      beta[r]  = betaScale * dt[r];
      alpha[r] = lam0 * beta[r];
    }
  }
  SEXP hazIn = PROTECT(allocMatrix(REALSXP, q, nSubj));
  SEXP hazOo = PROTECT(allocMatrix(REALSXP, q, nSubj));
  double *hazI = REAL(hazIn);
  double *hazO = REAL(hazOo);
  size_t outLen = (size_t) q * (size_t) nSubj;
  for (size_t k = 0; k < outLen; k++) {
    hazI[k] = 0.0;
    hazO[k] = 0.0;
  }
  long long posIn = 0;
  long long posOo = 0;
  int gLeaf = 0;
  double *expoRow = doEB ? (double*) R_alloc(q, sizeof(double)) : NULL;
  int    *fullDiff = doEB ? (int*)    R_alloc(q + 1, sizeof(int)) : NULL;
  for (int b = 0; b < B; b++) {
    int Lb = leafCount[b];
    SEXP hazMatSEXP = VECTOR_ELT(tHazardSEXP, b);
    if (!isReal(hazMatSEXP) || !isMatrix(hazMatSEXP)) {
      error("tHazard[[b]] must be a numeric matrix.");
    }
    SEXP dimHaz = getAttrib(hazMatSEXP, R_DimSymbol);
    int nrowHaz = INTEGER(dimHaz)[0];
    int ncolHaz = INTEGER(dimHaz)[1];
    if (nrowHaz != Lb) error("tHazard[[b]] nrow must equal leafCount[b].");
    if (ncolHaz != q)  error("tHazard[[b]] ncol must equal length(timeInterest).");
    double *hazMat = REAL(hazMatSEXP);
    for (int l = 0; l < Lb; l++) {
      if (gLeaf >= totalLeaves) error("Internal error: leaf index exceeded totalLeaves.");
      int cti = timbrCt[gLeaf];
      int cto = tombrCt[gLeaf];
      if (doEB) {
        for (int r = 0; r < q; r++) {
          expoRow[r] = 0.0;
          fullDiff[r] = 0;
        }
        fullDiff[q] = 0;
        if (cti > 0) {
          for (int j = 0; j < cti; j++) {
            int m1 = timbrId[posIn + j];
            if (m1 < 1 || m1 > N) error("timbrCaseId contains out-of-range record index.");
            int m = m1 - 1;
            double s = start[m];
            double e = stopTrainArr[m];
            if (!(e > s)) continue;
            int rS = rStartTrain[m];
            int rE = rEndTrain[m];
            if (!(rS <= rE)) continue;
            if (rS < 0) rS = 0;
            if (rE > q - 1) rE = q - 1;
            if (rS == rE) {
              expoRow[rS] += overlap_len(s, e, bin_left(t, rS), t[rS]);
            } else {
              expoRow[rS] += overlap_len(s, e, bin_left(t, rS), t[rS]);
              expoRow[rE] += overlap_len(s, e, bin_left(t, rE), t[rE]);
              int fs = rS + 1;
              int fe = rE - 1;
              if (fs <= fe) {
                fullDiff[fs] += 1;
                fullDiff[fe + 1] -= 1;
              }
            }
          }
        }
        int runLeaf = 0;
        for (int r = 0; r < q; r++) {
          runLeaf += fullDiff[r];
          if (runLeaf > 0) expoRow[r] += ((double) runLeaf) * dt[r];
        }
      }
      for (int j = 0; j < cti; j++) {
        int m1 = timbrId[posIn + j];
        int m  = m1 - 1;
        int subj0 = id[m] - 1;
        int rS = rStartPred[m];
        int rE = rEndPred[m];
        if (!(rS <= rE && rS < q && rE >= 0)) continue;
        if (rS < 0) rS = 0;
        if (rE > q - 1) rE = q - 1;
        for (int r = rS; r <= rE; r++) {
          size_t outIdx = (size_t) r + (size_t) q * (size_t) subj0;
          double h = hazMat[l + Lb * r];
          if (doEB) {
            double u = expoRow[r];
            h = (u * h + alpha[r]) / (u + beta[r]);
          }
          hazI[outIdx] += h;
        }
      }
      for (int j = 0; j < cto; j++) {
        int m1 = tombrId[posOo + j];
        if (m1 < 1 || m1 > N) error("tombrCaseId contains out-of-range record index.");
        int m  = m1 - 1;
        int subj0 = id[m] - 1;
        int rS = rStartPred[m];
        int rE = rEndPred[m];
        if (!(rS <= rE && rS < q && rE >= 0)) continue;
        if (rS < 0) rS = 0;
        if (rE > q - 1) rE = q - 1;
        for (int r = rS; r <= rE; r++) {
          size_t outIdx = (size_t) r + (size_t) q * (size_t) subj0;
          double h = hazMat[l + Lb * r];
          if (doEB) {
            double u = expoRow[r];
            h = (u * h + alpha[r]) / (u + beta[r]);
          }
          hazO[outIdx] += h;
        }
      }
      posIn += cti;
      posOo += cto;
      gLeaf++;
    }
    if ((b % 10) == 0) R_CheckUserInterrupt();
  }
  if (gLeaf != totalLeaves) error("Internal error: did not consume all leaf nodes.");
  if (posIn != sumTimbr)    error("Internal error: did not consume all timbrCaseId entries.");
  if (posOo != sumTombr)    error("Internal error: did not consume all tombrCaseId entries.");
  for (int subj0 = 0; subj0 < nSubj; subj0++) {
    int Bi_in = nTreeIn[subj0];
    int Bi_oo = nTreeOo[subj0];
    for (int r = 0; r < q; r++) {
      size_t outIdx = (size_t) r + (size_t) q * (size_t) subj0;
      hazI[outIdx] = (Bi_in <= 0) ? NA_REAL : (hazI[outIdx] / (double) Bi_in);
      hazO[outIdx] = (Bi_oo <= 0) ? NA_REAL : (hazO[outIdx] / (double) Bi_oo);
    }
  }
  SEXP out = PROTECT(allocVector(VECSXP, 2));
  SET_VECTOR_ELT(out, 0, hazIn);
  SET_VECTOR_ELT(out, 1, hazOo);
  SEXP nms = PROTECT(allocVector(STRSXP, 2));
  SET_STRING_ELT(nms, 0, mkChar("hazard.inbag"));
  SET_STRING_ELT(nms, 1, mkChar("hazard.oob"));
  setAttrib(out, R_NamesSymbol, nms);
  UNPROTECT(4);
  return out;
}
