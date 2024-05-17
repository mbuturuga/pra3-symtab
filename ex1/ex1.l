%{
    
    #include "ex1.tab.h"
    #include <string.h> // for strncpy
    int nlin=1;
%}

%array

%option nounput
%option noinput
%option noyywrap


VARIABLES    [x-z][1-9]+
CONSTANTS    [a-c][1-9]+
PREDICATES   [P-T][1-9]+
FUNCTIONS    [f-g][1-9]+

SEPARATORS   "("|")"|","

WHITESPACE  [ \t]+
COMMENT     "//".*\n

%%

{WHITESPACE}  { /* ignore whitespace */ }
{COMMENT}     { /* ignore comments */ nlin++; }
\n            { nlin++; }

{VARIABLES}   { yylval.value = malloc( yyleng+1 ); strcpy( yylval.value, yytext ); return VAR; }
{CONSTANTS}   { yylval.value = malloc( yyleng+1 ); strcpy( yylval.value, yytext ); return CONST; }
{PREDICATES}  { yylval.value = malloc( yyleng+1 ); strcpy( yylval.value, yytext ); return PRED; }
{FUNCTIONS}   { yylval.value = malloc( yyleng+1 ); strcpy( yylval.value, yytext ); return FUNC; }

forall        { return FORALL; }
exists        { return EXISTS; }

{SEPARATORS}  { return yytext[0]; }

and           { return AND; }
or            { return OR; }
!             { return NOT; }
"->"          { return IMPLIES; }
"<->"         { return IFF; }

";"           { return EOL; }
.             { return yytext[0]; }
