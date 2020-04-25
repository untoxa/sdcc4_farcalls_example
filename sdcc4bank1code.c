#include <stdio.h>

int some_bank1_proc(int a, int b, int c) __banked {
    printf("  in bank1\n");
    return a + b + c;
}