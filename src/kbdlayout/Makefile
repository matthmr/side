CC?=gcc
CFLAGS?=-Wall
CFLAGSADD?=

all: kbdlayout

kbdlayout.o: kbdlayout.c
	$(CC) -c $(CFLAGS) $(CFLAGSADD) $< -o $@

kbdlayout: kbdlayout.o
	$(CC) $(CFLAGS) $(CFLAGSADD) $< -o $@ -lX11

clean:
	rm -f kbdlayout kbdlayout.o
