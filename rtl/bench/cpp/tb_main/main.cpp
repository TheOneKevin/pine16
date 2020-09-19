#include <stdlib.h>
#include "obj_harness/Vharness.h"
#include "verilated.h"

SData address;
SData mem[1024] = {
    0x0312, 0x0200, 0x0702, 0x0300, 0x2112
};

// HI: 03 02 07 03 21
// LO: 12 00 02 00 12

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vharness* cpu = new Vharness;
    for(int i = 0; i < 100; i++) {
        
        cpu -> CLK = 0;
        if(!cpu -> oe) { cpu->din = mem[address]; }
        cpu->eval(); // 1 to 0

        cpu -> CLK = 1;
        cpu->eval(); // 0 to 1
        if(cpu -> ale) address = cpu->ad0;

        //printf("%d %04X\n", address, cpu->harness__DOT__u0__DOT__mem__DOT__latched_din);
        printf("r0: %d, r1: %d\n",
            cpu->harness__DOT__u0__DOT__execute__DOT__regs__DOT__regs[0],
            cpu->harness__DOT__u0__DOT__execute__DOT__regs__DOT__regs[1]);
    }
}
