all: VIMODE.dsk VIMODE-PRODOS.dsk

VIMODE-PRODOS.dsk: VIMODE Makefile
	rm -f $@
	cp SYSTEM.dsk $@
	prodos -t BIN -a 0x6000 $@ SAVE VIMODE

VIMODE.dsk: VIMODE BSTRAP HELLO Makefile
	rm -f $@
	cp empty.dsk $@
	dos33 -y $@ save A HELLO
	dos33 -y -a 0x6000 $@ bsave VIMODE
	dos33 -y -a 0x300 $@ bsave BSTRAP

HELLO: hello-basic.txt Makefile
	tokenize_asoft < $< > $@ || { rm $@; exit 1; }

VIMODE: vimode.o Makefile
	ld65 -t none -o $@ $<

BSTRAP: bootstrap.o Makefile
	ld65 -t none -o $@ $<

.s.o:
	ca65 --listing $(subst .o,.list,$@) $<

.PHONY: clean
clean:
	rm -f VIMODE.dsk VIMODE-PRODOS.dsk VIMODE BSTRAP HELLO *.o *.list
