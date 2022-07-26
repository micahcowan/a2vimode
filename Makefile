all: VIMODE.dsk VIMODE-PRODOS.dsk

VIMODE-PRODOS.dsk: VIMODE STARTUP SYSTEM.dsk Makefile
	rm -f $@
	cp SYSTEM.dsk $@
	# This isn't working at the moment:
	#prodos -t BAS -a 0x0801 $@ SAVE STARTUP
	# We have it pre-saved to SYSTEM.DSK instead.
	prodos -t BIN -a 0x6000 $@ SAVE VIMODE

VIMODE.dsk: VIMODE BSTRAP HELLO Makefile
	rm -f $@
	cp empty.dsk $@
	dos33 -y $@ save A HELLO
	dos33 -y -a 0x6000 $@ bsave VIMODE
	dos33 -y -a 0x300 $@ bsave BSTRAP

STARTUP: startup-basic.txt Makefile
	tokenize_asoft < $< > $@ || { rm $@; exit 1; }

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
