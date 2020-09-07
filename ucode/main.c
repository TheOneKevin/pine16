#include <stdlib.h>
#include <stdio.h>

#include "utils.h"
#include "gen/parser.h"
#include "gen/lexer.h"

static void print_jmptab()
{
    extern global_t* global;
    for(int i = 0; i < 256; i++) {
        printf("%02X ", global->jmptab[i]);
        if((i+1) % 16 == 0)
            printf("\n");
    }
    printf("\n");
}

static void print_insmem()
{
    extern global_t* global;
    uint16_t* mem = dyncast(uint16_t, g(insmem));
    for(int i = 0; i < dynsize(g(insmem)); i++) {
        printf("%04X ", mem[i]);
        if((i+1) % 8 == 0)
            printf("\n");
    }
    printf("\n");
}

int main(int argc, char** argv)
{
    ++argv, --argc;
	if ( argc > 0 ) {
        yyin = fopen( argv[0], "r" );
    } else {
        printf("No input file specified.\n");
        return 0;
    }
    init_global();
    if(yyparse() == 0) {
        printf("Compilation successful.\n");
        printf("Printing jump table:\n");
        print_jmptab();
        printf("Printing instruction ROM:\n");
        print_insmem();
    } else {
        printf("Compilation failed with errors.\n");
    }
    destroy_global();
}
