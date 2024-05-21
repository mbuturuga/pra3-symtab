        /************************************************/
        /*              ESPECIFICACIO YACC              */
        /*               Gestió atributs                 */
        /*  Gestio de tipus basics  a les declaracions	 */
        /************************************************/



%{
    #include <stdio.h>
    #include <stdlib.h>
    #include"symtab.h" // Conté la definicio de les Entrades a la TS


#define TCHAR 1    // Tipus del IDENTIFICADORS: de més específic a més general
#define TINT 2
#define TREAL 3


#define MAX(x,y) (x)>=(y)?x:y
#define NUL (void *)0

extern int nlin;
extern int yylex();

void yyerror (char const *);


extern FILE * yyin;
extern FILE * yyout;

int tid;        // variable extreure atributs de la TS

%}

%union	{
    char *name;         // lexema amb memòria dinàmica
    int enter;          // valor de les constants enteres
    double real;        // valor de les constants reals
    char caracter;      // valor de les constants de caràcter
    int tipus_b;        // 3 tipus bàsics
    void *sense_atribut;    // constructors sense atribut
    }

	
%start programa

%token<name> ID

%token<enter> VINT
%token<real> VREAL
%token<caracter> VCHAR

%token INT REAL CHAR

%left '+' '-'
%left '*' '/'

%type<tipus_b> tipus llistaid expr aux

%type<sense_atribut> programa llistainst inst decla asig

%%

programa:                        { $$=NUL; }     // epsilon (programa buit)
            |   llistainst       { $$=NUL; }
            ;

llistainst:     inst                 { $$=NUL; }
            | llistainst inst        { $$=NUL; }
            ;


inst:         ';'                { $$=NUL; }
        |   decla ';'           { $$=NUL; }
        |   asig  ';'           { $$=NUL; }
        |   error ';'           { $$=NUL;
                                fprintf(stderr,"Línea %d: ERROR INSTRUCCIÓ INCORRECTA\n", nlin);
                                yyerrok; }      // sortir de l'error amb ;
        ;

decla:	    tipus llistaid       {$$=NUL;}
        ;


tipus   : INT  {$$ = TINT;}
        | REAL {$$ = TREAL;}
        | CHAR {$$ = TCHAR;}
        ;



llistaid: 	ID      {  if (sym_lookup($1, &tid)==SYMTAB_OK){   //verificar duplicat
                            fprintf(stderr,"ERROR ID %s ja utilitzat. Línea %d \n", $1, nlin);
                            YYERROR;
                        }else{
                            tid=$<tipus_b>0;
                            sym_add($1,&tid);
                            fprintf(yyout,"Declara Identificador: %s\t Tipus: %d\n", $1, tid);
                            $$ = $<tipus_b>0;
                        }
                    }
        |  llistaid ',' ID      {   if (sym_lookup($3, &tid)==SYMTAB_OK){   //verificar duplicat
                                        fprintf(stderr,"ERROR ID %s ja utilitzat. Línea %d \n", $3, nlin);
                                        YYERROR;
                                    }else{
                                        tid=$1;
                                        sym_add($3,&tid);
                                        fprintf(yyout,"Declara Identificador: %s\t Tipus: %d\n", $3, tid);
                                        $$ = $1;
                                    }
                                }
            ;

asig  :     ID '=' aux expr     { if ($4>$3){   // verificar casament de tipus entre ID i exp
                                    fprintf(stderr,"Línea %d: Error tipus: ID %s tipus %d \t Expressió tipus %d\n", nlin, $1, $3, $4);
                                    YYERROR; }
                                else{
                                    fprintf(yyout,"Línea %d: Assignació Ok: ID %s tipus %d \t Expressió tipus %d\n", nlin, $1, $3, $4);
                                    $$=NUL;
                                }
                            }
           ;

aux:                    { if (sym_lookup($<name>-1, &tid)!=SYMTAB_OK){   //verificar existeix
                            fprintf(stderr,"Línea %d: ERROR ID %s no declarat. \n", nlin, $<name>-1);
                            YYERROR; }
                        $$=tid; }
        ;


expr  :         expr '+' expr   { $$=MAX($1,$3); }   // tipus expressió més general

        |        expr '-' expr   { $$=MAX($1,$3); }
        |        expr '*' expr   { $$=MAX($1,$3); }
        |        expr '/' expr   { $$=MAX($1,$3); }
        |      '(' expr ')'      { $$=$2; }
        |       ID              { if (sym_lookup($1,&tid)!=SYMTAB_OK){   //verificar existeix entrada TS
                                        fprintf(stderr,"Línea %d: ERROR ID %s NO definit\n", nlin, $1);
                                        YYERROR;
                                    } else { $$= tid; }
                                }
        |       VINT            { $$=TINT; }
        |       VREAL           { $$ = TREAL;}
        |       VCHAR           { $$ = TCHAR;}
        ;

%%

/* Called by yyparse on error. */

void yyerror (char const *s){
    fprintf (stderr, "%s\n", s);
}

int main(int argc, char *argv[]){
    if (argc>=2){
        yyin = fopen( argv[1], "r" );
    }
    if (argc==3){
        yyout = fopen( argv[2], "w" );
    }
    if (argc > 3){
        fprintf(stderr, "Error paràmetres línia comanda");
        return 1;
    }
    return(yyparse());
    
}
