nginx 1.20.1 for macOS
======================

This project builds a signed macOS installer package for [`nginx`][1], a
widely used and capable HTTP and proxy server.

[1]: http://nginx.org "nginx"

## Building

The `Makefile` in the project root directory builds the installer package.  The following
makefile variables can be set from the command line:

    - `SIGNING_ID`: The name of the 
        [Apple _Developer ID Installer_ certificate][2] to use to sign the 
        installer.  The certificate must be installed on the build machine's
        keychain.  Defaults to "Developer ID Installer: Donald McCaughey" if 
        not specified.
    - `TMP`: The name of the directory for intermediate files.  Defaults to 
        "`./tmp`" if not specified.

[2]: https://developer.apple.com/account/resources/certificates/list

To build the installer, run:

        $ make SIGNING_ID=<my cert name> [TMP=<build dir>]

to build and sign the installer.  Intermediate files are generated in the temp
directory; the signed installer package is written into the project root.  To 
remove all generated files, run:

        $ make clean

## License

The installer and related scripts are copyright (c) 2021 Don McCaughey.
`nginx` and the installer are distributed under a BSD-style license.
See the LICENSE file for details.

