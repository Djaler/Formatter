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

    public class FormatterApp : Gtk.Application {
        private static FormatterApp _instance = null;
        public static FormatterApp instance {
            get {
                if (_instance == null) {
                    _instance = new FormatterApp ();
                }

                return _instance;
            }
        }

        private MainWindow mainwindow;

        public static Settings settings;

        construct {
            application_id = "com.github.djaler.formatter";
        }

        static construct {
            settings = new Settings ("com.github.djaler.formatter");
        }

        protected override void activate () {
            if (mainwindow != null) {
                mainwindow.present ();
                return;
            }

            mainwindow = new MainWindow ();
            mainwindow.set_application (this);
        }
    }
}

public static int main (string [] args) {
    Gtk.init (ref args);
    var app = Formatter.FormatterApp.instance;
    return app.run (args);
}
