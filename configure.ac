dnl Process this file with autoconf to produce a configure script.
dnl Created by Anjuta application wizard.

dnl Making releases:
dnl   MOBILECT_PAYROLL_MICRO_VERSION += 1;
dnl   MOBILECT_PAYROLL_INTERFACE_AGE += 1;
dnl   MOBILECT_PAYROLL_BINARY_AGE += 1;
dnl if any functions have been added, set MOBILECT_PAYROLL_INTERFACE_AGE to 0.
dnl if backwards compatibility has been broken,
dnl set MOBILECT_PAYROLL_BINARY_AGE and MOBILECT_PAYROLL_INTERFACE_AGE to 0.

m4_define([mobilect_payroll_major_version], [0])
m4_define([mobilect_payroll_minor_version], [1])
m4_define([mobilect_payroll_micro_version], [0])
dnl lib m4_define([mobilect_payroll_interface_age], [0])
dnl lib m4_define([mobilect_payroll_binary_age],
dnl lib           [m4_eval(100 * mobilect_payroll_minor_version + mobilect_payroll_micro_version)])
m4_define([mobilect_payroll_version],
          [mobilect_payroll_major_version.mobilect_payroll_minor_version.mobilect_payroll_micro_version])
dnl This is the X.Y used in -lmobilect_payroll-FOO-X.Y
dnl lib m4_define([mobilect_payroll_api_version], [0.0])

dnl Define a string for the earliest version that this release has
dnl backwards binary compatibility with for all interfaces a module
dnl might. Unless we add module-only API with lower stability
dnl guarantees, this should be unchanged until we break binary compat
dnl for GPInstruct.
dnl
dnl MOBILECT_PAYROLL_BINARY_VERSION=$MOBILECT_PAYROLL_MAJOR_VERSION.$MOBILECT_PAYROLL_MINOR_VERSION.$LT_CURRENT
m4_define([mobilect_payroll_binary_version], [0.0.0])

AC_INIT([Mobilect Payroll], [mobilect_payroll_version],
		[info@mobilectpower.com],
		[mobilect-payroll],
		[http://www.mobilectpower.com/])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_SRCDIR([ChangeLog])

MOBILECT_PAYROLL_MAJOR_VERSION=mobilect_payroll_major_version
MOBILECT_PAYROLL_MINOR_VERSION=mobilect_payroll_minor_version
MOBILECT_PAYROLL_MICRO_VERSION=mobilect_payroll_micro_version
dnl lib MOBILECT_PAYROLL_INTERFACE_AGE=mobilect_payroll_interface_age
dnl lib MOBILECT_PAYROLL_BINARY_AGE=mobilect_payroll_binary_age
MOBILECT_PAYROLL_VERSION=mobilect_payroll_version
dnl lib MOBILECT_PAYROLL_API_VERSION=mobilect_payroll_api_version
dnl lib MOBILECT_PAYROLL_BINARY_VERSION=mobilect_payroll_binary_version
AC_SUBST(MOBILECT_PAYROLL_MAJOR_VERSION)
AC_SUBST(MOBILECT_PAYROLL_MINOR_VERSION)
AC_SUBST(MOBILECT_PAYROLL_MICRO_VERSION)
dnl lib AC_SUBST(MOBILECT_PAYROLL_INTERFACE_AGE)
dnl lib AC_SUBST(MOBILECT_PAYROLL_BINARY_AGE)
dnl lib AC_SUBST(MOBILECT_PAYROLL_API_VERSION)
AC_SUBST(MOBILECT_PAYROLL_VERSION)
dnl lib AC_SUBST(MOBILECT_PAYROLL_BINARY_VERSION)

dnl libtool versioning
dnl lib m4_define([lt_current], [m4_eval(100 * mobilect_payroll_minor_version + mobilect_payroll_micro_version - mobilect_payroll_interface_age)])
dnl lib m4_define([lt_revision], [mobilect_payroll_interface_age])
dnl lib m4_define([lt_age], [m4_eval(mobilect_payroll_binary_age - mobilect_payroll_interface_age)])
dnl lib LT_VERSION_INFO="lt_current:lt_revision:lt_age"
dnl lib LT_CURRENT_MINUS_AGE=m4_eval(lt_current - lt_age)
dnl lib AC_SUBST(LT_VERSION_INFO)
dnl lib AC_SUBST(LT_CURRENT_MINUS_AGE)


AM_INIT_AUTOMAKE([-Wall -Werror gnu no-dist-gzip dist-xz])

AM_SILENT_RULES([yes])


LT_INIT([disable-static win32-dll])
LT_OUTPUT


AC_PROG_CC


dnl Check for vala
AM_PROG_VALAC([0.16.0])


dnl ***************************************************************************
dnl Internationalization
dnl ***************************************************************************

GETTEXT_PACKAGE=AC_PACKAGE_TARNAME
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE,"$GETTEXT_PACKAGE", [GETTEXT package name])
AM_GLIB_GNU_GETTEXT
IT_PROG_INTLTOOL([0.35.0])


dnl ***************************************************************************
dnl Check for MS Windows
dnl ***************************************************************************
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


PKG_CHECK_MODULES(GTK, [gtk+-3.0])
PKG_CHECK_MODULES(GDK, [gdk-3.0])
PKG_CHECK_MODULES(PANGO, [pango])
PKG_CHECK_MODULES(CAIRO, [cairo])
PKG_CHECK_MODULES(PANGOCAIRO, [pangocairo])
PKG_CHECK_MODULES(GDA, [libgda-5.0])
PKG_CHECK_MODULES(XML, [libxml-2.0])
PKG_CHECK_MODULES(GEE, [gee-1.0])


AC_OUTPUT([
Makefile
src/Makefile
src/mobilect-payroll.rc
vapi/Makefile
data/Makefile
data/mobilect-payroll.desktop.in
data/icons/Makefile
po/Makefile.in
])
