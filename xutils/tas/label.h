#ifndef LABEL_H
#define LABEL_H
#include <stdint.h>
#ifndef ARCH_INT
#error "ARCH_INT not defined."
#endif
struct label {
    char name[128];
    ARCH_INT addr;
    int on;
};
#endif