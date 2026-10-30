#include <stdio.h>
#ifndef CONFIG_DONE
#define CONFIG_XE16
#endif
#ifdef CONFIG_XE16
#include "../tas/xe16-asm.h"
ARCH_INT endian_swap(ARCH_INT n) {
    ARCH_INT tmp = ((n >> 8) & 0xff) | (n << 8);
    return tmp;
}
#endif

int main(int argc, char** argv) {
    if (argc == 0) {
        printf("tpd: Malformed usage. Please run tpd directly without tampering argv (but keep it empty) to get help.\n");
        return 1;
    }
    if (argc == 1) {
        printf("tpd - File Padder, (C) CodeX S/C 2025\n");
        printf("Usage: \n");
        printf("\t%s <in_file> <out_file>\n", argv[0]);
        return 1;
    }
    if (argc != 3) {
        printf("tpd: Malformed usage. Please run tpd directly to get help.\n");
        return 1;
    }
    FILE* input = fopen(argv[1], "rb");
    if (!input) {
        perror("tpd: Cannot open input file");
        return 1;
    }
    FILE* output = fopen(argv[2], "wb");
    if (!output) {
        perror("tpd: Cannot open output file");
        fclose(input);
        return 1;
    }
    fseek(input, 0, SEEK_END);
    size_t size = ftell(input);
    fseek(input, 0, SEEK_SET);
    size_t add = (size % 5) ? (5 - (size % 5)) : 0;
    for (size_t i = 0; i < size; i++) {
        fputc(fgetc(input), output);
    }
    for (size_t i = 0; i < add; i++) {
        fputc(0, output);
    }
    fclose(output);
    fclose(input);
    return 0;
}