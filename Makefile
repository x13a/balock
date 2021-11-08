NAME        := balock

prefix      ?= /usr/local
exec_prefix ?= $(prefix)
bindir      ?= $(exec_prefix)/bin

bindestdir  := $(DESTDIR)$(bindir)
targetdir   := ./zig-out

all: build

build:
	zig build

installdirs:
	install -d $(bindestdir)/

install: installdirs
	install $(targetdir)/bin/$(NAME) $(bindestdir)/

uninstall:
	rm -f $(bindestdir)/$(NAME)

test:
	zig build test

clean:
	rm -rf $(targetdir)/
