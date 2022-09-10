---@diagnostic disable: undefined-global
--------------------------------------------------------------------------
--[[ DynamicMusic class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local SEASON_BUSY_MUSIC =
{
	day =
	{
		autumn = "music_mod/music/music_work",
		winter = "music_mod/music/music_work_winter",
		spring = "music_mod/music/music_work_spring",
		summer = "music_mod/music/music_work_summer",
                lunar = "music_mod/music/music_work_lunar",
		sailing = "music_mod/music/music_work_sailing",
	},
	dusk =
	{
		autumn = "music_mod/music/music_work_dusk",
		winter = "music_mod/music/music_work_winter_dusk",
		spring = "music_mod/music/music_work_spring_dusk",
		summer = "music_mod/music/music_work_summer_dusk",
                lunar = "music_mod/music/music_work_lunar_dusk",
		sailing = "music_mod/music/music_work_sailing_dusk",
	},
	night = 
	{
		autumn = "music_mod/music/music_work_night",
		winter = "music_mod/music/music_work_winter_night",
		spring = "music_mod/music/music_work_spring_night",
		summer = "music_mod/music/music_work_summer_night",
                lunar = "music_mod/music/music_work_lunar_night",
	        sailing = "music_mod/music/music_work_sailing_night",
	},
}

local SEASON_EPICFIGHT_MUSIC =
{
    autumn = "music_mod/music/music_epicfight",
    winter = "music_mod/music/music_epicfight_winter",
    spring = "music_mod/music/music_epicfight_spring",
    summer = "music_mod/music/music_epicfight_summer",
    lunar = "music_mod/music/music_epicfight_lunar",
	sailing = "music_mod/music/music_epicfight_sailing",
}

local SEASON_DANGER_MUSIC =
{
    autumn = "music_mod/music/music_danger",
    winter = "music_mod/music/music_danger_winter",
    spring = "music_mod/music/music_danger_spring",
    summer = "music_mod/music/music_danger_summer",
    lunar = "music_mod/music/music_danger_lunar",
	sailing = "music_mod/music/music_danger_sailing",
}

local TRIGGERED_DANGER_MUSIC =
{
    wagstaff_experiment = 
    {
        "music_mod/music/music_wagstaff_experiment",
    },

    crabking =
    {
        "music_mod/music/music_epicfight_crabking",
    },

    malbatross =
    {
        "music_mod/music/malbatross",
    },
        
    moonbase =
    {
        "music_mod/music/music_epicfight_moonbase",
        "music_mod/music/music_epicfight_moonbase_b",
    },

    toadstool =
    {
        "music_mod/music/music_epicfight_toadboss",
    },

    beequeen =
    {
        "music_mod/music/music_epicfight_4",
    },

    dragonfly =
    {
        "music_mod/music/music_epicfight_3",
    },

    shadowchess =
    {
        "music_mod/music/music_epicfight_4",
    },

    klaus =
    {
        "music_mod/music/music_epicfight_5a",
        "",
        "music_mod/music/music_epicfight_5b",
    },

    antlion =
    {
        "music_mod/music/music_epicfight_antlion",
    },

    stalker =
    {
        "music_mod/music/music_epicfight_stalker",
        "music_mod/music/music_epicfight_stalker_b",
        "",
    },

    pigking =
    {
        "music_mod/music/music_epicfight_pigking",
    },

    alterguardian_phase1 =
    {
        "music_mod/music/music_epicfight_champion1",
    },
    alterguardian_phase2 =
    {
        "music_mod/music/music_epicfight_champion2",
    },
    alterguardian_phase3 =
    {
        "music_mod/music/music_epicfight_champion3",
    },

    default =
    {
        "music_mod/music/music_epicfight_ruins",
    },
}

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _isruin = inst:HasTag("ruin")
local _iscave = _isruin or inst:HasTag("cave")
local _isenabled = true
local _busytask = nil
local _dangertask = nil
local _realdangertask = nil
local _lastdangermusic = nil
local _triggeredlevel = nil
local _isday = nil
local _isbusydirty = nil
local _extendtime = nil
local _soundemitter = nil
local _activatedplayer = nil --cached for activation/deactivation only, NOT for logic use
local _stingeractive = false -- Used to prevent music overlapping with stinger
local _innightmare = false -- When in caves
local _inlunar = false -- Player is on lunar island
local _inocean = false -- Player is not on land. (Triggers if ocean is nil in ChangeArea function)
local _isfullmoon = false -- Only true when full moon.

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------
local function StopContinuous()
	if _busytask ~= nil then
        _busytask:Cancel()
	end
	_busytask = nil
	_extendtime = 0
	_soundemitter:SetParameter("busy", "intensity", 0)
end
local function StopBusy(inst, istimeout)
    if not continuous_mode and _busytask ~= nil then
        if not istimeout then
            _busytask:Cancel()
        elseif _extendtime > 0 then
            local time = GetTime()
            if time < _extendtime then
                _busytask = inst:DoTaskInTime(_extendtime - time, StopBusy, true)
                _extendtime = 0
                return
            end
        end
        _busytask = nil
        _extendtime = 0
        _soundemitter:SetParameter("busy", "intensity", 0)
    end
end

local function StartBusy()
    if _busytask ~= nil and not _isbusydirty then
        _extendtime = GetTime() + 15
    elseif _soundemitter ~= nil and _dangertask == nil and not _stingeractive and (continuous_mode or _extendtime == 0 or GetTime() >= _extendtime) and _isenabled then
        if _isbusydirty then
            _isbusydirty = false
            _soundemitter:KillSound("busy")
			-- Check if music for phase and season exist
			local season = inst.state.season
			local phase = inst.state.phase
			if SEASON_BUSY_MUSIC[phase] == nil then
				phase = "day"
			end
			if SEASON_BUSY_MUSIC[phase][season] == nil then
				season = "autumn"
                        end
			if _inlunar then
				season = "lunar"
			end
            _soundemitter:PlaySound(
                (_innightmare and "music_mod/music/music_work_ruins") or
                (_iscave and "music_mod/music/music_work_cave") or
				(_isfullmoon and "music_mod/music/music_work_fullmoon") or
				(_inlunar and SEASON_BUSY_MUSIC[phase]["lunar"]) or
				(_inocean and SEASON_BUSY_MUSIC[phase]["sailing"]) or
                (SEASON_BUSY_MUSIC[phase][season]),
                "busy")
        end
        _soundemitter:SetParameter("busy", "intensity", 1)
        _busytask = inst:DoTaskInTime(15, StopBusy, true)
        _extendtime = 0
    end
end

local function ExtendBusy()
    if _busytask ~= nil then
        _extendtime = math.max(_extendtime, GetTime() + 10)
    end
end

local function RealStopDanger(inst)
	_realdangertask = nil
	_soundemitter:KillSound("danger")
	_dangertask = nil
	_triggeredlevel = nil
    _extendtime = 0
	if continuous_mode then
		StartBusy()
	end
end

local function StopDanger(inst, istimeout)
    if _dangertask ~= nil then
        if not istimeout then
            _dangertask:Cancel()
        elseif _extendtime > 0 then
            local time = GetTime()
            if time < _extendtime then
                _dangertask = inst:DoTaskInTime(_extendtime - time, StopDanger, true)
                _extendtime = 0
                return
            end
        end
        _dangertask = nil
        _triggeredlevel = nil
        _extendtime = 0
		if not istimeout then
			_soundemitter:KillSound("danger")
		else
			_soundemitter:SetParameter("danger", "intensity", 0)
			if continuous_mode then
				StartBusy()
			end
			_realdangertask = inst:DoTaskInTime(20, RealStopDanger)
		end
    end
end

local EPIC_TAGS = { "epic" }
local NO_EPIC_TAGS = { "noepicmusic" }
local function StartDanger(player)
    if _dangertask ~= nil then
        _extendtime = GetTime() + 10
		_soundemitter:SetParameter("danger", "intensity", 1)
	elseif _realdangertask ~= nil then
		StopBusy()
		StopContinuous()
		_realdangertask:Cancel()
		_realdangertask = nil
		--获取如果要播放的音乐和现在是不是同一首
		local season = inst.state.season
		if SEASON_DANGER_MUSIC[season] == nil then
			season = "autumn"
		end
		local x, y, z = player.Transform:GetWorldPosition()
		local epics = TheSim:FindEntities(x, y, z, 30, EPIC_TAGS, NO_EPIC_TAGS)
		local newmusic = #epics > 0
            and ((_innightmare and "music_mod/music/music_epicfight_ruins") or
                (_iscave and "music_mod/music/music_epicfight_cave") or
				(_inlunar and "music_mod/music/music_epicfight_lunar") or
				(_inocean and "music_mod/music/music_epicfight_sailing") or
                (SEASON_EPICFIGHT_MUSIC[season]))
            or ((_innightmare and "music_mod/music/music_danger_ruins") or
                (_iscave and "music_mod/music/music_danger_cave") or
				(_inlunar and "music_mod/music/music_epicfight_lunar") or
				(_inocean and "music_mod/music/music_epicfight_sailing") or
                (SEASON_DANGER_MUSIC[season]))
		if newmusic ~= _lastdangermusic then
			_soundemitter:KillSound("danger")
			_soundemitter:PlaySound(newmusic, "danger")
			_lastdangermusic = newmusic
			_triggeredlevel = nil
			_extendtime = 0
		end
		--
		_soundemitter:SetParameter("danger", "intensity", 1)
		_dangertask = inst:DoTaskInTime(10, StopDanger, true)
    elseif _isenabled then
		StopBusy()
		StopContinuous()
		-- Check if music for season exists
		local season = inst.state.season
		if SEASON_DANGER_MUSIC[season] == nil then
			season = "autumn"
		end
		local x, y, z = player.Transform:GetWorldPosition()
		local epics = TheSim:FindEntities(x, y, z, 30, EPIC_TAGS, NO_EPIC_TAGS)
		local newmusic = #epics > 0
            and ((_innightmare and "music_mod/music/music_epicfight_ruins") or
                (_iscave and "music_mod/music/music_epicfight_cave") or
				(_inlunar and "music_mod/music/music_epicfight_lunar") or
				(_inocean and "music_mod/music/music_epicfight_sailing") or
                (SEASON_EPICFIGHT_MUSIC[season]))
            or ((_innightmare and "music_mod/music/music_danger_ruins") or
                (_iscave and "music_mod/music/music_danger_cave") or
				(_inlunar and "music_mod/music/music_epicfight_lunar") or
				(_inocean and "music_mod/music/music_epicfight_sailing") or
                (SEASON_DANGER_MUSIC[season]))
		if _soundemitter:PlayingSound("danger") then
			_soundemitter:KillSound("danger")
		end
        _soundemitter:PlaySound(newmusic, "danger")
		_lastdangermusic = newmusic
		_soundemitter:SetParameter("danger", "intensity", 1)
        _dangertask = inst:DoTaskInTime(10, StopDanger, true)
        _triggeredlevel = nil
        _extendtime = 0
    end
end

local function StartTriggeredDanger(player, data)
    local level = math.max(1, math.floor(data ~= nil and data.level or 1))
	if _realdangertask ~= nil then
		_realdangertask:Cancel()
		_realdangertask = nil
	end
	print(_triggeredlevel, level)
    if _triggeredlevel == level then
        _extendtime = math.max(_extendtime, GetTime() + (data.duration or 10))
    elseif _isenabled then
        StopContinuous()
		StopBusy()
        StopDanger()
        local musics = data ~= nil and TRIGGERED_DANGER_MUSIC[data.name or "default"] or TRIGGERED_DANGER_MUSIC.default
		if #musics > 0 then
			if _soundemitter:PlayingSound("danger") then
				_soundemitter:KillSound("danger")
			end
			local music = musics[level] or musics[1]
            _soundemitter:PlaySound(music, "danger")
			_lastdangermusic = music
			_soundemitter:SetParameter("danger", "intensity", 1)
        end
        _dangertask = inst:DoTaskInTime(data.duration or 10, StopDanger, true)
        _triggeredlevel = level
        _extendtime = 0
    end
end


local function CheckAction(player)
    if player:HasTag("attack") then
        local target = player.replica.combat:GetTarget()
        if target ~= nil and
            target:HasTag("_combat") and
            not ((target:HasTag("prey") and not target:HasTag("hostile")) or
                target:HasTag("bird") or
                target:HasTag("butterfly") or
                target:HasTag("shadow") or
                target:HasTag("noepicmusic") or
                target:HasTag("thorny") or
                target:HasTag("smashable") or
                target:HasTag("wall") or
                target:HasTag("engineering") or
                target:HasTag("smoldering") or
                target:HasTag("veggie")) then
            if target:HasTag("shadowminion") or target:HasTag("abigail") then
                local follower = target.replica.follower
                if not (follower ~= nil and follower:GetLeader() == player) then
                    StartDanger(player)
                    return
                end
            else
                StartDanger(player)
                return
            end
        end
    end
    if player:HasTag("working") then
        StartBusy()
    end
end

local function OnAttacked(player, data)
    if data ~= nil and
        --For a valid client side check, shadowattacker must be
        --false and not nil, pushed from player_classified
        (data.isattackedbydanger == true or
        --For a valid server side check, attacker must be non-nil
        (data.attacker ~= nil and
        not (data.attacker:HasTag("shadow") or
            data.attacker:HasTag("noepicmusic") or
            data.attacker:HasTag("thorny") or
            data.attacker:HasTag("smolder")))) then
        StartDanger(player)
    end
end

local function OnBlocked(player, data)
	if data ~= nil and
        --For a valid client side check, shadowattacker must be
        --false and not nil, pushed from player_classified
        (data.isattackedbydanger == true or
        --For a valid server side check, attacker must be non-nil
        (data.attacker ~= nil and
        not (data.attacker:HasTag("shadow") or
            data.attacker:HasTag("noepicmusic") or
            data.attacker:HasTag("thorny") or
            data.attacker:HasTag("smolder")))) then
        StartDanger(player)
    end
end

local function OnInsane()
    if _dangertask == nil and _isenabled then
        _soundemitter:PlaySound("music_mod/sanity/gonecrazy_stinger")
        StopContinuous()
        --Repurpose this as a delay before stingers or busy can start again
        _extendtime = GetTime() + 15
		if continuous_mode then
			self.inst:DoTaskInTime(8, function(inst) -- Give the stinger time to play before playing music
				StartBusy()
			end)
		end
    end
end

local function OnEnlightened()
    if _dangertask == nil and _isenabled then
        _soundemitter:PlaySound("music_mod/music/gonecrazy_stinger")
        StopContinuous()
        --Repurpose this as a delay before stingers or busy can start again
        _extendtime = GetTime() + 15
		if continuous_mode then
			self.inst:DoTaskInTime(8, function(inst) -- Give the stinger time to play before playing music
				StartBusy()
			end)
		end
    end
end

local function OnChangeArea(player)
	if player.components.areaaware then
		local nightmare = player.components.areaaware:CurrentlyInTag("Nightmare")
		local lunar = player.components.areaaware:CurrentlyInTag("lunacyarea") --true if lunar, false if mainland, nil if not on land
		local ocean = player.components.areaaware:CurrentlyInTag("not_mainland") --true if lunar, false if mainland, nil if not on land
--		print("Printing: nightmare, lunar, ocean...")
--		print(nightmare)
--		print(lunar)
--		print(ocean)
		if nightmare == true then
			if nightmare ~= _innightmare then
				_innightmare = nightmare
				_isbusydirty = true
				if continuous_mode then
					StartBusy()
				end
			end
		end
		if lunar then
			if lunar ~= _inlunar then
				_inlunar = lunar
				if not _isbusydirty then
					_isbusydirty = true
					if continuous_mode then
--						print("Lunar - StartBusy")
						StartBusy()
					end
				end
			end
		elseif not lunar then
			if lunar ~= _inlunar then
				_inlunar = false
				if not _isbusydirty then
					_isbusydirty = true
					if continuous_mode then
--						print("Not Lunar - StartBusy")
						StartBusy()
					end
				end
			end
		end 	
		if ocean == nil then
			if not lunar then
				if _inocean ~= true then
					_inocean = true
					if not _isbusydirty then
						_isbusydirty = true
						if continuous_mode then
--							print("Ocean is nil, Not Lunar - StartBusy")
							StartBusy()
						end
					end
				end
			end
		elseif ocean ~= nil then
			if _inocean ~= false then
				_inocean = false
				if not _isbusydirty then
					_isbusydirty = true
					if continuous_mode then
--						print("Not Ocean, Not Lunar - StartBusy")
						StartBusy()
					end
				end
			end
		end
	end
end

local function StartPlayerListeners(player)
    inst:ListenForEvent("buildsuccess", StartBusy, player)
    inst:ListenForEvent("gotnewitem", ExtendBusy, player)
    inst:ListenForEvent("performaction", CheckAction, player)
    inst:ListenForEvent("attacked", OnAttacked, player)
	inst:ListenForEvent("blocked", OnBlocked, player)
    inst:ListenForEvent("goinsane", OnInsane, player)
    inst:ListenForEvent("triggeredevent", StartTriggeredDanger, player)
    inst:ListenForEvent("changearea", OnChangeArea, player)
end

local function StopPlayerListeners(player)
    inst:RemoveEventCallback("buildsuccess", StartBusy, player)
    inst:RemoveEventCallback("gotnewitem", ExtendBusy, player)
    inst:RemoveEventCallback("performaction", CheckAction, player)
    inst:RemoveEventCallback("attacked", OnAttacked, player)
	inst:RemoveEventCallback("blocked", OnBlocked, player)
    inst:RemoveEventCallback("goinsane", OnInsane, player)
    inst:RemoveEventCallback("triggeredevent", StartTriggeredDanger, player)
    inst:RemoveEventCallback("changearea", OnChangeArea, player)
end

local function OnPhase(inst, phase)
	_isfullmoon = false -- Is not a full moon by default.
	if phase == "night" and TheWorld.state.isfullmoon then -- If full moon, then _isfullmoon.
		_isfullmoon = true
	end
	
    _isday = phase == "day"
		if _dangertask ~= nil or not _isenabled then
			_isbusydirty = true
			return
		end
    --Don't want to play overlapping stingers
    local time
    if _busytask == nil and _extendtime ~= 0 then
        time = GetTime()
        if time < _extendtime then
			_isbusydirty = true
            return
        end
    end
	if _isday then
		_soundemitter:PlaySound("music_mod/music/music_dawn_stinger")
		if continuous_mode then
			_stingeractive = true
		end
	end
	if phase == "dusk" then
		_soundemitter:PlaySound("music_mod/music/music_dusk_stinger")
		if continuous_mode then
			_stingeractive = true
		end
	end
	
	if phase ~= "night" then 
		self.inst:DoTaskInTime(8, function(inst) -- Give the stinger time to play before changing music
			_isbusydirty = true
			if continuous_mode then
				_stingeractive = false
				StartBusy()
			end
		end)
	else
		self.inst:DoTaskInTime(2, function(inst) -- No stinger. Wait a shorter time.
--			if TheWorld.state.isfullmoon then -- If full moon, then _isfullmoon.
--				_isfullmoon = true
--				print("Is TheWorld.state.isfullmoon?:")
--				print(TheWorld.state.isfullmoon)
--				print("Is _isfullmoon?:")
--				print("_isfullmoon")
--			end	
			_isbusydirty = true
			if continuous_mode then
				StartBusy()
			end
		end)
	end
	StopContinuous()
    --Repurpose this as a delay before stingers or busy can start again
    _extendtime = (time or GetTime()) + 15
end

local function OnSeason()
    _isbusydirty = true
end

local function StartSoundEmitter()
    if _soundemitter == nil then
        _soundemitter = TheFocalPoint.SoundEmitter
        _extendtime = 0
        _isbusydirty = true
        if not _iscave then
            _isday = inst.state.isday
            inst:WatchWorldState("phase", OnPhase)
            inst:WatchWorldState("season", OnSeason)
        end
    end
end

local function StopSoundEmitter()
    if _soundemitter ~= nil then
        StopDanger()
        StopContinuous()
        _soundemitter:KillSound("busy")
        inst:StopWatchingWorldState("phase", OnPhase)
        inst:StopWatchingWorldState("season", OnSeason)
        _isday = nil
        _isbusydirty = nil
        _extendtime = nil
        _soundemitter = nil
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnPlayerActivated(inst, player)
    if _activatedplayer == player then
        return
    elseif _activatedplayer ~= nil and _activatedplayer.entity:IsValid() then
        StopPlayerListeners(_activatedplayer)
    end
    _activatedplayer = player
    StopSoundEmitter()
    StartSoundEmitter()
    StartPlayerListeners(player)
	if continuous_mode then
		StartBusy()
	end
end

local function OnPlayerDeactivated(inst, player)
    StopPlayerListeners(player)
    if player == _activatedplayer then
        _activatedplayer = nil
        StopSoundEmitter()
    end
end

local function OnEnableDynamicMusic(inst, enable)
    if _isenabled ~= enable then
        if not enable and _soundemitter ~= nil then
            StopDanger()
            StopContinuous()
            _soundemitter:KillSound("busy")
            _isbusydirty = true
        end
        _isenabled = enable
    end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Register events
inst:ListenForEvent("playeractivated", OnPlayerActivated)
inst:ListenForEvent("playerdeactivated", OnPlayerDeactivated)
inst:ListenForEvent("enabledynamicmusic", OnEnableDynamicMusic)

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)