# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

RDEPEND="${RDEPEND}"

DEPEND="${RDEPEND}
        net-libs/nodejs[npm]"

inherit eutils npm-secaudit versionator

COMMIT="e32789f40a9c5a1145be01ea8c1a6bc4a16bc972"

DESCRIPTION="Instagram Direct Messages in your terminal"
HOMEPAGE="https://github.com/mathdroid/igdm-cli"
SRC_URI="https://github.com/mathdroid/${PN}/archive/${COMMIT}.zip -> ${P}.zip"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~arm ~arm64 ~ppc ~ppc64"
IUSE=""

S="${WORKDIR}/${PN}-${COMMIT}"

BABEL_CODE_FRAME_V="^6.26.0"
BABEL_MESSAGES_V="^6.23.0"
BABEL_RUNTIME_V="^6.26.0"
BABEL_TYPES_V="^6.26.0"
BABEL_GENERATOR_V="^6.26.0"
BABEL_CORE_V="^6.26.0"
DEBUG_V="2.6.9"

_npm_install_sub() {
	local dir="${1}"
	einfo "dir=${dir}"
	pushd "${dir}"
	npm install
	[ -e package-lock.json ] && rm package-lock.json
	npm i --package-lock-only
	popd
}

_npm_audit_package_lock_update() {
	local dir="${1}"
	einfo "dir=${dir}"
	pushd "${dir}"
	# audit fix may fail on dependency but that is okay.  the eclass does another audit pass.
	npm audit fix --force > /dev/null
	rm package-lock.json
	npm i --package-lock-only
	popd
}

_npm_audit_fix() {
	local dir="${1}"
	einfo "dir=${dir}"
	pushd "${dir}"
	npm audit fix --force
	popd
}

npm-secaudit_src_postprepare() {
	einfo "npm-secaudit_src_postprepare START"
	npm install babel-code-frame@"${BABEL_CODE_FRAME_V}" || die
	npm install babel-messages@"${BABEL_MESSAGES_V}" || die
	npm install babel-runtime@"${BABEL_RUNTIME_V}" || die
	npm install babel-types@"${BABEL_TYPES_V}" || die
	npm install babel-generator@"${BABEL_GENERATOR_V}" || die

	_npm_audit_package_lock_update node_modules/babel-template/node_modules/babel-traverse
	_npm_audit_package_lock_update node_modules/babel-template/node_modules/babel-runtime

	# break circular dependency sequence with babel-runtime
	npm dedupe

	npm install babel-core@"${BABEL_CORE_V}" || die

	_npm_audit_package_lock_update node_modules/babel-register
	_npm_audit_package_lock_update node_modules/babel-polyfill
	_npm_audit_package_lock_update node_modules/babel-runtime

	# fix circular
	npm dedupe

	# must do again
	_npm_audit_package_lock_update node_modules/babel-runtime

	# fix circular
	npm dedupe

	_npm_audit_package_lock_update node_modules/babel-types

	_npm_audit_package_lock_update ./

	# fix vulnerbilities
	sed -i -e "s|\"debug\": \"~0.8.1\",|\"debug\": \"${DEBUG_V}\",|" node_modules/git-spawned-stream/package.json || die
	pushd node_modules/git-spawned-stream || die
	npm i debug@"${DEBUG_V}" --save-prod || die
	popd

	sed -i -e "s|\"debug\": \"^2.6.8\",|\"debug\": \"${DEBUG_V}\",|" node_modules/babel-traverse/package.json || die
	pushd node_modules/babel-traverse || die
	npm i debug@"${DEBUG_V}" --save-prod || die
	popd

	_npm_audit_package_lock_update node_modules/babel-traverse/node_modules/babel-runtime

	# fix circular
	npm dedupe

	_npm_audit_package_lock_update node_modules/git-spawned-stream
	_npm_audit_fix node_modules/git-spawned-stream

	einfo "npm-secaudit_src_postprepare DONE"
}

src_install() {
	npm-secaudit_install "*"

	#create wrapper
	mkdir -p "${D}/usr/bin"
	echo "#!/bin/bash" > "${D}/usr/bin/${PN}"
	echo "/usr/bin/node /usr/$(get_libdir)/node/${PN}/${SLOT}/bin \$@" >> "${D}/usr/bin/${PN}"
	chmod +x "${D}"/usr/bin/${PN}
}