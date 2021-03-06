# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
DESCRIPTION="A python wrapper for the pocket api"
HOMEPAGE="https://github.com/tapanpandita/pocket/"
LICENSE="BSD"
KEYWORDS="~amd64 ~arm ~arm64 ~mips ~mips64 ~ppc ~ppc64 ~x86"
SLOT="0/${PV}"
IUSE="test"
PYTHON_COMPAT=( python3_{6,7,8} )
inherit distutils-r1
DEPEND="${RDEPEND}
	test? ( >=dev-python/coverage-3.7.1[${PYTHON_USEDEP}]
		>=dev-python/distribute-0.7.3[${PYTHON_USEDEP}]
		>=dev-python/mock-1.0.1[${PYTHON_USEDEP}]
		>=dev-python/nose-1.3.0[${PYTHON_USEDEP}]
		>=dev-python/requests-2.1.0[${PYTHON_USEDEP}] )"
inherit eutils
SRC_URI=\
"https://github.com/tapanpandita/pocket/archive/v${PV}.tar.gz \
	-> ${P}.tar.gz"
S="${WORKDIR}/${P}"
RESTRICT="mirror"
