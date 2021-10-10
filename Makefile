RELEASE_DATE := "01 October 2021"
RELEASE_MAJOR := 2
RELEASE_MINOR := 8
RELEASE_MICRO := 7
RELEASE_NAME := dkms
RELEASE_VERSION := $(RELEASE_MAJOR).$(RELEASE_MINOR).$(RELEASE_MICRO)
RELEASE_STRING := $(RELEASE_NAME)-$(RELEASE_VERSION)
DIST := unstable
SHELL=bash

SBIN = $(DESTDIR)/usr/sbin
ETC = $(DESTDIR)/etc/dkms
VAR = $(DESTDIR)/var/lib/dkms
MAN = $(DESTDIR)/usr/share/man/man8
INITD = $(DESTDIR)/etc/rc.d/init.d
LIBDIR = $(DESTDIR)/usr/lib/dkms
BASHDIR = $(DESTDIR)/usr/share/bash-completion/completions
KCONF = $(DESTDIR)/etc/kernel
SHAREDIR = $(DESTDIR)/usr/share
DOCDIR = $(SHAREDIR)/doc/dkms
SYSTEMD = $(DESTDIR)/usr/lib/systemd/system

#Define the top-level build directory
BUILDDIR := $(shell pwd)
TOPDIR := $(shell pwd)

.PHONY = tarball

all: clean tarball

clean:
	-rm -rf dist/
	-rm -rf dkms
	-rm -rf dkms.8

dkms: dkms.in
	sed -e 's/#RELEASE_STRING#/$(RELEASE_STRING)/' $^ > $@

dkms.8: dkms.8.in
	sed -e 's/#RELEASE_STRING#/$(RELEASE_STRING)/' -e 's/#RELEASE_DATE#/$(RELEASE_DATE)/' $^ > $@

install: dkms dkms.8
	install -D -m 0755 dkms_common.postinst $(LIBDIR)/common.postinst
	install -D -m 0755 dkms $(SBIN)/dkms
	install -D -m 0755 dkms_autoinstaller $(LIBDIR)/dkms_autoinstaller
	install -D -m 0644 dkms_framework.conf $(ETC)/framework.conf
	install -D -m 0755 sign_helper.sh $(ETC)/sign_helper.sh
	install -D -m 0644 dkms.bash-completion $(BASHDIR)/dkms
	install -D -m 0644 dkms.8 $(MAN)/dkms.8
	install -D -m 0755 kernel_install.d_dkms $(KCONF)/install.d/dkms
	install -D -m 0755 kernel_postinst.d_dkms $(KCONF)/postinst.d/dkms
	install -D -m 0755 kernel_prerm.d_dkms $(KCONF)/prerm.d/dkms

install-redhat-systemd: install
	install -D -m 0755 dkms_mkkerneldoth $(LIBDIR)/mkkerneldoth
	install -D -m 0755 dkms_find-provides $(LIBDIR)/find-provides
	install -D -m 0755 lsb_release $(LIBDIR)/lsb_release
	install -D -m 0644 dkms.service $(SYSTEMD)/dkms.service

install-debian: install
	install -D -m 0755 dkms_apport.py $(SHAREDIR)/apport/package-hooks/dkms_packages.py
	install -D -m 0755 kernel_postinst.d_dkms $(KCONF)/header_postinst.d/dkms

install-doc:
	install -d -m 0644 COPYING $(DOCDIR)
	install -d -m 0644 README.md $(DOCDIR)

TARBALL=$(BUILDDIR)/dist/$(RELEASE_STRING).tar.gz
tarball: $(TARBALL)

$(TARBALL): dkms dkms.8
	mkdir -p $(@D)
	git archive --prefix=$(RELEASE_STRING)/ --add-file=dkms --add-file=dkms.8 -o $@ HEAD
