local reannounce = require("tools.reannounce")
local events = require("porla_events")

local added_signal = nil

return {
    init = function(config)
        if config == nil then
            print("No racing config specified")
            return false
        end

        if config.reannounce ~= nil then
            if config.reannounce.filter == nil then
                print("A filter must be specified when running the racing reannounce")
            else
                print("Setting up racing reannounce event")

                added_signal = events.on("torrent.added", function(event)
                    local torrent = event.torrent
                    local status = torrent:status()
                    local name   = status.name
                    local filter = PoQuery.parse(config.reannounce.filter)
                    print(string.format("Checking %s against racing filter", name))

                    if filter:includes(status) then
                        print(string.format("Torrent %s matched racing filter - reannouncing", name))

                        local interval    = config.reannounce.interval or 7000
                        local max_tries   = config.reannounce.max_tries or 85
                        local max_age     = config.reannounce.max_age or 600
                        local add_tags    = config.reannounce.add_tags or {"racing-failed"}
                        local remove_tags = config.reannounce.remove_tags or {}

                        reannounce.begin(torrent, interval, max_tries, max_age, add_tags, remove_tags)
                    else
                        print(string.format("Torrent %s did not match racing filter", name))
                    end
                end)
            end
        end
    end,

    destroy = function()
        reannounce.cancel()

        if added_signal ~= nil then
            added_signal:cancel()
            added_signal = nil
        end
    end
}