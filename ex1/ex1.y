%{

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include"symtab.h" // Contains the symtab entry definitions

// ANSI color codes
#define RESET   "\033[0m"
#define RED     "\033[31m"
#define GREEN   "\033[32m"


#define MAX(x,y) (x)>=(y)?x:y
#define NUL (void *)0

extern int nlin;
extern int yylex();

void yyerror (char const *);


extern FILE * yyin;
extern FILE * yyout;

// Type definitions
#define TVAR 1
#define TPRED 2
#define TFUNC 3


// Variable to store entry information
entry_info info;

// Boolean to check errors -> we won't print popped scopes after the error
int error = 0;      

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

// Function to count the number of arguments in a term list
int count_args(char* term_list){
    int count = 1;
    // Count commas
    for (int i = 0; term_list[i] != '\0'; i++){
        if (term_list[i] == ',') count++;
    }
    return count;
}


%}

%union{
    char *name;
    char *string;
    void *notype;
}	

%token <name> VAR CONST PRED FUNC 
%token FORALL EXISTS AND OR NOT IMPLIES IFF EOL

%type <string> formula composite_formula atomic_formula term_list term
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

sentence: EOL                                   {/* empty sentence */ $$ = NUL; }
    | aux_scope formula EOL aux_end_scope       { printf(GREEN "Valid formula at line %d:\n  %s\n\n" RESET, nlin, $2); $$ = NUL; free($2); }
    | error EOL aux_end_all_scopes              { fprintf(stderr, RED "Invalid formula at line %d\n\n" RESET, nlin); 
                                                  $$ = NUL; 
                                                  yyerrok; }   
    ;

aux_scope:{ 
    // Check stack has space to push a new scope
    if (sym_push_scope() == SYMTAB_STACK_OVERFLOW){
        fprintf(stderr, "Error: Unable to create new scope at line %d\n", nlin);
        YYERROR;  
        }
    else{
        // Push new scope and print it
        int id_scope = sym_get_scope();
        printf("Pushed scope ID %d\n", id_scope);
        }
    }
    ;

aux_end_scope : %prec FORALL {
    // Pop current scope
    int id_scope = sym_get_scope();
    if(sym_pop_scope() == SYMTAB_OK){
        printf("Popped scope ID %d\n", id_scope);
        }
    else{
        fprintf(stderr, "Error: Unable to pop scope at line %d\n", nlin);
        YYERROR;
        }
    }
    ;

aux_end_all_scopes: {
    // Pop all remaining scopes
    int id_scope = sym_get_scope();
    while(id_scope >= 0){
        if(sym_pop_scope() == SYMTAB_OK){
            // Only print if there was no error
            if(!error)  printf("Popped scope ID %d\n", id_scope);
            id_scope = sym_get_scope();
            }
        else{
            fprintf(stderr, "Error: Unable to pop scope at line %d\n", nlin);
            YYERROR;
            }
        }
    // Reset error flag
    error = 0;
    }
    ;

formula: atomic_formula         { $$ = get_string("%s", $1); free($1); }
    | composite_formula         { $$ = get_string("%s", $1); free($1); }
    ;

composite_formula: 
      FORALL aux_scope VAR aux_var formula aux_end_scope %prec FORALL       { $$ = get_string("forall %s %s", $3, $5); free($5); }
    | EXISTS aux_scope VAR aux_var formula aux_end_scope %prec EXISTS       { $$ = get_string("exists %s %s", $3, $5); free($5); }
    | NOT formula                   { $$ = get_string("!%s", $2); free($2); }
    | formula AND formula           { $$ = get_string("(%s and %s)", $1, $3); free($1); free($3); }
    | formula OR formula            { $$ = get_string("(%s or %s)", $1, $3); free($1); free($3); }
    | formula IMPLIES formula       { $$ = get_string("(%s -> %s)", $1, $3); free($1); free($3); }
    | formula IFF formula           { $$ = get_string("(%s <-> %s)", $1, $3); free($1); free($3); }
    | '(' formula ')'               { $$ = get_string("(%s)", $2); free($2);}
    ;

aux_var: {
    // Add variable to current scope
    char* var_name = $<name>0;

    // Check if variable is already declared
    if (sym_lookup(var_name, &info) == SYMTAB_OK){
        fprintf(stderr, "SEMANTIC ERROR: Variable %s already declared. Line%d\n", var_name, nlin);
        error = 1;
        YYERROR;
    }
    else{
        info.type = TVAR;
        info.arity = 0;
        sym_add(var_name, &info);
        printf("Added variable %s\n", var_name);
    }
    }
    ;

atomic_formula: PRED '(' term_list ')'      { int arity = count_args($3);

                                              // If predicate is not declared, add it
                                              if (sym_lookup($1, &info) == SYMTAB_NOT_FOUND){
                                                info.type = TPRED;
                                                info.arity = arity;

                                                sym_add($1, &info);
                                                printf("Added predicate %s with arity %d\n", $1, info.arity);
                                              }
                                              // If declared, check arity
                                              else if (info.arity != arity){
                                                fprintf(stderr, "SEMANTIC ERROR: Predicate %s expects %d arguments, but %d were given. Line %d\n", $1, info.arity, arity, nlin);
                                                error = 1;
                                                YYERROR;
                                                }

                                              $$ = get_string("%s(%s)", $1, $3); free($3);
                                            }
    ;

term_list: term                             { $$ = get_string("%s", $1); free($1); }
    | term_list ',' term                    { $$ = get_string("%s,%s", $1, $3); free($1); free($3); }
    ;

term: VAR                                   { 
                                              // Check if variable is not declared (quantified)
                                              if (sym_lookup($1, &info) == SYMTAB_NOT_FOUND){
                                                fprintf(stderr, "SEMANTIC ERROR: Variable %s not quantified. Line %d\n", $1, nlin);
                                                error = 1;
                                                YYERROR;
                                              }
                                                $$ = get_string("%s", $1); free($1);
                                            }                           
    | CONST                                 { $$ = get_string("%s", $1); free($1); }
    | FUNC '(' term_list ')'                { int arity = count_args($3);

                                              // If function is not declared, add it
                                              if (sym_lookup($1, &info) == SYMTAB_NOT_FOUND){
                                                info.type = TFUNC;
                                                info.arity = arity;

                                                sym_add($1, &info);
                                                printf("Added function %s with arity %d\n", $1, info.arity);
                                              }
                                              // If declared, check arity
                                              else if (info.arity != arity){
                                                fprintf(stderr, "SEMANTIC ERROR: Function %s expects %d arguments, but %d were given. Line %d\n", $1, info.arity, arity, nlin);
                                                error = 1;
                                                YYERROR;
                                                }

                                              $$ = get_string("%s(%s)", $1, $3); free($3);
                                            }
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
    printf("Parsing file %s...\n\n", argv[1]);

    if (yyparse() == 0){
        printf("File parsed successfully.\n");

    }else{
        fprintf(stderr, "Error: File finished unexpectedly.\n");
    }
    
}