local thcd = CurTime() + 1

local function checkdist(targ1, targ2, dist)
    local distsqr = dist*dist
    if IsValid(targ1) and IsValid(targ2) then
        local pos = targ1:GetPos():DistToSqr(targ2:GetPos())
        return pos < distsqr
    end
end

local function stompDamage(npc, radius, damage, damageType)
    local pos = npc:GetPos()
    local damageInfo = DamageInfo()
    
    damageInfo:SetAttacker(npc)
    damageInfo:SetInflictor(npc)
    damageInfo:SetDamageType(damageType or DMG_GENERIC)
    damageInfo:SetDamage(damage)
    
    -- Create blast damage effect
    util.BlastDamageInfo(damageInfo, pos, radius)
    
    -- Optional: Add physics force
    util.ScreenShake(pos, 5, 5, 1, radius)
    
    -- Optional: Visual effect
    local vPoint = npc:GetPos() + Vector(math.random(-20, 20), math.random(-20, 20), 20)
    local effectdata = EffectData()
    effectdata:SetOrigin(vPoint)
    effectdata:SetScale(100)
    effectdata:SetEntity(npc)
    util.Effect( "ThumperDust", effectdata )
    npc:EmitSound("ambient/machines/thumper_hit.wav")
end

local function evo3stomp(npc)
    npc:SetSaveValue("m_flNextDecisionTime", 1)
    npc:ResetSequence("tantrum")

    timer.Simple(0.5, function()
        if IsValid(npc) then
            stompDamage(npc, 200, 60, DMG_SONIC)
        end
    end)
end

local function evolve(npc)
    if npc.EvolveTier == nil then       --zombie evo tree
        npc.EvolveTier = 1 --tier 1
        npc:SetNWInt("EvolveTier", npc.EvolveTier)

        npc:SetModelScale(npc:GetModelScale() * 1.25, 1)
        npc:SetColor(Color(241, 245, 10))
        npc:SetHealth(npc:GetMaxHealth() * 1.25)
    else
        if npc.Kills > 3 and npc.EvolveTier == 1 then
            npc.EvolveTier = 2 --tier 2 evo
            npc:SetNWInt("EvolveTier", npc.EvolveTier)

            --npc:SetModelScale(npc:GetModelScale() * 2, 1)
            npc:SetColor(Color(29, 232, 19))
            npc:SetHealth(npc:GetMaxHealth() * 3)

            timer.Create("EffectTimerEvo2_"..npc:EntIndex(), 2, 0, function()
                if IsValid(npc) then
                    local vPoint = npc:GetPos() + Vector(0, 0, npc:BoundingRadius()/2)
                    local effectdata = EffectData()
                    effectdata:SetOrigin(vPoint)
                    effectdata:SetScale(6)
                    effectdata:SetEntity(npc)
                    util.Effect( "HL1Gib", effectdata )
                else
                    timer.Remove("EffectTimerEvo2_"..npc:EntIndex())
                end
            end)
        elseif npc.Kills > 6 and npc.EvolveTier == 2 then
            npc.EvolveTier = 3 --tier 3 evo
            npc:SetNWInt("EvolveTier", npc.EvolveTier)

            npc:SetModelScale(npc:GetModelScale() * 1.25, 1)
            npc:SetColor(Color(232, 0, 19))
            npc:SetHealth(npc:GetMaxHealth() * 7)

            timer.Remove("EffectTimerEvo2_"..npc:EntIndex())
        end
    end
    if npc.Kills == nil then
        npc.Kills = 1
    else
        npc.Kills = npc.Kills + 1
    end
end

local function checkBlacklist(whatever)
    local blacklisted = false
    if string.find(whatever, "crab") then
        blacklisted = true
    end
    if string.find(whatever, "zombie") then
        blacklisted = true
    end
    if string.find(whatever, "zombine") then
        blacklisted = true
    end
    return blacklisted
end

local function checkStomps(npc)
    local cunts = ents.FindByClass("npc_*")
    for k, v in ipairs(cunts) do
        if v:IsNPC() and !checkBlacklist(v:GetClass()) then
            if checkdist(npc, v, 200) and v:EntIndex() != npc:EntIndex() then
                evo3stomp(npc)
            end
        end
    end
end

hook.Add("Think", "stompscheck", function()
    local meow = ents.GetAll()
    if CurTime() >= thcd then
        for k,v in ipairs(meow) do
            if v:IsNPC() and v.EvolveTier == 3 then
                checkStomps(v)
            end
        end
        thcd = CurTime() + 1
    end
end)

--self-explanatory bro
local function explodeInViscera(pos, scale)
    local effects = {"HL1Gib", "bloodspray", "BloodImpact"}
    for i = 1, 4 do
        local vPoint = pos + Vector(math.Rand(-15, 15), math.Rand(-15, 15), 70)
        local effectdata = EffectData()
        effectdata:SetOrigin(vPoint)
        effectdata:SetScale(scale)
        util.Effect(table.Random(effects), effectdata )
    end
    EmitSound("physics/flesh/flesh_squishy_impact_hard"..math.random(1,4)..".wav", pos, 1, CHAN_AUTO, 1, 120, 0, 100 )
end
--kills give more kills for npcs
hook.Add( "OnNPCKilled", "evolvebrah", function( npc, attacker, inflictor )
    if string.find(attacker:GetClass(), "zombie") or string.find(attacker:GetClass(), "zombine") then
        evolve(attacker)
    end
    --so they dont ragdoll and just... self-explanatory
    if npc.EvolveTier and npc.EvolveTier >= 2 then
        local pos = npc:GetPos()
        npc:Remove()
        explodeInViscera(pos, npc.EvolveTier * 20)
    end
end)
--zombifications give kills
--hook.Add("headcrabtakeovershouldntzombine", "evolveheadcrabtakeover", function(victim, infector)
--    if string.find(infector:GetClass(), "zombie") or string.find(infector:GetClass(), "zombine") then
--        evolve(infector)
--    end
--    if infector.EvolveTier == 3 then
--        return true
--    end
--    return false
--end)
--stomps dont zombify with headcrabtakeover
hook.Add("headcrabtakeoverbeforecreatezombiehook", "evolveheadcrabtakeover", function(target, damage)
    local infector = damage:GetAttacker()
    if string.find(infector:GetClass(), "zombie") or string.find(infector:GetClass(), "zombine") then
        evolve(infector)
    end

    if infector.EvolveTier == 3 then
        return false
    end
end)
--apply effects for testing
concommand.Add("terra_applyeffect", function( ply, cmd, args, argStr )
    local uc = ply:GetEyeTrace().HitPos
    local npc = ply:GetEyeTrace().Entity
    if argStr == nil then
        print("[terra] Provide an effect name!")
    else
        local vPoint = uc
        local effectdata = EffectData()
        effectdata:SetOrigin(vPoint)
        effectdata:SetFlags(3)
        effectdata:SetScale(10)
        effectdata:SetMagnitude(10)
        if npc != nil then
            effectdata:SetEntity(npc)
        end
        timer.Simple(1.5, function() util.Effect( argStr, effectdata ) end)
    end
end)
--evolve for testing
--concommand.Add("terra_evolvenpctest", function( ply, cmd, args, argStr )
--    local uc = ply:GetEyeTrace().Entity
--    if uc:IsNPC() then
--        evolve(uc)
--        uc.Kills = uc.Kills + 1
--    end           --these are for testing, u can enable these
--end)
----getheight
--concommand.Add("terra_getheight", function( ply, cmd, args, argStr )
--    local uc = ply:GetEyeTrace().Entity
--    if uc:IsNPC() then
--        print(uc:BoundingRadius())
--    end
--end)