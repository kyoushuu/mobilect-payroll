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
portability_format_money (gdouble number, gboolean decimal)
{
	gboolean success;
	gchar buffer[64];

#ifdef G_OS_WIN32
	gchar *value;
	gint size, i;
	TCHAR *DecimalSep, *ThousandSep, *Grouping;
	CURRENCYFMTA format;

	value = g_strdup_printf (decimal? "%lf" : "%.0lf", number);

	if (decimal)
	{
		GetLocaleInfoA (LOCALE_USER_DEFAULT, LOCALE_ICURRDIGITS | LOCALE_RETURN_NUMBER,
		                (LPTSTR) &format.NumDigits,
		                sizeof (format.NumDigits) / sizeof (TCHAR));
	}
	else
		format.NumDigits = 0;

	GetLocaleInfoA (LOCALE_USER_DEFAULT, LOCALE_ILZERO | LOCALE_RETURN_NUMBER,
	                (LPTSTR) &format.LeadingZero,
	                sizeof (format.LeadingZero) / sizeof (TCHAR));

	GetLocaleInfoA (LOCALE_USER_DEFAULT, LOCALE_INEGCURR | LOCALE_RETURN_NUMBER,
	                (LPTSTR) &format.NegativeOrder,
	                sizeof (format.NegativeOrder) / sizeof (TCHAR));

	GetLocaleInfoA (LOCALE_USER_DEFAULT, LOCALE_ICURRENCY | LOCALE_RETURN_NUMBER,
	                (LPTSTR) &format.PositiveOrder,
	                sizeof (format.PositiveOrder) / sizeof (TCHAR));

	size = GetLocaleInfoA (LOCALE_USER_DEFAULT, LOCALE_SMONDECIMALSEP, 0, 0);
	DecimalSep = g_malloc (size * sizeof (TCHAR));
	GetLocaleInfoA (LOCALE_USER_DEFAULT, LOCALE_SMONDECIMALSEP, DecimalSep, size);
	format.lpDecimalSep = DecimalSep;

	size = GetLocaleInfoA (LOCALE_USER_DEFAULT, LOCALE_SMONTHOUSANDSEP, 0, 0);
	ThousandSep = g_malloc (size * sizeof (TCHAR));
	GetLocaleInfoA (LOCALE_USER_DEFAULT, LOCALE_SMONTHOUSANDSEP, ThousandSep, size);
	format.lpThousandSep = ThousandSep;

	size = GetLocaleInfoA (LOCALE_USER_DEFAULT, LOCALE_SMONGROUPING, 0, 0);
	Grouping = g_malloc (size * sizeof (TCHAR));
	GetLocaleInfoA (LOCALE_USER_DEFAULT, LOCALE_SMONGROUPING, Grouping, size);

	format.Grouping = 0;
	for (i = 0; ; i++) {
		if (Grouping[i] == '0') {
			break;
		} else if ('0' < Grouping[i] && Grouping[i] <= '9') {
			format.Grouping *= 10;
			format.Grouping += Grouping[i] - '0';

			if (Grouping[++i] == '\0') {
				format.Grouping *= 10;
			} else if (Grouping[i] != ';') {
				success = FALSE;
				break;
			}
		} else {
			success = FALSE;
			break;
		}
	}
	g_free (Grouping);

	format.lpCurrencySymbol = "";

	success = GetCurrencyFormatA (LOCALE_USER_DEFAULT, 0, value, &format,
	                              buffer, sizeof (buffer)) > 0;

	g_free (DecimalSep);
	g_free (ThousandSep);

	g_free (value);
#else
	success = strfmon (buffer, sizeof (buffer),
	                   decimal? "%!n" : "%!.0n", number) > 0;
#endif

	if (success)
	{
		return g_strdup (buffer);
	}
	else
	{
		return NULL;
	}
}

