CC = g++
CFLAGS = -O3
VERILATOR = verilator
VFLAGS = -Ibench --public-flat-rw --trace -Wno-STMTDLY -Wno-COMBDLY -Wno-CASEINCOMPLETE -Wno-PINMISSING -Wno-WIDTH
VERILATOR_ROOT = /usr/local/share/verilator/

MODULE_NAME = harness
OBJ_DIR = obj_$(MODULE_NAME)

SRCS = bench/cpp/tb_main/main.cpp $(VERILATOR_ROOT)/include/verilated.cpp $(VERILATOR_ROOT)/include/verilated_vcd_c.cpp

all: bench

bench: $(SRCS) verilator
	$(CC) -I"build" -I"$(VERILATOR_ROOT)/include" -I"$(VERILATOR_ROOT)/include/vltstd" $(CFLAGS) $(SRCS) build/$(OBJ_DIR)/V$(MODULE_NAME)__ALL.cpp -o build/bench_$(MODULE_NAME)

verilator:
	$(VERILATOR) --Mdir build/$(OBJ_DIR) -cc $(MODULE_NAME) $(VFLAGS)
	cd build/$(OBJ_DIR); make -f V$(MODULE_NAME).mk

clean:
	rm -rf build/$(OBJ_DIR)
	rm build/bench_$(MODULE_NAME)
