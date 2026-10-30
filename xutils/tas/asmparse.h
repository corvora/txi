#ifndef ASMPARSE_H
#define ASMPARSE_H
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct asminst {
    char op[128];
    char a[128];
    char b[128];
    int cnt;
    char lbl[128];
    int ilbl;
};

struct asminst* parseinst(const char*);
#endif