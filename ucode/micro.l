%{
    #include "utils.h" // Utils must go before parser
    #include "parser.h"

    // Please kill me now
    int yycolumn = 1, yylastline = 1;
    #define YY_USER_ACTION { \
        yycolumn = yylastline == yylineno ? yycolumn + yyleng : 1; \
        yylastline = yylineno; \
    }
    #define max(a, b) ((a)>(b)?(a):(b))
%}

%option outfile="gen/lexer.c" header-file="gen/lexer.h"
%option yylineno

IDENT   [A-Za-z_][A-Za-z0-9_]*
LABEL   [A-Za-z_][A-Za-z0-9_]*[ \t]*:
INTB4   [01]{4}
FLAGEND >[ \t]*(END)?

%%

#.*         { /* Comments */ }
[ \r\t]*    { }
[\n]+       { return TOKEN_NL; }
<<EOF>>     { // Interpret EOF as new line
    static int once = 0;
    return (once = !once) ? TOKEN_NL : 0;
}
"["         { return TOKEN_LSP; }
"]"         { return TOKEN_RSP; }
".."        { return TOKEN_DDOT; }
"@"         { return TOKEN_AT; }
","         { return TOKEN_COMMA; }
"!"         { return TOKEN_BANG; }
{IDENT}     {
    yylval.txt = safe_strdup(yytext);
    return TOKEN_IDENT;
}
{INTB4}     {
    int i = 0;
    yylval.num = 0;
    while (i < 4) {
        yylval.num <<= 1;
        if (yytext[i++] == '1')
            yylval.num++;
    }
    return TOKEN_INTB4;
}
{LABEL}     {
    char* txt = safe_strdup(yytext);
    txt[strlen(txt)-1] = '\0';
    while(txt[strlen(txt)-1] == ' ') {
        txt[strlen(txt)-1] = '\0';
    }
    yylval.txt = txt;
    return TOKEN_LABEL;
}
{FLAGEND}   {
    return TOKEN_ENDFLAG;
}

%%

int yyerror(const char* s)
{
    fprintf(stderr, "Lexer Error: %s at %d:%d\n", s, yylineno, max(yycolumn-yyleng, 1));
    return 0;
}
