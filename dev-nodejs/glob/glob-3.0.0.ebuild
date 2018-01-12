# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

NODE_MODULE_DEPEND="inherits:1.0.0 graceful-fs:1.1.2 fast-list:1.0.0 minimatch:0.1.1" #minimatch:0.1.0 fails to download

inherit node-module

DESCRIPTION="A little globber"

LICENSE="" #doesn't say in the json file
KEYWORDS="~amd64 ~x86"
IUSE="examples"

DOCS=( README.md )

src_install() {
	node-module_src_install
	use examples && dodoc -r examples
}
