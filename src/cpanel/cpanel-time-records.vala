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

		public class CPanelTimeRecords : CPanelTab {

			public DateSpinButton start_spin { get; private set; }
			public DateSpinButton end_spin { get; private set; }
			public TreeView tree_view { get; private set; }
			public TreeModelSort sort { get; private set; }
			public Spinner search_spinner { get; private set; }
			public Button search_button { get; private set; }
			public TimeRecordList list;

			public const string ACTION = "cpanel-time-records";
			public const string ACTION_ADD = "cpanel-time-records-add";
			public const string ACTION_REMOVE = "cpanel-time-records-remove";
			public const string ACTION_PROPERTIES = "cpanel-time-records-properties";


			public CPanelTimeRecords (CPanel cpanel) {
				base (cpanel, ACTION);


				var vbox = new Box (Orientation.VERTICAL, 3);
				this.add_with_viewport (vbox);

				var hbox = new Box (Orientation.HORIZONTAL, 3);
				vbox.add (hbox);

				var sw = new ScrolledWindow (null, null);
				vbox.pack_start (sw, true, true, 0);

				tree_view = new TreeView ();
				tree_view.get_selection ().mode = SelectionMode.MULTIPLE;
				tree_view.rubber_banding = true;
				tree_view.row_activated.connect ((t, p, c) => {
					edit_action ();
				});
				sw.add (tree_view);

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


				var date_label = new Label (_("_Date:"));
				date_label.use_underline = true;
				hbox.add (date_label);

				start_spin = new DateSpinButton ();
				hbox.add (start_spin);

				var to_label = new Label (_("_to"));
				to_label.use_underline = true;
				hbox.add (to_label);

				end_spin = new DateSpinButton ();
				hbox.add (end_spin);

				search_button = new Button.with_mnemonic (_("_Search"));
				search_button.clicked.connect ((b) => {
					search_spinner.show ();
					search_spinner.start ();

					this.list = this.cpanel.window.app.database.get_time_records_within_date (start_spin.date, end_spin.date);

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

					search_spinner.stop ();
					search_spinner.hide ();
				});
				hbox.add (search_button);

				search_spinner = new Spinner ();
				search_spinner.no_show_all = true;
				hbox.add (search_spinner);


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


				ui_def =
					"<ui>" +
					"  <menubar name=\"menubar\">" +
					"    <menu name=\"EditMenu\" action=\"edit\">" +
					"      <placeholder name=\"EditMenuAdditions\">" +
					"        <menuitem name=\"AddTimeRecord\" action=\"" + ACTION_ADD + "\" />" +
					"        <menuitem name=\"RemoveTimeRecord\" action=\"" + ACTION_REMOVE + "\" />" +
					"        <separator />" +
					"        <menuitem name=\"PropertiesTimeRecord\" action=\"" + ACTION_PROPERTIES + "\" />" +
					"      </placeholder>" +
					"    </menu>" +
					"  </menubar>" +
					"  <toolbar action=\"toolbar\">" +
					"    <placeholder name=\"EditToolbarAdditions\">" +
					"      <toolitem name=\"AddTimeRecord\" action=\"" + ACTION_ADD + "\" />" +
					"      <toolitem name=\"RemoveTimeRecord\" action=\"" + ACTION_REMOVE + "\" />" +
					"      <toolitem name=\"PropertiesTimeRecord\" action=\"" + ACTION_PROPERTIES + "\" />" +
					"    </placeholder>" +
					"  </toolbar>" +
					"</ui>";

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
							edit_action ();
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

				int selected_count = selection.count_selected_rows ();
				if (selected_count <= 0) {
					this.cpanel.window.show_error_dialog (_("No time record selected"),
					                                      _("Select at least one time record first."));

					return time_records;
				}

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
				dialog.show_all ();
			}

			private void remove_action () {
				var selection = tree_view.get_selection ();
				var time_records = get_selected (selection);

				int selected_count = selection.count_selected_rows ();
				if (selected_count < 1) {
					return;
				}

				var m_dialog = new MessageDialog (this.cpanel.window,
				                                  DialogFlags.MODAL,
				                                  MessageType.WARNING,
				                                  ButtonsType.NONE,
				                                  ngettext ("Are you sure you want to remove the selected time record?",
				                                            "Are you sure you want to remove the %d selected time records?",
				                                            selected_count).printf (selected_count));
				m_dialog.secondary_text = ngettext ("All information about this time record will be deleted and cannot be restored.",
				                                    "All information about these time records will be deleted and cannot be restored.",
				                                    selected_count);
				m_dialog.add_buttons (Stock.CANCEL, ResponseType.REJECT,
				                      Stock.DELETE, ResponseType.ACCEPT);

				if (m_dialog.run () == ResponseType.ACCEPT) {
					foreach (var time_record in time_records) {
						time_record.remove ();
					};
				}

				m_dialog.destroy ();
			}

			private void edit_action () {
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

					dialog.show_all ();
				}
			}

		}

	}

}
