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

		public class CPanelHolidays : CPanelTab {

			public const string ACTION = "cpanel-holidays";

			public SpinButton year_spin { get; private set; }
			public ComboBoxText month_combo { get; private set; }
			public TreeView tree_view { get; private set; }

			public MonthInfo mh { get; private set; }


			public CPanelHolidays (CPanel cpanel) {
				base (cpanel, ACTION);

				var dt = new DateTime.now_local ();

				var vbox = new Box (Orientation.VERTICAL, 3);
				this.add_with_viewport (vbox);

				var hbox = new Box (Orientation.HORIZONTAL, 3);
				vbox.add (hbox);

				var sw = new ScrolledWindow (null, null);
				vbox.pack_start (sw, true, true, 0);

				tree_view = new TreeView ();
				sw.add (tree_view);

				TreeViewColumn column;
				CellRendererText renderer_text;

				column = new TreeViewColumn ();
				renderer_text = new CellRendererText ();
				column.title = _("Day");
				column.pack_start (renderer_text, false);
				column.set_cell_data_func (renderer_text, (c, r, m, i) => {
					Value value;
					m.get_value (i, MonthInfo.Columns.DAY, out value);
					(r as CellRendererText).text = value.get_int ().to_string ();
				});
				tree_view.append_column (column);

				column = new TreeViewColumn ();
				renderer_text = new CellRendererText ();
				column.title = _("Weekday");
				column.pack_start (renderer_text, false);
				column.set_cell_data_func (renderer_text, (c, r, m, i) => {
					Value value;
					string text;

					m.get_value (i, MonthInfo.Columns.WEEKDAY, out value);
					var wd = (DateWeekday) value.get_int ();
					switch (wd) {
						case DateWeekday.SUNDAY:
							text = _("Sun");
							break;
						case DateWeekday.MONDAY:
							text = _("Mon");
							break;
						case DateWeekday.TUESDAY:
							text = _("Tue");
							break;
						case DateWeekday.WEDNESDAY:
							text = _("Wed");
							break;
						case DateWeekday.THURSDAY:
							text = _("Thu");
							break;
						case DateWeekday.FRIDAY:
							text = _("Fri");
							break;
						case DateWeekday.SATURDAY:
							text = _("Sat");
							break;
						default:
							text = null;
							break;
					}

					var rt = r as CellRendererText;
					rt.text = text;
					if (wd == DateWeekday.SUNDAY) {
						rt.foreground_rgba = Gdk.RGBA () {
							red = 1.0,
							green = 0.0,
							blue = 0.0,
							alpha = 1.0
						};
					} else {
						rt.foreground_set = false;
					}
				});
				tree_view.append_column (column);

				var holiday_type_model = new ListStore (1, typeof (string));
				holiday_type_model.insert_with_values (null, -1, 0, _("Non-Holiday"));
				holiday_type_model.insert_with_values (null, -1, 0, _("Special Holiday"));
				holiday_type_model.insert_with_values (null, -1, 0, _("Regular Holiday"));

				column = new TreeViewColumn ();
				var renderer_combo = new CellRendererCombo ();
				renderer_combo.editable = true;
				renderer_combo.has_entry = false;
				renderer_combo.model = holiday_type_model;
				renderer_combo.text_column = 0;
				renderer_combo.changed.connect ((c, s, i) => {
					mh.set_day_type (new TreePath.from_string (s).get_indices ()[0] + 1,                         // day
					                 (MonthInfo.HolidayType) holiday_type_model.get_path (i).get_indices ()[0]); // holiday type
				});
				column.title = _("Holiday Type");
				column.pack_start (renderer_combo, false);
				column.set_cell_data_func (renderer_combo, (c, r, m, i) => {
					Value value;
					TreeIter iter;
					string text;
					m.get_value (i, MonthInfo.Columns.HOLIDAY_TYPE, out value);
					holiday_type_model.iter_nth_child (out iter, null, value.get_int ());
					holiday_type_model.get (iter, 0, out text);
					(r as CellRendererText).text = text;
				});
				tree_view.append_column (column);


				var date_label = new Label (_("_Date:"));
				date_label.use_underline = true;
				hbox.add (date_label);


				year_spin = new SpinButton (new Adjustment (dt.get_year (),
				                                            1970, 3000,
				                                            1, 10,
				                                            0),
				                            1, 0);
				year_spin.value_changed.connect ((s) => {
					update ();
				});
				hbox.add (year_spin);

				month_combo = new ComboBoxText ();
				month_combo.append_text (_("January"));
				month_combo.append_text (_("February"));
				month_combo.append_text (_("March"));
				month_combo.append_text (_("April"));
				month_combo.append_text (_("May"));
				month_combo.append_text (_("June"));
				month_combo.append_text (_("July"));
				month_combo.append_text (_("August"));
				month_combo.append_text (_("September"));
				month_combo.append_text (_("October"));
				month_combo.append_text (_("November"));
				month_combo.append_text (_("December"));
				month_combo.changed.connect ((w) => {
					update ();
				});
				month_combo.active = dt.get_month () - 1;
				hbox.add (month_combo);
			}

			public void update () {
				mh = new MonthInfo (this.cpanel.window.app.database,
				                    (int) year_spin.value, month_combo.active + 1);
				tree_view.model = mh;
			}

		}

	}

}
