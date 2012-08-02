AC_INIT()

AC_CANONICAL_BUILD
AC_CANONICAL_HOST
AC_SUBST(build)
AC_CANONICAL_TARGET
AC_SUBST(target)

dnl Force cross_compiling, even if it *looks* like we can run cross-built 
dnl binaries (get around wine's cleverness).
if test ${cross_compiling} = "maybe"; then
  if test ${target_os} != ${build_os}; then
    cross_compiling=yes
  fi
fi  

AC_CONFIG_SRCDIR(Scripts/HL3.src)
AM_INIT_AUTOMAKE(HomeLibrarian,3.0b3)

AC_CONFIG_FILES([Makefile Images/Makefile Scripts/Makefile \
		 Documentation/Makefile BuildScripts/Makefile \
		 BuildData/Makefile Doxyfile HomeLibrarian.spec])

if test "x${prefix}" = "xNONE"; then
    prefix=/usr/local
fi
if test "x${exec_prefix}" = "xNONE"; then
    exec_prefix="${prefix}"
fi

BUILD_DIR=`pwd`
TOP_DIR=${BUILD_DIR}

AC_SUBST(TOP_DIR)
AC_SUBST(BUILD_DIR)


AC_PATH_PROG(DOXYGEN,doxygen,/bin/true)
AC_PATH_PROG(PDFLATEX,pdflatex,/bin/true)
AC_CHECK_PROGS(HTLATEX,[htlatex htlatex.sh])
AC_SUBST(HTLATEX)
AC_PATH_PROG(MAKEINDEX,makeindex,/bin/true)
AC_PATH_PROG(BIBTEX,bibtex,/bin/true)
AC_PATH_PROGS(HOSTTCLSH,[tclsh8.4 tclsh])

TCL_LIBRARY=`echo 'puts $tcl_library'|${HOSTTCLSH}`
TCL_AUTO_PATH=`echo 'puts $auto_path'|${HOSTTCLSH}`

AC_MSG_CHECKING(bwidget dir)
BWLIB=`echo 'puts $tcl_library'|${HOSTTCLSH}`
dirs=${TCL_AUTO_PATH}
for i in $dirs ; do 
  subdirs="$i/bwidget* $i/tcllib*/bwidget*"
  for j in $subdirs ; do
    if test -d "$j" -a -f "$j/pkgIndex.tcl"; then
      BWLIB=`cd $j; pwd`
    fi
  done
done
AC_ARG_WITH(bwlib, [  --with-bwlib=DIR          use BWidget from DIR], BWLIB=$withval,)
if test -d $BWLIB; then
   AC_MSG_RESULT([using BWidget library in $BWLIB])
else
   AC_MSG_ERROR(BWidget library directory $BWLIB doesn't exist)
fi
AC_SUBST(BWLIB)

#AC_MSG_CHECKING(snit dir)
#SNITLIB=${TCL_LIBRARY}
#dirs=${TCL_AUTO_PATH}
#for i in $dirs ; do 
#  subdirs="$i/snit* $i/tcllib*/snit*"
#  for j in $subdirs ; do
#    if test -d "$j" -a -f "$j/pkgIndex.tcl"; then
#      SNITLIB=`cd $j; pwd`
#    fi
#  done
#done
#AC_ARG_WITH(snitlib, [  --with-snitlib=DIR          use snit from DIR], SNITLIB=$withval,)
#if test -d $SNITLIB; then
#   AC_MSG_RESULT([using snit library in $SNITLIB])
#else
#   AC_MSG_ERROR(snit library directory $SNITLIB doesn't exist)
#fi
#AC_SUBST(SNITLIB)

AC_MSG_CHECKING(http dir)
HTTPLIB=${TCL_LIBRARY}
dirs=${TCL_AUTO_PATH}
for i in $dirs ; do 
  subdirs="$i/tcllib*/http* $i/http*"
  for j in $subdirs ; do
    if test -d "$j" -a -f "$j/pkgIndex.tcl"; then
      HTTPLIB=`cd $j; pwd`
    fi
  done
done
AC_ARG_WITH(httplib, [  --with-httplib=DIR          use http from DIR], HTTPLIB=$withval,)
if test -d $HTTPLIB; then
   AC_MSG_RESULT([using http library in $HTTPLIB])
else
   AC_MSG_ERROR(http library directory $HTTPLIB doesn't exist)
fi
AC_SUBST(HTTPLIB)


AC_MSG_CHECKING(uri dir)
URILIB=${TCL_LIBRARY}
dirs=${TCL_AUTO_PATH}
for i in $dirs ; do 
  subdirs="$i/tcllib*/uri* $i/uri*"
  for j in $subdirs ; do
    if test -d "$j" -a -f "$j/pkgIndex.tcl"; then
      URILIB=`cd $j; pwd`
    fi
  done
done
AC_ARG_WITH(urilib, [  --with-urilib=DIR          use uri from DIR], URILIB=$withval,)
if test -d $URILIB; then
   AC_MSG_RESULT([using uri library in $URILIB])
else
   AC_MSG_ERROR(uri library directory $URILIB doesn't exist)
fi
AC_SUBST(URILIB)

AC_PATH_PROGS(UNZIP,unzip)
AC_MSG_CHECKING([Checking target Img, Tclxml,  and tclkit])
case $target_os in 
  linux-gnu)
    case $target_cpu in
      x86_64|i*86)
        AC_SUBST(IMG_ZIP, Img-1.3-Linux32.zip)
        AC_SUBST(TCLKITRUN, tclkit-linux-x86)
        AC_SUBST(TCLXML_ZIP, Tclxml3.1-Linux32.zip)
        ;;
      *)
        AC_MSG_ERROR([Unsupported Linux arch: $target_cpu])
        ;;
     esac
     ;;

   mingw32 | winnt | windows* | cygwin)
     AC_SUBST(IMG_ZIP, Img-1.3-win32.zip)
     AC_SUBST(TCLKITRUN, tclkit-win32.exe)
     AC_SUBST(TCLXML_ZIP, Tclxml2.6-win32.zip)
     AC_SUBST(EXEEXT, .exe)
     ;;
   *) 
     AC_MSG_ERROR([Unsupported Operating System: $target_os])
     ;;
esac
AC_MSG_RESULT([IMG_ZIP is $IMG_ZIP, TCLXML_ZIP is $TCLXML_ZIP, and TCLKITRUN is $TCLKITRUN])

AC_MSG_CHECKING([Checking build tclkit])
case $build_os in 
  macos | darwin) 
    AC_SUBST(TCLKITBSRC, tclkit-darwin-univ-aqua)
    AC_SUBST(BEXEEXT, )
    ;;
  linux-gnu)
    AC_SUBST(BEXEEXT, )
    case $build_cpu in
      x86_64)
        AC_SUBST(TCLKITBSRC, tclkit-linux-x86_64)
        ;;
      i*86)
        AC_SUBST(TCLKITBSRC, tclkit-linux-x86)
        ;;
      *)
        AC_MSG_ERROR([Unsupported Linux arch: $build_cpu])
        ;;
     esac
     ;;

   mingw32 | winnt | windows* | cygwin)
     AC_SUBST(BEXEEXT, .exe)
     AC_SUBST(TCLKITBSRC, tclkit-win32.exe)
     ;;
   *) 
     AC_MSG_ERROR([Unsupported Operating System: $build_os])
     ;;
esac
AC_MSG_RESULT([TCLKITBSRC is $TCLKITBSRC])

AC_PATH_PROG(SED,sed)

AC_OUTPUT

