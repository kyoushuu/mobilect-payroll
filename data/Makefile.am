## Process this file with automake to produce Makefile.in

SUBDIRS = icons


desktop_in_files = \
	mobilect-payroll.desktop.in
desktopdir 	 = $(datadir)/applications
desktop_DATA 	 = $(desktop_in_files:.desktop.in=.desktop)

@INTLTOOL_DESKTOP_RULE@


gschema_xml_in_files = \
	com.mobilectpower.payroll.gschema.xml
gsettings_SCHEMAS = $(gschema_xml_in_files:.gschema.xml.in=.gschema.xml)

@INTLTOOL_XML_NOMERGE_RULE@

@GSETTINGS_RULES@


EXTRA_DIST = \
	$(desktop_in_files) \
	$(gschema_xml_in_files)

CLEANFILES = \
	$(desktop_DATA) \
	$(gsettings_SCHEMAS)

DISTCLEANFILES = \
	$(desktop_DATA) \
	$(gsettings_SCHEMAS)

