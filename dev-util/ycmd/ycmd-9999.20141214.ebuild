# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

PYTHON_COMPAT=( python2_7 )

inherit eutils python-r1

DESCRIPTION="A code-completion & code-comprehension server"
HOMEPAGE=""
#around time gycm last commit
#https://github.com/Valloric/ycmd/commits/master?after=Y3Vyc29yOr3iUUspUqC5tVJRrSZXDnNClH0YKzExMTk%3D
COMMIT="0af509bcda444853836ba740b6b4fbcdea3f8f6c"
SRC_URI="https://github.com/Valloric/ycmd/archive/${COMMIT}.zip -> ${P}.zip"
KEYWORDS="~amd64 ~x86"
SLOT="0"
LICENSE="GPL-3"

IUSE="system-boost system-clang csharp c++ c objc objc++ python tests"
REQUIRED_USE="system-clang? ( || ( c c++ objc objc++ ) )"

COMMON_DEPEND="
	${PYTHON_DEPS}
	system-clang? ( >=sys-devel/clang-3.8 )
	system-boost? ( >=dev-libs/boost-1.57[python,threads,${PYTHON_USEDEP}] )
"
RDEPEND="
	${COMMON_DEPEND}
	python? ( dev-python/jedihttp[${PYTHON_USEDEP}] )
	csharp? ( dev-dotnet/omnisharp-server )
	dev-python/argparse[${PYTHON_USEDEP}]
	>=dev-python/bottle-0.12.7[${PYTHON_USEDEP}]
	dev-python/frozendict[${PYTHON_USEDEP}]
	dev-python/future[${PYTHON_USEDEP}]
	dev-python/requests[${PYTHON_USEDEP}]
	dev-python/sh[${PYTHON_USEDEP}]
	=dev-python/waitress-0.8.10-r2[${PYTHON_USEDEP}]
	system-clang? (
	        c? ( sys-devel/clang )
	        c++? ( sys-devel/clang )
	        objc? ( sys-devel/clang )
	        objc++? ( sys-devel/clang )
	)
	tests? ( dev-python/pyhamcrest
		 dev-python/webtest
		 dev-python/flake8
		 dev-python/mock
		 dev-python/nose
		 dev-python/nose-exclude
        )
"
DEPEND="
	${COMMON_DEPEND}
"

S="${WORKDIR}/${PN}-${COMMIT}"

src_prepare() {
	eapply "${FILESDIR}/${PN}-9999.20141214-skip-thirdparty-check.patch"
	eapply "${FILESDIR}/${PN}-9999.20141214-exe-paths.patch"
	eapply "${FILESDIR}/${PN}-9999.20141214-no-third-party-folder-check.patch"
	eapply "${FILESDIR}/${PN}-9999.20141214-force-python-libs-path.patch"
	#eapply "${FILESDIR}/${PN}-9999.20170107-core-version-path.patch"

	#eapply "${FILESDIR}/${PN}-9999.20170107-bottle-0.12.11.patch"

	if use csharp ; then
		cp -a "${FILESDIR}/omnisharp.sh.net45" "${WORKDIR}/omnisharp.sh"
		sed -i -e "s|GENTOO_OMNISHARP_SERVER_PATH|/usr/$(get_libdir)/mono/omnisharp-server|g"  "${WORKDIR}/omnisharp.sh"
	fi

	eapply "${FILESDIR}/${PN}-9999.20141214-no-prepend-mono.patch"

	eapply_user

	python_copy_sources

	python_foreach_impl python_prepare_all
}

python_prepare_all() {
	cd "${WORKDIR}/${PN}-${COMMIT}-${EPYTHON//./_}"

	echo "python is ${EPYTHON}"

	sed -i -e "s|lib64|$(get_libdir)|g" ycmd/completers/cs/cs_completer.py
	#sed -i -e "s|lib64|$(get_libdir)|g" ycmd/completers/javascript/tern_completer.py
	#sed -i -e "s|0.20.0|$(ls /usr/$(get_libdir)/node/tern/ | tail -n 1)|g" ycmd/completers/javascript/tern_completer.py

	if [[ "${EPYTHON}" == "python2.7" ]] ; then
		echo "editing 2.7"
		sed -i -e "s|GENTOO_PYTHON_LIBRARY|/usr/$(get_libdir)/libpython2.7.so|" build.sh || die
		sed -i -e "s|GENTOO_PYTHON_INCLUDE_DIR|/usr/include/python2.7|" build.sh || die
	elif [[ "${EPYTHON}" == "python3.4" ]] ; then
		echo "editing 3.4"
		sed -i -e "s|GENTOO_PYTHON_LIBRARY|/usr/$(get_libdir)/libpython3.4m.so|" build.sh || die
		sed -i -e "s|GENTOO_PYTHON_INCLUDE_DIR|/usr/include/python3.4m|" build.sh || die
	else
		die "not currently supported.  notify the package maintainer or hand edit it."
	fi

	if use csharp ; then
		sed -i -e "s|GENTOO_OMNISHARP|/usr/$(get_libdir)/${EPYTHON}/site-packages/ycmd/completers/cs/omnisharp.sh|g" ycmd/completers/cs/cs_completer.py || die
	fi

	cp "${FILESDIR}/default_settings.json" ycmd/default_settings.json

	sed -i -e "s|HFJ1aRMhtCX/DMYWYkUl9g==|$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16 | base64)|g" ycmd/default_settings.json || die
	sed -i -e "s|/usr/bin/python3.4|/usr/bin/${EPYTHON}|g" ycmd/default_settings.json || die
}

src_compile() {
	#bypass setup.py check
	python_foreach_impl python_compile_all
}

python_compile_all() {
	cd "${WORKDIR}/${PN}-${COMMIT}-${EPYTHON//./_}"
	myargs=""
	use system-boost && myargs+=" --system-boost"
	use system-clang && myargs+=" --system-libclang"
	if use c || use c++ || use objc || use objc++ ; then
		myargs+=" --clang-completer"
	fi

	if use system-clang ; then
		export EXTRA_CMAKE_ARGS="-DEXTERNAL_LIBCLANG_PATH=/usr/$(get_libdir)/libclang.so"
	fi
	if use system-boost ; then
		export EXTRA_CMAKE_ARGS+=" -DUSE_SYSTEM_BOOST=1"
	fi
	./build.sh ${myargs}
	mkdir "${WORKDIR}/${EPYTHON}"
	cp -a "ycm_core.so" "${WORKDIR}/${EPYTHON}"
}

src_install() {
	#bypass setup.py check
	python_foreach_impl python_install_all
}

python_install_all() {
	cd "${WORKDIR}/${PN}-${COMMIT}-${EPYTHON//./_}"
	mkdir -p "${D}/$(python_get_sitedir)/ycmd"
	cp "${WORKDIR}/${EPYTHON}/ycm_core.so" "${D}/$(python_get_sitedir)"
	#cp "CORE_VERSION" "${D}/$(python_get_sitedir)/ycmd"

	cp -a "cpp/ycm/.ycm_extra_conf.py" "${D}/$(python_get_sitedir)/ycmd"
	if use csharp ; then
		cp -a "${WORKDIR}/omnisharp.sh" "ycmd/completers/cs/"
	fi

	rm -rf "ycmd/tests"
	rm -rf "ycmd/completers/general/tests"

	python_domodule ycmd

	if use csharp ; then
		chmod 755 "${D}/$(python_get_sitedir)/ycmd/completers/cs/omnisharp.sh"
	fi
}

src_test() {
	#disabled because tests are poor quality
	#python_foreach_impl python_install_all
	true
}
python_test_all() {
	cp "${WORKDIR}/${EPYTHON}" ./
	cp "${S}/CORE_VERSION" ./ycmd
	./run_tests.py --skip-build
}

pkg_postinst() {
	einfo "Examples of the .json files can be found at targeting particular python version:"
	if use python_targets_python2_7 ; then
		einfo "/usr/$(get_libdir)/python2.7/site-packages/ycmd/default_settings.json"
	fi

	if use c || use c++ || use objc || use objc++ ; then
		einfo ""
		einfo "You need to edit the global_ycm_extra_conf property in your .json file per project to the full path of the .ycm_extra_conf.py."

		einfo ""
		einfo "Examples of the .ycm_extra_conf.py which should be defined per project can be found at:"
		if use python_targets_python2_7 ; then
			einfo "/usr/$(get_libdir)/python2.7/site-packages/ycmd/.ycm_extra_conf.py"
		fi

		einfo ""
		einfo "Consider emerging ycm-generator to properly generate a .ycm_extra_conf.py which is mandatory for c/c++/objc/objc++."
		einfo "After generating it, it may need to be slightly modified."
	fi

	if use csharp ; then
		einfo "You need a .sln file in your project for C# support"
	fi

	#if use javascript ; then
	#	einfo "You need a .tern-project in your project for javascript support."
	#fi

	einfo ""
        einfo "You must generate a 16 byte HMAC secret wrapped in base64 for the hmac_secret property of your .json file:"
        einfo "Do: openssl rand -base64 16"
        einfo "or"
        einfo "Do: < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16 | base64"
}
