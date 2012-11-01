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
using Portability;


namespace Mobilect {

	namespace Payroll {

		public class OvertimeReport : Report {

			private double table_width;

			private Surface[] surfaces;
			public PayGroup[] pay_groups { get; set; }
			public PayPeriod[] pay_periods { get; set; }

			private class PeriodPay {
				public weak PayPeriod pay_period;

				public int hours;

				public PeriodPay (PayPeriod pay_period) {
					this.pay_period = pay_period;
				}

				private double earnings;
				public double get_earnings_in_rate (double rate) {
					if (earnings <= 0) {
						earnings = rate * pay_period.rate * hours;
					}

					return earnings;
				}
			}

			private class GroupPay {
				public weak PayGroup pay_group;
				public LinkedList <PeriodPay> periods;

				private int _total_hours;
				public int total_hours {
					get {
						if (_total_hours <= 0) {
							_total_hours = 0;

							foreach (var period in periods) {
								if (period.pay_period.is_overtime ||
								    pay_group.straight_time ||
								    pay_group.is_sunday_work) {
									_total_hours += period.hours;
								}
							}
						}

						return _total_hours;
					}
				}

				private double earnings;
				public double get_earnings_in_rate (double rate) {
					if (earnings == 0) {
						earnings = 0;

						foreach (var period in periods) {
							/* Remove paid parts from regular */
							if (period.pay_period.is_overtime ||
							    pay_group.straight_time ||
							    pay_group.is_sunday_work) {
								earnings += pay_group.rate * period.get_earnings_in_rate (rate);
							} else {
								earnings += (pay_group.rate - 1) * period.get_earnings_in_rate (rate);
							}
						}
					}

					return earnings;
				}

				public GroupPay (PayGroup pay_group) {
					this.pay_group = pay_group;
					this.periods = new LinkedList <PeriodPay> ();
				}
			}

			private class EmployeePay {
				public weak Employee employee;
				public LinkedList <GroupPay> groups;

				private int _total_hours;
				public int total_hours {
					get {
						if (_total_hours <= 0) {
							_total_hours = 0;

							foreach (var group in groups) {
								_total_hours += group.total_hours;
							}
						}

						return _total_hours;
					}

				}

				private double _earnings;
				public double earnings {
					get {
						if (_earnings == 0) {
							_earnings = 0;

							foreach (var group in groups) {
								_earnings += group.get_earnings_in_rate (employee.rate_per_hour);
							}
						}

						return _earnings;
					}

				}

				public EmployeePay (Employee employee) {
					this.employee = employee;
					this.groups = new LinkedList <GroupPay> ();
				}
			}

			private LinkedList <EmployeePay> employee_data;


			public OvertimeReport (Date start, Date end) throws ReportError {
				base (start, end);
			}

			public void process () {
				var database = employees.database;


				/* Check if the groups affect any dates */
				int affected;
				var affected_pay_groups = new LinkedList<PayGroup> ();
				foreach (var pay_group in pay_groups) {
					affected = 0;

					foreach (var pay_period in pay_periods) {
						affected += pay_group.create_filter (pay_period, start, end)
							.get_affected_dates (database).length;

						step ();
					}

					if (affected > 0) {
						affected_pay_groups.add (pay_group);
					}

					step ();
				}


				employee_data = new LinkedList <EmployeePay> ();

				foreach (var employee in employees) {
					var emp_pay = new EmployeePay (employee);

					foreach (var pay_group in affected_pay_groups) {
						var group = new GroupPay (pay_group);

						foreach (var pay_period in pay_periods) {
							var period = new PeriodPay (pay_period);
							period.hours = (int) Math.floor (employee.get_hours (pay_group.create_filter (pay_period, start, end)));

							group.periods.add (period);

							step ();
						}

						if (group.total_hours > 0) {
							emp_pay.groups.add (group);
						}

						step ();
					}

					if (emp_pay.groups.size > 0) {
						employee_data.add (emp_pay);
					}

					step ();
				}
			}

			public override void begin_print (PrintContext context) {
				process ();

				update_font_metrics (context);

				/* Get height of header and footer */
				table_top = (title_font_height * 2) + company_name_font_height + (padding * 6);
				table_header_height = ((header_font_height + (padding * 2)) * 2);
				header_height = table_top + table_header_height;
				footer_height = (text_font_height + (padding * 2)) * 10;


				payslip_height = context.get_height ();
				payslip_width = context.get_width ();

				payroll_height = payslip_height;
				payroll_width = payslip_width;


				/* Name, Rate and Hourly Rate */
				table_width = name_column_width +
					rate_column_width +
					hourly_rate_column_width;

				/* Hour and Subtotal per pay period */
				table_width += (hour_column_width + subtotal_column_width) * pay_periods.length;

				/* Total and Signature */
				table_width += total_column_width;
				table_width += signature_column_width;


				name_column_width += payroll_width - table_width - index_column_width - total_hour_column_width;
				table_width = payroll_width - index_column_width - total_hour_column_width;


				lines_per_page = (int) Math.floor ((payroll_height - header_height) / (text_font_height + (padding * 2)));

				num_lines = 0;
				foreach (var emp_pay in employee_data) {
					num_lines += (emp_pay.groups.size * 2) + 1;
				}

				if (continuous) {
					payslip_per_page = employee_data.size;
					payslip_height = payslip_per_page * get_payslip_height ();
				} else {
					payslip_per_page = (int) Math.floor (payslip_height / get_payslip_height ());
				}


				/* Note: +12 for footer */
				pages_payroll = (int) Math.ceil ((double) (num_lines + 12) / lines_per_page);
				pages_payslip = (int) Math.ceil ((double) employee_data.size / payslip_per_page);
				set_n_pages (pages_payroll + pages_payslip);


				double table_y, x, y = 0;
				int page_line = 0, curr_line = 0;
				int surface = 0;
				double period_column_width = hour_column_width + subtotal_column_width;

				Cairo.Context cr = null;
				Pango.Layout layout = null;
				int id = 0;

				surfaces = new Surface[pages_payroll];
				foreach (var employee in employee_data) {
					int groups_size = employee.groups.size;
					for (int employee_line = 0; employee_line < (groups_size * 2) + 1; employee_line++)
					{
						var table_header_line_height = table_header_height/2;

						if (page_line == 0) {
							/* Create page */
							surfaces[surface] = new Surface.similar (context.get_cairo_context ().get_target (), Content.COLOR_ALPHA,
							                                         (int) Math.ceil (payroll_width),
							                                         (int) Math.ceil (payroll_height));
							cr = new Cairo.Context (surfaces[surface]);

							layout = context.create_pango_layout ();
							layout.get_context ().set_font_map (CairoFontMap.new_for_font_type (FontType.FT));
							layout.set_wrap (Pango.WrapMode.WORD_CHAR);
							layout.set_ellipsize (EllipsizeMode.END);


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

							cr.rel_move_to (index_column_width, (title_font_height + (padding * 2))*2);
							layout.set_alignment (Pango.Alignment.LEFT);
							layout.set_markup (_("<span foreground=\"blue\">M<span foreground=\"red\">O</span>BILECT POWER CORPORATION</span>"), -1);
							cairo_show_layout (cr, layout);


							x = index_column_width + padding;
							layout.set_font_description (header_font);
							layout.set_alignment (Pango.Alignment.CENTER);

							/* Name */
							cr.move_to (x, table_top + padding);
							layout.set_width (units_from_double (name_column_width - (padding * 2)));
							layout.set_markup (_("NAME OF\nEMPLOYEE"), -1);
							cairo_show_layout (cr, layout);
							x += name_column_width;

							/* Rate */
							cr.move_to (x, table_top + padding);
							layout.set_width (units_from_double (rate_column_width - (padding * 2)));
							layout.set_markup (_("RATE"), -1);
							cairo_show_layout (cr, layout);
							x += rate_column_width;

							/* Hourly Rate */
							cr.move_to (x, table_top + padding);
							layout.set_width (units_from_double (hourly_rate_column_width - (padding * 2)));
							layout.set_markup (_("per\nHour"), -1);
							cairo_show_layout (cr, layout);
							x += hourly_rate_column_width;

							foreach (var pay_period in pay_periods) {
								/* Percentage */
								cr.move_to (x, table_top + table_header_line_height + padding);
								layout.set_width (units_from_double (hour_column_width + subtotal_column_width - (padding * 2)));
								layout.set_markup (pay_period.rate > 1.0? _("(+%.0lf%%)").printf ((pay_period.rate - 1.0) * 100) : _("(Reg.)"), -1);
								cairo_show_layout (cr, layout);

								/* Hour */
								cr.move_to (x, table_top + padding);
								layout.set_width (units_from_double (hour_column_width - (padding * 2)));
								layout.set_markup (_("Hrs."), -1);
								cairo_show_layout (cr, layout);
								x += hour_column_width;

								/* Subtotal */
								cr.move_to (x, table_top + padding);
								layout.set_width (units_from_double (subtotal_column_width - (padding * 2)));
								layout.set_markup (pay_period.name, -1);
								cairo_show_layout (cr, layout);
								x += subtotal_column_width;
							}

							/* Total */
//							cr.move_to (x, table_top + padding);
//							layout.set_width (units_from_double (total_column_width - (padding * 2)));
//							layout.set_markup (_("TOTAL\nAMOUNT"), -1);
//							cairo_show_layout (cr, layout);
							x += total_column_width;

							/* Signature */
							cr.move_to (x, table_top + padding);
							layout.set_width (units_from_double (signature_column_width - (padding * 2)));
							layout.set_markup (_("SIGNATURE"), -1);
							cairo_show_layout (cr, layout);

							table_y = header_height;
							y = table_y;
						}

						if (employee_line == 0) {
							/* Index */
							cr.move_to (padding, y + padding);

							layout.set_width (units_from_double (index_column_width - (padding * 2)));
							layout.set_font_description (emp_number_font);
							layout.set_alignment (Pango.Alignment.RIGHT);

							layout.set_markup ("%d".printf (id + 1), -1);
							cairo_show_layout (cr, layout);


							var layout_height = layout.get_height ();


							/* Name */
							cr.move_to (index_column_width + padding, y + padding);

							layout.set_width (units_from_double (name_column_width - (padding * 2)));
							layout.set_font_description (text_font);
							layout.set_alignment (Pango.Alignment.LEFT);
							layout.set_height (units_from_double ((text_font_height + (padding * 2)) * 3));

							layout.set_markup (employee.employee.get_name ().up (), -1);
							cairo_show_layout (cr, layout);


							/* TIN Number */
							cr.rel_move_to (0, layout.get_line_count () * (text_font_height + (padding * 2)));

							layout.set_font_description (number_font);
							layout.set_alignment (Pango.Alignment.CENTER);
							layout.set_height (units_from_double (text_font_height + (padding * 2)));

							layout.set_markup (employee.employee.tin, -1);

							cairo_show_layout (cr, layout);


							layout.set_height (layout_height);


							/* Rate */
							cr.move_to (index_column_width + name_column_width + padding, y + padding);

							layout.set_width (units_from_double (rate_column_width - (padding * 2)));
							layout.set_font_description (number_font);
							layout.set_alignment (Pango.Alignment.RIGHT);

							layout.set_markup (format_money ((double) employee.employee.rate), -1);
							cairo_show_layout (cr, layout);


							/* Rate per Hour */
							cr.rel_move_to (rate_column_width, 0);

							layout.set_width (units_from_double (hourly_rate_column_width - (padding * 2)));
							layout.set_font_description (number_font);
							layout.set_alignment (Pango.Alignment.RIGHT);

							layout.set_markup ("%.2lf".printf (employee.employee.rate_per_hour), -1);
							cairo_show_layout (cr, layout);


							/* Total Hours */
							cr.move_to (index_column_width + table_width + padding, y + padding);

							layout.set_width (units_from_double (total_hour_column_width - (padding * 2)));
							layout.set_font_description (number_font);
							layout.set_alignment (Pango.Alignment.RIGHT);

							layout.set_markup ("%d".printf (employee.total_hours), -1);
							cairo_show_layout (cr, layout);
						}


						x = index_column_width + name_column_width +
							rate_column_width + hourly_rate_column_width +
							padding;

						if (employee_line < groups_size * 2) {
							var group = employee.groups.get (employee_line/2);

							/* Pay Group */
							if (employee_line % 2 == 0) {
								/* Pay Group name */
								cr.move_to (x, y + padding);

								layout.set_width (units_from_double ((period_column_width * 3) - (padding * 2)));
								layout.set_font_description (text_font);
								layout.set_alignment (Pango.Alignment.CENTER);

								layout.set_markup (group.pay_group.name, -1);
								cairo_show_layout (cr, layout);


								cr.rel_move_to (period_column_width * 3, 0);

								if (group.pay_group.rate > 1.0) {
									layout.set_width (units_from_double (total_column_width - (padding * 2)));
									layout.set_markup (_("(+%.0lf%%)").printf ((group.pay_group.rate - 1) * 100), -1);
									cairo_show_layout (cr, layout);
								}
							} else {
								/* Pay Periods */
								foreach (var period in group.periods) {
									if (period.hours > 0 &&
									    (period.pay_period.is_overtime ||
									     group.pay_group.straight_time ||
									     group.pay_group.is_sunday_work)) {
										/* Hours */
										cr.move_to (x, y + padding);

										layout.set_width (units_from_double (hour_column_width - (padding * 2)));
										layout.set_font_description (number_font);
										layout.set_alignment (Pango.Alignment.RIGHT);

										layout.set_markup (period.hours.to_string (), -1);
										cairo_show_layout (cr, layout);


										/* Earnings */
										cr.move_to (x + hour_column_width, y + padding);

										layout.set_width (units_from_double (subtotal_column_width - (padding * 2)));
										layout.set_font_description (number_font);
										layout.set_alignment (Pango.Alignment.RIGHT);

										layout.set_markup (format_money (period.get_earnings_in_rate (employee.employee.rate_per_hour)), -1);
										cairo_show_layout (cr, layout);


										cr.move_to (x + hour_column_width - padding, y);
										cr.rel_line_to (0, text_font_height + (padding * 2));
									}

									cr.move_to (x + period_column_width - padding, y);
									cr.rel_line_to (0, text_font_height + (padding * 2));

									cr.set_line_width (cell_border);
									cr.stroke ();


									x += period_column_width;
								}

								/* Group Total */
								cr.move_to (x, y + padding);

								layout.set_width (units_from_double (total_column_width - (padding * 2)));
								layout.set_font_description (number_font);
								layout.set_alignment (Pango.Alignment.RIGHT);

								layout.set_markup (format_money (group.get_earnings_in_rate (employee.employee.rate_per_hour)), -1);
								cairo_show_layout (cr, layout);
							}


							cr.move_to (index_column_width + name_column_width +
							            rate_column_width + hourly_rate_column_width,
							            y + text_font_height + (padding * 2));
							cr.rel_line_to ((period_column_width * 3) + total_column_width, 0);

							cr.set_line_width (cell_border);
							cr.stroke ();
						} else {
							/* Employee Total */
							cr.move_to (x, y + padding);

							layout.set_width (units_from_double ((period_column_width * 3) - (padding * 2)));
							layout.set_font_description (text_font);
							layout.set_alignment (Pango.Alignment.CENTER);

							layout.set_markup (_("<b>TOTAL AMOUNT</b>"), -1);
							cairo_show_layout (cr, layout);


							cr.rel_move_to (period_column_width * 3, 0);

							layout.set_width (units_from_double (total_column_width - (padding * 2)));
							layout.set_font_description (emp_number_font);
							layout.set_alignment (Pango.Alignment.RIGHT);

							layout.set_markup (format_money (employee.earnings), -1);
							cairo_show_layout (cr, layout);


							cr.move_to (index_column_width, y + text_font_height + (padding * 2));
							cr.rel_line_to (table_width, 0);

							cr.set_line_width (cell_border);
							cr.stroke ();
						}


						page_line++;
						curr_line++;
						y += text_font_height + (padding * 2);

						if (page_line > lines_per_page || curr_line == num_lines) {
							double table_content_height = (page_line * (text_font_height + (padding * 2)));

							/* Draw table lines */
							cr.rectangle (index_column_width + (table_border / 2),
							              table_top,
							              table_width - table_border,
							              table_content_height + table_header_height);
							cr.set_line_width (table_border);
							cr.stroke ();

							/* Vertical */
							x = index_column_width + name_column_width +
								rate_column_width + hourly_rate_column_width;
							double x0 = 0;

							foreach (var pay_period in pay_periods) {
								/* Hour and Subtotal */
								x0 = x;
								x += hour_column_width + subtotal_column_width;

								cr.move_to (x0, table_top + table_header_line_height);
								cr.rel_line_to (x - x0, 0);

								cr.move_to (x, table_top);
								cr.rel_line_to (0, table_header_line_height * 2);
							}

							cr.set_line_width (cell_border);
							cr.stroke ();

							/* Horizontal */
							cr.move_to (index_column_width, table_top + table_header_height);
							cr.rel_line_to (table_width, 0);

							cr.set_line_width (table_border);
							cr.stroke ();

							/* Vertical */

							/* Name */
							x = index_column_width + name_column_width;
							cr.move_to (x, table_top);
							cr.rel_line_to (0, table_content_height + table_header_height);

							/* Rate */
							x += rate_column_width;
							cr.move_to (x, table_top);
							cr.rel_line_to (0, table_content_height + table_header_height);

							cr.set_line_width (cell_border);
							cr.stroke ();

							/* Hourly Rate */
							x += hourly_rate_column_width;
							cr.move_to (x, table_top);
							cr.rel_line_to (0, table_content_height + table_header_height);

							/* Periods */
							x += period_column_width * 3;
							cr.move_to (x, table_top);
							cr.rel_line_to (0, table_content_height + table_header_height);

							/* Total */
							x += total_column_width;
							cr.move_to (x, table_top);
							cr.rel_line_to (0, table_content_height + table_header_height);

							cr.set_line_width (table_border);
							cr.stroke ();
						}

						if (page_line > lines_per_page) {
							page_line = 0;
							surface++;
						}
					}

					id++;
					step ();
				}

				if (cr != null) {
					surface = pages_payroll - 1;

					double total_earnings = 0;
					foreach (var emp_pay in employee_data) {
						total_earnings += emp_pay.earnings;
					}

					y += text_font_height + (padding * 2);

					layout.set_width (units_from_double (total_column_width - (padding * 2)));
					layout.set_font_description (emp_number_font);
					layout.set_alignment (Pango.Alignment.RIGHT);

					cr.move_to (index_column_width + name_column_width +
					            rate_column_width + hourly_rate_column_width +
					            (period_column_width * 3) + padding,
					            y + padding);
					layout.set_markup (format_money (total_earnings), -1);
					cairo_show_layout (cr, layout);

					cr.move_to (index_column_width + name_column_width +
					            rate_column_width + hourly_rate_column_width +
					            (period_column_width * 3),
					            y + text_font_height + (padding * 2));
					cr.rel_line_to (total_column_width, 0);
					cr.set_line_width (1);
					cr.stroke ();

					cr.move_to (index_column_width + name_column_width +
					            rate_column_width + hourly_rate_column_width +
					            (period_column_width * 3),
					            y + text_font_height + (padding * 2) + 2);
					cr.rel_line_to (total_column_width, 0);
					cr.set_line_width (1);
					cr.stroke ();

					layout.set_width (units_from_double (table_width / 2));
					layout.set_font_description (header_font);
					layout.set_alignment (Pango.Alignment.LEFT);

					cr.move_to (table_width / 2, y);
					layout.set_markup (_("TOTAL OVERTIME:"), -1);
					cairo_show_layout (cr, layout);

					layout.set_font_description (header_font);
					layout.set_alignment (Pango.Alignment.LEFT);

					cr.move_to (index_column_width, y + (text_font_height + (padding * 2)) * 3);
					layout.set_markup (_("Prepared by:"), -1);
					cairo_show_layout (cr, layout);
					cr.rel_move_to (0, (text_font_height + (padding * 2)) * 3);
					layout.set_markup (_("<u>%s</u>").printf (preparer), -1);
					cairo_show_layout (cr, layout);

					int layout_width;
					cr.move_to ((table_width / 2), y + (text_font_height + (padding * 2)) * 3);
					layout.set_markup (_("Approved by:"), -1);
					cairo_show_layout (cr, layout);
					cr.rel_move_to (0, (text_font_height + (padding * 2)) * 3);
					layout.set_markup (_("<u>%s</u>").printf (approver), -1);
					cairo_update_layout (cr, layout);
					layout.get_size (out layout_width, null);
					cairo_show_layout (cr, layout);

					layout.set_width (layout_width);
					layout.set_alignment (Pango.Alignment.CENTER);
					cr.rel_move_to (0, text_font_height + (padding * 2));
					layout.set_markup (approver_position, -1);
					cairo_show_layout (cr, layout);
				}
			}

			public override void draw_page (PrintContext context, int page_nr) {
				var cr = context.get_cairo_context ();

				if (page_nr < pages_payroll) {
					/* Copy surface created before into page surface */
					cr.rectangle (0, 0, payroll_width, payroll_height);
					cr.clip ();
					cr.set_source_surface (surfaces[page_nr], 0, 0);
					cr.paint ();
				} else {
					int id = (page_nr - pages_payroll) * payslip_per_page;

					/* Draw payslip */
					double y = 0;
					var size = employee_data.size;
					for (int i = 0; i < payslip_per_page && i + id < size; i++) {
						var emp_pay = employee_data.get (i + id);
						draw_payslip (context, y, emp_pay.employee, emp_pay.total_hours, emp_pay.earnings);
						y += get_payslip_height ();
					}
				}

				step ();
			}

		}

	}

}
