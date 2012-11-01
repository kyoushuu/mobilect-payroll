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

		public class ReportAssistant : Assistant {

			public enum Pages {
				WELCOME,
				BASIC_INFO,
				SELECT_EMPLOYEES,
				FOOTER_INFO,
				PAGE_SETUP,
				CONFIRM,
				APPLY,
				FINISH,
				NUM
			}


			public Window parent_window { get; private set; }

			public UIManager ui_manager { get; private set; }

			public PageSetup page_setup { get; set; }
			public PrintSettings print_settings { get; set; }
			public bool continuous { get; set; }


			public ReportAssistant (Window parent, PageSetup page_setup, PrintSettings print_settings) {
				Object (title: _("Report Assistant"),
				        transient_for: parent);

				this.parent_window = parent;
				this.page_setup = page_setup;
				this.print_settings = print_settings;
				this.prepare.connect ((a, p) => {
							(p as ReportAssistantPage).prepare ();
						});

				this.ui_manager = new UIManager ();
				try {
					this.ui_manager.add_ui_from_resource ("/com/mobilectpower/Payroll/mobilect-payroll-report-assistant-ui.xml");
				} catch (Error e) {
					error ("Failed to add UI to UI Manager: %s", e.message);
				}


				ReportAssistantPage page;


				page = new ReportAssistantWelcomePage (this);
				insert_page (page, Pages.WELCOME);
				set_page_type (page, AssistantPageType.INTRO);
				set_page_title (page, _("Welcome"));
				set_page_complete (page, true);
				page.show ();

				page = new ReportAssistantBasicInfoPage (this);
				insert_page (page, Pages.BASIC_INFO);
				set_page_type (page, AssistantPageType.CONTENT);
				set_page_title (page, _("Basic Information"));
				set_page_complete (page, true);
				page.show ();

				page = new ReportAssistantSelectEmployeesPage (this);
				insert_page (page, Pages.SELECT_EMPLOYEES);
				set_page_type (page, AssistantPageType.CONTENT);
				set_page_title (page, _("Select Employees"));
				set_page_complete (page, true);
				page.show ();

				page = new ReportAssistantFooterInfoPage (this);
				insert_page (page, Pages.FOOTER_INFO);
				set_page_type (page, AssistantPageType.CONTENT);
				set_page_title (page, _("Footer Information"));
				set_page_complete (page, true);
				page.show ();

				page = new ReportAssistantPageSetupPage (this);
				insert_page (page, Pages.PAGE_SETUP);
				set_page_type (page, AssistantPageType.CONTENT);
				set_page_title (page, _("Page Setup"));
				set_page_complete (page, true);
				page.show ();

				page = new ReportAssistantConfirmPage (this);
				insert_page (page, Pages.CONFIRM);
				set_page_type (page, AssistantPageType.CONFIRM);
				set_page_title (page, _("Confirmation"));
				set_page_complete (page, true);
				page.show ();

				page = new ReportAssistantApplyPage (this);
				insert_page (page, Pages.APPLY);
				set_page_type (page, AssistantPageType.PROGRESS);
				set_page_title (page, _("Applying Changes"));
				set_page_complete (page, false);
				page.show ();

				page = new ReportAssistantFinishPage (this);
				insert_page (page, Pages.FINISH);
				set_page_type (page, AssistantPageType.SUMMARY);
				set_page_title (page, _("Finish"));
				set_page_complete (page, true);
				page.show ();
			}

			public override void apply () {
				Idle.add (() => {
					var basic_info_page = get_nth_page (ReportAssistant.Pages.BASIC_INFO) as ReportAssistantBasicInfoPage;
					var select_employees_page = get_nth_page (ReportAssistant.Pages.SELECT_EMPLOYEES) as ReportAssistantSelectEmployeesPage;
					var confirm_page = get_nth_page (ReportAssistant.Pages.CONFIRM) as ReportAssistantConfirmPage;
					var apply_page = get_nth_page (ReportAssistant.Pages.APPLY) as ReportAssistantApplyPage;

					var is_regular = basic_info_page.regular_radio.active;
					var start_date = basic_info_page.start_spin.date;
					var end_date = basic_info_page.end_spin.date;

					var progress_bar = apply_page.progress_bar;

					TreeModel model;
					TreeIter iter;

					confirm_page.tree_view.get_selection ().get_selected (out model, out iter);
					var p = model.get_path (iter);

					try {
						var pr = create_report (is_regular,
						                        start_date,
						                        end_date,
						                        select_employees_page.list.get_subset (true));
						pr.status_changed.connect ((o) => {
													progress_bar.text = pr.status_string;
												});
						pr.step.connect (() => {
													progress_bar.pulse ();

													while (Gtk.events_pending ()) {
														main_iteration ();
													}
												});

						switch (p.get_indices ()[0]) {
							case ReportAssistantConfirmPage.Actions.SAVE:
								var dialog = new FileChooserDialog (_("Export"),
								                                    this,
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
									pr.export (this);
								}

								dialog.destroy ();

								break;
							case ReportAssistantConfirmPage.Actions.PRINT:
								pr.print_dialog (this);
								break;
							case ReportAssistantConfirmPage.Actions.PRINT_PREVIEW:
								pr.preview_dialog (this);
								break;
						}
					} catch (Error e) {
						parent_window.show_error_dialog (_("Failed to print report"),
						                                 e.message);
					}

					apply_page.progress_bar.fraction = 1.0;
					apply_page.progress_bar.text = _("Finished");
					this.set_page_complete (apply_page, true);

					return false;
				});
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
						              1.0),
						new PayGroup (_("Sundays, Non-Holiday"),
						              false,
						              true,
						              MonthInfo.HolidayType.NON_HOLIDAY,
						              1.3),
						new PayGroup (_("Regular Holiday"),
						              false,
						              false,
						              MonthInfo.HolidayType.REGULAR_HOLIDAY,
						              2.0),
						new PayGroup (_("Sundays, Regular Holiday"),
						              false,
						              true,
						              MonthInfo.HolidayType.REGULAR_HOLIDAY,
						              1.3 * 2.0),
						new PayGroup (_("Special Holiday"),
						              false,
						              false,
						              MonthInfo.HolidayType.SPECIAL_HOLIDAY,
						              1.3),
						new PayGroup (_("Sundays, Special Holiday"),
						              false,
						              true,
						              MonthInfo.HolidayType.SPECIAL_HOLIDAY,
						              1.3 * 1.3),
						new PayGroup (_("Straight Time Only"),
						              true,
						              false, /* Ignored */
						              MonthInfo.HolidayType.NON_HOLIDAY, /* Ignored */
						              1.0)
					};


					pr = new OvertimeReport (start_date, end_date);
					pr.title = _("MONTHLY OVERTIME PAYROLL");

					(pr as OvertimeReport).pay_groups = pay_groups;
					(pr as OvertimeReport).pay_periods = pay_periods;
				}

				pr.employees = employees;

				pr.default_page_setup = page_setup;
				pr.print_settings = print_settings;

				pr.continuous = continuous;

				/* Set fonts */
				var report_settings = parent_window.app.settings.report;
				pr.title_font = FontDescription.from_string (report_settings.get_string ("title-font"));
				pr.company_name_font = FontDescription.from_string (report_settings.get_string ("company-name-font"));
				pr.header_font = FontDescription.from_string (report_settings.get_string ("header-font"));
				pr.text_font = FontDescription.from_string (report_settings.get_string ("text-font"));
				pr.number_font = FontDescription.from_string (report_settings.get_string ("number-font"));
				pr.emp_number_font = FontDescription.from_string (report_settings.get_string ("emphasized-number-font"));

				/* Set padding */
				pr.padding = report_settings.get_double ("padding");

				/* Set preparer */
				var footer_info_page = get_nth_page (ReportAssistant.Pages.FOOTER_INFO) as ReportAssistantFooterInfoPage;
				pr.preparer = footer_info_page.preparer_entry.text;
				pr.approver = footer_info_page.approver_entry.text;
				pr.approver_position = footer_info_page.approver_position_entry.text;

				/* Show status in statusbar */
				uint context_id = parent_window.statusbar.get_context_id ("report-assistant");
				pr.status_changed.connect ((o) => {
										  parent_window.statusbar.push (context_id, _("Report: %s").printf (pr.status_string));
									  });
				pr.done.connect ((o, r) => {
										  if (r == PrintOperationResult.ERROR) {
											  /* Show error */
											  try {
												  o.get_error ();
											  } catch (Error e) {
												  parent_window.show_error_dialog (_("Failed to print report"),
												                                   e.message);
											  }
										  } else if (r == PrintOperationResult.APPLY) {
											  /* Save print settings */
											  try {
												  print_settings = pr.print_settings;
												  print_settings.to_file (parent_window.app.settings.print_settings);
											  } catch (Error e) {
												  parent_window.show_error_dialog (_("Failed to save print settings"),
												                                   e.message);
											  }
										  }

										  /* Remove messages after 5 seconds */
										  Timeout.add_seconds (5, () => {
																					   parent_window.statusbar.remove_all (context_id);
																					   return false;
																				   });

									  });

				return pr;
			}

		}

	}

}
