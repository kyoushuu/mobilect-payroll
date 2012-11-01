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

		public class AddTimeRecordAssistant : Assistant {

			public enum Pages {
				WELCOME,
				BASIC_INFO,
				SELECT_EMPLOYEES,
				CONFIRM,
				APPLY,
				FINISH,
				NUM
			}


			public Window parent_window { get; private set; }

			public UIManager ui_manager { get; private set; }


			public AddTimeRecordAssistant (Window parent) {
				Object (title: _("Add Time Record Assistant"),
				        transient_for: parent);

				this.parent_window = parent;
				this.prepare.connect ((a, p) => {
							(p as Page).prepare ();
						});

				this.ui_manager = new UIManager ();
				try {
					this.ui_manager.add_ui_from_resource ("/com/mobilectpower/Payroll/mobilect-payroll-add-time-record-assistant-ui.xml");
				} catch (Error e) {
					error ("Failed to add UI to UI Manager: %s", e.message);
				}


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

				page = new ConfirmPage (this);
				insert_page (page, Pages.CONFIRM);
				set_page_type (page, AssistantPageType.CONFIRM);
				set_page_title (page, _("Confirmation"));
				set_page_complete (page, true);
				page.show ();

				page = new ApplyPage (this);
				insert_page (page, Pages.APPLY);
				set_page_type (page, AssistantPageType.PROGRESS);
				set_page_title (page, _("Applying changes"));
				set_page_complete (page, false);
				page.show ();

				page = new FinishPage (this);
				insert_page (page, Pages.FINISH);
				set_page_type (page, AssistantPageType.SUMMARY);
				set_page_title (page, _("Finish"));
				set_page_complete (page, true);
				page.show ();
			}

			public override void apply () {
				Idle.add (() => {
					var select_employees_page = get_nth_page (Pages.SELECT_EMPLOYEES) as SelectEmployeesPage;
					var basic_info_page = get_nth_page (Pages.BASIC_INFO) as BasicInfoPage;
					var apply_page = get_nth_page (Pages.APPLY) as ApplyPage;

					basic_info_page.widget.save ();

					var progress_bar = apply_page.progress_bar;
					var database = parent_window.app.database;
					var time_record = basic_info_page.widget.time_record;
					var list = select_employees_page.list.get_subset (true);
					var list_size = list.size;
					int i = 0;

					foreach (var employee in list) {
						progress_bar.text = "Adding time record for %s".printf (employee.get_name ());

						while (Gtk.events_pending ()) {
							main_iteration ();
						}

						database.add_time_record (employee.id,
							                      time_record.start,
							                      time_record.end,
							                      time_record.straight_time);

						progress_bar.fraction = ++i / (double) list_size;
					}

					progress_bar.text = _("Finished");
					this.set_page_complete (apply_page, true);

					return false;
				});
			}

			public abstract class Page : Box {

				public AddTimeRecordAssistant assistant;

				public Page (AddTimeRecordAssistant assistant) {
					this.assistant = assistant;
					this.orientation = Orientation.VERTICAL;
					this.spacing = 12;
					this.border_width = 6;
				}

				public virtual signal void prepare () {
				}

			}

			public class WelcomePage : Page {

				public WelcomePage (AddTimeRecordAssistant assistant) {
					base (assistant);


					push_composite_child ();


					var label = new Label (_("Welcome to the Add Time Record Assistant.\n\nPress \"Forward\" to continue."));
					label.xalign = 0.0f;
					this.add (label);
					label.show ();


					pop_composite_child ();
				}

			}

			public class BasicInfoPage : Page {

				public Grid grid { get; private set; }

				public ComboBox branch_combobox { public get; private set; }
				public TimeRecordEditWidget widget { public get; private set; }
				public EmployeeList list { public get; private set; }


				public BasicInfoPage (AddTimeRecordAssistant assistant) {
					base (assistant);


					push_composite_child ();


					var label = new Label (_("Select the branch and time record information below."));
					label.wrap = true;
					label.xalign = 0.0f;
					this.add (label);
					label.show ();

					widget = new TimeRecordEditWidget (new TimeRecord (0, assistant.parent_window.app.database, null));
					widget.grid.get_child_at (0, 0).hide ();
					widget.employee_combobox.hide ();
					widget.start_spin.value_changed.connect (changed);
					widget.end_spin.value_changed.connect (changed);
					widget.open_end_check.toggled.connect (changed);
					this.add (widget);
					widget.show ();

					var branch_label = new Label.with_mnemonic (_("_Branch:"));
					branch_label.xalign = 0.0f;
					widget.grid.attach_next_to (branch_label,
					                            widget.grid.get_child_at (0, 0),
					                            PositionType.TOP,
					                            1, 1);
					branch_label.show ();

					branch_combobox = new ComboBox.with_model (assistant.parent_window.app.database.branch_list);
					branch_combobox.hexpand = true;
					branch_combobox.changed.connect (changed);
					widget.grid.attach_next_to (branch_combobox,
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


					/* Set default branch */
					TreeIter iter;
					Branch branch;

					if (branch_combobox.model.get_iter_first (out iter)) {
						branch_combobox.set_active_iter (iter);
						branch_combobox.model.get (iter, BranchList.Columns.OBJECT, out branch);
						list = assistant.parent_window.app.database.employee_list.get_subset_with_branch (branch);
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
						list = assistant.parent_window.app.database.employee_list.get_subset_with_branch (branch);
					} else {
						assistant.set_page_complete (this, false);
						return;
					}

					assistant.set_page_complete (this,
					                             widget.open_end_check.active ||
					                             widget.start_spin.get_date_time ().compare (widget.end_spin.get_date_time ()) < 0);
				}

			}

			public class SelectEmployeesPage : Page {

				public const string ACTION = "add-time-record-assistant-select-employees";
				public const string ACTION_INCLUDE_ALL = "add-time-record-assistant-select-employees-include-all";
				public const string ACTION_INCLUDE_NONE = "add-time-record-assistant-select-employees-include-none";

				public Gtk.ActionGroup action_group { public get; internal set; }

				public TreeView tree_view { public get; private set; }
				public TreeModelSort sort { public get; private set; }
				public EmployeeList list { public get; private set; }


				public SelectEmployeesPage (AddTimeRecordAssistant assistant) {
					base (assistant);


					action_group = new Gtk.ActionGroup (ACTION);
					assistant.ui_manager.insert_action_group (action_group, -1);


					push_composite_child ();


					var label = new Label (_("Select employees to get the desired time record."));
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
					tree_view.button_press_event.connect ((w, e) => {
										  /* Is not right-click? */
										  if (e.button != 3) {
											  return false;
										  }

										  return show_popup (3, e.time);
									  });
					tree_view.popup_menu.connect ((w) => {
										  return show_popup (0, get_current_event_time ());
									  });
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


					Gtk.ActionEntry[] actions = {
						Gtk.ActionEntry () {
							name = ACTION_INCLUDE_ALL,
							label = _("_Include All"),
							accelerator = _("<Primary>A"),
							tooltip = _("Include all employees"),
							callback = (a) => {
								list.set_is_enable_all (true);
							}
						},
						Gtk.ActionEntry () {
							name = ACTION_INCLUDE_NONE,
							label = _("_Uninclude All"),
							accelerator = _("<Shift><Primary>A"),
							tooltip = _("Don't include all employees"),
							callback = (a) => {
								list.set_is_enable_all (false);
							}
						}
					};

					this.action_group.add_actions (actions, this);
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

				private bool show_popup (uint button, uint32 time) {
					var menu = assistant.ui_manager.get_widget ("/popup-add-time-record-assistant-select-employees") as Gtk.Menu;
					menu.popup (null, null, null, button, time);
					return true;
				}

			}

			public class ConfirmPage : Page {

				public ConfirmPage (AddTimeRecordAssistant assistant) {
					base (assistant);


					push_composite_child ();


					var label = new Label (_("The Assistant is now ready to add the time records to the database.\n\nPress \"Apply\" to apply changes."));
					label.xalign = 0.0f;
					this.add (label);
					label.show ();


					pop_composite_child ();
				}

			}

			public class ApplyPage : Page {

				public ProgressBar progress_bar { get; private set; }

				public ApplyPage (AddTimeRecordAssistant assistant) {
					base (assistant);


					push_composite_child ();


					var label = new Label (_("Adding the time records to the database..."));
					label.xalign = 0.0f;
					this.add (label);
					label.show ();

					progress_bar = new ProgressBar ();
					progress_bar.ellipsize = EllipsizeMode.END;
					progress_bar.show_text = true;
					progress_bar.text = _("Please wait...");
					this.pack_end (progress_bar, true, false);
					progress_bar.show ();


					pop_composite_child ();
				}

				public override void prepare () {
					assistant.commit ();
				}

			}

			public class FinishPage : Page {

				public FinishPage (AddTimeRecordAssistant assistant) {
					base (assistant);


					push_composite_child ();


					var label = new Label (_("The time records are successfully added to database."));
					label.xalign = 0.0f;
					this.add (label);
					label.show ();


					pop_composite_child ();
				}

			}

		}

	}

}
