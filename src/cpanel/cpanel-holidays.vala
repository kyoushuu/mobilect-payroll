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
			public const string ACTION_SORT_BY = "cpanel-holidays-sort-by";
			public const string ACTION_REFRESH = "cpanel-holidays-refresh";

			public SpinButton year_spin { get; private set; }
			public ComboBoxText month_combo { get; private set; }
			public TreeView tree_view { get; private set; }
			public TreeModelSort sort { get; private set; }

			public MonthInfo mh { get; private set; }


			public CPanelHolidays (CPanel cpanel) {
				base (cpanel, ACTION, "/com/mobilectpower/Payroll/mobilect-payroll-cpanel-holidays-ui.xml");

				var dt = new DateTime.now_local ();


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
				sw.add (tree_view);
				tree_view.show ();

				TreeViewColumn column;
				CellRendererText renderer;

				renderer = new CellRendererText ();
				renderer.xalign = 1;
				column = new TreeViewColumn.with_attributes (_("Day"), renderer);
				column.sort_column_id = MonthInfo.Columns.DAY;
				column.reorderable = true;
				column.resizable = true;
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, MonthInfo.Columns.DAY, out value);
					(r as CellRendererText).text = ((int) value).to_string ();
				});
				tree_view.append_column (column);

				renderer = new CellRendererText ();
				column = new TreeViewColumn.with_attributes (_("Weekday"), renderer);
				column.sort_column_id = MonthInfo.Columns.WEEKDAY;
				column.reorderable = true;
				column.resizable = true;
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					string markup;

					m.get_value (i, MonthInfo.Columns.WEEKDAY, out value);
					var wd = (DateWeekday) value;
					switch (wd) {
						case DateWeekday.SUNDAY:
							markup = _("<b>Sun</b>");
							break;
						case DateWeekday.MONDAY:
							markup = _("Mon");
							break;
						case DateWeekday.TUESDAY:
							markup = _("Tue");
							break;
						case DateWeekday.WEDNESDAY:
							markup = _("Wed");
							break;
						case DateWeekday.THURSDAY:
							markup = _("Thu");
							break;
						case DateWeekday.FRIDAY:
							markup = _("Fri");
							break;
						case DateWeekday.SATURDAY:
							markup = _("Sat");
							break;
						default:
							markup = null;
							break;
					}

					var rt = r as CellRendererText;
					rt.markup = markup;
				});
				tree_view.append_column (column);

				var holiday_type_model = new ListStore (1, typeof (string));
				holiday_type_model.insert_with_values (null, -1, 0, _("Non-Holiday"));
				holiday_type_model.insert_with_values (null, -1, 0, _("Special Holiday"));
				holiday_type_model.insert_with_values (null, -1, 0, _("Regular Holiday"));

				var renderer_combo = new CellRendererCombo ();
				renderer_combo.editable = true;
				renderer_combo.has_entry = false;
				renderer_combo.model = holiday_type_model;
				renderer_combo.text_column = 0;
				renderer_combo.changed.connect ((c, s, i) => {
					mh.set_day_type (new TreePath.from_string (s).get_indices ()[0] + 1,                         // day
					                 (MonthInfo.HolidayType) holiday_type_model.get_path (i).get_indices ()[0]); // holiday type
				});
				column = new TreeViewColumn.with_attributes (_("Holiday Type"), renderer_combo);
				column.sort_column_id = MonthInfo.Columns.HOLIDAY_TYPE;
				column.reorderable = true;
				column.resizable = true;
				column.set_cell_data_func (renderer_combo, (c, r, m, i) => {
					Value value;
					TreeIter iter;

					m.get_value (i, MonthInfo.Columns.HOLIDAY_TYPE, out value);
					holiday_type_model.iter_nth_child (out iter, null, (MonthInfo.HolidayType) value);
					holiday_type_model.get_value (iter, 0, out value);
					(r as CellRendererText).text = (string) value;
				});
				tree_view.append_column (column);


				var date_label = new Label.with_mnemonic (_("_Date:"));
				hbox.add (date_label);
				date_label.show ();


				year_spin = new SpinButton (new Adjustment (dt.get_year (),
				                                            1970, 3000,
				                                            1, 10,
				                                            0),
				                            1, 0);
				year_spin.value_changed.connect ((s) => {
					update ();
				});
				hbox.add (year_spin);
				date_label.mnemonic_widget = year_spin;
				year_spin.show ();

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
				month_combo.show ();


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
						accelerator = _("<Control>R"),
						tooltip = _("Reload information from database"),
						callback = (a) => {
							update ();
						}
					}
				};

				this.action_group.add_actions (actions, this);
			}

			public void update () {
				mh = new MonthInfo (this.cpanel.window.app.database,
				                    (int) year_spin.value, month_combo.active + 1);

				sort = new TreeModelSort.with_model (mh);
				sort.set_sort_func (MonthInfo.Columns.DAY, (model, a, b) => {
					Value day1, day2;
					model.get_value (a, MonthInfo.Columns.DAY, out day1);
					model.get_value (b, MonthInfo.Columns.DAY, out day2);

					return (int) day1 - (int) day2;
				});
				sort.set_sort_func (MonthInfo.Columns.WEEKDAY, (model, a, b) => {
					Value day1, day2;
					model.get_value (a, MonthInfo.Columns.WEEKDAY, out day1);
					model.get_value (b, MonthInfo.Columns.WEEKDAY, out day2);

					return (int) day1 - (int) day2;
				});
				sort.set_sort_func (MonthInfo.Columns.HOLIDAY_TYPE, (model, a, b) => {
					Value day1, day2;
					model.get_value (a, MonthInfo.Columns.HOLIDAY_TYPE, out day1);
					model.get_value (b, MonthInfo.Columns.HOLIDAY_TYPE, out day2);

					return (MonthInfo.HolidayType) day1 - (MonthInfo.HolidayType) day2;
				});
				tree_view.model = sort;
				tree_view.search_column = (int) MonthInfo.Columns.DAY;
			}

		}

	}

}
