#ifndef XE16_ASM_H
#define XE16_ASM_H
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


struct opcode* processasm(const struct asminst*);
void setoffset(int);
int getoffset();
#endif