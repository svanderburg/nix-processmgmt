CC = cc

all:
	$(CC) $(CFLAGS) $(LDFLAGS) main.c -o nixproc-chainload-user

install: all
	install -d -m755 $(PREFIX)/bin
	install -m755 nixproc-chainload-user $(PREFIX)/bin

clean:
	rm -f *.o
	rm -f nixproc-chainload-user
