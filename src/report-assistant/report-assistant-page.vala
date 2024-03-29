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

		public abstract class ReportAssistantPage : Box {

			public ReportAssistant assistant;

			protected ReportAssistantPage (ReportAssistant assistant) {
				this.assistant = assistant;
				this.orientation = Orientation.VERTICAL;
				this.spacing = 12;
				this.border_width = 6;
			}

			public virtual signal void prepare () {
			}

		}

	}

}
