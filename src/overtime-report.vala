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
			private double table_header_height;

			/* In points */
			private double hour_column_width = 25;
			private double number_column_width = 60;
			private double name_column_width = 120;
			private double signature_column_width = 70;

			private int days = 0;

			private int pages_v;
			private int pages_h;
			private Surface[] surfaces;


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
					new PayGroup (_("Sunday, Non-Holiday"),
					              true,
					              MonthInfo.HolidayType.NON_HOLIDAY,
					              1.0,
					              pay_periods_sunday,
					              null),
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
				table_header_height = ((header_font_height + (padding * 2)) * 3);
				header_height = table_top + table_header_height;
				footer_height = (text_font_height + (padding * 2)) * 10;
				var table_header_line_height = table_header_height/3;


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
				table_width += signature_column_width;


				lines_first_page = (int) Math.floor ((height - header_height) / (text_font_height + (padding * 2)));
				lines_first_page -= lines_first_page % 2;

				lines_per_page = (int) Math.floor (height / (text_font_height + (padding * 2)));
				lines_per_page -= lines_per_page % 2;

				num_lines = employees.size * 2;
				if (num_lines < lines_first_page) {
					lines_first_page = num_lines;
				}


				/* Note: +10 for footer */
				pages_v = (int) Math.ceil ((double) (num_lines + (lines_first_page != num_lines? lines_per_page - lines_first_page : 0) + 10) / lines_per_page);
				pages_h = (int) Math.ceil (table_width / width);
				set_n_pages (pages_v * pages_h);

				stdout.printf ("Pages: %d\n", (int) Math.ceil ((double) (num_lines + (lines_first_page != num_lines? lines_per_page - lines_first_page : 0) + 10) / lines_per_page));
				stdout.printf ("Lines in First Page: %d\n", lines_first_page);
				stdout.printf ("Lines per Page: %d\n", lines_per_page);
				stdout.printf ("Number of Lines: %d\n", num_lines);
				stdout.printf ("Useable height in first page: %lf\n", height - header_height);
				stdout.printf ("Line height: %lf\n", text_font_height + (padding * 2));
				stdout.printf ("Width: %lf\n", width);
				stdout.printf ("Height: %lf\n", height);


				double table_x, table_y;


				surfaces = new Surface[pages_v];
				for (var surface = 0; surface < pages_v; surface++)
				{
					/* Create page */
					surfaces[surface] = new Surface.similar (context.get_cairo_context ().get_target (), Content.COLOR_ALPHA,
					                                         (int) Math.ceil (table_width),
					                                         (int) Math.ceil (height));
					var cr = new Cairo.Context (surfaces[surface]);

					var layout = context.create_pango_layout ();
					layout.set_wrap (Pango.WrapMode.WORD_CHAR);
					layout.set_ellipsize (EllipsizeMode.END);


					int id = (((surface-1) * lines_per_page) + lines_first_page)/2;
					int page_num_lines = lines_per_page;
					stdout.printf ("page_num_lines: %d\n", page_num_lines);
					if (surface == 0) {
						id = 0;
						page_num_lines = lines_first_page;
					stdout.printf ("page_num_lines A: %d\n", page_num_lines);
					} else if ((id + (page_num_lines/2)) > (num_lines/2)) {
						page_num_lines = num_lines - (id*2);
					stdout.printf ("page_num_lines B: %d\n", page_num_lines);
					}
					double table_content_height = (page_num_lines * (text_font_height + (padding * 2)));

					stdout.printf ("page_num_lines: %d\n", page_num_lines);

					if (surface == 0) {
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


						double x = padding, x0;
						layout.set_alignment (Pango.Alignment.CENTER);

						/* Name */
						cr.move_to (x, table_top + padding);
						layout.set_width (units_from_double (name_column_width - (padding * 2)));
						layout.set_markup (_("NAME OF EMPLOYEE"), -1);
						cairo_show_layout (cr, layout);
						x += name_column_width;

						/* Rate */
						cr.move_to (x, table_top + padding);
						layout.set_width (units_from_double (number_column_width - (padding * 2)));
						layout.set_markup (_("RATE"), -1);
						cairo_show_layout (cr, layout);
						x += number_column_width;

						/* Hourly Rate */
						cr.move_to (x, table_top + padding);
						layout.set_width (units_from_double (number_column_width - (padding * 2)));
						layout.set_markup (_("per\nHour"), -1);
						cairo_show_layout (cr, layout);
						x += number_column_width;

						foreach (var pay_group in pay_groups) {
							/* Date */
							cr.move_to (x, table_top + padding);
							layout.set_width (units_from_double (((hour_column_width + number_column_width) * pay_group.periods.length) + number_column_width - (padding * 2)));
							layout.set_markup (_("DATE"), -1);
							cairo_show_layout (cr, layout);

							foreach (var pay_period in pay_group.periods) {
								/* Hour */
								cr.move_to (x, table_top + table_header_line_height + padding);
								layout.set_width (units_from_double (hour_column_width - (padding * 2)));
								layout.set_markup (_("Hrs."), -1);
								cairo_show_layout (cr, layout);
								x += hour_column_width;

								/* Subtotal */
								cr.move_to (x, table_top + table_header_line_height + padding);
								layout.set_width (units_from_double (number_column_width - (padding * 2)));
								layout.set_markup (pay_period.name, -1);
								cairo_show_layout (cr, layout);
								x += number_column_width;
							}

							/* Subtotal each group */
							cr.move_to (x, table_top + table_header_line_height + padding);
							layout.set_width (units_from_double (number_column_width - (padding * 2)));
							layout.set_markup (_("Sub. Total"), -1);
							cairo_show_layout (cr, layout);
							x += number_column_width;
						}

						/* Total */
						cr.move_to (x, table_top + padding);
						layout.set_width (units_from_double (number_column_width - (padding * 2)));
						layout.set_markup (_("TOTAL\nAMOUNT"), -1);
						cairo_show_layout (cr, layout);
						x += number_column_width;

						/* Signature */
						cr.move_to (x, table_top + padding);
						layout.set_width (units_from_double (signature_column_width - (padding * 2)));
						layout.set_markup (_("SIGNATURE"), -1);
						cairo_show_layout (cr, layout);


						table_x = 0;
						table_y = header_height;

						/* Draw table lines */
						cr.rectangle (0, table_top, table_width, table_content_height + table_header_height);
						cr.set_line_width (2);
						cr.stroke ();

						/* Vertical */
						x = 0;
						x0 = 0;
						/* Name */
						x += name_column_width;
						cr.move_to (x, table_top);
						cr.rel_line_to (0, table_header_height);
						/* Rate */
						x += number_column_width;
						cr.move_to (x, table_top);
						cr.rel_line_to (0, table_header_height);
						/* Hourly Rate */
						x += number_column_width;
						cr.move_to (x, table_top);
						cr.rel_line_to (0, table_header_height);
						foreach (var pay_group in pay_groups) {
							foreach (var pay_period in pay_group.periods) {
								/* Hour and Subtotal */
								x0 = x;
								x += hour_column_width + number_column_width;
								cr.move_to (x0, table_top + table_header_line_height);
								cr.rel_line_to (x - x0 + number_column_width, 0);
								cr.move_to (x0, table_top + table_header_line_height * 2);
								cr.rel_line_to (x - x0, 0);
								cr.move_to (x, table_top + table_header_line_height);
								cr.rel_line_to (0, table_header_line_height * 2);
							}
							/* Subtotal each group */
							x += number_column_width;
							cr.move_to (x, table_top);
							cr.rel_line_to (0, table_header_height);
						}
						/* Total */
						x += number_column_width;
						cr.move_to (x, table_top);
						cr.rel_line_to (0, table_header_height);

						/* Horizontal */
						cr.move_to (0, table_top + table_header_height);
						cr.rel_line_to (table_width, 0);

						cr.set_line_width (2);
						cr.stroke ();
					} else {
						table_x = 0;
						table_y = 0;

						/* Draw table lines */
						cr.rectangle (0, 0, table_width, table_content_height);
						cr.set_line_width (2);
						cr.stroke ();
					}


					/* Print table lines */

					/* Horizontal */
					for (int i = 0; i < page_num_lines - 1 && (i+id) < num_lines; i++) {
						cr.move_to (0, table_y + ((text_font_height + (padding * 2)) * (i+1)));
						cr.rel_line_to (table_width, 0);
					}

					/* Vertical */
					double x = 0;
					/* Name */
					x += name_column_width;
					cr.move_to (x, table_y);
					cr.rel_line_to (0, table_content_height);
					/* Rate */
					x += number_column_width;
					cr.move_to (x, table_y);
					cr.rel_line_to (0, table_content_height);
					/* Hourly Rate */
					x += number_column_width;
					cr.move_to (x, table_y);
					cr.rel_line_to (0, table_content_height);
					foreach (var pay_group in pay_groups) {
						foreach (var pay_period in pay_group.periods) {
							/* Hour */
							x += hour_column_width;
							cr.move_to (x, table_y);
							cr.rel_line_to (0, table_content_height);
							/* Subtotal */
							x += number_column_width;
							cr.move_to (x, table_y);
							cr.rel_line_to (0, table_content_height);
						}
						/* Subtotal each group */
						x += number_column_width;
						cr.move_to (x, table_y);
						cr.rel_line_to (0, table_content_height);
					}
					/* Total */
					x += number_column_width;
					cr.move_to (x, table_y);
					cr.rel_line_to (0, table_content_height);

					cr.set_line_width (1);
					cr.stroke ();


					for (int i = 0; i * 2 < page_num_lines && (i+id) * 2 < num_lines; i++) {
						var employee = (employees as ArrayList<Employee>).get (i + id);
						/* Half-month salary - (salary per day times days without pay) */
						double salary = 0, subtotal;

						layout.set_height (units_from_double (text_font_height));

						layout.set_font_description (text_font);
						layout.set_alignment (Pango.Alignment.LEFT);

						cr.move_to (table_x + padding, table_y + padding + ((text_font_height + (padding * 2)) * 2 * i));

						/* Name */
						layout.set_width (units_from_double (name_column_width - (padding * 2)));
						layout.set_markup (employee.get_name ().up (), -1);
						cairo_show_layout (cr, layout);
						cr.rel_move_to (name_column_width, 0);

						/* Setup for numbers */
						layout.set_font_description (number_font);
						layout.set_alignment (Pango.Alignment.RIGHT);
						layout.set_width (units_from_double (number_column_width - (padding * 2)));

						/* Rates */
						layout.set_markup ("%.2lf".printf (employee.rate), -1);
						cairo_show_layout (cr, layout);
						cr.rel_move_to (number_column_width, 0);

						/* Hourly Rate */
						layout.set_markup ("%.2lf".printf (employee.rate/(26*8)), -1);
						cairo_show_layout (cr, layout);
						cr.rel_move_to (number_column_width, 0);

						foreach (var pay_group in pay_groups) {
							foreach (var pay_period in pay_group.periods) {
								/* Hour */
								layout.set_width (units_from_double (hour_column_width - (padding * 2)));
								layout.set_markup ("0", -1);
								cairo_show_layout (cr, layout);
								cr.rel_move_to (hour_column_width, 0);

								/* Subtotal */
								layout.set_width (units_from_double (number_column_width - (padding * 2)));
								layout.set_markup ("0.00", -1);
								cairo_show_layout (cr, layout);
								cr.rel_move_to (number_column_width, 0);
							}

							/* Subtotal each group */
							layout.set_width (units_from_double (number_column_width - (padding * 2)));
							layout.set_markup ("0.00", -1);
							cairo_show_layout (cr, layout);
							cr.rel_move_to (number_column_width, 0);
						}

						layout.set_width (units_from_double (name_column_width));

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

			public void draw_page_handler (Gtk.PrintContext context, int page_nr) {
				var cr = context.get_cairo_context ();

				var layout = context.create_pango_layout ();
				layout.set_wrap (Pango.WrapMode.WORD_CHAR);
				layout.set_ellipsize (EllipsizeMode.END);

				int page_h = page_nr % pages_v;
				int page_v = page_nr / pages_v;
				stdout.printf ("Page %d is (%d, %d)\n", page_nr, page_h, page_v);

				cr.rectangle (0, 0, width, height);
				cr.clip ();
				cr.set_source_surface (surfaces[page_v], page_h * -width, 0);
				cr.paint ();
			}

		}

	}

}
