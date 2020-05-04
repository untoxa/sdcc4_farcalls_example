#include <stdio.h>

const unsigned char const hello2[] = "bank2";

void some_local_proc_in_bank_2(int a) {
    printf("    locb2: %d\n", a);
}

int some_bank2_proc(int a, int b, int c) __banked {
    printf("  in %s\n", hello2);
    some_local_proc_in_bank_2(b);
    return a + b + c;
}

int some_bank2_proc_wrapper(int a, int b, int c) __nonbanked {
    return some_bank2_proc(a, b, c);
}