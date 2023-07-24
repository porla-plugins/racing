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

        local timer = timers.new({
            interval = interval,
            callback = function()
                log.debug(string.format("Checking if %s needs reannouncing", torrent.name))

                local peers = torrents.peers.list(torrent)

                if #(peers) > 0 then
                    log.info(string.format("Torrent %s has %d peers - racing done", torrent.name, #(peers)))

                    active_timers[torrent.name].timer:cancel()
                    active_timers[torrent.name] = nil

                    return
                end

                if active_timers[torrent.name].tries >= max_tries then
                    log.info(string.format("Torrent %s reached max announce tries", torrent.name))

                    active_timers[torrent.name].timer:cancel()
                    active_timers[torrent.name] = nil

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
                            log.info(string.format("Matching tracker message '%s' against known failures (tracker %s)", aih.message, tracker.url))

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
                    log.info(string.format("Sending reannounce attempt %d of %d for %s", active_timers[torrent.name].tries + 1, max_tries, torrent.name))

                    torrents.reannounce(torrent, {
                        seconds       = 0,
                        tracker_index = -1
                    })

                    active_timers[torrent.name].tries = active_timers[torrent.name].tries + 1

                    return
                end

                log.warning(string.format("No tracker for %s matches any known failure - skipping reannounce", torrent.name))

                active_timers[torrent.name].timer:cancel()
                active_timers[torrent.name] = nil
            end
        })

        active_timers[torrent.name] = {
            timer = timer,
            tries = 0
        }
    end,

    cancel = function()
        for name, _ in pairs(active_timers) do
            log.info(string.format("Cancelling timer for %s (currently on attempt %d)", name, active_timers[name].tries))

            active_timers[name].timer:cancel()
            active_timers[name] = nil
        end
    end
}
