
// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***
#include           "shared/globalCore.h"
#include           "shared/externalCore.h"
#include           "global.h"
#include           "external.h"

// *** THIS HEADER IS AUTO GENERATED. DO NOT EDIT IT ***

      
    

#include <R.h>
#include <Rinternals.h>
#include <stdlib.h> 
#include <R_ext/Rdynload.h>
extern SEXP entryGrow(SEXP, SEXP, SEXP, SEXP,
                      SEXP, SEXP, SEXP, SEXP,
                      SEXP, SEXP, SEXP, SEXP,
                      SEXP, SEXP, SEXP, SEXP,
                      SEXP, SEXP, SEXP, SEXP,
                      SEXP, SEXP, SEXP, SEXP,
                      SEXP, SEXP);
extern SEXP entryPred(SEXP, SEXP, SEXP, SEXP,
                      SEXP, SEXP, SEXP, SEXP,
                      SEXP, SEXP, SEXP, SEXP,
                      SEXP, SEXP, SEXP, SEXP,
                      SEXP, SEXP, SEXP, SEXP,
                      SEXP, SEXP, SEXP, SEXP,
                      SEXP, SEXP, SEXP, SEXP,
                      SEXP, SEXP, SEXP, SEXP,
                      SEXP, SEXP, SEXP, SEXP,
                      SEXP, SEXP, SEXP, SEXP,
                      SEXP, SEXP, SEXP);
extern SEXP weightedStitchedHazard(SEXP, SEXP, SEXP, SEXP,
                                   SEXP, SEXP, SEXP, SEXP,
                                   SEXP, SEXP, SEXP, SEXP,
                                   SEXP, SEXP);
extern SEXP medianLogStitchedHazard(SEXP, SEXP, SEXP, SEXP,
                                    SEXP, SEXP, SEXP, SEXP,
                                    SEXP, SEXP, SEXP, SEXP,
                                    SEXP);
static const R_CallMethodDef CallEntries[] = {
    {"entryGrow", (DL_FUNC) &entryGrow, 26},
    {"entryPred", (DL_FUNC) &entryPred, 43},
    {"weightedStitchedHazard", (DL_FUNC) &weightedStitchedHazard, 14},
    {"medianLogStitchedHazard", (DL_FUNC) &medianLogStitchedHazard, 13},
    {NULL, NULL, 0}
};
void R_init_randomForestSGT(DllInfo *dll)
{
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
