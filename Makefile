TMP ?= $(abspath tmp)

version := 1.15.2
revision := 1


.SECONDEXPANSION :


.PHONY : all
all : nginx-$(version).pkg


.PHONY : clean
clean :
	-rm -f nginx-*.pkg
	-rm -f nginx/Makefile
	-rm -rf $(TMP)


##### nginx dist ##########

# configure

$(TMP)/nginx/build :
	mkdir -p $@

$(TMP)/nginx/configured.stamp.txt : ./nginx/configure | $(TMP)/nginx/build
	cd ./nginx && ./configure \
		--builddir=$(TMP)/nginx/build \
		--without-http_rewrite_module
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
	cd ./nginx && $(MAKE)
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
	cd ./nginx && $(MAKE) DESTDIR=$(TMP)/nginx/install install
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
	$(TMP)/nginx/install/usr/local/nginx/conf/nginx.conf \
	$(TMP)/nginx/install/usr/local/nginx/conf/nginx.conf.default \
	$(TMP)/nginx/install/usr/local/nginx/conf/scgi_params \
	$(TMP)/nginx/install/usr/local/nginx/conf/scgi_params.default \
	$(TMP)/nginx/install/usr/local/nginx/conf/uwsgi_params \
	$(TMP)/nginx/install/usr/local/nginx/conf/uwsgi_params.default \
	$(TMP)/nginx/install/usr/local/nginx/conf/win-utf \
	$(TMP)/nginx/install/usr/local/nginx/html/50x.html \
	$(TMP)/nginx/install/usr/local/nginx/html/index.html \
	$(TMP)/nginx/install/usr/local/nginx/sbin/nginx

nginx_installed_dirs := \
	$(TMP)/nginx/install/usr/local/nginx/logs \
	$(sort $(dir $(nginx_installed_files)))

$(nginx_installed_files) $(nginx_installed_dirs) : $(TMP)/nginx/installed.stamp.txt
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

nginx_pkg_dirs := $(patsubst $(TMP)/nginx/install/%,$(TMP)/pkg/%,\
		$(nginx_installed_dirs) $(nginx_extra_dirs))
	
$(nginx_pkg_dirs) : $(TMP)/pkg/% : $(TMP)/nginx/install/%
	mkdir -p $@

nginx_pkg_files := $(patsubst $(TMP)/nginx/install/%,$(TMP)/pkg/%,\
		$(nginx_installed_files) $(nginx_extra_files))

$(nginx_pkg_files) : $(TMP)/pkg/% : $(TMP)/nginx/install/% | $$(dir $$@)
	cp $< $@

# install

install_dirs := $(shell find ./install -type d \! -path ./install \! -name .DS_Store)

pkg_dirs := $(patsubst ./install/%,$(TMP)/pkg/%,$(install_dirs))

$(pkg_dirs) : $(TMP)/pkg/% : ./install/%
	mkdir -p $@

install_files := $(shell find ./install -type f \! -name .DS_Store)

pkg_files := $(patsubst ./install/%,$(TMP)/pkg/%,$(install_files))

$(pkg_files) : $(TMP)/pkg/% : ./install/% | $$(dir $$@)
	cp $< $@

# uninstall

$(TMP)/pkg/usr/local/nginx/sbin/uninstall-nginx : \
		./uninstall-nginx \
		$(nginx_pkg_files) \
		$(pkg_files) \
		| $$(dir $$@)
	cp $< $@
	cd $(TMP)/pkg && find . -type f \
		\! -name .DS_Store \
		\! -path './usr/local/nginx/*' \
		| sort >> $@
	sed -e 's/^\./rm -f /g' -i '' $@
	chmod a+x $@

# package

$(TMP)/nginx.pkg : \
		$(nginx_pkg_dirs) $(nginx_pkg_files) \
		$(pkg_dirs) $(pkg_files) \
		$(TMP)/pkg/usr/local/nginx/sbin/uninstall-nginx
	pkgbuild \
		--root $(TMP)/pkg \
		--identifier cc.donm.pkg.nginx \
		--ownership recommended \
		--version $(version) \
		$@


##### product ##########

date := $(shell date '+%Y-%m-%d')
macos:=$(shell \
	system_profiler -detailLevel mini SPSoftwareDataType \
	| grep 'System Version:' \
	| awk -F ' ' '{print $$4}' \
	)
xcode:=$(shell \
	system_profiler -detailLevel mini SPDeveloperToolsDataType \
	| grep 'Version:' \
	| awk -F ' ' '{print $$2}' \
	)

nginx-$(version).pkg : \
		$(TMP)/nginx.pkg \
		$(TMP)/build-report.txt \
		$(TMP)/distribution.xml \
		$(TMP)/resources/background.png \
		$(TMP)/resources/license.html \
		$(TMP)/resources/welcome.html
	productbuild \
		--distribution $(TMP)/distribution.xml \
		--resources $(TMP)/resources \
		--package-path $(TMP) \
		--version v$(version)-r$(revision) \
		--sign 'Donald McCaughey' \
		$@

$(TMP)/build-report.txt : | $$(dir $$@)
	printf 'Build Date: %s\n' "$(date)" > $@
	printf 'Software Version: %s\n' "$(version)" >> $@
	printf 'Installer Revision: %s\n' "$(revision)" >> $@
	printf 'macOS Version: %s\n' "$(macos)" >> $@
	printf 'Xcode Version: %s\n' "$(xcode)" >> $@
	printf 'Tag Version: v%s-r%s\n' "$(version)" "$(revision)" >> $@
	printf 'Release Title: nginx %s for macOS rev %s\n' "$(version)" "$(revision)" >> $@
	printf 'Description: A signed macOS installer package for `nginx` %s.\n' "$(version)" >> $@

$(TMP)/distribution.xml \
$(TMP)/resources/welcome.html : $(TMP)/% : % | $$(dir $$@)
	sed \
		-e s/{{date}}/$(date)/g \
		-e s/{{macos}}/$(macos)/g \
		-e s/{{revision}}/$(revision)/g \
		-e s/{{version}}/$(version)/g \
		-e s/{{xcode}}/$(xcode)/g \
		$< > $@

$(TMP)/resources/background.png \
$(TMP)/resources/license.html : $(TMP)/% : % | $$(dir $$@)
	cp $< $@

$(TMP) \
$(TMP)/resources : 
	mkdir -p $@

