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
    public class Plugin : GLib.Object, Budgie.Plugin {
        public Budgie.Applet get_panel_widget(string uuid) {return new Applet(uuid);}
    }

    public class Applet : Budgie.Applet {
        private Gtk.EventBox widget;
        private Gtk.Label cpu_freq;

        Budgie.Popover? popover = null;
        unowned Budgie.PopoverManager? manager = null;
        CpuFreqApplet.Widgets.CpuView? cpu_view = null;

        public string uuid { public set; public get; }
        private uint source_id;
        private Settings? settings;

        public Applet(string uuid) {
            Object(uuid: uuid);
            settings_schema = "com.github.dirli.budgie-cpufreq-applet";
            settings_prefix = "/com/github/dirli/budgie-cpufreq-applet";
            settings = get_applet_settings(uuid);
            CpuFreqApplet.Utils.init_utils (settings);

            on_settings_change("turbo-boost");
            on_settings_change("governor");
            on_settings_change("pstate-max");
            on_settings_change("pstate-min");

            settings.changed.connect(on_settings_change);

            cpu_view = new Widgets.CpuView (settings);
            cpu_freq = new Gtk.Label ("-");

            Gtk.Box box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            box.pack_start (cpu_freq, false, false, 0);

            widget = new Gtk.EventBox();
            widget.add(box);
            add(widget);

            popover = new Budgie.Popover (widget);
            popover.add(cpu_view);

            widget.button_press_event.connect((e) => {
                if (e.button != 1) {
                    return Gdk.EVENT_PROPAGATE;
                }

                if (popover.get_visible()) {
                    popover.hide();
                } else {
                    this.manager.show_popover(widget);
                }

                return Gdk.EVENT_STOP;
            });

            enable_timer ();

            popover.get_child().show_all();
            show_all();
        }

        private void enable_timer () {
            if (source_id > 0) {
                Source.remove(source_id);
            }

            source_id = GLib.Timeout.add_full(GLib.Priority.DEFAULT, 2000, update);
        }

        private unowned bool update () {
            double cur_freq = CpuFreqApplet.Utils.get_cur_frequency ();
            cpu_freq.label = CpuFreqApplet.Utils.format_frequency (cur_freq);

            return true;
        }

        protected void on_settings_change(string key) {
            switch (key) {
                case "turbo-boost":
                    CpuFreqApplet.Services.FreqManager.set_turbo_boost (settings.get_boolean("turbo-boost"));
                    break;
                case "governor":
                    CpuFreqApplet.Services.FreqManager.set_governor (settings.get_string("governor"));
                    break;
                case "pstate-max":
                    CpuFreqApplet.Services.FreqManager.set_freq_scaling ("max", settings.get_double("pstate-max"));
                    break;
                case "pstate-min":
                    CpuFreqApplet.Services.FreqManager.set_freq_scaling ("min", settings.get_double("pstate-min"));
                    break;
            }
            return;
        }

        public override void update_popovers(Budgie.PopoverManager? manager){
            this.manager = manager;
            manager.register_popover(widget, popover);
        }
    }
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(CpuFreqApplet.Plugin));
}
