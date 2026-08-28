#ifndef RF_TERMINAL_H
#define RF_TERMINAL_H
typedef struct terminal Terminal;
struct terminal {
  struct terminalBase base;
  double mean;
  uint repMembrCount, oobMembrCount, ibgMembrCount, tstMembrCount;
  uint allMembrSize;
  uint *repMembrIndx, *ibgMembrIndx, *oobMembrIndx, *tstMembrIndx;
  double *ratio;
  double *nodeU;
  double *nodeV;
  double *coeHazard;
  double *coeCHF;
};
#endif
