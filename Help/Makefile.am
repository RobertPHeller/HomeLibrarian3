helpdir = $(datadir)/$(PACKAGE)-$(VERSION)/Help
GIFFiles = 
GeneratedHelpFiles = Copying.hh Warranty.hh Version.hh
HelpFiles = Help.hh General.hh Database.hh Print.hh Edit.hh Import.hh
HelpFiles += Search.hh Tutorial.hh Amazon.hh
HelpIndex = hh.index
HelpIndexBuilder = $(top_srcdir)/BuildScripts/HelpIndexBuild.tcl
IndexHHBuilder = $(top_srcdir)/BuildScripts/IndexHH.tcl
IndexHH = index.hh

EXTRA_DIST = $(HelpFiles) $(GIFFiles)
CONFIG_CLEAN_FILES = $(HelpIndex) $(IndexHH)
help_DATA = $(HelpFiles) $(GIFFiles) $(GeneratedHelpFiles) $(HelpIndex) \
	$(IndexHH)

Copying.hh : ../COPYING
	echo '0 Copying' | cat - ../COPYING >Copying.hh

Warranty.hh : ../COPYING
	echo '0 Warranty' > Warranty.hh
	sed '1,/of promoting the sharing and reuse of software generally./d' \
		../COPYING | \
	sed '/How to Apply These Terms to Your New Programs/,999d' >>Warranty.hh

Version.hh : $(top_srcdir)/configure
	echo '0 Version' > Version.hh
	echo 'This is $(PACKAGE_STRING), Copyright 2006 by Robert Heller D/B/A Deepwoods Software.' >>Version.hh
	echo 'See <Copying> for complete copyright information.'  >>Version.hh

$(HelpIndex): $(HelpFiles) $(GeneratedHelpFiles)
	$(HOSTTCLSH) $(HelpIndexBuilder) $(HelpIndex) $(HelpFiles) \
		$(GeneratedHelpFiles)

$(IndexHH) : $(HelpIndex) $(HelpFiles) $(GeneratedHelpFiles)
	$(HOSTTCLSH) $(IndexHHBuilder) $(HelpIndex) $(IndexHH) $(HelpFiles) \
		$(GeneratedHelpFiles)

$(top_srcdir)/configure: $(top_srcdir)/configure.ac
	$(MAKE) -C $(top_srcdir) configure
