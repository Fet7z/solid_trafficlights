local entityEnumerator = {
	__gc = function(enum)
		if enum.destructor and enum.handle then
			enum.destructor(enum.handle)
		end
		enum.destructor = nil
		enum.handle = nil
	end
}

local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
	return coroutine.wrap(function()
		local iter, id = initFunc()
		if not id or id == 0 then
			disposeFunc(iter)
			return
		end
		local enum = {handle = iter, destructor = disposeFunc}
		setmetatable(enum, entityEnumerator)
		local next = true
		repeat
		coroutine.yield(id)
		next, id = moveFunc(iter)
		until not next
		enum.destructor, enum.handle = nil, nil
		disposeFunc(iter)
	end)
end

function EnumerateObjects()
	return EnumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
end

local props = {
	"prop_traffic_01a",
	"prop_traffic_03a",
	"prop_traffic_01b",
	"prop_traffic_01d",
	"prop_traffic_03b"
}

local enumeratedObjects = nil
local cachedPlayerCoords = vector3(0,0,0)

CreateThread(function()
	local propsHash = {}
	for i=1,#props do
		propsHash[GetHashKey(props[i])] = true
	end
	while true do
		sleepThread = 500
		local player = PlayerPedId()
		local pCoords = GetEntityCoords(player)
		local moveDst = #(pCoords - cachedPlayerCoords)
		if moveDst >= 50.0 then
			cachedPlayerCoords = pCoords
			for v in EnumerateObjects() do
				if propsHash[GetEntityModel(v)] then
					FreezeEntityPosition(v, true)
					SetEntityCanBeDamaged(v, false)
				end
			end
		end
		Wait(sleepThread)
	end
end)
