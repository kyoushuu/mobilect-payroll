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

			public TreeView tree_view { get; private set; }
			public TimeRecordList list;

			public const string ACTION = "cpanel-time-records";
			public const string ACTION_ADD = "cpanel-time-records-add";
			public const string ACTION_REMOVE = "cpanel-time-records-remove";
			public const string ACTION_EDIT = "cpanel-time-records-edit";

			public CPanelTimeRecords (CPanel cpanel) {
				base (cpanel, "cpanel-time-records");

				this.changed_to.connect (() => {
					reload ();
				});

				tree_view = new TreeView ();
				tree_view.row_activated.connect ((t, p, c) => {
					edit ();
				});
				this.add (tree_view);

				TreeViewColumn column;

				column = new TreeViewColumn.with_attributes ("Employee",
				                                             new CellRendererText (),
				                                             "text", TimeRecordList.Columns.EMPLOYEE_STRING,
				                                             null);
				tree_view.append_column (column);

				column = new TreeViewColumn.with_attributes ("Start Date",
				                                             new CellRendererText (),
				                                             "text", TimeRecordList.Columns.START_STRING,
				                                             null);
				tree_view.append_column (column);

				column = new TreeViewColumn.with_attributes ("End Date",
				                                             new CellRendererText (),
				                                             "text", TimeRecordList.Columns.END_STRING,
				                                             null);
				tree_view.append_column (column);

				reload ();


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
						label = "_Time Records"
					},
					Gtk.ActionEntry () {
						name = ACTION_ADD,
						stock_id = Stock.ADD,
						label = "_Add Time Record",
						accelerator = "<Control>A",
						tooltip = "Add an time record to database",
						callback = (a) => {
							var time_record = new TimeRecord (0);
							time_record.database = list.database;

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

									this.list.database.add_time_record (time_record.employee_id,
									                                    time_record.start,
									                                    time_record.end);
									reload ();
								}

								d.destroy ();
							});
							dialog.show_all ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_REMOVE,
						stock_id = Stock.REMOVE,
						label = "_Remove Time Record",
						accelerator = "<Control>R",
						tooltip = "Remove the selected time record from database",
						callback = (a) => {
							TreeIter iter;
							TimeRecord time_record;

							if (tree_view.get_selection ().get_selected (null, out iter)) {
								this.list.get (iter, TimeRecordList.Columns.OBJECT, out time_record);
								var m_dialog = new MessageDialog (this.cpanel.window,
								                                  DialogFlags.MODAL,
								                                  MessageType.INFO,
								                                  ButtonsType.YES_NO,
								                                  _("Are you sure you want to remove the selected time record? The changes will be permanent."));

								if (m_dialog.run () == ResponseType.YES) {
									time_record.remove ();
									reload ();
								}

								m_dialog.destroy ();
							} else {
								var e_dialog = new MessageDialog (this.cpanel.window,
								                                  DialogFlags.MODAL,
								                                  MessageType.ERROR,
								                                  ButtonsType.OK,
								                                  _("No time record selected."));
								e_dialog.run ();
								e_dialog.destroy ();
							}
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_EDIT,
						stock_id = Stock.EDIT,
						label = "_Edit Time Record",
						accelerator = "<Control>E",
						tooltip = "Edit information about the selected time record",
						callback = (a) => {
							edit ();
						}
					}
				};

				this.action_group.add_actions (actions, this);
				tree_view.get_selection ().changed.connect ((s) => {
					var selected = tree_view.get_selection ().get_selected (null, null);
					this.action_group.get_action (ACTION_REMOVE).sensitive = selected;
					this.action_group.get_action (ACTION_EDIT).sensitive = selected;
				});
			}

			public void edit () {
				TreeIter iter;
				TimeRecord time_record;

				if (tree_view.get_selection ().get_selected (null, out iter)) {
					this.list.get (iter, TimeRecordList.Columns.OBJECT, out time_record);

					var dialog = new TimeRecordEditDialog (_("Time Record Properties"),
					                                       this.cpanel.window,
					                                       time_record);
					dialog.response.connect ((d, r) => {
						if (r == ResponseType.ACCEPT) {
							dialog.time_record.update ();
							reload ();
						}

						d.destroy ();
					});
					dialog.show_all ();
				} else {
					var e_dialog = new MessageDialog (this.cpanel.window,
					                                  DialogFlags.MODAL,
					                                  MessageType.ERROR,
					                                  ButtonsType.OK,
					                                  _("No time record selected."));
					e_dialog.run ();
					e_dialog.destroy ();
				}
			}

			public void reload () {
				try {
					this.list = this.cpanel.window.app.database.get_time_records ();
					this.tree_view.model = this.list;
				} catch (Error e) {
					var m_dialog = new MessageDialog (this.cpanel.window, DialogFlags.DESTROY_WITH_PARENT,
					                                  MessageType.ERROR, ButtonsType.CLOSE,
					                                  _("Error: %s"), e.message);
					m_dialog.run ();
					m_dialog.destroy ();
				}
			}

		}

	}

}
