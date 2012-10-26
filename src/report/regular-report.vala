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

		public errordomain RegularReportError {
			PERIOD_START_NOT_MONTH_START_OR_MIDDLE,
			PERIOD_END_NOT_MONTH_END_OR_MIDDLE
		}


		public class RegularReport : Report {

			private int days;
			private Filter filter_nh;
			private Filter filter_rh;
			private Filter filter_sh;

			private double[,] cells;

			private Deductions deductions;

			private double index_column_width = 20;


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

				filter_rh = filter_nh.duplicate ();
				filter_rh.holiday_type = MonthInfo.HolidayType.REGULAR_HOLIDAY;

				filter_sh = filter_nh.duplicate ();
				filter_sh.holiday_type = MonthInfo.HolidayType.SPECIAL_HOLIDAY;
			}

			public void process () {
				var month_info = new MonthInfo (employees.database,
				                                this.start.get_year (),
				                                this.start.get_month ());
				for (var d = this.start; d.compare (this.end) <= 0; d.add_days (1)) {
					if (d.get_weekday () != DateWeekday.SUNDAY &&
					    month_info.get_day_type (d.get_day ()) == MonthInfo.HolidayType.NON_HOLIDAY) {
						days++;
					}
				}


				deductions = new Deductions.with_date (this.employees.database, this.start);

				int size = employees.size;
				cells = new double[size + 1, 13]; /* Last is total */


				for (int i = 0, j = 0; i < employees.size; i++, j = 0) {
					var employee = (employees as ArrayList<Employee>).get (i);

					double days_wo_pay = days - (employee.get_hours (filter_nh)/8);
					double holidays_w_pay = (employee.get_hours (filter_rh) + employee.get_hours (filter_sh))/8;

					/* Half-month salary - (salary per day times days without pay) */
					/* Include holiday regular hours with pay */
					double salary = (employee.rate/2) + (employee.rate_per_day * (holidays_w_pay - days_wo_pay));
					if (salary < 0) {
						salary = 0;
					}
					cells[i, j] = days - days_wo_pay + holidays_w_pay;
					cells[size, j] += cells[i, j];
					j++;

					/* Iter */
					double value = 0;
					double deduction = 0;

					/* Rates */
					cells[i, j] = employee.rate;
					cells[size, j] += cells[i, j];
					j++;

					/* Days w/o Pay */
					cells[i, j] = days_wo_pay;
					cells[size, j] += cells[i, j];
					j++;

					/* Salary to Date */
					cells[i, j] = salary;
					cells[size, j] += cells[i, j];
					j++;

					/* Tax / SSS */
					value = deductions.get_deduction_with_category (employee, Deductions.Category.TAX);
					deduction += value;
					cells[i, j] = value;
					cells[size, j] += cells[i, j];
					j++;

					/* Loan */
					value = deductions.get_deduction_with_category (employee, Deductions.Category.LOAN);
					deduction += value;
					cells[i, j] = value;
					cells[size, j] += cells[i, j];
					j++;

					/* PAG-IBIG / PhilHealth */
					value = deductions.get_deduction_with_category (employee, Deductions.Category.PAG_IBIG);
					deduction += value;
					cells[i, j] = value;
					cells[size, j] += cells[i, j];
					j++;

					/* SSS Loan */
					value = deductions.get_deduction_with_category (employee, Deductions.Category.SSS_LOAN);
					deduction += value;
					cells[i, j] = value;
					cells[size, j] += cells[i, j];
					j++;

					/* Vale */
					value = deductions.get_deduction_with_category (employee, Deductions.Category.VALE);
					deduction += value;
					cells[i, j] = value;
					cells[size, j] += cells[i, j];
					j++;

					/* Moesala Loan */
					value = deductions.get_deduction_with_category (employee, Deductions.Category.MOESALA_LOAN);
					deduction += value;
					cells[i, j] = value;
					cells[size, j] += cells[i, j];
					j++;

					/* Moesala Savings */
					value = deductions.get_deduction_with_category (employee, Deductions.Category.MOESALA_SAVINGS);
					deduction += value;
					cells[i, j] = value;
					cells[size, j] += cells[i, j];
					j++;

					/* Total Deductions */
					cells[i, j] = deduction;
					cells[size, j] += cells[i, j];
					j++;

					/* Net Amount */
					cells[i, j] = salary - deduction;
					cells[size, j] += cells[i, j];
				}
			}

			public override void begin_print (PrintContext context) {
				update_font_height (context);

				/* Get height of header and footer */
				table_top = (title_font_height * 2) + company_name_font_height + (padding * 6);
				table_header_height = ((header_font_height + (padding * 2)) * 2);
				header_height = table_top + table_header_height;
				footer_height = (text_font_height + (padding * 2)) * 10;


				payslip_height = context.get_height ();
				payslip_width = context.get_width ();

				/* Landscape for payroll */
				payroll_height = payslip_width;
				payroll_width = payslip_height;


				if (continuous) {
					payslip_per_page = employees.size;
					payslip_height = payslip_per_page * get_payslip_height ();
				} else {
					payslip_per_page = (int) Math.floor (payslip_height / get_payslip_height ());
				}


				lines_first_page = (int) Math.floor ((payroll_height - header_height) / (text_font_height + (padding * 2)));
				lines_first_page -= lines_first_page % 2;

				lines_per_page = (int) Math.floor (payroll_height / (text_font_height + (padding * 2)));
				lines_per_page -= lines_per_page % 2;

				payslip_per_page = (int) Math.floor (payslip_height / get_payslip_height ());

				num_lines = employees.size * 2;
				if (num_lines < lines_first_page) {
					lines_first_page = num_lines;
				}

				/* Note: +12 for footer */
				pages_payroll = (int) Math.ceil ((double) (num_lines + (lines_first_page != num_lines? lines_per_page - lines_first_page : 0) + 12) / lines_per_page);
				pages_payslip = (int) Math.ceil ((double) employees.size / payslip_per_page);
				set_n_pages (pages_payroll + pages_payslip);


				process ();
			}

			public override void draw_page (PrintContext context, int page_nr) {
				var cr = context.get_cairo_context ();

				var layout = context.create_pango_layout ();
				layout.get_context ().set_font_map (CairoFontMap.new_for_font_type (FontType.FT));
				layout.set_wrap (Pango.WrapMode.WORD_CHAR);
				layout.set_ellipsize (EllipsizeMode.END);

				double column_width = payroll_width / 15;

				if (page_nr < pages_payroll) {
					int id = (((page_nr-1) * lines_per_page) + lines_first_page)/2;
					int page_num_lines = lines_per_page;
					if (page_nr == 0) {
						id = 0;
						page_num_lines = lines_first_page;
					} else if ((id + (page_num_lines/2)) > (num_lines/2)) {
						page_num_lines = num_lines - (id*2);
					}

					/* Add summary to last page of payroll */
					if (page_nr == pages_payroll - 1) {
						page_num_lines++;
					}

					double table_content_height = (page_num_lines * (text_font_height + (padding * 2)));

					double table_x = 0, table_y = 0;


					if (page_nr == 0) {
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
						layout.set_markup (_("For the period of %s").printf (period_to_string (this.start, this.end).up ()), -1);
						cairo_show_layout (cr, layout);


						/* Table Headers */
						layout.set_font_description (header_font);
						layout.set_width (units_from_double ((column_width * 2) - (padding * 2)));
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

						cr.move_to ((column_width * 5) + padding, table_top + padding);
						layout.set_markup (_("Salary Deduction"), -1);
						cairo_show_layout (cr, layout);

						layout.set_width (units_from_double (column_width - (padding * 2)));

						cr.rel_move_to (0, (header_font_height + (padding * 2)));
						if (this.start.get_day () == 1) {
							layout.set_markup (_("TAX"), -1);
						} else {
							layout.set_markup (_("SSS"), -1);
						}
						cairo_show_layout (cr, layout);

						cr.rel_move_to (column_width, 0);
						layout.set_markup (_("LOAN"), -1);
						cairo_show_layout (cr, layout);

						cr.rel_move_to (column_width, 0);
						if (this.start.get_day () == 1) {
							layout.set_markup (_("PAG-IBIG"), -1);
						} else {
							layout.set_markup (_("PH"), -1);
						}
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
						cr.rectangle (table_border / 2,
						              table_top + (table_border / 2),
						              payroll_width - table_border,
						              table_content_height + table_header_height - table_border);
						/* Vertical */
						for (int i = 0; i < 13; i++) {
							cr.move_to (column_width * (2+i), table_top + ((i >= 4 && i <= 7)? (header_font_height + (padding * 2)) : 0));
							cr.rel_line_to (0, ((i >= 4 && i <= 7)? 1 : 2) * (header_font_height + (padding * 2)));
						}
						/* Horizontal */
						cr.move_to (column_width * 5, table_top + (header_font_height + (padding * 2)));
						cr.rel_line_to (column_width * 5, 0);
						cr.move_to (0, table_top + table_header_height);
						cr.rel_line_to (payroll_width, 0);

						cr.set_line_width (table_border);
						cr.stroke ();
					} else {
						table_x = 0;
						table_y = 0;

						/* Draw table lines */
						cr.rectangle (table_border / 2, table_border / 2,
						              payroll_width - table_border,
						              table_content_height - table_border);

						cr.set_line_width (table_border);
						cr.stroke ();
					}


					/* Print table lines */
					/* Horizontal */
					for (int i = 0; i < page_num_lines - 1 && (i+id) < num_lines; i++) {
						cr.move_to (0, table_y + ((text_font_height + (padding * 2)) * (i+1)));
						cr.rel_line_to (payroll_width, 0);
					}
					/* Vertical */
					for (int i = 0; i < 13; i++) {
						cr.move_to (column_width * (2+i), table_y);
						cr.rel_line_to (0, table_content_height);
					}
					cr.set_line_width (cell_border);
					cr.stroke ();


					/* Skip no. of days paid */
					for (int i = 0, j = 1; i * 2 < page_num_lines && (i+id) * 2 < num_lines; i++, j = 1) {
						var employee = (employees as ArrayList<Employee>).get (i + id);

						layout.set_width (units_from_double (index_column_width - (padding * 2)));

						layout.set_font_description (number_font);
						layout.set_alignment (Pango.Alignment.RIGHT);

						/* Index */
						cr.move_to (table_x + padding, table_y + padding + ((text_font_height + (padding * 2)) * 2 * i));
						layout.set_markup ("%d.".printf (i + id + 1), -1);
						cairo_show_layout (cr, layout);

						layout.set_width (units_from_double ((column_width * 2) - (padding * 2) - index_column_width));

						layout.set_font_description (text_font);
						layout.set_alignment (Pango.Alignment.LEFT);

						/* Name */
						cr.rel_move_to (index_column_width, 0);
						layout.set_markup (employee.get_name ().up (), -1);
						cairo_show_layout (cr, layout);

						layout.set_width (units_from_double (column_width - (padding * 2)));

						layout.set_font_description (number_font);
						layout.set_alignment (Pango.Alignment.RIGHT);

						/* Rates */
						cr.rel_move_to (column_width * 2 - padding - index_column_width, 0);
						layout.set_markup ("%.2lf".printf (cells[i + id, j]), -1);
						cairo_show_layout (cr, layout);
						j++;

						/* Days w/o Pay */
						cr.rel_move_to (column_width, 0);
						layout.set_markup ("%.1lf".printf (cells[i + id, j]), -1);
						cairo_show_layout (cr, layout);
						j++;

						/* Salary to Date */
						cr.rel_move_to (column_width, 0);
						layout.set_markup ("%.2lf".printf (cells[i + id, j]), -1);
						cairo_show_layout (cr, layout);
						j++;

						/* Tax / SSS */
						cr.rel_move_to (column_width, 0);
						layout.set_markup ("%.2lf".printf (cells[i + id, j]), -1);
						cairo_show_layout (cr, layout);
						j++;

						/* Loan */
						cr.rel_move_to (column_width, 0);
						layout.set_markup ("%.2lf".printf (cells[i + id, j]), -1);
						cairo_show_layout (cr, layout);
						j++;

						/* PAG-IBIG / PhilHealth */
						cr.rel_move_to (column_width, 0);
						layout.set_markup ("%.2lf".printf (cells[i + id, j]), -1);
						cairo_show_layout (cr, layout);
						j++;

						/* SSS Loan */
						cr.rel_move_to (column_width, 0);
						layout.set_markup ("%.2lf".printf (cells[i + id, j]), -1);
						cairo_show_layout (cr, layout);
						j++;

						/* Vale */
						cr.rel_move_to (column_width, 0);
						layout.set_markup ("%.2lf".printf (cells[i + id, j]), -1);
						cairo_show_layout (cr, layout);
						j++;

						/* Moesala Loan */
						cr.rel_move_to (column_width, 0);
						layout.set_markup ("%.2lf".printf (cells[i + id, j]), -1);
						cairo_show_layout (cr, layout);
						j++;

						/* Moesala Savings */
						cr.rel_move_to (column_width, 0);
						layout.set_markup ("%.2lf".printf (cells[i + id, j]), -1);
						cairo_show_layout (cr, layout);
						j++;

						/* Total Deductions */
						cr.rel_move_to (column_width, 0);
						layout.set_markup ("%.2lf".printf (cells[i + id, j]), -1);
						cairo_show_layout (cr, layout);
						j++;

						/* Net Amount */
						layout.set_font_description (emp_number_font);

						cr.rel_move_to (column_width, 0);
						layout.set_markup ("%.2lf".printf (cells[i + id, j]), -1);
						cairo_show_layout (cr, layout);

						/* TIN No. */
						layout.set_width (units_from_double ((column_width * 2) - (padding * 2)));

						layout.set_font_description (number_font);
						layout.set_alignment (Pango.Alignment.CENTER);

						cr.move_to (table_x + padding, table_y + padding + ((text_font_height + (padding * 2)) * ((2 * i) + 1)));
						layout.set_markup (employee.tin, -1);
						cairo_show_layout (cr, layout);
					}

					if (page_nr == pages_payroll - 1) {
						int size = employees.size;
						/* Skip no. of days paid */
						int j = 1;

						layout.set_width (units_from_double ((column_width * 2) - (padding * 2)));

						layout.set_font_description (header_font);
						layout.set_alignment (Pango.Alignment.RIGHT);

						/* Name */
						cr.rel_move_to (0, (text_font_height + (padding * 2)));
						layout.set_markup (_("TOTAL"), -1);
						cairo_show_layout (cr, layout);

						layout.set_width (units_from_double (column_width - (padding * 2)));

						layout.set_font_description (emp_number_font);

						/* Rates */
						cr.rel_move_to (column_width * 2 - padding, 0);
						layout.set_markup ("%.2lf".printf (cells[size, j]), -1);
						cairo_show_layout (cr, layout);
						j++;

						/* Days w/o Pay */
						cr.rel_move_to (column_width, 0);
						layout.set_markup ("%.1lf".printf (cells[size, j]), -1);
						cairo_show_layout (cr, layout);
						j++;

						/* Salary to Date */
						cr.rel_move_to (column_width, 0);
						layout.set_markup ("%.2lf".printf (cells[size, j]), -1);
						cairo_show_layout (cr, layout);
						j++;

						/* Tax / SSS */
						cr.rel_move_to (column_width, 0);
						layout.set_markup ("%.2lf".printf (cells[size, j]), -1);
						cairo_show_layout (cr, layout);
						j++;

						/* Loan */
						cr.rel_move_to (column_width, 0);
						layout.set_markup ("%.2lf".printf (cells[size, j]), -1);
						cairo_show_layout (cr, layout);
						j++;

						/* PAG-IBIG / PhilHealth */
						cr.rel_move_to (column_width, 0);
						layout.set_markup ("%.2lf".printf (cells[size, j]), -1);
						cairo_show_layout (cr, layout);
						j++;

						/* SSS Loan */
						cr.rel_move_to (column_width, 0);
						layout.set_markup ("%.2lf".printf (cells[size, j]), -1);
						cairo_show_layout (cr, layout);
						j++;

						/* Vale */
						cr.rel_move_to (column_width, 0);
						layout.set_markup ("%.2lf".printf (cells[size, j]), -1);
						cairo_show_layout (cr, layout);
						j++;

						/* Moesala Loan */
						cr.rel_move_to (column_width, 0);
						layout.set_markup ("%.2lf".printf (cells[size, j]), -1);
						cairo_show_layout (cr, layout);
						j++;

						/* Moesala Savings */
						cr.rel_move_to (column_width, 0);
						layout.set_markup ("%.2lf".printf (cells[size, j]), -1);
						cairo_show_layout (cr, layout);
						j++;

						/* Total Deductions */
						cr.rel_move_to (column_width, 0);
						layout.set_markup ("%.2lf".printf (cells[size, j]), -1);
						cairo_show_layout (cr, layout);
						j++;

						/* Net Amount */
						cr.rel_move_to (column_width, (text_font_height + (padding * 2)) * 2);
						layout.set_markup ("%.2lf".printf (cells[size, j]), -1);
						cairo_show_layout (cr, layout);

						double y;
						cr.get_current_point (null, out y);

						layout.set_width (units_from_double (payroll_width / 2));

						layout.set_font_description (header_font);
						layout.set_alignment (Pango.Alignment.LEFT);

						cr.move_to (payroll_width / 2, y);
						layout.set_markup (_("TOTAL PAYROLL:"), -1);
						cairo_show_layout (cr, layout);

						cr.move_to (column_width, y + (text_font_height + (padding * 2)) * 3);
						layout.set_markup (_("Prepared by:"), -1);
						cairo_show_layout (cr, layout);
						cr.rel_move_to (0, (text_font_height + (padding * 2)) * 3);
						layout.set_markup (_("<u>%s</u>").printf (preparer), -1);
						cairo_show_layout (cr, layout);

						int layout_width;
						cr.move_to (column_width + (payroll_width / 2), y + (text_font_height + (padding * 2)) * 3);
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
				} else {
					int id = (page_nr - pages_payroll) * payslip_per_page;

					double y = 0;
					var size = employees.size;
					for (int i = 0; i < payslip_per_page && i + id < size; i++) {
						draw_payslip (context, y, (employees as ArrayList<Employee>).get (i + id), cells[i + id, 0], cells[i + id, 3], deductions);
						y += get_payslip_height ();
					}
				}
			}

		}

	}

}
