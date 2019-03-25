project('com.github.djaler.formatter', 'vala', 'c', version: '0.2.5')

i18n = import('i18n')

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    language: 'c'
)

executable(
    meson.project_name(),
    'src/Widgets/Device.vala',
    'src/Widgets/Filesystem.vala',
    'src/Manager/DeviceManager.vala',
    'src/Objects/DeviceFormatter.vala',
    'src/MainWindow.vala',
    'src/Application.vala',
    dependencies: [
        dependency('granite'),
        dependency('gtk+-3.0')
    ],
    install: true
)

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')
