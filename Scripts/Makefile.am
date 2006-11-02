
scriptlibdir = $(datadir)/$(PACKAGE)-$(VERSION)/scriptlib
imagelibdir = $(datadir)/$(PACKAGE)-$(VERSION)/imagelib
docdir = $(datadir)/$(PACKAGE)-$(VERSION)/documentation
helpdir = $(datadir)/$(PACKAGE)-$(VERSION)/Help
LibraryScripts = BWHelp.tcl labelselectcolor.tcl panedw.tcl fileentry.tcl \
                 labelspinbox.tcl splash.tcl labelcombobox.tcl mainwindow.tcl \
                 BWStdMenuBar.tcl AnimatedHeader.tcl SearchWindow.tcl \
		 EditWindow.tcl DatabaseFunctions.tcl AECFunctions.tcl \
		 PrintFunctions.tcl ImportV1Ascii.tcl ImportV2Ascii.tcl
		 

EXTRA_DIST = $(LibraryScripts) HL3.src

scriptlib_DATA = $(LibraryScripts) pkgIndex.tcl

pkgIndex.tcl : $(LibraryScripts)
	echo "pkg_mkIndex . $(LibraryScripts)" | $(TCLSH_PROG)

bin_SCRIPTS = HL3
CONFIG_CLEAN_FILES = HL3
HL3 : HL3.src
	sed -f $(top_srcdir)/config_tcl <$< >$@
	chmod +x $@

$(top_builddir)/config_tcl.sed: $(top_builddir)/config.status \
				$(top_builddir)/config_tcl.sed.in
	cd $(top_builddir) && CONFIG_FILES=$(@F) CONFIG_HEADERS= $(SHELL) ./config.status


