local log      = require("log")
local timers   = require("timers")
local torrents = require("torrents")

local active_timers = {}

return {
    begin = function(torrent, interval, max_tries)
        local peers = torrents.peers.list(torrent)

        if #(peers) > 0 then
            log.info(string.format("Torrent %s already has %d peer(s) - not reannouncing", torrent.name, #(peers)))
            return
        end

        local current_tries = 0
        local timer         = nil

        timer = timers.new({
            interval = interval,
            callback = function()
                log.debug(string.format("Checking if %s needs reannouncing", torrent.name))

                local peers = torrents.peers.list(torrent)

                if #(peers) > 0 then
                    log.info(string.format("Torrent %s has %d peers - racing done", torrent.name, #(peers)))

                    timer:cancel()
                    timer = nil

                    return
                end

                if current_tries >= max_tries then
                    log.info(string.format("Torrent %s reached max announce tries", torrent.name))

                    timer:cancel()
                    timer = nil

                    return
                end

                local match_failures = {
                    "not exist",
                    "not found",
                    "not registered",
                    "unregistered",
                    "not authorized"
                }

                local trackers = torrents.trackers.list(torrent)
                local found_matching_failure = false

                for _, tracker in ipairs(trackers) do
                    for _, endpoint in ipairs(tracker.endpoints) do
                        for _, aih in ipairs(endpoint.info_hashes) do
                            for _, message in ipairs(match_failures) do
                                local i, j = string.find(aih.message, message)

                                if i == nil or j == nil then
                                    goto next_message
                                end

                                found_matching_failure = true

                                ::next_message::
                            end
                        end
                    end
                end

                if found_matching_failure then
                    log.info(string.format("Sending reannounce attempt %d of %d for %s", current_tries + 1, max_tries, torrent.name))

                    torrents.reannounce(torrent, {
                        seconds       = 0,
                        tracker_index = -1
                    })

                    current_tries = current_tries + 1

                    return
                end

                log.warning(string.format("No tracker for %s matches any known failure - skipping reannounce", torrent.name))

                timer:cancel()
                timer = nil
            end
        })

        table.insert(active_timers, timer)
    end,

    cancel = function()
        for _, tmr in ipairs(active_timers) do
            if tmr ~= nil then
                tmr:cancel()
                tmr = nil
            end
        end
    end
}
