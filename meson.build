project('budgie-cpufreq-applet',
    ['c', 'vala'],
    version: '1.0.3',
    license: 'GPL-2.0',
    default_options: [
        'c_std=c11',
    ],
)

am_cflags = [
    '-fstack-protector',
    '-pedantic',
    '-Wstrict-prototypes',
    '-Wundef',
    '-Werror-implicit-function-declaration',
    '-Wformat',
    '-Wformat-security',
    '-Werror=format-security',
    '-Wconversion',
    '-Wunused-variable',
    '-Wunreachable-code',
    '-Wall',
    '-W',
]

add_global_arguments(am_cflags, language: 'c')

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    language:'c'
)

dep_gtk3 = dependency('gtk+-3.0', version: '>=3.18')
dep_glib = dependency('glib-2.0', version: '>= 2.46.0')
dep_peas = dependency('libpeas-1.0', version: '>= 1.8.0')
dep_budgie = dependency('budgie-1.0', version: '>= 2')
dep_gobject = dependency('gobject-2.0')
dep_polkit = dependency('polkit-gobject-1')

LIB_INSTALL_DIR = join_paths(get_option('prefix'), get_option('libdir'), 'budgie-desktop', 'plugins', meson.project_name())

subdir('data')
subdir('src')

meson.add_install_script('meson/meson_post_install.py')
