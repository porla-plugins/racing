# Racing tools for Porla

This plugin contains tools and utils for making it easier to get ahead in early
swarms for newly announced torrents.

## Configuration

```lua
return {
    -- the reannounce runs whenever a torrent is added. it maches the torrent
    -- against the filter function. if the filter function returns true, it will
    -- start a reannounce chain, doing <max_tries> reannounces with <interval>
    -- milliseconds of sleep between.
    reannounce = {
        filter = function(torrent)
            return torrent.tags:find("racing")
        end,

        interval  = 1000,
        max_tries = 7
    }
}
```
