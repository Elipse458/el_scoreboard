ESX = nil
local playerdata,recentconnect,recentdisconnect,servername = {},{},{},GetConvar("sv_hostname","N/A")

TriggerEvent("esx:getSharedObject", function(obj) ESX = obj end)

ESX.RegisterServerCallback("el_scoreboard:getPlayerData", function(source,cb)
    cb(playerdata,recentconnect,recentdisconnect)
end)

ESX.RegisterServerCallback("el_scoreboard:getServerName", function(source,cb)
    cb(servername)
end)

ESX.RegisterServerCallback("el_scoreboard:whatsMyGroup", function(source,cb)
    cb(ESX.GetPlayerFromId(source).getGroup())
end)

ESX.RegisterServerCallback("el_scoreboard:gotoPlayer", function(source,cb,target)
    local xPlayer = ESX.GetPlayerFromId(source)
    local admin = xPlayer.getGroup()=="admin" or xPlayer.getGroup()=="superadmin"
    if admin then
        TriggerClientEvent("el_scoreboard:adminBringReq",target,source)
    end
    cb(admin)
end)

ESX.RegisterServerCallback("el_scoreboard:slayPlayer", function(source,cb,target)
    local xPlayer = ESX.GetPlayerFromId(source)
    local admin = xPlayer.getGroup()=="admin" or xPlayer.getGroup()=="superadmin"
    if admin then
        TriggerClientEvent("el_scoreboard:adminSlayReq",target)
    end
    cb(admin)
end)

ESX.RegisterServerCallback("el_scoreboard:kick", function(source,cb,target,reason)
    local xPlayer = ESX.GetPlayerFromId(source)
    local admin = xPlayer.getGroup()=="admin" or xPlayer.getGroup()=="superadmin"
    if admin then
        DropPlayer(target,reason)
    end
    cb(admin)
end)

AddEventHandler("playerConnecting", function(playername, kickreason, def)
    table.insert(recentconnect,{name=GetPlayerName(source),time=os.time()})
end)

AddEventHandler("playerDropped", function(reason)
    table.insert(recentdisconnect,{name=GetPlayerName(source),time=os.time(),reason=reason})
end)

-- Citizen.CreateThread(function()
--     Citizen.Wait(1500) -- wait for clients to load their lazy asses
--     for k,v in ipairs(GetPlayers()) do -- if resource gets restarted, re-setup online players
--         TriggerClientEvent("el_scoreboard:join", v, servername)
--     end
-- end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        local newplayerdata = {}
        for k,v in ipairs(GetPlayers()) do
            local xPlayer = ESX.GetPlayerFromId(v)
            if xPlayer then
                table.insert(newplayerdata,{sid=v,ping=GetPlayerPing(v),name=GetPlayerName(v),group=xPlayer.getGroup(),job=xPlayer.getJob().label,stid=xPlayer.identifier})
            end
        end
        playerdata = newplayerdata
        if #recentconnect>=Config.connect_history then
            table.remove(recentconnect,1)
        end
        if #recentdisconnect>=Config.disconnect_history then
            table.remove(recentdisconnect,1)
        end
    end
end)