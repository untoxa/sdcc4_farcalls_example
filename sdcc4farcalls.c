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

// no need for __banked here, bank0 is always on
int some_bank0_proc(int a, int b, int c) {
    printf("  in bank0\n");
    return a + b + c;
} 

void main() {
    printf("far call example:\n");    
    SET_ROM_BANK(1);
    printf("result: 0x%x\n", (int)some_bank2_proc(16, 32, 64) + some_bank0_proc(0, 8, 128) + some_bank1_proc(1, 2, 4));
}
