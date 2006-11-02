AC_INIT(HomeLibrarian,3.0)
AC_CONFIG_SRCDIR(Scripts/HL3.src)
AM_INIT_AUTOMAKE

AC_CONFIG_FILES([config_tcl Makefile Images/Makefile Scripts/Makefile Documentation/Makefile 
		 BuildScripts/Makefile Help/Makefile])

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

TEA_INIT([3.5])
TEA_PATH_TCLCONFIG
TEA_LOAD_TCLCONFIG
TEA_PATH_TKCONFIG
TEA_LOAD_TKCONFIG
TEA_PROG_TCLSH
TEA_PROG_WISH

AC_PATH_PROG(PDFLATEX,pdflatex,/bin/true)
AC_CHECK_PROGS(HTLATEX,[htlatex htlatex.sh])
AC_SUBST(HTLATEX)
AC_PATH_PROG(MAKEINDEX,makeindex,/bin/true)
AC_PATH_PROG(BIBTEX,bibtex,/bin/true)
TCL_LIBRARY=`echo 'puts $tcl_library'|${TCLSH_PROG}`
TCL_AUTO_PATH="${TCL_LIBRARY} ${TCL_PACKAGE_PATH}"

AC_MSG_CHECKING(bwidget dir)
BWLIB=`echo 'puts $tcl_library'|${TCLSH}`
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

AC_MSG_CHECKING(snit dir)
SNITLIB=${TCL_LIBRARY}
dirs=${TCL_AUTO_PATH}
for i in $dirs ; do 
  subdirs="$i/snit* $i/tcllib*/snit*"
  for j in $subdirs ; do
    if test -d "$j" -a -f "$j/pkgIndex.tcl"; then
      SNITLIB=`cd $j; pwd`
    fi
  done
done
AC_ARG_WITH(snitlib, [  --with-snitlib=DIR          use snit from DIR], SNITLIB=$withval,)
if test -d $SNITLIB; then
   AC_MSG_RESULT([using snit library in $SNITLIB])
else
   AC_MSG_ERROR(snit library directory $SNITLIB doesn't exist)
fi
AC_SUBST(SNITLIB)

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

AC_MSG_CHECKING(TclODBC dir)
TCLODBCLIB=${TCL_LIBRARY}
dirs=${TCL_AUTO_PATH}
for i in $dirs ; do 
  subdirs="$i/TclODBC*"
  for j in $subdirs ; do
    if test -d "$j" -a -f "$j/pkgIndex.tcl"; then
      TCLODBCLIB=`cd $j; pwd`
    fi
  done
done
AC_ARG_WITH(tclodbclib, [  --with-tclodbclib=DIR          use TclODBC from DIR], TCLODBCLIB=$withval,)
if test -d $TCLODBCLIB; then
   AC_MSG_RESULT([using TclODBC library in $TCLODBCLIB])
else
   AC_MSG_ERROR(TclODBC library directory $TCLODBCLIB doesn't exist)
fi
AC_SUBST(TCLODBCLIB)

AC_MSG_CHECKING(Tclxml dir)
TCLXMLLIB=${TCL_LIBRARY}
dirs=${TCL_AUTO_PATH}
for i in $dirs ; do 
  subdirs="$i/Tclxml*"
  for j in $subdirs ; do
    if test -d "$j" -a -f "$j/pkgIndex.tcl"; then
      TCLXMLLIB=`cd $j; pwd`
    fi
  done
done
AC_ARG_WITH(tclxmllib, [  --with-tclxmllib=DIR          use Tclxml from DIR], TCLXMLLIB=$withval,)
if test -d $TCLXMLLIB; then
   AC_MSG_RESULT([using Tclxml library in $TCLXMLLIB])
else
   AC_MSG_ERROR(Tclxml library directory $TCLXMLLIB doesn't exist)
fi
AC_SUBST(TCLXMLLIB)

AC_OUTPUT

