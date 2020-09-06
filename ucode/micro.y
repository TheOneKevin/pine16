%{
    #include <stdio.h>
    #include <stdlib.h>
    #include "utils.h"

    #define YYERROR_VERBOSE 1

    extern int yylex();
    extern int yyparse();
    extern FILE* yyin;
    void yyerror(const char* s);

    // Global state
    global_t* global;
%}

%output     "gen/parser.c"
%defines    "gen/parser.h"
%locations

%union {
    char* txt;
    int num;
    range_t* range;
    arg_t* args;
    ins_t* inst;
    suffix_t* flags;
}

%token TOKEN_BANG "!"
%token TOKEN_COMMA ","
%token TOKEN_LSP "["
%token TOKEN_RSP "]"
%token TOKEN_DDOT ".."
%token TOKEN_AT "@"
%token TOKEN_NL "\n"
%token TOKEN_ENDFLAG "sequence end flag"
%token <txt> TOKEN_IDENT "identifier"
%token <txt> TOKEN_LABEL "label"
%token <num> TOKEN_INTB4 "4-digit binary integer"

%type <range> jtab_range
%type <args> args;
%type <inst> statement;
// %type <inst> body;
%type <flags> suffix;

// This means that I really don't know what I'm doing
%left TOKEN_COMMA   // Left associative ((arg1), arg2), arg3
%left TOKEN_NL      // ((statement) \n statement) \n statement
%right TOKEN_IDENT  // (ident) ? ((ident) ? ident)

%start micro

%%

micro: %empty
    | micro jtab
    | micro block
    | micro TOKEN_NL
    ;

block:
    label TOKEN_NL | label TOKEN_NL body
    ;

body: jtab | statement | body jtab | body statement ;

label: TOKEN_LABEL[id]
    {
        if(set_label($id) < 0) {
            YYABORT;
        }
    }
    ;

jtab:
    TOKEN_IDENT[id] TOKEN_AT jtab_range[u] jtab_range[v] TOKEN_NL
    {
        free($u), free($v);
    }
    ;

jtab_range:
    TOKEN_LSP TOKEN_INTB4[lv] TOKEN_DDOT TOKEN_INTB4[rv] TOKEN_RSP
        { $$ = make_range($lv, $rv); }
    ;

statement:
    TOKEN_IDENT[id] args suffix TOKEN_NL
    {
        if(emit_instruction($id, $args, &$$) < 0) {
            YYABORT; // TODO: Yikes, a memory leak probably will happen
        }
        free($suffix), free($id);
        destroy_argument_list($args);
    }
    | TOKEN_IDENT[id] suffix TOKEN_NL
    {
        if(emit_instruction($id, NULL, &$$) < 0) {
            YYABORT;
        }
        free($suffix), free($id);
    }
    ;

args:
    TOKEN_IDENT
        { $$ = make_argument($1, NULL); }
    | TOKEN_COMMA args // Null first argument
        { $$ = chain_argument(make_argument(NULL, NULL), $2); }
    | args[a1] TOKEN_COMMA args[a2]
        { $$ = chain_argument($a1, $a2); }
    | args TOKEN_COMMA // Null last argument
        { $$ = make_argument(NULL, $1); }
    ;

// There has to be a better way, right?
suffix:
      %empty        { $$ = make_suffix(false, false); }
    | TOKEN_BANG    { $$ = make_suffix(false, true); }
    | TOKEN_ENDFLAG { $$ = make_suffix(true, false); }
    | TOKEN_BANG TOKEN_ENDFLAG { $$ = make_suffix(true, true); }
    ;

%%

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
    } else {
        printf("Compilation failed with errors.\n");
    }
    destroy_global();
}
