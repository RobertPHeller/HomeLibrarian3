ACLOCAL_AMFLAGS = -I .
bin_SCRIPTS = HL3$(EXEEXT)
SUBDIRS = Images Scripts Documentation BuildScripts Help
LibraryScripts = Scripts/BWHelp.tcl Scripts/labelselectcolor.tcl \
		 Scripts/panedw.tcl Scripts/fileentry.tcl \
		 Scripts/labelspinbox.tcl Scripts/splash.tcl \
		 Scripts/labelcombobox.tcl Scripts/mainwindow.tcl \
		 Scripts/BWStdMenuBar.tcl Scripts/AnimatedHeader.tcl \
		 Scripts/SearchWindow.tcl Scripts/EditWindow.tcl \
		 Scripts/DatabaseFunctions.tcl Scripts/AECFunctions.tcl \
		 Scripts/PrintFunctions.tcl Scripts/ImportV1Ascii.tcl \
		 Scripts/ImportV2Ascii.tcl
		 
EXTRA_DIST = bootstrap snodbc.kit


HL3$(EXEEXT) : Scripts/HL3.src $(LibraryScripts) \
		$(top_builddir)/Help/hh.index \
		$(top_builddir)/Help/index.hh \
		$(top_builddir)/snodbc.kit \
		$(top_builddir)/Images/*.gif
	-rm -f  HL3.kit
	-rm -rf HL3.vfs
	$(TCLKIT) $(SDX) qwrap Scripts/HL3.src
	$(TCLKIT) $(SDX) unwrap HL3.kit
	-rm -f  HL3.kit
	$(TCLKIT) $(top_builddir)/BuildScripts/AddKitDir.kit HL3 \
		lib $(BWLIB)
	$(TCLKIT) $(top_builddir)/BuildScripts/AddKitDir.kit HL3 \
		lib $(HTTPLIB)
	$(TCLKIT) $(top_builddir)/BuildScripts/AddKitDir.kit HL3 \
		lib $(URILIB)
	$(TCLKIT) $(top_builddir)/BuildScripts/AddKitDir.kit HL3 \
		lib $(TCLXMLLIB)
	-rm -rf  snodbc.vfs
	$(TCLKIT) $(SDX) unwrap $(top_builddir)/snodbc.kit
	$(TCLKIT) $(top_builddir)/BuildScripts/AddKitDir.kit HL3 \
		lib snodbc.vfs/lib
	$(TCLKIT) $(top_builddir)/BuildScripts/AddKitDir.kit HL3 \
		lib snodbc.vfs/compat-lib
	$(TCLKIT) $(top_builddir)/BuildScripts/AddKitFile.kit HL3 \
		lib/Common $(LibraryScripts)
	$(TCLKIT) $(top_builddir)/BuildScripts/MakePkgIndex.kit HL3 \
		Common
	$(TCLKIT) $(top_builddir)/BuildScripts/AddKitFile.kit HL3 \
		Help $(top_builddir)/Help/*.hh \
		     $(top_builddir)/Help/hh.index
	$(TCLKIT) $(top_builddir)/BuildScripts/AddKitFile.kit HL3 \
		Images $(top_builddir)/Images/*.gif
	$(TCLKIT) $(SDX) wrap HL3$(EXEEXT) -runtime $(TCLKITRUN)
	-rm -rf  snodbc.vfs
	-rm -rf HL3.vfs

$(top_builddir)/Help/hh.index : \
	$(top_builddir)/Help/*.hh
	$(MAKE) -C $(top_builddir)/Help/hh.index

$(top_builddir)/Help/index.hh : \
	$(top_builddir)/Help/*.hh
	$(MAKE) -C $(top_builddir)/Help/index.hh


binzip: $(bin_SCRIPTS)
	-rm -f $(distdir)-$(PLATFORM)Bin.zip
	zip $(distdir)-$(PLATFORM)Bin.zip $^

bintgz: $(bin_SCRIPTS)
	tar cjvf $(distdir)-$(PLATFORM)Bin.tar.bz2 $^

