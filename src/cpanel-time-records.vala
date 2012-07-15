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

			public DateEntry start_entry { get; private set; }
			public DateEntry end_entry { get; private set; }
			public TreeView tree_view { get; private set; }
			public Spinner search_spinner { get; private set; }
			public Button search_button { get; private set; }
			public TimeRecordList list;

			public const string ACTION = "cpanel-time-records";
			public const string ACTION_ADD = "cpanel-time-records-add";
			public const string ACTION_REMOVE = "cpanel-time-records-remove";
			public const string ACTION_EDIT = "cpanel-time-records-edit";

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
					edit ();
				});
				sw.add (tree_view);

				TreeViewColumn column;

				column = new TreeViewColumn.with_attributes (_("Employee"),
				                                             new CellRendererText (),
				                                             "text", TimeRecordList.Columns.EMPLOYEE_STRING,
				                                             null);
				tree_view.append_column (column);

				column = new TreeViewColumn.with_attributes (_("Start Date"),
				                                             new CellRendererText (),
				                                             "text", TimeRecordList.Columns.START_STRING,
				                                             null);
				tree_view.append_column (column);

				column = new TreeViewColumn.with_attributes (_("End Date"),
				                                             new CellRendererText (),
				                                             "text", TimeRecordList.Columns.END_STRING,
				                                             null);
				tree_view.append_column (column);


				var date_label = new Label (_("_Date:"));
				date_label.use_underline = true;
				hbox.add (date_label);

				start_entry = new DateEntry ();
				hbox.add (start_entry);

				var to_label = new Label (_("_to"));
				to_label.use_underline = true;
				hbox.add (to_label);

				end_entry = new DateEntry ();
				hbox.add (end_entry);

				search_button = new Button.with_mnemonic (_("_Search"));
				search_button.clicked.connect ((b) => {
					search_spinner.show ();
					search_spinner.start ();

					this.list = null;
					this.tree_view.model = null;

					this.list = this.cpanel.window.app.database.get_time_records_within_date (start_entry.get_date (), end_entry.get_date ());
					this.tree_view.model = this.list;

					search_spinner.stop ();
					search_spinner.hide ();
				});
				hbox.add (search_button);

				search_spinner = new Spinner ();
				search_spinner.no_show_all = true;
				hbox.add (search_spinner);


				ui_def =
					"<ui>" +
					"  <menubar name=\"menubar\">" +
					"    <placeholder name=\"MenuAdditions\">" +
					"      <placeholder name=\"CPanelMenuAdditions\">" +
					"        <menu name=\"CPanelTimeRecordsMenu\" action=\"" + ACTION + "\">" +
					"          <menuitem name=\"AddTimeRecord\" action=\"" + ACTION_ADD + "\" />" +
					"          <menuitem name=\"RemoveTimeRecord\" action=\"" + ACTION_REMOVE + "\" />" +
					"          <separator />" +
					"          <menuitem name=\"EditTimeRecord\" action=\"" + ACTION_EDIT + "\" />" +
					"        </menu>" +
					"      </placeholder>" +
					"    </placeholder>" +
					"  </menubar>" +
					"  <toolbar action=\"toolbar\">" +
					"    <placeholder name=\"ToolbarAdditions\">" +
					"      <placeholder name=\"CPanelToolItems\">" +
					"        <placeholder name=\"CPanelToolItemsAdditions\">" +
					"          <toolitem name=\"AddTimeRecord\" action=\"" + ACTION_ADD + "\" />" +
					"          <toolitem name=\"RemoveTimeRecord\" action=\"" + ACTION_REMOVE + "\" />" +
					"          <toolitem name=\"EditTimeRecord\" action=\"" + ACTION_EDIT + "\" />" +
					"        </placeholder>" +
					"      </placeholder>" +
					"    </placeholder>" +
					"  </toolbar>" +
					"</ui>";

				Gtk.ActionEntry[] actions = {
					Gtk.ActionEntry () {
						name = ACTION,
						stock_id = null,
						label = _("_Time Records")
					},
					Gtk.ActionEntry () {
						name = ACTION_ADD,
						stock_id = Stock.ADD,
						label = _("_Add"),
						accelerator = _("<Control>plus"),
						tooltip = _("Add a time record to database"),
						callback = (a) => {
							var database = this.cpanel.window.app.database;
							var time_record = new TimeRecord (0, database, null);

							var dialog = new TimeRecordEditDialog (_("Add Time Record"),
							                                       this.cpanel.window,
							                                       time_record);
							dialog.response.connect((d, r) => {
								if (r == ResponseType.ACCEPT) {
									if (time_record.employee == null) {
										var e_dialog = new MessageDialog (this.cpanel.window,
										                                  DialogFlags.MODAL,
										                                  MessageType.ERROR,
										                                  ButtonsType.OK,
										                                  _("No employee selected."));
										e_dialog.run ();
										e_dialog.destroy ();

										return;
									}

									try {
										database.add_time_record (time_record.employee_id,
										                          time_record.start,
										                          time_record.end);
									} catch (ApplicationError e) {
										var e_dialog = new MessageDialog (this.cpanel.window, DialogFlags.DESTROY_WITH_PARENT,
										                                  MessageType.ERROR, ButtonsType.CLOSE,
										                                  _("Error: %s"), e.message);
										e_dialog.run ();
										e_dialog.destroy ();
									}

									this.list = null;
									this.tree_view.model = null;

								}

								d.destroy ();
							});
							dialog.show_all ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_REMOVE,
						stock_id = Stock.REMOVE,
						label = _("_Remove"),
						accelerator = _("<Control>minus"),
						tooltip = _("Remove the selected time records from database"),
						callback = (a) => {
							var selection = tree_view.get_selection ();
							int selected_count = selection.count_selected_rows ();

							if (selected_count <= 0) {
								var e_dialog = new MessageDialog (this.cpanel.window,
								                                  DialogFlags.MODAL,
								                                  MessageType.ERROR,
								                                  ButtonsType.OK,
								                                  _("No time record selected."));
								e_dialog.run ();
								e_dialog.destroy ();

								return;
							}

							var m_dialog = new MessageDialog (this.cpanel.window,
							                                  DialogFlags.MODAL,
							                                  MessageType.INFO,
							                                  ButtonsType.YES_NO,
							                                  ngettext("Are you sure you want to remove the selected time record?",
							                                           "Are you sure you want to remove the %d selected time records?",
							                                           selected_count).printf (selected_count) + " " +
							                                  _("The changes will be permanent."));

							if (m_dialog.run () == ResponseType.YES) {
								selection.selected_foreach ((m, p, i) => {
									TimeRecord time_record;
									this.list.get (i, TimeRecordList.Columns.OBJECT, out time_record);
									try {
										time_record.remove ();
									} catch (ApplicationError e) {
										var e_dialog = new MessageDialog (this.cpanel.window, DialogFlags.DESTROY_WITH_PARENT,
										                                  MessageType.ERROR, ButtonsType.CLOSE,
										                                  _("Error: %s"), e.message);
										e_dialog.run ();
										e_dialog.destroy ();
									}
								});
								this.list = null;
								this.tree_view.model = null;
							}

							m_dialog.destroy ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_EDIT,
						stock_id = Stock.EDIT,
						label = _("_Edit"),
						accelerator = _("<Control>E"),
						tooltip = _("Edit information about the selected time records"),
						callback = (a) => {
							edit ();
						}
					}
				};

				this.action_group.add_actions (actions, this);
				this.action_group.get_action (ACTION_REMOVE).sensitive = false;
				this.action_group.get_action (ACTION_EDIT).sensitive = false;
				tree_view.get_selection ().changed.connect ((s) => {
					var selected = tree_view.get_selection ().count_selected_rows () > 0;
					this.action_group.get_action (ACTION_REMOVE).sensitive = selected;
					this.action_group.get_action (ACTION_EDIT).sensitive = selected;
				});
			}

			public void edit () {
				var selection = tree_view.get_selection ();
				int selected_count = selection.count_selected_rows ();

				if (selected_count <= 0) {
					var e_dialog = new MessageDialog (this.cpanel.window,
					                                  DialogFlags.MODAL,
					                                  MessageType.ERROR,
					                                  ButtonsType.OK,
					                                  _("No time record selected."));
					e_dialog.run ();
					e_dialog.destroy ();

					return;
				}

				selection.selected_foreach ((m, p, i) => {
					TimeRecord time_record;
					this.list.get (i, TimeRecordList.Columns.OBJECT, out time_record);

					var dialog = new TimeRecordEditDialog (_("Time Record Properties"),
					                                       this.cpanel.window,
					                                       time_record);
					dialog.response.connect ((d, r) => {
						if (r == ResponseType.ACCEPT) {
							try {
								dialog.time_record.update ();
							} catch (Error e) {
								stderr.printf (_("Error: %s\n"), e.message);
							}

							this.list = null;
							this.tree_view.model = null;
						}

						d.destroy ();
					});

					dialog.show_all ();
				});
			}

		}

	}

}
