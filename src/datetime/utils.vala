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


using Gee;


namespace Mobilect {

	namespace Payroll {

		public void get_current_period (out Date start, out Date end) {
			var date = new DateTime.now_local ().add_days (-12);
			var period = (int) Math.round ((date.get_day_of_month () - 1) / 30.0);

			start = Date ();
			end = Date ();

			DateDay last_day;
			if (period == 0) {
				last_day = 15;
			} else {
				last_day = 31;
				while (!Date.valid_dmy (last_day,
				                        (DateMonth) date.get_month (),
				                        (DateYear) date.get_year ())) {
					last_day--;
				}
			}

			start.set_dmy ((15 * period) + 1,
			               (DateMonth) date.get_month (),
			               (DateYear) date.get_year ());
			end.set_dmy (last_day,
			             (DateMonth) date.get_month (),
			             (DateYear) date.get_year ());
		}


		public static string format_date (Date date, string format) {
			char s[64];
			date.strftime (s, format);
			return (string) s;
		}

		public string period_to_string (Date start, Date end) {
			if (start.get_year () == end.get_year ()) {
				if (start.get_month () == end.get_month ()) {
					if (start.get_day () == end.get_day ()) {
						return format_date (start, "%B %d, %Y");
					} else {
						return format_date (start, "%B %d") + "-" + format_date (end, "%d, %Y");
					}
				} else {
					return format_date (start, "%B %d") + " to " + format_date (end, "%B %d, %Y");
				}
			} else {
				return format_date (start, "%B %d, %Y") + " to " + format_date (end, "%B %d, %Y");
			}
		}

		public string dates_to_string (LinkedList<Date?> dates) {
			bool is_range = false;
			Date start_date = Date (), last_date = Date (), last_added_date = Date ();
			string result = null;

			dates.sort ((a, b) => { return a.compare (b); });

			foreach (var date in dates) {
				if (last_date.valid () && date.compare (last_date) == 0) {
					continue;
				}

				if (last_date.valid () &&
				    date.get_julian () - last_date.get_julian () == 1) {
					if (!is_range) {
						is_range = true;
						start_date = date;
					}
				} else {
					if (is_range) {
						is_range = false;

						if (start_date.get_month () != last_date.get_month ()) {
							result += format_date (last_date, _(" - %b %d"));
						} else {
							result += format_date (last_date, _("-%d"));
						}

						result += ", ";
					} else {
						if (result != null) {
							result += ", ";
						} else {
							result = "";
						}
					}

					if (!last_added_date.valid () ||
					    last_added_date.get_month () != date.get_month ()) {
						result += format_date (date, _("%b %d"));
					} else {
						result += format_date (date, _("%d"));
					}

					last_added_date = date;
				}

				last_date = date;
			}

			if (is_range) {
				if (start_date.get_month () != last_date.get_month ()) {
					result += format_date (last_date, _(" - %b %d"));
				} else {
					result += format_date (last_date, _("-%d"));
				}
			}

			return result;
		}

	}

}
