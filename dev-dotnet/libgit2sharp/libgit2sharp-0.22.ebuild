# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

KEYWORDS="~x86 ~amd64"

USE_DOTNET="net45"
EBUILD_FRAMEWORK="4.5"
IUSE="${USE_DOTNET} +gac +nupkg"
IUSE+=" monodevelop"
REQUIRED_USE="|| ( ${USE_DOTNET} ) nupkg"

inherit nupkg

DESCRIPTION="A C# PInvoke wrapper library for LibGit2 C library"

EGIT_COMMIT="8daef23223e1374141bf496e4b310ded9ae4639e"
HOMEPAGE="https://github.com/libgit2/libgit2sharp"
SRC_URI="${HOMEPAGE}/archive/${EGIT_COMMIT}.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}/${PN}-${EGIT_COMMIT}"

LICENSE="MIT"
SLOT="0"

CDEPEND="
	dev-libs/libgit2
"

DEPEND="${CDEPEND}
	dev-dotnet/nuget
"
RDEPEND="${CDEPEND}"

NUSPEC_FILE="nuget.package/LibGit2Sharp.nuspec"
SNK_FILENAME="${S}/LibGit2Sharp/libgit2sharp.snk"

src_unpack() {
	default
	# remove rogue binaries
	rm -rf "${S}/Lib/NuGet/" || die
	rm -rf "${S}/Lib/CustomBuildTasks/CustomBuildTasks.dll" || die
}

src_prepare() {
	addpredict /etc/mono/registry/last-btime
	if use monodevelop ; then
		eapply "${FILESDIR}/libgit2sharp-0.22-monodevelop.patch"
		eapply "${FILESDIR}/remove-NativeBinaries-package-dependency-monodevelop.patch"
	else
		eapply "${FILESDIR}/csproj-remove-nuget-targets-check.patch"
		eapply "${FILESDIR}/remove-NativeBinaries-package-dependency.patch"
	fi
	eapply "${FILESDIR}/sln.patch"
	eapply "${FILESDIR}/packages-config-remove-xunit.patch"
	eapply "${FILESDIR}/nuspec-file-list.patch"
	echo "/usr/lib64/libgit2.so" >"LibGit2Sharp/libgit2_filename.txt" || die
	enuget_restore "LibGit2Sharp.sln"
	sed -i 's=\$id\$=LibGit2Sharp=g' "${NUSPEC_FILE}" || die
	sed -i "s=\\\$version\\\$=$(get_version_component_range 1-2)=g" "${NUSPEC_FILE}" || die
	sed -i 's=\$author\$=nulltoken=g' "${NUSPEC_FILE}" || die
	sed -i "s=\\\$description\\\$=${DESCRIPTION}=g" "${NUSPEC_FILE}" || die
	if use debug; then
		DIR="Debug"
	else
		DIR="Release"
	fi
	sed -i "s=\\\$configuration\\\$=${DIR}=g" "${NUSPEC_FILE}" || die

	default
}

src_compile() {
	# recreate custom build tasks .dll
	sed -i "s#<OutputPath>.*</OutputPath>#<OutputPath>.</OutputPath>#g" "Lib/CustomBuildTasks/CustomBuildTasks.csproj" || die
	exbuild_strong "Lib/CustomBuildTasks/CustomBuildTasks.csproj"

	# main compilation
	exbuild "LibGit2Sharp.sln"

	enuspec "${NUSPEC_FILE}"
}

genlibdir() {
	prefix=${PREFIX}/usr
	exec_prefix=${prefix}
	libdir=${exec_prefix}/$(get_libdir)/mono/${EBUILD_FRAMEWORK}
}

src_install() {
	genlibdir
	insinto "${libdir}"
	if use debug; then
		DIR="Debug"
	else
		DIR="Release"
	fi
	doins "LibGit2Sharp/bin/${DIR}/LibGit2Sharp.dll"

	enupkg "${WORKDIR}/LibGit2Sharp.0.22.nupkg"

	insinto "/usr/$(get_libdir)/mono/${PN}"
	doins LibGit2Sharp/libgit2sharp.snk

	if use developer ; then
		insinto "/usr/$(get_libdir)/mono/${PN}"
		doins LibGit2Sharp/bin/${DIR}/LibGit2Sharp.dll.mdb
		doins LibGit2Sharp/bin/${DIR}/LibGit2Sharp.xml
	fi

	dotnet_multilib_comply
}

pkg_postinst() {
	genlibdir

	if use gac; then
		for x in ${USE_DOTNET} ; do
			FW_UPPER=${x:3:1}
			FW_LOWER=${x:4:1}
			einfo "strong signing"
			sn -R /usr/$(get_libdir)/mono/${FW_UPPER}.${FW_LOWER}/LibGit2Sharp.dll "/usr/$(get_libdir)/mono/${PN}/libgit2sharp.snk" || die
			einfo "adding to GAC"
			gacutil -i "/usr/$(get_libdir)/mono/${FW_UPPER}.${FW_LOWER}/LibGit2Sharp.dll" || die
		done
	fi

	# cd "${WORKDIR}
	# nuget push -source "Local NuGet packages" LibGit2Sharp.0.22.nupkg
}

pkg_postrm() {
	genlibdir

	if use gac; then
		for x in ${USE_DOTNET} ; do
			FW_UPPER=${x:3:1}
			FW_LOWER=${x:4:1}
			einfo "removing from GAC"
			gacutil -u LibGit2Sharp
			# don't die, it there is no such assembly in GAC
		done
	fi

	# yes | nuget delete -source "Local NuGet packages" LibGit2Sharp 0.22
}

