#pragma once
#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

#define SYMTAB_RESERVE 128

#define arglen(a) (a == NULL ? 0 : a -> pos + 1)
#define foreach(i, a) for(arg_t* i = a; i; i = i -> prev)

typedef struct {
    int l, r;
} range_t;

typedef struct argument {
    char* text;
    int pos;
    struct argument* prev;
} arg_t;

typedef struct instruction {
    uint16_t word;
    struct instruction* prev;
    struct instruction* next;
} ins_t;

typedef struct {
    bool end;
    bool store_flags;
} suffix_t;

typedef struct {
    char* name;
    int uip;
} symbol_t;

typedef struct {
    int uip;
    size_t max_symtab_size;
    size_t symtab_size;
    symbol_t* symtab;
    struct instruction* ins_next;
} global_t;

// Undocumented clusterfuck

range_t* make_range(int l, int r);
arg_t* make_argument(char* text, arg_t* prev);
arg_t* chain_argument(arg_t* prev, arg_t* next);
void destroy_argument_list(arg_t* ptr);
int set_label(char* id);
suffix_t* make_suffix(bool a, bool b);
int emit_instruction(char* op, arg_t* args, ins_t** out);
char* safe_strdup(char* str);
void init_global();
void destroy_global();
