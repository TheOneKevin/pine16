CC = g++
CFLAGS = -O3
VERILATOR = verilator
VFLAGS = --trace -Wno-STMTDLY -Wno-COMBDLY -Wno-CASEINCOMPLETE -Wno-PINMISSING -Wno-WIDTH
VERILATOR_ROOT = /usr/local/share/verilator/

OBJ_DIR = obj_main

SRCS = machine/verilator/main.cpp $(VERILATOR_ROOT)/include/verilated.cpp $(VERILATOR_ROOT)/include/verilated_vcd_c.cpp

all: build/bench

build/bench: $(SRCS) Vmain__ALL.a
	$(CC) -I"build/$(OBJ_DIR)" -I"$(VERILATOR_ROOT)/include" $(CFLAGS) $(SRCS) build/$(OBJ_DIR)/Vmain__ALL.a -o build/bench

Vmain__ALL.a:
	$(VERILATOR) --Mdir build/$(OBJ_DIR) -cc main $(VFLAGS)
	cd build/$(OBJ_DIR); make -f Vmain.mk

clean:
	rm -rf build/$(OBJ_DIR)
	rm build/bench
