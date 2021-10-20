# TODO

1. When `notarytool submit` fails (e.g. on timeout), it leaves an empty
    `submit-log.json` behind: figure out how to not create or remove the file
    on failure
1. When `jq --raw-output '.id' < $< > $@` fails to find a value for `id`, it
    leaves an empty `submission-id.txt` file behind: figure out how to not
    create or remove the file on failure

