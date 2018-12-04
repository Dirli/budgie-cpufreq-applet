/*
* Copyright (c) 2018 Dirli <litandrej85@gmail.com>
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*/

namespace CpuFreqApplet {
    public class Utils {
        public static string get_content (string file_path) {
            string content;

            try {
                FileUtils.get_contents (file_path, out content);
            } catch (Error e) {
                warning (e.message);
                return "";
            }

            return content.chomp ();
        }

        public static void run_cli (string cli_cmd) {
            string stdout;
            string stderr;
            int status;

            try {
                Process.spawn_command_line_sync (
                    cli_cmd,
                    out stdout,
                    out stderr,
                    out status);
            } catch (Error e) {
                warning (e.message);
            }
        }

        private static Polkit.Permission? permission = null;
        public static Polkit.Permission? get_permission () {
            if (permission != null) {
                return permission;
            }

            try {
                permission = new Polkit.Permission.sync ("budgie.cpufreq.setcpufreq", new Polkit.UnixProcess (Posix.getpid ()));
                return permission;
            } catch (Error e) {
                critical (e.message);
                return null;
            }
        }

        public static string format_frequency (double val) {
            const string[] units = {
                "{} MHz",
                "{} GHz"
            };
            int index = -1;

            while (index + 1 < units.length && (val >= 1000 || index < 0)) {
                val /= 1000;
                ++index;
            }
            var pattern = units[index].replace ("{}", val <   9.95 ? "%.1f" : "%.0f");
            return pattern.printf (val);
        }
    }
}
