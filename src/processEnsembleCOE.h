#ifndef RF_PROCESS_ENSEMBLE_COE_H
#define RF_PROCESS_ENSEMBLE_COE_H
#define SG_COE_TRIM_INDEX_MEDIAN_FALLBACK 0U
#define SG_COE_TRIM_MEDIAN_FALLBACK_THRESHOLD 0.50
uint firstTimeInterestGreater(double value);
uint firstTimeInterestGreaterOrEqual(double value);
void updateCOEObjectsGrow(char mode, uint treeID);
void updateCOEObjectsPred(char mode, uint treeID);
void populateCOEEnsembleSupport(char mode, uint subjIndex);
double getCOEOOBRiskObjective(uint *subjectCount);
double getCOEOOBRiskObjectiveForTrim(uint trimIndex,
                                     uint *subjectCount);
uint selectCOETrimByOOBRiskAllTrim(double *objective,
                                   uint *supportedSubjectCount,
                                   double *selectedSubjectRisk);
void validateCOEOOBRiskObjectiveAllTrim(double *referenceObjective,
                                        uint referenceSubjectCount,
                                        uint referenceTrimIndex);
void getCOEEnsembleAggregateAllSubjects(char mode, uint subjCount, uint trimIndex);
double getCOEOOBSubjectRiskExactOverlap(uint subjIndex,
                                        uint trimIndex,
                                        uint *oobTreeIndex,
                                        double *treeValue);
#endif
