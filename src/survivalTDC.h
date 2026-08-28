#ifndef RF_SURVIVAL_TDC_H
#define RF_SURVIVAL_TDC_H
#include "shared/terminalBase.h"
void calculateAllTerminalNodeOutcomesTDC(char mode, uint treeID, TerminalBase  *term);
void getAtRiskAndEventCount(uint treeID, TerminalSurvival *parent);
void getLocalRatio(uint treeID, TerminalSurvival *parent);
void getLocalHazard(uint treeID, TerminalSurvival *parent);
void getLocalNelsonAalen(uint treeID, TerminalSurvival *parent);
void getNelsonAalen(uint treeID, TerminalSurvival *parent);
void getHazard(uint treeID, TerminalSurvival *parent);
void getPseudoHazard5(uint treeID, TerminalSurvival *parent);
void getHeadCorrections(uint treeID, TerminalSurvival *parent);
void getTailCorrections(uint treeID, TerminalSurvival *parent);
void getPseudoHazard2(uint treeID, TerminalSurvival *parent);
void getNelsonAalenSmooth(uint treeID, TerminalSurvival *parent);
void getRatio(uint treeID, TerminalSurvival *parent);
void getCOEObjects(uint treeID, TerminalSurvival *parent);
void mapLocalToTimeInterest(uint treeID,
                            TerminalSurvival *parent,
                            double *genericLocal,
                            double *genericGlobal);
void mapLocalToTimeInterestRaw(uint              treeID,
                               TerminalSurvival *parent,
                               double   *genericLocal,
                               double   *genericGlobal);
void getVectorDelta(uint size, double *inValue, double *outValue);
void assignAllTerminalNodeOutcomesTDC(char mode,
                                      uint treeID,
                                      TerminalBase  *term);
#endif
