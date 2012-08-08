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
			public TreeView deduc_view { get; private set; }

			private FontDescription title_font;
			private FontDescription company_name_font;
			private FontDescription header_font;
			private FontDescription text_font;
			private FontDescription number_font;
			private FontDescription emp_number_font;

			private PageSetup page_setup;
			private PrintSettings print_settings;
			private GLib.Settings report_settings;


			/* Philippines Legal / FanFold German Legal / US Foolscap */
			public const string PAPER_NAME_FANFOLD_GERMAN_LEGAL = "na_foolscap";


			public enum Columns {
				ID,
				NAME,
				TAX,
				LOAN,
				PAG_IBIG,
				SSS_LOAN,
				VALE,
				MOESALA_LOAN,
				MOESALA_SAVINGS,
				NUM
			}


			public CPanelReport (CPanel cpanel) {
				base (cpanel, ACTION, "/com/mobilectpower/Payroll/mobilect-payroll-cpanel-report-ui.xml");

				page_setup = new PageSetup ();
				page_setup.set_paper_size (new PaperSize (PAPER_NAME_FANFOLD_GERMAN_LEGAL));

				report_settings = this.cpanel.window.app.settings.report;
				title_font = FontDescription.from_string (report_settings.get_string ("title-font"));
				company_name_font = FontDescription.from_string (report_settings.get_string ("company-name-font"));
				header_font = FontDescription.from_string (report_settings.get_string ("header-font"));
				text_font = FontDescription.from_string (report_settings.get_string ("text-font"));
				number_font = FontDescription.from_string (report_settings.get_string ("number-font"));
				emp_number_font = FontDescription.from_string (report_settings.get_string ("emphasized-number-font"));
				report_settings.changed.connect ((s, k) => {
					if (!k.has_suffix ("-font")) {
						return;
					}

					var font = FontDescription.from_string (report_settings.get_string (k));

					switch (k) {
						case "title-font":
							title_font = font;
							break;
						case "company-name-font":
							company_name_font = font;
							break;
						case "header-font":
							header_font = font;
							break;
						case "text-font":
							text_font = font;
							break;
						case "number-font":
							number_font = font;
							break;
						case "emphasized-number-font":
							emp_number_font = font;
							break;
					}
				});

				/* Load page setup */
				if (FileUtils.test (this.cpanel.window.app.settings.page_setup, FileTest.IS_REGULAR)) {
					try {
						page_setup = new PageSetup.from_file (this.cpanel.window.app.settings.page_setup);
					} catch (Error e) {
						this.cpanel.window.show_error_dialog (_("Failed to load page setup"),
						                                      e.message);
					}
				}

				/* Load print settings */
				if (FileUtils.test (this.cpanel.window.app.settings.print_settings, FileTest.IS_REGULAR)) {
					try {
						print_settings = new PrintSettings.from_file (this.cpanel.window.app.settings.print_settings);
					} catch (Error e) {
						this.cpanel.window.show_error_dialog (_("Failed to load print settings"),
						                                      e.message);
					}
				}


				push_composite_child ();


				grid = new Grid ();
				grid.orientation = Orientation.VERTICAL;
				grid.row_spacing = 3;
				grid.column_spacing = 6;
				this.add_with_viewport (grid);
				grid.show ();

				var type_label = new Label (_("_Type:"));
				type_label.use_underline = true;
				type_label.xalign = 0.0f;
				grid.add (type_label);
				type_label.show ();

				regular_radio = new RadioButton.with_mnemonic (null, _("Re_gular"));
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

				var period_label = new Label (_("_Period:"));
				period_label.use_underline = true;
				period_label.xalign = 0.0f;
				grid.add (period_label);
				period_label.show ();

				start_spin = new DateSpinButton ();
				grid.attach_next_to (start_spin,
				                     period_label,
				                     PositionType.RIGHT,
				                     1, 1);
				start_spin.show ();

				end_spin = new DateSpinButton ();
				grid.attach_next_to (end_spin,
				                     start_spin,
				                     PositionType.BOTTOM,
				                     1, 1);
				end_spin.show ();

				var deduc_scroll = new ScrolledWindow (null, null);
				deduc_scroll.expand = true;
				grid.add_with_properties (deduc_scroll, width: 3);
				deduc_scroll.show ();

				deduc_view = new TreeView ();
				deduc_scroll.add (deduc_view);
				deduc_view.show ();

				CellRendererSpin renderer;
				TreeViewColumn column;

				column = new TreeViewColumn.with_attributes (_("Employee Name"),
				                                             new CellRendererText (),
				                                             "text", Columns.NAME,
				                                             null);
				column.expand = true;
				deduc_view.append_column (column);

				renderer = new CellRendererSpin ();
				renderer.adjustment = new Adjustment (0, 0, 999999,
				                                      1, 10, 0);
				renderer.editable = true;
				renderer.climb_rate = 1;
				renderer.digits = 2;
				renderer.edited.connect ((r, p, n) => {
					TreeIter iter;
					var deduc_store = deduc_view.model as ListStore;
					deduc_store.get_iter_from_string (out iter, p);
					deduc_store.set (iter, Columns.TAX, double.parse (n));
				});
				column = new TreeViewColumn ();
				column.title = _("Tax");
				column.expand = true;
				column.pack_start (renderer, true);
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, Columns.TAX, out value);
					(r as CellRendererText).text = "%.2lf".printf ((double) value);
				});
				deduc_view.append_column (column);

				renderer = new CellRendererSpin ();
				renderer.adjustment = new Adjustment (0, 0, 999999,
				                                      1, 10, 0);
				renderer.editable = true;
				renderer.climb_rate = 1;
				renderer.digits = 2;
				renderer.edited.connect ((r, p, n) => {
					TreeIter iter;
					var deduc_store = deduc_view.model as ListStore;
					deduc_store.get_iter_from_string (out iter, p);
					deduc_store.set (iter, Columns.LOAN, double.parse (n));
				});
				column = new TreeViewColumn ();
				column.title = _("Loan");
				column.expand = true;
				column.pack_start (renderer, true);
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, Columns.LOAN, out value);
					(r as CellRendererText).text = "%.2lf".printf ((double) value);
				});
				deduc_view.append_column (column);

				renderer = new CellRendererSpin ();
				renderer.adjustment = new Adjustment (0, 0, 999999,
				                                      1, 10, 0);
				renderer.editable = true;
				renderer.climb_rate = 1;
				renderer.digits = 2;
				renderer.edited.connect ((r, p, n) => {
					TreeIter iter;
					var deduc_store = deduc_view.model as ListStore;
					deduc_store.get_iter_from_string (out iter, p);
					deduc_store.set (iter, Columns.PAG_IBIG, double.parse (n));
				});
				column = new TreeViewColumn ();
				column.title = _("PAG-IBIG");
				column.expand = true;
				column.pack_start (renderer, true);
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, Columns.PAG_IBIG, out value);
					(r as CellRendererText).text = "%.2lf".printf ((double) value);
				});
				deduc_view.append_column (column);

				renderer = new CellRendererSpin ();
				renderer.adjustment = new Adjustment (0, 0, 999999,
				                                      1, 10, 0);
				renderer.editable = true;
				renderer.climb_rate = 1;
				renderer.digits = 2;
				renderer.edited.connect ((r, p, n) => {
					TreeIter iter;
					var deduc_store = deduc_view.model as ListStore;
					deduc_store.get_iter_from_string (out iter, p);
					deduc_store.set (iter, Columns.SSS_LOAN, double.parse (n));
				});
				column = new TreeViewColumn ();
				column.title = _("SSS Loan");
				column.expand = true;
				column.pack_start (renderer, true);
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, Columns.SSS_LOAN, out value);
					(r as CellRendererText).text = "%.2lf".printf ((double) value);
				});
				deduc_view.append_column (column);

				renderer = new CellRendererSpin ();
				renderer.adjustment = new Adjustment (0, 0, 999999,
				                                      1, 10, 0);
				renderer.editable = true;
				renderer.climb_rate = 1;
				renderer.digits = 2;
				renderer.edited.connect ((r, p, n) => {
					TreeIter iter;
					var deduc_store = deduc_view.model as ListStore;
					deduc_store.get_iter_from_string (out iter, p);
					deduc_store.set (iter, Columns.VALE, double.parse (n));
				});
				column = new TreeViewColumn ();
				column.title = _("Vale");
				column.expand = true;
				column.pack_start (renderer, true);
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, Columns.VALE, out value);
					(r as CellRendererText).text = "%.2lf".printf ((double) value);
				});
				deduc_view.append_column (column);

				renderer = new CellRendererSpin ();
				renderer.adjustment = new Adjustment (0, 0, 999999,
				                                      1, 10, 0);
				renderer.editable = true;
				renderer.climb_rate = 1;
				renderer.digits = 2;
				renderer.edited.connect ((r, p, n) => {
					TreeIter iter;
					var deduc_store = deduc_view.model as ListStore;
					deduc_store.get_iter_from_string (out iter, p);
					deduc_store.set (iter, Columns.MOESALA_LOAN, double.parse (n));
				});
				column = new TreeViewColumn ();
				column.title = _("Moesala Loan");
				column.expand = true;
				column.pack_start (renderer, true);
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, Columns.MOESALA_LOAN, out value);
					(r as CellRendererText).text = "%.2lf".printf ((double) value);
				});
				deduc_view.append_column (column);

				renderer = new CellRendererSpin ();
				renderer.adjustment = new Adjustment (0, 0, 999999,
				                                      1, 10, 0);
				renderer.editable = true;
				renderer.climb_rate = 1;
				renderer.digits = 2;
				renderer.edited.connect ((r, p, n) => {
					TreeIter iter;
					var deduc_store = deduc_view.model as ListStore;
					deduc_store.get_iter_from_string (out iter, p);
					deduc_store.set (iter, Columns.MOESALA_SAVINGS, double.parse (n));
				});
				column = new TreeViewColumn ();
				column.title = _("Moesala Savings");
				column.expand = true;
				column.pack_start (renderer, true);
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, Columns.MOESALA_SAVINGS, out value);
					(r as CellRendererText).text = "%.2lf".printf ((double) value);
				});
				deduc_view.append_column (column);


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
							if (this.print_settings == null) {
								print_settings = new PrintSettings ();
								print_settings.set_paper_size (new PaperSize (PAPER_NAME_FANFOLD_GERMAN_LEGAL));
							}

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
					(pr as RegularReport).deductions = deduc_view.model as ListStore;
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
				pr.default_page_setup = page_setup;
				pr.show_progress = true;

				pr.title_font = title_font;
				pr.company_name_font = company_name_font;
				pr.header_font = header_font;
				pr.text_font = text_font;
				pr.number_font = number_font;
				pr.emp_number_font = emp_number_font;

				if (print_settings != null) {
					pr.print_settings = print_settings;
				}

				return pr;
			}

			public override void changed_to () {
				base.changed_to ();

				var deduc_store = new ListStore (Columns.NUM,
				                                 typeof (int),
				                                 typeof (string),
				                                 typeof (double),
				                                 typeof (double),
				                                 typeof (double),
				                                 typeof (double),
				                                 typeof (double),
				                                 typeof (double),
				                                 typeof (double));
				deduc_view.model = deduc_store;

				var list = this.cpanel.window.app.database.employee_list;
				for (int i = 0; i < list.size; i++) {
					var employee = (list as ArrayList<Employee>).get (i);
					deduc_store.insert_with_values (null, -1,
					                                Columns.NAME, employee.get_name (),
					                                Columns.ID, employee.id);
				}
			}

		}

	}

}
