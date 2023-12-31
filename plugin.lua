local reannounce = require("tools.reannounce")

local config     = require("config")
local events     = require("events")
local log        = require("log")

local added_signal = nil

function porla.init()
    if config == nil then
        log.warning("No racing config specified")
        return false
    end

    if config.reannounce ~= nil then
        if config.reannounce.filter == nil then
            log.error("A filter must be specified when running the racing reannounce")
        else
            log.info("Setting up racing reannounce event")

            added_signal = events.on("torrent_added", function(torrent)
                local torrentstatus = torrent:status()
                local name          = torrentstatus.name
                log.debug(string.format("Checking %s against racing filter", name))

                if config.reannounce.filter(torrent) then
                    log.info(string.format("Torrent %s matched racing filter - reannouncing", name))

                    local interval    = config.reannounce.interval
                    local max_tries   = config.reannounce.max_tries
                    local max_age     = config.reannounce.max_age
                    local add_tags    = config.reannounce.add_tags
                    local remove_tags = config.reannounce.remove_tags

                    if interval == nil then
                        interval = 7000
                    end

                    if max_tries == nil then
                        max_tries = 18
                    end

                    if max_age == nil then
                        max_age = 3600
                    end

                    if add_tags == nil then
                        add_tags = {"racing-failed"}
                    end

                    if remove_tags == nil then
                        remove_tags = {}
                    end

                    reannounce.begin(torrent, interval, max_tries, max_age, add_tags, remove_tags)
                else
                    log.debug(string.format("Torrent %s did not match racing filter", name))
                end
            end)
        end
    end

    return true
end

function porla.destroy()
    reannounce.cancel()

    if added_signal ~= nil then
        added_signal:disconnect()
        added_signal = nil
    end
end
