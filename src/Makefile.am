## Process this file with automake to produce Makefile.in

AM_CPPFLAGS = \
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\" \
	-DPACKAGE_SRC_DIR=\""$(srcdir)"\" \
	-DPACKAGE_DATA_DIR=\""$(pkgdatadir)"\" \
	-DG_LOG_DOMAIN=\"Mobilect-Payroll\" \
	$(GTK_CFLAGS) \
	$(GDK_CFLAGS) \
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
	main/mobilect-payroll.vala \
	main/application.vala \
	main/window.vala \
	database/database.vala \
	database/employee.vala \
	database/employee-list.vala \
	database/administrator.vala \
	database/administrator-list.vala \
	database/time-record.vala \
	database/time-record-list.vala \
	database/month-info.vala \
	database-widgets/administrator-edit-widget.vala \
	database-widgets/administrator-edit-dialog.vala \
	database-widgets/employee-edit-widget.vala \
	database-widgets/employee-edit-dialog.vala \
	database-widgets/time-record-edit-widget.vala \
	database-widgets/time-record-edit-dialog.vala \
	widgets/password-widget.vala \
	widgets/password-dialog.vala \
	login/login-page.vala \
	login/employee-login-page.vala \
	login/admin-login-page.vala \
	cpanel/cpanel.vala \
	cpanel/cpanel-tab.vala \
	cpanel/cpanel-employees.vala \
	cpanel/cpanel-administrators.vala \
	cpanel/cpanel-time-records.vala \
	cpanel/cpanel-holidays.vala \
	cpanel/cpanel-report.vala \
	report/report.vala \
	report/regular-report.vala \
	report/overtime-report.vala \
	datetime/time.vala \
	datetime/time-spin-button.vala \
	datetime/date-spin-button.vala \
	datetime/date-time-spin-button.vala \
	filter/filter.vala \
	filter/pay-group.vala \
	filter/pay-period.vala \
	filter/time-period.vala \
	config.vapi

mobilect_payroll_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gdk-3.0 \
	--pkg pango \
	--pkg cairo \
	--pkg pangocairo \
	--pkg libxml-2.0 \
	--pkg libgda-5.0 \
	--pkg gee-1.0 \
	--vapidir $(top_srcdir)/vapi

mobilect_payroll_LDADD = \
	$(GTK_LIBS) \
	$(GDK_LIBS) \
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

