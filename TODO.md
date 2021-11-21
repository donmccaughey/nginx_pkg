# TODO

1. Add line to end of `nginx.conf`:
    > include /Users/*/Sites/*/nginx.conf;
1. On macOS Monterey, user home dirs aren't world-readable or traversable 
    (missing chmod +orx)
1. Add /usr/local/nginx/man path file to /etc/manpaths.d
1. Strip xattrs from package files (showing up in path files)
1. When `notarytool submit` fails (e.g. on timeout), it leaves an empty
    `submit-log.json` behind: figure out how to not create or remove the file on
    failure
1. When `jq --raw-output '.id' < $< > $@` fails to find a value for `id`, it
    leaves an empty `submission-id.txt` file behind: figure out how to not
    create or remove the file on failure

