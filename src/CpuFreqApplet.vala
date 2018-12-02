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
        CpuFreqApplet.Cpu? popover_grid = null;

        public string uuid { public set; public get; }
        private uint source_id;

        public Applet(string uuid) {
            Object(uuid: uuid);

            popover_grid = new Cpu ();
            cpu_freq = new Gtk.Label ("-");

            Gtk.Box box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            box.pack_start (cpu_freq, false, false, 0);

            widget = new Gtk.EventBox();
            widget.add(box);
            add(widget);

            popover = new Budgie.Popover (widget);
            popover.add(popover_grid);

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
            cpu_freq.label = popover_grid.get_cur_frequency ();

            return true;
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
