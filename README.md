# Racing tools for Porla

This plugin contains tools and utils for making it easier to get ahead in early
swarms for newly announced torrents.

This plugin requires Porla 0.35.1-beta.1+163 or newer. That is anything with PR #249 merged.

## Configuration

```lua
return {
    -- the reannounce runs whenever a torrent is added. it maches the torrent
    -- against the filter function. if the filter function returns true, it will
    -- start a reannounce chain, doing <max_tries> reannounces with <interval>
    -- milliseconds of sleep between.
    reannounce = {
        filter = function(torrent)
            local userdata = torrent:userdata()
            --the tag "racing" is set for this torrent.
            return userdata.tags.racing
        end,

        interval  = 7000,
        max_tries = 18
    }
}
```

### `filter`
Boolean. Function that filters which torrents the plugin will reannounce.
Defaults to nil.

### `interval`
Integer. Time between reannounce attempts in milliseconds. Defaults to 7000.

### `max_tries`
Integer. Maximum number of time the plugin will attempt a reannounce.
Defaults to 18.