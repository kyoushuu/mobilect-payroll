[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "config.h")]
namespace Config {
	public const string GETTEXT_PACKAGE;
	public const string PACKAGE;
	public const string PACKAGE_DATA_DIR;
	public const string PACKAGE_LOCALE_DIR;
	public const string PACKAGE_NAME;
	public const string PACKAGE_VERSION;
	public const string PACKAGE_URL;
	public const string VERSION;

	[CCode (cheader_filename = "mobilect-payroll-os-compat.h")]
	public static string get_prefix ();
	public static bool show_file (Gtk.Widget? window, string filename);
}
