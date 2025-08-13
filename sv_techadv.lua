local function checkdist(targ1, targ2, dist)
    local distsqr = dist*dist
    if IsValid(targ1) and IsValid(targ2) then
        local pos = targ1:GetPos():DistToSqr(targ2:GetPos()) --utility function
        return pos < distsqr
    end
end

local function promoteSoldier(npc)
    if npc.RankTier == nil then -- promotions
        npc.RankTier = 1    --rank 1: 50% chance to get zombified from headcrab takeover attacks. (Down from 100%). That's it.
        npc:SetNWInt("RankTier", npc.RankTier)
        npc:SetColor(Color(0, 138, 5))
    else
        if npc.Kills >= 3 and npc.RankTier == 1 then
            npc.RankTier = 2
            npc:SetNWInt("RankTier", npc.RankTier)  --rank 2: guaranteed AR2 and zombification immunity. Moar hp and 25% more damage

            npc:SetColor(Color(0, 0, 199))
            npc:SetHealth(npc:GetMaxHealth() * 1.5)
            npc:Give("weapon_ar2")
        elseif npc.Kills >= 5 and npc.RankTier == 2 then
            npc.RankTier = 3
            npc:SetNWInt("RankTier", npc.RankTier)  --rank 3: manhack ability: deploy manhacks. cooldown 30 seconds. 
                                                    
            npc:SetColor(Color(209, 96, 4))            --heal allies ability: every nearby ally gets healz. cooldown 45s
            npc.HealCD = CurTime()
            npc.ManhackCD = CurTime()
        elseif npc.Kills >= 7 and npc.RankTier == 3 then
            npc.RankTier = 4
            npc:SetNWInt("RankTier", npc.RankTier)       --rank 4: summon reinforcements ability: 4 dudes visualize nearby. cooldown 1 min. moar hp

            npc:SetColor(Color(209, 0, 0))            --shield ability: 50% less damage for 10 seconds. cooldown 1 min
            npc:SetHealth(npc:GetMaxHealth() * 1.75)
            npc.ReinforceCD = CurTime()
            npc.ShieldCD = CurTime()
        elseif npc.Kills >= 10 and npc.RankTier == 4 then    --rank 5: megaguy. he's the coolest of em all!
            npc.RankTier = 5
            npc:SetNWInt("RankTier", npc.RankTier)  --MOAR hp. ehhh

            npc:SetColor(Color(140, 5, 237))
            npc:SetHealth(npc:GetMaxHealth() * 2)                        
        end
    end
    if npc.Kills == nil then -- kill credits
        npc.Kills = 1 
    else
        npc.Kills = npc.Kills + 1 
    end
end

local function healAbility(user)
    user:SetSaveValue("m_flNextDecisionTime", 1)
    user:ResetSequence("Signal_Halt")

    local healed = {}
    local meow = ents.GetAll()
    for k,v in ipairs(meow) do
        if v:IsNPC() and v:Classify() == CLASS_COMBINE and checkdist(v, user, 70) and v.ToBeHealed == nil then
            v.ToBeHealed = true
            table.insert(healed, v)
            print(v:EntIndex())
        end
    end
    table.insert(healed, user)
    timer.Simple(1.5, function()
        for k,v in ipairs(healed) do
            v:SetHealth(math.Round(v:Health() + v:GetMaxHealth()/3))
            local vPoint = v:GetPos()
            local effectdata = EffectData()
            effectdata:SetOrigin(vPoint)
            util.Effect( "VortDispel", effectdata )
            v.ToBeHealed = nil
            table.remove(healed, k)
        end
    end)

    user.HealCD = CurTime() + 45
end

local function manhackAbility(user)
    user:SetSaveValue("m_flNextDecisionTime", 1)
    user:ResetSequence("Signal_Advance")

    --print(user:GetForward()*10)

    local manhack = ents.Create("npc_manhack")
    manhack:SetPos(user:GetPos() + Vector(0, 0, user:BoundingRadius() + 45))
    timer.Simple(1, function() manhack:Spawn() end)

    user.ManhackCD = CurTime() + 30
end

local function shieldAbility(user)
    user:SetSaveValue("m_flNextDecisionTime", 1)
    user:ResetSequence("Signal_Group")
    
    user:SetHealth(user:Health() * 1.5)
    user:SetMaterial("models/props_combine/com_shield001a")
    timer.Simple(10, function() 
        user:SetHealth(user:Health() * 0.5)
        user:SetMaterial("")
    end)

    user.ShieldCD = CurTime() + 60
end

local function reinforceAbility(user)
    local userpos = user:GetPos()

    print(user:GetRight())
    print(user:GetForward())
    user:SetSaveValue("m_flNextDecisionTime", 1)
    user:ResetSequence("Signal_Takecover")

    for i = 1,4 do
        local newpos = userpos

        if i == 1 then
            newpos = newpos + Vector(user:GetForward() * 40)
        elseif i == 2 then
            newpos = newpos + Vector(user:GetForward() * -40)
        elseif i == 3 then
            newpos = newpos + Vector(user:GetRight() * 40)
        elseif i == 4 then
            newpos = newpos + Vector(user:GetRight() * -40)
        end

        local newguy = ents.Create("npc_combine_s")
        newguy:SetPos(newpos)
        newguy:Spawn()

        --local effectdata = EffectData()
        --effectdata:SetOrigin(newpos)
        --effectdata:SetEntity(newguy)
        --timer.Simple(1.5, function() util.Effect( "phys_freeze", effectdata ) end)
    end

    user.ReinforceCD = CurTime() + 60
end

hook.Add("Think", "ThinkOfTheAbilities", function()
    local cunts = ents.FindByClass("npc_*")
    for k,v in ipairs(cunts) do
        if IsValid(v) and v.RankTier and v.RankTier >= 3 then
            if v:GetEnemy() != nil and v.ManhackCD < CurTime() then
                if math.random(1, 100) >= 33 then
                    manhackAbility(v)
                end
                if v.ReinforceCD and v.ReinforceCD < CurTime() then
                    reinforceAbility(v)
                end
            end
            if v.HealCD < CurTime() then
                healAbility(v)
            end
        end
    end
end)

hook.Add( "OnNPCKilled", "promotionsyay", function( npc, attacker, inflictor )
    if string.find(attacker:GetClass(), "combine") then
        promoteSoldier(attacker)
    end
end)

hook.Add("headcrabtakeoverbeforecreatezombiehook", "thinkofthecombines", function(target, damage)
    if target.RankTier != nil and target.RankTier >= 2 then
        return false
    elseif target.RankTier != nil and target.RankTier == 1 then
        local prob = math.random(1, 10)
        if prob >= 5 then
            return false
        else
            return true
        end
    end
end)

hook.Add( "EntityTakeDamage", "EntityDamageExample", function( target, dmginfo )
    local attacker = dmginfo:GetAttacker()
	if (target:IsNPC() and target:Classify() != CLASS_COMBINE and attacker:IsNPC() and attacker:Classify() == CLASS_COMBINE and attacker.RankTier and attacker.RankTier >= 2) then
        if attacker.RankTier == 5 then
		    dmginfo:ScaleDamage(2)
        else
            dmginfo:ScaleDamage(1.25)
        end
	end
    if target:IsNPC() and target:Classify() == CLASS_COMBINE and target.RankTier and target.RankTier >= 4 then
        if math.random(1, 100) >= 85 then
            shieldAbility(target)
        end
    end
end)

concommand.Add("terra_promoteguytest", function( ply, cmd, args, argStr )
    local uc = ply:GetEyeTrace().Entity
    if uc:IsNPC() then
        promoteSoldier(uc)
        uc.Kills = uc.Kills + 1
    end
end)

concommand.Add("terra_useabiltest", function( ply, cmd, args, argStr )
    local uc = ply:GetEyeTrace().Entity
    if uc:IsNPC() then
        if argStr == "heal" then
            healAbility(uc)
        elseif argStr == "manhack" then
            manhackAbility(uc)
        elseif argStr == "shield" then
            shieldAbility(uc)
        elseif argStr == "reinforce" then
            reinforceAbility(uc)
        end
    end
end)