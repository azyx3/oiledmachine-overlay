# Copyright 2019 Orson Teodoro
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

KERNEL_NO_POINT_RELEASE="1"
K_GENPATCHES_VER="1"
PATCH_BMQ_VER="5.4-r0"
BMQ_FN="bmq_v${PATCH_BMQ_VER}.patch"

inherit ot-kernel-v5.4

KEYWORDS="~amd64 ~x86"

pkg_setup() {
        kernel-2_pkg_setup
	ot-kernel-common_pkg_setup
}

pkg_pretend() {
	ot-kernel-common_pkg_pretend
}

src_unpack() {
	ot-kernel-common_src_unpack
}

src_compile() {
	ot-kernel-common_src_compile
}

src_install() {
	ot-kernel-common_src_install
	kernel-2_src_install
}

pkg_postinst() {
	unset K_SECURITY_UNSUPPORTED
	kernel-2_pkg_postinst
	ot-kernel-common_pkg_postinst
}
