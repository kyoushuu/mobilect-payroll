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

			public PayGroup pay_groups { get; set; }
			public EmployeeList employees { get; set; }
			public ListStore deductions { get; set; }

			public Date start { get; private set; }
			public Date end { get; private set; }

			public FontDescription title_font = FontDescription.from_string ("Sans Bold 14");
			public FontDescription company_name_font = FontDescription.from_string ("Sans Bold 12");
			public FontDescription header_font = FontDescription.from_string ("Sans Bold 9");
			public FontDescription text_font = FontDescription.from_string ("Sans 9");
			public FontDescription number_font = FontDescription.from_string ("Monospace 9");
			public FontDescription emp_number_font = FontDescription.from_string ("Monospace Bold 9");

			private int lines_per_page = 0;
			private int lines_first_page = 0;
			private int num_lines = 0;
			private double height = 0;
			private double width = 0;

			private double title_font_height;
			private double company_name_font_height;
			private double header_font_height;
			private double text_font_height;
			private double number_font_height;
			private double number_emp_font_height;

			private double table_top;
			private double header_height;
			private double footer_height;

			private double padding = 1.0;
			private int days = 0;
			private Filter filter;


			public Report (Date start, Date end) {
				this.start = start;
				this.end = end;

				if (start.compare (end) > 0) {
					this.end = start;
				}

				for (var d = start; d.compare (end) <= 0; d.add_days (1)) {
					if (d.get_weekday () != DateWeekday.SUNDAY) {
						days++;
					}
				}

				filter = new Filter ();
				filter.date_start = start;
				filter.date_end = end;
				filter.time_start.set (8, 0);
				filter.time_end.set (17, 0);

				begin_print.connect (begin_print_handler);
				draw_page.connect (draw_page_handler);
			}

			public void print_dialog (Window window) throws Error {
				var ps = new PageSetup ();
				ps.set_orientation (PageOrientation.LANDSCAPE);
				ps.set_paper_size (new PaperSize (PAPER_NAME_LEGAL));
				set_default_page_setup (ps);

				run (PrintOperationAction.PRINT_DIALOG, window);
			}

			public void preview_dialog (Window window) throws Error {
				var ps = new PageSetup ();
				ps.set_orientation (PageOrientation.LANDSCAPE);
				ps.set_paper_size (new PaperSize (PAPER_NAME_LEGAL));
				set_default_page_setup (ps);

				run (PrintOperationAction.PREVIEW, window);
			}


			public void begin_print_handler (Gtk.PrintContext context) {
				/* Get font height */
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

				/* Get height of header and footer */
				table_top = (title_font_height * 2) + company_name_font_height + (padding * 6);
				header_height = table_top + ((header_font_height + (padding * 2)) * 2);
				footer_height = (text_font_height + (padding * 2)) * 10;


				height = context.get_height ();

				lines_first_page = (int) Math.floor ((height - header_height) / (text_font_height + (padding * 2)));
				lines_first_page -= lines_first_page % 2;

				lines_per_page = (int) Math.floor (height / (text_font_height + (padding * 2)));
				lines_per_page -= lines_per_page % 2;

				num_lines = employees.size * 2;
				if (num_lines < lines_first_page) {
					lines_first_page = num_lines;
				}

				/* Note: +10 for footer */
				set_n_pages ((int) Math.ceil ((double) (num_lines + (lines_per_page - lines_first_page) + 10) / lines_per_page));
			}

			public void draw_page_handler (Gtk.PrintContext context, int page_nr) {
				var cr = context.get_cairo_context ();
				width = context.get_width ();

				var layout = context.create_pango_layout ();
				double column_width = width / 15;

				int id = (((page_nr-1) * lines_per_page) + lines_first_page)/2;
				int page_num_lines = lines_per_page;
				if (page_nr == 0) {
					id = 0;
					page_num_lines = lines_first_page;
				}

				double table_x, table_y;


				if (page_nr == 0) {
					/* Print out headers */

					/* Title */
					layout.set_font_description (title_font);
					layout.set_width (units_from_double (width));

					cr.move_to (0, padding);
					layout.set_alignment (Pango.Alignment.CENTER);
					layout.set_markup (@"<u>$title</u>", -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (0, (title_font_height + (padding * 2))*2);
					layout.set_alignment (Pango.Alignment.LEFT);
					layout.set_markup ("<span foreground=\"blue\">M<span foreground=\"red\">O</span>BILECT POWER CORPORATION</span>", -1);
					cairo_show_layout (cr, layout);


					/* Table Headers */
					layout.set_font_description (header_font);
					layout.set_width (units_from_double (column_width * 2));
					layout.set_height (units_from_double (header_font_height * 2));
					layout.set_alignment (Pango.Alignment.CENTER);

					cr.move_to (0, table_top + (padding * 2));
					layout.set_markup ("NAME OF EMPLOYEE", -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width, 0);
					layout.set_width (units_from_double (column_width));

					cr.rel_move_to (column_width, 0);
					layout.set_markup ("RATE", -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width, 0);
					layout.set_markup ("DAYS\nw/o PAY", -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width, 0);
					layout.set_markup ("SALARY\nTO DATE", -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width * 6, 0);
					layout.set_markup ("MOESALA\nLOAN", -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width, 0);
					layout.set_markup ("MOESALA\nSAVINGS", -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width, 0);
					layout.set_markup ("TOTAL\nDEDUC", -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width, 0);
					layout.set_markup ("NET\nAMOUNT", -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width, 0);
					layout.set_markup ("SIGNATURE", -1);
					cairo_show_layout (cr, layout);

					layout.set_width (units_from_double (column_width * 5));
					layout.set_height (units_from_double (header_font_height));

					cr.move_to (column_width * 5, table_top + padding);
					layout.set_markup ("Salary Deduction", -1);
					cairo_show_layout (cr, layout);

					layout.set_width (units_from_double (column_width));

					cr.rel_move_to (0, (header_font_height + (padding * 2)));
					layout.set_markup ("TAX", -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width, 0);
					layout.set_markup ("LOAN", -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width, 0);
					layout.set_markup ("PAG-IBIG", -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width, 0);
					layout.set_markup ("SSS LOAN", -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width, 0);
					layout.set_markup ("VALE", -1);
					cairo_show_layout (cr, layout);


					/* Draw table lines */
					cr.rectangle (0, table_top, width, (page_num_lines * (text_font_height + (padding * 2))) + ((header_font_height + (padding * 2)) * 2));
					/* Horizontal */
					for (int i = 0; i < page_num_lines; i++) {
						cr.move_to (0, header_height + ((text_font_height + (padding * 2)) * i));
						cr.rel_line_to (width, 0);
					}
					/* Vertical */
					for (int i = 0; i < 13; i++) {
						cr.move_to (column_width * (2+i), table_top + ((i >= 4 && i <= 7)? (header_font_height + (padding * 2)) : 0));
						cr.rel_line_to (0, (page_num_lines * (text_font_height + (padding * 2))) + (((i >= 4 && i <= 7)? 1 : 2) * (header_font_height + (padding * 2))));
					}
					cr.move_to (column_width * 5, table_top + (header_font_height + (padding * 2)));
					cr.rel_line_to (column_width * 5, 0);

					cr.set_line_width (1);
					cr.stroke ();

					table_x = 0;
					table_y = header_height;
				} else {
					table_x = 0;
					table_y = 0;
				}


				for (int i = 0; i * 2 < page_num_lines && (i+id) * 2 < num_lines; i++) {
					var employee = (employees as ArrayList<Employee>).get (i + id);
					double days_wo_pay = days - (employee.get_hours (filter)/8);
					/* Half-month salary - (salary per day times days without pay) */
					double salary = (employee.rate/2) - (employee.rate * days_wo_pay/26);

					/* Iter */
					var value = Value (typeof (double));
					var iter = TreeIter ();
					if (deductions != null) {
						var p = new TreePath.from_indices (i + id);
						deductions.get_iter (out iter, p);
					}

					layout.set_height (units_from_double (text_font_height));

					layout.set_width (units_from_double (column_width * 2));

					layout.set_font_description (text_font);
					layout.set_alignment (Pango.Alignment.LEFT);

					/* Name */
					cr.move_to (table_x + padding, table_y + padding + ((text_font_height + (padding * 2)) * 2 * i));
					layout.set_markup (employee.get_name ().up (), -1);
					cairo_show_layout (cr, layout);

					layout.set_width (units_from_double (column_width));

					layout.set_font_description (number_font);
					layout.set_alignment (Pango.Alignment.RIGHT);

					/* Rates */
					cr.rel_move_to (column_width * 2 - padding, 0);
					layout.set_markup ("%.2lf".printf (employee.rate), -1);
					cairo_show_layout (cr, layout);

					/* Days w/o Pay */
					cr.rel_move_to (column_width, 0);
					layout.set_markup ("%.1lf".printf (days_wo_pay), -1);
					cairo_show_layout (cr, layout);

					/* Salary to Date */
					cr.rel_move_to (column_width, 0);
					layout.set_markup ("%.2lf".printf (salary), -1);
					cairo_show_layout (cr, layout);

					/* Tax */
					if (deductions != null) deductions.get (iter, CPanelReport.Columns.TAX, out value);
					cr.rel_move_to (column_width, 0);
					layout.set_markup ("%.2lf".printf (value.get_double ()), -1);
					cairo_show_layout (cr, layout);

					/* Loan */
					if (deductions != null) deductions.get (iter, CPanelReport.Columns.LOAN, out value);
					cr.rel_move_to (column_width, 0);
					layout.set_markup ("%.2lf".printf (value.get_double ()), -1);
					cairo_show_layout (cr, layout);

					/* PAG-IBIG */
					if (deductions != null) deductions.get (iter, CPanelReport.Columns.PAG_IBIG, out value);
					cr.rel_move_to (column_width, 0);
					layout.set_markup ("%.2lf".printf (value.get_double ()), -1);
					cairo_show_layout (cr, layout);

					/* SSS Loan */
					if (deductions != null) deductions.get (iter, CPanelReport.Columns.SSS_LOAN, out value);
					cr.rel_move_to (column_width, 0);
					layout.set_markup ("%.2lf".printf (value.get_double ()), -1);
					cairo_show_layout (cr, layout);

					/* Vale */
					if (deductions != null) deductions.get (iter, CPanelReport.Columns.VALE, out value);
					cr.rel_move_to (column_width, 0);
					layout.set_markup ("%.2lf".printf (value.get_double ()), -1);
					cairo_show_layout (cr, layout);

					/* Moesala Loan */
					if (deductions != null) deductions.get (iter, CPanelReport.Columns.MOESALA_LOAN, out value);
					cr.rel_move_to (column_width, 0);
					layout.set_markup ("%.2lf".printf (value.get_double ()), -1);
					cairo_show_layout (cr, layout);

					/* Moesala Savings */
					if (deductions != null) deductions.get (iter, CPanelReport.Columns.MOESALA_SAVINGS, out value);
					cr.rel_move_to (column_width, 0);
					layout.set_markup ("%.2lf".printf (value.get_double ()), -1);
					cairo_show_layout (cr, layout);

					layout.set_width (units_from_double (column_width * 2));

					layout.set_font_description (number_font);
					layout.set_alignment (Pango.Alignment.CENTER);

					/* TIN No. */
					cr.move_to (table_x + padding, table_y + padding + ((text_font_height + (padding * 2)) * ((2 * i) + 1)));
					layout.set_markup ("XXX-XXX-XXX", -1);
					cairo_show_layout (cr, layout);
					cr.rel_move_to (0, (text_font_height + (padding * 2)));
				}

				/* start in line #1 (#0 is header of table) */
				/*for (int i = 0; i < page_num_lines && line < num_lines; i++, line++)
				{
					var employee = (employees as ArrayList<Employee>).get (line);
					double hours = employee.get_hours (this.cpanel.filter);

					layout.set_font_description (sans_font);
					layout.set_alignment (Pango.Alignment.LEFT);
					layout.set_width (units_from_double (width / 2));

					cr.move_to (0, font_height * (i+1));
					layout.set_markup (employee.get_name (), -1);
					cairo_show_layout (cr, layout);

					layout.set_font_description (mono_font);
					layout.set_alignment (Pango.Alignment.RIGHT);
					layout.set_width (units_from_double (width / 4));

					cr.move_to (width * 2 / 4, font_height * (i+1));
					layout.set_markup ("%5.1lf".printf(hours), -1);
					cairo_show_layout (cr, layout);

					cr.move_to (width * 3 / 4, font_height * (i+1));
					layout.set_markup ("%10.2lf".printf(hours * this.cpanel.hour_rate), -1);
					cairo_show_layout (cr, layout);
				}*/
			}

		}

	}

}
