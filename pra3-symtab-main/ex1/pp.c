#include<stdio.h>

#include"symtab.h"

int main()
{
    char* name = "variable1";

    int ret = sym_add(name, (void*)0);
    if(ret == 0)
    {
        printf("Variable added successfully\n");
    }
    else
    {
        printf("Variable not added\n");
    }

}