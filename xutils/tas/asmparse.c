/*
    asmparse - Assembly Parser
    Copyright (C) 2025 CodeX
    Redistribution of this file in any form (incl. compiled) is highly PROHIBITED. 
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "asmparse.h"

struct asminst* parseinst(const char* inst) {
    char* copy = strdup(inst);
    if (!copy) {
        printf("tas: asmparse: Cannot create a copy of the input string.\n");
        return NULL;
    }
    char *pointer = strchr(copy, ';');
    if (pointer) *pointer = 0;
    struct asminst* insts = (struct asminst*)calloc(1, sizeof(struct asminst));
    if (!insts) {
        printf("tas: asmparse: Cannot allocate memory for instruction buffer.\n");
        free(copy);
        return NULL;
    }
    pointer = strchr(copy, ':');
    insts->op[0] = insts->a[0] = insts->b[0] = insts->cnt = insts->ilbl = insts->lbl[0] = 0;
    if (pointer) {
        *pointer = 0;
        if (strlen(copy) > 127) {
            printf("tas: asmparse: Name lengths cannot exceed 127 chars.\n");
            free(copy);
            free(insts);
            return NULL;
        }
        strncpy(insts->lbl, copy, strlen(copy));
        insts->ilbl = 1;
        free(copy);
        return insts;
    }
    insts->cnt = sscanf(copy, "%127s %127[^, ] , %127s", insts->op, insts->a, insts->b);
    switch (insts->cnt) {
        case -1:
            insts->op[0] = insts->a[0] = insts->b[0] = insts->cnt = insts->ilbl = insts->lbl[0] = 0;
        case 1:
            break;
        case 2:
            break;
        case 3:
            break;
        default:
            printf("tas: asmparse: Malformed instruction.\n");
            free(copy);
            free(insts);
            return NULL;
    }
    free(copy);
    return insts;
}
