project('liblstparse', 'd',
	meson_version: '>=0.49.0',
	version: '0.0.1',
	license: 'LGPL-3.0')

d_lstparse_inc = include_directories('source')

d_lstparse_src = [
	'source/parser.d',
]

d_lstparse_lib = library('lstparse',
	d_lstparse_src,
	include_directories: [d_lstparse_inc],
	install: true,
)
