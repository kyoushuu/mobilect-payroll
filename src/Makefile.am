## Process this file with automake to produce Makefile.in

AM_CPPFLAGS = \
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\" \
	-DPACKAGE_SRC_DIR=\""$(srcdir)"\" \
	-DPACKAGE_DATA_DIR=\""$(pkgdatadir)"\" \
	-DG_LOG_DOMAIN=\"Mobilect-Payroll\" \
	$(GTK_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(PANGO_CFLAGS) \
	$(CAIRO_CFLAGS) \
	$(PANGOCAIRO_CFLAGS) \
	$(XML_CFLAGS) \
	$(GDA_CFLAGS) \
	$(GEE_CFLAGS) \
	-I$(top_srcdir)/src \
	-include $(top_builddir)/config.h

AM_CFLAGS = \
	-w


bin_PROGRAMS = mobilect-payroll

mobilect_payroll_SOURCES = \
	main/mobilect-payroll.vala \
	main/application.vala \
	main/window.vala \
	main/preferences-dialog.vala \
	database/database.vala \
	database/employee.vala \
	database/employee-list.vala \
	database/time-record.vala \
	database/time-record-list.vala \
	database/deductions.vala \
	database/administrator.vala \
	database/administrator-list.vala \
	database/month-info.vala \
	database-widgets/administrator-edit-widget.vala \
	database-widgets/administrator-edit-dialog.vala \
	database-widgets/employee-edit-widget.vala \
	database-widgets/employee-edit-dialog.vala \
	database-widgets/time-record-edit-widget.vala \
	database-widgets/time-record-edit-dialog.vala \
	widgets/find-widget.vala \
	widgets/find-dialog.vala \
	widgets/password-widget.vala \
	widgets/password-dialog.vala \
	widgets/sort-tree-view-dialog.vala \
	login/login-page.vala \
	login/employee-login-page.vala \
	login/admin-login-page.vala \
	cpanel/cpanel.vala \
	cpanel/cpanel-tab.vala \
	cpanel/cpanel-employees.vala \
	cpanel/cpanel-administrators.vala \
	cpanel/cpanel-time-records.vala \
	cpanel/cpanel-deductions.vala \
	cpanel/cpanel-holidays.vala \
	cpanel/cpanel-report.vala \
  settings/settings.vala \
	report/report.vala \
	report/regular-report.vala \
	report/overtime-report.vala \
	datetime/time.vala \
	datetime/time-spin-button.vala \
	datetime/date-spin-button.vala \
	datetime/date-time-spin-button.vala \
	datetime/period-spin-button.vala \
	filter/filter.vala \
	filter/pay-group.vala \
	filter/pay-period.vala \
	filter/time-period.vala \
	config.vapi \
  mobilect-payroll-resources.c

mobilect_payroll_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gdk-3.0 \
	--pkg glib-2.0 \
	--pkg gobject-2.0 \
	--pkg pango \
	--pkg cairo \
	--pkg pangocairo \
	--pkg libxml-2.0 \
	--pkg libgda-5.0 \
	--pkg gee-1.0 \
	--vapidir $(top_srcdir)/vapi

mobilect_payroll_LDADD = \
	$(GTK_LIBS) \
	$(GLIB_LIBS) \
	$(PANGO_LIBS) \
	$(CAIRO_LIBS) \
	$(PANGOCAIRO_LIBS) \
	$(XML_LIBS) \
	$(GDA_LIBS) \
	$(GEE_LIBS)


if NATIVE_WIN32
mobilect_payroll_LDFLAGS = -mwindows
mobilect_payroll_LDADD += mobilect-payroll-win32-res.o
endif



ui_files = \
	mobilect-payroll-ui.xml \
	mobilect-payroll-cpanel-ui.xml \
	mobilect-payroll-cpanel-employees-ui.xml \
	mobilect-payroll-cpanel-administrators-ui.xml \
	mobilect-payroll-cpanel-time-records-ui.xml \
	mobilect-payroll-cpanel-report-ui.xml


mobilect-payroll-win32-res.o: mobilect-payroll.rc
	$(WINDRES) $< $@

mobilect-payroll-resources.c: mobilect-payroll.gresource.xml $(ui_files)
	$(AM_V_GEN) $(GLIB_COMPILE_RESOURCES) --target=$@ --sourcedir=$(srcdir) --generate $(srcdir)/mobilect-payroll.gresource.xml


EXTRA_DIST = \
	mobilect-payroll.rc.in \
	mobilect-payroll.gresource.xml \
	$(ui_files)

