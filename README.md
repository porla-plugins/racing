# Racing tools for Porla

This plugin contains tools and utils for making it easier to get ahead in early
swarms for newly announced torrents.

This plugin requires Porla 0.51.0 or newer.

## Configuration

```lua
return {
    -- the reannounce runs whenever a torrent is added. It maches the torrent
    -- against the PQL Query. If the PQL filter query is matched, it will
    -- start a reannounce chain, doing <max_tries> reannounces with <interval>
    -- milliseconds of sleep between.
    reannounce = {
        filter = "$userdata.tags:\"racing\"",
        interval  = 7000,
        max_tries = 85,
        max_age = 600,
        add_tags = {"racing-failed"},
        remove_tags = {"racing"}
    }
}
```

### `filter`
[PQL Query](https://porla.org/concepts/pql). PQL query that filters which torrents the plugin will reannounce.
Defaults to 'racing'.

### `interval`
Integer. Time between reannounce attempts in milliseconds. Defaults to 7000.

### `max_tries`
Integer. Maximum number of times the plugin will attempt a reannounce.
Defaults to 85.

### `max_age`
Integer. Maximum time since the torrent was added to attempt to reannounce.
Defaults to 600.
This is useful if you have more racing torrents queued than your active
downloads setting.

If either max_tries or max_age is reached the torrent will have its
auto_managed flag set to false, be paused and have the add_tags applied and
remove_tags removed.

### `add_tags`
Table of tags (strings). The tags to apply to the torrent if either max_tries or max_age is
reached. Defaults to "racing-failed". If you don't want any tags added set add_tags to {}.

### `remove_tags`
Table of tags (strings). The tags to remove from a torrent if either max_tries or max_age
is reached. No tags are removed by default.

