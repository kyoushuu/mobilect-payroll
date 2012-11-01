[CCode (cheader_filename = "portability.h")]
namespace Portability {
	public static string get_prefix ();
	public static bool show_file (Gtk.Widget? window, string filename);
	public static string? format_money (double number, int decimal_places = 2);
	public string? format_money_int (int number) {
		return format_money ((double) number, 0);
	}
}

