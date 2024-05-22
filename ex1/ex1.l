%{
    
    #include "ex1.tab.h"
    #include <string.h> // for strncpy
    int nlin=1;
%}

%array

%option nounput
%option noinput
%option noyywrap


VARIABLES    [x-z][1-9][0-9]*
CONSTANTS    [a-c][1-9][0-9]*
PREDICATES   [P-T][1-9][0-9]*
FUNCTIONS    [f-g][1-9][0-9]*

SEPARATORS   "("|")"|","

WHITESPACE  [ \t]+
COMMENT     "//".*\n

%%

{WHITESPACE}  { /* ignore whitespace */ }
{COMMENT}     { /* ignore comments */ nlin++; }
\n            { nlin++; }

{VARIABLES}   { yylval.name = malloc( yyleng+1 ); strcpy( yylval.name, yytext ); return VAR; }
{CONSTANTS}   { yylval.name = malloc( yyleng+1 ); strcpy( yylval.name, yytext ); return CONST; }
{PREDICATES}  { yylval.name = malloc( yyleng+1 ); strcpy( yylval.name, yytext ); return PRED; }
{FUNCTIONS}   { yylval.name = malloc( yyleng+1 ); strcpy( yylval.name, yytext ); return FUNC; }

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
