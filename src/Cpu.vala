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
    public class Cpu : Gtk.Grid {
        private string cpu_path = "/sys/devices/system/cpu/";
        private string cli_path = "pkexec /usr/lib/budgie-desktop/plugins/budgie-cpufreq-applet/budgie-cpufreq-modifier";
        private string freq_driver;
        private string current_governor;
        private string[]? available_freqs = null;
        private string[] available_governors;

        private static Polkit.Permission? permission = null;
        private bool turbo_boost {
            get {
                string _turbo_boost;
                try {
                    FileUtils.get_contents ((cpu_path + "intel_pstate/no_turbo"), out _turbo_boost);
                } catch (Error e) {
                    _turbo_boost = "1";
                    warning (e.message);
                }
                if (_turbo_boost.chomp () == "1") {
                    return false;
                }
                return true;
            }
            set {
                if (get_permission ().allowed) {
                    string cli_cmd = cli_path + " -t ";
                    if (value) {
                        cli_cmd += "on";
                    } else {
                        cli_cmd += "off";
                    }

                    run_cli (cli_cmd);
                }
            }
        }

        public Cpu () {
            row_spacing = 10;
            margin_top = margin_bottom = 10;
            margin_start = margin_end = 6;

            if (!FileUtils.test(cpu_path + "cpu0/cpufreq", FileTest.IS_DIR)) {
                Gtk.Label label = new Gtk.Label ("Your system does not support cpufreq");
                attach (label,  0, 0, 1, 1);
            } else {
                int top = 0;
                freq_driver = get_cpufreq_driver ();

                if (freq_driver != "intel_pstate") {
                    available_freqs = get_available_freqs ();
                    /* not yet implemented */
                } else {
                    Gtk.Label tb_label = new Gtk.Label ("Turbo Boost");
                    Gtk.Switch tb_switch = new Gtk.Switch ();
                    tb_switch.active = turbo_boost;

                    tb_switch.notify["active"].connect (() => {
                        if ((tb_switch as Gtk.Switch).get_active ()) {
                            turbo_boost = true;
                        } else {
                            turbo_boost = false;
                        }
                    });

                    attach (tb_label,  0, top, 1, 1);
                    attach (tb_switch, 1, top, 1, 1);
                    ++top;
                }

                available_governors = get_available_governors ();
                current_governor = get_cur_governor ();

                Gtk.Separator separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
                separator.margin_bottom = 6;
                attach (separator, 0, top, 2, 1);
                ++top;

                Gtk.RadioButton? button1 = null;

                foreach (string gov in available_governors) {
                    Gtk.RadioButton button;

                    button = new Gtk.RadioButton.with_label_from_widget (button1, gov.chomp ());
                    attach (button, 0, top, 2, 1);
                    ++top;

                    button.toggled.connect (toggled_governor);
                    if (button1 == null) {
                        button1 = button;
                    }

                    if (gov.chomp () == current_governor) {
                        button.set_active (true);
                    }
                }
            }
        }

        private unowned void toggled_governor (Gtk.ToggleButton button) {
            if (get_permission ().allowed) {
                string cli_cmd = cli_path + " -g " + button.label;
                run_cli (cli_cmd);
            }
        }

        private void run_cli (string cli_cmd) {
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

        public string get_cur_frequency () {
            string cur_value;
            double maxcur = 0;

            for (uint i = 0, isize = (int)get_num_processors (); i < isize; ++i) {
                try {
                    FileUtils.get_contents (@"/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq", out cur_value);
                } catch (Error e) {
                    cur_value = "0";
                }
                var cur = double.parse (cur_value);

                if (i == 0) {
                    maxcur = cur;
                } else {
                    maxcur = double.max (cur, maxcur);
                }
            }

            return format_frequency (maxcur);
        }


        public string get_cur_governor () {
            string governor = "";
            try {
                FileUtils.get_contents ((cpu_path + "cpu0/cpufreq/scaling_governor"), out governor);
            } catch (Error e) {
                warning (e.message);
            }
            return governor.chomp ();

        }

        public string[] get_available_freqs () {
            string? freq_str = "";
            string str = cpu_path + "cpu0/cpufreq/scaling_available_frequencies";

            try {
                FileUtils.get_contents (str, out freq_str);
            } catch (Error e) {
                warning (e.message);
            }

            string[] freq_arr = freq_str.split (" ");
            return freq_arr;
        }

        public string[] get_available_governors () {
            string? gov_str = "";

            try {
                FileUtils.get_contents (cpu_path + "cpu0/cpufreq/scaling_available_governors", out gov_str);
            } catch (Error e) {
                warning (e.message);
            }

            string[] gov_arr = gov_str.split (" ");
            return gov_arr;
        }

        public string get_cpufreq_driver () {
            string? driver = "";

            try {
                FileUtils.get_contents (cpu_path + "cpu0/cpufreq/scaling_driver", out driver);
            } catch (Error e) {
                warning (e.message);
            }

            return driver.chomp ();
        }

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

        public string format_frequency (double val) {
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
