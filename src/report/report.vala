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

			internal int payslip_per_page;


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

			public double get_payslip_height () {
				return
					company_name_font_height +  /* Company Name */
					header_font_height +		/* "PAYSLIP" */
					(5 * text_font_height) +	/* Form */
					header_font_height +		/* Earnings */
					(3 * text_font_height) +	/* Earnings Table */
					(3 * 2 * padding) +
					text_font_height +			/* Horizontal Line */
					header_font_height +		/* Deductions */
					(6 * text_font_height) +	/* Deductions Table */
					(6 * 2 * padding) +
					(3 * text_font_height);		/* Received Payment */
			}

			public void draw_payslip (PrintContext context, double top_y, Employee employee) {
				double x = 0, y = top_y;
				double padding_payslip = 5;
				int layout_width;
				double total_y;

				var cr = context.get_cairo_context ();
				var width = context.get_width ();

				var layout = context.create_pango_layout ();
				layout.set_wrap (Pango.WrapMode.WORD_CHAR);
				layout.set_ellipsize (EllipsizeMode.END);

				cr.rectangle (x, y, width, get_payslip_height ());
				cr.set_line_width (1.5);
				cr.stroke ();

				width -= padding_payslip * 2;
				x += padding_payslip;

				layout.set_width (units_from_double (width));

				cr.move_to (x, y);
				layout.set_font_description (company_name_font);
				layout.set_alignment (Pango.Alignment.CENTER);
				layout.set_markup (_("MOBILECT POWER CORPORATION"), -1);
				cairo_show_layout (cr, layout);
				y += company_name_font_height;

				layout.set_alignment (Pango.Alignment.LEFT);

				cr.move_to (x, y);
				layout.set_width (-1);
				layout.set_font_description (header_font);
				layout.set_markup (_("PAYSLIP"), -1);
				cairo_show_layout (cr, layout);
				y += header_font_height;

				layout.set_font_description (text_font);
				y += text_font_height;

				cr.move_to (x, y);
				layout.set_width (-1);
				layout.set_alignment (Pango.Alignment.LEFT);
				layout.set_markup (_("NAME:"), -1);
				cairo_show_layout (cr, layout);

				layout.get_size (out layout_width, null);
				cr.move_to (x + units_to_double (layout_width) + padding, y);
				layout.set_width (units_from_double (width) - layout_width);
				layout.set_alignment (Pango.Alignment.CENTER);
				layout.set_markup (employee.get_name (), -1);
				cairo_show_layout (cr, layout);
				y += text_font_height * 1.5;

				cr.move_to (x, y);
				cr.rel_line_to (width, 0);
				cr.set_line_width (1);
				cr.stroke ();
				y += text_font_height * 0.5;

				cr.move_to (x, y);
				layout.set_width (-1);
				layout.set_alignment (Pango.Alignment.LEFT);
				layout.set_markup (_("TIN NO."), -1);
				cairo_show_layout (cr, layout);

				layout.get_size (out layout_width, null);
				cr.move_to (x + units_to_double (layout_width), y);
				layout.set_width (units_from_double (width/3) - layout_width);
				layout.set_alignment (Pango.Alignment.CENTER);
				layout.set_markup (employee.tin, -1);
				cairo_show_layout (cr, layout);

				cr.move_to (x + (width/3), y);
				layout.set_width (-1);
				layout.set_alignment (Pango.Alignment.LEFT);
				layout.set_markup (_("PERIOD"), -1);
				cairo_show_layout (cr, layout);

				layout.get_size (out layout_width, null);
				cr.move_to (x + (width/3) + units_to_double (layout_width), y);
				layout.set_width (units_from_double (width/3) - layout_width);
				layout.set_alignment (Pango.Alignment.CENTER);
				layout.set_markup (format_date (start, "%d %B, %Y"), -1);
				cairo_show_layout (cr, layout);

				cr.move_to (x + (width*2/3), y);
				layout.set_width (-1);
				layout.set_alignment (Pango.Alignment.LEFT);
				layout.set_markup (_("TO"), -1);
				cairo_show_layout (cr, layout);

				layout.get_size (out layout_width, null);
				cr.move_to (x + (width*2/3) + units_to_double (layout_width), y);
				layout.set_width (units_from_double (width/3) - layout_width);
				layout.set_alignment (Pango.Alignment.CENTER);
				layout.set_markup (format_date (end, "%d %B, %Y"), -1);
				cairo_show_layout (cr, layout);
				y += text_font_height * 0.5;

				cr.move_to (x + (width/3) - (text_font_height * 0.5), y);
				cr.rel_line_to (0, text_font_height);
				y += text_font_height;

				cr.move_to (x, y);
				cr.rel_line_to (width, 0);
				cr.set_line_width (1);
				cr.stroke ();
				y += text_font_height * 0.5;

				cr.move_to (x, y);
				layout.set_font_description (header_font);
				layout.set_alignment (Pango.Alignment.CENTER);
				layout.set_width (units_from_double (width*3/4));
				layout.set_markup (_("EARNINGS"), -1);
				cairo_show_layout (cr, layout);
				y += header_font_height;

				cr.rectangle (x, y, width*3/4, (text_font_height * 3) + (padding * 2 * 3));
				cr.set_line_width (1.5);
				cr.stroke ();

				cr.move_to (x + (width/2), y);
				cr.rel_line_to (0, (text_font_height * 3) + (padding * 2 * 3));
				cr.move_to (x + (width*2/3), y);
				cr.rel_line_to (0, (text_font_height * 3) + (padding * 2 * 3));
				cr.set_line_width (1);
				cr.stroke ();

				layout.set_font_description (text_font);
				layout.set_width (units_from_double ((width / 2) - (padding * 2)));
				layout.set_alignment (Pango.Alignment.LEFT);

				cr.move_to (x + padding, y + padding);
				layout.set_markup (_("GROSS EARNINGS: rate/day/month P %.2lf (# of days    )").printf ((double) employee.rate/26), -1);
				cairo_show_layout (cr, layout);
				y += text_font_height + (padding * 2);

				cr.move_to (x, y);
				cr.rel_line_to (width*3/4, 0);
				cr.set_line_width (1);
				cr.stroke ();

				cr.move_to (x + padding, y + padding);
				layout.set_markup (_("OVERTIME: rate/hr P %.2lf (# of hrs    )").printf ((double) employee.rate/26/8), -1);
				cairo_show_layout (cr, layout);
				y += text_font_height + (padding * 2);

				cr.move_to (x, y);
				cr.rel_line_to (width*3/4, 0);
				cr.set_line_width (1);
				cr.stroke ();

				cr.move_to (x + padding, y + padding);
				layout.set_markup (_("OTHER COMPENSATION"), -1);
				cairo_show_layout (cr, layout);

				y += text_font_height;
				y += text_font_height;
				y += (padding * 2);

				cr.move_to (x, y);
				cr.rel_line_to (width, 0);
				cr.set_line_width (1);
				cr.stroke ();

				cr.move_to (x, y);
				layout.set_font_description (header_font);
				layout.set_alignment (Pango.Alignment.CENTER);
				layout.set_width (units_from_double (width/2));
				layout.set_markup (_("DEDUCTIONS"), -1);
				cairo_show_layout (cr, layout);
				y += header_font_height;

				total_y = y;

				cr.rectangle (x, y, width/2, (text_font_height * 6) + (padding * 2 * 6));
				cr.set_line_width (1.5);
				cr.stroke ();

				cr.move_to (x + (width/4), y);
				cr.rel_line_to (0, (text_font_height * 6) + (padding * 2 * 6));
				cr.move_to (x + (width*5/12), y);
				cr.rel_line_to (0, (text_font_height * 6) + (padding * 2 * 6));
				cr.set_line_width (1);
				cr.stroke ();

				layout.set_font_description (text_font);
				layout.set_width (units_from_double ((width / 4) - (padding * 2)));
				layout.set_alignment (Pango.Alignment.LEFT);

				cr.move_to (x + padding, y + padding);
				layout.set_markup (_("WITHHOLDING TAX"), -1);
				cairo_show_layout (cr, layout);
				y += text_font_height + (padding * 2);

				cr.move_to (x, y);
				cr.rel_line_to (width/2, 0);
				cr.set_line_width (1);
				cr.stroke ();

				cr.move_to (x + padding, y + padding);
				layout.set_markup (_("SSS PREMIUMS"), -1);
				cairo_show_layout (cr, layout);
				y += text_font_height + (padding * 2);

				cr.move_to (x, y);
				cr.rel_line_to (width/2, 0);
				cr.set_line_width (1);
				cr.stroke ();

				cr.move_to (x + padding, y + padding);
				layout.set_markup (_("PHILHEALTH"), -1);
				cairo_show_layout (cr, layout);
				y += text_font_height + (padding * 2);

				cr.move_to (x, y);
				cr.rel_line_to (width/2, 0);
				cr.set_line_width (1);
				cr.stroke ();

				cr.move_to (x + padding, y + padding);
				layout.set_markup (_("LOANS / VALE"), -1);
				cairo_show_layout (cr, layout);
				y += text_font_height + (padding * 2);

				cr.move_to (x, y);
				cr.rel_line_to (width/2, 0);
				cr.set_line_width (1);
				cr.stroke ();

				cr.move_to (x + padding, y + padding);
				layout.set_markup (_("OTHERS"), -1);
				cairo_show_layout (cr, layout);
				y += text_font_height + (padding * 2);

				cr.move_to (x, y);
				cr.rel_line_to (width/2, 0);
				cr.set_line_width (1);
				cr.stroke ();

				cr.move_to (x + padding, y + padding);
				layout.set_markup (_(""), -1);
				cairo_show_layout (cr, layout);
				y += text_font_height + (padding * 2);

				cr.move_to (x + (width*4/6), total_y);
				layout.set_alignment (Pango.Alignment.LEFT);
				layout.set_markup (_("TOTAL\nEARNINGS"), -1);
				cairo_show_layout (cr, layout);
				total_y += text_font_height;

				cr.move_to (x + (width*5/6), total_y);
				layout.set_alignment (Pango.Alignment.RIGHT);
				layout.set_width (units_from_double (width/6));
				layout.set_markup (_("%.2lf").printf (4160.00), -1);
				cairo_show_layout (cr, layout);

				layout.set_alignment (Pango.Alignment.LEFT);
				layout.set_markup (_("P"), -1);
				cairo_show_layout (cr, layout);
				total_y += text_font_height;

				cr.move_to (x + (width*5/6), total_y);
				cr.rel_line_to (width/6, 0);
				cr.set_line_width (1);
				cr.stroke ();
				total_y += text_font_height;

				cr.move_to (x + (width*4/6), total_y);
				layout.set_alignment (Pango.Alignment.LEFT);
				layout.set_markup (_("TOTAL\nDEDUCTIONS"), -1);
				cairo_show_layout (cr, layout);
				total_y += text_font_height;

				cr.move_to (x + (width*5/6), total_y);
				layout.set_alignment (Pango.Alignment.RIGHT);
				layout.set_width (units_from_double (width/6));
				layout.set_markup (_("%.2lf").printf (4160.00), -1);
				cairo_show_layout (cr, layout);

				layout.set_alignment (Pango.Alignment.LEFT);
				layout.set_markup (_("P"), -1);
				cairo_show_layout (cr, layout);
				total_y += text_font_height;

				cr.move_to (x + (width*5/6), total_y);
				cr.rel_line_to (width/6, 0);
				cr.set_line_width (1);
				cr.stroke ();
				total_y += text_font_height;

				cr.move_to (x + (width*4/6), total_y);
				layout.set_alignment (Pango.Alignment.LEFT);
				layout.set_markup (_("NET EARNINGS"), -1);
				cairo_show_layout (cr, layout);

				cr.move_to (x + (width*5/6), total_y);
				layout.set_alignment (Pango.Alignment.RIGHT);
				layout.set_width (units_from_double (width/6));
				layout.set_markup (_("%.2lf").printf (4160.00), -1);
				cairo_show_layout (cr, layout);

				layout.set_alignment (Pango.Alignment.LEFT);
				layout.set_markup (_("P"), -1);
				cairo_show_layout (cr, layout);
				total_y += text_font_height;

				cr.move_to (x + (width*5/6), total_y);
				cr.rel_line_to (width/6, 0);
				cr.set_line_width (1);
				cr.stroke ();

				cr.move_to (x + (width*5/6), total_y + 2);
				cr.rel_line_to (width/6, 0);
				cr.set_line_width (1);
				cr.stroke ();
				total_y += text_font_height;

				total_y += padding_payslip;

				cr.move_to (x + (width/2) + padding_payslip, total_y);
				layout.set_alignment (Pango.Alignment.LEFT);
				layout.set_markup (_("RECEIVED PAYMENT:"), -1);
				cairo_show_layout (cr, layout);
				total_y += text_font_height;

				layout.get_size (out layout_width, null);
				cr.move_to (x + (width/2) + padding_payslip + units_to_double (layout_width), total_y);
				cr.rel_line_to ((width/2) - padding_payslip - units_to_double (layout_width), 0);
				cr.set_line_width (1);
				cr.stroke ();
			}

		}

	}

}
