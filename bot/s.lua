-- Required libs
Discordia = require("discordia")
BOT = Discordia.Client()
json = require("json")
http = require("coro-http")
fs = require("fs")

-- Config. **MAKE SURE VALUES MARKED WITH "_NAME" MATCH WITH THE VALUE ON THE SERVER CONFIG!!!** 
Config = json.decode(fs.readFileSync("config.json"))
Prefix = Config.Prefix

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

CommandManager = {
    [Prefix.."rcon"] = {
        ["AdminOnly"] = true, -- The user using this command needs to have the administrator permission.
        ["Handle"] = function(Payload, Args)
            coroutine.wrap(function()
                if Args[2] then
					local RCONCommand = tostring(Args[2])
                    local RCONArgs = nil
                    
					if Args[3] then
						RCONArgs = table.concat(Args, " ", 3) -- Turns all args into string as seperated by a space " ". We start at index 3 as index 2 and 1 are the command and rcon command.
                    end
					local Suc, Res, Body = pcall(http.request, "POST", "http://"..Config.ServerIP..":"..Config.ServerPort.."/"..Config._RESOURCENAME..Config._ENDPOINT, { { "Authentication", Config._RCONPASS } }, json.encode({ ["command"] = tostring(Args[2]), ["args"] = RCONArgs }) )
					if Suc then
						Res = json.decode(json.encode(Res))
						if Res.code == 200 then 
							Payload:reply("Request successful!")
						else
                            Payload:reply("Request failed!\nCode: ``"..Res.code.."``")
						end
					else
						Payload:reply("Request failed!\nServer offline?")
                    end
                    
					Suc, Res, Body = nil, nil, nil

					return
				end
            end)()
        end
    }
}

BOT:on("messageCreate", function(Payload)
	if Payload.author.id == BOT.user.id or Payload.guild == nil then 
        return
	end

	local Content = Payload.content
    local Args = string_split(Content)
    if Args[1] and Args[1]:sub(1, 1) == Prefix then
        Command = Args[1]:lower()
        if CommandManager[Command] then
            local CommandOBJ = CommandManager[Command]

            if CommandOBJ.AdminOnly and not Payload.member:hasPermission("administrator") then 
                print("A non admin just entered an admin command "..Payload.author.name.."#"..Payload.author.discriminator)
                Payload:reply("You do not have permission to use that command.")

                return
            end

            CommandOBJ.Handle(Payload, Args)
        end
    end
end)

BOT:on("ready", function()
    print("Bot online.")
end)

BOT:run(Config.Token)