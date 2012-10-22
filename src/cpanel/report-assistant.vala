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
				FINISH,
				NUM
			}


			public Window parent_window { get; private set; }

			private PageSetup page_setup;
			private PrintSettings print_settings;


			public ReportAssistant (Window parent, PageSetup page_setup, PrintSettings print_settings) {
				Object (title: _("Report Assistant"),
				        transient_for: parent);

				this.parent_window = parent;
				this.page_setup = page_setup;
				this.print_settings = print_settings;
				this.prepare.connect ((a, p) => {
							(p as Page).prepare ();
						});


				Page page;


				page = new WelcomePage (this);
				insert_page (page, Pages.WELCOME);
				set_page_type (page, AssistantPageType.INTRO);
				set_page_title (page, _("Welcome"));
				set_page_complete (page, true);
				page.show ();

				page = new BasicInfoPage (this);
				insert_page (page, Pages.BASIC_INFO);
				set_page_type (page, AssistantPageType.CONTENT);
				set_page_title (page, _("Basic Information"));
				set_page_complete (page, true);
				page.show ();

				page = new SelectEmployeesPage (this);
				insert_page (page, Pages.SELECT_EMPLOYEES);
				set_page_type (page, AssistantPageType.CONTENT);
				set_page_title (page, _("Select Employees"));
				set_page_complete (page, true);
				page.show ();

				page = new FooterInfoPage (this);
				insert_page (page, Pages.FOOTER_INFO);
				set_page_type (page, AssistantPageType.CONTENT);
				set_page_title (page, _("Footer Information"));
				set_page_complete (page, true);
				page.show ();

				page = new FinishPage (this);
				insert_page (page, Pages.FINISH);
				set_page_type (page, AssistantPageType.SUMMARY);
				set_page_title (page, _("Finish"));
				set_page_complete (page, true);
				page.show ();
			}


			public abstract class Page : Box {

				public ReportAssistant assistant;

				public Page (ReportAssistant assistant) {
					this.assistant = assistant;
					this.orientation = Orientation.VERTICAL;
					this.spacing = 12;
					this.border_width = 6;
				}

				public virtual signal void prepare () {
				}

			}


			public class WelcomePage : Page {

				public WelcomePage (ReportAssistant assistant) {
					base (assistant);


					push_composite_child ();


					var label = new Label (_("Welcome to the Report Assistant.\n\nClick \"Forward\" to continue."));
					label.xalign = 0.0f;
					this.add (label);
					label.show ();


					pop_composite_child ();
				}

			}


			public class BasicInfoPage : Page {

				public Grid grid { get; private set; }

				public RadioButton regular_radio { get; private set; }
				public RadioButton overtime_radio { get; private set; }
				public DateSpinButton start_spin { get; private set; }
				public DateSpinButton end_spin { get; private set; }
				public ComboBox branch_combobox { get; private set; }
				public EmployeeList list;


				public BasicInfoPage (ReportAssistant assistant) {
					base (assistant);


					push_composite_child ();


					var label = new Label (_("Select the branch, type and date for the report below.\n\nFor regular reports, the start date should be the 1st or 15th day of the month, with the end date 16th or last day of the month, respectively."));
					label.wrap = true;
					label.xalign = 0.0f;
					this.add (label);
					label.show ();

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
					regular_radio.toggled.connect (changed);
					grid.attach_next_to (regular_radio,
					                     type_label,
					                     PositionType.RIGHT,
					                     1, 1);
					regular_radio.show ();

					overtime_radio = new RadioButton.with_mnemonic_from_widget (regular_radio, _("_Overtime"));
					overtime_radio.toggled.connect (changed);
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
					start_spin.value_changed.connect (changed);
					grid.attach_next_to (start_spin,
					                     period_label,
					                     PositionType.RIGHT,
					                     1, 1);
					period_label.mnemonic_widget = start_spin;
					start_spin.show ();

					end_spin = new DateSpinButton ();
					end_spin.value_changed.connect (changed);
					grid.attach_next_to (end_spin,
					                     start_spin,
					                     PositionType.BOTTOM,
					                     1, 1);
					end_spin.show ();

					var branch_label = new Label.with_mnemonic (_("_Branch:"));
					branch_label.xalign = 0.0f;
					grid.add (branch_label);
					branch_label.show ();

					branch_combobox = new ComboBox.with_model (assistant.parent_window.app.database.branch_list);
					branch_combobox.hexpand = true;
					branch_combobox.changed.connect (changed);
					grid.attach_next_to (branch_combobox,
					                     branch_label,
					                     PositionType.RIGHT,
					                     1, 1);
					branch_label.mnemonic_widget = branch_combobox;
					branch_combobox.show ();

					var branch_cell_renderer = new CellRendererText ();
					branch_combobox.pack_start (branch_cell_renderer, true);
					branch_combobox.add_attribute (branch_cell_renderer,
					                               "text", BranchList.Columns.NAME);


					pop_composite_child ();


					/* Set default period */
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

					/* Set default branch */
					TreeIter iter;
					if (branch_combobox.model.get_iter_first (out iter)) {
						branch_combobox.set_active_iter (iter);
					}
				}

				public void changed () {
					TreeIter iter;
					Branch branch;

					if (assistant.get_current_page () < 0) {
						return;
					}

					if (branch_combobox.get_active_iter (out iter)) {
						branch_combobox.model.get (iter, BranchList.Columns.OBJECT, out branch);
					} else {
						assistant.set_page_complete (this, false);
						return;
					}

					var start = start_spin.date;

					if (regular_radio.active) {
						if (start.get_day () != 1 && start.get_day () != 16) {
							assistant.set_page_complete (this, false);
							return;
						}
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

					var end = end_spin.date;
					var correct_end = Date ();
					correct_end.set_dmy (last_day, start.get_month (), start.get_year ());
					if (correct_end.compare (end) != 0) {
						assistant.set_page_complete (this, false);
						return;
					}

					assistant.set_page_complete (this, true);
				}

			}


			public class SelectEmployeesPage : Page {

				public TreeView tree_view { get; private set; }
				public TreeModelSort sort { get; private set; }
				public EmployeeList list;


				public SelectEmployeesPage (ReportAssistant assistant) {
					base (assistant);


					push_composite_child ();


					var label = new Label (_("Select employees to be included to the report."));
					label.xalign = 0.0f;
					this.add (label);
					label.show ();


					var sw = new ScrolledWindow (null, null);
					this.add (sw);
					sw.show ();

					tree_view = new TreeView ();
					tree_view.expand = true;
					tree_view.get_selection ().mode = SelectionMode.MULTIPLE;
					tree_view.rubber_banding = true;
					tree_view.search_column = (int) EmployeeList.Columns.NAME;
					sw.add (tree_view);
					tree_view.show ();

					TreeViewColumn column;

					var renderer = new CellRendererToggle ();
					renderer.toggled.connect ((renderer, path) => {
																TreeIter iter, iterSort;
																Value value;
																sort.get_iter_from_string (out iterSort, path);
																sort.convert_iter_to_child_iter (out iter, iterSort);
																list.get_value (iter, EmployeeList.Columns.OBJECT, out value);
																list.set_is_enabled (value as Employee, !renderer.active);
															});

					column = new TreeViewColumn.with_attributes (_("Include"),
					                                             renderer,
					                                             "active", EmployeeList.Columns.ENABLED);
					column.sort_column_id = EmployeeList.Columns.ENABLED;
					column.expand = false;
					column.reorderable = true;
					column.resizable = true;
					tree_view.append_column (column);

					column = new TreeViewColumn.with_attributes (_("Employee Name"),
					                                             new CellRendererText (),
					                                             "text", EmployeeList.Columns.NAME);
					column.sort_column_id = EmployeeList.Columns.NAME;
					column.expand = true;
					column.reorderable = true;
					column.resizable = true;
					tree_view.append_column (column);


					pop_composite_child ();
				}

				public override void prepare () {
					list = (assistant.get_nth_page (Pages.BASIC_INFO) as BasicInfoPage).list;

					sort = new TreeModelSort.with_model (this.list);
					sort.set_sort_func (EmployeeList.Columns.NAME,
					                    (model, a, b) => {
																var employee1 = a.user_data as Employee;
																var employee2 = b.user_data as Employee;

																return strcmp (employee1.get_name (),
																               employee2.get_name ());
															});

					sort.set_sort_func (EmployeeList.Columns.ENABLED,
					                    (model, a, b) => {
																var employee1 = list.get_is_enabled (a.user_data as Employee);
																var employee2 = list.get_is_enabled (b.user_data as Employee);

																return
																	employee1 == employee2? 0 :
																	employee1 == false? -1 : 1;
															});

					tree_view.model = sort;
				}

			}


			public class FooterInfoPage : Page {

				public Grid grid { get; private set; }

				public Entry preparer_entry { get; private set; }
				public Entry approver_entry { get; private set; }
				public Entry approver_position_entry { get; private set; }


				public FooterInfoPage (ReportAssistant assistant) {
					base (assistant);


					push_composite_child ();


					var label = new Label (_("Set the information shown in the footer of the report below."));
					label.xalign = 0.0f;
					this.add (label);
					label.show ();

					grid = new Grid ();
					grid.orientation = Orientation.VERTICAL;
					grid.row_spacing = 3;
					grid.column_spacing = 6;
					this.add (grid);
					grid.show ();

					var preparer_label = new Label.with_mnemonic (_("P_reparer:"));
					preparer_label.xalign = 0.0f;
					grid.add (preparer_label);
					preparer_label.show ();

					preparer_entry = new Entry ();
					grid.attach_next_to (preparer_entry,
					                     preparer_label,
					                     PositionType.RIGHT,
					                     1, 1);
					preparer_entry.show ();

					var approver_label = new Label.with_mnemonic (_("_Approver:"));
					approver_label.xalign = 0.0f;
					grid.add (approver_label);
					approver_label.show ();

					approver_entry = new Entry ();
					grid.attach_next_to (approver_entry,
					                     approver_label,
					                     PositionType.RIGHT,
					                     1, 1);
					approver_entry.show ();

					approver_position_entry = new Entry ();
					grid.attach_next_to (approver_position_entry,
					                     approver_entry,
					                     PositionType.BOTTOM,
					                     1, 1);
					approver_position_entry.show ();


					var report_settings = assistant.parent_window.app.settings.report;
					preparer_entry.text = report_settings.get_string ("preparer");
					approver_entry.text = report_settings.get_string ("approver");
					approver_position_entry.text = report_settings.get_string ("approver-position");


					pop_composite_child ();
				}

			}


			public class FinishPage : Page {

				private enum Columns {
					TEXT,
					TOOLTIP,
					PIXBUF,
					NUM
				}

				private enum Actions {
					SAVE,
					PRINT,
					PRINT_PREVIEW
				}

				public FinishPage (ReportAssistant assistant) {
					base (assistant);


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


					push_composite_child ();


					var label = new Label (_("The report has been successfully created. Select an action below."));
					label.xalign = 0.0f;
					this.add (label);
					label.show ();

					var sw = new ScrolledWindow (null, null);
					this.add (sw);
					sw.show ();

					var icon_view = new IconView.with_model (actions);
					icon_view.expand = true;
					icon_view.item_orientation = Orientation.HORIZONTAL;
					icon_view.text_column = Columns.TEXT;
					icon_view.tooltip_column = Columns.TOOLTIP;
					icon_view.pixbuf_column = Columns.PIXBUF;
					icon_view.item_activated.connect ((i, p) => {
													var basic_info_page = assistant.get_nth_page (Pages.BASIC_INFO) as BasicInfoPage;
													var select_employees_page = assistant.get_nth_page (Pages.SELECT_EMPLOYEES) as SelectEmployeesPage;

													var is_regular = basic_info_page.regular_radio.active;
													var start_date = basic_info_page.start_spin.date;
													var end_date = basic_info_page.end_spin.date;

													try {
														var pr = assistant.create_report (is_regular,
														                                  start_date,
														                                  end_date,
														                                  select_employees_page.list);

														switch (p.get_indices ()[0])
														{
															case Actions.SAVE:
																var dialog = new FileChooserDialog (_("Export"),
																                                    assistant.parent_window,
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
																	pr.export (assistant.parent_window);
																}

																dialog.destroy ();

																break;
															case Actions.PRINT:
																pr.print_dialog (assistant.parent_window);
																break;
															case Actions.PRINT_PREVIEW:
																pr.preview_dialog (assistant.parent_window);
																break;
														}
													} catch (Error e) {
														assistant.parent_window.show_error_dialog (_("Failed to print report"),
														                                      e.message);
													}
												});
					sw.add (icon_view);
					icon_view.show ();


					pop_composite_child ();
				}

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
						              MonthInfo.HolidayType.NON_HOLIDAY,
						              1.0,
						              new PayPeriod[] {
														period_5pm_10pm,
														period_10pm_6am
													}),
						new PayGroup (_("Sunday, Non-Holiday"),
						              true,
						              MonthInfo.HolidayType.NON_HOLIDAY,
						              1.3,
						              pay_periods),
						new PayGroup (_("Regular Holiday"),
						              false,
						              MonthInfo.HolidayType.REGULAR_HOLIDAY,
						              2.0,
						              pay_periods),
						new PayGroup (_("Sunday, Regular Holiday"),
						              true,
						              MonthInfo.HolidayType.REGULAR_HOLIDAY,
						              1.3 * 2.0,
						              pay_periods),
						new PayGroup (_("Special Holiday"),
						              false,
						              MonthInfo.HolidayType.SPECIAL_HOLIDAY,
						              1.3,
						              pay_periods),
						new PayGroup (_("Sunday, Special Holiday"),
						              true,
						              MonthInfo.HolidayType.SPECIAL_HOLIDAY,
						              1.3 * 1.3,
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
								.get_affected_dates (parent_window.app.database).length;
						}
						if (affected > 0) {
							affected_pay_groups += pay_group;
						}
					}

					(pr as OvertimeReport).pay_groups = affected_pay_groups;
				}

				pr.employees = employees;

				pr.default_page_setup = page_setup;
				pr.print_settings = print_settings;

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
				var footer_info_page = get_nth_page (Pages.FOOTER_INFO) as FooterInfoPage;
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
