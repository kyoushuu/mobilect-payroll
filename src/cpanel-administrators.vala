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
				tree_view.row_activated.connect ((t, p, c) => {
					edit ();
				});
				this.add (tree_view);

				var column = new TreeViewColumn.with_attributes (_("Username"),
				                                                 new CellRendererText (),
				                                                 "text", AdministratorList.Columns.NAME,
				                                                 null);
				tree_view.append_column (column);

				reload ();


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
						accelerator = _("<Control>A"),
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
															              _("Error: %s"), e.message);
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
						accelerator = _("<Control>R"),
						tooltip = _("Remove the selected administrator from database"),
						callback = (a) => {
							TreeIter iter;
							Administrator administrator;

							if (tree_view.get_selection ().get_selected (null, out iter)) {
								this.list.get (iter, AdministratorList.Columns.OBJECT, out administrator);
								var m_dialog = new MessageDialog (this.cpanel.window,
								                                  DialogFlags.MODAL,
								                                  MessageType.INFO,
								                                  ButtonsType.YES_NO,
								                                  _("Are you sure you want to remove the selected administrator? The changes will be permanent."));

								if (m_dialog.run () == ResponseType.YES) {
									try {
										administrator.remove ();
									} catch (ApplicationError e) {
										var e_dialog = new MessageDialog (this.cpanel.window, DialogFlags.DESTROY_WITH_PARENT,
															              MessageType.ERROR, ButtonsType.CLOSE,
															              _("Error: %s"), e.message);
										e_dialog.run ();
										e_dialog.destroy ();
									}

									reload ();
								}

								m_dialog.destroy ();
							} else {
								var e_dialog = new MessageDialog (this.cpanel.window,
								                                  DialogFlags.MODAL,
								                                  MessageType.ERROR,
								                                  ButtonsType.OK,
								                                  _("No administrator selected."));
								e_dialog.run ();
								e_dialog.destroy ();
							}
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_EDIT,
						stock_id = Stock.EDIT,
						label = _("_Edit"),
						accelerator = _("<Control>E"),
						tooltip = _("Edit information about the selected administrator"),
						callback = (a) => {
							edit ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_PASSWORD,
						stock_id = Stock.PROPERTIES,
						label = _("_Change Password"),
						tooltip = _("Change password of selected administrator"),
						callback = (a) => {
							TreeIter iter;
							Administrator administrator;

							if (tree_view.get_selection ().get_selected (null, out iter)) {
								this.list.get (iter, AdministratorList.Columns.OBJECT, out administrator);
								var dialog = new PasswordDialog (_("Change Administrator Password"),
									                              this.cpanel.window);

								dialog.response.connect((d, r) => {
									if (r == ResponseType.ACCEPT) {
										var password = dialog.widget.get_password ();

										if (password != null) {
											try {
												administrator.change_password (password);
											} catch (ApplicationError e) {
												var e_dialog = new MessageDialog (this.cpanel.window, DialogFlags.DESTROY_WITH_PARENT,
																			      MessageType.ERROR, ButtonsType.CLOSE,
																			      _("Error: %s"), e.message);
												e_dialog.run ();
												e_dialog.destroy ();
											}
										} else {
											return;
										}
									}

									d.destroy ();
								});
								dialog.show_all ();
							} else {
								var e_dialog = new MessageDialog (this.cpanel.window,
								                                  DialogFlags.MODAL,
								                                  MessageType.ERROR,
								                                  ButtonsType.OK,
								                                  _("No administrator selected."));
								e_dialog.run ();
								e_dialog.destroy ();
							}
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
				Administrator administrator;

				if (tree_view.get_selection ().get_selected (null, out iter)) {
					this.list.get (iter, AdministratorList.Columns.OBJECT, out administrator);

					var dialog = new AdministratorEditDialog (_("Administrator \"%s\" Properties").printf (administrator.username),
					                                          this.cpanel.window,
					                                          administrator);
					dialog.response.connect ((d, r) => {
						if (r == ResponseType.ACCEPT) {
							try {
								dialog.administrator.update ();
							} catch (Error e) {
								stderr.printf ("Error: %s\n", e.message);
							}

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
					                                  _("No administrator selected."));
					e_dialog.run ();
					e_dialog.destroy ();
				}
			}

			public void reload () {
				this.list = this.cpanel.window.app.database.get_administrators ();
				this.tree_view.model = this.list ;
			}

		}

	}

}
