%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <stdarg.h>
    #include"symtab.h" // Contains the symtab entry definitions


#define MAX(x,y) (x)>=(y)?x:y
#define NUL (void *)0

extern int nlin;
extern int yylex();

void yyerror (char const *);


extern FILE * yyin;
extern FILE * yyout;

// Function to get a string from a format
char* get_string(char* format, ...){
        va_list args;

        va_start(args, format);
        int len = vsnprintf(NULL, 0, format, args) + 1;
        va_end(args);

        char* str = malloc(len);
        va_start(args, format);
        vsnprintf(str, len, format, args);
        va_end(args);

        return str;
    }

%}

%union{
    char *value;
    void *notype;
}	

%token <value> VAR CONST PRED FUNC 
%token FORALL EXISTS AND OR NOT IMPLIES IFF EOL

%type <value> formula composite_formula atomic_formula term_list term
%type <notype> program sentence_list sentence 

%start program    /* specify the start symbol */

/* precedence */
%left  IMPLIES IFF
%left  OR
%left  AND
%right FORALL EXISTS
%right NOT

%%

program: sentence_list          { $$ = NUL;}
    | /* empty program */       { $$ = NUL;}
    ;

sentence_list: sentence         { $$ = NUL;}
    | sentence_list sentence    { $$ = NUL;}
    ;

sentence: EOL                   {/* empty sentence */ $$ = NUL; }
    | formula EOL               { printf("Valid formula: %s\n", $1); $$ = NUL; free($1); }
    | error EOL                 { fprintf(stderr, "Error: Invalid formula at line %d\n", nlin); 
                                  $$ = NUL; 
                                  yyerrok; }   
    ;

formula: atomic_formula                     { $$ = get_string("%s", $1); free($1); }
    | composite_formula                     { $$ = get_string("%s", $1); free($1); }
    ;

composite_formula: 
      FORALL aux_scope VAR formula %prec FORALL       { $$ = get_string("forall %s %s", $3, $4); free($3); free($4); }
    | EXISTS aux_scope VAR formula %prec EXISTS       { $$ = get_string("exists %s %s", $3, $4); free($3); free($4); }
    | NOT formula                           { $$ = get_string("!%s", $2); free($2); }
    | formula AND formula                   { $$ = get_string("(%s and %s)", $1, $3); free($1); free($3); }
    | formula OR formula                    { $$ = get_string("(%s or %s)", $1, $3); free($1); free($3); }
    | formula IMPLIES formula               { $$ = get_string("(%s -> %s)", $1, $3); free($1); free($3); }
    | formula IFF formula                   { $$ = get_string("(%s <-> %s)", $1, $3); free($1); free($3); }
    | '(' formula ')'                       { $$ = get_string("(%s)", $2); free($2);}
    ;

aux_scope:{ 
    // Check stack has space to push a new scope
    if (sym_push_scope() == SYMTAB_STACK_OVERFLOW){
        fprintf(stderr, "Error: Unable to create new scope at line %d\n", nlin);
        YYERROR;  
        }
    else{
        int id_scope = sym_get_scope();
        printf("PUSH scope %d\n", id_scope);
        }
    }

atomic_formula: PRED '(' term_list ')'      { $$ = get_string("%s(%s)", $1, $3); free($1); free($3); }
    ;

term_list: term                             { $$ = get_string("%s", $1); free($1); }
    | term_list ',' term                    { $$ = get_string("%s,%s", $1, $3); free($1); free($3); }
    ;

term: VAR                                   { $$ = get_string("%s", $1); free($1); }                            
    | CONST                                 { $$ = get_string("%s", $1); free($1); }
    | FUNC '(' term_list ')'                { $$ = get_string("%s(%s)", $1, $3); free($1); free($3); }
    ;

%%

// Called by yyparse on error
void yyerror (char const *s){
    fprintf (stderr, "%s at line %d\n", s, nlin);
} 

// Main function     
int main( int argc, char *argv[] ) {
    if (argc!=2){
        fprintf(stderr,"Usage: %s [file]\n", argv[0]);
        return(1);
    }

    yyin = fopen( argv[ 1 ], "r" );
    
    if ( yyin == NULL ){
        fprintf (stderr, "Error: Cannot open file %s\n", argv[ 1 ] );
        return(1);
    }

    // Parse the file
    printf("Parsing file %s...\n", argv[1]);

    if (yyparse() == 0){
        printf("File parsed successfully.\n");

    }else{
        fprintf(stderr, "Error: File finished unexpectedly.\n");
    }
    
}