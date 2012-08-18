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

		public class PreferencesDialog : Dialog {

			private GLib.Settings report_settings;


			public PreferencesDialog (Window parent) {
				base (_("Mobilect Payroll Preferences"), parent);

				this.action = Stock.CLOSE;
				this.help_link_id = "control-panel-change-preferences";
				this.reject_button.hide ();

				var content_area = this.get_content_area ();


				report_settings = parent.app.settings.report;


				push_composite_child ();


				var notebook = new Notebook ();
				notebook.border_width = 5;
				content_area.add (notebook);
				notebook.show ();


				var fonts_grid = new Grid ();
				fonts_grid.orientation = Orientation.VERTICAL;
				fonts_grid.row_homogeneous = true;
				fonts_grid.row_spacing = 3;
				fonts_grid.column_spacing = 12;
				fonts_grid.border_width = 5;
				notebook.append_page (fonts_grid, new Label (_("Report Fonts")));
				fonts_grid.show ();


				var title_label = new Label.with_mnemonic (_("_Title:"));
				title_label.xalign = 0.0f;
				fonts_grid.add (title_label);
				title_label.show ();

				var title_font_button = new FontButton ();
				title_font_button.font_name = this.report_settings.get_string ("title-font");
				title_font_button.font_set.connect ((w) => {
									this.report_settings.set_string ("title-font",
									                                 w.font_name);
								});
				fonts_grid.attach_next_to (title_font_button,
				                        title_label,
				                        PositionType.RIGHT,
				                        2, 1);
				title_label.mnemonic_widget = title_font_button;
				title_font_button.show ();


				var company_name_label = new Label.with_mnemonic (_("Co_mpany Name:"));
				company_name_label.xalign = 0.0f;
				fonts_grid.add (company_name_label);
				company_name_label.show ();

				var company_name_font_button = new FontButton ();
				company_name_font_button.font_name = this.report_settings.get_string ("company-name-font");
				company_name_font_button.font_set.connect ((w) => {
																	this.report_settings.set_string ("company-name-font",
																	                                 w.font_name);
																});
				fonts_grid.attach_next_to (company_name_font_button,
				                        company_name_label,
				                        PositionType.RIGHT,
				                        2, 1);
				company_name_label.mnemonic_widget = company_name_font_button;
				company_name_font_button.show ();


				var header_label = new Label.with_mnemonic (_("_Header:"));
				header_label.xalign = 0.0f;
				fonts_grid.add (header_label);
				header_label.show ();

				var header_font_button = new FontButton ();
				header_font_button.font_name = this.report_settings.get_string ("header-font");
				header_font_button.font_set.connect ((w) => {
																	this.report_settings.set_string ("header-font",
																	                                 w.font_name);
																});
				fonts_grid.attach_next_to (header_font_button,
				                        header_label,
				                        PositionType.RIGHT,
				                        2, 1);
				header_label.mnemonic_widget = header_font_button;
				header_font_button.show ();


				var text_label = new Label.with_mnemonic (_("Te_xt:"));
				text_label.xalign = 0.0f;
				fonts_grid.add (text_label);
				text_label.show ();

				var text_font_button = new FontButton ();
				text_font_button.font_name = this.report_settings.get_string ("text-font");
				text_font_button.font_set.connect ((w) => {
																	this.report_settings.set_string ("text-font",
																	                                 w.font_name);
																});
				fonts_grid.attach_next_to (text_font_button,
				                        text_label,
				                        PositionType.RIGHT,
				                        2, 1);
				text_label.mnemonic_widget = text_font_button;
				text_font_button.show ();


				var number_label = new Label.with_mnemonic (_("_Number:"));
				number_label.xalign = 0.0f;
				fonts_grid.add (number_label);
				number_label.show ();

				var number_font_button = new FontButton ();
				number_font_button.font_name = this.report_settings.get_string ("number-font");
				number_font_button.font_set.connect ((w) => {
																	this.report_settings.set_string ("number-font",
																	                                 w.font_name);
																});
				fonts_grid.attach_next_to (number_font_button,
				                        number_label,
				                        PositionType.RIGHT,
				                        2, 1);
				number_label.mnemonic_widget = number_font_button;
				number_font_button.show ();


				var emp_number_label = new Label.with_mnemonic (_("_Emphasized Number:"));
				emp_number_label.xalign = 0.0f;
				fonts_grid.add (emp_number_label);
				emp_number_label.show ();

				var emp_number_font_button = new FontButton ();
				emp_number_font_button.font_name = this.report_settings.get_string ("emphasized-number-font");
				emp_number_font_button.font_set.connect ((w) => {
																	this.report_settings.set_string ("emphasized-number-font",
																	                                 w.font_name);
																});
				fonts_grid.attach_next_to (emp_number_font_button,
				                        emp_number_label,
				                        PositionType.RIGHT,
				                        2, 1);
				emp_number_label.mnemonic_widget = emp_number_font_button;
				emp_number_font_button.show ();


				pop_composite_child ();
			}

		}

	}

}
