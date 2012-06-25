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

		public class OvertimeReport : Report {

			private int lines_per_page = 0;
			private int lines_first_page = 0;
			private int num_lines = 0;
			private double height = 0;
			private double width = 0;

			private double table_top;
			private double header_height;
			private double footer_height;
			private double table_width;

			/* In points */
			private double hour_column_width = 15;
			private double number_column_width = 60;
			private double name_column_width = 120;
			private double signature_column_width = 60;

			private int days = 0;


			public OvertimeReport (Date start, Date end) {
				base (start, end);

				for (var d = start; d.compare (end) <= 0; d.add_days (1)) {
					if (d.get_weekday () != DateWeekday.SUNDAY) {
						days++;
					}
				}

				var period_8am_5pm_regular = new PayPeriod (_("8am-5pm"),
				                                            false,
				                                            1.0,
				                                            new TimePeriod[] {
																new TimePeriod (new Time (8,0), new Time (17,0))
															});
				var period_8am_5pm_sunday = new PayPeriod (_("8am-5pm"),
				                                           false,
				                                           1.3,
				                                           new TimePeriod[] {
															   new TimePeriod (new Time (8,0), new Time (17,0))
														   });
				var period_5pm_10pm = new PayPeriod (_("5pm-10pm"),
				                                     false,
				                                     1.25,
				                                     new TimePeriod[] {
														 new TimePeriod (new Time (17,0), new Time (22,0))
													 });
				var period_10pm_6am = new PayPeriod (_("10pm-6am"),
				                                     false,
				                                     1.5,
				                                     new TimePeriod[] {
														 new TimePeriod (new Time (22,0), new Time (6,0))
													 });

				var pay_periods_regular = new PayPeriod[] {
					period_8am_5pm_regular,
					period_5pm_10pm,
					period_10pm_6am
				};
				var pay_periods_sunday = new PayPeriod[] {
					period_8am_5pm_sunday,
					period_5pm_10pm,
					period_10pm_6am
				};

				pay_groups = new PayGroup[] {
					new PayGroup (_("Regular Holiday"),
					              false,
					              MonthInfo.HolidayType.REGULAR_HOLIDAY,
					              2.0,
					              pay_periods_regular,
					              new double[] {
									  1.0, 0, 0
								  }),
					new PayGroup (_("Sunday, Regular Holiday"),
					              true,
					              MonthInfo.HolidayType.REGULAR_HOLIDAY,
					              2.0,
					              pay_periods_sunday,
					              null),
					new PayGroup (_("Special Holiday"),
					              false,
					              MonthInfo.HolidayType.SPECIAL_HOLIDAY,
					              1.3,
					              pay_periods_regular,
					              new double[] {
									  1.0, 0, 0
								  }),
					new PayGroup (_("Sunday, Special Holiday"),
					              true,
					              MonthInfo.HolidayType.SPECIAL_HOLIDAY,
					              1.3,
					              pay_periods_sunday,
					              null)
				};

				export_filename = "payroll-overtime-" +
					format_date (start, "%Y%m%d") + "-" +
					format_date (end, "%Y%m%d");

				begin_print.connect (begin_print_handler);
				draw_page.connect (draw_page_handler);
			}


			public void begin_print_handler (Gtk.PrintContext context) {
				update_font_height (context);

				/* Get height of header and footer */
				table_top = (title_font_height * 2) + company_name_font_height + (padding * 6);
				header_height = table_top + ((header_font_height + (padding * 2)) * 2);
				footer_height = (text_font_height + (padding * 2)) * 10;


				height = context.get_height ();
				width = context.get_width ();


				/* Name, Rate and Hourly Rate */
				table_width = name_column_width +
					number_column_width +
					number_column_width;
				foreach (var pay_group in pay_groups) {
					foreach (var pay_period in pay_group.periods) {
						/* Hour and Subtotal each period */
						table_width += hour_column_width + number_column_width;
					}
					/* Subtotal each group */
					table_width += number_column_width;
				}
				/* Total and Signature */
				table_width += number_column_width;


				lines_first_page = (int) Math.floor ((height - header_height) / (text_font_height + (padding * 2)));
				lines_first_page -= lines_first_page % 2;

				lines_per_page = (int) Math.floor (height / (text_font_height + (padding * 2)));
				lines_per_page -= lines_per_page % 2;

				num_lines = employees.size * 2;
				if (num_lines < lines_first_page) {
					lines_first_page = num_lines;
				}


				/* Note: +10 for footer */
				int pages_v = (int) Math.ceil ((double) (num_lines + (lines_per_page - lines_first_page) + 10) / lines_per_page);
				int pages_h = (int) Math.ceil (table_width / width);
				set_n_pages (pages_v * pages_h);
			}

			public void draw_page_handler (Gtk.PrintContext context, int page_nr) {
				var cr = context.get_cairo_context ();

				var layout = context.create_pango_layout ();
				layout.set_wrap (Pango.WrapMode.WORD_CHAR);
				layout.set_ellipsize (EllipsizeMode.END);

				double column_width = width / 15;

				int id = (((page_nr-1) * lines_per_page) + lines_first_page)/2;
				int page_num_lines = lines_per_page;
				if (page_nr == 0) {
					id = 0;
					page_num_lines = lines_first_page;
				} else if ((id + (page_num_lines/2)) > num_lines) {
					page_num_lines = num_lines - (id*2);
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
					layout.set_markup ("NAME OF EMPLOYEE", -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (column_width, 0);
					layout.set_width (units_from_double (column_width - (padding * 2)));

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

					layout.set_width (units_from_double ((column_width * 5) - (padding * 2)));
					layout.set_height (units_from_double (header_font_height));

					cr.move_to ((column_width * 5) + padding, table_top + padding);
					layout.set_markup ("Salary Deduction", -1);
					cairo_show_layout (cr, layout);

					layout.set_width (units_from_double (column_width - (padding * 2)));

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


					table_x = 0;
					table_y = header_height;


					/* Draw table lines */
					cr.rectangle (0, table_top, width, (page_num_lines * (text_font_height + (padding * 2))) + ((header_font_height + (padding * 2)) * 2));
					/* Vertical */
					for (int i = 0; i < 13; i++) {
						cr.move_to (column_width * (2+i), table_top + ((i >= 4 && i <= 7)? (header_font_height + (padding * 2)) : 0));
						cr.rel_line_to (0, ((i >= 4 && i <= 7)? 1 : 2) * (header_font_height + (padding * 2)));
					}
					/* Horizontal */
					cr.move_to (column_width * 5, table_top + (header_font_height + (padding * 2)));
					cr.rel_line_to (column_width * 5, 0);
					cr.move_to (0, table_top + (2 * (header_font_height + (padding * 2))));
					cr.rel_line_to (width, 0);

					cr.set_line_width (2);
					cr.stroke ();
				} else {
					table_x = 0;
					table_y = 0;

					/* Draw table lines */
					cr.rectangle (0, 0, width, (page_num_lines * (text_font_height + (padding * 2))));

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
					cr.rel_line_to (0, (page_num_lines * (text_font_height + (padding * 2))));
				}
				cr.set_line_width (1);
				cr.stroke ();


				for (int i = 0; i * 2 < page_num_lines && (i+id) * 2 < num_lines; i++) {
					var employee = (employees as ArrayList<Employee>).get (i + id);

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
