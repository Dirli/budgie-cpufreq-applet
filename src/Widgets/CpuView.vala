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
    public class Widgets.CpuView : Gtk.Grid {
        private string cpu_path = "/sys/devices/system/cpu/";
        private string cli_path = "pkexec /usr/lib/budgie-desktop/plugins/budgie-cpufreq-applet/budgie-cpufreq-modifier";
        private string freq_driver;

        private string[]? available_freqs = null;
        private string[] available_governors;

        private Settings? settings;

        public bool turbo_boost {
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
                if (Utils.get_permission ().allowed) {
                    string cli_cmd = cli_path + " -t ";
                    if (value) {
                        cli_cmd += "on";
                    } else {
                        cli_cmd += "off";
                    }

                    Utils.run_cli (cli_cmd);
                }
            }
        }

        public CpuView (Settings settings) {
            row_spacing = 10;
            margin_top = margin_bottom = 10;
            margin_start = margin_end = 6;

            this.settings = settings;

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
                    turbo_boost = settings.get_boolean("turbo-boost");
                    tb_switch.active = settings.get_boolean("turbo-boost");

                    attach (tb_label,  0, top, 1, 1);
                    attach (tb_switch, 1, top, 1, 1);
                    ++top;
                    settings.bind("turbo-boost", tb_switch, "active", SettingsBindFlags.DEFAULT);
                }

                available_governors = get_available_governors ();
                string current_governor = get_governor ();

                Gtk.Separator separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
                separator.margin_bottom = 6;
                attach (separator, 0, top, 2, 1);
                ++top;

                Gtk.RadioButton? button1 = null;

                foreach (string gov in available_governors) {
                    Gtk.RadioButton button;
                    gov = gov.chomp ();

                    button = new Gtk.RadioButton.with_label_from_widget (button1, gov);
                    attach (button, 0, top, 2, 1);
                    ++top;

                    if (button1 == null) {
                        button1 = button;
                    }

                    if (gov == current_governor) {
                        button.set_active (true);
                        set_governor (gov);
                    }

                    button.toggled.connect (toggled_governor);
                }
            }
        }

        private unowned void toggled_governor (Gtk.ToggleButton button) {
            if (Utils.get_permission ().allowed) {
                if (button.get_active ()) {
                    settings.set_string("governor", button.label);
                }
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

            return Utils.format_frequency (maxcur);
        }

        public void set_governor (string governor) {
            string cli_cmd = cli_path + " -g " + governor;
            Utils.run_cli (cli_cmd);
        }

        public string get_governor () {
            string cur_governor = settings.get_string("governor");

            if (cur_governor == "") {
                cur_governor = Utils.get_content ((cpu_path + "cpu0/cpufreq/scaling_governor"));
            }

            return cur_governor;
        }

        public string[] get_available_freqs () {
            string freq_str = Utils.get_content (cpu_path + "cpu0/cpufreq/scaling_available_frequencies");
            return freq_str.split (" ");
        }

        public string[] get_available_governors () {
            string gov_str = Utils.get_content (cpu_path + "cpu0/cpufreq/scaling_available_governors");
            return gov_str.split (" ");
        }

        public string get_cpufreq_driver () {
            return Utils.get_content (cpu_path + "cpu0/cpufreq/scaling_driver");
        }
    }
}
