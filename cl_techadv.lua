local corporal = Material("icon16/bullet_green.png")
local sergeant = Material("icon16/bullet_blue.png")
local lieutenant = Material("icon16/bullet_orange.png")
local major = Material("icon16/bullet_red.png")
local general = Material("icon16/bullet_purple.png")

hook.Add("HUDPaint", "NPCCoolIcons", function()
    for _, npc in ipairs(ents.FindByClass("npc_*")) do
        if IsValid(npc) and npc:GetNWInt("RankTier") != 0 then
            local tier = npc:GetNWInt("RankTier")
            local rankname = ""

            local height = 80

            local headPos = npc:GetPos() + Vector(0, 0, height)
            
            local screenPos = headPos:ToScreen()
            
            if screenPos.visible then
                -- Size settings
                local iconSize = 32
                local pulse = math.sin(CurTime() * 3) * 5  -- Pulsing effect
                local currentSize = iconSize + pulse
                
                -- Draw icon
                if tier == 1 then
                    surface.SetMaterial(corporal)
                    rankname = "corporal"
                elseif tier == 2 then
                    surface.SetMaterial(sergeant)
                    rankname = "sergeant"
                elseif tier == 3 then
                    surface.SetMaterial(lieutenant)
                    rankname = "lieutenant"
                elseif tier == 4 then
                    surface.SetMaterial(major)
                    rankname = "major"
                elseif tier == 5 then
                    surface.SetMaterial(general)
                    rankname = "general"
                end

                surface.SetDrawColor(255, 255, 255, 200)  -- White with transparency
                surface.DrawTexturedRect(
                    screenPos.x - currentSize/2, 
                    screenPos.y - currentSize/2,
                    currentSize,
                    currentSize
                )
                surface.SetTextColor( 255, 255, 255 )
                surface.SetFont("BudgetLabel")
	            surface.SetTextPos(screenPos.x, screenPos.y) 
	            surface.DrawText(rankname)
            end
        end
    end
end)