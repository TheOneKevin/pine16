#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "utils.h"
#include "masks.h"

#define THROW_ERROR(...) { fprintf(stderr, __VA_ARGS__); return -1; }

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

int set_label(char* id) {
    extern global_t* global;

    if(id == NULL) {
        THROW_ERROR("Label cannot be null.\n");
    }

    // Search for existing labels
    for(int i = 0; i < global->symtab_size; i++) {
        if(!strcmp(global->symtab[i].name, id)) {
            THROW_ERROR("Label \"%s\" already exists.", id);
        }
    }

    // Add label, resizing array if needed
    if(global->symtab_size == global->max_symtab_size) {
        // 1. Allocate new array 2. Copy contents 3. Free old array
        printf("Warning: Too many symbols, resizing array (old: %d, new: %d).\n",
            (int) global->max_symtab_size,
            (int) global->max_symtab_size+SYMTAB_RESERVE);
        symbol_t* prv = global->symtab;
        global->symtab = (symbol_t*) calloc(global->max_symtab_size+SYMTAB_RESERVE, sizeof(symbol_t));
        memcpy(global->symtab, prv, global->max_symtab_size*sizeof(symbol_t));
        global->max_symtab_size += SYMTAB_RESERVE;
        free(prv);
    }
    global->symtab[global->symtab_size].name = id;
    global->symtab[global->symtab_size].uip = global->uip;
    global->symtab_size++;

    return 0;
}

void append_instruction() {
    extern global_t* global;
}

int emit_instruction(char* op, arg_t* args, ins_t** out) {
    uint16_t word = 0;
    if(!strcasecmp(op, "RAW") && arglen(args) == 3) {
        word |= OP_RAW;
        // Parse arguments
        foreach(ptr, args) switch(ptr->pos) {
        case 2: {
            if(ptr->text == NULL) {
                word |= OP_NOWRITE;
                break;
            }
            int flag = get_write_id(ptr->text);
            word |= OP_WMASK(flag);
            if(flag < 0) {
                THROW_ERROR("Unknown write register \"%s\" expected mar, mdr, rs or rd.\n", ptr->text);
            }
            break;
        } case 1: {
            if(ptr->text == NULL) {
                THROW_ERROR("ALU operation cannot be null.\n");
            }
            int flag = get_alu_id(ptr->text);
            if(!strcasecmp(ptr->text, "aop")) {
                word |= OP_ALUIMM;
            } else if(flag < 0) {
                THROW_ERROR("Unknown ALU operation \"%s\".\n", ptr->text);
            } else {
                word |= OP_AMASK(flag);
            }
            break;
        } case 0: {
            int flag = get_read_id(ptr->text);
            word |= OP_WMASK(flag);
            if(flag == -1) {
                THROW_ERROR("Unknown read register \"%s\" expected imm, mdr, rs or rd.\n", ptr->text);
            }
            break;
        }}
    }
    else {
        THROW_ERROR("Unknown instruction \"%s\" with %d arguments.\n", op, arglen(args));
    }
    printf("Emit [%4X]\n", word);
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
    
    global->uip = 0;
    global->ins_next = NULL;

    global->symtab_size = 0;
    global->max_symtab_size = SYMTAB_RESERVE;
    global->symtab = (symbol_t*) calloc(global->max_symtab_size, sizeof(symbol_t));
}

void destroy_global() {

}
