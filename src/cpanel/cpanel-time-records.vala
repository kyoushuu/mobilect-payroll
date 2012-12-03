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


namespace Mobilect {

	namespace Payroll {

		public class CPanelTimeRecords : CPanelTab {

			public const string ACTION = "cpanel-time-records";
			public const string ACTION_ADD = "cpanel-time-records-add";
			public const string ACTION_ADD_MULTIPLE = "cpanel-time-records-add-multiple";
			public const string ACTION_REMOVE = "cpanel-time-records-remove";
			public const string ACTION_PROPERTIES = "cpanel-time-records-properties";
			public const string ACTION_SELECT_ALL = "cpanel-time-records-select-all";
			public const string ACTION_DESELECT_ALL = "cpanel-time-records-deselect-all";
			public const string ACTION_FIND = "cpanel-time-records-find";
			public const string ACTION_SORT_BY = "cpanel-time-records-sort-by";

			public TreeView tree_view { get; private set; }
			public TreeModelSort sort { get; private set; }
			public TimeRecordList list;


			public CPanelTimeRecords (CPanel cpanel) {
				base (cpanel, ACTION, "/com/mobilectpower/Payroll/mobilect-payroll-cpanel-time-records-ui.xml");


				push_composite_child ();


				var sw = new ScrolledWindow (null, null);
				this.add (sw);
				sw.show ();

				tree_view = new TreeView ();
				tree_view.expand = true;
				tree_view.get_selection ().mode = SelectionMode.MULTIPLE;
				tree_view.rubber_banding = true;
				tree_view.fixed_height_mode = true;
				tree_view.row_activated.connect ((t, p, c) => {
					properties_action ();
				});
				tree_view.set_search_equal_func ((m, c, k, i) => {
					Value value;
					m.get_value (i, c, out value);
					return (value as Employee).get_name ().has_prefix (k) == false;
				});
				tree_view.button_press_event.connect ((w, e) => {
					/* Is not right-click? */
					if (e.button != 3) {
						return false;
					}

					/* Get cell in coordinate */
					TreePath path;
					if (!tree_view.get_path_at_pos ((int) e.x, (int) e.y, out path,
					                                null, null, null)) {
						return false;
					}

					/* Is cell selected */
					var selection = tree_view.get_selection ();
					if (!selection.path_is_selected (path)) {
						selection.unselect_all ();
						selection.select_path (path);
					}

					/* Show popup on cell under mouse */
					return show_popup (3, e.time);
				});
				tree_view.popup_menu.connect ((w) => {
					return show_popup (0, get_current_event_time ());
				});
				sw.add (tree_view);
				tree_view.show ();

				TreeViewColumn column;
				CellRendererText renderer;

				renderer = new CellRendererText ();
				renderer.ellipsize = EllipsizeMode.END;
				column = new TreeViewColumn.with_attributes (_("Employee"), renderer);
				column.sort_column_id = TimeRecordList.Columns.EMPLOYEE;
				column.sizing = TreeViewColumnSizing.FIXED;
				column.fixed_width = 150;
				column.expand = true;
				column.reorderable = true;
				column.resizable = true;
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					TreeIter iter;
					(m as TreeModelSort).convert_iter_to_child_iter (out iter, i);
					(r as CellRendererText).text = list.get_from_iter (iter).employee.get_name ();
				});
				tree_view.append_column (column);

				renderer = new CellRendererText ();
				renderer.ellipsize = EllipsizeMode.END;
				column = new TreeViewColumn.with_attributes (_("Start Date"), renderer);
				column.sort_column_id = TimeRecordList.Columns.START;
				column.sizing = TreeViewColumnSizing.FIXED;
				column.fixed_width = 200;
				column.reorderable = true;
				column.resizable = true;
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					TreeIter iter;
					(m as TreeModelSort).convert_iter_to_child_iter (out iter, i);
					(r as CellRendererText).text = list.get_from_iter (iter).start.format (_("%a, %d %b, %Y %I:%M %p"));
				});
				tree_view.append_column (column);

				renderer = new CellRendererText ();
				renderer.ellipsize = EllipsizeMode.END;
				column = new TreeViewColumn.with_attributes (_("End Date"), renderer);
				column.sort_column_id = TimeRecordList.Columns.END;
				column.sizing = TreeViewColumnSizing.FIXED;
				column.fixed_width = 200;
				column.reorderable = true;
				column.resizable = true;
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					TreeIter iter;
					(m as TreeModelSort).convert_iter_to_child_iter (out iter, i);
					var dt = list.get_from_iter (iter).end;
					(r as CellRendererText).text = (dt != null)? dt.format (_("%a, %d %b, %Y %I:%M %p")) : _("Open");
				});
				tree_view.append_column (column);

				column = new TreeViewColumn.with_attributes (_("Straight Time"), new CellRendererToggle (),
				                                             "active", TimeRecordList.Columns.STRAIGHT_TIME);
				column.sort_column_id = TimeRecordList.Columns.STRAIGHT_TIME;
				column.sizing = TreeViewColumnSizing.FIXED;
				column.fixed_width = 50;
				column.reorderable = true;
				column.resizable = true;
				tree_view.append_column (column);

				column = new TreeViewColumn.with_attributes (_("Include Break"), new CellRendererToggle (),
				                                             "active", TimeRecordList.Columns.INCLUDE_BREAK);
				column.sort_column_id = TimeRecordList.Columns.INCLUDE_BREAK;
				column.sizing = TreeViewColumnSizing.FIXED;
				column.fixed_width = 50;
				column.reorderable = true;
				column.resizable = true;
				tree_view.append_column (column);


				pop_composite_child ();


				Gtk.ActionEntry[] actions = {
					Gtk.ActionEntry () {
						name = ACTION_ADD,
						stock_id = Stock.ADD,
						accelerator = _("<Primary>I"),
						tooltip = _("Add a time record to database"),
						callback = (a) => {
							add_action ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_ADD_MULTIPLE,
						label = _("_Add Multiple"),
						accelerator = _("<Shift><Primary>I"),
						tooltip = _("Add a set of time records to database"),
						callback = (a) => {
							add_multiple_action ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_REMOVE,
						stock_id = Stock.REMOVE,
						accelerator = _("Delete"),
						tooltip = _("Remove the selected time records from database"),
						callback = (a) => {
							remove_action ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_PROPERTIES,
						stock_id = Stock.PROPERTIES,
						accelerator = _("<Alt>Return"),
						tooltip = _("Edit information about the selected time records"),
						callback = (a) => {
							properties_action ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_SELECT_ALL,
						stock_id = Stock.SELECT_ALL,
						accelerator = _("<Primary>A"),
						tooltip = _("Select all time records"),
						callback = (a) => {
							tree_view.get_selection ().select_all ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_DESELECT_ALL,
						label = _("_Deselect All"),
						accelerator = _("<Shift><Primary>A"),
						tooltip = _("Deselects all selected time records"),
						callback = (a) => {
							tree_view.get_selection ().unselect_all ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_FIND,
						stock_id = Stock.FIND,
						accelerator = _("<Primary>F"),
						tooltip = _("Find time records"),
						callback = (a) => {
							/* Set period */
							Date start, end;
							get_current_period (out start, out end);

							var dialog = new FindTimeRecordDialog (this.cpanel.window);
							dialog.set_dates (start, end);

							dialog.response.connect ((d, r) => {
								if (r == ResponseType.ACCEPT) {
									d.hide ();

									TreeIter iter;

									Branch branch = null;
									if (dialog.branch_check.active && dialog.branch_combobox.get_active_iter (out iter)) {
										dialog.branch_combobox.get_active_iter (out iter); /* NOTE: Vala bug */
										branch = (dialog.branch_combobox.model as BranchList).get_from_iter (iter);
									}

									Employee employee = null;
									if (dialog.employee_check.sensitive && dialog.employee_check.active && dialog.employee_combobox.get_active_iter (out iter)) {
										dialog.employee_combobox.get_active_iter (out iter); /* NOTE: Vala bug */
										employee = (dialog.employee_combobox.model as EmployeeList).get_from_iter (iter);
									}

									update (dialog.get_start_date (), dialog.get_end_date (), branch, employee);

									d.destroy ();
								} else if (r == ResponseType.REJECT) {
									d.destroy ();
								}
							});
							dialog.show ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_SORT_BY,
						label = _("_Sort By..."),
						tooltip = _("Sort the view using a column"),
						callback = (a) => {
							var dialog = new SortTreeViewDialog (this.cpanel.window,
							                                     tree_view);
							dialog.response.connect ((d, r) => {
								if (r == ResponseType.ACCEPT ||
								    r == ResponseType.REJECT) {
									d.destroy ();
								}
							});
							dialog.show ();
						}
					}
				};

				this.action_group.add_actions (actions, this);
				this.action_group.get_action (ACTION_ADD).is_important = true;
				this.action_group.get_action (ACTION_REMOVE).sensitive = false;
				this.action_group.get_action (ACTION_PROPERTIES).sensitive = false;
				tree_view.get_selection ().changed.connect ((s) => {
					var selected = tree_view.get_selection ().count_selected_rows () > 0;
					this.action_group.get_action (ACTION_REMOVE).sensitive = selected;
					this.action_group.get_action (ACTION_PROPERTIES).sensitive = selected;
				});


				/* Set period */
				var date = new DateTime.now_local ().add_days (-12);
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


				Date start = Date (), end = Date ();
				start.set_dmy ((15 * period) + 1, date.get_month (), (DateYear) date.get_year ());
				end.set_dmy (last_day, date.get_month (), (DateYear) date.get_year ());
				update (start, end);
			}


			private GLib.List<TimeRecord> get_selected (TreeSelection selection) {
				var time_records = new GLib.List<TimeRecord>();

				foreach (var p in selection.get_selected_rows (null)) {
					TreePath path;
					TreeIter iter;

					path = sort.convert_path_to_child_path (p);
					list.get_iter (out iter, path);
					time_records.append (this.list.get_from_iter (iter));
				}

				return time_records;
			}

			private void add_action () {
				var database = this.cpanel.window.app.database;
				var time_record = new TimeRecord (0, database, null);

				var dialog = new TimeRecordEditDialog (_("Add Time Record"),
				                                       this.cpanel.window,
				                                       time_record);
				dialog.help_link_id = "time-records-add";
				dialog.action = Stock.ADD;
				dialog.response.connect ((d, r) => {
					if (r == ResponseType.ACCEPT) {
						if (time_record.employee == null) {
							this.cpanel.window.show_error_dialog (dialog,
							                                      _("No employee selected"),
							                                      _("Select at least one employee first."));

							return;
						}

						dialog.hide ();

						try {
							database.add_time_record (time_record.employee_id,
							                          time_record.start,
							                          time_record.end,
							                          time_record.straight_time,
							                          time_record.include_break);

							dialog.destroy ();
						} catch (Error e) {
							(dialog.transient_for as Window).show_error_dialog (dialog, _("Failed to add time record"), e.message);
						}
					} else if (r == ResponseType.REJECT) {
						dialog.destroy ();
					}
				});
				dialog.show ();
			}

			private void add_multiple_action () {
				var assistant = new AddTimeRecordAssistant (this.cpanel.window);
				assistant.cancel.connect ((assistant) => {
					assistant.destroy ();
				});
				assistant.close.connect ((assistant) => {
					assistant.destroy ();
				});
				assistant.show ();
			}

			private void remove_action () {
				var selection = tree_view.get_selection ();
				var time_records = get_selected (selection);

				int selected_count = selection.count_selected_rows ();
				if (selected_count < 1) {
					return;
				}

				var dialog = new MessageDialog (this.cpanel.window,
				                                DialogFlags.MODAL,
				                                MessageType.WARNING,
				                                ButtonsType.NONE,
				                                ngettext ("Are you sure you want to remove the selected time record?",
				                                          "Are you sure you want to remove the %d selected time records?",
				                                          selected_count).printf (selected_count));
				dialog.secondary_text = ngettext ("All information about this time record will be deleted and cannot be restored.",
				                                  "All information about these time records will be deleted and cannot be restored.",
				                                  selected_count);
				dialog.add_buttons (Stock.CANCEL, ResponseType.REJECT,
				                    Stock.DELETE, ResponseType.ACCEPT);
				dialog.set_alternative_button_order (ResponseType.ACCEPT, ResponseType.REJECT);

				if (dialog.run () == ResponseType.ACCEPT) {
					dialog.hide ();
					foreach (var time_record in time_records) {
						time_record.remove ();
					};
				}

				dialog.destroy ();
			}

			private void properties_action () {
				var selection = tree_view.get_selection ();
				var time_records = get_selected (selection);

				foreach (var time_record in time_records) {
					var dialog = new TimeRecordEditDialog (_("Time Record Properties"),
					                                       this.cpanel.window,
					                                       time_record);
					dialog.help_link_id = "time-records-edit";
					dialog.action = Stock.SAVE;
					dialog.response.connect ((d, r) => {
						if (r == ResponseType.ACCEPT) {
							foreach (var t in time_record.database.get_time_records_of_employee (time_record.employee)) {
								if (t.id == time_record.id) {
									continue;
								}

								/* Check if the time records overlap */
								if (t.end.compare (time_record.start) > 0 &&
								    t.start.compare (time_record.end) < 0) {
									this.cpanel.window.show_error_dialog (dialog,
									                                      _("Cannot save time record"),
									                                      _("Conflict with another time record:\nEmployee Name: %s\nStart: %s\nEnd: %s")
									                                      .printf (t.employee.get_name (),
									                                               t.start.format (_("%a, %d %b, %Y %I:%M %p")),
									                                               t.end.format (_("%a, %d %b, %Y %I:%M %p"))));

									time_record.pull ();

									return;
								}
							}

							dialog.hide ();
							dialog.time_record.update ();
							dialog.destroy ();
						} else if (r == ResponseType.REJECT) {
							dialog.destroy ();
						}
					});

					dialog.show ();
				}
			}

			private bool show_popup (uint button, uint32 time) {
				/* Check if a row is selected */
				if (tree_view.get_selection ().count_selected_rows () < 1) {
					return false;
				}

				var menu = cpanel.window.ui_manager.get_widget ("/popup-time-records") as Gtk.Menu;
				menu.popup (null, null, null, button, time);

				return true;
			}

			public void update (Date start, Date end, Branch? branch = null, Employee? employee = null) {
				this.list = this.cpanel.window.app.database.get_time_records_within_date (start, end);

				if (employee != null) {
					this.list = this.list.get_subset_with_employee (employee);
				} else if (branch != null) {
					this.list = this.list.get_subset_with_branch (branch);
				}

				this.sort = new TreeModelSort.with_model (this.list);
				sort.set_sort_func (TimeRecordList.Columns.EMPLOYEE, (model, a, b) => {
					var time_record1 = a.user_data as TimeRecord;
					var time_record2 = b.user_data as TimeRecord;

					return strcmp (time_record1.employee.get_name (),
					               time_record2.employee.get_name ());
				});
				sort.set_sort_func (TimeRecordList.Columns.START, (model, a, b) => {
					var time_record1 = a.user_data as TimeRecord;
					var time_record2 = b.user_data as TimeRecord;

					return time_record1.start.compare (time_record2.start);
				});
				sort.set_sort_func (TimeRecordList.Columns.END, (model, a, b) => {
					var time_record1 = a.user_data as TimeRecord;
					var time_record2 = b.user_data as TimeRecord;

					if (time_record1.end != null && time_record2.end != null) {
						return time_record1.end.compare (time_record2.end);
					} else if (time_record1.end != null) {
						return 1;
					} else if (time_record2.end != null) {
						return -1;
					} else {
						return 0;
					}
				});
				sort.set_sort_func (TimeRecordList.Columns.STRAIGHT_TIME, (model, a, b) => {
					var time_record1 = a.user_data as TimeRecord;
					var time_record2 = b.user_data as TimeRecord;

					if (time_record1.straight_time == time_record2.straight_time) {
						return 0;
					} else if (time_record1.straight_time) {
						return 1;
					} else {
						return -1;
					}
				});
				sort.set_sort_func (TimeRecordList.Columns.INCLUDE_BREAK, (model, a, b) => {
					var time_record1 = a.user_data as TimeRecord;
					var time_record2 = b.user_data as TimeRecord;

					if (time_record1.include_break == time_record2.include_break) {
						return 0;
					} else if (time_record1.include_break) {
						return 1;
					} else {
						return -1;
					}
				});
				this.tree_view.model = sort;
				tree_view.search_column = (int) TimeRecordList.Columns.EMPLOYEE;
			}

		}

	}

}
