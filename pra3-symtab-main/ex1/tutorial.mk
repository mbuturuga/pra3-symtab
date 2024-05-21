$(TARGET) : $(TARGET).tab.c  lex.yy.c symtab.c
	gcc $(CFLAGS) $(TARGET).tab.c lex.yy.c symtab.c -o $(TARGET) 

$(TARGET).tab.c: $(TARGET).y
	bison -d -v $(TARGET).y -o $(TARGET).tab.c -Wcounterexamples

lex.yy.c : $(TARGET).l
	flex $(TARGET).l

clean : 
	$(RM) $(TARGET) $(TARGET).tab.c $(TARGET).tab.h lex.yy.c $(TARGET).output