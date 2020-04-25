#include <gb/gb.h>
#include <stdio.h>

// we MUST set the correct value to the _current_bank crt variable when 
// switching banks manually, to have them back after call. 
// you also need to do this in the switching functions if you are using 
// non-intrinsic spaces
extern BYTE _current_bank; // defined in crt.s
#define SET_ROM_BANK(n) ((_current_bank = (n)), SWITCH_ROM_MBC1((n)))

#include "sdcc4bank1code.h"
#include "sdcc4bank2code.h"

// there is no compiler magic for pointers, so we need to declare a prototype
// with first two extra dummy int parameters to make a correct stack.
// unfortuanely __banked keyword seem to do nothing for function pointers
typedef int (* my_far_proc_t)(int __dummy0, int __dummy1, int a, int b, int c);

// no need for __banked here, bank0 is always on
int some_bank0_proc(int a, int b, int c) {
    printf("  in bank0\n");
    return a + b + c;
} 

my_far_proc_t farproc_ptr = (my_far_proc_t)&some_bank2_proc;

void main() {
    SET_ROM_BANK(1);
    // hello2 contains garbage, because bank1 is active, not bank2
    printf("hello2: '%s'\n", hello2);
    SET_ROM_BANK(2);
    // now hello2 data is in place
    printf("hello2: '%s'\n", hello2);
    printf("far call example:\n");    
    printf("result: 0x%x\n", (int)some_bank2_proc(16, 32, 64) + some_bank0_proc(0, 8, 128) + some_bank1_proc(1, 2, 4));
    // after far calls, bank should be restored:
    printf("hello2: '%s'\n", hello2);
    // yes! we are in bank2, no need to switch to call some_bank2_proc by pointer 
    // we MUST switch banks manually when calling __banked function by pointer!
    printf("b%d byptr: %d\n", (int)_current_bank, (int)farproc_ptr(0, 0, 1, 2, 3));
}
