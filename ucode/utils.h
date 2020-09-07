#pragma once
#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

#define arglen(a) (a == NULL ? 0 : a -> pos + 1)
#define foreach(i, a) for(arg_t* i = a; i; i = i -> prev)

// Dynamic array macros and structures

#define DYNLIST_RESERVE 128
typedef struct {
    size_t size; // Size in elements
    size_t max_size;
    void* array;
} dynlist_t;
#define dyninit(T, list) { \
    (list)->size = 0; \
    (list)->max_size = DYNLIST_RESERVE; \
    (list)->array = calloc((list)->max_size, sizeof(T)); \
}
#define dyn_try_expand(T, list, f) { \
    if((list)->size == (list)->max_size) { \
        { f; }; \
        /* 1. Allocate new array 2. Copy contents 3. Free old array */ \
        void* prv = (list)->array; \
        (list)->array = calloc((list)->size+DYNLIST_RESERVE, sizeof(T)); \
        memcpy((list)->array, prv, (list)->size*sizeof(T)); \
        (list)->size += DYNLIST_RESERVE; \
        free(prv); \
    } \
}
#define g(list) (&global->list)
#define dynsize(list) ((list)->size)
#define dynmax(list) ((list)->max_size)
#define dyncast(T, list) ((T*)(list)->array)

// Regular data structures

typedef struct {
    int l, r;
} range_t;

typedef struct argument {
    char* text;
    int pos;
    struct argument* prev;
} arg_t;

typedef struct {
    bool end;
    bool store_flags;
} suffix_t;

typedef struct {
    char* name;
    int uip;
    range_t *p, *s;
    bool sym, jmp;
} symbol_t;

typedef struct {
    uint16_t jmptab[256];
    dynlist_t symtab; // type symbol_t
    dynlist_t insmem; // type uint16_t
} global_t;

// Undocumented clusterfuck

range_t* make_range(int l, int r);
arg_t* make_argument(char* text, arg_t* prev);
arg_t* chain_argument(arg_t* prev, arg_t* next);
void destroy_argument_list(arg_t* ptr);
int set_label(char* id);
int set_jumptable(char* id, range_t* p, range_t* s);
suffix_t* make_suffix(bool a, bool b);
int emit_instruction(char* op, arg_t* args, suffix_t* flags);
char* safe_strdup(char* str);
void init_global();
void destroy_global();
