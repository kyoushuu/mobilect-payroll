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
using Gee;


namespace Mobilect {

	namespace Payroll {

		public class CPanelReport : CPanelTab {

			public const string ACTION = "cpanel-report";
			public const string ACTION_PAGE_SETUP = "cpanel-report-page-setup";
			public const string ACTION_PRINT = "cpanel-report-print";
			public const string ACTION_PRINT_PREVIEW = "cpanel-report-print-preview";
			public const string ACTION_SAVE = "cpanel-report-save";

			public Grid grid { get; private set; }

			public RadioButton regular_radio { get; private set; }
			public RadioButton overtime_radio { get; private set; }
			public DateSpinButton start_spin { get; private set; }
			public DateSpinButton end_spin { get; private set; }

			private PageSetup page_setup;
			private PrintSettings print_settings;
			private GLib.Settings report_settings;


			/* Philippines Legal / FanFold German Legal / US Foolscap */
			public const string PAPER_NAME_FANFOLD_GERMAN_LEGAL = "na_foolscap";


			public CPanelReport (CPanel cpanel) {
				base (cpanel, ACTION, "/com/mobilectpower/Payroll/mobilect-payroll-cpanel-report-ui.xml");

				this.border_width = 6;

				/* Load page setup */
				if (FileUtils.test (this.cpanel.window.app.settings.page_setup, FileTest.IS_REGULAR)) {
					try {
						page_setup = new PageSetup.from_file (this.cpanel.window.app.settings.page_setup);
					} catch (Error e) {
						this.cpanel.window.show_error_dialog (_("Failed to load page setup"),
						                                      e.message);
					}
				} else {
					page_setup = new PageSetup ();
					page_setup.set_paper_size (new PaperSize (PAPER_NAME_FANFOLD_GERMAN_LEGAL));
				}

				/* Load print settings */
				if (FileUtils.test (this.cpanel.window.app.settings.print_settings, FileTest.IS_REGULAR)) {
					try {
						print_settings = new PrintSettings.from_file (this.cpanel.window.app.settings.print_settings);
					} catch (Error e) {
						this.cpanel.window.show_error_dialog (_("Failed to load print settings"),
						                                      e.message);
					}
				} else {
					print_settings = new PrintSettings ();
					print_settings.set_paper_size (new PaperSize (PAPER_NAME_FANFOLD_GERMAN_LEGAL));
				}

				report_settings = this.cpanel.window.app.settings.report;


				push_composite_child ();


				grid = new Grid ();
				grid.orientation = Orientation.VERTICAL;
				grid.row_spacing = 3;
				grid.column_spacing = 6;
				this.add (grid);
				grid.show ();

				var type_label = new Label (_("Type:"));
				type_label.xalign = 0.0f;
				grid.add (type_label);
				type_label.show ();

				regular_radio = new RadioButton.with_mnemonic (null, _("_Regular"));
				grid.attach_next_to (regular_radio,
				                     type_label,
				                     PositionType.RIGHT,
				                     1, 1);
				regular_radio.show ();

				overtime_radio = new RadioButton.with_mnemonic_from_widget (regular_radio, _("_Overtime"));
				grid.attach_next_to (overtime_radio,
				                     regular_radio,
				                     PositionType.BOTTOM,
				                     1, 1);
				overtime_radio.show ();

				var period_label = new Label.with_mnemonic (_("_Period:"));
				period_label.xalign = 0.0f;
				grid.add (period_label);
				period_label.show ();

				start_spin = new DateSpinButton ();
				grid.attach_next_to (start_spin,
				                     period_label,
				                     PositionType.RIGHT,
				                     1, 1);
				period_label.mnemonic_widget = start_spin;
				start_spin.show ();

				end_spin = new DateSpinButton ();
				grid.attach_next_to (end_spin,
				                     start_spin,
				                     PositionType.BOTTOM,
				                     1, 1);
				end_spin.show ();


				pop_composite_child ();


				/* Set period */
				var date = new DateTime.now_local ().add_days (-15);
				var period = (int) Math.round ((date.get_day_of_month () - 1) / 30.0);

				DateDay last_day;
				if (period == 0) {
					last_day = 15;
				} else {
					last_day = 31;
					while (!Date.valid_dmy (last_day,
					                        (DateMonth) date.get_month (),
					                        (DateYear) date.get_year ())) {
						last_day--;
					}
				}

				start_spin.set_dmy ((15 * period) + 1,
				                    date.get_month (),
				                    date.get_year ());
				end_spin.set_dmy (last_day,
				                  date.get_month (),
				                  date.get_year ());


				Gtk.ActionEntry[] actions = {
					Gtk.ActionEntry () {
						name = ACTION_PAGE_SETUP,
						stock_id = Stock.PAGE_SETUP,
						tooltip = _("Customize the page size, orientation and margins"),
						callback = (a) => {
							var new_page_setup = print_run_page_setup_dialog (this.cpanel.window, page_setup, print_settings);

							try {
								page_setup = new_page_setup;
								page_setup.to_file (this.cpanel.window.app.settings.page_setup);

								print_settings.to_file (this.cpanel.window.app.settings.print_settings);
							} catch (Error e) {
								this.cpanel.window.show_error_dialog (_("Failed to save page setup and print settings"),
								                                      e.message);
							}
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_PRINT,
						stock_id = Stock.PRINT,
						accelerator = _("<Control>P"),
						tooltip = _("Print payroll and payslips"),
						callback = (a) => {
							try {
								var pr = create_report ();
								pr.print_dialog (this.cpanel.window);

								print_settings = pr.print_settings;
								print_settings.to_file (this.cpanel.window.app.settings.print_settings);
							} catch (Error e) {
								this.cpanel.window.show_error_dialog (_("Failed to print report"),
								                                      e.message);
							}
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_PRINT_PREVIEW,
						stock_id = Stock.PRINT_PREVIEW,
						accelerator = _("<Shift><Control>P"),
						tooltip = _("Print preview of payroll and payslips"),
						callback = (a) => {
							try {
								var pr = create_report ();
								pr.preview_dialog (this.cpanel.window);

								print_settings = pr.print_settings;
								print_settings.to_file (this.cpanel.window.app.settings.print_settings);
							} catch (Error e) {
								this.cpanel.window.show_error_dialog (_("Failed to preview report"),
								                                      e.message);
							}
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_SAVE,
						stock_id = Stock.SAVE,
						accelerator = _("<Control>S"),
						tooltip = _("Export payroll and payslips to a PDF file"),
						callback = (a) => {
							try {
								var pr = create_report ();

								var dialog = new FileChooserDialog (_("Export"),
								                                    this.cpanel.window,
								                                    FileChooserAction.SAVE,
								                                    Stock.CANCEL, ResponseType.REJECT,
								                                    Stock.SAVE, ResponseType.ACCEPT);
								dialog.do_overwrite_confirmation = true;

								string current_name;
								if (regular_radio.active) {
									current_name = _("payroll-regular_%s-%s.pdf");
								} else {
									current_name = _("payroll-overtime_%s-%s.pdf");
								}
								dialog.set_current_name (current_name.printf (pr.format_date (start_spin.date, "%Y%m%d"),
								                                              pr.format_date (end_spin.date, "%Y%m%d")));

								if (dialog.run () == ResponseType.ACCEPT) {
									dialog.hide ();

									pr.export_filename = dialog.get_filename ();
									pr.export (this.cpanel.window);

									print_settings = pr.print_settings;
									print_settings.to_file (this.cpanel.window.app.settings.print_settings);
								}

								dialog.destroy ();
							} catch (Error e) {
								this.cpanel.window.show_error_dialog (_("Failed to export report"),
								                                      e.message);
							}
						}
					}
				};

				this.action_group.add_actions (actions, this);
				this.action_group.get_action (ACTION_SAVE).is_important = true;
			}

			private Report create_report () throws ReportError, RegularReportError {
				Report pr;
				var start_date = start_spin.date;
				var end_date = end_spin.date;

				if (regular_radio.active) {
					pr = new RegularReport (start_date, end_date);
					pr.title = _("SEMI-MONTHLY PAYROLL");
				} else {
					var period_8am_5pm_regular = new PayPeriod (_("8am-5pm"),
					                                            false,
					                                            1.0,
					                                            new TimePeriod[] {
																												TimePeriod (Time (8,0), Time (12,0)),
																												TimePeriod (Time (13,0), Time (17,0))
																											});
					var period_8am_5pm_sunday = new PayPeriod (_("8am-5pm"),
					                                           false,
					                                           1.3,
					                                           new TimePeriod[] {
																											 TimePeriod (Time (8,0), Time (12,0)),
																											 TimePeriod (Time (13,0), Time (17,0))
																										 });
					var period_5pm_10pm = new PayPeriod (_("5pm-10pm"),
					                                     true,
					                                     1.25,
					                                     new TimePeriod[] {
																								 TimePeriod (Time (17,0), Time (22,0))
																							 });
					var period_10pm_6am = new PayPeriod (_("10pm-6am"),
					                                     true,
					                                     1.5,
					                                     new TimePeriod[] {
																								 TimePeriod (Time (22,0), Time (0,0)),
																								 TimePeriod (Time (0,0), Time (6,0))
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

					var pay_groups = new PayGroup[] {
						new PayGroup (_("Non-Holiday"),
						              false,
						              MonthInfo.HolidayType.NON_HOLIDAY,
						              1.0,
						              new PayPeriod[] {
														period_5pm_10pm,
														period_10pm_6am
													},
						              null),
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


					pr = new OvertimeReport (start_date, end_date);
					pr.title = _("MONTHLY OVERTIME PAYROLL");

					int affected;
					var affected_pay_groups = new PayGroup[0];
					foreach (var pay_group in pay_groups) {
						affected = 0;
						for (int i = 0; i < pay_group.periods.length; i++) {
							affected += pay_group.create_filter (i, start_date, end_date)
								.get_affected_dates (this.cpanel.window.app.database).length;
						}
						if (affected > 0) {
							affected_pay_groups += pay_group;
						}
					}

					(pr as OvertimeReport).pay_groups = affected_pay_groups;
				}

				pr.employees = this.cpanel.window.app.database.employee_list;
				pr.show_progress = true;

				pr.default_page_setup = page_setup;
				pr.print_settings = print_settings;

				pr.title_font = FontDescription.from_string (report_settings.get_string ("title-font"));
				pr.company_name_font = FontDescription.from_string (report_settings.get_string ("company-name-font"));
				pr.header_font = FontDescription.from_string (report_settings.get_string ("header-font"));
				pr.text_font = FontDescription.from_string (report_settings.get_string ("text-font"));
				pr.number_font = FontDescription.from_string (report_settings.get_string ("number-font"));
				pr.emp_number_font = FontDescription.from_string (report_settings.get_string ("emphasized-number-font"));

				pr.padding = report_settings.get_double ("padding");

				return pr;
			}

		}

	}

}
