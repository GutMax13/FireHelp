-- �������� ����������
local ev = require 'lib.samp.events'
local inicfg = require 'inicfg'
local imgui = require 'imgui'
local encoding = require 'encoding'
local update_status = require('moonloader').download_status

-- ���� inicfg
local directIni = "moonloader\\fh_setting.ini"
local mainIni = inicfg.load(nil, directIni)

-- ���� Imgui
encoding.default = 'CP1251'
u8 = encoding.UTF8

local sw, sh = getScreenResolution()
local main_windows_state = imgui.ImBool(false)
local text_buffer = imgui.ImBuffer(256)
local siren = imgui.ImBool(false)

-- ���������������� ����������
local isFire = false
local player = tostring(u8:decode(mainIni.main.name))

-- ���� Update
local update_state = false
local script_version = 1.01
local script_version_text = tostring(script_version)

local update_url = "https://raw.githubusercontent.com/GutMax13/FireHelp/main/update.ini"
local update_path = getWorkingDirectory() .. "/update.ini"

local script_url = "https://raw.githubusercontent.com/GutMax13/FireHelp/main/FireHelp.lua"
local script_path = thisScript().path

local changelog_url = "https://raw.githubusercontent.com/GutMax13/FireHelp/main/changelog.ini"
local changelog_path = getWorkingDirectory() .. "/changelog.ini"

-- ������ �������
function main()
    if not isSampfuncsLoaded() or not isSampLoaded() then
        return
    end
    while not isSampAvailable() do
        wait(0)
    end
	downloadUrlToFile(update_url, update_path, function(id, status) 
		if status == update_status.STATUS_ENDDOWNLOADDATA then
			downloadUrlToFile(changelog_url, changelog_path, function(id, status)
				changelogIni = inicfg.load(nil, changelog_path)
			end)
			updateIni = inicfg.load(nil, update_path)
			if tonumber(updateIni.info.vers) > script_version then
				sampAddChatMessage("{fbec5d}[Update] {ffffff}����� ���������� (" .. script_version_text .. " >>> ".. updateIni.info.vers ..")", -1)
				update_state = true
			end
			os.remove(update_path)
		end
	end)
	
	imgui.Process = false
	sampRegisterChatCommand("fh", cmd_imgui)
	if mainIni.main.name == "" then
		sampAddChatMessage("{fbec5d}[FireHelp | {ffffff}Status - No Working {fbec5d}| Version - "..script_version_text.."]")
	else
		sampAddChatMessage("{fbec5d}[FireHelp | {ffffff}Status - Working {fbec5d}| Version - "..script_version_text.."]")
	end
    while true do
        wait(0)
		if update_state then
			downloadUrlToFile(script_url, script_path, function(id, status) 
				if status == update_status.STATUS_ENDDOWNLOADDATA then
					sampAddChatMessage("[Update] {ffffff}- C����� ��������", -1)
					thisScript():reload()
				end
			update_state = false
			end)
		end
		if isFire then
			player_x, player_z, x,z = pos()
			local sumX = math.abs(math.ceil(x) - math.ceil(player_x))
			local sumZ = math.abs(math.ceil(z) - math.ceil(player_z))
			if (sumX <= 30) and (sumZ <= 60) then
				sampSendChat("/i to disp: "..player..", ������� �� ����� ����������.", -1)
				isFire = false
			end
		end
		if main_windows_state.v == false then
			imgui.Process = false
		end
    end
end

-- ��������� ������������ �������
function ev.onSendEnterVehicle(vehicleID, passenger)
	if ((vehicleID == 1269) or (vehicleID == 1271) or (vehicleID == 1270) or (vehicleID == 1268) or (vehicleID == 551) or (vehicleID == 552)) and (passenger == false) and (mainIni.main.siren == true) then
		lua_thread.create(function()
		wait(4000)
		v = getCarCharIsUsing(PLAYER_PED)
        switchCarSiren(v, not isCarSirenOn(v))
		end)
	end
end

-- ������� �� ��������� � ���
function ev.onServerMessage(color, text)
	if text:find("������������� �� ����� {fbec5d}(%a+.+%d+)") then
		local address = text:match("������������� �� ����� {fbec5d}(%a+.+%d+)")
		sampSendChat("/i to disp: "..player..", ������ ����� �� ������: " .. upper_string(address), -1)
		lua_thread.create(function()
		wait(1000)
		isFire = true
		end)
	end
	if text:find("��� ����� ���������� �������������. ������������� ������� � �����������.") then
		sampSendChat("/i to disp: "..player..", ����� �������, ����������� � �����������.", -1)
		v = getCarCharIsUsing(PLAYER_PED)
        switchCarSiren(v, not isCarSirenOn(v))
	end
end

-- ����������� ����
function cmd_imgui(arg)
	main_windows_state.v = not main_windows_state.v
	imgui.Process = main_windows_state.v
end

-- ���������� ���� � ����
function imgui.OnDrawFrame()
	text_buffer.v = mainIni.main.name
	siren.v = mainIni.main.siren
	imgui.SetNextWindowSize(imgui.ImVec2(200,140), imgui.Cond.FirstUseEver)
	imgui.SetNextWindowPos(imgui.ImVec2((sw / 2), sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	imgui.Begin(u8"��������� �������", main_windows_state, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove)
	imgui.SetCursorPosX(40)
	imgui.Text(u8"����� ������� - GutMax")
	imgui.Text(u8"������� ���� ��� (�� �������)")
	imgui.SetCursorPosX(30)
	imgui.InputText("", text_buffer)
	imgui.SetCursorPosX(30)
	imgui.Checkbox(u8'�������� ������', siren)
	imgui.SetCursorPosX(60)
	mainIni.main.name = text_buffer.v
	mainIni.main.siren = siren.v
	if imgui.Button(u8'���������') then
		if inicfg.save(mainIni, directIni) then
			sampAddChatMessage("{fbec5d}[FireHelp]{ffffff} ���������!",-1)
		end
	end
	imgui.End()
end

-- ����������� ��������� ������ / ������� 
function pos()
	local player_x, player_y, player_z = getCharCoordinates(playerPed)
	res, x, y, z = SearchMarker(player_x, player_y, player_z, 9999.0, false)
	return player_x, player_z, x,z
end

-- ����� ������� �� �����
function SearchMarker(posX, posY, posZ, radius, isRace)
    local ret_posX = 0.0
    local ret_posY = 0.0
    local ret_posZ = 0.0
    local isFind = false

    for id = 0, 31 do
        local MarkerStruct = 0
        if isRace then MarkerStruct = 0xC7F168 + id * 56
        else MarkerStruct = 0xC7DD88 + id * 160 end
        local MarkerPosX = representIntAsFloat(readMemory(MarkerStruct + 0, 4, false))
        local MarkerPosY = representIntAsFloat(readMemory(MarkerStruct + 4, 4, false))
        local MarkerPosZ = representIntAsFloat(readMemory(MarkerStruct + 8, 4, false))

        if MarkerPosX ~= 0.0 or MarkerPosY ~= 0.0 or MarkerPosZ ~= 0.0 then
            if getDistanceBetweenCoords3d(MarkerPosX, MarkerPosY, MarkerPosZ, posX, posY, posZ) < radius then
                ret_posX = MarkerPosX
                ret_posY = MarkerPosY
                ret_posZ = MarkerPosZ
                isFind = true
                radius = getDistanceBetweenCoords3d(MarkerPosX, MarkerPosY, MarkerPosZ, posX, posY, posZ)
            end
        end
    end

    return isFind, ret_posX, ret_posY, ret_posZ
end

-- �������������� � �������� ����� 
function upper_string(str)
	str = str:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
	return str
end