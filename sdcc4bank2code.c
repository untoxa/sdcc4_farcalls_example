#include <stdio.h>

const unsigned char const hello2[] = "bank2";

int some_bank2_proc(int a, int b, int c) __banked {
    printf("  in %s\n", hello2);
    return a + b + c;
}