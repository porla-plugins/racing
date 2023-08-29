local log      = require("log")
local timers   = require("timers")
local torrents = require("torrents")

local active_timers = {}

return {
    begin = function(torrent, interval, max_tries, max_age, add_tags, remove_tags)

        local torrentstatus = torrent:status()
        local peers         = torrentstatus.num_peers
        local name          = torrentstatus.name

        if peers > 0 then
            log.info(string.format("Torrent %s already has %d peer(s) - not reannouncing", name, peers))
            return
        end

        local timer = timers.new({
            interval = interval,
            callback = function()
                if not torrent:is_valid() then
                    log.info("Torrent doesn't exist - not reannouncing")

                    active_timers[name].timer:cancel()
                    active_timers[name] = nil

                    return
                end

                log.debug(string.format("Checking if %s needs reannouncing", name))

                local torrentstatus = torrent:status()
                local peers         = torrentstatus.num_peers
                local name          = torrentstatus.name

                if peers > 0 then
                    log.info(string.format("Torrent %s has %d peers - racing done", name, peers))

                    active_timers[name].timer:cancel()
                    active_timers[name] = nil

                    return
                end

                local age = os.time() - torrentstatus.added_time

                if (active_timers[name].tries >= max_tries) or (age > max_age) then
                    log.info(string.format("Torrent %s reached max announce tries or age", name))
                    local userdata = torrent:userdata()

                    for _,v in pairs(add_tags) do
                        userdata.tags:add(v)
                    end

                    for _,v in pairs(remove_tags) do
                        userdata.tags:erase(v)
                    end

                    torrent:set_flags({
                        auto_managed = false,
                    })
                    torrent:pause()

                    active_timers[name].timer:cancel()
                    active_timers[name] = nil

                    return
                end

                if torrent:flags().paused then
                    log.info(string.format("Torrent %s paused, not reannouncing", name))

                    return
                end

                if peers == 0 then
                    log.info(string.format("Sending reannounce attempt %d of %d for %s", active_timers[name].tries + 1, max_tries, name))

                    torrent:force_reannounce({
                        seconds       = 0,
                        tracker_index = -1
                    })

                    active_timers[name].tries = active_timers[name].tries + 1

                    return
                end

                active_timers[name].timer:cancel()
                active_timers[name] = nil
            end
        })

        active_timers[name] = {
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
