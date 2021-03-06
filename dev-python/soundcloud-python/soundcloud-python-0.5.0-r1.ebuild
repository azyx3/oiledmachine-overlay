# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
DESCRIPTION="A Python wrapper around the Soundcloud API"
HOMEPAGE="https://github.com/soundcloud/soundcloud-python"
LICENSE="BSD-2"
KEYWORDS="~amd64 ~arm ~arm64 ~mips ~mips64 ~ppc ~ppc64 ~x86"
SLOT="0/${PV}"
IUSE="test"
PYTHON_COMPAT=( python3_{6,7,8} )
# Only Python 3.5 tested upstream.
inherit distutils-r1
RDEPEND="${PYTHON_DEPEND}
	>=dev-python/fudge-1.0.3[${PYTHON_USEDEP}]
	>=dev-python/requests-1.0.0[${PYTHON_USEDEP}]
	>=dev-python/simplejson-2.0[${PYTHON_USEDEP}]
	>=dev-python/six-1.2.0[${PYTHON_USEDEP}]"
DEPEND="${RDEPEND}
	test? ( >=dev-python/nose-1.1.2[${PYTHON_USEDEP}] )"
SRC_URI=\
"https://github.com/${PN/-*}/${PN}/archive/v${PV}.tar.gz \
	-> ${P}.tar.gz"
RESTRICT="mirror"
