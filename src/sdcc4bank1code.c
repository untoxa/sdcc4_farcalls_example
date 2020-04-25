#include <stdio.h>

const unsigned char const hello1[] = "bank1";

int some_bank1_proc(int a, int b, int c) __banked {
    printf("  in %s\n", hello1);
    return a + b + c;
}