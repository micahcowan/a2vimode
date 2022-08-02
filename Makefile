all: VIMODE-DOS.dsk VIMODE-PRODOS.dsk

VIMODE-PRODOS.dsk: VIMODE PRODOS_242.dsk Makefile
	rm -f $@
	cp PRODOS_242.dsk $@
	prodos -t BIN -a 0x6000 $@ SAVE VIMODE

VIMODE-DOS.dsk: VIMODE BSTRAP DOS_33.dsk Makefile
	rm -f $@
	cp DOS_33.dsk $@
	dos33 -y -a 0x6000 $@ bsave VIMODE
	dos33 -y -a 0x300 $@ bsave BSTRAP

VIMODE: vimode.o Makefile
	ld65 -t none -o $@ $<

BSTRAP: bootstrap.o Makefile
	ld65 -t none -o $@ $<

version.inc: vimode.s bootstrap.s DOS_33.dsk PRODOS_242.dsk Makefile
	rm -f $@
	git fetch --tags # make sure we have any tags from server
	( \
	  set -e; \
	  exec >| $@; \
	  printf '%s\n' 'ViModeVersion:'; \
	  printf '    scrcode "A2VIMODE %s \\"\n' \
	      "$$(git describe --tags | tr 'a-z' 'A-Z')"; \
	  printf '    .byte $$8D, $$00\n'; \
	) || { rm -f $@; exit 1; }

vimode.o: version.inc

.s.o:
	ca65 --listing $(subst .o,.list,$@) $<

.PHONY: clean
clean:
	rm -f VIMODE-DOS.dsk VIMODE-PRODOS.dsk VIMODE BSTRAP version.inc *.o *.list
