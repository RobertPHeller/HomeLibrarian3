SUBDIRS = Images Scripts Documentation BuildScripts BuildData

ACLOCAL_AMFLAGS = -I .
bin_SCRIPTS = HL3$(EXEEXT)
LibraryScripts = $(wildcard $(top_srcdir)/Scripts/*.tcl) $(wildcard Scripts/*.tcl)
AllImages  = $(wildcard $(top_srcdir)/Images/*.gif) \
                $(wildcard $(top_srcdir)/Images/*.png)
AllHelpDep = Documentation/UserManual/UserManual.html
AllHelpFiles = $(wildcard Documentation/UserManual/*)

EXTRA_DIST = bootstrap snodbc.kit Doxyfile.in Doxyfile
SDX = $(top_srcdir)/BuildScripts/sdx.kit
TCLKIT = $(top_builddir)/BuildData/tclkit${BEXEEXT}

HL3$(EXEEXT) : Scripts/HL3.src $(LibraryScripts) \
		$(top_srcdir)/snodbc.kit $(AllImages) $(AllHelpDep)
	-rm -f  HL3.kit
	-rm -rf HL3.vfs
	$(TCLKIT) $(SDX) qwrap $(srcdir)/Scripts/HL3.src
	$(TCLKIT) $(SDX) unwrap HL3.kit
	-rm -f  HL3.kit
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit HL3 \
		lib $(BWLIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit HL3 \
		lib $(HTTPLIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit HL3 \
		lib $(URILIB)
	$(UNZIP) -qq -d HL3.vfs/lib \
		$(top_srcdir)/BuildData/$(IMG_ZIP)
	$(UNZIP) -qq -d HL3.vfs/lib \
		$(top_srcdir)/BuildData/$(TCLXML_ZIP)
	$(UNZIP) -qq -d HL3.vfs/lib \
		$(top_srcdir)/BuildData/pdf4tcl05.zip
	-rm -rf  snodbc.vfs
	$(TCLKIT) $(SDX) unwrap $(top_srcdir)/snodbc.kit
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit HL3 \
		lib snodbc.vfs/lib
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit HL3 \
		lib snodbc.vfs/compat-lib
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit -srcdir $(srcdir) \
		HL3 lib/Common $(LibraryScripts)
	$(TCLKIT) $(top_srcdir)/BuildScripts/MakePkgIndex.kit HL3 \
		Common
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit -srcdir $(srcdir) \
		HL3 Help $(AllHelpFiles)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit -srcdir $(srcdir) \
		HL3 Images $(AllImages)
	$(TCLKIT) $(SDX) wrap HL3$(EXEEXT) \
			-runtime $(top_srcdir)/BuildData/$(TCLKITRUN)
	-rm -rf  snodbc.vfs
	-rm -rf HL3.vfs

$(top_builddir)/BuildData/tclkit${BEXEEXT}: FORCE
	$(MAKE) -C $(top_builddir)/BuildData tclkit${BEXEEXT}

$(top_builddir)/Scripts/Version.tcl: $(top_builddir)/config.status
	$(MAKE) -C $(top_builddir)/Scripts Version.tcl


FORCE:

Documentation/UserManual/UserManual.html: FORCE
	$(MAKE) -C $(top_builddir)/Documentation UserManual/UserManual.html

dist-binary-tarbz2: all
	$(MAKE) $(AM_MAKEFLAGS) DESTDIR=/tmp/$(PACKAGE)-$(VERSION)-$(target) install
	tar cjf $(PACKAGE)-$(VERSION)-$(target).tar.bz2 -C /tmp/$(PACKAGE)-$(VERSION)-$(target)${prefix} .
	rm -rf /tmp/$(PACKAGE)-$(VERSION)-$(target)

dist-binary-zip: all
	$(MAKE) $(AM_MAKEFLAGS) DESTDIR=/tmp/$(PACKAGE)-$(VERSION)-$(target) install
	rm -f $(PACKAGE)-$(VERSION)-$(target).zip
	(cd  /tmp/$(PACKAGE)-$(VERSION)-$(target)${prefix}; zip -rq $(BUILD_DIR)/$(PACKAGE)-$(VERSION)-$(target).zip .)

	
man1/HL3.1 : Doxyfile Scripts/HL3.src
	-rm -rf man1
	$(DOXYGEN)

clean-local:
	-rm -rf man1


