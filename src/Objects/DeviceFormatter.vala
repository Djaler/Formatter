/*-
 * Copyright (c) 2017-2018 Kirill Romanov <djaler1@gmail.com>
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
        public signal void begin ();
        public signal void canceled ();
        public signal void finished (bool success);

        private static DeviceFormatter _instance = null;
        public static DeviceFormatter instance {
            get {
                if (_instance == null) {
                    _instance = new DeviceFormatter ();
                }

                return _instance;
            }
        }

        public bool is_running { get; private set; }

        private Pid child_pid;

        private DeviceFormatter () {
        }

        construct {
            this.is_running = false;
            this.begin.connect (() => {
                this.is_running = true;
                debug ("begin");
            });
            this.canceled.connect (() => {
                this.is_running = false;
                debug ("canceled");
            });
            this.finished.connect (() => {
                this.is_running = false;
                debug ("finished");
            });
        }

        public async void format_partition (Drive drive, Formatter.Filesystems filesystem, string label) {
            string[] spawn_args;

            string drive_identifier = drive.get_identifier ("unix-device");
            switch (filesystem) {
                case Formatter.Filesystems.EXT4:
                    spawn_args = {"pkexec", "mkfs.ext4", drive_identifier, "-F"};
                    if (label != "") {
                        spawn_args += "-L";
                        spawn_args += label;
                    }
                    break;
                case Formatter.Filesystems.EXFAT:
                    spawn_args = {"pkexec", "mkfs.exfat", drive_identifier};
                    if (label != "") {
                        spawn_args += "-n";
                        spawn_args += label;
                    }
                    break;
                case Formatter.Filesystems.FAT16:
                    spawn_args = {"pkexec", "mkfs.fat", "-F16", "-I", drive_identifier};
                    if (label != "") {
                        spawn_args += "-n";
                        spawn_args += label;
                    }
                    break;
                case Formatter.Filesystems.FAT32:
                    spawn_args = {"pkexec", "mkfs.fat", "-F32", "-I", drive_identifier};
                    if (label != "") {
                        spawn_args += "-n";
                        spawn_args += label;
                    }
                    break;
                case Formatter.Filesystems.NTFS:
                    spawn_args = {"pkexec", "mkfs.ntfs", drive_identifier, "-f", "-F"};
                    if (label != "") {
                        spawn_args += "-L";
                        spawn_args += label;
                    }
                    break;
                case Formatter.Filesystems.HFS_PLUS:
                    spawn_args = {"pkexec", "mkfs.hfsplus", drive_identifier};
                    if (label != "") {
                        spawn_args += "-v";
                        spawn_args += label;
                    }
                    break;
                default:
                    assert_not_reached ();
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

            IOChannel error_channel = new IOChannel.unix_new (standard_error);
            error_channel.add_watch (IOCondition.IN | IOCondition.HUP, (channel, condition) => {
                if (condition == IOCondition.HUP) {
                    return false;
                }

                try {
                    string line;
                    channel.read_line (out line, null, null);

                    if (line.contains ("Request dismissed")) {
                        canceled ();
                    } else {
                        stdout.printf ("Error: %s", line);
                    }
                } catch (IOChannelError e) {
                    stdout.printf ("IOChannelError: %s\n", e.message);
                    return false;
                } catch (ConvertError e) {
                    stdout.printf ("ConvertError: %s\n", e.message);
                    return false;
                }

                return true;
            });


            ChildWatch.add (child_pid, (pid, status) => {
                Process.close_pid (pid);

                finished (status == 0);
            });

            begin ();
        }
    }
}
