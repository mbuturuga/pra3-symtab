        /********************************************************/
        /*               ESPECIFICACIO LEX                      */
        /*        Gestio de tipus basics a les declaracions	    */
        /********************************************************/

%{
    
    #include "decla_tipus_basics.tab.h"

    int nlin=1;
%}

%array

%option nounput
%option noinput
%option noyywrap

lletra      [a-zA-Z]
digit       [0-9]
id          {lletra}({lletra}|{digit}|_)*

enter       [0-9]+
real        {enter}\.{enter}(e|E[+-]?{enter})?


%%

[ \t]+                          ;       // saltar delimitadors

"//".*\n                 nlin++;       // saltar comentaris

"int"                           return INT;		    // paraules reservades

"float"|"double"               	return REAL;

"char"                          return CHAR;

{id}                          { yylval.name = malloc( yyleng+1 );
                                  strcpy( yylval.name, yytext );
                                  return ID; }

{enter}                         { yylval.enter = atoi( yytext );
                                 return VINT; }

{real}                         { yylval.real = atof( yytext );
                                return VREAL; }

\'.\'                           { yylval.caracter = yytext[1];
                                return VCHAR; }

\n                             { nlin++; }              // comptar línies

                        /*  resta operadors  1 símbol lèxic */

.                              { return(yytext[0]); }    //  Els errors es processaran a nivell sintàctic

