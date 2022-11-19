## Process this file with automake to produce Makefile.in

SUBDIRS = icons


desktop_in_files = \
	mobilect-payroll.desktop.in
desktopdir 	 = $(datadir)/applications
desktop_DATA 	 = $(desktop_in_files:.desktop.in=.desktop)
$(desktop_DATA): $(desktop_in_files)
	$(AM_V_GEN) $(MSGFMT) --desktop --template $< -d $(top_srcdir)/po -o $@


gsettings_SCHEMAS = \
	com.mobilectpower.payroll.gschema.xml

@GSETTINGS_RULES@


EXTRA_DIST = \
	$(desktop_in_files)

CLEANFILES = \
	$(desktop_DATA)

DISTCLEANFILES = \
	$(desktop_DATA)

