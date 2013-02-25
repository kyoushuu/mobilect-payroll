[CCode (cheader_filename = "cairo.h", gir_namespace = "cairo", gir_version = "1.0")]
namespace Cairo {
        [Compact]
        [CCode (cname = "cairo_surface_t", cheader_filename = "cairo.h")]
        public class RecordingSurface : Surface {
                [CCode (cname = "cairo_recording_surface_create")]
                public RecordingSurface (Content content, Rectangle extents);
                public void ink_extents (out double x0, out double y0, out double width, out double height);
				public bool get_extents (Rectangle extents);
        }
}

