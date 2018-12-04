vala_compiler = meson.get_compiler('vala')

bcfa_sources = [
    'CpuFreqApplet.vala',
    'Utils.vala',
    'Widgets/CpuView.vala'
]

bcfa_deps = [
    dep_gtk3,
    dep_glib,
    dep_peas,
    dep_budgie,
    dep_gobject,
    dep_polkit
]

shared_library('budgiecpufreqapplet',
    bcfa_sources,
    dependencies: [
        bcfa_deps,
        vala_compiler.find_library('posix'),
    ],
    install: true,
    install_dir: LIB_INSTALL_DIR,
)
