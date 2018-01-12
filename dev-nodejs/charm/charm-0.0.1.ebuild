# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

NODEJS_MIN_VERSION="0.4"

inherit node-module

DESCRIPTION="Ansi control sequences for terminal cursor hopping and colors"

LICENSE="MIT"
KEYWORDS="~amd64 ~x86"
IUSE="examples"

DOCS=( README.markdown )

src_install() {
	node-module_src_install
	use examples && dodoc -r example
}
