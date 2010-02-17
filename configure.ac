AC_INIT(HomeLibrarian,3.0b2)
AC_CONFIG_SRCDIR(Scripts/HL3.src)
AM_INIT_AUTOMAKE

AC_CONFIG_FILES([Makefile Images/Makefile Scripts/Makefile Documentation/Makefile 
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


AC_PATH_PROG(PDFLATEX,pdflatex,/bin/true)
AC_CHECK_PROGS(HTLATEX,[htlatex htlatex.sh])
AC_SUBST(HTLATEX)
AC_PATH_PROG(MAKEINDEX,makeindex,/bin/true)
AC_PATH_PROG(BIBTEX,bibtex,/bin/true)
AC_PATH_PROGS(SDX,[sdx.kit sdx])
AC_PATH_PROGS(TCLKIT,tclkit)
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

TCLKITRUN="${TCL_EXEC_PREFIX}/bin/tclkit$EXEEXT"
AC_ARG_WITH(tclkitrun, [  --with-tclkitrun=filename     use tclkit runtime in fi
lename], TCLKITRUN=$withval,)
if test -x $TCLKITRUN;  then
   AC_MSG_RESULT([using tclkit runtime $TCLKITRUN])
else
   AC_MSG_ERROR([Can't find tclkit, please use --with-tclkitrun to set the tclki
t])
fi
AC_SUBST(TCLKITRUN)

AC_PATH_PROG(PDFLATEX,pdflatex,/bin/true)
AC_PATH_PROGS(HTLATEX,[htlatex htlatex.sh],/bin/true)


AC_OUTPUT

