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
#else
#include <monetary.h>
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
	g_return_if_fail (GTK_IS_WINDOW (window));

	gboolean result;
	gchar *uri;

	uri = g_filename_to_uri (filename, NULL, NULL);
	if (uri)
	{
#ifdef G_OS_WIN32
		gchar *prefix;

		/* Use ShellExecute in Windows since GIO doesn't fully support Windows */
		prefix = portability_get_prefix ();
		result = ShellExecute (GDK_WINDOW_HWND (gtk_widget_get_window (window)),
	                       "open", filename, NULL, prefix, SW_SHOWNORMAL) > 32;
		g_free (prefix);
#else
		result = gtk_show_uri (gtk_widget_get_screen (window),
		                       uri, GDK_CURRENT_TIME, NULL);
#endif

		g_free (uri);
	}

	return result;
}


gchar *
portability_format_money (gdouble number, gint decimal_places)
{
	gboolean success;
	gchar *format;
	gchar buffer[64];

#ifdef G_OS_WIN32
	gchar *value;

	format = g_strdup_printf ("%%.%dlf", decimal_places);
	value = g_strdup_printf (format, number);

	success = GetNumberFormat (LOCALE_USER_DEFAULT, 0, value, NULL,
	                           buffer, sizeof (buffer)) > 0;

	if (success && decimal_places == 0)
	{
		int size, i;

		size = strlen (buffer);
		for (i = size - 1; i >= 0; i--)
		{
			if (!isdigit (buffer[i]))
			{
				buffer[i] = '\0';
				break;
			}
		}
	}

	g_free (value);
#else
	format = g_strdup_printf ("%%!.%dn", decimal_places);
	success = strfmon (buffer, sizeof (buffer), format, number) > 0;
#endif

	g_free (format);

	if (success)
	{
		return g_strdup (buffer);
	}
	else
	{
		return NULL;
	}
}

