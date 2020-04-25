#include <stdio.h>

int some_bank2_proc(int a, int b, int c) __banked {
    printf("  in bank2\n");
    return a + b + c;
}