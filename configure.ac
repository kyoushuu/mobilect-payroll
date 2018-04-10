dnl Process this file with autoconf to produce a configure script.
dnl Created by Anjuta application wizard.

AC_INIT([Mobilect Payroll], [0.1],
		[info@mobilectpower.com],
		[mobilect-payroll],
		[http://www.mobilectpower.com/])

AC_CONFIG_HEADERS([config.h])

AM_INIT_AUTOMAKE([-Wall -Werror gnu no-dist-gzip dist-xz])

AM_SILENT_RULES([yes])

AC_PROG_CC


LT_INIT


dnl Check for vala
AM_PROG_VALAC([0.10.0])


dnl ***************************************************************************
dnl Internationalization
dnl ***************************************************************************

GETTEXT_PACKAGE=AC_PACKAGE_NAME
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE,"$GETTEXT_PACKAGE", [GETTEXT package name])
AM_GLIB_GNU_GETTEXT
IT_PROG_INTLTOOL([0.35.0])


PKG_CHECK_MODULES(GTK, [gtk+-3.0])
PKG_CHECK_MODULES(PANGO, [pango])
PKG_CHECK_MODULES(CAIRO, [cairo])
PKG_CHECK_MODULES(PANGOCAIRO, [pangocairo])
PKG_CHECK_MODULES(GDA, [libgda-5.0])
PKG_CHECK_MODULES(XML, [libxml-2.0])
PKG_CHECK_MODULES(GEE, [gee-1.0])


AC_OUTPUT([
Makefile
src/Makefile
vapi/Makefile
po/Makefile.in
])
