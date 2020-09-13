#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "utils.h"
#include "masks.h"

#define THROW_ERROR(x, ...) { fprintf(stderr, "Error: " x "\n", ## __VA_ARGS__); return -1; }

range_t* make_range(int l, int r) {
    range_t* st = (range_t*) malloc(sizeof(range_t));
    st->l = l, st->r = r;
    return st;
}

arg_t* make_argument(char* text, arg_t* prev) {
    arg_t* st = (arg_t*) malloc(sizeof(arg_t));
    st->text = text;
    st->prev = prev;
    st->pos = prev ? prev->pos + 1 : 0;
    return st;
}

arg_t* chain_argument(arg_t* prev, arg_t* next) {
    next->prev = prev;
    next->pos = prev ? prev->pos + 1 : 0;
    return next;
}

void destroy_argument_list(arg_t* ptr) {
    arg_t* prev = ptr;
    while(ptr) {
        prev = ptr->prev;
        free(ptr->text);
        free(ptr);
        ptr = prev;
    }
}

suffix_t* make_suffix(bool a, bool b) {
    suffix_t* st = (suffix_t*) malloc(sizeof(suffix_t));
    st->end = a;
    st->store_flags = b;
    return st;
}

static int add_jump(symbol_t* sym) {
    extern global_t* global;
    // Loop through all prefix and suffix ranges
    for(unsigned int i = sym->p->l; i <= sym->p->r; i++) {
        for(unsigned int j = sym->s->l; j <= sym->s->r; j++) {
            uint8_t op = ((i & 0b1111) << 4) | (j & 0b1111);
            if(global->jmptab[op] != 0) {
                THROW_ERROR("Overlapping jump table region [%04X] of label \"%s\".", op, sym->name);
            }
            global->jmptab[op] = (uint16_t) sym->uip;
        }
    }
    return 0;
}

int set_label(char* id) {
    extern global_t* global;
    symbol_t* symtab = dyncast(symbol_t, g(symtab));
    // Check for null label names (impossible?)
    if(id == NULL) {
        THROW_ERROR("Label cannot be null.");
    }
    // If a jump appears already, pair and return
    for(int i = 0; i < dynsize(g(symtab)); i++) {
        assert(symtab[i].jmp || symtab[i].sym);
        if(!strcmp(symtab[i].name, id)) {
            if(symtab[i].jmp && !symtab[i].sym) {
                symtab[i].uip = dynsize(g(insmem));
                symtab[i].sym = true;
                return add_jump(&symtab[i]);
            } // else
            THROW_ERROR("Label \"%s\" already exists.", id);
        }
    }
    // Add label, resizing array if needed
    dyn_try_expand(symbol_t, g(symtab), {
        printf("Warning: Too many symbols, resizing array (old: %d, new: %d).\n",
            (int) dynsize(g(symtab)), (int) dynmax(g(symtab)) + DYNLIST_RESERVE);
    });
    symtab[dynsize(g(symtab))].name = id;
    symtab[dynsize(g(symtab))].uip = dynsize(g(insmem));
    symtab[dynsize(g(symtab))].sym = true;
    dynsize(g(symtab))++;
    return 0;
}

int set_jumptable(char* id, range_t* p, range_t* s) {
    extern global_t* global;
    symbol_t* symtab = dyncast(symbol_t, g(symtab));
    if(id == NULL) {
        THROW_ERROR("Jump label cannot be null.");
    }
    // If a label appears already, pair and return
    for(int i = 0; i < dynsize(g(symtab)); i++) {
        assert(symtab[i].jmp || symtab[i].sym);
        if(!strcmp(symtab[i].name, id)) {
            if(!symtab[i].jmp && symtab[i].sym) {
                symtab[i].jmp = true;
                symtab[i].p = p;
                symtab[i].s = s;
                return add_jump(&symtab[i]);
            } // else
            THROW_ERROR("Jump table entry \"%s\" already exists.", id);
        }
    }
    dyn_try_expand(symbol_t, g(symtab), {
        printf("Warning: Too many symbols, resizing array (old: %d, new: %d).\n",
            (int) dynsize(g(symtab)), (int) dynmax(g(symtab)) + DYNLIST_RESERVE);
    });
    symtab[dynsize(g(symtab))].name = id;
    symtab[dynsize(g(symtab))].p = p;
    symtab[dynsize(g(symtab))].s = s;
    symtab[dynsize(g(symtab))].jmp = true;
    dynsize(g(symtab))++;
    return 0;
}

int emit_instruction(char* op, arg_t* args, suffix_t* flags) {
    uint16_t word = 0;
    if(flags->end) word |= OP_END;
    // Build microinstruction word
    if(!strcasecmp(op, "RAW") && arglen(args) == 3) {
        word |= OP_RAW;
        if(flags->store_flags) word |= RAW_FLAGS;
        // Parse arguments
        foreach(ptr, args) switch(ptr->pos) {
        case 2: {
            if(ptr->text == NULL) {
                break;
            }
            word |= RAW_WRITE;
            int flag = get_write_id(ptr->text);
            word |= RAW_WMASK(flag);
            if(flag < 0) {
                THROW_ERROR("Unknown write register \"%s\" expected mar, mdr, rs or rd.", ptr->text);
            }
            break;
        } case 1: {
            if(ptr->text == NULL) {
                THROW_ERROR("ALU operation cannot be null.");
            }
            int flag = get_alu_id(ptr->text);
            if(!strcasecmp(ptr->text, "op")) {
                
            } else if(flag < 0) {
                THROW_ERROR("Unknown ALU operation \"%s\".", ptr->text);
            } else {
                word |= RAW_ALUIMM;
                word |= RAW_AMASK(flag);
            }
            break;
        } case 0: {
            int flag = get_read_id(ptr->text);
            word |= RAW_RMASK(flag);
            if(flag == -1) {
                THROW_ERROR("Unknown read register \"%s\" expected imm, mdr, rs or rd.", ptr->text);
            }
            break;
        }}
    }
    else {
        THROW_ERROR("Unknown instruction \"%s\" with %d arguments.", op, arglen(args));
    }

    // Add instruction to global
    extern global_t* global;
    dyn_try_expand(uint16_t, g(insmem),);
    dyncast(uint16_t, g(insmem))[dynsize(g(insmem))] = word;
    dynsize(g(insmem))++;
    
    return 0;
}

char* safe_strdup(char* str) {
    size_t len = strlen(str);
    char* res = (char*) malloc(len+1);
    strcpy(res, str);
    res[len] = '\0';
    return res;
}

void init_global() {
    extern global_t* global;
    global = (global_t*) malloc(sizeof(global_t));
    memset(global->jmptab, 0, sizeof(global->jmptab));
    dyninit(uint16_t, g(insmem));
    dyninit(symbol_t, g(symtab));
    // Set instruction at 0 to be 0x0010
    dyncast(uint16_t, g(insmem))[dynsize(g(insmem))] = 0x0010;
    dynsize(g(insmem))++;
}

void destroy_global() {
    // TODO: Clean up after yourself!
}
