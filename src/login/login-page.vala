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

		public abstract class LoginPage : Frame {

			public weak Window window { get; internal set; }

			public Grid grid { get; private set; }
			public ButtonBox button_box { get; private set; }


			protected LoginPage (Window window, string label) {
				this.window = window;

				this.label = @"<b>$label</b>";
				this.halign = Align.CENTER;
				this.valign = Align.CENTER;
				(this.label_widget as Label).use_markup = true;


				push_composite_child ();


				var box = new Box (Orientation.VERTICAL, 12);
				box.margin = 12;
				this.add (box);
				box.show ();

				grid = new Grid ();
				grid.orientation = Orientation.VERTICAL;
				grid.row_homogeneous = true;
				grid.row_spacing = 3;
				grid.column_spacing = 12;
				box.add (grid);
				grid.show ();

				button_box = new ButtonBox (Orientation.HORIZONTAL);
				button_box.set_layout (ButtonBoxStyle.END);
				button_box.spacing = 6;
				box.add (button_box);
				button_box.show ();


				pop_composite_child ();
			}

		}

	}

}
