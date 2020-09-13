#include <stdlib.h>
#include "Vmain.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vmain* cpu = new Vmain;
    while(!Verilated::gotFinish()) {
        cpu->CLK = 0;
        cpu->eval();
        cpu->CLK = 1;
        cpu->eval();
    }
}
