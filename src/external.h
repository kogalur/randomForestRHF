// *** THIS FILE IS AUTO GENERATED. DO NOT EDIT IT ***
#ifndef RF_EXTERNAL_H
#define RF_EXTERNAL_H

#include "shared/globalCore.h"
#include "shared/sampling.h"
#include "shared/terminalBase.h"
#include "descriptor.h"
#include "augmentation.h"
#include "node.h"
extern double    *SG_yHatOut_;
extern double   **SG_yHatOutPtr;
extern double   *SG_cpuTime_;
extern double *SG_ibg_tree_risk_;
extern double *SG_oob_tree_risk_;
extern double *SG_ibg_tree_risk_raw_;
extern double *SG_oob_tree_risk_raw_;
extern double   **SG_ibg_tree_risk_ptr;
extern double   **SG_oob_tree_risk_ptr;
extern double   **SG_ibg_tree_risk_raw_ptr;
extern double   **SG_oob_tree_risk_raw_ptr;
extern uint     *SG_MEMB_ID_;
extern uint     *SG_BOOT_CT_;
extern uint     **SG_MEMB_ID_ptr;
extern uint     **SG_BOOT_CT_ptr;
extern double   *SG_oobEnsembleKHZ_;
extern double   *SG_fullEnsembleKHZ_;
extern double   *SG_oobEnsembleCHF_;
extern double   *SG_fullEnsembleCHF_;
extern double   *SG_oobEnsembleHRW_;
extern double   *SG_fullEnsembleHRW_;
extern uint     *SG_ensembleID_;
extern uint   *SG_termHazardTimeIndex_;
extern uint   *SG_termHazardTimeCount_;
extern double  **SG_oobEnsembleKHZptr;
extern double  **SG_oobEnsembleKHZnum;
extern double  **SG_fullEnsembleKHZptr;
extern double  **SG_fullEnsembleKHZnum;
extern double  **SG_oobEnsembleCHFptr;
extern double  **SG_oobEnsembleCHFnum;
extern double  **SG_fullEnsembleCHFptr;
extern double  **SG_fullEnsembleCHFnum;
extern double  **SG_oobEnsembleHRWptr;
extern double  **SG_oobEnsembleHRWnum;
extern double  **SG_fullEnsembleHRWptr;
extern double  **SG_fullEnsembleHRWnum;
extern double  *SG_oobRisk_;
extern double  *SG_fullRisk_;
extern double  *SG_oobWCase_;
extern double  *SG_fullWCase_;
extern double  *SG_absWCaseTimeLeft_;
extern double  *SG_absWCaseTimeRight_;
extern double  *SG_oobRiskRaw_;
extern double  *SG_fullRiskRaw_;
extern uint   RF_totalNodeCount;
extern uint  *SG_treeID_;
extern uint  *SG_nodeID_;
extern uint  *SG_nodeSZ_;
extern uint  *SG_brnodeID_;
extern uint  *SG_prnodeID_;
extern uint   *SG_parmID_;
extern double *SG_contPT_;
extern uint   *SG_mwcpSZ_;
extern uint   *SG_mwcpCT_;
extern uint   *SG_mwcpPT_;
extern uint   *SG_fsrecID_;
extern double   *SG_nodeStat_;
extern uint     *SG_bsf_;
extern double  *SG_yBar_;
extern double  *SG_yStar_;
extern uint    *SG_rmbrTNodeCT_;
extern uint    *SG_imbrTNodeCT_;
extern uint    *SG_ombrTNodeCT_;
extern uint    *SG_rmbrTNodeID_;
extern uint    *SG_imbrTNodeID_;
extern uint    *SG_ombrTNodeID_;
extern uint    *SG_IBG_SZ_CASE_;
extern uint    *SG_OOB_SZ_CASE_;
extern double *SG_node_risk_;
extern double *SG_node_risk_raw_;
extern double **SG_node_risk_ptr;
extern double **SG_node_risk_raw_ptr;
extern uint   **SG_rmbrTNodeCT_ptr;
extern uint   **SG_imbrTNodeCT_ptr;
extern uint   **SG_ombrTNodeCT_ptr;
extern uint  ***SG_rmbrTNodeID_ptr;
extern uint  ***SG_imbrTNodeID_ptr;
extern uint  ***SG_ombrTNodeID_ptr;
extern double *SG_termNelsonAalen_;
extern double *SG_termHazard_;
extern double *SG_nodeU_;
extern double *SG_nodeV_;
extern double *SG_nodeCOE_;
extern double *SG_nodeCumulativeCOE_;
extern double *SG_coeHazardTreeIBG_;
extern double *SG_coeHazardTreeOOB_;
extern double *SG_coeCHFTreeIBG_;
extern double *SG_coeCHFTreeOOB_;
extern double ***SG_termNelsonAalen_ptr;
extern double ***SG_termHazard_ptr;
extern double ***SG_nodeU_ptr;
extern double ***SG_nodeV_ptr;
extern double ***SG_nodeCOE_ptr;
extern double ***SG_nodeCumulativeCOE_ptr;
extern double ***SG_coeHazardTreeIBG_ptr;
extern double ***SG_coeHazardTreeOOB_ptr;
extern double ***SG_coeCHFTreeIBG_ptr;
extern double ***SG_coeCHFTreeOOB_ptr;
extern uint **SG_treeID_ptr;
extern uint **SG_nodeID_ptr;
extern uint **SG_nodeSZ_ptr;
extern uint **SG_brnodeID_ptr;
extern uint **SG_prnodeID_ptr;
extern uint   **SG_parmID_ptr;
extern double **SG_contPT_ptr;
extern uint   **SG_mwcpSZ_ptr;
extern uint    *SG_mwcpCT_ptr;
extern uint   **SG_mwcpPT_ptr;
extern uint   **SG_fsrecID_ptr;
extern double **SG_nodeStat_ptr;
extern uint   **SG_bsf_ptr;
extern uint    *SG_bootstrapSizeCase;
extern char    **SG_bootMembershipFlagCase;
extern char    **SG_oobMembershipFlagCase;
extern uint     *SG_oobSizeCase;
extern uint     *SG_ibgSizeCase;
extern uint    **SG_oobMembershipIndexCase;
extern uint    **SG_ibgMembershipIndexCase;
extern uint     SG_xSizeAugm;
extern double **SG_observationInAugm;
extern double **SG_fobservationInAugm;
extern uint     SG_optLocal;
extern double  *SG_coeTrim;
extern uint     SG_coeTrimSize;
extern uint     SG_coeTrimIndex;
extern uint    *SG_coeTrimIndex_;
extern double  *SG_coeTrimRiskOOB_;
extern uint     SG_bsfOrder;
extern double (*updateBetaGeneric) (uint,
                             uint,
                             double,
                             double*,
                             double**,
                             double*);
extern double (*updateGradientResidual) (uint,
                                  uint,
                                  uint,
                                  double,
                                  double,
                                  double,
                                  double**,
                                  double**,
                                  double*);
extern AugmentationObj* ((*getAugmentationObjGeneric) (AugmentationObjCommon *objCommon, uint treeID, Node *parent));
extern AugmentationObjCommon* ((*getAugmentationObjCommonGeneric) (uint n,
                                                            uint p,
                                                            double **xArrayIn,
                                                            char    *permIn,
                                                            double **yArrayIn));
extern void (*freeAugmentationObjCommonGeneric) (AugmentationObjCommon *obj);
extern void (*getAugmentationObjCommonGenericTest) (AugmentationObjCommon *obj,
                                             uint     fn,
                                             double **fxArrayIn,
                                             double **fyArrayIn);
extern void (*freeAugmentationObjCommonGenericTestOnly) (AugmentationObjCommon *obj);
extern uint    SG_splitRule;
extern uint    SG_hcut;
extern uint    SG_lotSize;
extern uint    SG_lotLag;
extern uint    SG_lotStrikeout;
extern uint     **SG_OMBR_ID_ptr;
extern uint     **SG_TN_OCNT_ptr;
extern ulong    *SG_offsetTree;
extern ulong    *SG_offsetCT;
extern ulong    *SG_offsetID_rmbr;
extern ulong    *SG_offsetID_imbr;
extern ulong    *SG_offsetID_ombr;
extern AugmentationObjCommon *SG_augmObjCommon;
extern uint      RF_xWeightType;
extern uint     *RF_xWeightSorted;
extern uint      RF_xWeightDensitySize;
extern DistributionObj *(*stackRandomCovariates) (uint, NodeBase*, uint);
extern void (*unstackRandomCovariates) (uint, DistributionObj*);
extern char (*selectRandomCovariates) (uint, NodeBase*, DistributionObj*, uint, char*, uint*, uint*);
extern double  *SG_allTimeInterest;
extern uint     SG_allTimeInterestSize;
extern double  *SG_allTimeInterestDelta;
extern char     SG_timeInterestPassFlag;
extern uint    *SG_timeInterestIntervalCount;
extern uint   **SG_timeInterestIntervalIndex;
extern double  *SG_timeInterestDelta;
extern uint    *SG_timeInterestSubjTailIndex;
extern uint    *SG_subjTailCaseMap;
extern uint    *SG_timeInterestSubjTailIndexIBG;
extern uint    *SG_timeInterestSubjTailIndexOOB;
extern uint    *SG_fsubjIn;
extern uint     SG_fsubjSize;
extern uint    *SG_fsubjSlot;
extern uint    *SG_fsubjSlotCount;
extern uint   **SG_fsubjList;
extern uint    *SG_fcaseMap;
extern uint    *SG_fsubjMap;
extern uint     SG_fsubjCount;
extern uint    *SG_ftimeInterestIntervalCount;
extern uint   **SG_ftimeInterestIntervalIndex;
extern uint    *SG_ftimeInterestSubjTailIndex;
extern uint    *SG_fsubjTailCaseMap;
extern char (*getVariance) (uint, uint*, double*, double*, double*);
extern DescriptorObj *SG_headDO;
extern uint SG_tcpPort;
extern uint SG_tcpTimeOut;
#ifdef _OPENMP
extern omp_lock_t   SG_lockDO;
#endif

#endif
