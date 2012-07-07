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

		public class RegularReport : Report {

			public ListStore deductions { get; set; }

			private int lines_per_page = 0;
			private int lines_first_page = 0;
			private int num_lines = 0;
			private double height = 0;
			private double width = 0;

			private double table_top;
			private double header_height;
			private double footer_height;
			private double table_header_height;

			private int days = 0;
			private Filter filter;


			public RegularReport (Date start, Date end) {
				base (start, end);

				for (var d = start; d.compare (end) <= 0; d.add_days (1)) {
					if (d.get_weekday () != DateWeekday.SUNDAY) {
						days++;
					}
				}

				filter = new Filter ();
				filter.date_start = start;
				filter.date_end = end;
				filter.time_periods = new TimePeriod[] {
					new TimePeriod (new Time (8,0), new Time (12,0)),
					new TimePeriod (new Time (13,0), new Time (17,0))
				};

				export_filename = "payroll-regular-" +
					format_date (start, "%Y%m%d") + "-" +
					format_date (end, "%Y%m%d");

				begin_print.connect (begin_print_handler);
				draw_page.connect (draw_page_handler);
			}


			public void begin_print_handler (Gtk.PrintContext context) {
				update_font_height (context);

				/* Get height of header and footer */
				table_top = (title_font_height * 2) + company_name_font_height + (padding * 6);
				table_header_height = ((header_font_height + (padding * 2)) * 2);
				header_height = table_top + table_header_height;
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
				set_n_pages ((int) Math.ceil ((double) (num_lines + (lines_first_page != num_lines? lines_per_page - lines_first_page : 0) + 10) / lines_per_page));
			}

			public void draw_page_handler (Gtk.PrintContext context, int page_nr) {
				var cr = context.get_cairo_context ();

				var layout = context.create_pango_layout ();
				layout.set_wrap (Pango.WrapMode.WORD_CHAR);
				layout.set_ellipsize (EllipsizeMode.END);

				width = context.get_width ();
				double column_width = width / 15;

				int id = (((page_nr-1) * lines_per_page) + lines_first_page)/2;
				int page_num_lines = lines_per_page;
				if (page_nr == 0) {
					id = 0;
					page_num_lines = lines_first_page;
				} else if ((id + (page_num_lines/2)) > (num_lines/2)) {
					page_num_lines = num_lines - (id*2);
				}
				double table_content_height = (page_num_lines * (text_font_height + (padding * 2)));

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

					/* Company Name */
					layout.set_font_description (company_name_font);
					layout.set_width (units_from_double (width/2));

					cr.rel_move_to (0, (title_font_height + (padding * 2))*2);
					layout.set_alignment (Pango.Alignment.LEFT);
					layout.set_markup (_("<span foreground=\"blue\">M<span foreground=\"red\">O</span>BILECT POWER CORPORATION</span>"), -1);
					cairo_show_layout (cr, layout);

					/* Period */
					layout.set_font_description (header_font);
					layout.set_width (units_from_double (width/2));

					cr.move_to (width/2, table_top - (header_font_height + padding));
					layout.set_markup (_("For the period of %s").printf (period_to_string (start, end).up ()), -1);
					cairo_show_layout (cr, layout);


					/* Table Headers */
					layout.set_font_description (header_font);
					layout.set_width (units_from_double ((column_width * 2) - (padding * 2)));
					layout.set_height (units_from_double (header_font_height * 2));
					layout.set_alignment (Pango.Alignment.CENTER);

					cr.move_to (padding, table_top + (padding * 2));
					layout.set_markup (_("NAME OF EMPLOYEE"), -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width, 0);
					layout.set_width (units_from_double (column_width - (padding * 2)));

					cr.rel_move_to (column_width, 0);
					layout.set_markup (_("RATE"), -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width, 0);
					layout.set_markup (_("DAYS\nw/o PAY"), -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width, 0);
					layout.set_markup (_("SALARY\nTO DATE"), -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width * 6, 0);
					layout.set_markup (_("MOESALA\nLOAN"), -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width, 0);
					layout.set_markup (_("MOESALA\nSAVINGS"), -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width, 0);
					layout.set_markup (_("TOTAL\nDEDUC"), -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width, 0);
					layout.set_markup (_("NET\nAMOUNT"), -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width, 0);
					layout.set_markup (_("SIGNATURE"), -1);
					cairo_show_layout (cr, layout);

					layout.set_width (units_from_double ((column_width * 5) - (padding * 2)));
					layout.set_height (units_from_double (header_font_height));

					cr.move_to ((column_width * 5) + padding, table_top + padding);
					layout.set_markup (_("Salary Deduction"), -1);
					cairo_show_layout (cr, layout);

					layout.set_width (units_from_double (column_width - (padding * 2)));

					cr.rel_move_to (0, (header_font_height + (padding * 2)));
					layout.set_markup (_("TAX"), -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width, 0);
					layout.set_markup (_("LOAN"), -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width, 0);
					layout.set_markup (_("PAG-IBIG"), -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width, 0);
					layout.set_markup (_("SSS LOAN"), -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width, 0);
					layout.set_markup (_("VALE"), -1);
					cairo_show_layout (cr, layout);


					table_x = 0;
					table_y = header_height;


					/* Draw table lines */
					cr.rectangle (0, table_top, width, table_content_height + table_header_height);
					/* Vertical */
					for (int i = 0; i < 13; i++) {
						cr.move_to (column_width * (2+i), table_top + ((i >= 4 && i <= 7)? (header_font_height + (padding * 2)) : 0));
						cr.rel_line_to (0, ((i >= 4 && i <= 7)? 1 : 2) * (header_font_height + (padding * 2)));
					}
					/* Horizontal */
					cr.move_to (column_width * 5, table_top + (header_font_height + (padding * 2)));
					cr.rel_line_to (column_width * 5, 0);
					cr.move_to (0, table_top + table_header_height);
					cr.rel_line_to (width, 0);

					cr.set_line_width (2);
					cr.stroke ();
				} else {
					table_x = 0;
					table_y = 0;

					/* Draw table lines */
					cr.rectangle (0, 0, width, table_content_height);

					cr.set_line_width (2);
					cr.stroke ();
				}


				/* Print table lines */
				/* Horizontal */
				for (int i = 0; i < page_num_lines - 1 && (i+id) < num_lines; i++) {
					cr.move_to (0, table_y + ((text_font_height + (padding * 2)) * (i+1)));
					cr.rel_line_to (width, 0);
				}
				/* Vertical */
				for (int i = 0; i < 13; i++) {
					cr.move_to (column_width * (2+i), table_y);
					cr.rel_line_to (0, table_content_height);
				}
				cr.set_line_width (1);
				cr.stroke ();


				for (int i = 0; i * 2 < page_num_lines && (i+id) * 2 < num_lines; i++) {
					var employee = (employees as ArrayList<Employee>).get (i + id);
					double days_wo_pay = days - (employee.get_hours (filter)/8);
					/* Half-month salary - (salary per day times days without pay) */
					double salary = (employee.rate/2) - (employee.rate * days_wo_pay/26);
					if (salary < 0) {
						salary = 0;
					}

					/* Iter */
					double value = 0;
					double deduction = 0;
					var iter = TreeIter ();
					if (deductions != null) {
						var p = new TreePath.from_indices (i + id);
						deductions.get_iter (out iter, p);
					}

					layout.set_height (units_from_double (text_font_height));

					layout.set_width (units_from_double ((column_width * 2) - (padding * 2)));

					layout.set_font_description (text_font);
					layout.set_alignment (Pango.Alignment.LEFT);

					/* Name */
					cr.move_to (table_x + padding, table_y + padding + ((text_font_height + (padding * 2)) * 2 * i));
					layout.set_markup (employee.get_name ().up (), -1);
					cairo_show_layout (cr, layout);

					layout.set_width (units_from_double (column_width - (padding * 2)));

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
					deduction += value;
					cr.rel_move_to (column_width, 0);
					layout.set_markup ("%.2lf".printf (value), -1);
					cairo_show_layout (cr, layout);

					/* Loan */
					if (deductions != null) deductions.get (iter, CPanelReport.Columns.LOAN, out value);
					deduction += value;
					cr.rel_move_to (column_width, 0);
					layout.set_markup ("%.2lf".printf (value), -1);
					cairo_show_layout (cr, layout);

					/* PAG-IBIG */
					if (deductions != null) deductions.get (iter, CPanelReport.Columns.PAG_IBIG, out value);
					deduction += value;
					cr.rel_move_to (column_width, 0);
					layout.set_markup ("%.2lf".printf (value), -1);
					cairo_show_layout (cr, layout);

					/* SSS Loan */
					if (deductions != null) deductions.get (iter, CPanelReport.Columns.SSS_LOAN, out value);
					deduction += value;
					cr.rel_move_to (column_width, 0);
					layout.set_markup ("%.2lf".printf (value), -1);
					cairo_show_layout (cr, layout);

					/* Vale */
					if (deductions != null) deductions.get (iter, CPanelReport.Columns.VALE, out value);
					deduction += value;
					cr.rel_move_to (column_width, 0);
					layout.set_markup ("%.2lf".printf (value), -1);
					cairo_show_layout (cr, layout);

					/* Moesala Loan */
					if (deductions != null) deductions.get (iter, CPanelReport.Columns.MOESALA_LOAN, out value);
					deduction += value;
					cr.rel_move_to (column_width, 0);
					layout.set_markup ("%.2lf".printf (value), -1);
					cairo_show_layout (cr, layout);

					/* Moesala Savings */
					if (deductions != null) deductions.get (iter, CPanelReport.Columns.MOESALA_SAVINGS, out value);
					deduction += value;
					cr.rel_move_to (column_width, 0);
					layout.set_markup ("%.2lf".printf (value), -1);
					cairo_show_layout (cr, layout);

					/* Total Deductions */
					cr.rel_move_to (column_width, 0);
					layout.set_markup ("%.2lf".printf (deduction), -1);
					cairo_show_layout (cr, layout);

					/* Net Amount */
					cr.rel_move_to (column_width, 0);
					layout.set_markup ("%.2lf".printf (salary - deduction), -1);
					cairo_show_layout (cr, layout);

					layout.set_width (units_from_double ((column_width * 2) - (padding * 2)));

					layout.set_font_description (number_font);
					layout.set_alignment (Pango.Alignment.CENTER);

					/* TIN No. */
					cr.move_to (table_x + padding, table_y + padding + ((text_font_height + (padding * 2)) * ((2 * i) + 1)));
					layout.set_markup ("XXX-XXX-XXX", -1);
					cairo_show_layout (cr, layout);
					cr.rel_move_to (0, (text_font_height + (padding * 2)));
				}
			}

		}

	}

}
