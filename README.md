nginx 1.24.0 for macOS
======================

This project builds a signed and notarized macOS universal installer package
for [`nginx`][1], a widely used and capable HTTP and proxy server.  It contains
the source distributions of nginx 1.24.0, [PCRE2 10.42][2] and [zlib 1.3][3].

[1]: https://nginx.org "nginx"
[2]: http://www.pcre.org
[3]: https://www.zlib.net

## Prerequesites

A recent version of Xcode and the [`jq`][4] command are needed to build and
notarize this installer package.  An [Apple Developer][5] account is required
to generate the credentials needed to sign and notarize.

[4]: https://stedolan.github.io/jq/
[5]: https://developer.apple.com

## Building

The [`Makefile`][6] in the project root directory builds the installer package.
The following makefile variables can be set from the command line:

- `APP_SIGNING_ID`: The name of the 
    [Apple _Developer ID Application_ certificate][7] used to sign the 
    `nginx` executable.  The certificate must be installed on the build 
    machine's Keychain.  Defaults to "Developer ID Application: Donald 
    McCaughey" if not specified.
- `INSTALLER_SIGNING_ID`: The name of the 
    [Apple _Developer ID Installer_ certificate][7] used to sign the 
    installer.  The certificate must be installed on the build machine's
    Keychain.  Defaults to "Developer ID Installer: Donald McCaughey" if 
    not specified.
- `NOTARIZATION_KEYCHAIN_PROFILE`: The name of the notarization credentials
    stored on the build machine's Keychain.  Use the `notarytool 
    store-credentials` command to create this profile.  Defaults to "Donald 
    McCaughey" if not specified.
- `TMP`: The name of the directory for intermediate files.  Defaults to 
    "`./tmp`" if not specified.

[6]: https://github.com/donmccaughey/nginx_pkg/blob/master/Makefile
[7]: https://developer.apple.com/account/resources/certificates/list

To build and sign the executable and installer, run:

        $ make [APP_SIGNING_ID="<cert name 1>"] [INSTALLER_SIGNING_ID="<cert name 2>"] [TMP="<build dir>"]

Intermediate files are generated in the temp directory; the signed installer 
package is written into the project root with the name `nginx-1.24.0-r2.pkg`.
To notarize the signed installer package, run:

        $ make notarize [NOTARIZATION_KEYCHAIN_PROFILE="<profile name>"] [TMP="<build dir>"]

This will submit the installer package for notarization and staple it on 
success.  Check the file `$(TMP)/notarization-log.json` for detailed 
information if notarization fails.  The signed installer is stapled in place
if notarization succeeds.  Use the command:

        $ xcrun stapler validate --verbose nginx-1.24.0-r2.pkg

to check the notarization state of the installer package.

To remove all generated files (including the signed installer), run:

        $ make clean

## Signing and Notarizing Credentials

Three sets of credentials are needed to sign and notarize this package:
- A "Developer ID Application" certificate (for signing the `nginx` executable)
- A "Developer ID Installer" certificate (for signing the installer package)
- An App Store Connect API key (for notarizing the signed installer)

The two certificates are obtained from the [Apple Developer portal][8]; use the 
[Keychain Access app][9] to create the certificate signing requests.  Add the 
certificates to the build machine's Keychain.

The App Store Connect API key is obtained from the [App Store Connect site][10].
After the key is created, get the _Issuer ID_ (a UUID), the _Key ID_
(an alphanumeric string) and download the API key, which comes as a file named
`AuthKey_<key id>.p8`.  To add the API key to the build machine's Keychain, 
use the `store-credentials` subcommand of `notarytool`:

        $ xcrun notarytool store-credentials "<keychain profile name>" \
            --key ~/.keys/AuthKey_<key id>.p8 \
            --key-id <key id> \
            --issuer <issuer id> \
            --sync

The `--sync` option adds the credentials to the user's iCloud Keychain.

[8]: https://developer.apple.com/account/resources/certificates/add
[9]: https://help.apple.com/developer-account/#/devbfa00fef7
[10]: https://appstoreconnect.apple.com/access/api

## License

The installer and related scripts are copyright (c) 2023 Don McCaughey.
`nginx` and the installer are distributed under a BSD-style license.
See the LICENSE file for details.

