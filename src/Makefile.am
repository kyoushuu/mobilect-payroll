## Process this file with automake to produce Makefile.in

## Created by Anjuta



AM_CPPFLAGS = \
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\" \
	-DPACKAGE_SRC_DIR=\""$(srcdir)"\" \
	-DPACKAGE_DATA_DIR=\""$(pkgdatadir)"\" \
	$(GTK_CFLAGS) \
	$(PANGO_CFLAGS) \
	$(CAIRO_CFLAGS) \
	$(PANGOCAIRO_CFLAGS) \
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
	administrator-list.vala \
	administrator.vala \
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
	cpanel-holidays.vala \
	cpanel-report.vala \
	password-widget.vala \
	password-dialog.vala \
	administrator-edit-widget.vala \
	administrator-edit-dialog.vala \
	employee-edit-widget.vala \
	employee-edit-dialog.vala \
	time-record-edit-widget.vala \
	time-record-edit-dialog.vala \
	date-time-entry.vala \
	time.vala \
	filter.vala \
	month-info.vala \
	pay-group.vala \
	pay-period.vala \
	time-period.vala \
	report.vala \
	regular-report.vala \
	overtime-report.vala \
	date-entry.vala \
	config.vapi

mobilect_payroll_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg pango \
	--pkg cairo \
	--pkg pangocairo \
	--pkg libxml-2.0 \
	--pkg libgda-5.0 \
	--pkg gee-1.0 \
	--vapidir $(top_srcdir)/vapi

mobilect_payroll_LDADD = \
	$(GTK_LIBS) \
	$(PANGO_LIBS) \
	$(CAIRO_LIBS) \
	$(PANGOCAIRO_LIBS) \
	$(GDA_LIBS) \
	$(XML_LIBS) \
	$(GEE_LIBS)


if NATIVE_WIN32
mobilect_payroll_LDFLAGS = -mwindows
mobilect_payroll_LDADD += mobilect-payroll-win32-res.o
endif

mobilect-payroll-win32-res.o: mobilect-payroll.rc
	$(WINDRES) $< $@

EXTRA_DIST = \
	mobilect-payroll.rc.in

