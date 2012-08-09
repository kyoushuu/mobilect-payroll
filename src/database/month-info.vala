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


using Gda;
using Gtk;


namespace Mobilect {

	namespace Payroll {

		public class MonthInfo : Object, TreeModel {

			public enum HolidayType {
				NON_HOLIDAY,
				SPECIAL_HOLIDAY,
				REGULAR_HOLIDAY
			}


			public enum Columns {
				ID,
				DAY,
				WEEKDAY,
				HOLIDAY_TYPE,
				NUM
			}


			public int stamp { get; private set; }

			public int year { get; private set; }
			public int month { get; private set; }
			public int days { get; private set; }

			internal weak Database database { get; private set; }

			private HolidayType[] is_holiday = new HolidayType[31];
			private DateWeekday weekday;


			/* Months and Days are one-based */
			public MonthInfo (Database database, int year, int month) {
				this.database = database;
				this.stamp = (int) Random.next_int ();

				set_date (year, month);
			}

			public void set_date (int year, int month) {
				this.year = year;
				this.month = month;

				var d = Date ();
				d.set_dmy ((DateDay) 1, (DateMonth) month, (DateYear) year);
				weekday = d.get_weekday ();

				var dt = new DateTime.local (year, month, 1, 0, 0, 0)
					.add_months (1)
					.add_days (-1);

				this.days = dt.get_day_of_month ();


				Set stmt_params;

				Value value_year = this.year;
				Value value_month = this.month;
				Value value_day;

				for (int i = 0; i < days; i++) {
					value_day = i+1;

					/* Check if in database */
					try {
						var stmt = database.cnc.parse_sql_string ("SELECT type" +
						                                          "  FROM holidays" +
						                                          "  WHERE year=##year::int" +
						                                          "  AND month=##month::int" +
						                                          "  AND day=##day::int",
						                                          out stmt_params);
						stmt_params.get_holder ("year").set_value (value_year);
						stmt_params.get_holder ("month").set_value (value_month);
						stmt_params.get_holder ("day").set_value (value_day);
						var data_model = database.cnc.statement_execute_select (stmt, stmt_params);

						if (data_model.get_n_rows () > 0) {
							/* Get type if exists */
							is_holiday[i] = (HolidayType) data_model.get_value_at (0, 0).get_int ();
						} else {
							/* Set as non-holiday if not */
							is_holiday[i] = HolidayType.NON_HOLIDAY;
						}
					} catch (Error e) {
						/* Set as non-holiday on error */
						is_holiday[i] = HolidayType.NON_HOLIDAY;
						critical ("Failed to get day types from database: %s", e.message);
					}
				}
			}

			public HolidayType get_day_type (int day) requires (day > 0 && day <= days) {
				return this.is_holiday[day-1];
			}

			public void set_day_type (int day, HolidayType type) requires (day > 0 && day <= days) {
				Set stmt_params;

				this.is_holiday[day-1] = type;

				Value value_year = this.year;
				Value value_month = this.month;
				Value value_day = day;
				Value value_type = (int) is_holiday[day-1];

				/* Check if in database */
				try {
					var stmt = database.cnc.parse_sql_string ("SELECT id, type" +
					                                          "  FROM holidays" +
					                                          "  WHERE year=##year::int" +
					                                          "  AND month=##month::int" +
					                                          "  AND day=##day::int",
					                                          out stmt_params);
					stmt_params.get_holder ("year").set_value (value_year);
					stmt_params.get_holder ("month").set_value (value_month);
					stmt_params.get_holder ("day").set_value (value_day);
					var data_model = database.cnc.statement_execute_select (stmt, stmt_params);

					stmt = null;
					if (data_model.get_n_rows () > 0) {
						/* If in database and different, set new type */
						if ((HolidayType) data_model.get_value_at (1, 0).get_int () != type) {
							stmt = database.cnc.parse_sql_string ("UPDATE holidays" +
							                                      "  SET type=##type::int" +
							                                      "  WHERE id=##id::int",
							                                      out stmt_params);
							stmt_params.get_holder ("id").set_value (data_model.get_value_at (0, 0));
						}
					} else {
						/* Else, add new entry */
						stmt = database.cnc.parse_sql_string ("INSERT INTO holidays (year, month, day, type)" +
						                                      "  VALUES (##year::int, ##month::int, ##day::int, ##type::int)",
						                                      out stmt_params);
						stmt_params.get_holder ("year").set_value (value_year);
						stmt_params.get_holder ("month").set_value (value_month);
						stmt_params.get_holder ("day").set_value (value_day);
					}

					/* Execute query */
					if (stmt != null) {
						stmt_params.get_holder ("type").set_value (value_type);
						database.cnc.statement_execute_non_select (stmt, stmt_params, null);
					}
				} catch (Error e) {
					critical ("Failed to set day type in database: %s", e.message);
				}
			}

			public DateWeekday get_weekday (int day) requires (day > 0 && day <= days) {
				return ((weekday-2+day)%7)+1;
			}


			/* TreeModel implementation */
			public Type get_column_type (int index_) {
				switch (index_) {
					case Columns.ID:
						return typeof (int);
					case Columns.DAY:
						return typeof (int);
					case Columns.WEEKDAY:
						return typeof (int);
					case Columns.HOLIDAY_TYPE:
						return typeof (int);
					default:
						return Type.INVALID;
				}
			}

			public TreeModelFlags get_flags () {
				return TreeModelFlags.LIST_ONLY | TreeModelFlags.ITERS_PERSIST;
			}

			public bool get_iter (out TreeIter iter, TreePath path) {
				/* we do not allow children */
				/* depth 1 = top level; a list only has top level nodes and no children */
				assert (path.get_depth () == 1);

				/* the n-th top level row */
				return create_iter (out iter, path.get_indices ()[0]);
			}

			public int get_n_columns () {
				return this.Columns.NUM;
			}

			public TreePath? get_path (TreeIter iter) requires (iter.stamp == this.stamp) {
				var path = new TreePath ();
				path.append_index ((int) iter.user_data);

				return path;
			}

			public void get_value (TreeIter iter, int column, out Value value) requires (iter.stamp == this.stamp) {
				var id = (int) iter.user_data;

				switch (column) {
					case Columns.ID:
						value = id;
						break;
					case Columns.DAY:
						value = id+1;
						break;
					case Columns.WEEKDAY:
						value = get_weekday (id+1);
						break;
					case Columns.HOLIDAY_TYPE:
						value = is_holiday[id];
						break;
					default:
						value = Value (Type.INVALID);
						break;
				}
			}

			public bool iter_children (out TreeIter iter, TreeIter? parent) {
				if (parent != null) {
					iter = TreeIter ();
					return false;
				}

				return create_iter (out iter, 0);
			}

			public bool iter_has_child (TreeIter iter) {
				return false;
			}

			public int iter_n_children (TreeIter? iter) {
				if (iter != null) {
					return 0;
				}

				return days;
			}

			public bool iter_next (ref TreeIter iter) requires (iter.stamp == this.stamp) {
				return create_iter (out iter, ((int) iter.user_data) + 1);
			}

			public bool iter_nth_child (out TreeIter iter, TreeIter? parent, int n) {
				if (parent != null) {
					iter = TreeIter ();
					return false;
				}

				return create_iter (out iter, n);
			}

			public bool iter_parent (out TreeIter iter, TreeIter child) {
				iter = TreeIter ();
				return false;
			}

			private bool create_iter (out TreeIter iter, int index) {
				if ((index) < days) {
					/* We simply store a pointer to our custom record in the iter */
					iter = TreeIter () {
						stamp      = this.stamp,
						user_data  = (void*) index
					};
					return true;
				} else {
					iter = TreeIter ();
					return false;
				}
			}

		}

	}

}
