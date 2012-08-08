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


namespace Mobilect {

	namespace Payroll {

		public class CPanelTimeRecords : CPanelTab {

			public const string ACTION = "cpanel-time-records";
			public const string ACTION_ADD = "cpanel-time-records-add";
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


				tree_view = new TreeView ();
				tree_view.get_selection ().mode = SelectionMode.MULTIPLE;
				tree_view.rubber_banding = true;
				tree_view.row_activated.connect ((t, p, c) => {
					properties_action ();
				});
				tree_view.button_press_event.connect ((w, e) => {
					/* Is not right-click? */
					if (e.button != 3) {
						return false;
					}

					return show_popup (3, e.time);
				});
				tree_view.key_press_event.connect ((w, e) => {
					/* Has key modifier or not menu key? */
					if (e.state != 0 || e.keyval != Key.Menu) {
						return false;
					}

					return show_popup (0, e.time);
				});
				this.add (tree_view);
				tree_view.show ();

				TreeViewColumn column;
				CellRendererText renderer;

				renderer = new CellRendererText ();
				column = new TreeViewColumn.with_attributes (_("Employee"), renderer);
				column.sort_column_id = TimeRecordList.Columns.EMPLOYEE;
				column.expand = true;
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, TimeRecordList.Columns.EMPLOYEE, out value);
					(r as CellRendererText).text = (value as Employee).get_name ();
				});
				tree_view.append_column (column);

				renderer = new CellRendererText ();
				column = new TreeViewColumn.with_attributes (_("Start Date"), renderer);
				column.sort_column_id = TimeRecordList.Columns.START;
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, TimeRecordList.Columns.START, out value);
					(r as CellRendererText).text = ((DateTime) value).format (_("%a, %d %B, %Y %I:%M %p"));
				});
				tree_view.append_column (column);

				renderer = new CellRendererText ();
				column = new TreeViewColumn.with_attributes (_("End Date"), renderer);
				column.sort_column_id = TimeRecordList.Columns.END;
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, TimeRecordList.Columns.END, out value);
					var dt = ((DateTime) value);
					if (dt != null) {
						(r as CellRendererText).text = dt.format (_("%a, %d %B, %Y %I:%M %p"));
					} else {
						(r as CellRendererText).text = _("Open");
					}
				});
				tree_view.append_column (column);


				pop_composite_child ();


				Gtk.ActionEntry[] actions = {
					Gtk.ActionEntry () {
						name = ACTION_ADD,
						stock_id = Stock.ADD,
						accelerator = _("<Control>I"),
						tooltip = _("Add a time record to database"),
						callback = (a) => {
							add_action ();
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
						accelerator = _("<Control>A"),
						tooltip = _("Select all time records"),
						callback = (a) => {
							tree_view.get_selection ().select_all ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_DESELECT_ALL,
						label = _("_Deselect All"),
						accelerator = _("<Shift><Control>A"),
						tooltip = _("Deselects all selected time records"),
						callback = (a) => {
							tree_view.get_selection ().unselect_all ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_FIND,
						stock_id = Stock.FIND,
						accelerator = _("<Control>F"),
						tooltip = _("Find time records"),
						callback = (a) => {
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


							var dialog = new FindDialog (_("Find"), this.cpanel.window);
							dialog.set_start_dmy ((15 * period) + 1, date.get_month (), date.get_year ());
							dialog.set_end_dmy (last_day, date.get_month (), date.get_year ());

							if (dialog.run () == ResponseType.ACCEPT) {
								dialog.hide ();

								this.list = this.cpanel.window.app.database.get_time_records_within_date (dialog.get_start_date (), dialog.get_end_date ());

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
								this.tree_view.model = sort;
							}

							dialog.destroy ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_SORT_BY,
						label = _("_Sort By..."),
						tooltip = _("Sort the view using a column"),
						callback = (a) => {
							var dialog = new SortTreeViewDialog (this.cpanel.window,
							                                     tree_view);
							dialog.run ();
							dialog.destroy ();
						}
					}
				};

				this.action_group.add_actions (actions, this);
				this.action_group.get_action (ACTION_REMOVE).sensitive = false;
				this.action_group.get_action (ACTION_PROPERTIES).sensitive = false;
				tree_view.get_selection ().changed.connect ((s) => {
					var selected = tree_view.get_selection ().count_selected_rows () > 0;
					this.action_group.get_action (ACTION_REMOVE).sensitive = selected;
					this.action_group.get_action (ACTION_PROPERTIES).sensitive = selected;
				});
			}


			private GLib.List<TimeRecord> get_selected (TreeSelection selection) {
				var time_records = new GLib.List<TimeRecord>();

				foreach (var p in selection.get_selected_rows (null)) {
					TimeRecord time_record;
					TreePath path;
					TreeIter iter;

					path = sort.convert_path_to_child_path (p);
					list.get_iter (out iter, path);
					this.list.get (iter, TimeRecordList.Columns.OBJECT, out time_record);
					time_records.append (time_record);
				}

				return time_records;
			}

			private void add_action () {
				var database = this.cpanel.window.app.database;
				var time_record = new TimeRecord (0, database, null);

				var dialog = new TimeRecordEditDialog (_("Add Time Record"),
				                                       this.cpanel.window,
				                                       time_record);
				dialog.response.connect ((d, r) => {
					d.hide ();

					if (r == ResponseType.ACCEPT) {
						if (time_record.employee == null) {
							this.cpanel.window.show_error_dialog (_("No employee selected"),
							                                      _("Select at least one employee first."));

							return;
						}

						database.add_time_record (time_record.employee_id,
						                          time_record.start,
						                          time_record.end);
					}

					d.destroy ();
				});
				dialog.show ();
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

				if (dialog.run () == ResponseType.ACCEPT) {
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
					dialog.response.connect ((d, r) => {
						d.hide ();

						if (r == ResponseType.ACCEPT) {
							dialog.time_record.update ();
						}

						d.destroy ();
					});

					dialog.show ();
				}
			}

			private bool show_popup (uint button, uint32 time) {
				/* Has any selected rows? */
				if (tree_view.get_selection ().count_selected_rows () <= 0) {
					return false;
				}

				var menu = cpanel.window.ui_manager.get_widget ("/popup-time-records") as Gtk.Menu;
				menu.popup (null, null, null, button, time);
				return true;
			}

		}

	}

}
