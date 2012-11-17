[CCode (cheader_filename = "portability.h")]
namespace Portability {
	public static string get_prefix ();
	public static bool show_file (Gtk.Widget? window, string filename);
	public static string? format_money (double number, bool decimal = true);
}

