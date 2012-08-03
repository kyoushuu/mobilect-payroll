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

		public class CPanelTab : ScrolledWindow {

			public weak CPanel cpanel { get; internal set; }

			public string ui_def { get; internal set; }
			public Gtk.ActionGroup action_group { get; internal set; }


			public virtual signal void changed_to () {
					this.action_group.visible = true;
			}

			public virtual signal void changed_from () {
					this.action_group.visible = false;
			}


			public CPanelTab (CPanel cpanel, string name) {
				this.cpanel = cpanel;
				this.action_group = new Gtk.ActionGroup (name);
			}

		}

	}

}
