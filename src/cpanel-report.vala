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
using Gee;


namespace Mobilect {

	namespace Payroll {

		public class CPanelReport : CPanelTab {

			public const string ACTION = "cpanel-report";
			public const string ACTION_SELECT_FONT = "cpanel-report-select-font";
			public const string ACTION_PAGE_SETUP = "cpanel-report-page-setup";
			public const string ACTION_PRINT = "cpanel-report-print";
			public const string ACTION_PRINT_PREVIEW = "cpanel-report-print-preview";

			public EmployeeList list;

			public Grid grid { get; private set; }

			public ComboBoxText type_combo { get; private set; }
			public DateEntry start_entry { get; private set; }
			public DateEntry end_entry { get; private set; }
			public TreeView deduc_view { get; private set; }

			private FontDescription title_font = FontDescription.from_string ("Sans Bold 14");
			private FontDescription company_name_font = FontDescription.from_string ("Sans Bold 12");
			private FontDescription header_font = FontDescription.from_string ("Sans Bold 9");
			private FontDescription text_font = FontDescription.from_string ("Sans 9");
			private FontDescription number_font = FontDescription.from_string ("Monospace 9");
			private FontDescription emp_number_font = FontDescription.from_string ("Monospace Bold 9");

			private PageSetup page_setup;
			private PrintSettings settings;


			public enum Columns {
				ID,
				NAME,
				TAX,
				LOAN,
				PAG_IBIG,
				SSS_LOAN,
				VALE,
				MOESALA_LOAN,
				MOESALA_SAVINGS,
				NUM
			}


			public CPanelReport (CPanel cpanel) {
				base (cpanel, ACTION);

				this.changed_to.connect (() => {
					reload ();
				});

				page_setup = new PageSetup ();
				page_setup.set_orientation (PageOrientation.LANDSCAPE);
				page_setup.set_paper_size (new PaperSize (PAPER_NAME_LEGAL));

				grid = new Grid ();
				grid.orientation = Orientation.VERTICAL;
				grid.row_spacing = 3;
				grid.column_spacing = 12;
				this.add_with_viewport (grid);

				var type_label = new Label (_("_Type:"));
				type_label.use_underline = true;
				type_label.xalign = 0.0f;
				grid.add (type_label);

				type_combo = new ComboBoxText ();
				type_combo.append_text (_("Regular"));
				type_combo.append_text (_("Overtime"));
				type_combo.active = 0;
				grid.attach_next_to (type_combo,
				                     type_label,
				                     PositionType.RIGHT,
				                     2, 1);

				var period_label = new Label (_("_Period:"));
				period_label.use_underline = true;
				period_label.xalign = 0.0f;
				grid.add (period_label);

				start_entry = new DateEntry ();
				grid.attach_next_to (start_entry,
				                     period_label,
				                     PositionType.RIGHT,
				                     2, 1);

				end_entry = new DateEntry ();
				grid.attach_next_to (end_entry,
				                     start_entry,
				                     PositionType.BOTTOM,
				                     2, 1);

				var deduc_scroll = new ScrolledWindow (null, null);
				deduc_scroll.expand = true;
				grid.add_with_properties (deduc_scroll, width: 3);

				deduc_view = new TreeView ();
				deduc_scroll.add (deduc_view);

				CellRendererSpin renderer;
				TreeViewColumn column;

				column = new TreeViewColumn.with_attributes (_("Employee Name"),
				                                             new CellRendererText (),
				                                             "text", Columns.NAME,
				                                             null);
				column.expand = true;
				deduc_view.append_column (column);

				renderer = new CellRendererSpin ();
				renderer.adjustment = new Adjustment (0, 0, 999999,
				                                      1, 10, 0);
				renderer.editable = true;
				renderer.climb_rate = 1;
				renderer.digits = 2;
				renderer.edited.connect ((r, p, n) => {
					TreeIter iter;
					var deduc_store = deduc_view.model as ListStore;
					deduc_store.get_iter_from_string (out iter, p);
					deduc_store.set (iter, Columns.TAX, double.parse (n));
				});
				column = new TreeViewColumn ();
				column.title = _("Tax");
				column.expand = true;
				column.pack_start (renderer, true);
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, Columns.TAX, out value);
					(r as CellRendererText).text = "%.2lf".printf (value.get_double ());
				});
				deduc_view.append_column (column);

				renderer = new CellRendererSpin ();
				renderer.adjustment = new Adjustment (0, 0, 999999,
				                                      1, 10, 0);
				renderer.editable = true;
				renderer.climb_rate = 1;
				renderer.digits = 2;
				renderer.edited.connect ((r, p, n) => {
					TreeIter iter;
					var deduc_store = deduc_view.model as ListStore;
					deduc_store.get_iter_from_string (out iter, p);
					deduc_store.set (iter, Columns.LOAN, double.parse (n));
				});
				column = new TreeViewColumn ();
				column.title = _("Loan");
				column.expand = true;
				column.pack_start (renderer, true);
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, Columns.LOAN, out value);
					(r as CellRendererText).text = "%.2lf".printf (value.get_double ());
				});
				deduc_view.append_column (column);

				renderer = new CellRendererSpin ();
				renderer.adjustment = new Adjustment (0, 0, 999999,
				                                      1, 10, 0);
				renderer.editable = true;
				renderer.climb_rate = 1;
				renderer.digits = 2;
				renderer.edited.connect ((r, p, n) => {
					TreeIter iter;
					var deduc_store = deduc_view.model as ListStore;
					deduc_store.get_iter_from_string (out iter, p);
					deduc_store.set (iter, Columns.PAG_IBIG, double.parse (n));
				});
				column = new TreeViewColumn ();
				column.title = _("PAG-IBIG");
				column.expand = true;
				column.pack_start (renderer, true);
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, Columns.PAG_IBIG, out value);
					(r as CellRendererText).text = "%.2lf".printf (value.get_double ());
				});
				deduc_view.append_column (column);

				renderer = new CellRendererSpin ();
				renderer.adjustment = new Adjustment (0, 0, 999999,
				                                      1, 10, 0);
				renderer.editable = true;
				renderer.climb_rate = 1;
				renderer.digits = 2;
				renderer.edited.connect ((r, p, n) => {
					TreeIter iter;
					var deduc_store = deduc_view.model as ListStore;
					deduc_store.get_iter_from_string (out iter, p);
					deduc_store.set (iter, Columns.SSS_LOAN, double.parse (n));
				});
				column = new TreeViewColumn ();
				column.title = _("SSS Loan");
				column.expand = true;
				column.pack_start (renderer, true);
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, Columns.SSS_LOAN, out value);
					(r as CellRendererText).text = "%.2lf".printf (value.get_double ());
				});
				deduc_view.append_column (column);

				renderer = new CellRendererSpin ();
				renderer.adjustment = new Adjustment (0, 0, 999999,
				                                      1, 10, 0);
				renderer.editable = true;
				renderer.climb_rate = 1;
				renderer.digits = 2;
				renderer.edited.connect ((r, p, n) => {
					TreeIter iter;
					var deduc_store = deduc_view.model as ListStore;
					deduc_store.get_iter_from_string (out iter, p);
					deduc_store.set (iter, Columns.VALE, double.parse (n));
				});
				column = new TreeViewColumn ();
				column.title = _("Vale");
				column.expand = true;
				column.pack_start (renderer, true);
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, Columns.VALE, out value);
					(r as CellRendererText).text = "%.2lf".printf (value.get_double ());
				});
				deduc_view.append_column (column);

				renderer = new CellRendererSpin ();
				renderer.adjustment = new Adjustment (0, 0, 999999,
				                                      1, 10, 0);
				renderer.editable = true;
				renderer.climb_rate = 1;
				renderer.digits = 2;
				renderer.edited.connect ((r, p, n) => {
					TreeIter iter;
					var deduc_store = deduc_view.model as ListStore;
					deduc_store.get_iter_from_string (out iter, p);
					deduc_store.set (iter, Columns.MOESALA_LOAN, double.parse (n));
				});
				column = new TreeViewColumn ();
				column.title = _("Moesala Loan");
				column.expand = true;
				column.pack_start (renderer, true);
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, Columns.MOESALA_LOAN, out value);
					(r as CellRendererText).text = "%.2lf".printf (value.get_double ());
				});
				deduc_view.append_column (column);

				renderer = new CellRendererSpin ();
				renderer.adjustment = new Adjustment (0, 0, 999999,
				                                      1, 10, 0);
				renderer.editable = true;
				renderer.climb_rate = 1;
				renderer.digits = 2;
				renderer.edited.connect ((r, p, n) => {
					TreeIter iter;
					var deduc_store = deduc_view.model as ListStore;
					deduc_store.get_iter_from_string (out iter, p);
					deduc_store.set (iter, Columns.MOESALA_SAVINGS, double.parse (n));
				});
				column = new TreeViewColumn ();
				column.title = _("Moesala Savings");
				column.expand = true;
				column.pack_start (renderer, true);
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, Columns.MOESALA_SAVINGS, out value);
					(r as CellRendererText).text = "%.2lf".printf (value.get_double ());
				});
				deduc_view.append_column (column);

				ui_def =
					"<ui>" +
					"  <menubar name=\"menubar\">" +
					"    <placeholder name=\"MenuAdditions\">" +
					"      <placeholder name=\"CPanelMenuAdditions\">" +
					"        <menu name=\"CPanelReportMenu\" action=\"" + ACTION + "\">" +
					"          <menuitem name=\"SelectFontReport\" action=\"" + ACTION_SELECT_FONT + "\" />" +
					"          <menuitem name=\"PageSetupReport\" action=\"" + ACTION_PAGE_SETUP + "\" />" +
					"          <separator />" +
					"          <menuitem name=\"PrintReport\" action=\"" + ACTION_PRINT + "\" />" +
					"          <menuitem name=\"PrintPreviewReport\" action=\"" + ACTION_PRINT_PREVIEW + "\" />" +
					"        </menu>" +
					"      </placeholder>" +
					"    </placeholder>" +
					"  </menubar>" +
					"  <toolbar action=\"toolbar\">" +
					"    <placeholder name=\"ToolbarAdditions\">" +
					"      <placeholder name=\"CPanelToolItems\">" +
					"        <placeholder name=\"CPanelToolItemsAdditions\">" +
					"          <toolitem name=\"SelectFontReport\" action=\"" + ACTION_SELECT_FONT + "\" />" +
					"          <toolitem name=\"PageSetupReport\" action=\"" + ACTION_PAGE_SETUP + "\" />" +
					"          <separator />" +
					"          <toolitem name=\"PrintReport\" action=\"" + ACTION_PRINT + "\" />" +
					"          <toolitem name=\"PrintPreviewReport\" action=\"" + ACTION_PRINT_PREVIEW + "\" />" +
					"        </placeholder>" +
					"      </placeholder>" +
					"    </placeholder>" +
					"  </toolbar>" +
					"</ui>";

				Gtk.ActionEntry[] actions = {
					Gtk.ActionEntry () {
						name = ACTION,
						stock_id = null,
						label = _("_Report")
					},
					Gtk.ActionEntry () {
						name = ACTION_SELECT_FONT,
						stock_id = Stock.SELECT_FONT,
						label = _("Select _Fonts"),
						accelerator = _("<Control>F"),
						tooltip = _("Select fonts to use in the report"),
						callback = (a) => {
							var dialog = new Dialog.with_buttons (_("Select Fonts"),
							                                      this.cpanel.window,
							                                      DialogFlags.MODAL | DialogFlags.DESTROY_WITH_PARENT,
							                                      Stock.OK,
							                                      ResponseType.ACCEPT,
							                                      Stock.CANCEL,
							                                      ResponseType.REJECT);

							var content_area = dialog.get_content_area ();

							var sf_grid = new Grid ();
							sf_grid.orientation = Orientation.VERTICAL;
							sf_grid.row_spacing = 3;
							sf_grid.column_spacing = 12;
							content_area.add (sf_grid);

							var title_label = new Label (_("_Title:"));
							title_label.use_underline = true;
							title_label.xalign = 0.0f;
							sf_grid.add (title_label);

							var title_font_button = new FontButton ();
							title_font_button.font_desc = title_font;
							sf_grid.attach_next_to (title_font_button,
							                        title_label,
							                        PositionType.RIGHT,
							                        2, 1);

							var company_name_label = new Label (_("_Company Name:"));
							company_name_label.use_underline = true;
							company_name_label.xalign = 0.0f;
							sf_grid.add (company_name_label);

							var company_name_font_button = new FontButton ();
							company_name_font_button.font_desc = company_name_font;
							sf_grid.attach_next_to (company_name_font_button,
							                        company_name_label,
							                        PositionType.RIGHT,
							                        2, 1);

							var header_label = new Label (_("_Header:"));
							header_label.use_underline = true;
							header_label.xalign = 0.0f;
							sf_grid.add (header_label);

							var header_font_button = new FontButton ();
							header_font_button.font_desc = header_font;
							sf_grid.attach_next_to (header_font_button,
							                        header_label,
							                        PositionType.RIGHT,
							                        2, 1);

							var text_label = new Label (_("_Text:"));
							text_label.use_underline = true;
							text_label.xalign = 0.0f;
							sf_grid.add (text_label);

							var text_font_button = new FontButton ();
							text_font_button.font_desc = text_font;
							sf_grid.attach_next_to (text_font_button,
							                        text_label,
							                        PositionType.RIGHT,
							                        2, 1);

							var number_label = new Label (_("_Number:"));
							number_label.use_underline = true;
							number_label.xalign = 0.0f;
							sf_grid.add (number_label);

							var number_font_button = new FontButton ();
							number_font_button.font_desc = number_font;
							sf_grid.attach_next_to (number_font_button,
							                        number_label,
							                        PositionType.RIGHT,
							                        2, 1);

							var emp_number_label = new Label (_("_Emphasized Number:"));
							emp_number_label.use_underline = true;
							emp_number_label.xalign = 0.0f;
							sf_grid.add (emp_number_label);

							var emp_number_font_button = new FontButton ();
							emp_number_font_button.font_desc = emp_number_font;
							sf_grid.attach_next_to (emp_number_font_button,
							                        emp_number_label,
							                        PositionType.RIGHT,
							                        2, 1);

							dialog.show_all ();
							if (dialog.run () == ResponseType.ACCEPT) {
								title_font = title_font_button.get_font_desc ();
								company_name_font = company_name_font_button.get_font_desc ();
								header_font = header_font_button.get_font_desc ();
								text_font = text_font_button.get_font_desc ();
								number_font = number_font_button.get_font_desc ();
								emp_number_font = emp_number_font_button.get_font_desc ();
							}
							dialog.destroy ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_PAGE_SETUP,
						stock_id = Stock.PAGE_SETUP,
						label = _("Page _Setup"),
						accelerator = _("<Control>S"),
						tooltip = _("Customize the page size, orientation and margins"),
						callback = (a) => {
							if (settings == null) {
								settings = new PrintSettings ();
								settings.set_orientation (PageOrientation.LANDSCAPE);
								settings.set_paper_size (new PaperSize (PAPER_NAME_LEGAL));
							}

							var new_page_setup = print_run_page_setup_dialog (this.cpanel.window, page_setup, settings);
							page_setup = new_page_setup;
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_PRINT,
						stock_id = Stock.PRINT,
						label = _("_Print"),
						accelerator = _("<Control>P"),
						tooltip = _("Print payroll and payslips"),
						callback = (a) => {
							var pr = create_report ();

							try {
								pr.print_dialog (this.cpanel.window);
							} catch (Error e) {
								var e_dialog = new MessageDialog (this.cpanel.window,
								                                  DialogFlags.MODAL,
								                                  MessageType.ERROR,
								                                  ButtonsType.OK,
								                                  e.message);
								e_dialog.run ();
								e_dialog.destroy ();
							}

							settings = pr.print_settings;
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_PRINT_PREVIEW,
						stock_id = Stock.PRINT_PREVIEW,
						label = _("Print Previe_w"),
						accelerator = _("<Shift><Control>P"),
						tooltip = _("Print preview of payroll and payslips"),
						callback = (a) => {
							var pr = create_report ();

							try {
								pr.preview_dialog (this.cpanel.window);
							} catch (Error e) {
								var e_dialog = new MessageDialog (this.cpanel.window,
								                                  DialogFlags.MODAL,
								                                  MessageType.ERROR,
								                                  ButtonsType.OK,
								                                  e.message);
								e_dialog.run ();
								e_dialog.destroy ();
							}

							settings = pr.print_settings;
						}
					}
				};

				this.action_group.add_actions (actions, this);
			}

			private Report create_report () {
				var pr = new Report (start_entry.date, end_entry.date);
				pr.title = "SEMI-MONTHLY PAYROLL";
				pr.employees = this.cpanel.window.app.database.get_employees ();
				pr.default_page_setup = page_setup;
				pr.deductions = deduc_view.model as ListStore;

				if (settings != null) {
					pr.print_settings = settings;
				}

				return pr;
			}

			public void reload () {
				var deduc_store = new ListStore (Columns.NUM,
				                                 typeof (int),
				                                 typeof (string),
				                                 typeof (double),
				                                 typeof (double),
				                                 typeof (double),
				                                 typeof (double),
				                                 typeof (double),
				                                 typeof (double),
				                                 typeof (double));
				this.list = this.cpanel.window.app.database.get_employees ();
				for (int i = 0; i < list.size; i++) {
					var employee = (list as ArrayList<Employee>).get (i);
					deduc_store.insert_with_values (null, -1,
					                                Columns.NAME, employee.get_name (),
					                                Columns.ID, employee.id);
				}
				deduc_view.model = deduc_store;
			}

		}

	}

}
