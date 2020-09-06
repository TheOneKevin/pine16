SRCS = utils.c gen/parser.c gen/lexer.c
CC = gcc
FLAGS = -Os -lfl -I.

all: micro

micro: gen $(SRCS) utils.h masks.h
	$(CC) $(SRCS) $(FLAGS) -o micro

gen/lexer.c: micro.l utils.h
	flex micro.l

gen/parser.c: micro.y utils.h
	bison -v micro.y

gen:
	mkdir gen

clean:
	rm -rf gen/ micro