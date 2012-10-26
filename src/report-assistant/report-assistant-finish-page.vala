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
using Gdk;
using Pango;


namespace Mobilect {

	namespace Payroll {

		public class ReportAssistantFinishPage : ReportAssistantPage {

			private enum Columns {
				TITLE,
				SUBTITLE,
				ICON_NAME,
				NUM
			}

			private enum Actions {
				SAVE,
				PRINT,
				PRINT_PREVIEW
			}

			public ReportAssistantFinishPage (ReportAssistant assistant) {
				base (assistant);

				/*
				 var actions = new ListStore (Columns.NUM, typeof (string), typeof (string), typeof (Pixbuf));

				 actions.insert_with_values (null, Actions.SAVE,
				                             Columns.TEXT, _("Save"),
											 Columns.TOOLTIP, _("Export payroll and payslips to a PDF file"),
											 Columns.PIXBUF, this.render_icon (Stock.SAVE, IconSize.LARGE_TOOLBAR, null));
				 actions.insert_with_values (null, Actions.PRINT,
				                             Columns.TEXT, _("Print"),
											 Columns.TOOLTIP, _("Print payroll and payslips"),
											 Columns.PIXBUF, this.render_icon (Stock.PRINT, IconSize.LARGE_TOOLBAR, null));
				 actions.insert_with_values (null, Actions.PRINT_PREVIEW,
				                             Columns.TEXT, _("Print Preview"),
											 Columns.TOOLTIP, _("Print preview of payroll and payslips"),
											 Columns.PIXBUF, this.render_icon (Stock.PRINT_PREVIEW, IconSize.LARGE_TOOLBAR, null));
				 */
				var actions = new ListStore (Columns.NUM, typeof (string), typeof (string), typeof (string));

				actions.insert_with_values (null, Actions.SAVE,
				                            Columns.TITLE, _("Save"),
				                            Columns.SUBTITLE, _("Export payroll and payslips to a PDF file"),
				                            Columns.ICON_NAME, Stock.SAVE);
				actions.insert_with_values (null, Actions.PRINT,
				                            Columns.TITLE, _("Print"),
				                            Columns.SUBTITLE, _("Print payroll and payslips"),
				                            Columns.ICON_NAME, Stock.PRINT);
				actions.insert_with_values (null, Actions.PRINT_PREVIEW,
				                            Columns.TITLE, _("Print Preview"),
				                            Columns.SUBTITLE, _("Print preview of payroll and payslips"),
				                            Columns.ICON_NAME, Stock.PRINT_PREVIEW);


				push_composite_child ();


				var label = new Label (_("The report has been successfully created. Select an action below."));
				label.xalign = 0.0f;
				this.add (label);
				label.show ();

				var sw = new ScrolledWindow (null, null);
				this.add (sw);
				sw.show ();

				var tree_view = new TreeView.with_model (actions);
				tree_view.expand = true;
				tree_view.headers_visible = false;
				tree_view.row_activated.connect ((i, p, r) => {
												var basic_info_page = assistant.get_nth_page (ReportAssistant.Pages.BASIC_INFO) as ReportAssistantBasicInfoPage;
												var select_employees_page = assistant.get_nth_page (ReportAssistant.Pages.SELECT_EMPLOYEES) as ReportAssistantSelectEmployeesPage;

												var is_regular = basic_info_page.regular_radio.active;
												var start_date = basic_info_page.start_spin.date;
												var end_date = basic_info_page.end_spin.date;

												try {
													var pr = create_report (is_regular,
													                        start_date,
													                        end_date,
													                        select_employees_page.list.get_subset (true));

													switch (p.get_indices ()[0])
													{
														case Actions.SAVE:
															var dialog = new FileChooserDialog (_("Export"),
															                                    assistant,
															                                    FileChooserAction.SAVE,
															                                    Stock.CANCEL, ResponseType.REJECT,
															                                    Stock.SAVE, ResponseType.ACCEPT);
															dialog.set_alternative_button_order (ResponseType.ACCEPT, ResponseType.REJECT);
															dialog.do_overwrite_confirmation = true;

															string current_name;
															if (is_regular) {
																current_name = _("payroll-regular_%s-%s.pdf");
															} else {
																current_name = _("payroll-overtime_%s-%s.pdf");
															}
															dialog.set_current_name (current_name.printf (pr.format_date (start_date, "%Y%m%d"),
															                                              pr.format_date (end_date, "%Y%m%d")));

															if (dialog.run () == ResponseType.ACCEPT) {
																dialog.hide ();

																pr.export_filename = dialog.get_filename ();
																pr.export (assistant);
															}

															dialog.destroy ();

															break;
														case Actions.PRINT:
															pr.print_dialog (assistant);
															break;
														case Actions.PRINT_PREVIEW:
															pr.preview_dialog (assistant);
															break;
													}
												} catch (Error e) {
													assistant.parent_window.show_error_dialog (_("Failed to print report"),
													                                           e.message);
												}
											});
				sw.add (tree_view);
				tree_view.show ();

				var cell_icon = new CellRendererPixbuf ();
				cell_icon.stock_size = IconSize.LARGE_TOOLBAR;

				var column_icon = new TreeViewColumn.with_attributes (_("Icon"),
				                                                      cell_icon,
				                                                      "stock-id", Columns.ICON_NAME);
				tree_view.append_column (column_icon);

				var vbox = new CellAreaBox ();
				vbox.orientation = Orientation.VERTICAL;

				var column_text = new TreeViewColumn.with_area (vbox);
				tree_view.append_column (column_text);

				var cell_title = new CellRendererText ();
				cell_title.weight = Weight.BOLD;
				column_text.pack_start (cell_title, true);
				column_text.set_attributes (cell_title,
				                            "text", Columns.TITLE);

				var cell_subtitle = new CellRendererText ();
				column_text.pack_start (cell_subtitle, true);
				column_text.set_attributes (cell_subtitle,
				                            "text", Columns.SUBTITLE);

				pop_composite_child ();
			}

			private Report create_report (bool regular, Date start_date, Date end_date, EmployeeList employees) throws ReportError, RegularReportError {
				Report pr;

				if (regular) {
					pr = new RegularReport (start_date, end_date);
					pr.title = _("SEMI-MONTHLY PAYROLL");
				} else {
					var period_8am_5pm = new PayPeriod (_("8am-5pm"),
					                                    false,
					                                    1.0,
					                                    new TimePeriod[] {
																								TimePeriod (Time (8,0), Time (12,0)),
																								TimePeriod (Time (13,0), Time (17,0))
																							});
					var period_5pm_10pm = new PayPeriod (_("5pm-10pm"),
					                                     true,
					                                     1.25,
					                                     new TimePeriod[] {
																								 TimePeriod (Time (6,0), Time (8,0)),
																								 TimePeriod (Time (17,0), Time (22,0))
																							 });
					var period_10pm_6am = new PayPeriod (_("10pm-6am"),
					                                     true,
					                                     1.5,
					                                     new TimePeriod[] {
																								 TimePeriod (Time (22,0), Time (0,0)),
																								 TimePeriod (Time (0,0), Time (6,0))
																							 });

					var pay_periods = new PayPeriod[] {
						period_8am_5pm,
						period_5pm_10pm,
						period_10pm_6am
					};

					var pay_groups = new PayGroup[] {
						new PayGroup (_("Non-Holiday"),
						              false,
						              false,
						              MonthInfo.HolidayType.NON_HOLIDAY,
						              1.0,
						              new PayPeriod[] {
														period_5pm_10pm,
														period_10pm_6am
													}),
						new PayGroup (_("Sunday, Non-Holiday"),
						              false,
						              true,
						              MonthInfo.HolidayType.NON_HOLIDAY,
						              1.3,
						              pay_periods),
						new PayGroup (_("Regular Holiday"),
						              false,
						              false,
						              MonthInfo.HolidayType.REGULAR_HOLIDAY,
						              2.0,
						              pay_periods),
						new PayGroup (_("Sunday, Regular Holiday"),
						              false,
						              true,
						              MonthInfo.HolidayType.REGULAR_HOLIDAY,
						              1.3 * 2.0,
						              pay_periods),
						new PayGroup (_("Special Holiday"),
						              false,
						              false,
						              MonthInfo.HolidayType.SPECIAL_HOLIDAY,
						              1.3,
						              pay_periods),
						new PayGroup (_("Sunday, Special Holiday"),
						              false,
						              true,
						              MonthInfo.HolidayType.SPECIAL_HOLIDAY,
						              1.3 * 1.3,
						              pay_periods),
						new PayGroup (_("Straight Time Only"),
						              true,
						              false, /* Ignored */
						              MonthInfo.HolidayType.NON_HOLIDAY, /* Ignored */
						              1.0,
						              pay_periods)
					};


					pr = new OvertimeReport (start_date, end_date);
					pr.title = _("MONTHLY OVERTIME PAYROLL");

					int affected;
					var affected_pay_groups = new PayGroup[0];
					foreach (var pay_group in pay_groups) {
						affected = 0;
						for (int i = 0; i < pay_group.periods.length; i++) {
							affected += pay_group.create_filter (i, start_date, end_date)
								.get_affected_dates (assistant.parent_window.app.database).length;
						}
						if (affected > 0) {
							affected_pay_groups += pay_group;
						}
					}

					(pr as OvertimeReport).pay_groups = affected_pay_groups;
				}

				pr.employees = employees;

				pr.default_page_setup = assistant.page_setup;
				pr.print_settings = assistant.print_settings;

				pr.continuous = assistant.continuous;

				/* Set fonts */
				var report_settings = assistant.parent_window.app.settings.report;
				pr.title_font = FontDescription.from_string (report_settings.get_string ("title-font"));
				pr.company_name_font = FontDescription.from_string (report_settings.get_string ("company-name-font"));
				pr.header_font = FontDescription.from_string (report_settings.get_string ("header-font"));
				pr.text_font = FontDescription.from_string (report_settings.get_string ("text-font"));
				pr.number_font = FontDescription.from_string (report_settings.get_string ("number-font"));
				pr.emp_number_font = FontDescription.from_string (report_settings.get_string ("emphasized-number-font"));

				/* Set padding */
				pr.padding = report_settings.get_double ("padding");

				/* Set preparer */
				var footer_info_page = assistant.get_nth_page (ReportAssistant.Pages.FOOTER_INFO) as ReportAssistantFooterInfoPage;
				pr.preparer = footer_info_page.preparer_entry.text;
				pr.approver = footer_info_page.approver_entry.text;
				pr.approver_position = footer_info_page.approver_position_entry.text;

				/* Show status in statusbar */
				uint context_id = assistant.parent_window.statusbar.get_context_id ("report-assistant");
				pr.status_changed.connect ((o) => {
														assistant.parent_window.statusbar.push (context_id, _("Report: %s").printf (pr.status_string));
													});
				pr.done.connect ((o, r) => {
														if (r == PrintOperationResult.ERROR) {
															/* Show error */
															try {
																o.get_error ();
															} catch (Error e) {
																assistant.parent_window.show_error_dialog (_("Failed to print report"),
																                                           e.message);
															}
														} else if (r == PrintOperationResult.APPLY) {
															/* Save print settings */
															try {
																assistant.print_settings = pr.print_settings;
																assistant.print_settings.to_file (assistant.parent_window.app.settings.print_settings);
															} catch (Error e) {
																assistant.parent_window.show_error_dialog (_("Failed to save print settings"),
																                                           e.message);
															}
														}

														/* Remove messages after 5 seconds */
														Timeout.add_seconds (5, () => {
																																				assistant.parent_window.statusbar.remove_all (context_id);
																																				return false;
																																			});

													});

				return pr;
			}

		}

	}

}
