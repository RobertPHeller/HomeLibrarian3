EXTRA_DIST=Img-1.3-Mac-Universal.zip Img-1.3-Linux32.zip Img-1.3-Linux64.zip \
	   Img-1.3-win32.zip tclkit-darwin-univ-aqua tclkit-linux-x86 \
	   tclkit-linux-x86_64 tclkit-win32.exe Tclxml2.6-win32.zip \
	   Tclxml3.1-Linux32.zip Tclxml3.1-Linux64.zip pdf4tcl05.zip

BUILT_SOURCES = tclkit${BEXEEXT}

noinst_SCRIPTS = tclkit${BEXEEXT}

EXTRA_SCRIPTS = tclkit-darwin-univ-aqua tclkit-linux-x86 tclkit-linux-x86_64 \
		 tclkit-win32.exe
#bin_SCRIPTS = $(TCLKITRUN)

tclkit${BEXEEXT}: $(TCLKITBSRC) $(top_builddir)/config.status
	cp $(srcdir)/$(TCLKITBSRC) ./tclkit${BEXEEXT}

FORCE:

