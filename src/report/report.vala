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

		public errordomain ReportError {
			PERIOD_START_AFTER_END
		}


		public abstract class Report : PrintOperation {

			public string title { get; set; }

			public EmployeeList employees { get; set; }

			public Date start { get; private set; }
			public Date end { get; private set; }

			public bool continuous;

			public double padding = 1.0;
			public double table_border = 1.5;
			public double cell_border = 1.0;

			public string preparer;
			public string approver;
			public string approver_position;

			public FontDescription title_font = FontDescription.from_string ("Sans Bold 14");
			public FontDescription company_name_font = FontDescription.from_string ("Sans Bold 12");
			public FontDescription header_font = FontDescription.from_string ("Sans Bold 9");
			public FontDescription text_font = FontDescription.from_string ("Sans 9");
			public FontDescription number_font = FontDescription.from_string ("Monospace 9");
			public FontDescription emp_number_font = FontDescription.from_string ("Monospace Bold 9");

			protected int lines_per_page;
			protected int num_lines;

			protected double payroll_height;
			protected double payroll_width;
			protected double payslip_height;
			protected double payslip_width;

			protected double table_top;
			protected double header_height;
			protected double footer_height;
			protected double table_header_line_height;
			protected double table_content_line_height;
			protected double table_header_height;

			protected double title_font_height;
			protected double company_name_font_height;
			protected double header_font_height;
			protected double header_font_width;
			protected double header_font_digit_width;
			protected double text_font_height;
			protected double text_font_width;
			protected double number_font_height;
			protected double number_font_width;
			protected double number_emp_font_height;
			protected double number_emp_font_width;

			protected double hour_column_width = 25;
			protected double total_hour_column_width = 20;
			protected double day_column_width = 25;
			protected double rate_column_width = 60;
			protected double hourly_rate_column_width = 60;
			protected double number_column_width = 60;
			protected double subtotal_column_width = 60;
			protected double total_column_width = 60;
			protected double index_column_width = 20;
			protected double name_column_width = 150;
			protected double signature_column_width = 70;

			protected int pages_payroll;
			protected int pages_payslip;
			protected int payslip_per_page;

			public signal void step ();


			public Report (Date start, Date end) throws ReportError {
				this.start = start;
				this.end = end;

				if (start.compare (end) > 0) {
					throw new ReportError.PERIOD_START_AFTER_END (_("Start of period is after end of period."));
				}
			}

			public abstract void process ();

			public override void request_page_setup (PrintContext context, int page_nr, PageSetup setup) {
				if (page_nr < pages_payroll && this is RegularReport) {
					/* Print payroll in landscape */
					setup.set_orientation (PageOrientation.LANDSCAPE);

					/* GTK+ rotates margins, treat margins as hard margins */
					var bottom_margin = setup.get_bottom_margin (Unit.POINTS);
					var top_margin = setup.get_top_margin (Unit.POINTS);
					var left_margin = setup.get_left_margin (Unit.POINTS);
					var right_margin = setup.get_right_margin (Unit.POINTS);

					setup.set_top_margin (left_margin, Unit.POINTS);
					setup.set_bottom_margin (right_margin, Unit.POINTS);
					setup.set_left_margin (top_margin, Unit.POINTS);
					setup.set_right_margin (bottom_margin, Unit.POINTS);
				} else {
					if (continuous) {
						var bottom_margin = setup.get_bottom_margin (Unit.POINTS);
						var top_margin = setup.get_top_margin (Unit.POINTS);

						var paper_size = new PaperSize.custom ("continuous-payslip-page-size",
						                                       "Continuous Payslip Page Size",
						                                       setup.get_paper_width (Unit.POINTS),
						                                       top_margin + payslip_height + bottom_margin,
						                                       Unit.POINTS);
						setup.set_paper_size (paper_size);
					}
				}
			}

			public override void begin_print (PrintContext context) {
				process ();

				update_font_metrics (context);

				/* Get height of header and footer */
				table_top = (title_font_height * 2) + company_name_font_height + (padding * 6);
				table_header_line_height = header_font_height + (padding * 2);
				table_content_line_height = text_font_height + (padding * 2);
				table_header_height = table_header_line_height * 2;
				header_height = table_top + table_header_height;
				footer_height = table_content_line_height * 10;
			}

			public void print_dialog (Gtk.Window window) throws Error {
				run (PrintOperationAction.PRINT_DIALOG, window);
			}

			public void preview_dialog (Gtk.Window window) throws Error {
				run (PrintOperationAction.PREVIEW, window);
			}

			public void export (Gtk.Window window) throws Error {
				run (PrintOperationAction.EXPORT, window);
			}

			public static string format_date (Date date, string format) {
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

			internal string dates_to_string (LinkedList<Date?> dates) {
				bool is_range = false;
				Date start_date = Date (), last_date = Date (), last_added_date = Date ();
				string result = null;

				dates.sort ((a, b) => { return a.compare (b); });

				foreach (var date in dates) {
					if (last_date.valid () && date.compare (last_date) == 0) {
						continue;
					}

					if (last_date.valid () &&
					    date.get_julian () - last_date.get_julian () == 1) {
						if (!is_range) {
							is_range = true;
							start_date = date;
						}
					} else {
						if (is_range) {
							is_range = false;

							if (start_date.get_month () != last_date.get_month ()) {
								result += format_date (last_date, _(" - %b %d"));
							} else {
								result += format_date (last_date, _("-%d"));
							}

							result += ", ";
						} else {
							if (result != null) {
								result += ", ";
							} else {
								result = "";
							}
						}

						if (!last_added_date.valid () ||
						    last_added_date.get_month () != date.get_month ()) {
							result += format_date (date, _("%b %d"));
						} else {
							result += format_date (date, _("%d"));
						}

						last_added_date = date;
					}

					last_date = date;
				}

				if (is_range) {
					if (start_date.get_month () != last_date.get_month ()) {
						result += format_date (last_date, _(" - %b %d"));
					} else {
						result += format_date (last_date, _("-%d"));
					}
				}

				return result;
			}

			private inline double greater (double a, double b) { return a > b? a : b; }

			internal void update_font_metrics (Gtk.PrintContext context) {
				/* Get font height */
				FontMetrics font_metrics;
				var pcontext = context.create_pango_context ();

				font_metrics = pcontext.load_font (title_font).get_metrics (pcontext.get_language ());
				title_font_height = units_to_double (font_metrics.get_ascent () + font_metrics.get_descent ());

				font_metrics = pcontext.load_font (company_name_font).get_metrics (pcontext.get_language ());
				company_name_font_height = units_to_double (font_metrics.get_ascent () + font_metrics.get_descent ());

				font_metrics = pcontext.load_font (header_font).get_metrics (pcontext.get_language ());
				header_font_height = units_to_double (font_metrics.get_ascent () + font_metrics.get_descent ());
				header_font_width = units_to_double (font_metrics.get_approximate_char_width ());
				header_font_digit_width = units_to_double (font_metrics.get_approximate_digit_width ());

				font_metrics = pcontext.load_font (text_font).get_metrics (pcontext.get_language ());
				text_font_height = units_to_double (font_metrics.get_ascent () + font_metrics.get_descent ());
				text_font_width = units_to_double (font_metrics.get_approximate_char_width ());

				font_metrics = pcontext.load_font (number_font).get_metrics (pcontext.get_language ());
				number_font_height = units_to_double (font_metrics.get_ascent () + font_metrics.get_descent ());
				number_font_width = units_to_double (font_metrics.get_approximate_digit_width ());

				font_metrics = pcontext.load_font (emp_number_font).get_metrics (pcontext.get_language ());
				number_emp_font_height = units_to_double (font_metrics.get_ascent () + font_metrics.get_descent ());
				number_emp_font_width = units_to_double (font_metrics.get_approximate_digit_width ());

				hour_column_width = greater (number_font_width * 3, header_font_width * 4) + (padding * 2); /* 3 or "Hrs." */
				total_hour_column_width = (number_font_width * 3) + (padding * 2); /* 3 */
				day_column_width = greater (number_font_width * 4, header_font_width * 8) + (padding * 2); /* 2.1 or "w/o Pay" with extra char */
				rate_column_width = (number_emp_font_width * 9) + (padding * 2); /* '5.2 */
				hourly_rate_column_width = (number_font_width * 6) + (padding * 2); /* 3.2 */
				number_column_width = (number_emp_font_width * 10) + (padding * 2); /* '6.2 */
				subtotal_column_width = greater (number_font_width * 9, (header_font_width * 6) + (header_font_digit_width * 4)) + (padding * 2); /* '5.2 or XX[a|p]m-XX[a|p]m with extra char */
				total_column_width = (number_emp_font_width * 10) + (padding * 2); /* '6.2 */
				index_column_width = (number_emp_font_width * 2) + (padding * 2); /* 2 */
				name_column_width = (text_font_width * 27) + (padding * 2);
				signature_column_width = (header_font_width * 12) + (padding * 2); /* "Signature" with extra chars */
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

			public void draw_payslip (PrintContext context, double top_y, Employee employee, double units, double earnings, Deductions? deductions = null) {
				double x = 0, y = top_y;
				double padding_payslip = 5;
				int layout_width;
				double total_y;

				double deduction = 0;
				double total_deductions = 0;

				var cr = context.get_cairo_context ();
				var width = context.get_width ();

				var layout = context.create_pango_layout ();
				layout.get_context ().set_font_map (CairoFontMap.new_for_font_type (FontType.FT));
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

				/* Draw table for earnings */
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
				layout.set_markup (_("GROSS EARNINGS: rate/day/month P %s").printf (format_money (employee.rate_per_day)), -1);
				cairo_show_layout (cr, layout);

				if (this is RegularReport) {
					layout.set_font_description (number_font);

					layout.set_alignment (Pango.Alignment.RIGHT);
					layout.set_width (units_from_double ((width/6) - (padding * 2)));
					cr.move_to (x + padding + (width/2), y + padding);
					layout.set_markup (format_money (Math.floor (earnings), false), -1);
					cairo_show_layout (cr, layout);

					layout.set_alignment (Pango.Alignment.LEFT);
					layout.set_width (units_from_double ((width/12) - (padding * 2)));
					cr.move_to (x + padding + (width*2/3), y + padding);
					layout.set_markup (_("%02d").printf ((int) Math.round ((earnings - Math.floor (earnings)) * 100)), -1);
					cairo_show_layout (cr, layout);
				}
				y += text_font_height + (padding * 2);

				cr.move_to (x, y);
				cr.rel_line_to (width*3/4, 0);
				cr.set_line_width (1);
				cr.stroke ();

				layout.set_font_description (text_font);
				layout.set_width (units_from_double ((width / 2) - (padding * 2)));
				layout.set_alignment (Pango.Alignment.LEFT);

				cr.move_to (x + padding, y + padding);
				layout.set_markup (_("OVERTIME: rate/hr P %.2lf (# of hrs %s)").printf (employee.rate_per_hour, (this is OvertimeReport)? "%.0lf".printf (units) : "   "), -1);
				cairo_show_layout (cr, layout);

				if (this is OvertimeReport) {
					layout.set_font_description (number_font);

					layout.set_alignment (Pango.Alignment.RIGHT);
					layout.set_width (units_from_double ((width/6) - (padding * 2)));
					cr.move_to (x + padding + (width/2), y + padding);
					layout.set_markup (format_money (Math.floor (earnings), false), -1);
					cairo_show_layout (cr, layout);

					layout.set_alignment (Pango.Alignment.LEFT);
					layout.set_width (units_from_double ((width/12) - (padding * 2)));
					cr.move_to (x + padding + (width*2/3), y + padding);
					layout.set_markup (_("%02d").printf ((int) Math.round ((earnings - Math.floor (earnings)) * 100)), -1);
					cairo_show_layout (cr, layout);
				}
				y += text_font_height + (padding * 2);

				cr.move_to (x, y);
				cr.rel_line_to (width*3/4, 0);
				cr.set_line_width (1);
				cr.stroke ();

				layout.set_font_description (text_font);
				layout.set_width (units_from_double ((width / 2) - (padding * 2)));
				layout.set_alignment (Pango.Alignment.LEFT);

				cr.move_to (x + padding, y + padding);
				layout.set_markup (_("OTHER COMPENSATION"), -1);
				cairo_show_layout (cr, layout);

				y += text_font_height + (padding * 2);
				y += text_font_height;

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

				/* Draw table for deductions */
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
				if (start.get_day () == 1) {
					layout.set_markup (_("WITHHOLDING TAX"), -1);
				} else {
					layout.set_markup (_("SSS PREMIUMS"), -1);
				}
				cairo_show_layout (cr, layout);

				if (deductions != null) {
					deduction = deductions.get_deduction_with_category (employee, Deductions.Category.TAX);
					total_deductions += deduction;

					layout.set_font_description (number_font);

					layout.set_alignment (Pango.Alignment.RIGHT);
					layout.set_width (units_from_double ((width/6) - (padding * 2)));
					cr.move_to (x + padding + (width/4), y + padding);
					layout.set_markup (format_money (Math.floor (deduction), false), -1);
					cairo_show_layout (cr, layout);

					layout.set_alignment (Pango.Alignment.LEFT);
					layout.set_width (units_from_double ((width/12) - (padding * 2)));
					cr.move_to (x + padding + (width*5/12), y + padding);
					layout.set_markup (_("%02d").printf ((int) Math.round ((deduction - Math.floor (deduction)) * 100)), -1);
					cairo_show_layout (cr, layout);
				}

				y += text_font_height + (padding * 2);

				cr.move_to (x, y);
				cr.rel_line_to (width/2, 0);
				cr.set_line_width (1);
				cr.stroke ();

				layout.set_font_description (text_font);
				layout.set_width (units_from_double ((width / 4) - (padding * 2)));
				layout.set_alignment (Pango.Alignment.LEFT);

				cr.move_to (x + padding, y + padding);
				layout.set_markup (_("SSS LOAN"), -1);
				cairo_show_layout (cr, layout);

				if (deductions != null) {
					deduction = deductions.get_deduction_with_category (employee, Deductions.Category.SSS_LOAN);
					total_deductions += deduction;

					layout.set_font_description (number_font);

					layout.set_alignment (Pango.Alignment.RIGHT);
					layout.set_width (units_from_double ((width/6) - (padding * 2)));
					cr.move_to (x + padding + (width/4), y + padding);
					layout.set_markup (format_money (Math.floor (deduction), false), -1);
					cairo_show_layout (cr, layout);

					layout.set_alignment (Pango.Alignment.LEFT);
					layout.set_width (units_from_double ((width/12) - (padding * 2)));
					cr.move_to (x + padding + (width*5/12), y + padding);
					layout.set_markup (_("%02d").printf ((int) Math.round ((deduction - Math.floor (deduction)) * 100)), -1);
					cairo_show_layout (cr, layout);
				}

				y += text_font_height + (padding * 2);

				cr.move_to (x, y);
				cr.rel_line_to (width/2, 0);
				cr.set_line_width (1);
				cr.stroke ();

				layout.set_font_description (text_font);
				layout.set_width (units_from_double ((width / 4) - (padding * 2)));
				layout.set_alignment (Pango.Alignment.LEFT);

				cr.move_to (x + padding, y + padding);
				if (start.get_day () == 1) {
					layout.set_markup (_("PAG-IBIG"), -1);
				} else {
					layout.set_markup (_("PHILHEALTH"), -1);
				}
				cairo_show_layout (cr, layout);

				if (deductions != null) {
					deduction = deductions.get_deduction_with_category (employee, Deductions.Category.PAG_IBIG);
					total_deductions += deduction;

					layout.set_font_description (number_font);

					layout.set_alignment (Pango.Alignment.RIGHT);
					layout.set_width (units_from_double ((width/6) - (padding * 2)));
					cr.move_to (x + padding + (width/4), y + padding);
					layout.set_markup (format_money (Math.floor (deduction), false), -1);
					cairo_show_layout (cr, layout);

					layout.set_alignment (Pango.Alignment.LEFT);
					layout.set_width (units_from_double ((width/12) - (padding * 2)));
					cr.move_to (x + padding + (width*5/12), y + padding);
					layout.set_markup (_("%02d").printf ((int) Math.round ((deduction - Math.floor (deduction)) * 100)), -1);
					cairo_show_layout (cr, layout);
				}

				y += text_font_height + (padding * 2);

				cr.move_to (x, y);
				cr.rel_line_to (width/2, 0);
				cr.set_line_width (1);
				cr.stroke ();

				layout.set_font_description (text_font);
				layout.set_width (units_from_double ((width / 4) - (padding * 2)));
				layout.set_alignment (Pango.Alignment.LEFT);

				cr.move_to (x + padding, y + padding);
				layout.set_markup (_("LOANS / VALE"), -1);
				cairo_show_layout (cr, layout);

				if (deductions != null) {
					deduction = deductions.get_deduction_with_category (employee, Deductions.Category.LOAN) +
						deductions.get_deduction_with_category (employee, Deductions.Category.VALE);
					total_deductions += deduction;

					layout.set_font_description (number_font);

					layout.set_alignment (Pango.Alignment.RIGHT);
					layout.set_width (units_from_double ((width/6) - (padding * 2)));
					cr.move_to (x + padding + (width/4), y + padding);
					layout.set_markup (format_money (Math.floor (deduction), false), -1);
					cairo_show_layout (cr, layout);

					layout.set_alignment (Pango.Alignment.LEFT);
					layout.set_width (units_from_double ((width/12) - (padding * 2)));
					cr.move_to (x + padding + (width*5/12), y + padding);
					layout.set_markup (_("%02d").printf ((int) Math.round ((deduction - Math.floor (deduction)) * 100)), -1);
					cairo_show_layout (cr, layout);
				}

				y += text_font_height + (padding * 2);

				cr.move_to (x, y);
				cr.rel_line_to (width/2, 0);
				cr.set_line_width (1);
				cr.stroke ();

				layout.set_font_description (text_font);
				layout.set_width (units_from_double ((width / 4) - (padding * 2)));
				layout.set_alignment (Pango.Alignment.LEFT);

				cr.move_to (x + padding, y + padding);
				layout.set_markup (_("OTHERS (MOESALA)"), -1);
				cairo_show_layout (cr, layout);

				if (deductions != null) {
					deduction = deductions.get_deduction_with_category (employee, Deductions.Category.MOESALA_LOAN) +
						deductions.get_deduction_with_category (employee, Deductions.Category.MOESALA_SAVINGS);
					total_deductions += deduction;

					layout.set_font_description (number_font);

					layout.set_alignment (Pango.Alignment.RIGHT);
					layout.set_width (units_from_double ((width/6) - (padding * 2)));
					cr.move_to (x + padding + (width/4), y + padding);
					layout.set_markup (format_money (Math.floor (deduction), false), -1);
					cairo_show_layout (cr, layout);

					layout.set_alignment (Pango.Alignment.LEFT);
					layout.set_width (units_from_double ((width/12) - (padding * 2)));
					cr.move_to (x + padding + (width*5/12), y + padding);
					layout.set_markup (_("%02d").printf ((int) Math.round ((deduction - Math.floor (deduction)) * 100)), -1);
					cairo_show_layout (cr, layout);
				}

				y += text_font_height + (padding * 2);

				cr.move_to (x, y);
				cr.rel_line_to (width/2, 0);
				cr.set_line_width (1);
				cr.stroke ();

				if (deductions != null) {
					layout.set_font_description (number_font);

					layout.set_alignment (Pango.Alignment.RIGHT);
					layout.set_width (units_from_double ((width/6) - (padding * 2)));
					cr.move_to (x + padding + (width/4), y + padding);
					layout.set_markup (format_money (Math.floor (total_deductions), false), -1);
					cairo_show_layout (cr, layout);

					layout.set_alignment (Pango.Alignment.LEFT);
					layout.set_width (units_from_double ((width/12) - (padding * 2)));
					cr.move_to (x + padding + (width*5/12), y + padding);
					layout.set_markup (_("%02d").printf ((int) Math.round ((total_deductions - Math.floor (total_deductions)) * 100)), -1);
					cairo_show_layout (cr, layout);
				}

				y += text_font_height + (padding * 2);

				layout.set_width (units_from_double ((width / 4) - (padding * 2)));

				cr.move_to (x + (width*4/6), total_y);
				layout.set_font_description (text_font);
				layout.set_alignment (Pango.Alignment.LEFT);
				layout.set_markup (_("TOTAL\nEARNINGS"), -1);
				cairo_show_layout (cr, layout);
				total_y += text_font_height;

				cr.move_to (x + (width*5/6), total_y);
				layout.set_font_description (emp_number_font);
				layout.set_alignment (Pango.Alignment.RIGHT);
				layout.set_width (units_from_double (width/6));
				layout.set_markup (format_money (earnings), -1);
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
				layout.set_font_description (text_font);
				layout.set_alignment (Pango.Alignment.LEFT);
				layout.set_markup (_("TOTAL\nDEDUCTIONS"), -1);
				cairo_show_layout (cr, layout);
				total_y += text_font_height;

				cr.move_to (x + (width*5/6), total_y);
				layout.set_font_description (emp_number_font);
				layout.set_alignment (Pango.Alignment.RIGHT);
				layout.set_width (units_from_double (width/6));
				layout.set_markup (format_money (total_deductions), -1);
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
				layout.set_font_description (text_font);
				layout.set_alignment (Pango.Alignment.LEFT);
				layout.set_markup (_("NET EARNINGS"), -1);
				cairo_show_layout (cr, layout);

				cr.move_to (x + (width*5/6), total_y);
				layout.set_font_description (emp_number_font);
				layout.set_alignment (Pango.Alignment.RIGHT);
				layout.set_width (units_from_double (width/6));
				layout.set_markup (format_money (earnings - total_deductions), -1);
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
				layout.set_font_description (text_font);
				layout.set_alignment (Pango.Alignment.LEFT);
				layout.set_width (-1);
				layout.set_markup (_("RECEIVED PAYMENT:"), -1);
				cairo_update_layout (cr, layout);
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
