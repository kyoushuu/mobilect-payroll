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

		public class CPanelAdministrators : CPanelTab {

			public TreeView tree_view { get; private set; }
			public AdministratorList list;

			public const string ACTION = "cpanel-administrators";
			public const string ACTION_ADD = "cpanel-administrators-add";
			public const string ACTION_REMOVE = "cpanel-administrators-remove";
			public const string ACTION_EDIT = "cpanel-administrators-edit";
			public const string ACTION_PASSWORD = "cpanel-administrators-password";

			public CPanelAdministrators (CPanel cpanel) {
				base (cpanel, ACTION);

				this.changed_to.connect (() => {
					reload ();
				});

				tree_view = new TreeView ();
				tree_view.get_selection ().mode = SelectionMode.MULTIPLE;
				tree_view.rubber_banding = true;
				tree_view.row_activated.connect ((t, p, c) => {
					edit ();
				});
				this.add (tree_view);

				var column = new TreeViewColumn.with_attributes (_("Username"),
				                                                 new CellRendererText (),
				                                                 "text", AdministratorList.Columns.NAME,
				                                                 null);
				tree_view.append_column (column);


				ui_def =
					"<ui>" +
					"  <menubar name=\"menubar\">" +
					"    <placeholder name=\"MenuAdditions\">" +
					"      <placeholder name=\"CPanelMenuAdditions\">" +
					"        <menu name=\"CPanelAdministratorsMenu\" action=\"" + ACTION + "\">" +
					"          <menuitem name=\"AddAdministrator\" action=\"" + ACTION_ADD + "\" />" +
					"          <menuitem name=\"RemoveAdministrator\" action=\"" + ACTION_REMOVE + "\" />" +
					"          <separator />" +
					"          <menuitem name=\"EditAdministrator\" action=\"" + ACTION_EDIT + "\" />" +
					"          <menuitem name=\"PasswordAdministrator\" action=\"" + ACTION_PASSWORD + "\" />" +
					"        </menu>" +
					"      </placeholder>" +
					"    </placeholder>" +
					"  </menubar>" +
					"  <toolbar action=\"toolbar\">" +
					"    <placeholder name=\"ToolbarAdditions\">" +
					"      <placeholder name=\"CPanelToolItems\">" +
					"        <placeholder name=\"CPanelToolItemsAdditions\">" +
					"          <toolitem name=\"AddAdministrator\" action=\"" + ACTION_ADD + "\" />" +
					"          <toolitem name=\"RemoveAdministrator\" action=\"" + ACTION_REMOVE + "\" />" +
					"          <toolitem name=\"EditAdministrator\" action=\"" + ACTION_EDIT + "\" />" +
					"          <toolitem name=\"PasswordAdministrator\" action=\"" + ACTION_PASSWORD + "\" />" +
					"        </placeholder>" +
					"      </placeholder>" +
					"    </placeholder>" +
					"  </toolbar>" +
					"</ui>";

				Gtk.ActionEntry[] actions = {
					Gtk.ActionEntry () {
						name = ACTION,
						stock_id = null,
						label = _("_Administrators")
					},
					Gtk.ActionEntry () {
						name = ACTION_ADD,
						stock_id = Stock.ADD,
						label = _("_Add"),
						accelerator = _("<Control>plus"),
						tooltip = _("Add an administrator to database"),
						callback = (a) => {
							var administrator = new Administrator (0, list.database);

							var dialog = new AdministratorEditDialog (_("Add Administrator"),
							                                          this.cpanel.window,
							                                          administrator);

							var password_label = new Label (_("_Password:"));
							password_label.use_underline = true;
							password_label.xalign = 0.0f;
							dialog.widget.grid.add (password_label);

							var password_entry = new Entry ();
							password_entry.hexpand = true;
							password_entry.activates_default = true;
							password_entry.visibility = false;
							dialog.widget.grid.attach_next_to (password_entry,
							                                   password_label,
							                                   PositionType.RIGHT,
							                                   2, 1);

							dialog.response.connect((d, r) => {
								if (r == ResponseType.ACCEPT) {
									try {
										this.list.database.add_administrator (administrator.username,
										                                      password_entry.text);
									} catch (ApplicationError e) {
										var e_dialog = new MessageDialog (this.cpanel.window, DialogFlags.DESTROY_WITH_PARENT,
															              MessageType.ERROR, ButtonsType.CLOSE,
															              _("Failed to add administrator."));
										e_dialog.secondary_text = e.message;
										e_dialog.run ();
										e_dialog.destroy ();
									}

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
						label = _("_Remove"),
						accelerator = _("<Control>minus"),
						tooltip = _("Remove the selected administrators from database"),
						callback = (a) => {
							var selection = tree_view.get_selection ();
							int selected_count = selection.count_selected_rows ();

							if (selected_count <= 0) {
								var e_dialog = new MessageDialog (this.cpanel.window,
								                                  DialogFlags.MODAL,
								                                  MessageType.ERROR,
								                                  ButtonsType.OK,
								                                  _("No administrator selected."));
								e_dialog.secondary_text = _("Select atleast one administrator first.");
								e_dialog.run ();
								e_dialog.destroy ();

								return;
							}

							if (this.list.size - selected_count < 1) {
								var e_dialog = new MessageDialog (this.cpanel.window,
								                                  DialogFlags.MODAL,
								                                  MessageType.ERROR,
								                                  ButtonsType.OK,
								                                  ngettext("Can't remove selected administrator.",
								                                           "Can't remove selected administrators.",
								                                           selected_count));
								e_dialog.secondary_text = _("There should be atleast one administrator.");
								e_dialog.run ();
								e_dialog.destroy ();

								return;
							}

							var m_dialog = new MessageDialog (this.cpanel.window,
							                                  DialogFlags.MODAL,
							                                  MessageType.INFO,
							                                  ButtonsType.YES_NO,
							                                  ngettext("Are you sure you want to remove the selected administrator?",
							                                           "Are you sure you want to remove the %d selected administrators?",
							                                           selected_count).printf (selected_count));
							m_dialog.secondary_text = _("The changes will be permanent.");

							if (m_dialog.run () == ResponseType.YES) {
								selection.selected_foreach ((m, p, i) => {
									Administrator administrator;
									this.list.get (i, AdministratorList.Columns.OBJECT, out administrator);
									try {
										administrator.remove ();
									} catch (ApplicationError e) {
										var e_dialog = new MessageDialog (this.cpanel.window, DialogFlags.DESTROY_WITH_PARENT,
										                                  MessageType.ERROR, ButtonsType.CLOSE,
										                                  ngettext("Failed to remove selected administrator.",
										                                           "Failed to remove selected administrators.",
										                                           selected_count));
										e_dialog.secondary_text = e.message;
										e_dialog.run ();
										e_dialog.destroy ();
									}
								});
								reload ();
							}

							m_dialog.destroy ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_EDIT,
						stock_id = Stock.EDIT,
						label = _("_Edit"),
						accelerator = _("<Control>E"),
						tooltip = _("Edit information about the selected administrators"),
						callback = (a) => {
							edit ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_PASSWORD,
						stock_id = Stock.PROPERTIES,
						label = _("_Change Password"),
						tooltip = _("Change password of selected administrators"),
						callback = (a) => {
							var selection = tree_view.get_selection ();
							int selected_count = selection.count_selected_rows ();

							if (selected_count <= 0) {
								var e_dialog = new MessageDialog (this.cpanel.window,
								                                  DialogFlags.MODAL,
								                                  MessageType.ERROR,
								                                  ButtonsType.OK,
								                                  _("No administrator selected."));
								e_dialog.secondary_text = _("Select atleast one administrator first.");
								e_dialog.run ();
								e_dialog.destroy ();

								return;
							}

							selection.selected_foreach ((m, p, i) => {
								Administrator administrator;
								this.list.get (i, AdministratorList.Columns.OBJECT, out administrator);

								var dialog = new PasswordDialog (_("Change Administrator Password"),
								                                 this.cpanel.window);

								dialog.response.connect((d, r) => {
									if (r == ResponseType.ACCEPT) {
										var password = dialog.widget.get_password ();

										if (password == null) {
											var e_dialog = new MessageDialog (this.cpanel.window, DialogFlags.DESTROY_WITH_PARENT,
											                                  MessageType.ERROR, ButtonsType.CLOSE,
											                                  _("Failed to change password."));
											e_dialog.secondary_text = _("Passwords didn't match.");
											e_dialog.run ();
											e_dialog.destroy ();

											return;
										}

										try {
											administrator.change_password (password);
										} catch (ApplicationError e) {
											var e_dialog = new MessageDialog (this.cpanel.window, DialogFlags.DESTROY_WITH_PARENT,
											                                  MessageType.ERROR, ButtonsType.CLOSE,
											                                  _("Failed to change password."));
											e_dialog.secondary_text = e.message;
											e_dialog.run ();
											e_dialog.destroy ();
										}
									}

									d.destroy ();
								});
								dialog.show_all ();
							});
						}
					}
				};

				this.action_group.add_actions (actions, this);
				this.action_group.get_action (ACTION_REMOVE).sensitive = false;
				this.action_group.get_action (ACTION_EDIT).sensitive = false;
				this.action_group.get_action (ACTION_PASSWORD).sensitive = false;
				tree_view.get_selection ().changed.connect ((s) => {
					var selected = tree_view.get_selection ().count_selected_rows () > 0;
					this.action_group.get_action (ACTION_REMOVE).sensitive = selected;
					this.action_group.get_action (ACTION_EDIT).sensitive = selected;
					this.action_group.get_action (ACTION_PASSWORD).sensitive = selected;
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
					                                  _("No administrator selected."));
					e_dialog.secondary_text = _("Select atleast one administrator first.");
					e_dialog.run ();
					e_dialog.destroy ();

					return;
				}

				selection.selected_foreach ((m, p, i) => {
					Administrator administrator;
					this.list.get (i, AdministratorList.Columns.OBJECT, out administrator);

					var dialog = new AdministratorEditDialog (_("Administrator \"%s\" Properties").printf (administrator.username),
					                                          this.cpanel.window,
					                                          administrator);
					dialog.response.connect ((d, r) => {
						if (r == ResponseType.ACCEPT) {
							try {
								dialog.administrator.update ();
							} catch (Error e) {
								stderr.printf (_("Error: %s\n"), e.message);
							}

							reload ();
						}

						d.destroy ();
					});
					dialog.show_all ();
				});
			}

			public void reload () {
				this.list = this.cpanel.window.app.database.get_administrators ();
				this.tree_view.model = this.list ;
			}

		}

	}

}
