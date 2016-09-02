Syncing Flutter
===============

## Strategy

We try to keep our version of Flutter as up-to-date as possible by performing
frequent syncs. This is so that we get the latest features and bugfixes in a
timely fashion and that the potential, ensuing breakages do not get compounded.


## Performing a sync

Syncs are performed using a command which takes care of most of the work: it
inspects new changes in Flutter and generates a commit.
```sh
$ sync_flutter generate
Working directory: /tmp/sync_flutterhlhnds
Flutter currently synced at: d6a605363023cbbbf5e9f589733a69e6b9936ad1
Current Flutter head is: afc0550a67c02f87ef7188578bddf1c691213800
5 missing commits:
    afc0550 Fix circle antialiasing in the animation demo (#5729)
    f6f37ef Roll the engine (#5725)
    9e808aa Change from plural to singular (#5705)
    8a20b26 Changed Material ease animations to fastOutSlowIn. (#5643)
    c57635f adjust channel_test to be less specific (#5721)
Engine revision: dcb026188a53e9724c282baaab7ea47ac8ffb2bd
mojo_sdk package: 0.2.31
Commit created!
```


## Inspecting new commits

In order to check what's new in Flutter without actually creating a PR, use the
`diff` option:
```sh
$ sync_flutter diff
Showing commits from: d6a605363023cbbbf5e9f589733a69e6b9936ad1 to HEAD
-------------------------------------
afc0550 Fix circle antialiasing in the animation demo (#5729)
f6f37ef Roll the engine (#5725)
9e808aa Change from plural to singular (#5705)
8a20b26 Changed Material ease animations to fastOutSlowIn. (#5643)
c57635f adjust channel_test to be less specific (#5721)
-------------------------------------
5 commits
```
