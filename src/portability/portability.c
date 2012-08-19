/*
 * Mobilect Payroll
 * Copyright (C) 2012 - Arnel A. Borja (kyoushuu@yahoo.com)
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */


#include <config.h>
#include <gtk/gtk.h>

#ifdef G_OS_WIN32
#include <gdk/gdkwin32.h>

#include <windows.h>
#include <shlwapi.h>
#endif

#include "portability.h"


gchar *
portability_get_prefix ()
{
#ifdef G_OS_WIN32
	return g_win32_get_package_installation_directory_of_module (NULL);
#else
	return g_strdup (PREFIX);
#endif
}


gboolean
portability_show_file (GtkWidget *window,
                       const gchar *filename)
{
	gboolean result;

#ifdef G_OS_WIN32
	gchar *prefix;

	/* Use ShellExecute in Windows since GIO doesn't fully support Windows */
	prefix = portability_get_prefix ();
	result = ShellExecute (window? GDK_WINDOW_HWND (gtk_widget_get_window (window)) : NULL,
	                       "open", filename, NULL, prefix, SW_SHOWNORMAL) > 32;
	g_free (prefix);
#else
	GdkScreen *screen;
	gchar *uri;

	screen = window? gtk_widget_get_screen (window) : NULL;
	uri = g_filename_to_uri (filename, NULL, NULL);
	if (uri)
	{
		result = gtk_show_uri (screen, uri, GDK_CURRENT_TIME, NULL);
		g_free (uri);
	}
#endif

	return result;
}

