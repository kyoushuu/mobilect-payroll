m4_define([mobilect_payroll_major_version], [0])
m4_define([mobilect_payroll_minor_version], [1])
m4_define([mobilect_payroll_micro_version], [0])
m4_define([mobilect_payroll_version],
          [mobilect_payroll_major_version.mobilect_payroll_minor_version.mobilect_payroll_micro_version])

AC_INIT([Mobilect Payroll], [mobilect_payroll_version],
        [info@mobilectpower.com],
        [mobilect-payroll],
        [http://www.mobilectpower.com/])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_SRCDIR([ChangeLog])

MOBILECT_PAYROLL_MAJOR_VERSION=mobilect_payroll_major_version
MOBILECT_PAYROLL_MINOR_VERSION=mobilect_payroll_minor_version
MOBILECT_PAYROLL_MICRO_VERSION=mobilect_payroll_micro_version
MOBILECT_PAYROLL_VERSION=mobilect_payroll_version
AC_SUBST(MOBILECT_PAYROLL_MAJOR_VERSION)
AC_SUBST(MOBILECT_PAYROLL_MINOR_VERSION)
AC_SUBST(MOBILECT_PAYROLL_MICRO_VERSION)
AC_SUBST(MOBILECT_PAYROLL_VERSION)


AM_INIT_AUTOMAKE([-Wall -Werror gnu no-dist-gzip dist-xz])

AM_SILENT_RULES([yes])


AC_PROG_CC
AM_PROG_VALAC([0.16.0])


dnl ***************************************************************************
dnl Check for MS Windows
dnl ***************************************************************************

AC_CANONICAL_HOST

case $host_os in
  *mingw* | pw32* | cygwin*)
    platform_win32=yes
    ;;
  *)
    platform_win32=no
    ;;
esac
AM_CONDITIONAL(PLATFORM_WIN32, test x"$platform_win32" = "xyes")

case $host_os in
  *mingw*)
    native_win32=yes
    ;;
  *)
    native_win32=no
    ;;
esac
AM_CONDITIONAL(NATIVE_WIN32, test x"$native_win32" = "xyes")

if test "$native_win32" = "yes"; then
  AC_CHECK_TOOL(WINDRES, windres, no)
  if test "$WINDRES" = no; then
    AC_MSG_ERROR([*** Could not find an implementation of windres in your PATH.])
  fi
fi


dnl ***************************************************************************
dnl Internationalization
dnl ***************************************************************************

AM_GNU_GETTEXT_VERSION([0.19])
AM_GNU_GETTEXT([external])

GETTEXT_PACKAGE="$PACKAGE"
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE", [GETTEXT package name])


dnl ***************************************************************************
dnl GSettings
dnl ***************************************************************************

GLIB_GSETTINGS


dnl ***************************************************************************
dnl User manual
dnl ***************************************************************************

YELP_HELP_INIT


dnl ***************************************************************************
dnl Check packages
dnl ***************************************************************************

GTK_REQUIRED=3.4.0
GLIB_REQUIRED=2.32.0
GDA_REQUIRED=5.0.0

PKG_CHECK_MODULES(GTK, gtk+-3.0 >= $GTK_REQUIRED gdk-3.0 >= $GTK_REQUIRED)
PKG_CHECK_MODULES(GLIB, glib-2.0 >= $GLIB_REQUIRED gobject-2.0 >= $GLIB_REQUIRED)
PKG_CHECK_MODULES(PANGO, pango)
PKG_CHECK_MODULES(CAIRO, cairo)
PKG_CHECK_MODULES(PANGOCAIRO, pangocairo)
PKG_CHECK_MODULES(XML, libxml-2.0)
PKG_CHECK_MODULES(GDA, libgda-5.0 >= $GDA_REQUIRED)
PKG_CHECK_MODULES(GEE, gee-0.8,
                  [GEE_MODULE=gee-0.8],
                  [PKG_CHECK_MODULES(GEE, gee-1.0, [GEE_MODULE=gee-1.0])])
AC_SUBST(GEE_MODULE)


dnl ***************************************************************************
dnl Check tools
dnl ***************************************************************************

GLIB_COMPILE_RESOURCES=`$PKG_CONFIG --variable glib_compile_resources gio-2.0`
AC_SUBST(GLIB_COMPILE_RESOURCES)


AC_CONFIG_FILES([
Makefile
src/Makefile
src/mobilect-payroll.rc
vapi/Makefile
data/Makefile
data/mobilect-payroll.desktop.in
data/icons/Makefile
help/Makefile
po/Makefile.in
])

AC_OUTPUT
