# Copyright 1999-2019 Gentoo Authors
# Copyright 2019 Orson Teodoro
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: electron-app.eclass
# @MAINTAINER:
# Orson Teodoro <orsonteodoro@hotmail.com>
# @AUTHOR:
# Orson Teodoro <orsonteodoro@hotmail.com>
# @SUPPORTED_EAPIS: 4 5
# @BLURB: Eclass for Electron packages
# @DESCRIPTION:
# The electron-app eclass defines phase functions and utility functions for
# Electron app packages. It depends on the app-portage/npm-secaudit package to
# maintain a secure environment.

case "${EAPI:-0}" in
        0|1|2|3)
                die "Unsupported EAPI=${EAPI:-0} (too old) for ${ECLASS}"
                ;;
        4|5|6)
                ;;
        *)
                die "Unsupported EAPI=${EAPI} (unknown) for ${ECLASS}"
                ;;
esac

inherit desktop eutils

EXPORT_FUNCTIONS pkg_setup src_unpack pkg_postinst pkg_postrm

DEPEND+=" app-portage/npm-secaudit"
IUSE+=" debug"

NPM_PACKAGE_DB="/var/lib/portage/npm-packages"
YARN_PACKAGE_DB="/var/lib/portage/yarn-packages"
ELECTRON_APP_REG_PATH=""

ELECTRON_APP_MODE=${ELECTRON_APP_MODE:="npm"} # can be npm, yarn
ELECTRON_APP_PRUNE=${ELECTRON_APP_PRUNE:="1"}
ELECTRON_APP_AUDIT_FIX=${ELECTRON_APP_AUDIT_FIX:="1"}
ELECTRON_APP_MAXSOCKETS=${ELECTRON_APP_MAXSOCKETS:="1"} # Set this in your make.conf to control number of HTTP requests.  50 is npm default but it is too high.
_NPM_CACHE_LOCK=/run/lock/npm_cache

# @FUNCTION: _electron-app_fix_locks
# @DESCRIPTION:
# Restores ownership change caused by yarn
_electron-app_fix_locks() {
	local d="${NPM_STORE_DIR}"
	local f="_locks"
	local dt="${d}/${f}"
	if [ -d "${dt}" ] ; then
		local u=$(ls -l "${d}" | grep "${f}" | column -t | cut -f 5 -d ' ')
		local g=$(ls -l "${d}" | grep "${f}" | column -t | cut -f 7 -d ' ')
		if [[ "$u" == "root" && "$g" == "root" ]] ; then
			einfo "Restoring portage ownership on ${dt}"
			chown portage:portage -R "${dt}"
		fi
	fi
}

# @FUNCTION: _electron-app_fix_logs
# @DESCRIPTION:
# Restores ownership change to logs
_electron-app_fix_logs() {
	local d="${NPM_STORE_DIR}"
	local f="_logs"
	local dt="${d}/${f}"
	if [ -d "${dt}" ] ; then
		local u=$(ls -l "${d}" | grep "${f}" | column -t | cut -f 5 -d ' ')
		local g=$(ls -l "${d}" | grep "${f}" | column -t | cut -f 7 -d ' ')
		if [[ "$u" == "root" && "$g" == "root" ]] ; then
			einfo "Restoring portage ownership on ${dt}"
			chown portage:portage -R "${dt}"
		fi
	fi
}

# @FUNCTION: _electron-app_fix_yarn_access
# @DESCRIPTION:
# Restores ownership change caused by yarn
_electron-app_fix_yarn_access() {
	local d="${HOME}"
	local f=".config"
	local dt="${d}/${f}"
	if [ -d "${dt}" ] ; then
		local u=$(ls -l "${d}" | grep "${f}" | column -t | cut -f 5 -d ' ')
		local g=$(ls -l "${d}" | grep "${f}" | column -t | cut -f 7 -d ' ')
		if [[ "$u" == "root" && "$g" == "root" ]] ; then
			einfo "Restoring portage ownership on ${dt}"
			chown portage:portage -R "${dt}"
		fi
	fi
}

# @FUNCTION: _electron-app_fix_cacache_access
# @DESCRIPTION:
# Restores ownership change on cacache
_electron-app_fix_cacache_access() {
	local d="${NPM_STORE_DIR}"
	local f="_cacache"
	local dt="${d}/${f}"
	if [ -d "${dt}" ] ; then
		local u=$(ls -l "${d}" | grep "${f}" | column -t | cut -f 5 -d ' ')
		local g=$(ls -l "${d}" | grep "${f}" | column -t | cut -f 7 -d ' ')
		# too slow to reset
		# todo mutex lock?  possible to run two emerges and then one instance deletes and the other uses it
		einfo "Removing ${dt}"
		rm -rf "${dt}"
	fi
	einfo "Restoring portage ownership on ${dt}"
	addwrite "${d}"
	mkdir -p "${dt}"
	chown portage:portage -R "${dt}"
}

# @FUNCTION: _electron-app_fix_index-v5_access
# @DESCRIPTION:
# Restores ownership change on cacache
_electron-app_fix_index-v5_access() {
	local d="${NPM_STORE_DIR}"
	local f="index-v5"
	local dt="${d}/${f}"
	if [ -d "${dt}" ] ; then
		local u=$(ls -l "${d}" | grep "${f}" | column -t | cut -f 5 -d ' ')
		local g=$(ls -l "${d}" | grep "${f}" | column -t | cut -f 7 -d ' ')
		if [[ "$u" == "root" && "$g" == "root" ]] ; then
			einfo "Restoring portage ownership on ${dt}"
			chown portage:portage -R "${dt}"
		fi
	fi
}

# @FUNCTION: _electron-app-flakey-check
# @DESCRIPTION:
# Warns user that download or building can fail randomly
_electron-app-flakey-check() {
	local l=$(find "${S}" -name "package.json")
	grep -r -e "electron-builder" $l >/dev/null
	if [[ "$?" == "0" ]] ; then
		ewarn "This ebuild may fail when building with electron-builder.  Re-emerge if it fails."
	fi

	grep -r -e "\"electron\":" $l >/dev/null
	if [[ "$?" == "0" ]] ; then
		ewarn "This ebuild may fail when downloading Electron as a dependency.  Re-emerge if it fails."
	fi
}

# @FUNCTION: electron-app_dedupe_npm
# @DESCRIPTION:
# Replaces duplicate packages into a single package.
electron-app_dedupe_npm() {
	einfo "Deduping packages"
	npm dedupe || die
}

# @FUNCTION: electron-app_audit_fix_npm
# @DESCRIPTION:
# Removes vulnerable packages.  It will audit every folder containing a package-lock.json
electron-app_audit_fix_npm() {
	if [[ "${ELECTRON_APP_AUDIT_FIX}" == "1" ||
		"${ELECTRON_APP_AUDIT_FIX,,}" == "true" ]] ; then

		einfo "Performing recursive package-lock.json audit fix"
		L=$(find . -name "package-lock.json")
		for l in $L; do
			pushd $(dirname $l) || die
			[ -e package-lock.json ] && rm package-lock.json
			einfo "Running \`npm i --package-lock\`"
			npm i --package-lock || die
			einfo "Running \`npm audit fix --force\`"
			npm audit fix --force --maxsockets=${ELECTRON_APP_MAXSOCKETS} || die "location: $l"
			popd
		done
		einfo "Audit fix done"
	fi
}

# @FUNCTION: electron-app_audit_fix
# @DESCRIPTION:
# Removes vulnerable packages based on the packaging system.
electron-app_audit_fix() {
	case "$ELECTRON_APP_MODE" in
		npm)
			electron-app_audit_fix_npm
			;;
		yarn)
			# use npm audit anyway?
			ewarn "No audit fix implemented in yarn.  Package may be likely vulnerable."
			;;
		*)
			;;
	esac

}

# @FUNCTION: electron-app_pkg_setup
# @DESCRIPTION:
# Initializes globals
electron-app_pkg_setup() {
        debug-print-function ${FUNCNAME} "${@}"

	export ELECTRON_VER=$(strings /usr/bin/electron | grep "%s Electron/" | sed -e "s|[%s A-Za-z/]||g")
	export NPM_STORE_DIR="${PORTAGE_ACTUAL_DISTDIR:-${DISTDIR}}/npm"
	export YARN_STORE_DIR="${PORTAGE_ACTUAL_DISTDIR:-${DISTDIR}}/yarn"

	case "$ELECTRON_APP_MODE" in
		npm)
			# Lame bug.  We cannot run `electron --version` because it requires X.
			# It is okay to emerge package outside of X without problems.
			export npm_config_cache="${NPM_STORE_DIR}"
			einfo "Electron version: ${ELECTRON_VER}"
			if [[ -z "${ELECTRON_VER}" ]] ; then
				echo "Some ebuilds may break.  Restart and run in X."
			fi

			addwrite "${PORTAGE_ACTUAL_DISTDIR:-${DISTDIR}}"
			mkdir -p "${NPM_STORE_DIR}/offline"

			# Some npm package.json use yarn.
			addwrite ${PORTAGE_ACTUAL_DISTDIR:-${DISTDIR}}
			mkdir -p ${YARN_STORE_DIR}/offline
			export YARN_CACHE_FOLDER=${YARN_CACHE_FOLDER:=${YARN_STORE_DIR}}

			_electron-app_fix_locks
			_electron-app_fix_logs
			_electron-app_fix_cacache_access
			_electron-app_fix_index-v5_access
			;;
		yarn)
			ewarn "Using yarn mode which has no audit fix yet."

			# Some npm package.json use yarn.
			addwrite ${PORTAGE_ACTUAL_DISTDIR:-${DISTDIR}}
			mkdir -p ${YARN_STORE_DIR}/offline
			export YARN_CACHE_FOLDER=${YARN_CACHE_FOLDER:=${YARN_STORE_DIR}}
			;;
		*)
			die "Unsupported package system"
			;;
	esac
}

# @FUNCTION: electron-app_fetch_deps_npm
# @DESCRIPTION:
# Fetches an Electron npm app with security checks
# MUST be called after default unpack AND patching.
electron-app_fetch_deps_npm() {
	_electron-app-flakey-check

	pushd "${S}" || die
	npm install --maxsockets=${ELECTRON_APP_MAXSOCKETS} || die
	popd
}

# @FUNCTION: electron-app_fetch_deps_yarn
# @DESCRIPTION:
# Fetches an Electron yarn app with security checks
# MUST be called after default unpack AND patching.
electron-app_fetch_deps_yarn() {
	pushd "${S}" || die
		export FAKEROOTKEY="15574641" # don't check /usr/local/share/.yarnrc .  same number used in their testing.

		# set global dir
		cp "${S}"/.yarnrc{,.orig}
		echo "prefix \"${S}/.yarn\"" >> "${S}/.yarnrc" || die
		echo "global-folder \"${S}/.yarn\"" >> "${S}/.yarnrc" || die
		echo "offline-cache-mirror \"${YARN_STORE_DIR}/offline\"" >> "${S}/.yarnrc" || die

		mkdir -p "${S}/.yarn"
		einfo "yarn prefix: $(yarn config get prefix)"
		einfo "yarn global-folder: $(yarn config get global-folder)"
		einfo "yarn offline-cache-mirror: $(yarn config get offline-cache-mirror)"

		yarn install --network-concurrency ${ELECTRON_APP_MAXSOCKETS} --verbose || die
		# todo yarn audit auto patch
		# an analog to yarn audix fix doesn't exit yet
	popd
}

# @FUNCTION: electron-app_fetch_deps
# @DESCRIPTION:
# Fetches an electron app with security checks
# MUST be called after default unpack AND patching.
electron-app_fetch_deps() {
	cd "${S}"

	_electron-app_fix_yarn_access

	cd "${S}"

	# todo handle yarn
	case "$ELECTRON_APP_MODE" in
		npm)
			_electron-app_fix_locks
			electron-app_fetch_deps_npm
			;;
		yarn)
			electron-app_fetch_deps_yarn
			;;
		*)
			die "Unsupported package system"
			;;
	esac
}

# @FUNCTION: electron-app_src_unpack
# @DESCRIPTION:
# Unpacks sources
electron-app_src_unpack() {
        debug-print-function ${FUNCNAME} "${@}"

	cd "${WORKDIR}"

	default_src_unpack

	# all the phase hooks get run in unpack because of download restrictions

	cd "${S}"
	if declare -f electron-app_src_preprepare > /dev/null ; then
		electron-app_src_preprepare
	fi

	cd "${S}"
	if declare -f electron-app_src_prepare > /dev/null ; then
		electron-app_src_prepare
	else
		electron-app_src_prepare_default
	fi

	cd "${S}"
	electron-app_audit_fix

	cd "${S}"
	if declare -f electron-app_src_postprepare > /dev/null ; then
		electron-app_src_postprepare
	fi

	electron-app_dedupe_npm
	# post dedupe hook?

	# audit before possibly bundling a vulnerable package
	electron-app_audit_dev

	cd "${S}"
	if declare -f electron-app_src_compile > /dev/null ; then
		electron-app_src_compile
	else
		electron-app_src_compile_default
	fi

	cd "${S}"
	if declare -f electron-app_src_postcompile > /dev/null ; then
		electron-app_src_postcompile
	fi

	cd "${S}"
	if declare -f electron-app_src_preinst > /dev/null ; then
		electron-app_src_preinst
	else
		electron-app_src_preinst_default
	fi

	cd "${S}"
	electron-app_dedupe_and_prune
}

# @FUNCTION: electron-app_src_prepare_default
# @DESCRIPTION:
# Fetches dependencies and audit fixes them.  Currently a stub.  TODO per package patching support.
electron-app_src_prepare_default() {
        debug-print-function ${FUNCNAME} "${@}"

	cd "${S}"
	electron-app_fetch_deps
	cd "${S}"
	#default_src_prepare
}

# @FUNCTION: electron-app_install_default
# @DESCRIPTION:
# Installs the app.  Currently a stub.
electron-app_src_install_default() {
        debug-print-function ${FUNCNAME} "${@}"

	cd "${S}"

	die "currently uninplemented.  must override"
# todo electron-app_src_install_default
}

# @FUNCTION: electron-app-build-npm
# @DESCRIPTION:
# Builds an electron app with npm
electron-app-build-npm() {
	# electron-builder can still pull packages at the build step.
	npm run build --maxsockets=${ELECTRON_APP_MAXSOCKETS} || die
}

# @FUNCTION: electron-app-build-yarn
# @DESCRIPTION:
# Builds an electron app with yarn
electron-app-build-yarn() {
	yarn run build || die
}

# @FUNCTION: electron-app_src_compile_default
# @DESCRIPTION:
# Builds an electron app.
electron-app_src_compile_default() {
        debug-print-function ${FUNCNAME} "${@}"

	cd "${S}"

	case "$ELECTRON_APP_MODE" in
		npm)
			electron-app-build-npm
			;;
		yarn)
			electron-app-build-yarn
			;;
		*)
			die "Unsupported package system"
			;;
	esac
}

# @FUNCTION: electron-app_audit_dev
# @DESCRIPTION:
# This will preform an recursive audit in place without adding packages.
electron-app_audit_dev() {
	[ ! -e package-lock.json ] && die "Missing package-lock.json in implied root $(pwd)"

	L=$(find . -name "package-lock.json")
	for l in $L; do
		pushd $(dirname $l) || die
		npm audit || die
		popd
	done
}


# @FUNCTION: electron-app_audit_prod
# @DESCRIPTION:
# This will preform an recursive audit for production in place without adding packages ignoring pruned packages.
electron-app_audit_prod() {
	[ ! -e package-lock.json ] && die "Missing package-lock.json in implied root $(pwd)"

	L=$(find . -name "package-lock.json")
	for l in $L; do
		pushd $(dirname $l) || die
		[ -e "${T}"/npm-secaudit-result ] && rm "${T}"/npm-secaudit-result
		npm audit &> "${T}"/npm-secaudit-result
		cat "${T}"/npm-secaudit-result | grep "ELOCKVERIFY" >/dev/null
		if [[ "$?" != "0" ]] ; then
			cat "${T}"/npm-secaudit-result | grep "require manual review" >/dev/null
			local result_found1="$?"
			cat "${T}"/npm-secaudit-result | grep "npm audit fix" >/dev/null
			local result_found2="$?"
			if [[ "${result_found1}" == "0" || "${result_found2}" == "0" ]] ; then
				die "package is still vulnerable at $(pwd)$l"
			fi
		fi
		popd
	done
}

# @FUNCTION: electron-app_src_preinst_default
# @DESCRIPTION:
# Dummy function
electron-app_src_preinst_default() {
	true
}

# @FUNCTION: electron-app_dedupe_and_prune
# @DESCRIPTION:
# Preforms dedupe and pruning
electron-app_dedupe_and_prune() {
	einfo "Deduping and pruning"

	cd "${S}"

	case "$ELECTRON_APP_MODE" in
		npm)
			electron-app_dedupe_npm

			electron-app_store_package_jsons "${S}"

			if ! use debug ; then
				if [[ "${ELECTRON_APP_PRUNE}" == "1" ||
					"${ELECTRON_APP_PRUNE,,}" == "true" ]] ; then
					einfo "Running \`npm prune --production\`"
					npm prune --production
				fi
			fi

			#electron-app_audit_prod
			electron-app_audit_dev

			electron-app_restore_package_jsons "${S}"

			;;
		yarn)
			electron-app_store_package_jsons "${S}"

			if ! use debug ; then
				if [[ "${ELECTRON_APP_PRUNE}" == "1" ||
					"${ELECTRON_APP_PRUNE,,}" == "true" ]] ; then
					einfo "Running \`yarn install --production --ignore-scripts --prefer-offline\`"
					yarn install --production --ignore-scripts --prefer-offline
				fi
			fi

			cp "${S}"/.yarnrc{,.orig}
			echo "global-folder \"/usr/$(get_libdir)/node/${PN}/${SLOT}/.yarn\"" >> "${S}/.yarnrc" || die
			echo "prefix \"/usr/$(get_libdir)/node/${PN}/${SLOT}/.yarn\"" >> "${S}/.yarnrc" || die

			# todo final audit fix

			electron-app_restore_package_jsons "${S}"

			;;
		*)
			die "Unsupported package system"
			;;
	esac
}

# @FUNCTION: electron-app_desktop_install
# @DESCRIPTION:
# Installs a desktop app with wrapper and desktop menu entry.
electron-app_desktop_install() {
	local rel_src_path="$1"
	local rel_icon_path="$2"
	local pkg_name="$3"
	local category="$4"
	local cmd="$5"

	case "$ELECTRON_APP_MODE" in
		npm)
			local old_dotglob=$(shopt dotglob | cut -f 2)
			shopt -s dotglob # copy hidden files

			mkdir -p "${D}/usr/$(get_libdir)/node/${PN}/${SLOT}"
			cp -a ${rel_src_path} "${D}/usr/$(get_libdir)/node/${PN}/${SLOT}"

			if [[ "${old_dotglob}" == "on" ]] ; then
				shopt -s dotglob
			else
				shopt -u dotglob
			fi
			;;
		yarn)
			local old_dotglob=$(shopt dotglob | cut -f 2)
			shopt -s dotglob # copy hidden files

			mkdir -p "${D}/usr/$(get_libdir)/node/${PN}/${SLOT}"
			cp -a ${rel_src_path} "${D}/usr/$(get_libdir)/node/${PN}/${SLOT}"

			if [[ "${old_dotglob}" == "on" ]] ; then
				shopt -s dotglob
			else
				shopt -u dotglob
			fi
			;;
		*)
			die "Unsupported package system"
			;;
	esac

	# Create wrapper
	mkdir -p "${D}/usr/bin"
	echo "#!/bin/bash" > "${D}/usr/bin/${PN}"
	echo "${cmd}" >> "${D}/usr/bin/${PN}"
	chmod +x "${D}"/usr/bin/${PN}

	newicon "${rel_icon_path}" "${PN}.png"
	make_desktop_entry ${PN} "${pkg_name}" ${PN} "${category}"
}

# @FUNCTION: electron-app-register-x
# @DESCRIPTION:
# Adds the package to the electron database
# This function MUST be called in pkg_postinst.
electron-app-register-x() {
	local pkg_db="${1}"
	local rel_path=${2:-""}
	local check_path="/usr/$(get_libdir)/node/${PN}/${SLOT}/${rel_path}"
	# format:
	# ${CATEGORY}/${P}	path_to_package
	addwrite "${pkg_db}"

	# remove existing entry
	touch "${pkg_db}"
	sed -i -e "s|${CATEGORY}/${PN}:${SLOT}\t.*||g" "${pkg_db}"

	echo -e "${CATEGORY}/${PN}:${SLOT}\t${check_path}" >> "${pkg_db}"

	# remove blank lines
	sed -i '/^$/d' "${pkg_db}"
}

# @FUNCTION: electron-app-register-npm
# @DESCRIPTION:
# Adds the package to the electron database
# This function MUST be called in pkg_postinst.
electron-app-register-npm() {
	local rel_path=${1:-""}
	electron-app-register-x "${NPM_PACKAGE_DB}" "${rel_path}"
}

# @FUNCTION: electron-app-register-yarn
# @DESCRIPTION:
# Adds the package to the electron database
# This function MUST be called in pkg_postinst.
electron-app-register-yarn() {
	local rel_path=${1:-""}
	electron-app-register-x "${YARN_PACKAGE_DB}" "${rel_path}"
}

# @FUNCTION: electron-app_pkg_postinst
# @DESCRIPTION:
# Automatically registers an electron app package.
# Set ELECTRON_APP_REG_PATH global to relative path to
# scan for vulnerabilities containing node_modules.
electron-app_pkg_postinst() {
        debug-print-function ${FUNCNAME} "${@}"
	case "$ELECTRON_APP_MODE" in
		npm)
			electron-app-register-npm "${ELECTRON_APP_REG_PATH}"
			;;
		yarn)
			electron-app-register-yarn "${ELECTRON_APP_REG_PATH}"
			;;
		*)
			die "Unsupported package system"
			;;
	esac
}

# @FUNCTION: electron-app_pkg_postrm
# @DESCRIPTION:
# Post-removal hook for Electron apps. Removes information required for security checks.
electron-app_pkg_postrm() {
        debug-print-function ${FUNCNAME} "${@}"

	case "$ELECTRON_APP_MODE" in
		npm)
			sed -i -e "s|${CATEGORY}/${PN}:${SLOT}\t.*||g" "${NPM_PACKAGE_DB}"
			sed -i '/^$/d' "${NPM_PACKAGE_DB}"
			;;
		yarn)
			sed -i -e "s|${CATEGORY}/${PN}:${SLOT}\t.*||g" "${YARN_PACKAGE_DB}"
			sed -i '/^$/d' "${YARN_PACKAGE_DB}"
			;;
		*)
			die "Unsupported package system"
			;;
	esac
}

# @FUNCTION: electron-app_store_package_jsons
# @DESCRIPTION: Saves the package{,-lock}.json to T for auditing
electron-app_store_package_jsons() {
	einfo "Saving package.json and package-lock.json for future audits ..."

	local old_dotglob=$(shopt dotglob | cut -f 2)
	shopt -s dotglob # copy hidden files

	local ROOTDIR="${1}"
	local d
	local rd
	local F=$(find ${ROOTDIR} -name "package*.json*" -o -name "yarn.lock")
	local td="${T}/package_jsons/"
	for f in $F; do
		d=$(dirname $f)
		rd=$(dirname ${f//${ROOTDIR}/})
		mkdir -p "${td}/${rd}"
		einfo "Copying $f to ${td}/${rd}"
		cp -a "${f}" "${td}/${rd}" || die
	done

	if [[ "${old_dotglob}" == "on" ]] ; then
		shopt -s dotglob
	else
		shopt -u dotglob
	fi
}

# @FUNCTION: electron-app_restore_package_jsons
# @DESCRIPTION: Restores the package{,-lock}.json to T for auditing
electron-app_restore_package_jsons() {
	local dest="${1}"
	einfo "Restoring package.jsons to ${dest} ..."

	local old_dotglob=$(shopt dotglob | cut -f 2)
	shopt -s dotglob # copy hidden files

	local td="${T}/package_jsons/${rd}"

	cp -a "${td}"/* "${dest}" || die

	if [[ "${old_dotglob}" == "on" ]] ; then
		shopt -s dotglob
	else
		shopt -u dotglob
	fi
}
