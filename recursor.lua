-- Debian default Lua configuration file for PowerDNS Recursor

-- Load DNSSEC root keys from dns-root-data package.
-- Note: If you provide your own Lua configuration file, consider
-- running rootkeys.lua too.
--dofile("/usr/share/pdns-recursor/lua-config/rootkeys.lua")

function get_challenge(file_path)
    local file = io.open(file_path, "r")
    if file then
        local value = file:read("*l")
        file:close()
        return value
    else
        return nil
    end
end

function preresolve(dq)
    domain = dq.qname
    if string.lower(domain:toString():gsub("%.$", "")):match("^[^%.]*_acme%-challenge") then
        local challenge_one = get_challenge("/tmp/challenge1.txt")
        local challenge_two = get_challenge("/tmp/challenge2.txt")

        if challenge_one and challenge_two then
            dq:addAnswer(pdns.TXT, challenge_one, 10)
            dq:addAnswer(pdns.TXT, challenge_two, 10)
            return true
        end
    end

    return false
end