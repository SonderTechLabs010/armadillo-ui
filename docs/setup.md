Install the Gerrit commit hook:

```sh
curl -Lo .git/hooks/commit-msg https://fuchsia-review.googlesource.com/tools/hooks/commit-msg
chmod u+x .git/hooks/commit-msg
```

Authenticate by going to your profile settings on Gerrit, selecting `HTTP Password > Obtain Password`, and following the instructions.
