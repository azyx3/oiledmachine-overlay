# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6
inherit eutils

DESCRIPTION="A lightweight code editor for use in Java applications."
HOMEPAGE="https://github.com/JoshDreamland/JoshEdit"
COMMIT="b9b73af6c20ed13151d5e63c355a884a423dde33"
PROJECT_NAME="JoshEdit"
SRC_URI="https://github.com/JoshDreamland/${PROJECT_NAME}/archive/${COMMIT}.zip -> ${P}.zip"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc ~ppc64 ~x86"
IUSE="lateralgm"

RDEPEND="virtual/jdk"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${PROJECT_NAME}-${COMMIT}"

src_prepare() {
	if use lateralgm ; then
		eapply "${FILESDIR}"/joshedit-9999-exception-handler.patch
	fi
	eapply_user
}

src_compile() {
	cd "${S}"/org/lateralgm/joshedit || die
	javac $(find . -name "*.java") || die
	cd "${S}" || die
	mkdir META-INF || die
	echo 'Main-Class: org.lateralgm.joshedit.Runner' > META-INF/MANIFEST.MF || die
	jar cmvf META-INF/MANIFEST.MF joshedit.jar $(find . -name "*.class") $(find . -name "*.properties") $(find . -name "*.flex") $(find . -name "*.gif") $(find . -name "*.png") $(find . -name "*.txt") || die
}

src_install() {
	if use lateralgm ; then
		mkdir -p "${D}/usr/share/joshedit-${SLOT}/source" || die
		cp -r "${S}"/* "${D}/usr/share/joshedit-${SLOT}/source" || die
		rm "${D}/usr/share/joshedit-${SLOT}/source/joshedit.jar" || die
	fi
	mkdir -p "${D}/usr/share/joshedit-${SLOT}/lib/" || die
	cp joshedit.jar "${D}/usr/share/joshedit-${SLOT}/lib/" || die
	mkdir -p "${D}/usr/bin" || die
	echo "#!/bin/bash" > "${D}/usr/bin/joshedit" || die
	echo "java -jar /usr/share/joshedit-${SLOT}/lib/joshedit.jar \$*" > "${D}/usr/bin/joshedit" || die
	chmod +x "${D}/usr/bin/joshedit" || die
	make_desktop_entry "/usr/bin/joshedit" "JoshEdit" "" "Utility;TextEditor"
}
