vapi_dir = meson.current_source_dir() / 'vapi'
add_project_arguments(['--vapidir', vapi_dir], language: 'vala')

linux_dep = meson.get_compiler('vala').find_library('linux')

lib_dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gio-2.0'),
    dependency('libssh2'),
    linux_dep,
]

scp_lib = shared_library('scp', 'scp.vala',
                  vala_header: 'scp.h',
                  vala_vapi: 'scp-1.0.vapi',
                  dependencies: lib_dependencies,
                  install: true,
                  install_dir: [true, true, true])