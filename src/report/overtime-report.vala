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

			private int lines_per_page;
			private int lines_first_page;
			private int num_lines;

			private double height;
			private double width;
			private double payroll_height;
			private double payroll_width;

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

			private int pages_v;
			private int pages_h;
			private int pages_payroll;
			private int pages_payslip;

			private Surface[] surfaces;
			public PayGroup[] pay_groups { get; set; }


			public OvertimeReport (Date start, Date end) throws ReportError {
				base (start, end);
			}


			public override void request_page_setup (PrintContext context, int page_nr, PageSetup setup) {
				if (page_nr < pages_payroll) {
					setup.set_orientation (PageOrientation.LANDSCAPE);
				}
			}

			public override void begin_print (PrintContext context) {
				update_font_height (context);

				/* Get height of header and footer */
				table_top = (title_font_height * 2) + company_name_font_height + (padding * 6);
				table_header_height = ((header_font_height + (padding * 2)) * 3);
				header_height = table_top + table_header_height;
				footer_height = (text_font_height + (padding * 2)) * 10;
				var table_header_line_height = table_header_height/3;


				height = context.get_height ();
				width = context.get_width ();

				/* Landscape */
				payroll_height = width;
				payroll_width = height;


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


				lines_first_page = (int) Math.floor ((payroll_height - header_height) / (text_font_height + (padding * 2)));
				lines_first_page -= lines_first_page % 2;

				lines_per_page = (int) Math.floor (payroll_height / (text_font_height + (padding * 2)));
				lines_per_page -= lines_per_page % 2;

				num_lines = employees.size * 2;
				if (num_lines < lines_first_page) {
					lines_first_page = num_lines;
				}

				payslip_per_page = (int) Math.floor (height / get_payslip_height ());


				/* Note: +10 for footer */
				pages_v = (int) Math.ceil ((double) (num_lines + (lines_first_page != num_lines? lines_per_page - lines_first_page : 0) + 10) / lines_per_page);
				pages_h = (int) Math.ceil (table_width / payroll_width);
				pages_payroll = pages_v * pages_h;
				pages_payslip = (int) Math.ceil ((double) employees.size / payslip_per_page);
				set_n_pages (pages_payroll + pages_payslip);


				double table_x, table_y;


				surfaces = new Surface[pages_v];
				for (var surface = 0; surface < pages_v; surface++)
				{
					/* Create page */
					surfaces[surface] = new Surface.similar (context.get_cairo_context ().get_target (), Content.COLOR_ALPHA,
					                                         (int) Math.ceil (table_width),
					                                         (int) Math.ceil (payroll_height));
					var cr = new Cairo.Context (surfaces[surface]);

					var layout = context.create_pango_layout ();
					layout.set_wrap (Pango.WrapMode.WORD_CHAR);
					layout.set_ellipsize (EllipsizeMode.END);


					int id = (((surface-1) * lines_per_page) + lines_first_page)/2;
					int page_num_lines = lines_per_page;
					if (surface == 0) {
						id = 0;
						page_num_lines = lines_first_page;
					} else if ((id + (page_num_lines/2)) > (num_lines/2)) {
						page_num_lines = num_lines - (id*2);
					}
					double table_content_height = (page_num_lines * (text_font_height + (padding * 2)));

					if (surface == 0) {
						/* Print out headers */

						/* Title */
						layout.set_font_description (title_font);
						layout.set_width (units_from_double (payroll_width));

						cr.move_to (0, padding);
						layout.set_alignment (Pango.Alignment.CENTER);
						layout.set_markup (@"<u>$title</u>", -1);
						cairo_show_layout (cr, layout);

						/* Company Name */
						layout.set_font_description (company_name_font);
						layout.set_width (units_from_double (payroll_width/2));

						cr.rel_move_to (0, (title_font_height + (padding * 2))*2);
						layout.set_alignment (Pango.Alignment.LEFT);
						layout.set_markup (_("<span foreground=\"blue\">M<span foreground=\"red\">O</span>BILECT POWER CORPORATION</span>"), -1);
						cairo_show_layout (cr, layout);

						/* Period */
						layout.set_font_description (header_font);
						layout.set_width (units_from_double (payroll_width/2));

						cr.move_to (payroll_width/2, table_top - (header_font_height + padding));
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
							layout.set_markup (pay_group.name, -1);
							cairo_show_layout (cr, layout);

							foreach (var pay_period in pay_group.periods) {
								/* Percentage */
								cr.move_to (x, table_top + (table_header_line_height * 2) + padding);
								layout.set_width (units_from_double (hour_column_width + number_column_width - (padding * 2)));
								layout.set_markup (pay_period.rate > 1.0? _("(+%.0lf%%)").printf ((pay_period.rate - 1.0) * 100) : _("(Reg.)"), -1);
								cairo_show_layout (cr, layout);

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

							/* Percentage */
							if (pay_group.rate > 1.0) {
								cr.move_to (x, table_top + (table_header_line_height * 2) + padding);
								layout.set_width (units_from_double (number_column_width - (padding * 2)));
								layout.set_markup (_("(+%.0lf%%)").printf ((pay_group.rate - 1) * 100), -1);
								cairo_show_layout (cr, layout);
							}

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
						cr.set_line_width (1.5);
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

						cr.set_line_width (1.5);
						cr.stroke ();
					} else {
						table_x = 0;
						table_y = 0;

						/* Draw table lines */
						cr.rectangle (0, 0, table_width, table_content_height);
						cr.set_line_width (1.5);
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
						double salary = 0, subtotal, hours, pay, rate, deduction;

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
						rate = employee.rate_per_hour;
						layout.set_markup ("%.2lf".printf (rate), -1);
						cairo_show_layout (cr, layout);
						cr.rel_move_to (number_column_width, 0);

						foreach (var pay_group in pay_groups) {
							subtotal = 0;
							deduction = 0;

							for (var j = 0; j < pay_group.periods.length; j++) {
								var pay_period = pay_group.periods[j];
								hours = employee.get_hours (pay_group.create_filter (j, start, end));
								pay = hours * rate * pay_period.rate;

								subtotal += pay;
								if (pay_group.minus_period_rates != null) {
									deduction += hours * rate * pay_group.minus_period_rates[j];
								}

								/* Hour */
								layout.set_width (units_from_double (hour_column_width - (padding * 2)));
								layout.set_markup ("%.0lf".printf (hours), -1);
								cairo_show_layout (cr, layout);
								cr.rel_move_to (hour_column_width, 0);

								/* Subtotal */
								layout.set_width (units_from_double (number_column_width - (padding * 2)));
								layout.set_markup ("%.2lf".printf (pay), -1);
								cairo_show_layout (cr, layout);
								cr.rel_move_to (number_column_width, 0);
							}

							subtotal *= pay_group.rate;
							subtotal -= deduction;
							salary += subtotal;

							/* Subtotal each group */
							layout.set_width (units_from_double (number_column_width - (padding * 2)));
							layout.set_markup ("%.2lf".printf (subtotal), -1);
							cairo_show_layout (cr, layout);
							cr.rel_move_to (number_column_width, 0);
						}

						/* Total */
						layout.set_width (units_from_double (number_column_width - (padding * 2)));
						layout.set_markup ("%.2lf".printf (salary), -1);
						cairo_show_layout (cr, layout);

						layout.set_width (units_from_double (name_column_width - (padding * 2)));

						layout.set_font_description (number_font);
						layout.set_alignment (Pango.Alignment.CENTER);

						/* TIN No. */
						cr.move_to (table_x + padding, table_y + padding + ((text_font_height + (padding * 2)) * ((2 * i) + 1)));
						layout.set_markup (employee.tin, -1);
						cairo_show_layout (cr, layout);
						cr.rel_move_to (0, (text_font_height + (padding * 2)));
					}
				}
			}

			public override void draw_page (PrintContext context, int page_nr) {
				var cr = context.get_cairo_context ();

				if (page_nr < pages_payroll) {
					int page_h = page_nr % pages_h;
					int page_v = page_nr / pages_h;

					cr.rectangle (0, 0, payroll_width, payroll_height);
					cr.clip ();
					cr.set_source_surface (surfaces[page_v], page_h * -payroll_width, 0);
					cr.paint ();
				} else {
					var layout = context.create_pango_layout ();
					layout.set_wrap (Pango.WrapMode.WORD_CHAR);
					layout.set_ellipsize (EllipsizeMode.END);
				}
			}

		}

	}

}
