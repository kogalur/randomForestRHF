#ifndef RF_TERM_OPS_H
#define RF_TERM_OPS_H
#include "terminal.h"
#include "shared/terminalBase.h"
void *makeTerminalDerived(void);
void  freeTerminalDerived(void *parent);
void stackRatio(Terminal *tTerm);
void unstackRatio(Terminal *tTerm);
void stackCOEObjects(Terminal *tTerm);
void unstackCOEObjects(Terminal *tTerm);
#endif 
