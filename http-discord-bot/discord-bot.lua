local Config = {}
Config._RCONPASS = "changeme1234" -- This is the password that will be checked against the password sent by the discord bot, if they do not match the request will be returned with code 401.
Config._ENDPOINT = "/" -- Refer to https://forum.cfx.re/t/release-util-lua-http-wrapper/1366733 to manage endpoints.
Config._RCONCOMMANDS = {
    ["say"] = function(SArgs) -- Here is an example command
        -- @SARGs is the arguments from the discord command if there are any in string format. Use a string split function to put them back into a table format.
        if SArgs then -- Check if args exist.
            TriggerClientEvent("chat:addMessage", -1, { args = { "[^8RCON^7]", SArgs --[[ Send args, they are already in string format ]] } })
        end
    end,
    ["drop"] = function(SArgs)
        if SArgs then
            Args = string_split(SArgs)
            if Args[1] and tonumber(Args[1]) ~= nil then
                local Reason = "No reason specified"
                if Args[2] then
                    Reason = table.concat(Args, " ", 2)
                end

                DropPlayer(tonumber(Args[1]), Reason)
            end 
        end
    end
}

-- DO **NOT** CHANGE ANYTHING BELOW UNLESS YOU KNOW WHAT YOU ARE DOING!!!!!

function string_split(InStr, Seperator) -- String split function, turns table elements into string as seperated by the given seperator.
    if Seperator == nil then
        Seperator = "%s"
    end

    local Temp = {}

    for Str in string.gmatch(InStr, "([^"..Seperator.."]+)") do
        table.insert(Temp, Str)
    end

    return Temp
end

HTTP.Router:POST(Config._ENDPOINT, function(Req, Res)
    HTTP.Headers:Set("Content-Type", "application/json")
    if (Req.headers.Authentication == nil) or (Req.headers.Authentication ~= Config._RCONPASS) then
        print("^8A request was made with invalid authentication!^7")
        Res.writeHead(401, HTTP.Headers:All())
        Res.send(json.encode({}))

        return
    end

    if not Req.body then
        Res.writeHead(400, HTTP.Headers:All())
        Res.send(json.encode({}))

        return
    end

    if not Req.body.command or not Config._RCONCOMMANDS[Req.body.command] then
        Res.writeHead(400, HTTP.Headers:All())
        Res.send(json.encode({}))

        return
    end

    Config._RCONCOMMANDS[Req.body.command]((Req.body.args))
    Res.writeHead(200, HTTP.Headers:All())
    Res.send(json.encode({}))

    return
end)
