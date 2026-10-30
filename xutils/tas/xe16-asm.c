/*
    xe16-asm - Opcode converter for tas with asmparse
    Copyright (C) 2025 CodeX
    Redistribution of this file in any form (incl. compiled) is highly PROHIBITED. 
*/


#include <inttypes.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#ifdef ARCH_INT
#undef ARCH_INT
#endif
#ifndef ARCH_INT
#define ARCH_INT uint16_t
#endif
#ifdef ARCH_OFF
#undef ARCH_OFF
#endif
#ifndef ARCH_OFF
#define ARCH_OFF 10
#endif
#include "opcode.h"
#include "asmparse.h"
#include "label.h"

const char* regs[] = {"flg", "g01", "g02", "g03", "g04", "g05", "g06", "g07", "g08", "g09", "g10", "g11", "g12", "g13", "g14", "g15", "g16", "rs", "ad", "ap", NULL};
const char* insts[] = {"mov", "add", "sub", "mul", "div", "and", "not", "or", "xor", "inp", "outp", "jmp", "cmp", "read", "write", "je", "jne", "jg", "js", "jc", "push", "pop", "sc", "cc", "cls", "hlt", "shl", "shr", "jnc", "mod", "nop", NULL};
struct label labels[1024];
int labelidx = 0;
enum dtypes { dreg = 0, draw = 1 };

int stridx(const char* arr[], const char* str) {
    int idx = 0;
    int fidx = -1;
    const char* tmp = arr[idx];
    while (tmp) {
        if (!tmp) break;
        if (strcmp(tmp, str) == 0) {
            fidx = idx;
            break;
        }
        idx++;
        tmp = arr[idx];
    }
    return fidx;
}

int lblidx(const char* str) {
    for (int i = 0; i < 1024; i++) {
        if (labels[i].on) {
            if (strcmp(labels[i].name, str) == 0) {
                return i;
            }
        }
    }
    return -1;
}

int cnt = 0;

void setoffset(int off) {
    cnt = off;
}
int getoffset() {
    return cnt;
}

struct opcode* processasm(const struct asminst* inst) {
    if (!inst) {
        printf("tas: xe16-asm: Input instruction is null.\n");
        return NULL;
    }
    struct opcode* opc = (struct opcode*)calloc(1, sizeof(struct opcode));
    if (!opc) {
        printf("tas: xe16-asm: Cannot allocate memory for opcode buffer.\n");
        return NULL;
    }
    if (inst->ilbl) {
        if (labelidx < 1024) {
            labels[labelidx].on = (ARCH_INT)1;
            strncpy(labels[labelidx].name, inst->lbl, 127);
            labels[labelidx].addr = (ARCH_INT)((cnt));
            labelidx++;
            opc->label = (ARCH_INT)1;
        } else {
            printf("tas: xe16-asm: Label count cannot exceed 1023.\n");
            free(opc);
            return NULL;
        }
    } else {
        opc->label = (ARCH_INT)0;
    }
    if (opc->label) {
        return opc;
    }
    int idx = -1;
    switch (inst->cnt) {
        case 1:
            idx = stridx(insts, inst->op);
            if (idx < 0) {
                printf("tas: xe16-asm: Instruction doesn't exist.\n");
                free(opc);
                return NULL;
            } else {
                opc->op = (ARCH_INT)idx;
            }
            break;
        case 2:
            idx = stridx(insts, inst->op);
            if (idx < 0) {
                printf("tas: xe16-asm: Instruction doesn't exist.\n");
                free(opc);
                return NULL;
            } else {
                opc->op = (ARCH_INT)idx;
            }

            idx = stridx(regs, inst->a);
            if (idx < 0) {
                if ((sscanf(inst->a, "%" SCNu16, &(opc->a))) != 1) {
                    idx = lblidx(inst->a);
                    if (idx < 0) {
                        free(opc);
                        printf("tas: xe16-asm: Argument A is malformed.\n");
                        return NULL;
                    } else {
                        opc->dta = (ARCH_INT)draw;
                        opc->a = (ARCH_INT)labels[idx].addr;
                    }
                } else {
                    opc->dta = (ARCH_INT)draw;
                };
            } else {
                opc->a = (ARCH_INT)idx;
                opc->dta = (ARCH_INT)dreg;
            }
            break;
        case 3:
            idx = stridx(insts, inst->op);
            if (idx < 0) {
                printf("tas: xe16-asm: Instruction doesn't exist.\n");
                free(opc);
                return NULL;
            } else {
                opc->op = (ARCH_INT)idx;
            }

            idx = stridx(regs, inst->a);
            if (idx < 0) {
                if ((sscanf(inst->a, "%" SCNu16, &(opc->a))) != 1) {
                    idx = lblidx(inst->a);
                    if (idx < 0) {
                        free(opc);
                        printf("tas: xe16-asm: Argument A is malformed.\n");
                        return NULL;
                    } else {
                        opc->dta = (ARCH_INT)draw;
                        opc->a = (ARCH_INT)labels[idx].addr;
                    }
                } else {
                    opc->dta = (ARCH_INT)draw;
                };
            } else {
                opc->a = (ARCH_INT)idx;
                opc->dta = (ARCH_INT)dreg;
            }

            idx = stridx(regs, inst->b);
            if (idx < 0) {
                if ((sscanf(inst->b, "%" SCNu16, &(opc->b))) != 1) {
                    idx = lblidx(inst->b);
                    if (idx < 0) {
                        free(opc);
                        printf("tas: xe16-asm: Argument B is malformed.\n");
                        return NULL;
                    } else {
                        opc->dtb = (ARCH_INT)draw;
                        opc->b = (ARCH_INT)labels[idx].addr;
                    }
                } else {
                    opc->dtb = (ARCH_INT)draw;
                };
            } else {
                opc->b = (ARCH_INT)idx;
                opc->dtb = (ARCH_INT)dreg;
            }
            break;
        default:
            printf("tas: xe16-asm: Malformed instruction.\n");
            free(opc);
            return NULL;
    }
    cnt++;
    return opc;
}