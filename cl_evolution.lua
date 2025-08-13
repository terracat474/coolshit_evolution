local function hasLOS(ply, ent)
    local tr = util.TraceLine({
        start = ply:EyePos(),
        endpos = ent:EyePos(),
        filter = function(e)
            return e ~= ply
        end
    })
    return tr.Entity == ent
end

--local function npcgetevolution(npc)
--
--end

local tier1 = Material("icon16/award_star_bronze_1.png")
local tier2 = Material("icon16/award_star_silver_1.png")
local tier3 = Material("icon16/award_star_gold_1.png")

hook.Add("HUDPaint", "NPCHeadIcons", function()
    for _, npc in ipairs(ents.FindByClass("npc_*")) do
        if IsValid(npc) and npc:GetNWInt("EvolveTier") != 0 then
            local tier = npc:GetNWInt("EvolveTier")

            local height = 0
            if tier == 1 then
                height = 70
            elseif tier == 2 then
                height = 70
            elseif tier == 3 then
                height = 170
            end
            local headPos = npc:GetPos() + Vector(0, 0, height + 15 * tier)
            
            local screenPos = headPos:ToScreen()
            
            if screenPos.visible then
                -- Size settings
                local iconSize = 32
                local pulse = math.sin(CurTime() * 3) * 5  -- Pulsing effect
                local currentSize = iconSize + pulse
                
                -- Draw icon
                if tier == 1 then
                    surface.SetMaterial(tier1)
                elseif tier == 2 then
                    surface.SetMaterial(tier2)
                elseif tier == 3 then
                    surface.SetMaterial(tier3)
                end
                surface.SetDrawColor(255, 255, 255, 200)  -- White with transparency
                surface.DrawTexturedRect(
                    screenPos.x - currentSize/2, 
                    screenPos.y - currentSize/2,
                    currentSize,
                    currentSize
                )
            end
        end
    end
end)