local timers = require("porla_timers")

local active_timers = {}

return {
    begin = function(torrent, interval, max_tries, max_age, add_tags, remove_tags)
        local torrentstatus = torrent:status()
        local peers         = torrentstatus.num_peers
        local name          = torrentstatus.name

        if peers > 0 then
            print(string.format("Torrent %s already has %d peer(s) - not reannouncing", name, peers))
            return
        end

        local timer = timers.interval(
            interval,
            function()
                local entry = active_timers[name]
                if not entry then
                    return
                end

                if not torrent:is_valid() then
                    print(string.format("Torrent %s doesn't exist - not reannouncing", name))
                    entry.timer:cancel()
                    active_timers[name] = nil
                    return
                end
                
                print(string.format("Checking if %s needs reannouncing", name))

                local torrentstatus = torrent:status()
                local peers         = torrentstatus.num_peers
                local current_name  = torrentstatus.name

                if peers > 0 then
                    print(string.format("Torrent %s has %d peers - racing done", current_name, peers))
                    entry.timer:cancel()
                    active_timers[name] = nil
                    return
                end

                local age = os.time() - torrentstatus.added_time

                if (entry.tries >= max_tries) or (age > max_age) then
                    print(string.format("Torrent %s reached max announce tries or age", current_name))
                    local userdata = torrent:userdata()

                    for _,v in pairs(add_tags) do
                        userdata:add_tag(v)
                    end

                    for _,v in pairs(remove_tags) do
                        userdata:remove_tag(v)
                    end

                    local flags = LtTorrentFlags()
                    local mask  = LtTorrentFlags()
                    mask:set("auto_managed")
                    torrent:set_flags(flags, mask)
                    torrent:pause()

                    entry.timer:cancel()
                    active_timers[name] = nil
                    return
                end

                if peers == 0 then
                    print(string.format("Sending reannounce attempt %d of %d for %s", entry.tries + 1, max_tries, current_name))
                    torrent:force_reannounce(0, -1, { ignore_min_interval = true })
                    entry.tries = active_timers[name].tries + 1
                    return
                end
            end
        )

        active_timers[name] = {
            timer = timer,
            tries = 0
        }
    end,

    cancel = function()
        for name, entry in pairs(active_timers) do
            print(string.format("Cancelling timer for %s (currently on attempt %d)", name, entry.tries))
            entry.timer:cancel()
            active_timers[name] = nil
        end
    end
}