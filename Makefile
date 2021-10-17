CC ?= gcc
CFLAGS ?= -g

ondemandcam:
	$(CC) $(CFLAGS) -o ondemandcam ondemandcam.c -lrt -lpthread
