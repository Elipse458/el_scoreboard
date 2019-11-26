ESX = nil
local PD,open,mygroup = nil,false,"user"

function updateNuiData()
	ESX.TriggerServerCallback("el_scoreboard:getPlayerData", function(a,b,c)
		SendNuiMessage(json.encode({type="update",data={pd=a,con=b,disc=c},mygroup=mygroup}))
	end)
end

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
	PD = ESX.GetPlayerData()
	updateNuiData()
	ESX.TriggerServerCallback("el_scoreboard:getServerName", function(sn)
		SendNuiMessage(json.encode({type="setup",pn=GetPlayerName(PlayerId()),sid=PD.identifier,sn=sn}))
	end)
	ESX.TriggerServerCallback("el_scoreboard:whatsMyGroup", function(mg)
		mygroup=mg
	end)
end)

Citizen.CreateThread(function()
	SetNuiFocus(false,false)
	while true do
		Citizen.Wait(500)
		if open then
			updateNuiData()
		end
	end
end)

RegisterNetEvent("el_scoreboard:adminBringReq")
AddEventHandler("el_scoreboard:adminBringReq", function(target)
	ESX.Game.Teleport(GetPlayerPed(-1),GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(target))))
end)

RegisterNetEvent("el_scoreboard:adminSlayReq")
AddEventHandler("el_scoreboard:adminSlayReq", function()
	SetEntityHealth(GetPlayerPed(-1), 0)
end)

RegisterNUICallback("toggle", function(data,cb) SetNuiFocus(data, data); open = data end)

RegisterNUICallback("admin-ctx", function(data,cb)
	local action = data.action
	local target = data.target
	local args = data.args
	if action=="warn" then
		ESX.TriggerServerCallback("el_bwh:warn",function(success)
			if success then ESX.ShowNotification("~g~Successfully warned player") else ESX.ShowNotification("~r~Something went wrong") end
		end, target, args, false)
	elseif action=="kick" then
		ESX.TriggerServerCallback("el_scoreboard:kick",function(success)
			if success then ESX.ShowNotification("~g~Successfully kicked player") else ESX.ShowNotification("~r~Something went wrong") end
		end, target, args)
	elseif action=="goto" then
		ESX.Game.Teleport(GetPlayerPed(-1),GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(target))))
	elseif action=="bring" then
		ESX.TriggerServerCallback("el_scoreboard:gotoPlayer", function(success)
			if success then ESX.ShowNotification("~g~Successfully brought player") else ESX.ShowNotification("~r~Something went wrong") end
		end, target)
	elseif action=="slay" then
		ESX.TriggerServerCallback("el_scoreboard:slayPlayer", function(success)
			if success then ESX.ShowNotification("~g~Successfully slain player") else ESX.ShowNotification("~r~Something went wrong") end
		end, target)
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if IsControlJustPressed(0, 56) then -- f9
			open = not open
			SendNuiMessage(json.encode({type="toggle",state=open}))
			SetNuiFocus(open, open)
			if open then
				updateNuiData()
			end
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(60000)
		ESX.TriggerServerCallback("el_scoreboard:whatsMyGroup", function(mg)
			mygroup=mg
		end)
	end
end)