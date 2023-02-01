#!/usr/bin/env lua5.2
sleep = require "socket".sleep

-- Server and channel to listen on
server = "127.0.0.1"
chan = "#chat"

bot = irc.new {
	nick = "Moonbot",
	realname = "Moonbot",
	username = "moonbot"
}

users = {}
usernotes = {}
usernotes_tmp = {}

function log(category, msg)
	io.stdout:write(string.format(" \27[36;1m%s\t\27[0m %s\n", category, msg))
end

-- This is called inside an if statement if the command has an argument.
function getcmdarg(msg, cmd)
	if string.match(tostring(msg), cmd .. " %w+") then
		return string.gsub(tostring(msg), cmd .. ' ', '', 1)
	else return false
	end
end

-- Hooks --

-- Join message
bot:hook("OnJoin", function(user, channel)
	if user.nick == "Moonbot" then return end
	local newuser = true
	for _, v in pairs(users) do
		if v == user.username then
			newuser = false
			goto continue
		end
	end
	::continue::
	if newuser then
		log("users", string.format("%s (%s) joined %s for the first time", user.nick, user.username, channel))
		bot:sendChat(channel, string.format("Welcome to the channel, %s!", user.nick))
		table.insert(users, user.username)
	else
		log("users", string.format("%s (%s) joined %s", user.nick, user.username, channel))
		bot:sendChat(channel, string.format("Welcome back, %s!", user.nick))
	end
end)

-- Leave message
bot:hook("OnPart", function(user, channel) 
	log("users", string.format("%s (%s) parted from %s", user.nick, user.username, channel))
	bot:sendChat(channel, string.format(quitmsgs[math.random(1, #quitmsgs)], user.nick))
end)

-- Quit message
bot:hook("OnQuit", function(user, channel) 
	log("users", string.format("%s (%s) quit", user.nick, user.username, channel))
	bot:sendChat(channel, string.format(quitmsgs[math.random(1, #quitmsgs)], user.nick))
end)

-- Commands
bot:hook("OnChat", function(user, channel, message)
	if not usernotes[user.username] then usernotes[user.username] = {} end
	for k, v in pairs(usernotes_tmp) do
		if user.username == k then
			usernotes[user.username][message] = usernotes_tmp[user.username]
			bot:sendChat(channel, string.format("%s: saved note", user.username))
			usernotes_tmp[user.username] = nil
			return
		end
	end
	if string.match(message, "^%-%-") then
		local cmd = string.gsub(message, '%-%- *', '', 1)
		if cmd == "help" then
			log("cmds", string.format("%s (%s) called command '%s'", user.nick, user.username, cmd))
			bot:sendChat(channel, "Help for my commands can be found at https://github.com/luajerry/moonbot/raw/master/HELP")
		elseif getcmdarg(cmd, "echo") then
			log("cmds", string.format("%s (%s) called command '%s'", user.nick, user.username, cmd))
			bot:sendChat(channel, getcmdarg(cmd, "echo"))
		elseif getcmdarg(cmd, "remember") then
			log("cmds", string.format("%s (%s) called command '%s'", user.nick, user.username, cmd))
			local cmdarg = getcmdarg(cmd, "remember")
			bot:sendChat(channel, string.format("%s: enter the name of the note:", user.username))
			usernotes_tmp[user.username] = cmdarg
		elseif getcmdarg(cmd, "shownote") then
			log("cmds", string.format("%s (%s) called command '%s'", user.nick, user.username, cmd))
			local cmdarg = getcmdarg(cmd, "shownote")
			if usernotes[user.username][cmdarg] then
				bot:sendChat(channel, usernotes[user.username][cmdarg])
			else
				bot:sendChat(channel, string.format("%s: no such note: '%s'", user.username, cmdarg))
			end
		end
	end
end)

log("init", "initialised")

bot:connect(server)
log("init", string.format("connected to %s", server))
bot:join(chan)
log("chan", string.format("joined %s", chan))

while true do
	bot:think()
	sleep(0.5)
end
