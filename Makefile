APP_SIGNING_ID ?= Developer ID Application: Donald McCaughey
INSTALLER_SIGNING_ID ?= Developer ID Installer: Donald McCaughey
NOTARIZATION_KEYCHAIN_PROFILE ?= Donald McCaughey
TMP ?= $(abspath tmp)

version := 1.20.2
pcre_version := 8.45
zlib_version := 1.2.12
revision := 2
archs := arm64 x86_64

rev := $(if $(patsubst 1,,$(revision)),-r$(revision),)
ver := $(version)$(rev)


.SECONDEXPANSION :


.PHONY : signed-package
signed-package : $(TMP)/nginx-$(ver)-unnotarized.pkg


.PHONY : notarize
notarize : nginx-$(ver).pkg


.PHONY : clean
clean :
	-rm -f nginx-*.pkg
	-rm -f nginx/Makefile
	-rm -rf $(TMP)


.PHONY : check
check :
	test "$(shell lipo -archs $(TMP)/pkg/usr/local/nginx/sbin/nginx)" = "x86_64 arm64"
	test "$(shell ./tools/dylibs --no-sys-libs --count $(TMP)/pkg/usr/local/nginx/sbin/nginx) dylibs" = "0 dylibs"
	codesign --verify --strict $(TMP)/pkg/usr/local/nginx/sbin/nginx
	pkgutil --check-signature nginx-$(ver).pkg
	spctl --assess --type install nginx-$(ver).pkg
	xcrun stapler validate nginx-$(ver).pkg


##### compilation flags ##########

arch_flags = $(patsubst %,-arch %,$(archs))

CFLAGS += $(arch_flags)
LDFLAGS += $(arch_flags)
LINK := $(CC) $(LDFLAGS)


##### pcre dist ##########

pcre_dist := $(shell find ./pcre -type f \! -name .DS_Store)


##### zlib dist ##########

zlib_dist := $(shell find ./zlib -type f \! -name .DS_Store)


##### nginx dist ##########

# configure

$(TMP)/nginx/build :
	mkdir -p $@

$(TMP)/nginx/configured.stamp.txt : \
		./nginx/configure \
		$(pcre_dist) \
		$(zlib_dist) \
		| $(TMP)/nginx/build
	rm -rf $(TMP)/pcre
	cp -r ./pcre $(TMP)/pcre
	rm -rf $(TMP)/zlib
	cp -r ./zlib $(TMP)/zlib
	cd ./nginx && ./configure \
		--builddir=$(TMP)/nginx/build \
		--with-pcre=$(TMP)/pcre \
		--with-pcre-jit \
		--with-zlib=$(TMP)/zlib
	date > $@

./nginx/Makefile \
$(TMP)/nginx/build/Makefile : $(TMP)/nginx/configured.stamp.txt
	@:


# build

nginx_files := $(shell find ./nginx -type f \
		\! -name Makefile \
		\! -name .DS_Store \
		)

$(TMP)/nginx/built.stamp.txt : \
		./nginx/Makefile \
		$(TMP)/nginx/build/Makefile \
		$(nginx_files)
	cd ./nginx && $(MAKE) CFLAGS='$(CFLAGS)' LINK='$(LINK)'
	date > $@

nginx_built_files := \
	$(TMP)/nginx/build/nginx \
	$(TMP)/nginx/build/nginx.8 

$(nginx_built_files) : $(TMP)/nginx/built.stamp.txt
	@:

# install

$(TMP)/nginx/install :
	mkdir -p $@

$(TMP)/nginx/installed.stamp.txt : $(nginx_built_files) | $(TMP)/nginx/install
	cd ./nginx \
		&& $(MAKE) \
			DESTDIR=$(TMP)/nginx/install \
			CFLAGS='$(CFLAGS)' \
			LINK='$(LINK)' \
			install
	date > $@

nginx_installed_files := \
	$(TMP)/nginx/install/usr/local/nginx/conf/fastcgi_params \
	$(TMP)/nginx/install/usr/local/nginx/conf/fastcgi_params.default \
	$(TMP)/nginx/install/usr/local/nginx/conf/fastcgi.conf \
	$(TMP)/nginx/install/usr/local/nginx/conf/fastcgi.conf.default \
	$(TMP)/nginx/install/usr/local/nginx/conf/koi-utf \
	$(TMP)/nginx/install/usr/local/nginx/conf/koi-win \
	$(TMP)/nginx/install/usr/local/nginx/conf/mime.types \
	$(TMP)/nginx/install/usr/local/nginx/conf/mime.types.default \
	$(TMP)/nginx/install/usr/local/nginx/conf/scgi_params \
	$(TMP)/nginx/install/usr/local/nginx/conf/scgi_params.default \
	$(TMP)/nginx/install/usr/local/nginx/conf/uwsgi_params \
	$(TMP)/nginx/install/usr/local/nginx/conf/uwsgi_params.default \
	$(TMP)/nginx/install/usr/local/nginx/conf/win-utf \
	$(TMP)/nginx/install/usr/local/nginx/html/50x.html

nginx_installed_conf := \
	$(TMP)/nginx/install/usr/local/nginx/conf/nginx.conf \
	$(TMP)/nginx/install/usr/local/nginx/conf/nginx.conf.default

nginx_installed_html := \
	$(TMP)/nginx/install/usr/local/nginx/html/index.html

nginx_installed_dirs := \
	$(TMP)/nginx/install/usr/local/nginx/logs \
	$(TMP)/nginx/install/usr/local/nginx/sbin \
	$(sort $(dir $(nginx_installed_files) $(nginx_installed_conf) $(nginx_installed_html)))

$(TMP)/nginx/install/usr/local/nginx/sbin/nginx \
$(nginx_installed_files) \
$(nginx_installed_conf) \
$(nginx_installed_html) \
$(nginx_installed_dirs) : $(TMP)/nginx/installed.stamp.txt
	@:

nginx_extra_files := $(TMP)/nginx/install/usr/local/nginx/man/man8/nginx.8

nginx_extra_dirs := $(sort $(dir $(nginx_extra_files)))

$(nginx_extra_dirs) :
	mkdir -p $@

$(TMP)/nginx/install/usr/local/nginx/man/man8/nginx.8 : \
		$(TMP)/nginx/build/nginx.8 \
		| $$(dir $$@)
	cp $< $@


##### pkg ##########

# nginx

pkg_nginx_dirs := $(patsubst $(TMP)/nginx/install/%,$(TMP)/pkg/%,\
		$(nginx_installed_dirs) $(nginx_extra_dirs))

$(pkg_nginx_dirs) : $(TMP)/pkg/% : $(TMP)/nginx/install/%
	mkdir -p $@

pkg_nginx_files := $(patsubst $(TMP)/nginx/install/%,$(TMP)/pkg/%,\
		$(nginx_installed_files) $(nginx_extra_files))

$(pkg_nginx_files) : $(TMP)/pkg/% : $(TMP)/nginx/install/% | $$(dir $$@)
	cp $< $@

pkg_nginx_conf := $(patsubst $(TMP)/nginx/install/%,$(TMP)/pkg/%,\
		$(nginx_installed_conf))

$(pkg_nginx_conf) : $(TMP)/pkg/% : $(TMP)/nginx/install/% | $$(dir $$@)
	sed \
		-e '1s/^/daemon off;/' \
		-e '1G' \
		$< > $@

pkg_nginx_html := $(patsubst $(TMP)/nginx/install/%,$(TMP)/pkg/%,\
		$(nginx_installed_html))

$(pkg_nginx_html) : $(TMP)/pkg/% : $(TMP)/nginx/install/% ./footer.html | $$(dir $$@)
	N=$$'\n'; \
	sed \
		-e "/<\/body>/{ x $$N r ./footer.html$$N }" \
		-e "\$${ H $$N x $$N }" \
		$< > $@
	sed \
		-e 's/{{pcre_version}}/$(pcre_version)/g' \
		-e 's/{{zlib_version}}/$(zlib_version)/g' \
		-e 's/{{revision}}/$(revision)/g'\
		-e 's/{{version}}/$(version)/g'\
		-i '' $@

$(TMP)/pkg/usr/local/nginx/sbin/nginx : $(TMP)/nginx/install/usr/local/nginx/sbin/nginx | $$(dir $$@)
	cp $< $@
	xcrun codesign \
		--sign "$(APP_SIGNING_ID)" \
		--options runtime \
		$@

# install

install_dirs := $(shell find ./install -type d \! -path ./install \! -name .DS_Store)

pkg_install_dirs := $(patsubst ./install/%,$(TMP)/pkg/%,$(install_dirs))

$(pkg_install_dirs) : $(TMP)/pkg/% : | ./install/%
	mkdir -p $@

install_files := $(shell find ./install -type f \! -name .DS_Store)

pkg_install_files := $(patsubst ./install/%,$(TMP)/pkg/%,$(install_files))

$(pkg_install_files) : $(TMP)/pkg/% : ./install/% | $$(dir $$@)
	cp $< $@

# uninstall

$(TMP)/pkg/usr/local/nginx/bin :
	mkdir -p $@

$(TMP)/pkg/usr/local/nginx/bin/uninstall-nginx : \
		./uninstall-nginx \
		$(TMP)/pkg/usr/local/nginx/sbin/nginx \
		$(pkg_nginx_dirs) \
		$(pkg_nginx_files) \
		$(pkg_nginx_conf) \
		$(pkg_nginx_html) \
		$(pkg_install_dirs) \
		$(pkg_install_files) \
		| $$(dir $$@)
	cp $< $@
	cd $(TMP)/pkg && find . -type f \
		\! -name .DS_Store \
		\! -path './usr/local/nginx/*' \
		| sort >> $@
	sed -e 's/^\./rm -f /g' -i '' $@
	chmod a+x $@

# package

script_files := $(shell find ./scripts -type f \! -name .DS_Store)

$(TMP)/nginx.pkg : \
		$(TMP)/pkg/usr/local/nginx/bin/uninstall-nginx \
		$(script_files)
	pkgbuild \
		--root $(TMP)/pkg \
		--identifier cc.donm.pkg.nginx \
		--ownership recommended \
		--scripts ./scripts \
		--version $(version) \
		$@


##### product ##########

arch_list := $(shell printf '%s' "$(archs)" | sed "s/ / and /g")
date := $(shell date '+%Y-%m-%d')
macos := $(shell \
	system_profiler -detailLevel mini SPSoftwareDataType \
	| grep 'System Version:' \
	| awk -F ' ' '{print $$4}' \
	)
xcode := $(shell \
	system_profiler -detailLevel mini SPDeveloperToolsDataType \
	| grep 'Version:' \
	| awk -F ' ' '{print $$2}' \
	)

$(TMP)/nginx-$(ver)-unnotarized.pkg : \
		$(TMP)/nginx.pkg \
		$(TMP)/build-report.txt \
		$(TMP)/distribution.xml \
		$(TMP)/resources/background.png \
		$(TMP)/resources/background-darkAqua.png \
		$(TMP)/resources/license.html \
		$(TMP)/resources/welcome.html
	productbuild \
		--distribution $(TMP)/distribution.xml \
		--resources $(TMP)/resources \
		--package-path $(TMP) \
		--version v$(version)-r$(revision) \
		--sign '$(INSTALLER_SIGNING_ID)' \
		$@

$(TMP)/build-report.txt : | $$(dir $$@)
	printf 'Build Date: %s\n' "$(date)" > $@
	printf 'Software Version: %s\n' "$(version)" >> $@
	printf 'PCRE Library Version: %s\n' "$(pcre_version)" >> $@
	printf 'zlib Library Version: %s\n' "$(zlib_version)" >> $@
	printf 'Installer Revision: %s\n' "$(revision)" >> $@
	printf 'Architectures: %s\n' "$(arch_list)" >> $@
	printf 'macOS Version: %s\n' "$(macos)" >> $@
	printf 'Xcode Version: %s\n' "$(xcode)" >> $@
	printf 'APP_SIGNING_ID: %s\n' "$(APP_SIGNING_ID)" >> $@
	printf 'INSTALLER_SIGNING_ID: %s\n' "$(INSTALLER_SIGNING_ID)" >> $@
	printf 'NOTARIZATION_KEYCHAIN_PROFILE: %s\n' "$(NOTARIZATION_KEYCHAIN_PROFILE)" >> $@
	printf 'TMP directory: %s\n' "$(TMP)" >> $@
	printf 'CFLAGS: %s\n' "$(CFLAGS)" >> $@
	printf 'LINK: %s\n' "$(LINK)" >> $@
	printf 'LDFLAGS: %s\n' "$(LDFLAGS)" >> $@
	printf 'Tag: v%s-r%s\n' "$(version)" "$(revision)" >> $@
	printf 'Tag Title: nginx %s for macOS rev %s\n' "$(version)" "$(revision)" >> $@
	printf 'Tag Message: A signed and notarized universal installer package for `nginx` %s, built with PCRE %s and zlib %s.\n' \
		"$(version)" "$(pcre_version)" "$(zlib_version)" >> $@

$(TMP)/distribution.xml \
$(TMP)/resources/welcome.html : $(TMP)/% : % | $$(dir $$@)
	sed \
		-e 's/{{arch_list}}/$(arch_list)/g' \
		-e 's/{{date}}/$(date)/g' \
		-e 's/{{macos}}/$(macos)/g' \
		-e 's/{{pcre_version}}/$(pcre_version)/g' \
		-e 's/{{zlib_version}}/$(zlib_version)/g' \
		-e 's/{{revision}}/$(revision)/g' \
		-e 's/{{version}}/$(version)/g' \
		-e 's/{{xcode}}/$(xcode)/g' \
		$< > $@

$(TMP)/resources/background.png \
$(TMP)/resources/background-darkAqua.png \
$(TMP)/resources/license.html : $(TMP)/% : % | $$(dir $$@)
	cp $< $@

$(TMP) \
$(TMP)/resources : 
	mkdir -p $@


##### notarization ##########

$(TMP)/submit-log.json : $(TMP)/nginx-$(ver)-unnotarized.pkg | $$(dir $$@)
	xcrun notarytool submit $< \
		--keychain-profile "$(NOTARIZATION_KEYCHAIN_PROFILE)" \
		--output-format json \
		--wait \
		> $@

$(TMP)/submission-id.txt : $(TMP)/submit-log.json | $$(dir $$@)
	jq --raw-output '.id' < $< > $@

$(TMP)/notarization-log.json : $(TMP)/submission-id.txt | $$(dir $$@)
	xcrun notarytool log "$$(<$<)" \
		--keychain-profile "$(NOTARIZATION_KEYCHAIN_PROFILE)" \
		$@

$(TMP)/notarized.stamp.txt : $(TMP)/notarization-log.json | $$(dir $$@)
	test "$$(jq --raw-output '.status' < $<)" = "Accepted"
	date > $@

nginx-$(ver).pkg : $(TMP)/nginx-$(ver)-unnotarized.pkg $(TMP)/notarized.stamp.txt
	cp $< $@
	xcrun stapler staple $@

