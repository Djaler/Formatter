icon_sizes = ['32', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        'icons/com.github.djaler.formatter.svg',
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
    )
endforeach

i18n.merge_file(
    input: 'com.github.djaler.formatter.desktop.in',
    output: 'com.github.djaler.formatter.desktop',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    type: 'desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications')
)

i18n.merge_file(
    input: 'com.github.djaler.formatter.appdata.xml.in',
    output: 'com.github.djaler.formatter.appdata.xml',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)
