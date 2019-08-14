# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6
KEYWORDS="~amd64 ~x86"
USE_DOTNET="net45"
# cli = do install command line interface
IUSE="${USE_DOTNET} developer gac nupkg debug cli"
REQUIRED_USE="|| ( ${USE_DOTNET} ) nupkg"
inherit dotnet gac

NAME="slntools"
HOMEPAGE="https://github.com/ArsenShnurkov/${NAME}"

EGIT_COMMIT="705869e96a2f0e401be03f8e8478df3e1f2b9373"
SRC_URI="${HOMEPAGE}/archive/${EGIT_COMMIT}.zip -> ${PF}.zip
	https://github.com/mono/mono/raw/master/mcs/class/mono.snk"

RESTRICT="mirror"
S="${WORKDIR}/${NAME}-${EGIT_COMMIT}"

SLOT=0

DESCRIPTION="Validator.nu HTML Parser, a HTML5 parser, port from Java Version 1.4 to C#"
LICENSE="MIT" # https://github.com/jamietre/HtmlParserSharp/blob/master/LICENSE.txt

RDEPEND=">=dev-lang/mono-4.0.2.5"
DEPEND="${RDEPEND}
	sys-apps/sed
	nupkg? ( dev-dotnet/nuget )"

S="${WORKDIR}/${NAME}-${EGIT_COMMIT}"
SLN_FILE=SLNTools.sln
METAFILETOBUILD="${S}/Main/${SLN_FILE}"
SNK_FILENAME="${S}/mono.snk"

src_prepare() {
	eapply "${FILESDIR}/remove-wix-project-from-sln-file.patch"

	# System.EntryPointNotFoundException: GetStdHandle
	#   at (wrapper managed-to-native) CWDev.SLNTools.CommandLine.Parser:GetStdHandle (int)
	#   at CWDev.SLNTools.CommandLine.Parser.GetConsoleWindowWidth () [0x00000] in <filename unknown>:0 
	#   at CWDev.SLNTools.CommandLine.Parser.ArgumentsUsage (System.Type argumentType) [0x00000] in <filename unknown>:0 
	#   at CWDev.SLNTools.Program.Main (System.String[] args) [0x00000] in <filename unknown>:0 
	# http://stackoverflow.com/questions/23824961/c-sharp-to-mono-getconsolewindow-exception
	eapply "${FILESDIR}/console-window-width.patch"

	# no need to restore if all dependencies are from GAC
	# nuget restore "${METAFILETOBUILD}" || die

	cp "${DISTDIR}/mono.snk" "${S}"

	default
}

src_compile() {
	ARGS=""
	ARGSN=""

	if use debug; then
		ARGS="${ARGS} /p:Configuration=Debug"
		ARGSN="${ARGSN} Configuration=Debug"
	else
		ARGS="${ARGS} /p:Configuration=Release"
		ARGSN="${ARGSN} Configuration=Release"
	fi

	if use developer; then
		ARGS="${ARGS} /p:DebugSymbols=True"
	else
		ARGS="${ARGS} /p:DebugSymbols=False"
	fi

	exbuild_strong ${ARGS} ${METAFILETOBUILD}

	if use nupkg; then
		nuget pack "${FILESDIR}/${SLN_FILE}.nuspec" -Properties ${ARGSN} -BasePath "${S}" -OutputDirectory "${WORKDIR}" -NonInteractive -Verbosity detailed
	fi
}

src_install() {
	default

	DIR=""
	if use debug; then
		DIR="Debug"
	else
		DIR="Release"
	fi

	insinto "/usr/share/slntools/"

	doins Main/SLNTools.exe/bin/${DIR}/CWDev.SLNTools.Core.dll
	if use developer; then
		doins Main/SLNTools.exe/bin/${DIR}/CWDev.SLNTools.Core.dll.mdb
	fi
	einfo "Strong signing dll again"
	sn -R Main/SLNTools.exe/bin/${DIR}/CWDev.SLNTools.Core.dll "${S}"/mono.snk || die
	einfo "GAC install"
	egacinstall Main/SLNTools.exe/bin/${DIR}/CWDev.SLNTools.Core.dll

	if use cli; then
		doins Main/SLNTools.exe/bin/${DIR}/CWDev.SLNTools.UIKit.dll
		doins Main/SLNTools.exe/bin/${DIR}/SLNTools.exe
		if use developer; then
			doins Main/SLNTools.exe/bin/${DIR}/CWDev.SLNTools.UIKit.dll.mdb
			doins Main/SLNTools.exe/bin/${DIR}/SLNTools.exe.mdb
		fi
		make_wrapper slntools "mono /usr/share/slntools/SLNTools.exe"
	fi

	if use nupkg; then
		if [ -d "/var/calculate/remote/distfiles" ]; then
			# Control will enter here if the directory exist.
			# this is necessary to handle calculate linux profiles feature (for corporate users)
			elog "Installing .nupkg into /var/calculate/remote/packages/NuGet"
			insinto /var/calculate/remote/packages/NuGet
		else
			# this is for all normal gentoo-based distributions
			elog "Installing .nupkg into /usr/local/nuget/nupkg"
			insinto /usr/local/nuget/nupkg
		fi
		doins "${WORKDIR}/SLNTools.1.1.3.nupkg"
	fi

	dotnet_multilib_comply
}
