/*-
 * Copyright (c) 2017-2017 Kirill Romanov <djaler1@gmail.com>
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
 * Authored by: Kirill Romanov <djaler1@gmail.com>
 */

namespace Formatter {

    public class DeviceFormatter : GLib.Object {

     	static DeviceFormatter _instance = null;
        public static DeviceFormatter instance {
            get {
                if (_instance == null)
                    _instance = new DeviceFormatter ();
                return _instance;
            }
        }

		private DeviceFormatter () {}

        construct {
            this.is_running = false;
            this.begin.connect (() => {
                this.is_running = true;
                debug ("begin");
            });
            this.finished.connect (() => {
                this.is_running = false;
                debug ("finished");
            });
        }

        public bool is_running {get;set;}

        public signal void begin ();
        public signal void finished ();

        Pid child_pid;

        public async void format_partition(Drive drive, Formatter.Filesystems filesystem) {
            string[] spawn_args;

            string drive_identifier = drive.get_identifier ("unix-device");
            switch (filesystem) {
                case Formatter.Filesystems.EXT4:
                    spawn_args = {"pkexec", "mkfs.ext4", drive_identifier, "-F"};
                    break;
                case Formatter.Filesystems.EXFAT:
                    spawn_args = {"pkexec", "mkfs.exfat", drive_identifier};
                    break;
                case Formatter.Filesystems.FAT32:
                    spawn_args = {"pkexec", "mkfs.vfat", "-I", drive_identifier};
                    break;
                case Formatter.Filesystems.NTFS:
                    spawn_args = {"pkexec", "mkfs.ntfs", drive_identifier, "-f", "-F"};
                    break;
                default:
                    assert_not_reached();
            }

            int standard_error = 0;
            try {
                Process.spawn_async_with_pipes ("/",
                    spawn_args,
                    null,
                    SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                    null,
                    out child_pid,
                    null,
                    null,
                    out standard_error);
            } catch (GLib.SpawnError e) {
                stdout.printf ("GLibSpawnError: %s\n", e.message);
            }

            ChildWatch.add (child_pid, (pid, status) => {
                Process.close_pid (pid);

                finished();
            });

            begin ();
        }
    }
}
