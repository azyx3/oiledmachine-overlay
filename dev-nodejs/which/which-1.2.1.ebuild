# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

NODE_MODULE_DEPEND="is-absolute:0.1.7"
NODE_MODULE_EXTRA_FILES="bin"

inherit node-module

DESCRIPTION="Like which(1) unix command. Find the first instance of an executable in the PATH"

LICENSE="ISC"
KEYWORDS="~amd64 ~x86"

DOCS=( README.md )
