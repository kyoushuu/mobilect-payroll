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

		public errordomain RegularReportError {
			PERIOD_START_NOT_MONTH_START_OR_MIDDLE,
			PERIOD_END_NOT_MONTH_END_OR_MIDDLE
		}


		public class RegularReport : Report {

			private enum Columns {
				DAYS,
				RATE,
				DAYS_WO_PAY,
				SALARY,
				TAX_SSS,
				LOAN,
				PAGIBIG_PHILHEALTH,
				SSS_LOAN,
				VALE,
				MOESALA_LOAN,
				MOEASALA_SAVINGS,
				TOTAL_DEDUC,
				NET_AMOUNT,
				NUM
			}


			private int days;
			private Filter filter_nh;

			private double[,] cells;

			private Deductions deductions;


			public RegularReport (Date start, Date end) throws ReportError, RegularReportError {
				base (start, end);

				if (start.get_day () != 1 && start.get_day () != 16) {
					throw new RegularReportError.PERIOD_START_NOT_MONTH_START_OR_MIDDLE (_("Period start should be 1st or 16th day of the month."));
				}

				var period = (int) Math.round ((start.get_day () - 1) / 30.0);

				DateDay last_day;
				if (period == 0) {
					last_day = 15;
				} else {
					last_day = 31;
					while (!Date.valid_dmy (last_day,
					                        start.get_month (),
					                        start.get_year ())) {
						last_day--;
					}
				}

				var correct_end = Date ();
				correct_end.set_dmy (last_day, start.get_month (), start.get_year ());
				if (correct_end.compare (end) != 0) {
					throw new RegularReportError.PERIOD_END_NOT_MONTH_END_OR_MIDDLE (_("Period end should be 15th or last day of the month."));
				}


				filter_nh = new Filter ();
				filter_nh.use_holiday_type = true;
				filter_nh.holiday_type = MonthInfo.HolidayType.NON_HOLIDAY;
				filter_nh.sunday_work = false;
				filter_nh.straight_time = false;
				filter_nh.date_start = start;
				filter_nh.date_end = end;
				filter_nh.time_periods = new TimePeriod[] {
					TimePeriod (Time (8,0), Time (12,0)),
					TimePeriod (Time (13,0), Time (17,0))
				};
			}

			public override void process () {
				var month_info = new MonthInfo (employees.database,
				                                this.start.get_year (),
				                                this.start.get_month ());
				for (var d = this.start; d.compare (this.end) <= 0; d.add_days (1)) {
					if (d.get_weekday () != DateWeekday.SUNDAY &&
					    month_info.get_day_type (d.get_day ()) == MonthInfo.HolidayType.NON_HOLIDAY) {
						days++;
					}
				}


				deductions = new Deductions.with_date (this.employees, this.start);

				int size = employees.size;
				cells = new double[size + 1, Columns.NUM]; /* Last is total */


				for (int i = 0; i < size; i++) {
					var employee = (employees as ArrayList<Employee>).get (i);

					double days_wo_pay = days - (employee.get_hours (filter_nh)/8);

					/* Half-month salary - (salary per day times days without pay) */
					double salary = (employee.rate/2) - (employee.rate_per_day * days_wo_pay);
					if (salary < 0) {
						salary = 0;
					}

					/* Iter */
					double value = 0;
					double deduction = 0;

					/* Days Present */
					cells[size, Columns.DAYS] += cells[i, Columns.DAYS] = days - days_wo_pay;

					/* Rates */
					cells[size, Columns.RATE] += cells[i, Columns.RATE] = employee.rate;

					/* Days w/o Pay */
					cells[size, Columns.DAYS_WO_PAY] += cells[i, Columns.DAYS_WO_PAY] = days_wo_pay;

					/* Salary to Date */
					cells[size, Columns.SALARY] += cells[i, Columns.SALARY] = salary;

					for (int column = Columns.TAX_SSS, category = Deductions.Category.TAX;
					     column <= Columns.MOEASALA_SAVINGS;
					     column++, category++) {
						value = deductions.get_deduction_with_category (employee, (Deductions.Category) category);
						deduction += value;
						cells[size, column] += cells[i, column] = value;
					}

					/* Total Deductions */
					cells[size, Columns.TOTAL_DEDUC] +=
						cells[i, Columns.TOTAL_DEDUC] = deduction;

					/* Net Amount */
					cells[size, Columns.NET_AMOUNT] +=
						cells[i, Columns.NET_AMOUNT] = salary - deduction;

					step ();
				}
			}

			public override void begin_print (PrintContext context) {
				base.begin_print (context);


				payslip_height = context.get_height ();
				payslip_width = context.get_width ();

				/* Landscape for payroll */
				payroll_height = payslip_width;
				payroll_width = payslip_height;


				if (payroll) {
					var temp = index_column_width + name_column_width +
						total_column_width + day_column_width +
						(number_column_width * 9) +
						total_column_width + signature_column_width;
					name_column_width += payroll_width - temp;

					lines_per_page = (int) Math.floor ((payroll_height - header_height) / table_content_line_height);
					lines_per_page -= lines_per_page % 2;

					payslip_per_page = (int) Math.floor (payslip_height / get_payslip_height ());

					num_lines = employees.size * 2;

					/* Note: +12 for footer */
					pages_payroll = (int) Math.ceil ((double) (num_lines + 12) / lines_per_page);
				}


				if (payslip) {
					if (continuous) {
						payslip_per_page = employees.size;
						payslip_height = payslip_per_page * get_payslip_height ();
					} else {
						payslip_per_page = (int) Math.floor (payslip_height / get_payslip_height ());
					}

					pages_payslip = (int) Math.ceil ((double) employees.size / payslip_per_page);
				}


				set_n_pages (pages_payroll + pages_payslip);
			}

			public override void draw_page (PrintContext context, int page_nr) {
				var dpadding = padding * 2;


				var cr = context.get_cairo_context ();

				var layout = context.create_pango_layout ();
				layout.get_context ().set_font_map (CairoFontMap.new_for_font_type (FontType.FT));
				layout.set_wrap (Pango.WrapMode.WORD_CHAR);
				layout.set_ellipsize (EllipsizeMode.END);

				if (page_nr < pages_payroll) {
					int id = (page_nr * lines_per_page)/2;
					int page_num_lines = lines_per_page;
					if ((id + (page_num_lines/2)) > (num_lines/2)) {
						page_num_lines = num_lines - (id*2);
					}

					/* Add summary to last page of payroll */
					if (page_nr == pages_payroll - 1) {
						page_num_lines++;
					}

					double table_content_height = (page_num_lines * table_content_line_height);

					double table_y = 0;


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

					cr.rel_move_to (index_column_width, (title_font_height + dpadding)*2);
					layout.set_alignment (Pango.Alignment.LEFT);
					layout.set_markup (_("<span foreground=\"blue\">M<span foreground=\"red\">O</span>BILECT POWER CORPORATION</span>"), -1);
					cairo_show_layout (cr, layout);

					/* Period */
					layout.set_font_description (header_font);
					layout.set_width (units_from_double (payroll_width/2));

					cr.move_to (payroll_width/2, table_top - (header_font_height + padding));
					layout.set_markup (_("For the period of %s").printf (period_to_string (this.start, this.end).up ()), -1);
					cairo_show_layout (cr, layout);


					/* Table Headers */
					layout.set_font_description (header_font);
					layout.set_alignment (Pango.Alignment.CENTER);

					cr.move_to (padding + index_column_width, table_top + dpadding);
					layout.set_width (units_from_double (name_column_width - dpadding));
					layout.set_markup (_("NAME OF EMPLOYEE"), -1);
					cairo_show_layout (cr, layout);
					cr.rel_move_to (name_column_width, 0);

					layout.set_width (units_from_double (total_column_width - dpadding));
					layout.set_markup (_("RATE"), -1);
					cairo_show_layout (cr, layout);
					cr.rel_move_to (total_column_width, 0);

					layout.set_width (units_from_double (day_column_width - dpadding));
					layout.set_markup (_("DAYS\nw/o PAY"), -1);
					cairo_show_layout (cr, layout);
					cr.rel_move_to (day_column_width, 0);

					layout.set_width (units_from_double (number_column_width - dpadding));

					layout.set_markup (_("SALARY\nTO DATE"), -1);
					cairo_show_layout (cr, layout);
					cr.rel_move_to (number_column_width * 6, 0);

					layout.set_markup (_("MOESALA\nLOAN"), -1);
					cairo_show_layout (cr, layout);
					cr.rel_move_to (number_column_width, 0);

					layout.set_markup (_("MOESALA\nSAVINGS"), -1);
					cairo_show_layout (cr, layout);
					cr.rel_move_to (number_column_width, 0);

					layout.set_markup (_("TOTAL\nDEDUC"), -1);
					cairo_show_layout (cr, layout);
					cr.rel_move_to (number_column_width, 0);

					layout.set_width (units_from_double (total_column_width - dpadding));
					layout.set_markup (_("NET\nAMOUNT"), -1);
					cairo_show_layout (cr, layout);
					cr.rel_move_to (total_column_width, 0);

					layout.set_width (units_from_double (signature_column_width - dpadding));
					layout.set_markup (_("SIGNATURE"), -1);
					cairo_show_layout (cr, layout);

					layout.set_width (units_from_double ((number_column_width * 5) - dpadding));

					cr.move_to (index_column_width + name_column_width + total_column_width + day_column_width + number_column_width + padding, table_top + padding);
					layout.set_markup (_("Salary Deduction"), -1);
					cairo_show_layout (cr, layout);

					layout.set_width (units_from_double (number_column_width - dpadding));

					cr.rel_move_to (0, table_header_line_height);
					if (this.start.get_day () == 1) {
						layout.set_markup (_("TAX"), -1);
					} else {
						layout.set_markup (_("SSS"), -1);
					}
					cairo_show_layout (cr, layout);

					cr.rel_move_to (number_column_width, 0);
					layout.set_markup (_("LOAN"), -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (number_column_width, 0);
					if (this.start.get_day () == 1) {
						layout.set_markup (_("PAG-IBIG"), -1);
					} else {
						layout.set_markup (_("PH"), -1);
					}
					cairo_show_layout (cr, layout);

					cr.rel_move_to (number_column_width, 0);
					layout.set_markup (_("SSS LOAN"), -1);
					cairo_show_layout (cr, layout);

					cr.rel_move_to (number_column_width, 0);
					layout.set_markup (_("VALE"), -1);
					cairo_show_layout (cr, layout);


					table_y = header_height;


					/* Draw table lines */
					cr.rectangle (index_column_width,
					              table_top,
					              payroll_width - index_column_width,
					              table_content_height + table_header_height);

					cr.set_line_width (table_border);
					cr.stroke ();


					/* Print table lines */
					/* Horizontal */
					cr.move_to (index_column_width + name_column_width +
					            total_column_width + day_column_width + number_column_width,
					            table_top + (table_header_height / 2));
					cr.rel_line_to ((5 * number_column_width), 0);

					cr.set_line_width (cell_border);
					cr.stroke ();

					cr.move_to (index_column_width,
					            table_top + table_header_height);
					cr.rel_line_to (payroll_width - index_column_width - cell_border, 0);

					cr.set_line_width (table_border);
					cr.stroke ();

					for (int i = 0; i < page_num_lines - 1 && (i+id) < num_lines; i++) {
						cr.move_to (index_column_width, table_y + table_content_line_height * (i + 1));
						cr.rel_line_to (payroll_width - index_column_width, 0);
					}

					cr.set_line_width (cell_border);
					cr.stroke ();


					/* Vertical */
					double x = index_column_width + name_column_width;

					cr.move_to (x, table_top);
					cr.rel_line_to (0, table_content_height + table_header_height);
					x += total_column_width;

					cr.move_to (x, table_top);
					cr.rel_line_to (0, table_content_height + table_header_height);
					x += day_column_width;

					cr.set_line_width (cell_border);
					cr.stroke ();

					double diff;
					for (var i = 0; i < 9; i++) {
						if (2 <= i && i <= 5) {
							diff = table_header_height / 2;
						} else {
							diff = 0;
						}

						cr.move_to (x, table_top + diff);
						cr.rel_line_to (0, table_content_height + table_header_height - diff);

						if (i == 1 || i == 4 || i == 6 || i == 8) {
							cr.set_line_width (table_border);
						} else {
							cr.set_line_width (cell_border);
						}
						cr.stroke ();

						x += number_column_width;
					}

					cr.move_to (x, table_top);
					cr.rel_line_to (0, table_content_height + table_header_height);
					x += total_column_width;

					cr.move_to (x, table_top);
					cr.rel_line_to (0, table_content_height + table_header_height);

					cr.set_line_width (table_border);
					cr.stroke ();


					/* Skip no. of days paid */
					for (int i = 0; i * 2 < page_num_lines && (i+id) * 2 < num_lines; i++) {
						var employee = (employees as ArrayList<Employee>).get (i + id);

						cr.move_to (padding, table_y + padding + (table_content_line_height * 2 * i));

						layout.set_font_description (emp_number_font);
						layout.set_alignment (Pango.Alignment.RIGHT);

						/* Index */
						layout.set_width (units_from_double (index_column_width - dpadding));
						layout.set_markup ("%d".printf (i + id + 1), -1);
						cairo_show_layout (cr, layout);

						layout.set_font_description (text_font);
						layout.set_alignment (Pango.Alignment.LEFT);

						cr.rel_move_to (index_column_width, 0);

						/* Name */
						layout.set_width (units_from_double (name_column_width - dpadding));
						layout.set_markup (employee.get_name ().up (), -1);
						cairo_show_layout (cr, layout);

						layout.set_font_description (number_font);
						layout.set_alignment (Pango.Alignment.RIGHT);

						cr.rel_move_to (name_column_width, 0);

						/* Rates */
						layout.set_width (units_from_double (total_column_width - dpadding));
						layout.set_markup (format_money (cells[i + id, Columns.RATE]), -1);
						cairo_show_layout (cr, layout);

						cr.rel_move_to (total_column_width, 0);

						/* Days w/o Pay */
						if (cells[i + id, Columns.DAYS_WO_PAY] > 0) {
							layout.set_width (units_from_double (day_column_width - dpadding));
							layout.set_markup ("%.1lf".printf (cells[i + id, Columns.DAYS_WO_PAY]), -1);
							cairo_show_layout (cr, layout);
						}

						cr.rel_move_to (day_column_width, 0);

						layout.set_width (units_from_double (number_column_width - dpadding));

						/* Salary to Date, Deductions, Total Deductions */
						for (int column = Columns.SALARY; column <= Columns.TOTAL_DEDUC; column++) {
							if (cells[i + id, column] > 0) {
								layout.set_markup (format_money (cells[i + id, column]), -1);
								cairo_show_layout (cr, layout);
							}

							cr.rel_move_to (number_column_width, 0);
						}

						/* Net Amount */
						layout.set_width (units_from_double (total_column_width - dpadding));
						layout.set_font_description (emp_number_font);

						layout.set_markup (format_money (cells[i + id, Columns.NET_AMOUNT]), -1);
						cairo_show_layout (cr, layout);

						/* TIN No. */
						layout.set_width (units_from_double (name_column_width - dpadding));

						layout.set_font_description (number_font);
						layout.set_alignment (Pango.Alignment.CENTER);

						cr.move_to (index_column_width + padding, table_y + padding + (table_content_line_height * ((2 * i) + 1)));
						layout.set_markup (employee.tin, -1);
						cairo_show_layout (cr, layout);

						step ();
					}

					if (page_nr == pages_payroll - 1) {
						int size = employees.size;

						layout.set_font_description (text_font);
						layout.set_alignment (Pango.Alignment.RIGHT);

						/* Name */
						cr.rel_move_to (0, table_content_line_height);
						layout.set_width (units_from_double (name_column_width - dpadding));
						layout.set_markup (_("<b>TOTAL</b>"), -1);
						cairo_show_layout (cr, layout);

						cr.rel_move_to (name_column_width, 0);

						layout.set_font_description (emp_number_font);

						/* Rates */
						layout.set_width (units_from_double (total_column_width - dpadding));
						layout.set_markup (format_money (cells[size, Columns.RATE]), -1);
						cairo_show_layout (cr, layout);

						cr.rel_move_to (total_column_width, 0);

						/* Days w/o Pay */
						layout.set_width (units_from_double (day_column_width - dpadding));
						layout.set_markup ("%.1lf".printf (cells[size, Columns.DAYS_WO_PAY]), -1);
						cairo_show_layout (cr, layout);

						cr.rel_move_to (day_column_width, 0);

						/* Salary to Date, Deductions, Total Deductions */
						layout.set_width (units_from_double (number_column_width - dpadding));

						for (int column = Columns.SALARY; column <= Columns.TOTAL_DEDUC; column++) {
							layout.set_markup (format_money (cells[size, column]), -1);
							cairo_show_layout (cr, layout);

							cr.rel_move_to (number_column_width, 0);
						}

						/* Net Amount */
						cr.rel_move_to (0, table_content_line_height * 2);

						layout.set_width (units_from_double (total_column_width - dpadding));
						layout.set_markup (format_money (cells[size, Columns.NET_AMOUNT]), -1);
						cairo_show_layout (cr, layout);


						double y;
						cr.get_current_point (out x, out y);

						cr.move_to (x, y + table_content_line_height);
						cr.rel_line_to (total_column_width, 0);
						cr.move_to (x, y + table_content_line_height + 2);
						cr.rel_line_to (total_column_width, 0);
						cr.set_line_width (1);
						cr.stroke ();

						layout.set_width (units_from_double (payroll_width / 2));

						layout.set_font_description (text_font);
						layout.set_alignment (Pango.Alignment.LEFT);

						cr.move_to (payroll_width / 2, y);
						layout.set_markup (_("<b>TOTAL PAYROLL:</b>"), -1);
						cairo_show_layout (cr, layout);


						int layout_width;

						y += table_content_line_height * 3;

						/* Prepared by */
						cr.move_to (index_column_width, y);
						layout.set_markup (_("<b>Prepared by:</b>"), -1);
						cairo_show_layout (cr, layout);
						cr.rel_move_to (0, table_content_line_height * 3);
						layout.set_markup (_("<b>%s</b>").printf (preparer), -1);
						cairo_update_layout (cr, layout);
						layout.get_size (out layout_width, null);
						cairo_show_layout (cr, layout);

						cr.rel_move_to (0, table_content_line_height - padding);

						cr.rel_line_to (units_to_double (layout_width), 0);
						cr.set_line_width (1);
						cr.stroke ();

						/* Approved by */
						cr.move_to (index_column_width + (payroll_width / 2), y);
						layout.set_markup (_("<b>Approved by:</b>"), -1);
						cairo_show_layout (cr, layout);
						cr.rel_move_to (0, table_content_line_height * 3);
						layout.set_markup (_("<b>%s</b>").printf (approver), -1);
						cairo_update_layout (cr, layout);
						layout.get_size (out layout_width, null);
						cairo_show_layout (cr, layout);

						cr.rel_move_to (0, table_content_line_height - padding);
						cr.get_current_point (out x, out y);

						cr.rel_line_to (units_to_double (layout_width), 0);
						cr.set_line_width (1);
						cr.stroke ();

						cr.move_to (x, y + padding);
						layout.set_width (layout_width);
						layout.set_alignment (Pango.Alignment.CENTER);
						layout.set_markup (_("<b>%s</b>").printf (approver_position), -1);
						cairo_show_layout (cr, layout);
					}
				} else {
					int id = (page_nr - pages_payroll) * payslip_per_page;

					double y = 0;
					var size = employees.size;
					for (int i = 0; i < payslip_per_page && i + id < size; i++) {
						draw_payslip (context, y, (employees as ArrayList<Employee>).get (i + id), cells[i + id, 0], cells[i + id, 3], deductions);
						y += get_payslip_height ();
					}
				}

				step ();
			}

		}

	}

}
