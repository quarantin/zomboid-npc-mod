ReputationSystem = {}
ReputationSystem.__index = ReputationSystem

function ReputationSystem:new(character, preset)
	local o = {}
	setmetatable(o, self)
	self.__index = self

    o.character = character

    o.reputationList = {}
    o.playerRep = preset.defaultReputation
    o.defaultReputation = preset.defaultReputation

    return o
end

function ReputationSystem:getNPCRep(npc)
    if self.character:getModData().NPC.groupID ~= nil then
        if self.character:getModData().NPC.isLeader then
            if npc.groupID == self.character:getModData().NPC.groupID then
                return 1000
            else
                if self.reputationList[npc.ID] == nil then
                    return self.defaultReputation
                else
                    return self.reputationList[npc.ID]
                end
            end
        else
            return NPCGroupManager:getLeaderOfGroup(self.character:getModData().NPC.groupID).reputationSystem:getNPCRep(npc)
        end
    else
        if npc.AI:getType() == "PlayerGroupAI" and self.character:getModData().NPC.AI:getType() == "PlayerGroupAI" then
            return 1000
        end

        if self.reputationList[npc.ID] == nil then
            return self.defaultReputation
        else
            return self.reputationList[npc.ID]
        end
    end
end

function ReputationSystem:getPlayerRep()
    if self.character:getModData().NPC.groupID ~= nil then
        if self.character:getModData().NPC.isLeader then
            return self.playerRep
        else
            return NPCGroupManager:getLeaderOfGroup(self.character:getModData().NPC.groupID).reputationSystem:getPlayerRep()
        end
    else
        if self.character:getModData().NPC.AI:getType() == "PlayerGroupAI" then
            return 1000
        else
            return self.playerRep
        end
    end
end


