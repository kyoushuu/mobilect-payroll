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

		public class TotalDeductionsDialog : Dialog {

			public TotalDeductionsDialog (Window parent, Deductions deduction, int period) {
				base (_("Total Deductions"), parent);

				this.action = Stock.CLOSE;
				this.help_button.hide ();
				this.reject_button.hide ();


				var content_area = this.get_content_area ();

				var list = new Gtk.ListStore (2, typeof (string), typeof (string));
				list.insert_with_values (null, -1,
				                         0, period % 2 == 0? _("Tax") : _("SSS Premiums"),
				                         1, _("%.2lf").printf (deduction.get_total_deductions_with_category (Deductions.Category.TAX)));
				list.insert_with_values (null, -1,
				                         0, _("Loan"),
				                         1, _("%.2lf").printf (deduction.get_total_deductions_with_category (Deductions.Category.LOAN)));
				list.insert_with_values (null, -1,
				                         0, period % 2 == 0? _("PAG-IBIG") : _("PhilHealth"),
				                         1, _("%.2lf").printf (deduction.get_total_deductions_with_category (Deductions.Category.PAG_IBIG)));
				list.insert_with_values (null, -1,
				                         0, _("SSS Loan"),
				                         1, _("%.2lf").printf (deduction.get_total_deductions_with_category (Deductions.Category.SSS_LOAN)));
				list.insert_with_values (null, -1,
				                         0, _("Vale"),
				                         1, _("%.2lf").printf (deduction.get_total_deductions_with_category (Deductions.Category.VALE)));
				list.insert_with_values (null, -1,
				                         0, _("Moesala Loan"),
				                         1, _("%.2lf").printf (deduction.get_total_deductions_with_category (Deductions.Category.MOESALA_LOAN)));
				list.insert_with_values (null, -1,
				                         0, _("Moesala Savings"),
				                         1, _("%.2lf").printf (deduction.get_total_deductions_with_category (Deductions.Category.MOESALA_SAVINGS)));


				push_composite_child ();

				var sw = new ScrolledWindow (null, null);
				sw.expand = true;
				sw.min_content_width = 200;
				sw.min_content_height = 150;
				content_area.add (sw);
				sw.show ();

				var tree_view = new TreeView.with_model (list);
				sw.add (tree_view);
				tree_view.show ();

				TreeViewColumn column;

				column = new TreeViewColumn.with_attributes (_("Deduction"),
				                                             new CellRendererText (),
				                                             "text", 0);
				column.expand = true;
				tree_view.append_column (column);

				var renderer = new CellRendererText ();
				renderer.xalign = 1;
				column = new TreeViewColumn.with_attributes (_("Total"),
				                                             renderer,
				                                             "text", 1);
				column.expand = true;
				tree_view.append_column (column);

				pop_composite_child ();
			}
		}

	}

}
