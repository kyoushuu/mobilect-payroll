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


using Gtk;
using Pango;
using Cairo;
using Gee;


namespace Mobilect {

	namespace Payroll {

		public class Report : PrintOperation {

			public string title { get; set; }

			public PayGroup[] pay_groups { get; set; }
			public EmployeeList employees { get; set; }

			public Date start { get; private set; }
			public Date end { get; private set; }

			public FontDescription title_font = FontDescription.from_string ("Sans Bold 14");
			public FontDescription company_name_font = FontDescription.from_string ("Sans Bold 12");
			public FontDescription header_font = FontDescription.from_string ("Sans Bold 9");
			public FontDescription text_font = FontDescription.from_string ("Sans 9");
			public FontDescription number_font = FontDescription.from_string ("Monospace 9");
			public FontDescription emp_number_font = FontDescription.from_string ("Monospace Bold 9");

			internal double title_font_height;
			internal double company_name_font_height;
			internal double header_font_height;
			internal double text_font_height;
			internal double number_font_height;
			internal double number_emp_font_height;

			internal double padding = 1.0;


			public Report (Date start, Date end) {
				this.start = start;
				this.end = end;

				if (start.compare (end) > 0) {
					this.end = start;
				}
			}

			public void print_dialog (Window window) throws Error {
				run (PrintOperationAction.PRINT_DIALOG, window);
			}

			public void preview_dialog (Window window) throws Error {
				run (PrintOperationAction.PREVIEW, window);
			}

			public void export (Window window) throws Error {
				run (PrintOperationAction.EXPORT, window);
			}

			public string format_date (Date date, string format) {
				char s[64];
				date.strftime (s, format);
				return (string) s;
			}


			internal string period_to_string (Date start, Date end) {
				if (start.get_year () == end.get_year ()) {
					if (start.get_month () == end.get_month ()) {
						if (start.get_day () == end.get_day ()) {
							return format_date (start, "%B %d, %Y");
						} else {
							return format_date (start, "%B %d") + "-" + format_date (end, "%d, %Y");
						}
					} else {
						return format_date (start, "%B %d") + " to " + format_date (end, "%B %d, %Y");
					}
				} else {
					return format_date (start, "%B %d, %Y") + " to " + format_date (end, "%B %d, %Y");
				}
			}

			internal void update_font_height (Gtk.PrintContext context) {				/* Get font height */
				FontMetrics font_metrics;
				var pcontext = context.create_pango_context ();

				font_metrics = pcontext.load_font (title_font).get_metrics (pcontext.get_language ());
				title_font_height = units_to_double (font_metrics.get_ascent () + font_metrics.get_descent ());

				font_metrics = pcontext.load_font (company_name_font).get_metrics (pcontext.get_language ());
				company_name_font_height = units_to_double (font_metrics.get_ascent () + font_metrics.get_descent ());

				font_metrics = pcontext.load_font (header_font).get_metrics (pcontext.get_language ());
				header_font_height = units_to_double (font_metrics.get_ascent () + font_metrics.get_descent ());

				font_metrics = pcontext.load_font (text_font).get_metrics (pcontext.get_language ());
				text_font_height = units_to_double (font_metrics.get_ascent () + font_metrics.get_descent ());

				font_metrics = pcontext.load_font (number_font).get_metrics (pcontext.get_language ());
				number_font_height = units_to_double (font_metrics.get_ascent () + font_metrics.get_descent ());

				font_metrics = pcontext.load_font (emp_number_font).get_metrics (pcontext.get_language ());
				number_emp_font_height = units_to_double (font_metrics.get_ascent () + font_metrics.get_descent ());
			}

		}

	}

}
