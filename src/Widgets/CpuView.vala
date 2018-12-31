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

        private int top = 0;
        private GLib.Settings settings;

        public CpuView (GLib.Settings settings) {
            orientation = Gtk.Orientation.HORIZONTAL;
            hexpand = true;
            row_spacing = 10;
            margin_top = margin_bottom = 10;
            margin_start = margin_end = 15;

            this.settings = settings;

            if (!FileUtils.test(CPU_PATH + "cpu0/cpufreq", FileTest.IS_DIR)) {
                Gtk.Label label = new Gtk.Label (_("Your system does not support cpufreq manage"));
                label.get_style_context ().add_class ("h2");
                label.sensitive = false;
                label.margin_top = label.margin_bottom = 24;
                label.margin_start = label.margin_end = 12;
                attach (label,  0, 0, 1, 1);
            } else {
                string freq_driver = Utils.get_content (CPU_PATH + "cpu0/cpufreq/scaling_driver");

                if (freq_driver != "intel_pstate") {
                    debug ("not yet implemented");
                    string[] available_freqs = Utils.get_available_values ("frequencies");
                } else {
                    add_turbo_boost ();
                }

                add_governor ();
            }
        }

        private void add_governor () {
            string current_governor = Utils.get_governor ();

            Gtk.Separator separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            separator.hexpand = true;
            separator.margin_bottom = 6;
            attach (separator, 0, top, 2, 1);
            ++top;

            Gtk.RadioButton? button1 = null;

            foreach (string gov in Utils.get_available_values ("governors")) {
                Gtk.RadioButton button;
                gov = gov.chomp ();

                button = new Gtk.RadioButton.with_label_from_widget (button1, gov);
                button.margin_start = button.margin_end = 15;
                button.margin_bottom = 10;
                button.halign = Gtk.Align.START;
                button.valign = Gtk.Align.CENTER;
                attach (button, 0, top, 2, 1);
                ++top;

                if (button1 == null) {button1 = button;}
                if (gov == current_governor) {
                    button.set_active (true);
                }
                button.toggled.connect (toggled_governor);
            }
        }

        private unowned void toggled_governor (Gtk.ToggleButton button) {
            if (Utils.get_permission ().allowed) {
                if (button.get_active ()) {
                    settings.set_string("governor", button.label);
                }
            }
        }

        private void add_turbo_boost () {
            Gtk.Label tb_label = new Gtk.Label ("Turbo Boost");
            tb_label.halign = Gtk.Align.START;
            Gtk.Switch tb_switch = new Gtk.Switch ();
            tb_switch.halign = Gtk.Align.END;
            settings.bind("turbo-boost", tb_switch, "active", GLib.SettingsBindFlags.DEFAULT);

            attach (tb_label,  0, top, 1, 1);
            attach (tb_switch, 1, top, 1, 1);
            ++top;

            Gtk.Separator separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            separator.hexpand = true;
            separator.margin_bottom = 6;
            attach (separator, 0, top, 2, 1);
            ++top;


            Gtk.Label min_freq = new Gtk.Label (_("Minimum frequency:"));
            attach (min_freq, 0, top, 2, 1);
            ++top;
            Gtk.Scale min_scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 25, 100, 5);
            min_scale.margin_start = min_scale.margin_end = 10;
            min_scale.set_value (Utils.get_freq_pct ("min"));
            attach (min_scale, 0, top, 2, 1);
            ++top;

            Gtk.Label max_freq = new Gtk.Label (_("Maximum frequency:"));
            attach (max_freq, 0, top, 2, 1);
            ++top;
            Gtk.Scale max_scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 25, 100, 5);
            max_scale.margin_start = max_scale.margin_end = 10;
            max_scale.set_value (Utils.get_freq_pct ("max"));
            attach (max_scale, 0, top, 2, 1);
            ++top;

            min_freq.halign = max_freq.halign = Gtk.Align.CENTER;

            min_scale.value_changed.connect (() => {
                settings.set_double ("pstate-min", min_scale.get_value ());
            });
            max_scale.value_changed.connect (() => {
                settings.set_double ("pstate-max", max_scale.get_value ());
            });
        }
    }
}
