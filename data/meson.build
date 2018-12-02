install_data('CpuFreqApplet.plugin',
             install_dir: LIB_INSTALL_DIR)

install_data(
             'budgie-cpufreq-modifier',
             install_mode: 'r-xr--r--',
             install_dir: '/usr/lib/budgie-desktop/plugins/budgie-cpufreq-applet'
)

install_data('budgie.cpufreq.policy',
    install_dir: join_paths(get_option('datadir'), 'polkit-1', 'actions')
)
