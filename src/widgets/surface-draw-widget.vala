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
using Cairo;


namespace Mobilect {

	namespace Payroll {

		public class SurfaceDrawWidget : Gtk.Widget {

			public Surface surface { get; private set; }
			public double width { get; private set; }
			public double height { get; private set; }

			private double zoom_;
			public double zoom {
				get {
					return zoom_;
				}
				set {
					zoom_ = value;
					queue_resize ();
				}
			}

			private double border_;
			public double border {
				get {
					return border_;
				}
				set {
					border_ = value;
					queue_draw ();
				}
			}


			construct {
				set_has_window (false);
			}

			public SurfaceDrawWidget () {
				zoom = 1.0;
				border = 2.0;
			}

			public override SizeRequestMode get_request_mode () {
				return SizeRequestMode.CONSTANT_SIZE;
			}

			public override void get_preferred_width (out int minimum_width, out int natural_width) {
				minimum_width = natural_width = (int) Math.ceil (width * zoom);
			}

			public override void get_preferred_height (out int minimum_height, out int natural_height) {
				minimum_height = natural_height = (int) Math.ceil (height * zoom);
			}

			public override bool draw (Context cr) {
				if (surface != null) {
					/* Scale using zoom */
					cr.scale (zoom, zoom);

					/* Draw page */
					cr.save ();
					cr.set_source_surface (surface, 0, 0);
					cr.paint ();
					cr.restore ();

					/* Black border */
					cr.set_source_rgba (0, 0, 0, 1);
					cr.rectangle (border_ / 2, border_ / 2,
					              width - border_,
					              height - border_);
					cr.set_line_width (border_);
					cr.set_line_join (LineJoin.ROUND);
					cr.stroke ();
				}

				return true;
			}

			public void set_cairo_surface (Surface surface, double width, double height) {
				this.surface = surface;
				this.width = width;
				this.height = height;

				queue_resize ();
			}

		}

	}

}
