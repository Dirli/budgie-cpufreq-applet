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
    public class Services.FreqManager : GLib.Object {
        public static void set_turbo_boost (bool state) {
            string state_str = state ? "0" : "1";
            string def_boost = Utils.get_content (CPU_PATH + "intel_pstate/no_turbo");
            if (def_boost != state_str && Utils.get_permission ().allowed) {
                string cli_cmd = "-t ";
                if (state) {
                    cli_cmd += "on";
                } else {
                    cli_cmd += "off";
                }

                Utils.run_cli (cli_cmd);
            }
        }

        public static void set_freq_scaling (string adv, double new_val) {
            if (Utils.get_freq_pct (adv) != new_val && Utils.get_permission ().allowed) {
                if (new_val >= 25 && new_val <= 100) {
                    string cli_cmd = " -f %s:%.0f".printf(adv, new_val);
                    Utils.run_cli (cli_cmd);
                }
            }
        }

        public static void set_governor (string governor) {
            if (governor != "" && Utils.get_governor () != governor) {
                string cli_cmd = " -g " + governor;
                Utils.run_cli (cli_cmd);
            }
        }
    }
}
