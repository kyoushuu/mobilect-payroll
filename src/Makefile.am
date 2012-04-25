## Process this file with automake to produce Makefile.in

## Created by Anjuta



AM_CPPFLAGS = \
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\" \
	-DPACKAGE_SRC_DIR=\""$(srcdir)"\" \
	-DPACKAGE_DATA_DIR=\""$(pkgdatadir)"\" \
	$(GTK_CFLAGS) \
	$(GDA_CFLAGS) \
	$(XML_CFLAGS) \
	$(GEE_CFLAGS) \
	-I$(top_srcdir)/src \
	-include $(top_builddir)/config.h

AM_CFLAGS = \
	-w \
	-g


bin_PROGRAMS = mobilect-payroll

mobilect_payroll_SOURCES = \
	mobilect-payroll.vala \
	application.vala \
	database.vala \
	employee-list.vala \
	employee.vala \
	time-record-list.vala \
	time-record.vala \
	window.vala \
	login-page.vala \
	employee-login-page.vala \
	admin-login-page.vala \
	cpanel.vala \
	cpanel-tab.vala \
	cpanel-administrators.vala \
	cpanel-employees.vala \
	cpanel-preferences.vala \
	cpanel-time-records.vala \
	employee-edit-widget.vala \
	employee-edit-dialog.vala \
	time-record-edit-widget.vala \
	time-record-edit-dialog.vala \
	date-time-entry.vala \
	config.vapi

mobilect_payroll_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg libxml-2.0 \
	--pkg libgda-5.0 \
	--pkg gee-1.0 \
	--vapidir $(top_srcdir)/vapi

mobilect_payroll_LDADD = \
	$(GTK_LIBS) \
	$(GDA_LIBS) \
	$(XML_LIBS) \
	$(GEE_LIBS)
