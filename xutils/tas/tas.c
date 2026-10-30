/*
    tas - Tiny Assembler for Xenon series
    Copyright (C) 2025 CodeX
    Redistribution of this file in any form (incl. compiled) is highly PROHIBITED. 
*/
#ifndef CONFIG_DONE
#define CONFIG_XE16
#endif
#ifdef CONFIG_XE16
#include "xe16-asm.h"
ARCH_INT endian_swap(ARCH_INT n) {
    ARCH_INT tmp = ((n >> 8) & 0xff) | (n << 8);
    return tmp;
}
#endif
#include "asmparse.h"
#include "opcode.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

enum endian_states { ebig = 0, elittle = 1 };
int endianness() {
    uint16_t b16 = 1;
    uint8_t b8 = *((uint8_t*)&b16);
    if (b8 == 1) {
        return elittle;
    } else {
        return ebig;
    }
}

int main(int argc, char** argv) {
    if (argc == 0) {
        printf("tas: Malformed usage. Please run tas directly without tampering argv (but keep it empty) to get help.\n");
        return 1;
    }
    if (argc == 1) {
        printf("tas - Tiny Assembler, (C) CodeX S/C 2025\n");
        printf("Usage: \n");
        printf("\t%s <asm_file> <out_file> <binary_origin>\n", argv[0]);
        return 1;
    }
    if (argc != 4) {
        printf("tas: Malformed usage. Please run tas directly to get help.\n");
        return 1;
    }
    FILE* input = fopen(argv[1], "rb");
    if (!input) {
        perror("tas: Cannot open input file");
        return 1;
    }
    FILE* output = fopen(argv[2], "wb");
    if (!output) {
        perror("tas: Cannot open output file");
        fclose(input);
        return 1;
    }
    int origin = atoi(strdup(argv[3]));
    fseek(input, 0, SEEK_END);
    size_t size = ftell(input);
    if (size == 0) {
        fclose(output);
        fclose(input);
        return 0;
    }
    size++;
    fseek(input, 0, SEEK_SET);
    char* buffer = calloc(size, sizeof(char));
    struct asminst* asins;
    struct opcode* opc;
    ARCH_INT opcode[5] = {0, 0, 0, 0, 0}; 
    #ifdef CONFIG_LABELDUMP
    printf("Labels\n===========\n");
    #endif
    setoffset(origin);
    while (fgets(buffer, size, input)) {
        char* p = strchr(buffer, '\n');
        if (p) *p = 0;
        asins = parseinst(buffer);
        if (!asins) {
            printf("tas: preprocess: Cannot parse instruction, probably unknown.\n");
            free(buffer);
            fclose(input);
            fclose(output);
            return 1;
        }
        if (asins->ilbl) {
            #ifdef CONFIG_LABELDUMP
            printf("%s -> %d\n", asins->lbl, getoffset());
            #endif
            opc = processasm(asins);
            if (!opc) {
                printf("tas: preprocess: Cannot create opcode packet, is instruction intact?\n");
                free(buffer);
                free(asins);
                fclose(input);
                fclose(output);
                return 1;
            }
            free(opc);
        } else {
            if (asins->cnt) setoffset(getoffset() + ARCH_OFF);
        }
        *buffer = 0;
        free(asins);
    }
    fseek(input, 0, SEEK_SET);
    setoffset(origin);
    while (fgets(buffer, size, input)) {
        char* p = strchr(buffer, '\n');
        if (p) *p = 0;
        asins = parseinst(buffer);
        if (!asins) {
            printf("tas: Cannot parse instruction, probably unknown.\n");
            free(buffer);
            fclose(input);
            fclose(output);
            return 1;
        }
        if (asins->cnt == 0 || asins->ilbl) {
            continue;
        }
        opc = processasm(asins);
        if (!opc) {
            printf("tas: Cannot create opcode packet, is instruction intact? off: %d\n", getoffset());
            free(buffer);
            free(asins);
            fclose(input);
            fclose(output);
            return 1;
        }
        opcode[0] = (ARCH_INT)opc->op;
        opcode[1] = (ARCH_INT)opc->dta;
        opcode[2] = (ARCH_INT)opc->a;
        opcode[3] = (ARCH_INT)opc->dtb;
        opcode[4] = (ARCH_INT)opc->b;
        if (endianness() == elittle) {
            for (int i = 0; i < 5; i++) {
                opcode[i] = (ARCH_INT)endian_swap(opcode[i]);
            }
        }
        if (!asins->ilbl) fwrite(opcode, sizeof(ARCH_INT), 5, output);
        *buffer = 0;
        free(opc);
        free(asins);
    }

    fclose(input);
    fclose(output);
    return 0;
}