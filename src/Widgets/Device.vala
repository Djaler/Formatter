/*-
 * Copyright (c) 2017-2017 Artem Anufrij <artem.anufrij@live.de>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Artem Anufrij <artem.anufrij@live.de>
 */

namespace Formatter {
    public class Device : Gtk.FlowBoxChild {
        private Gtk.Grid content;
        private Gtk.Image icon;
        private Gtk.Label title;

        public GLib.Drive drive { get; private set; }

        construct {
            content = new Gtk.Grid ();
            content.row_spacing = 12;
            content.valign = Gtk.Align.CENTER;
            this.add (content);
        }

        public Device (GLib.Drive d) {
            this.drive = d;

            icon = get_medium_icon ();
            icon.margin = 6;
            title = new Gtk.Label (d.get_name ());
            title.margin_end = 6;
            content.attach (icon, 0, 0, 1, 1);
            content.attach (title, 1, 0, 1, 1);
        }

        // PROPERTIES
        public bool is_card {
            get {
                string unix_device = drive.get_identifier ("unix-device");
                return unix_device.index_of ("/dev/mmc") == 0;
            }
        }

        // METHODS
        public Gtk.Image get_medium_icon () {
            if (is_card) {
                return new Gtk.Image.from_icon_name ("media-flash", Gtk.IconSize.LARGE_TOOLBAR);
            }

            return new Gtk.Image.from_gicon (drive.get_icon (), Gtk.IconSize.LARGE_TOOLBAR);
        }

        public void umount_all_volumes () {
            foreach (var volume in drive.get_volumes ()) {
                debug ("volume: %s", volume.get_name ());
                var mount = volume.get_mount ();

                if (mount != null) {
                    debug ("umount %s", mount.get_name ());
                    mount.unmount_with_operation.begin (GLib.MountUnmountFlags.FORCE, null);
                }
            }
        }
    }
}
