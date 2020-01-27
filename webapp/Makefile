CC = cc

all:
	$(CC) $(CFLAGS) -c daemonize.c
	$(CC) $(CFLAGS) -c service.c
	$(CC) $(CFLAGS) $(LDFLAGS) daemonize.o service.o main.c -lmicrohttpd -o webapp

install: all
	install -d -m755 $(PREFIX)/bin
	install -m755 webapp $(PREFIX)/bin

clean:
	rm -f *.o
	rm -f webapp
