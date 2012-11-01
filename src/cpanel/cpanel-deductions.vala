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

		public class CPanelDeductions : CPanelTab {

			public const string ACTION = "cpanel-deductions";
			public const string ACTION_SORT_BY = "cpanel-deductions-sort-by";
			public const string ACTION_REFRESH = "cpanel-deductions-refresh";

			public PeriodSpinButton period_spin { get; private set; }
			public TreeView tree_view { get; private set; }
			public TreeModelSort sort { get; private set; }

			public Deductions deduction { get; private set; }


			public CPanelDeductions (CPanel cpanel) {
				base (cpanel, ACTION, "/com/mobilectpower/Payroll/mobilect-payroll-cpanel-deductions-ui.xml");


				push_composite_child ();


				var vbox = new Box (Orientation.VERTICAL, 3);
				this.add (vbox);
				vbox.show ();

				var hbox = new Box (Orientation.HORIZONTAL, 3);
				hbox.border_width = 6;
				vbox.add (hbox);
				hbox.show ();

				var sw = new ScrolledWindow (null, null);
				vbox.add (sw);
				sw.show ();

				tree_view = new TreeView ();
				tree_view.expand = true;
				tree_view.set_search_equal_func ((m, c, k, i) => {
					Value value;
					m.get_value (i, c, out value);
					return (value as Employee).get_name ().has_prefix (k) == false;
				});
				sw.add (tree_view);
				tree_view.show ();

				TreeViewColumn column;
				CellRendererText renderer;
				CellRendererSpin renderer_spin;

				var adjustment = new Adjustment (0, 0, 999999,
				                                 1, 10, 0);

				renderer = new CellRendererText ();
				column = new TreeViewColumn.with_attributes (_("Employee"), renderer);
				column.expand = true;
				column.reorderable = true;
				column.resizable = true;
				column.sort_column_id = Deductions.Columns.EMPLOYEE;
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, Deductions.Columns.EMPLOYEE, out value);
					(r as CellRendererText).text = (value as Employee).get_name ();
				});
				tree_view.append_column (column);

				renderer_spin = new CellRendererSpin ();
				renderer_spin.adjustment = adjustment;
				renderer_spin.editable = true;
				renderer_spin.climb_rate = 10;
				renderer_spin.digits = 2;
				renderer_spin.xalign = 1;
				renderer_spin.edited.connect ((r, p, n) => {
					render_spin_edited (p, n, Deductions.Category.TAX);
				});
				column = new TreeViewColumn.with_attributes (_("Tax / SSS"), renderer_spin);
				column.min_width = 100;
				column.reorderable = true;
				column.resizable = true;
				column.sort_column_id = Deductions.Columns.NUM + Deductions.Category.TAX;
				column.set_cell_data_func (renderer_spin, (c, r, m, i) => {
					Value value;
					m.get_value (i, Deductions.Columns.NUM + Deductions.Category.TAX, out value);
					(r as CellRendererText).text = "%.2lf".printf ((double) value);
				});
				tree_view.append_column (column);

				renderer_spin = new CellRendererSpin ();
				renderer_spin.adjustment = adjustment;
				renderer_spin.editable = true;
				renderer_spin.climb_rate = 10;
				renderer_spin.digits = 2;
				renderer_spin.xalign = 1;
				renderer_spin.edited.connect ((r, p, n) => {
					render_spin_edited (p, n, Deductions.Category.LOAN);
				});
				column = new TreeViewColumn.with_attributes (_("Loan"), renderer_spin);
				column.min_width = 100;
				column.reorderable = true;
				column.resizable = true;
				column.sort_column_id = Deductions.Columns.NUM + Deductions.Category.LOAN;
				column.set_cell_data_func (renderer_spin, (c, r, m, i) => {
					Value value;
					m.get_value (i, Deductions.Columns.NUM + Deductions.Category.LOAN, out value);
					(r as CellRendererText).text = "%.2lf".printf ((double) value);
				});
				tree_view.append_column (column);

				renderer_spin = new CellRendererSpin ();
				renderer_spin.adjustment = adjustment;
				renderer_spin.editable = true;
				renderer_spin.climb_rate = 10;
				renderer_spin.digits = 2;
				renderer_spin.xalign = 1;
				renderer_spin.edited.connect ((r, p, n) => {
					render_spin_edited (p, n, Deductions.Category.PAG_IBIG);
				});
				column = new TreeViewColumn.with_attributes (_("PAG-IBIG / PH"), renderer_spin);
				column.min_width = 100;
				column.reorderable = true;
				column.resizable = true;
				column.sort_column_id = Deductions.Columns.NUM + Deductions.Category.PAG_IBIG;
				column.set_cell_data_func (renderer_spin, (c, r, m, i) => {
					Value value;
					m.get_value (i, Deductions.Columns.NUM + Deductions.Category.PAG_IBIG, out value);
					(r as CellRendererText).text = "%.2lf".printf ((double) value);
				});
				tree_view.append_column (column);

				renderer_spin = new CellRendererSpin ();
				renderer_spin.adjustment = adjustment;
				renderer_spin.editable = true;
				renderer_spin.climb_rate = 10;
				renderer_spin.digits = 2;
				renderer_spin.xalign = 1;
				renderer_spin.edited.connect ((r, p, n) => {
					render_spin_edited (p, n, Deductions.Category.SSS_LOAN);
				});
				column = new TreeViewColumn.with_attributes (_("SSS Loan"), renderer_spin);
				column.min_width = 100;
				column.reorderable = true;
				column.resizable = true;
				column.sort_column_id = Deductions.Columns.NUM + Deductions.Category.SSS_LOAN;
				column.set_cell_data_func (renderer_spin, (c, r, m, i) => {
					Value value;
					m.get_value (i, Deductions.Columns.NUM + Deductions.Category.SSS_LOAN, out value);
					(r as CellRendererText).text = "%.2lf".printf ((double) value);
				});
				tree_view.append_column (column);

				renderer_spin = new CellRendererSpin ();
				renderer_spin.adjustment = adjustment;
				renderer_spin.editable = true;
				renderer_spin.climb_rate = 10;
				renderer_spin.digits = 2;
				renderer_spin.xalign = 1;
				renderer_spin.edited.connect ((r, p, n) => {
					render_spin_edited (p, n, Deductions.Category.VALE);
				});
				column = new TreeViewColumn.with_attributes (_("Vale"), renderer_spin);
				column.min_width = 100;
				column.reorderable = true;
				column.resizable = true;
				column.sort_column_id = Deductions.Columns.NUM + Deductions.Category.VALE;
				column.set_cell_data_func (renderer_spin, (c, r, m, i) => {
					Value value;
					m.get_value (i, Deductions.Columns.NUM + Deductions.Category.VALE, out value);
					(r as CellRendererText).text = "%.2lf".printf ((double) value);
				});
				tree_view.append_column (column);

				renderer_spin = new CellRendererSpin ();
				renderer_spin.adjustment = adjustment;
				renderer_spin.editable = true;
				renderer_spin.climb_rate = 10;
				renderer_spin.digits = 2;
				renderer_spin.xalign = 1;
				renderer_spin.edited.connect ((r, p, n) => {
					render_spin_edited (p, n, Deductions.Category.MOESALA_LOAN);
				});
				column = new TreeViewColumn.with_attributes (_("Moesala Loan"), renderer_spin);
				column.min_width = 100;
				column.reorderable = true;
				column.resizable = true;
				column.sort_column_id = Deductions.Columns.NUM + Deductions.Category.MOESALA_LOAN;
				column.set_cell_data_func (renderer_spin, (c, r, m, i) => {
					Value value;
					m.get_value (i, Deductions.Columns.NUM + Deductions.Category.MOESALA_LOAN, out value);
					(r as CellRendererText).text = "%.2lf".printf ((double) value);
				});
				tree_view.append_column (column);

				renderer_spin = new CellRendererSpin ();
				renderer_spin.adjustment = adjustment;
				renderer_spin.editable = true;
				renderer_spin.climb_rate = 10;
				renderer_spin.digits = 2;
				renderer_spin.xalign = 1;
				renderer_spin.edited.connect ((r, p, n) => {
					render_spin_edited (p, n, Deductions.Category.MOESALA_SAVINGS);
				});
				column = new TreeViewColumn.with_attributes (_("Moesala Savings"), renderer_spin);
				column.min_width = 100;
				column.reorderable = true;
				column.resizable = true;
				column.sort_column_id = Deductions.Columns.NUM + Deductions.Category.MOESALA_SAVINGS;
				column.set_cell_data_func (renderer_spin, (c, r, m, i) => {
					Value value;
					m.get_value (i, Deductions.Columns.NUM + Deductions.Category.MOESALA_SAVINGS, out value);
					(r as CellRendererText).text = "%.2lf".printf ((double) value);
				});
				tree_view.append_column (column);


				var period_label = new Label.with_mnemonic (_("_Period:"));
				hbox.add (period_label);
				period_label.show ();


				period_spin = new PeriodSpinButton ();
				period_spin.value_changed.connect ((s) => {
					update ();
				});
				hbox.add (period_spin);
				period_label.mnemonic_widget = period_spin;
				period_spin.show ();


				pop_composite_child ();


				Gtk.ActionEntry[] actions = {
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
					},
					Gtk.ActionEntry () {
						name = ACTION_REFRESH,
						stock_id = Stock.REFRESH,
						accelerator = _("<Primary>R"),
						tooltip = _("Reload information from database"),
						callback = (a) => {
							update ();
						}
					}
				};

				this.action_group.add_actions (actions, this);


				var dt = new DateTime.now_local ().add_days (-12);
				period_spin.set_dmy (dt.get_day_of_month (), dt.get_month (), dt.get_year ());
			}

			private void render_spin_edited (string path, string new_text, Deductions.Category category) {
				TreeIter iter, iterSort;
				Value value;
				sort.get_iter_from_string (out iterSort, path);
				sort.convert_iter_to_child_iter (out iter, iterSort);
				deduction.get_value (iter, Deductions.Columns.EMPLOYEE, out value);
				deduction.set_deduction_with_category (value as Employee, category, double.parse (new_text));
			}

			public void update () {
				deduction = new Deductions (this.cpanel.window.app.database,
				                           (int) period_spin.period);

				sort = new TreeModelSort.with_model (deduction);
				sort.set_sort_func (Deductions.Columns.EMPLOYEE, (model, a, b) => {
					Value employee1, employee2;
					model.get_value (a, Deductions.Columns.EMPLOYEE, out employee1);
					model.get_value (b, Deductions.Columns.EMPLOYEE, out employee2);

					return strcmp ((employee1 as Employee).get_name (),
					               (employee2 as Employee).get_name ());
				});
				sort.set_sort_func (Deductions.Columns.NUM + Deductions.Category.TAX, (model, a, b) => {
					Value value1, value2;
					var column = Deductions.Columns.NUM + Deductions.Category.TAX;
					model.get_value (a, column, out value1);
					model.get_value (b, column, out value2);

					return (int) Math.round ((double) value1 - (double) value2);
				});
				sort.set_sort_func (Deductions.Columns.NUM + Deductions.Category.LOAN, (model, a, b) => {
					Value value1, value2;
					var column = Deductions.Columns.NUM + Deductions.Category.LOAN;
					model.get_value (a, column, out value1);
					model.get_value (b, column, out value2);

					return (int) Math.round ((double) value1 - (double) value2);
				});
				sort.set_sort_func (Deductions.Columns.NUM + Deductions.Category.PAG_IBIG, (model, a, b) => {
					Value value1, value2;
					var column = Deductions.Columns.NUM + Deductions.Category.PAG_IBIG;
					model.get_value (a, column, out value1);
					model.get_value (b, column, out value2);

					return (int) Math.round ((double) value1 - (double) value2);
				});
				sort.set_sort_func (Deductions.Columns.NUM + Deductions.Category.SSS_LOAN, (model, a, b) => {
					Value value1, value2;
					var column = Deductions.Columns.NUM + Deductions.Category.SSS_LOAN;
					model.get_value (a, column, out value1);
					model.get_value (b, column, out value2);

					return (int) Math.round ((double) value1 - (double) value2);
				});
				sort.set_sort_func (Deductions.Columns.NUM + Deductions.Category.VALE, (model, a, b) => {
					Value value1, value2;
					var column = Deductions.Columns.NUM + Deductions.Category.VALE;
					model.get_value (a, column, out value1);
					model.get_value (b, column, out value2);

					return (int) Math.round ((double) value1 - (double) value2);
				});
				sort.set_sort_func (Deductions.Columns.NUM + Deductions.Category.MOESALA_LOAN, (model, a, b) => {
					Value value1, value2;
					var column = Deductions.Columns.NUM + Deductions.Category.MOESALA_LOAN;
					model.get_value (a, column, out value1);
					model.get_value (b, column, out value2);

					return (int) Math.round ((double) value1 - (double) value2);
				});
				sort.set_sort_func (Deductions.Columns.NUM + Deductions.Category.MOESALA_SAVINGS, (model, a, b) => {
					Value value1, value2;
					var column = Deductions.Columns.NUM + Deductions.Category.MOESALA_SAVINGS;
					model.get_value (a, column, out value1);
					model.get_value (b, column, out value2);

					return (int) Math.round ((double) value1 - (double) value2);
				});

				tree_view.model = sort;
				tree_view.search_column = (int) Deductions.Columns.EMPLOYEE;
			}

		}

	}

}
