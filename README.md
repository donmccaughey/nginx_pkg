nginx 1.20.1 for macOS
======================

This project builds a signed macOS installer package for [`nginx`][1], a
widely used and capable HTTP and proxy server.

[1]: http://nginx.org "nginx"

## Prerequesites

You need a recent version of Xcode and the [`jq`][2] command installed to 
build and notarize this installer package.

[2]: https://stedolan.github.io/jq/

## Building

The [`Makefile`][3] in the project root directory builds the installer package.
The following makefile variables can be set from the command line:

- `APP_SIGNING_ID`: The name of the 
    [Apple _Developer ID Application_ certificate][4] to use to sign the 
    `nginx` executable.  The certificate must be installed on the build 
    machine's keychain.  Defaults to "Developer ID Application: Donald 
    McCaughey" if not specified.
- `INSTALLER_SIGNING_ID`: The name of the 
    [Apple _Developer ID Installer_ certificate][4] to use to sign the 
    installer.  The certificate must be installed on the build machine's
    keychain.  Defaults to "Developer ID Installer: Donald McCaughey" if 
    not specified.
- `NOTARIZATION_KEYCHAIN_PROFILE`: The name of the authentication credentials
    stored on the Keychain by [`notarytool`][5] used for notarization.  Use
    the subcommand `notarytool store-credentials` to create this profile.
    Defaults to "Donald McCaughey" if not specified.
- `TMP`: The name of the directory for intermediate files.  Defaults to 
    "`./tmp`" if not specified.

[3]: https://github.com/donmccaughey/nginx_pkg/blob/master/Makefile
[4]: https://developer.apple.com/account/resources/certificates/list
[5]: https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow

To build the installer, run:

        $ make [APP_SIGNING_ID=<cert name 1>] [INSTALLER_SIGNING_ID=<cert name 2> [TMP=<build dir>]

to build and sign the installer.  Intermediate files are generated in the temp
directory; the signed installer package is written into the project root with
the name `nginx-1.20.1.pkg`.  To remove all generated files (including the
signed installer), run:

        $ make clean

To notarize the signed installer package, run:

        $ make [NOTARIZATION_KEYCHAIN_PROFILE=<profile name>] [TMP=<build dir>]

This will submit the installer package for notarization.  Check the file 
`$(TMP)/notarization-log.json` for detailed information of notarization fails.
The notarized and stapled installer package is written into the project root
with the name `nginx-1.20.1-notarized.pkg`.

## License

The installer and related scripts are copyright (c) 2021 Don McCaughey.
`nginx` and the installer are distributed under a BSD-style license.
See the LICENSE file for details.

