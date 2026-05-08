APP_SIGNING_ID ?= Developer ID Application: Donald McCaughey
INSTALLER_SIGNING_ID ?= Developer ID Installer: Donald McCaughey
NOTARIZATION_KEYCHAIN_PROFILE ?= Donald McCaughey
TMP ?= $(abspath tmp)

version := 1.28.0
openssl_version := 3.5.5
pcre2_version := 10.47
zlib_version := 1.3.1
revision := 1
archs := arm64 x86_64

rev := $(if $(patsubst 1,,$(revision)),-r$(revision),)
tag := v$(version)-r$(revision)
tag-message := A signed and notarized universal installer package for \
	\`freenginx\` $(version) built with OpenSSL $(openssl_version), PCRE2 \
	$(pcre2_version) and zlib $(zlib_version).
tag-title := freenginx $(version) for macOS rev $(revision)
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
check : $(TMP)/checked-package.stamp.txt


.PHONY : release
release : $(TMP)/released.stamp.txt


##### openssl dist ##########

openssl_dist := $(shell find openssl -type f -not -name .DS_Store)

$(TMP)/arm64/copied-openssl.stamp.txt : $(openssl_dist) | $$(dir $$@)
	rm -rf $(TMP)/arm64/openssl
	cp -r openssl $(TMP)/arm64/openssl
	date > $@

$(TMP)/x86_64/copied-openssl.stamp.txt : $(openssl_dist) | $$(dir $$@)
	rm -rf $(TMP)/x86_64/openssl
	cp -r openssl $(TMP)/x86_64/openssl
	date > $@


##### pcre2 dist ##########

pcre2_dist := $(shell find pcre2 -type f -not -name .DS_Store)

$(TMP)/arm64/copied-pcre2.stamp.txt : $(pcre2_dist) | $$(dir $$@)
	rm -rf $(TMP)/arm64/pcre2
	cp -r pcre2 $(TMP)/arm64/pcre2
	date > $@

$(TMP)/x86_64/copied-pcre2.stamp.txt : $(pcre2_dist) | $$(dir $$@)
	rm -rf $(TMP)/x86_64/pcre2
	cp -r pcre2 $(TMP)/x86_64/pcre2
	date > $@


##### zlib dist ##########

zlib_dist := $(shell find ./zlib -type f \! -name .DS_Store)

$(TMP)/arm64/copied-zlib.stamp.txt : $(zlib_dist) | $$(dir $$@)
	rm -rf $(TMP)/arm64/zlib
	cp -r zlib $(TMP)/arm64/zlib
	date > $@

$(TMP)/x86_64/copied-zlib.stamp.txt : $(zlib_dist) | $$(dir $$@)
	rm -rf $(TMP)/x86_64/zlib
	cp -r zlib $(TMP)/x86_64/zlib
	date > $@


##### nginx dist ##########

nginx_dist := $(shell find nginx -type f -not -name .DS_Store)

$(TMP)/arm64/copied-nginx.stamp.txt : $(nginx_dist) | $$(dir $$@)
	rm -rf $(TMP)/arm64/nginx
	cp -r nginx $(TMP)/arm64/nginx
	date > $@

$(TMP)/x86_64/copied-nginx.stamp.txt : $(nginx_dist) | $$(dir $$@)
	rm -rf $(TMP)/x86_64/nginx
	cp -r nginx $(TMP)/x86_64/nginx
	date > $@


# configure

nginx_common_config_options = \
		--with-http_gunzip_module \
		--with-http_gzip_static_module \
		--with-http_ssl_module \
		--with-pcre-jit

$(TMP)/arm64/configured.stamp.txt : \
		$(TMP)/arm64/copied-openssl.stamp.txt \
		$(TMP)/arm64/copied-pcre2.stamp.txt \
		$(TMP)/arm64/copied-zlib.stamp.txt \
		$(TMP)/arm64/copied-nginx.stamp.txt
	cd $(TMP)/arm64/nginx \
			&& ./configure \
					$(nginx_common_config_options) \
					--with-openssl=$(TMP)/arm64/openssl \
					--with-openssl-opt=darwin64-arm64-cc \
					--with-pcre=$(TMP)/arm64/pcre2 \
					--with-zlib=$(TMP)/arm64/zlib
	date > $@

$(TMP)/x86_64/configured.stamp.txt : \
		$(TMP)/x86_64/copied-openssl.stamp.txt \
		$(TMP)/x86_64/copied-pcre2.stamp.txt \
		$(TMP)/x86_64/copied-zlib.stamp.txt \
		$(TMP)/x86_64/copied-nginx.stamp.txt
	cd $(TMP)/x86_64/nginx \
			&& ./configure \
					$(nginx_common_config_options) \
					--with-openssl=$(TMP)/x86_64/openssl \
					--with-openssl-opt=darwin64-x86_64-cc \
					--with-pcre=$(TMP)/x86_64/pcre2 \
					--with-zlib=$(TMP)/x86_64/zlib
	date > $@


# build

$(TMP)/arm64/built.stamp.txt : $(TMP)/arm64/configured.stamp.txt
	cd $(TMP)/arm64/nginx \
			&& $(MAKE) CFLAGS='-arch arm64' LINK='$(CC) -arch arm64'
	date > $@

$(TMP)/x86_64/built.stamp.txt : $(TMP)/x86_64/configured.stamp.txt
	cd $(TMP)/x86_64/nginx \
			&& $(MAKE) CFLAGS='-arch x86_64' LINK='$(CC) -arch x86_64'
	date > $@


# install

$(TMP)/install \
$(TMP)/arm64/install \
$(TMP)/x86_64/install :
	mkdir -p $@

$(TMP)/arm64/installed.stamp.txt : \
		$(TMP)/arm64/built.stamp.txt \
		| $(TMP)/arm64/install
	cd $(TMP)/arm64/nginx \
		&& $(MAKE) \
			DESTDIR=$(TMP)/arm64/install \
			CFLAGS='-arch arm64' \
			LINK='$(CC) -arch arm64' \
			install
	date > $@

$(TMP)/x86_64/installed.stamp.txt : \
		$(TMP)/x86_64/built.stamp.txt \
		| $(TMP)/x86_64/install
	cd $(TMP)/x86_64/nginx \
		&& $(MAKE) \
			DESTDIR=$(TMP)/x86_64/install \
			CFLAGS='-arch x86_64' \
			LINK='$(CC) -arch x86_64' \
			install
	date > $@


$(TMP)/installed.stamp.txt : \
		$(TMP)/arm64/installed.stamp.txt \
		$(TMP)/x86_64/installed.stamp.txt
	rm -rf $(TMP)/install
	cp -r $(TMP)/arm64/install/ $(TMP)/install/
	mkdir -p $(TMP)/install/usr/local/nginx/man/man8
	cp \
		$(TMP)/arm64/nginx/objs/nginx.8 \
		$(TMP)/install/usr/local/nginx/man/man8/nginx.8
	rm -f $(TMP)/install/usr/local/nginx/sbin/nginx
	lipo \
		-create \
			$(TMP)/arm64/install/usr/local/nginx/sbin/nginx \
			$(TMP)/x86_64/install/usr/local/nginx/sbin/nginx \
		-output $(TMP)/install/usr/local/nginx/sbin/nginx
	mkdir -p $(TMP)/install/usr/local/nginx/man/man8
	date > $@

nginx_installed_files := \
	$(TMP)/install/usr/local/nginx/conf/fastcgi_params \
	$(TMP)/install/usr/local/nginx/conf/fastcgi_params.default \
	$(TMP)/install/usr/local/nginx/conf/fastcgi.conf \
	$(TMP)/install/usr/local/nginx/conf/fastcgi.conf.default \
	$(TMP)/install/usr/local/nginx/conf/koi-utf \
	$(TMP)/install/usr/local/nginx/conf/koi-win \
	$(TMP)/install/usr/local/nginx/conf/mime.types \
	$(TMP)/install/usr/local/nginx/conf/mime.types.default \
	$(TMP)/install/usr/local/nginx/conf/scgi_params \
	$(TMP)/install/usr/local/nginx/conf/scgi_params.default \
	$(TMP)/install/usr/local/nginx/conf/uwsgi_params \
	$(TMP)/install/usr/local/nginx/conf/uwsgi_params.default \
	$(TMP)/install/usr/local/nginx/conf/win-utf \
	$(TMP)/install/usr/local/nginx/html/50x.html \
	$(TMP)/install/usr/local/nginx/man/man8/nginx.8

nginx_installed_conf := \
	$(TMP)/install/usr/local/nginx/conf/nginx.conf \
	$(TMP)/install/usr/local/nginx/conf/nginx.conf.default

nginx_installed_html := \
	$(TMP)/install/usr/local/nginx/html/index.html

nginx_installed_dirs := \
	$(TMP)/install/usr/local/nginx/logs \
	$(TMP)/install/usr/local/nginx/sbin \
	$(sort \
			$(dir \
					$(nginx_installed_files) \
					$(nginx_installed_conf) \
				   	$(nginx_installed_html) \
			) \
	)

$(TMP)/install/usr/local/nginx/sbin/nginx \
$(nginx_installed_files) \
$(nginx_installed_conf) \
$(nginx_installed_html) \
$(nginx_installed_dirs) : $(TMP)/installed.stamp.txt
	@:


##### pkg ##########

# nginx

pkg_nginx_dirs := $(patsubst $(TMP)/install/%,$(TMP)/pkg/%,\
		$(nginx_installed_dirs) $(nginx_extra_dirs))

$(pkg_nginx_dirs) :
	mkdir -p $@

pkg_nginx_files := $(patsubst \
		$(TMP)/install/%,$(TMP)/pkg/%,$(nginx_installed_files))

$(pkg_nginx_files) : $(TMP)/pkg/% : $(TMP)/install/% | $$(dir $$@)
	cp $< $@

pkg_nginx_conf := $(patsubst \
		$(TMP)/install/%,$(TMP)/pkg/%,$(nginx_installed_conf))

$(pkg_nginx_conf) : $(TMP)/pkg/% : $(TMP)/install/% \
			patches/nginx.conf.patch \
			| $$(dir $$@)
	patch --unified -o $@ $< patches/nginx.conf.patch

pkg_nginx_html := $(patsubst $(TMP)/install/%,$(TMP)/pkg/%,\
		$(nginx_installed_html))

$(pkg_nginx_html) : $(TMP)/pkg/% : $(TMP)/install/% \
			./footer.html \
			| $$(dir $$@)
	N=$$'\n'; \
	sed \
		-e "/<\/body>/{ x $$N r ./footer.html$$N }" \
		-e "\$${ H $$N x $$N }" \
		$< > $@
	sed \
		-e 's/{{openssl_version}}/$(openssl_version)/g' \
		-e 's/{{pcre2_version}}/$(pcre2_version)/g' \
		-e 's/{{zlib_version}}/$(zlib_version)/g' \
		-e 's/{{revision}}/$(revision)/g'\
		-e 's/{{version}}/$(version)/g'\
		-i '' $@

$(TMP)/pkg/usr/local/nginx/sbin/nginx : \
			$(TMP)/install/usr/local/nginx/sbin/nginx \
			| $$(dir $$@)
	cp $< $@
	xcrun codesign \
		--sign "$(APP_SIGNING_ID)" \
		--options runtime \
		$@

# install

install_dirs := $(shell \
		find ./install -type d \! -path ./install \! -name .DS_Store)

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
		$(pkg_nginx_files) \
		$(pkg_nginx_conf) \
		$(pkg_nginx_html) \
		$(pkg_install_dirs) \
		$(pkg_install_files) \
		| $(pkg_nginx_dirs) \
		$$(dir $$@)
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
	printf 'OpenSSL Library Version: %s\n' "$(openssl_version)" >> $@
	printf 'PCRE2 Library Version: %s\n' "$(pcre2_version)" >> $@
	printf 'zlib Library Version: %s\n' "$(zlib_version)" >> $@
	printf 'Installer Revision: %s\n' "$(revision)" >> $@
	printf 'Architectures: %s\n' "$(arch_list)" >> $@
	printf 'macOS Version: %s\n' "$(macos)" >> $@
	printf 'Xcode Version: %s\n' "$(xcode)" >> $@
	printf 'APP_SIGNING_ID: %s\n' "$(APP_SIGNING_ID)" >> $@
	printf 'INSTALLER_SIGNING_ID: %s\n' "$(INSTALLER_SIGNING_ID)" >> $@
	printf 'NOTARIZATION_KEYCHAIN_PROFILE: %s\n' \
			"$(NOTARIZATION_KEYCHAIN_PROFILE)" >> $@
	printf 'TMP directory: %s\n' "$(TMP)" >> $@
	printf 'Tag: %s\n' "$(tag)" >> $@
	printf 'Tag Title: %s\n' "$(tag-title)" >> $@
	printf 'Tag Message: %s\n' "$(tag-message)" >> $@

$(TMP)/distribution.xml \
$(TMP)/resources/welcome.html : $(TMP)/% : % | $$(dir $$@)
	sed \
		-e 's/{{arch_list}}/$(arch_list)/g' \
		-e 's/{{date}}/$(date)/g' \
		-e 's/{{macos}}/$(macos)/g' \
		-e 's/{{openssl_version}}/$(openssl_version)/g' \
		-e 's/{{pcre2_version}}/$(pcre2_version)/g' \
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
$(TMP)/arm64 \
$(TMP)/x86_64 \
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

nginx-$(ver).pkg : \
		$(TMP)/nginx-$(ver)-unnotarized.pkg \
		$(TMP)/notarized.stamp.txt
	cp $< $@
	xcrun stapler staple $@

$(TMP)/checked-package.stamp.txt : nginx-$(ver).pkg
	test "$(shell lipo -archs $(TMP)/pkg/usr/local/nginx/sbin/nginx)" = "x86_64 arm64"
	test "$(shell ./tools/dylibs --no-sys-libs --count $(TMP)/pkg/usr/local/nginx/sbin/nginx) dylibs" = "0 dylibs"
	codesign --verify --strict $(TMP)/pkg/usr/local/nginx/sbin/nginx
	pkgutil --check-signature nginx-$(ver).pkg
	spctl --assess --type install nginx-$(ver).pkg
	xcrun stapler validate nginx-$(ver).pkg


##### release ##########

$(TMP)/tagged.stamp.txt : $(TMP)/checked-package.stamp.txt
		git diff --quiet && git diff --cached --quiet
		git tag \
		    --annotate $(tag) \
			--message="$(tag-title)" \
			--message="$$(echo "$(tag-message)" | fold -s)"
		git push origin $(tag)
		date > $@

$(TMP)/released.stamp.txt : $(TMP)/tagged.stamp.txt
		gh release create $(tag) \
		    pkg-config-$(ver).pkg \
			--draft \
			--notes "$(tag-message)" \
			--title "$(tag-title)"
		date -> $@
