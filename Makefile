SHELL       := /bin/bash
WORKINGDIR  := /var/www/sites/apt
TEMPDIR     := $(WORKINGDIR)/debs/temp
SED         := sed

ifndef SIGN
SIGN   := 0
endif

all: clean repo

clean:
	if [[ -d $(TEMPDIR) ]]; then \
		rm -rf $(TEMPDIR)/*; \
		printf "Removed temp directory.\n\n"; \
	else \
		printf "Nothing to clean.\n\n"; \
	fi

setup: clean
	if [[ -d $(TEMPDIR) ]]; then \
		printf "Using existing temp directory.\n\n"; \
	else \
		mkdir -p $(TEMPDIR); \
		printf "Set up temporary directory.\n\n"; \
	fi

pojavlauncher-release: setup
	LOCALSHA=$$(cat $(WORKINGDIR)/resource-shas.txt | grep -w ".* pojavlauncher$$" | cut -b 1-40); \
	REMOTESHA=$$(git ls-remote https://github.com/PojavLauncherTeam/PojavLauncher_iOS | grep refs/tags | sort -t/ -k2 -r | sed '1d' | sed '2p' | sed '2,1000d' | cut -b 1-40); \
	DOWNURL=$$(curl --netrc-file ~/netrc -H "Accept: application/vnd.github.v3+json" -s https://api.github.com/repos/PojavLauncherTeam/PojavLauncher_iOS/releases | jq '.[] | .assets[] | select(.name | startswith("net.kdt.pojavlauncher.release_")) | .browser_download_url' | sed '2,1000d' | sed 's/"//' | sed 's/"[^"]*$$//'); \
	DOWNNAME=$$(curl --netrc-file ~/netrc -H "Accept: application/vnd.github.v3+json" -s https://api.github.com/repos/PojavLauncherTeam/PojavLauncher_iOS/releases | jq '.[] | .assets[] | select(.name | startswith("net.kdt.pojavlauncher.release_")) | .name' | sed '2,1000d' | sed 's/.$$//' | sed 's/"//'); \
        ROOTDOWNURL=$$(curl --netrc-file ~/netrc -H "Accept: application/vnd.github.v3+json" -s https://api.github.com/repos/PojavLauncherTeam/PojavLauncher_iOS/releases | jq '.[] | .assets[] | select(.name | startswith("net.kdt.pojavlauncher.release-rootless_")) | .browser_download_url' | sed '2,1000d' | sed 's/"//' | sed 's/"[^"]*$$//'); \
	ROOTDOWNNAME=$$(curl --netrc-file ~/netrc -H "Accept: application/vnd.github.v3+json" -s https://api.github.com/repos/PojavLauncherTeam/PojavLauncher_iOS/releases | jq '.[] | .assets[] | select(.name | startswith("net.kdt.pojavlauncher.release-rootless_")) | .name' | sed '2,1000d' | sed 's/.$$//' | sed 's/"//'); \
	if [[ $$REMOTESHA != $$LOCALSHA ]]; then \
		cd $(TEMPDIR); \
		curl -o $$DOWNNAME --netrc-file ~/netrc -Ls $$DOWNURL; \
                curl -o $$ROOTDOWNNAME --netrc-file ~/netrc -Ls $$ROOTDOWNURL; \
		mv net.kdt.pojavlauncher.release*.deb ..; \
		echo "$$REMOTESHA - pojavlauncher" > $(WORKINGDIR)/resource-shas.txt.pojavlauncher-release; \
		printf "[PojavLauncher iOS] Successfully updated to the newest version\n\n"; \
	else \
		printf "[PojavLauncher iOS] There's nothing to do, as this package is already the latest version\n\n"; \
		echo "$$LOCALSHA - pojavlauncher" > $(WORKINGDIR)/resource-shas.txt.pojavlauncher-release; \
	fi

pojavlauncher-dev: setup
	LOCALSHA=$$(cat $(WORKINGDIR)/resource-shas.txt | grep pojavlauncher-dev | cut -b 1-40); \
	REMOTESHA=$$(git ls-remote https://github.com/PojavLauncherTeam/PojavLauncher_iOS | grep refs/heads/main | cut -b 1-40); \
	DOWNURL=$$(curl --netrc-file ~/netrc -H "Accept: application/vnd.github.v3+json" -s https://api.github.com/repos/PojavLauncherTeam/PojavLauncher_iOS/actions/artifacts | jq '.artifacts[] | select(.name=="net.kdt.pojavlauncher.development_iphoneos-arm.deb") | .archive_download_url' | sed '2,1000d' | sed 's/"//' | sed 's/.$$//'); \
	DOWNNAME=$$(curl --netrc-file ~/netrc -H "Accept: application/vnd.github.v3+json" -s https://api.github.com/repos/PojavLauncherTeam/PojavLauncher_iOS/actions/artifacts | jq '.artifacts[] | select(.name=="net.kdt.pojavlauncher.development_iphoneos-arm.deb") | .name' | sed '2,1000d' | sed 's/.$$//' | sed 's/"//'); \
	ROOTDOWNURL=$$(curl --netrc-file ~/netrc -H "Accept: application/vnd.github.v3+json" -s https://api.github.com/repos/PojavLauncherTeam/PojavLauncher_iOS/actions/artifacts | jq '.artifacts[] | select(.name=="net.kdt.pojavlauncher.development-rootless_iphoneos-arm.deb") | .archive_download_url' | sed '2,1000d' | sed 's/"//' | sed 's/.$$//'); \
	ROOTDOWNNAME=$$(curl --netrc-file ~/netrc -H "Accept: application/vnd.github.v3+json" -s https://api.github.com/repos/PojavLauncherTeam/PojavLauncher_iOS/actions/artifacts | jq '.artifacts[] | select(.name=="net.kdt.pojavlauncher.development-rootless_iphoneos-arm.deb") | .name' | sed '2,1000d' | sed 's/.$$//' | sed 's/"//'); \
	if [[ "$$REMOTESHA" != "$$LOCALSHA" ]]; then \
		if [[ "$$DOWNURL" != "" ]]; then \
			cd $(TEMPDIR); \
			curl -o $$DOWNNAME.zip --netrc-file ~/netrc -Ls $$DOWNURL; \
        	        curl -o $$ROOTDOWNNAME.zip --netrc-file ~/netrc -Ls $$ROOTDOWNURL; \
			unzip $$DOWNNAME.zip; \
			unzip $$ROOTDOWNNAME.zip; \
			VERSION=$$(curl -s https://raw.githubusercontent.com/PojavLauncherTeam/PojavLauncher_iOS/main/DEBIAN/control.development | grep Version | cut -b 10-68); \
			CUTVER=$$(echo $$VERSION | sed 's/[^0-9]*//g'); \
                        if [[ $$(ls -l $(WORKINGDIR)/debs | grep net.kdt.pojavlauncher.development_| cut -b 52-98 | sed 's/[^0-9]*//g' | sort -Vr | grep "^$$CUTVER" | sed '1p' | sed '2,1000d' | cut -b 3-5) != '' ]]; then \
				REVISION=$$(expr $$(ls -l $(WORKINGDIR)/debs | grep net.kdt.pojavlauncher.development_ | cut -b 52-98 | sed 's/[^0-9]*//g' | sort -Vr | grep "^$$CUTVER" | sed '1p' | sed '2,1000d' | cut -b 3-5) + 1); \
			else \
				REVISION=1; \
			fi; \
			dpkg-deb --raw-extract net.kdt.pojavlauncher.development_"$$VERSION"_iphoneos-arm.deb net.kdt.pojavlauncher.development_"$$VERSION"~beta"$$REVISION"_iphoneos-arm; \
			dpkg-deb --raw-extract net.kdt.pojavlauncher.development-rootless_"$$VERSION"_iphoneos-arm64.deb net.kdt.pojavlauncher.development-rootless_"$$VERSION"~beta"$$REVISION"_iphoneos-arm64; \
			sed -i "6s/.*/Version: $$VERSION~beta$$REVISION/" net.kdt.pojavlauncher.development-rootless\_"$$VERSION"~beta"$$REVISION"_iphoneos-arm64/DEBIAN/control; \
			sed -i "6s/.*/Version: $$VERSION~beta$$REVISION/" net.kdt.pojavlauncher.development\_"$$VERSION"~beta"$$REVISION"_iphoneos-arm/DEBIAN/control;\
			dpkg-deb -b net.kdt.pojavlauncher.development_"$$VERSION"~beta"$$REVISION"_iphoneos-arm; \
			dpkg-deb -b net.kdt.pojavlauncher.development-rootless_"$$VERSION"~beta"$$REVISION"_iphoneos-arm64; \
			mv net.kdt.pojavlauncher.development_"$$VERSION"~beta"$$REVISION"_iphoneos-arm.deb ..; \
			mv net.kdt.pojavlauncher.development-rootless_"$$VERSION"~beta"$$REVISION"_iphoneos-arm64.deb ..;\
			rm -rf $$DOWNNAME.zip $$ROOTDOWNNAME.zip $(TEMPDIR)/*.deb; \
			echo "$$REMOTESHA - pojavlauncher-dev" > $(WORKINGDIR)/resource-shas.txt.pojavlauncher-dev; \
			printf "[PojavLauncher iOS (Dev)] Successfully updated to $$VERSION~beta$$REVISION\n\n"; \
		else \
			printf "[PojavLauncher iOS (Dev)] Artifact not found, skipping update\n\n"; \
			echo "$$LOCALSHA - pojavlauncher-dev" > $(WORKINGDIR)/resource-shas.txt.pojavlauncher-dev; \
		fi; \
	else \
		printf "[PojavLauncher iOS (Dev)] There's nothing to do, as this package is already the latest version\n\n"; \
		echo "$$LOCALSHA - pojavlauncher-dev" > $(WORKINGDIR)/resource-shas.txt.pojavlauncher-dev; \
	fi

openjdk-8-jre: setup
	REMOTESHA=$$(git ls-remote https://github.com/PojavLauncherTeam/android-openjdk-build-multiarch | grep refs/heads/buildjre8 | cut -b 1-40); \
	LOCALSHA=$$(cat $(WORKINGDIR)/resource-shas.txt | grep openjdk-8-jre | cut -b 1-40); \
	DOWNURL=$$(curl --netrc-file ~/netrc -H "Accept: application/vnd.github.v3+json" -s https://api.github.com/repos/PojavLauncherTeam/android-openjdk-build-multiarch/actions/artifacts | jq '.artifacts[] | select(.name=="jre8-ios-aarch64") | .archive_download_url' | sed '2,1000d' | sed 's/"//' | sed 's/"[^"]*$$//'); \
	if [[ $$REMOTESHA != $$LOCALSHA ]]; then \
		if [[ "$$DOWNURL" != "" ]]; then \
			cd $(TEMPDIR); \
			VERSION='1.8.0~292b10'; \
			REVISION="build$$(expr $$(ls -l $(WORKINGDIR)/debs | grep openjdk-8-jre | cut -b 52-98 | sed 's/[^0-9]*//g' | sort -Vr | grep "^8" | sed '1p' | sed '2,1000d' | cut -b 10-13) + 1)"; \
			curl --netrc-file ~/netrc -H "Accept: application/vnd.github.v3+json" -o jre8-ios-aarch64.zip -Ls $$DOWNURL; \
			unzip 'jre8-ios-aarch64.zip'; \
			mkdir -p openjdk-8-jre_$$VERSION-$$REVISION\_iphoneos-arm/usr/lib/jvm/java-8-openjdk; \
			tar -xf jre8-arm64-*-release.tar.xz --directory openjdk-8-jre_$$VERSION-$$REVISION\_iphoneos-arm; \
			cd openjdk-8-jre_$$VERSION-$$REVISION\_iphoneos-arm; \
			rm -rf {ASSEMBLY_EXCEPTION,release,LICENSE,THIRD_PARTY_README}; \
			mv bin usr/lib/jvm/java-8-openjdk/bin; \
			mv lib usr/lib/jvm/java-8-openjdk/lib; \
			ln -s /usr/lib/jvm/java-8-openjdk/lib/libawt_headless.dylib usr/lib/jvm/java-8-openjdk/lib/libawt_headless.so; \
			mkdir -p DEBIAN; \
			echo 'Package: openjdk-8-jre' >> DEBIAN/control; \
			echo 'Name: openjdk-8-jre' >> DEBIAN/control; \
			echo 'Maintainer: PojavLauncherTeam <https://discord.gg/6RpEJda>' >> DEBIAN/control; \
			echo 'Author: DuyKhanhTran, Azul <https://azul.com>' >> DEBIAN/control; \
			echo 'Architecture: iphoneos-arm' >> DEBIAN/control; \
			echo 'Replaces: java-8-openjdk' >> DEBIAN/control; \
			echo 'Conflicts: java-8-openjdk, openjdk-8-jdk' >> DEBIAN/control; \
			echo 'Version: '$$VERSION'-'$$REVISION'' >> DEBIAN/control; \
			echo 'Depends: firmware (>= 12.0)' >> DEBIAN/control; \
			echo 'Section: Development' >> DEBIAN/control; \
			echo 'Priority: optional' >> DEBIAN/control; \
			echo 'Homepage: https://www.azul.com' >> DEBIAN/control; \
			echo 'Description: OpenJDK 8 Runtime Environment, using HotSpot JIT runtime, from Azul'\''s Runtime.' >> DEBIAN/control; \
			echo 'Depiction: https://doregon.github.io/json-webviews/?json=https://repo.doregon.gq/depictions/natives/openjdk-8-jre.json&name=OpenJDK%208%20Developer%20Kit&dev=PojavLauncherTeam&section=Development' >> DEBIAN/control; \
			echo 'SileoDepiction: https://repo.doregon.gq/depictions/natives/openjdk-8-jre.json' >> DEBIAN/control; \
			cd $(TEMPDIR); \
			dpkg-deb -b openjdk-8-jre_$$VERSION-$$REVISION\_iphoneos-arm; \
			echo "$$REMOTESHA - openjdk-8-jre" > $(WORKINGDIR)/resource-shas.txt.openjdk-8-jre; \
			mv openjdk-8-jre_$$VERSION-$$REVISION\_iphoneos-arm.deb $(WORKINGDIR)/debs; \
		else \
			printf "[OpenJDK 8 (JRE)] Artifact not found, skipping update\n\n"; \
			echo "$$LOCALSHA - openjdk-8-jre" > $(WORKINGDIR)/resource-shas.txt.openjdk-8-jre; \
		fi; \
	else \
		printf "[OpenJDK 8 (JRE)] There's nothing to do, as this package is already the latest version\n\n"; \
		echo "$$LOCALSHA - openjdk-8-jre" > $(WORKINGDIR)/resource-shas.txt.openjdk-8-jre; \
	fi

openjdk-8-jdk: setup
	REMOTESHA=$$(git ls-remote https://github.com/PojavLauncherTeam/android-openjdk-build-multiarch | grep refs/heads/buildjre8 | cut -b 1-40); \
	LOCALSHA=$$(cat $(WORKINGDIR)/resource-shas.txt | grep openjdk-8-jdk | cut -b 1-40); \
	DOWNURL=$$(curl --netrc-file ~/netrc -H "Accept: application/vnd.github.v3+json" -s https://api.github.com/repos/PojavLauncherTeam/android-openjdk-build-multiarch/actions/artifacts | jq '.artifacts[] | select(.name=="jdk8-ios-aarch64") | .archive_download_url' | sed '2,1000d' | sed 's/"//' | sed 's/"[^"]*$$//'); \
	if [[ $$REMOTESHA != $$LOCALSHA ]]; then \
		if [[ "$$DOWNURL" != "" ]]; then \
			cd $(TEMPDIR); \
			VERSION='1.8.0~292b10'; \
			REVISION="build$$(expr $$(ls -l $(WORKINGDIR)/debs | grep openjdk-8-jdk | cut -b 52-98 | sed 's/[^0-9]*//g' | sort -Vr | grep "^8" | sed '1p' | sed '2,1000d' | cut -b 10-13) + 1)"; \
			curl --netrc-file ~/netrc -H "Accept: application/vnd.github.v3+json" -o jdk8-ios-aarch64.zip -Ls $$DOWNURL; \
			unzip 'jdk8-ios-aarch64.zip'; \
			mkdir -p openjdk-8-jdk_$$VERSION-$$REVISION\_iphoneos-arm/usr/lib/jvm/java-8-openjdk; \
			tar -xf jdk8-arm64-*-release.tar.xz --directory openjdk-8-jdk_$$VERSION-$$REVISION\_iphoneos-arm; \
			cd openjdk-8-jdk_$$VERSION-$$REVISION\_iphoneos-arm; \
			mv bin usr/lib/jvm/java-8-openjdk/bin; \
			mv lib usr/lib/jvm/java-8-openjdk/lib; \
			mv include usr/lib/jvm/java-8-openjdk/include; \
			mv man usr/lib/jvm/java-8-openjdk/man; \
			mv jre/lib/* usr/lib/jvm/java-8-openjdk/lib/; \
			mv src.zip usr/lib/jvm/java-8-openjdk/lib/; \
			rm -rf {ASSEMBLY_EXCEPTION,LICENSE,release,THIRD_PARTY_README,demo,sample,jre}; \
			ln -s /usr/lib/jvm/java-8-openjdk/lib/libawt_headless.dylib usr/lib/jvm/java-8-openjdk/lib/libawt_headless.so; \
			ln -s /usr/lib/jvm/java-8-openjdk usr/lib/jvm/java-8-openjdk/jre; \
			mkdir -p DEBIAN; \
			echo 'Package: openjdk-8-jdk' >> DEBIAN/control; \
			echo 'Name: openjdk-8-jdk' >> DEBIAN/control; \
			echo 'Maintainer: PojavLauncherTeam <https://discord.gg/6RpEJda>' >> DEBIAN/control; \
			echo 'Author: DuyKhanhTran, Azul <https://azul.com>' >> DEBIAN/control; \
			echo 'Architecture: iphoneos-arm' >> DEBIAN/control; \
			echo 'Replaces: java-8-openjdk' >> DEBIAN/control; \
			echo 'Conflicts: java-8-openjdk, openjdk-8-jre' >> DEBIAN/control; \
			echo 'Version: '$$VERSION'-'$$REVISION'' >> DEBIAN/control; \
			echo 'Depends: firmware (>= 12.0)' >> DEBIAN/control; \
			echo 'Section: Development' >> DEBIAN/control; \
			echo 'Priority: optional' >> DEBIAN/control; \
			echo 'Homepage: https://www.azul.com' >> DEBIAN/control; \
			echo 'Description: OpenJDK 8 Runtime Environment, using HotSpot JIT runtime, from Azul'\''s Runtime.' >> DEBIAN/control; \
			echo '  This package includes developer tools to build and test your Java 8 applications directly on iOS.' >> DEBIAN/control ; \
			echo 'Depiction: https://doregon.github.io/json-webviews/?json=https://repo.doregon.gq/depictions/natives/openjdk-8-jdk.json&name=OpenJDK%208%20Developer%20Kit&dev=PojavLauncherTeam&section=Development' >> DEBIAN/control; \
			echo 'SileoDepiction: https://repo.doregon.gq/depictions/natives/openjdk-8-jdk.json' >> DEBIAN/control; \
			cd $(TEMPDIR); \
			dpkg-deb -b openjdk-8-jdk_$$VERSION-$$REVISION\_iphoneos-arm; \
			echo "$$REMOTESHA - openjdk-8-jdk" > $(WORKINGDIR)/resource-shas.txt.openjdk-8-jdk; \
			mv openjdk-8-jdk_$$VERSION-$$REVISION\_iphoneos-arm.deb $(WORKINGDIR)/debs; \
			printf "[OpenJDK 8] Successfully updated to $$VERSION-$$REVISION\n\n"; \
		else \
			printf "[OpenJDK 8 (JDK)] Artifact not found, skipping update\n\n"; \
			echo "$$LOCALSHA - openjdk-8-jdk" > $(WORKINGDIR)/resource-shas.txt.openjdk-8-jdk; \
		fi; \
	else \
		printf "[OpenJDK 8 (JDK)] There's nothing to do, as this package is already the latest version\n\n"; \
		echo "$$LOCALSHA - openjdk-8-jdk" > $(WORKINGDIR)/resource-shas.txt.openjdk-8-jdk; \
	fi

repo: pojavlauncher-release pojavlauncher-dev openjdk-8-jre openjdk-8-jdk
	rm -rf $$(ls -l debs/ | grep openjdk-8-jdk | cut -b 53-98 | sort -Vr | sed '1,9d' | sed 's/open/debs\/open/'); \
	rm -rf $$(ls -l debs/ | grep openjdk-8-jre | cut -b 53-98 | sort -Vr | sed '1,9d' | sed 's/open/debs\/open/'); \
   rm -rf $(TEMPDIR)/*; \
	cat resource-shas.txt.* > resource-shas.txt; \
	git add debs/*.deb; \
	rm -rf Packages*; \
	apt-ftparchive packages ./debs > Packages; \
	gzip -c9 Packages > Packages.gz; \
	xz -c9 Packages > Packages.xz; \
	xz -5fkev --format=lzma Packages > Packages.lzma; \
	zstd -c19 Packages > Packages.zst; \
	bzip2 -c9 Packages > Packages.bz2; \
	rm -rf Release Release.gpg; \
	apt-ftparchive release . > Release; \
	cat Base Release > out; \
	mv out Release; \
	gpg --pinentry-mode=loopback --passphrase  "p@ssword" -abs -u 5E23E7BA568739CB88B68395A5F5B75BBD365B83 -o Release.gpg Release
	printf "[Repo] Action complete. You should see updates within the next 10 minutes.\n\n"

