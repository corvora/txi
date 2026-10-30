#ifndef OPCODE_H
#define OPCODE_H
#include <stdint.h>
#ifndef ARCH_INT
#error "ARCH_INT not defined."
#endif
struct opcode {
    ARCH_INT op;
    ARCH_INT dta;
    ARCH_INT a;
    ARCH_INT dtb;
    ARCH_INT b;
    int label;
};
struct rawopcode {
    ARCH_INT op;
    ARCH_INT dta;
    ARCH_INT a;
    ARCH_INT dtb;
    ARCH_INT b;
};
#endif