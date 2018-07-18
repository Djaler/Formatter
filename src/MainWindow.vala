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

    public class MainWindow : Gtk.ApplicationWindow {

        Gtk.Grid content;

        Gtk.Grid filesystem_container;
        Gtk.FlowBox filesystem_list;
        Gtk.Popover filesystem_popover;
        Gtk.Label filesystem_name;
        Gtk.Button select_filesystem;

        Gtk.Grid device_container;
        Gtk.Image device_logo;
        Gtk.FlowBox device_list;
        Gtk.Popover device_popover;
        Gtk.Button select_device;
        Gtk.Label device_name;

        Granite.Widgets.Toast app_notification;
        Notification desktop_notification;

        Gtk.Grid format_container;
        Gtk.Entry label_input;
        Gtk.Label format_label;
        Gtk.Button format_start;

        Formatter.Filesystem _selected_filesystem = null;
        Formatter.Filesystem selected_filesystem {
            get { return _selected_filesystem; }
            set {
                if (selected_filesystem == value) {
                    return;
                }
                _selected_filesystem = value;

                filesystem_name.label = selected_filesystem.filesystem.get_name ();
            }
        }

        Formatter.Device _selected_device = null;
        Formatter.Device selected_device {
            get { return _selected_device; }
            set {
                if (selected_device == value) {
                    return;
                }
                _selected_device = value;
                format_container.sensitive = selected_device != null;

                if (selected_device != null) {
                    set_device_label (selected_device.drive.get_name ());
                    select_device.label = _("Change");
                    if (selected_device.is_card) {
                        device_logo.set_from_icon_name ("media-flash", Gtk.IconSize.DIALOG);
                    } else {
                        device_logo.set_from_gicon (selected_device.drive.get_icon (), Gtk.IconSize.DIALOG);
                    }
                } else {
                    set_device_label ("");
                    select_device.label = _("Device");
                    device_logo.set_from_icon_name ("drive-removable-media-usb", Gtk.IconSize.DIALOG);
                }

                check_selected_device ();
            }
        }

        bool has_removable_devices {
            get {
                return device_list.get_children ().length () > 0;
            }
        }

        Formatter.DeviceManager devices;
        Formatter.DeviceFormatter formatter;

        public MainWindow () {
            title = _("Formatter");
            resizable = false;

            build_ui ();

            devices = DeviceManager.instance;
            devices.drive_connected.connect (device_added);
            devices.drive_disconnected.connect (device_removed);

            formatter = DeviceFormatter.instance;
            formatter.begin.connect (on_flash_started);
            formatter.canceled.connect (on_flash_canceled);

            devices.init ();
            present ();
        }

        private void build_ui () {
            get_style_context ().add_class ("rounded");

            content = new Gtk.Grid ();
            content.margin = 32;
            content.column_spacing = 32;
            content.column_homogeneous = true;
            content.row_spacing = 24;

            app_notification = new Granite.Widgets.Toast ("");
            var overlay = new Gtk.Overlay ();
            overlay.add (content);
            overlay.add_overlay (app_notification);

            desktop_notification = new Notification (_("Finished"));

            build_filesystem_area ();

            build_device_area ();

            build_flash_area ();

            add (overlay);
            show_all ();

            check_selected_device ();
        }

        private void build_filesystem_area () {
            filesystem_container = new Gtk.Grid ();
            filesystem_container.row_spacing = 24;
            filesystem_container.width_request = 180;

            var title = new Gtk.Label (_("File System"));
            title.get_style_context ().add_class("h2");
            title.hexpand = true;
            filesystem_container.attach (title, 0, 0, 1, 1);

            var start_logo = new Gtk.Image.from_icon_name ("office-database", Gtk.IconSize.DIALOG);
            filesystem_container.attach (start_logo, 0, 1, 1, 1);

            var filesystem_grid = new Gtk.Grid ();
            filesystem_list = new Gtk.FlowBox ();
            filesystem_list.child_activated.connect (on_select_filesystem);

            filesystem_grid.add (filesystem_list);

            select_filesystem = new Gtk.Button.with_label (_("Change"));
            select_filesystem.valign = Gtk.Align.END;
            select_filesystem.vexpand = true;
            select_filesystem.clicked.connect (() => {
                filesystem_popover.visible = !filesystem_popover.visible;
            });
            filesystem_container.attach (select_filesystem, 0, 3, 1, 1);

            filesystem_name = new Gtk.Label (("<i>%s</i>").printf(_("No removable devices found…")));
            filesystem_name.use_markup = true;
            filesystem_container.attach (filesystem_name, 0, 2, 1, 1);

            filesystem_popover = new Gtk.Popover (select_filesystem);
            filesystem_popover.position = Gtk.PositionType.TOP;
            filesystem_popover.add (filesystem_grid);

            filesystem_popover.show.connect (() => {
                if (selected_filesystem != null) {
                    filesystem_list.select_child (selected_filesystem);
                }
                selected_filesystem.grab_focus ();
            });

            content.attach (filesystem_container, 0, 0, 1, 1);

            foreach (var filesystem in Formatter.Filesystems.get_all ()) {
                var item = new Formatter.Filesystem (filesystem);
                filesystem_list.add (item);
                if (selected_filesystem == null) {
                    selected_filesystem = item;
                }
            }

            filesystem_grid.show_all ();
        }

        private void build_device_area () {
            device_container = new Gtk.Grid ();
            device_container.sensitive = false;
            device_container.row_spacing = 24;
            device_container.width_request = 180;

            var title = new Gtk.Label (_("Device"));
            title.get_style_context ().add_class("h2");
            title.hexpand = true;
            device_container.attach (title, 0, 0, 1, 1);

            device_logo = new Gtk.Image.from_icon_name ("drive-removable-media-usb", Gtk.IconSize.DIALOG);
            device_container.attach (device_logo, 0, 1, 1, 1);

            select_device = new Gtk.Button.with_label (_("Select Drive"));
            select_device.valign = Gtk.Align.END;
            select_device.vexpand = true;
            select_device.clicked.connect (() => {
                device_popover.visible = !device_popover.visible;
            });
            device_container.attach (select_device, 0, 3, 1, 1);

            device_name = new Gtk.Label (("<i>%s</i>").printf(_("No removable devices found…")));
            device_name.use_markup = true;
            device_container.attach (device_name, 0, 2, 1, 1);

            var device_grid = new Gtk.Grid ();
            device_list = new Gtk.FlowBox ();
            device_list.child_activated.connect (on_select_drive);

            device_grid.add (device_list);

            device_popover = new Gtk.Popover (select_device);
            device_popover.position = Gtk.PositionType.TOP;
            device_popover.add (device_grid);

            device_popover.show.connect (() => {
                if (selected_device != null) {
                    device_list.select_child (selected_device);
                }
                select_device.grab_focus ();
            });

            device_grid.show_all ();
            content.attach (device_container, 1, 0, 1, 1);
        }

        private void build_flash_area () {
            format_container = new Gtk.Grid ();
            format_container.row_spacing = 24;
            format_container.sensitive = false;
            format_container.width_request = 180;

            var title = new Gtk.Label (_("Format"));
            title.get_style_context ().add_class("h2");
            title.hexpand = true;
            format_container.attach (title, 0, 0, 1, 1);

            var start_logo = new Gtk.Image.from_icon_name ("document-save", Gtk.IconSize.DIALOG);
            format_container.attach (start_logo, 0, 1, 1, 1);

            format_start = new Gtk.Button.with_label (_("Format device"));
            format_start.valign = Gtk.Align.END;
            format_start.vexpand = true;
            format_start.get_style_context ().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            format_start.clicked.connect (flash_image);
            format_container.attach (format_start, 0, 3, 1, 1);

            label_input = new Gtk.Entry ();
            label_input.placeholder_text = (_("Enter label…"));
            label_input.hexpand = true;
            format_container.attach(label_input, 0, 2, 1, 1);

            format_label = new Gtk.Label (("<i>%s</i>").printf(_("No device chosen…")));
            format_label.use_markup = true;
            format_container.attach (format_label, 0, 2, 1, 1);

            content.attach (format_container, 2, 0, 1, 1);
        }

        private void on_select_filesystem (Gtk.FlowBoxChild item) {
            debug ("Selected filesystem: %s", (item as Formatter.Filesystem).filesystem.get_name ());
            selected_filesystem = item as Formatter.Filesystem;
            filesystem_popover.visible = false;
        }

        private void on_select_drive (Gtk.FlowBoxChild item) {
            debug ("Selected drive: %s", (item as Formatter.Device).drive.get_name ());
            selected_device = item as Formatter.Device;
            device_popover.visible = false;
        }

        private void on_flash_started () {
            filesystem_container.sensitive = false;
            device_container.sensitive = false;
            format_container.sensitive = false;
            app_notification.set_reveal_child (false);
        }

        private void on_flash_canceled () {
            formatter.finished.disconnect (on_flash_finished);

            filesystem_container.sensitive = true;
            device_container.sensitive = true;
            format_container.sensitive = true;
        }

        private void on_flash_finished (bool success) {
            formatter.finished.disconnect (on_flash_finished);

            filesystem_container.sensitive = true;
            device_container.sensitive = true;
            format_container.sensitive = true;

            string message;
            if (success) {
                message = _("%s was formatted into %s").printf (selected_device.drive.get_name (), selected_filesystem.filesystem.get_name ());   
            } else {
                message = _("Error while formatting %s into %s").printf (selected_device.drive.get_name (), selected_filesystem.filesystem.get_name ());
            }

            if (is_active) {
                app_notification.title = message;
                app_notification.send_notification ();
            } else {
                if (success) {
                    desktop_notification.set_title (_("Finished"));
                } else {
                    desktop_notification.set_title (_("Error"));
                }
                desktop_notification.set_body (message);
                application.send_notification ("notify.app", desktop_notification);
            }
        }

        private void flash_image () {
            if (!formatter.is_running) {
                selected_device.umount_all_volumes ();

                formatter.finished.connect (on_flash_finished);

                formatter.format_partition.begin(selected_device.drive, selected_filesystem.filesystem, label_input.text);
            }
        }

        private void device_added (GLib.Drive drive) {
            debug ("Add device into list");
            var item = new Formatter.Device (drive);
            selected_device = item;
            device_list.add (item);
            device_list.show_all ();

            device_container.sensitive = has_removable_devices;
        }

        private void device_removed (GLib.Drive drive) {
            debug ("Remove device from list");
            foreach (var child in device_list.get_children ()) {
                if ((child as Device).drive == drive) {
                    device_list.remove (child);
                }
            }
            if (selected_device != null && selected_device.drive == drive) {
                if (has_removable_devices) {
                    selected_device = device_list.get_children ().last ().data as Device;
                } else {
                    selected_device = null;
                }
            }

            device_container.sensitive = has_removable_devices;
        }

        private void set_device_label (string text) {
            if (text != "") {
                device_name.label = text;
            } else {
                device_name.label = ("<i>%s</i>").printf(_("No removable devices found…"));
            }
        }

        private void check_selected_device () {
            if (selected_device == null) {
                format_label.visible = true;
                label_input.visible = false;
            } else {
                format_label.visible = false;
                label_input.text = "";
                label_input.visible = true;
            }
        }
    }
}
