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
    public class DeviceManager : GLib.Object {
        public signal void drive_connected (Drive drive);
        public signal void drive_disconnected (Drive drive);

        private static DeviceManager _instance = null;
        public static DeviceManager instance {
            get {
                if (_instance == null) {
                    _instance = new DeviceManager ();
                }

                return _instance;
            }
        }

        private GLib.VolumeMonitor monitor;

        private DeviceManager () {
        }

        construct {
            monitor = GLib.VolumeMonitor.get ();

            monitor.drive_connected.connect ((drive) => {
                debug ("Drive connected: %s\n", drive.get_name ());
                if (valid_device (drive)) {
                    drive_connected (drive);
                }
            });

            monitor.drive_disconnected.connect ((drive) => {
                debug ("Drive disconnected: %s\n", drive.get_name ());
                drive_disconnected (drive);
            });
        }

        public void init () {
            GLib.List<GLib.Drive> drives = monitor.get_connected_drives ();
            foreach (Drive drive in drives) {
                if (valid_device (drive)) {
                    drive_connected (drive);
                }
            }
        }

        private bool valid_device (Drive drive) {
            string unix_device = drive.get_identifier ("unix-device");
            if (unix_device == null) {
                return false;
            }

            debug ("unix_device: %s", unix_device);
            return (drive.is_media_removable () || drive.can_stop ()) && (unix_device.index_of ("/dev/sd") == 0 || unix_device.index_of ("/dev/mmc") == 0);
        }
    }
}
