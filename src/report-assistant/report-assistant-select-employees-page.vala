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


namespace Mobilect {

	namespace Payroll {

		public class ReportAssistantSelectEmployeesPage : ReportAssistantPage {

			public const string ACTION = "report-assistant-select-employees";
			public const string ACTION_INCLUDE_ALL = "report-assistant-select-employees-include-all";
			public const string ACTION_INCLUDE_NONE = "report-assistant-select-employees-include-none";

			public Gtk.ActionGroup action_group { get; internal set; }

			public TreeView tree_view { get; private set; }
			public TreeModelSort sort { get; private set; }
			public EmployeeList list;


			public ReportAssistantSelectEmployeesPage (ReportAssistant assistant) {
				base (assistant);


				action_group = new Gtk.ActionGroup (ACTION);
				assistant.ui_manager.insert_action_group (action_group, -1);


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
				list = (assistant.get_nth_page (ReportAssistant.Pages.BASIC_INFO) as ReportAssistantBasicInfoPage).list;

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
				var menu = assistant.ui_manager.get_widget ("/popup-report-assistant-select-employees") as Gtk.Menu;
				menu.popup (null, null, null, button, time);
				return true;
			}

		}

	}

}
