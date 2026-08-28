#ifndef RF_PROCESS_ENSEMBLE_H
#define RF_PROCESS_ENSEMBLE_H
void processEnsembleInSitu(char mode, uint treeID);
void updateEnsemble (char mode, uint treeID);
void updateEnsembleGrow(char mode, uint treeID);
void updateEnsemblePred(char mode, uint treeID);
void normalizeEnsembleEstimates(char mode);
void populateEnsembleIds(char mode);
void summarizeFaithfulBlockPerformance (char        mode,
                                        uint        b,
                                        uint        blockID,
                                        double   ***blkEnsembleCLSnum,
                                        double    **blkEnsembleRGRnum,
                                        double     *blkEnsembleDen,
                                        double    **responsePtr,
                                        double   ***perfCLSblk,
                                        double    **perfRGRblk);
void getPerformance(uint      serialTreeID,
                    char      mode,
                    uint      obsSize,
                    double  **responsePtr,
                    double    *denomPtr,
                    double  ***outcomeCLS,
                    double   **outcomeRGR,
                    double  **perfCLSptr,
                    double   *perfRGRptr);
char getPerfFlag (char mode, uint serialTreeID);
void calculateRiskCore(char mode, char wMode, uint trimIndex, char coeOOBRiskPrecomputed);
void calculateRiskRaw(char mode);
void finalizePathDomainOutputs(char mode);
#endif
