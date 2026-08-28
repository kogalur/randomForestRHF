#include "shared/globalCore.h"
#include "shared/sampling.h"
#include "shared/terminalBase.h"
#include "descriptor.h"
#include "augmentation.h"
#include "node.h"
double    *SG_yHatOut_;
double   **SG_yHatOutPtr;
double   *SG_cpuTime_;
double *SG_ibg_tree_risk_;
double *SG_oob_tree_risk_;
double *SG_ibg_tree_risk_raw_;
double *SG_oob_tree_risk_raw_;
double   **SG_ibg_tree_risk_ptr;
double   **SG_oob_tree_risk_ptr;
double   **SG_ibg_tree_risk_raw_ptr;
double   **SG_oob_tree_risk_raw_ptr;
uint     *SG_MEMB_ID_;
uint     *SG_BOOT_CT_;
uint     **SG_MEMB_ID_ptr;
uint     **SG_BOOT_CT_ptr;
double   *SG_oobEnsembleKHZ_;
double   *SG_fullEnsembleKHZ_;
double   *SG_oobEnsembleCHF_;
double   *SG_fullEnsembleCHF_;
double   *SG_oobEnsembleHRW_;
double   *SG_fullEnsembleHRW_;
uint     *SG_ensembleID_;
uint   *SG_termHazardTimeIndex_;
uint   *SG_termHazardTimeCount_;
double  **SG_oobEnsembleKHZptr;
double  **SG_oobEnsembleKHZnum;
double  **SG_fullEnsembleKHZptr;
double  **SG_fullEnsembleKHZnum;
double  **SG_oobEnsembleCHFptr;
double  **SG_oobEnsembleCHFnum;
double  **SG_fullEnsembleCHFptr;
double  **SG_fullEnsembleCHFnum;
double  **SG_oobEnsembleHRWptr;
double  **SG_oobEnsembleHRWnum;
double  **SG_fullEnsembleHRWptr;
double  **SG_fullEnsembleHRWnum;
double  *SG_oobRisk_;
double  *SG_fullRisk_;
double  *SG_oobWCase_;
double  *SG_fullWCase_;
double  *SG_absWCaseTimeLeft_;
double  *SG_absWCaseTimeRight_;
double  *SG_oobRiskRaw_;
double  *SG_fullRiskRaw_;
uint   RF_totalNodeCount;
uint  *SG_treeID_;
uint  *SG_nodeID_;
uint  *SG_nodeSZ_;
uint  *SG_brnodeID_;
uint  *SG_prnodeID_;
uint   *SG_parmID_;
double *SG_contPT_;
uint   *SG_mwcpSZ_;
uint   *SG_mwcpCT_;
uint   *SG_mwcpPT_;
uint   *SG_fsrecID_;
double   *SG_nodeStat_;
uint     *SG_bsf_;
double  *SG_yBar_;
double  *SG_yStar_;
uint    *SG_rmbrTNodeCT_;
uint    *SG_imbrTNodeCT_;
uint    *SG_ombrTNodeCT_;
uint    *SG_rmbrTNodeID_;
uint    *SG_imbrTNodeID_;
uint    *SG_ombrTNodeID_;
uint    *SG_IBG_SZ_CASE_;
uint    *SG_OOB_SZ_CASE_;
double *SG_node_risk_;
double *SG_node_risk_raw_;
double **SG_node_risk_ptr;
double **SG_node_risk_raw_ptr;
uint   **SG_rmbrTNodeCT_ptr;
uint   **SG_imbrTNodeCT_ptr;
uint   **SG_ombrTNodeCT_ptr;
uint  ***SG_rmbrTNodeID_ptr;
uint  ***SG_imbrTNodeID_ptr;
uint  ***SG_ombrTNodeID_ptr;
double *SG_termNelsonAalen_;
double *SG_termHazard_;
double *SG_nodeU_;
double *SG_nodeV_;
double *SG_nodeCOE_;
double *SG_nodeCumulativeCOE_;
double *SG_coeHazardTreeIBG_;
double *SG_coeHazardTreeOOB_;
double *SG_coeCHFTreeIBG_;
double *SG_coeCHFTreeOOB_;
double ***SG_termNelsonAalen_ptr;
double ***SG_termHazard_ptr;
double ***SG_nodeU_ptr;
double ***SG_nodeV_ptr;
double ***SG_nodeCOE_ptr;
double ***SG_nodeCumulativeCOE_ptr;
double ***SG_coeHazardTreeIBG_ptr;
double ***SG_coeHazardTreeOOB_ptr;
double ***SG_coeCHFTreeIBG_ptr;
double ***SG_coeCHFTreeOOB_ptr;
uint **SG_treeID_ptr;
uint **SG_nodeID_ptr;
uint **SG_nodeSZ_ptr;
uint **SG_brnodeID_ptr;
uint **SG_prnodeID_ptr;
uint   **SG_parmID_ptr;
double **SG_contPT_ptr;
uint   **SG_mwcpSZ_ptr;
uint    *SG_mwcpCT_ptr;
uint   **SG_mwcpPT_ptr;
uint   **SG_fsrecID_ptr;
double **SG_nodeStat_ptr;
uint   **SG_bsf_ptr;
uint    *SG_bootstrapSizeCase;
char    **SG_bootMembershipFlagCase;
char    **SG_oobMembershipFlagCase;
uint     *SG_oobSizeCase;
uint     *SG_ibgSizeCase;
uint    **SG_oobMembershipIndexCase;
uint    **SG_ibgMembershipIndexCase;
uint     SG_xSizeAugm;
double **SG_observationInAugm;
double **SG_fobservationInAugm;
uint     SG_optLocal;
double  *SG_coeTrim;
uint     SG_coeTrimSize;
uint     SG_coeTrimIndex;
uint    *SG_coeTrimIndex_;
double  *SG_coeTrimRiskOOB_;
uint     SG_bsfOrder;
double (*updateBetaGeneric) (uint,
                             uint,
                             double,
                             double*,
                             double**,
                             double*);
double (*updateGradientResidual) (uint,
                                  uint,
                                  uint,
                                  double,
                                  double,
                                  double,
                                  double**,
                                  double**,
                                  double*);
AugmentationObj* ((*getAugmentationObjGeneric) (AugmentationObjCommon *objCommon, uint treeID, Node *parent));
AugmentationObjCommon* ((*getAugmentationObjCommonGeneric) (uint n,
                                                            uint p,
                                                            double **xArrayIn,
                                                            char    *permIn,
                                                            double **yArrayIn));
void (*freeAugmentationObjCommonGeneric) (AugmentationObjCommon *obj);
void (*getAugmentationObjCommonGenericTest) (AugmentationObjCommon *obj,
                                             uint     fn,
                                             double **fxArrayIn,
                                             double **fyArrayIn);
void (*freeAugmentationObjCommonGenericTestOnly) (AugmentationObjCommon *obj);
uint    SG_splitRule;
uint    SG_hcut;
uint    SG_lotSize;
uint    SG_lotLag;
uint    SG_lotStrikeout;
uint     **SG_OMBR_ID_ptr;
uint     **SG_TN_OCNT_ptr;
ulong    *SG_offsetTree;
ulong    *SG_offsetCT;
ulong    *SG_offsetID_rmbr;
ulong    *SG_offsetID_imbr;
ulong    *SG_offsetID_ombr;
AugmentationObjCommon *SG_augmObjCommon;
uint      RF_xWeightType;
uint     *RF_xWeightSorted;
uint      RF_xWeightDensitySize;
DistributionObj *(*stackRandomCovariates) (uint, NodeBase*, uint);
void (*unstackRandomCovariates) (uint, DistributionObj*);
char (*selectRandomCovariates) (uint, NodeBase*, DistributionObj*, uint, char*, uint*, uint*);
double  *SG_allTimeInterest;
uint     SG_allTimeInterestSize;
double  *SG_allTimeInterestDelta;
char     SG_timeInterestPassFlag;
uint    *SG_timeInterestIntervalCount;
uint   **SG_timeInterestIntervalIndex;
double  *SG_timeInterestDelta;
uint    *SG_timeInterestSubjTailIndex;
uint    *SG_subjTailCaseMap;
uint    *SG_timeInterestSubjTailIndexIBG;
uint    *SG_timeInterestSubjTailIndexOOB;
uint    *SG_fsubjIn;
uint     SG_fsubjSize;
uint    *SG_fsubjSlot;
uint    *SG_fsubjSlotCount;
uint   **SG_fsubjList;
uint    *SG_fcaseMap;
uint    *SG_fsubjMap;
uint     SG_fsubjCount;
uint    *SG_ftimeInterestIntervalCount;
uint   **SG_ftimeInterestIntervalIndex;
uint    *SG_ftimeInterestSubjTailIndex;
uint    *SG_fsubjTailCaseMap;
char (*getVariance) (uint, uint*, double*, double*, double*);
DescriptorObj *SG_headDO;
uint SG_tcpPort;
uint SG_tcpTimeOut;
#ifdef _OPENMP
omp_lock_t   SG_lockDO;
#endif
