FindItemsTask = {}
FindItemsTask.__index = FindItemsTask

function FindItemsTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "FindItems"
	o.complete = false

    o:updateItemLocation()
	return o
end

function FindItemsTask:updateItemLocation()
    self.character:getModData()["NPC"].AI:findNearbyItems()

    self.itemSquares, self.squaresCount = self.character:getModData()["NPC"]:getItemsSquareInNearbyItems(function(item)
        if self.character:getModData()["NPC"].AI.findItems.Food and NPCUtils:evalIsFood(item) then
            return true
        end          
    
        if self.character:getModData()["NPC"].AI.findItems.Weapon and NPCUtils:evalIsWeapon(item) then
            return true
        end  
    
        if self.character:getModData()["NPC"].AI.findItems.Clothing and NPCUtils:evalIsClothing(item) then
            return true
        end  
    
        if self.character:getModData()["NPC"].AI.findItems.Meds and NPCUtils:evalIsMeds(item) then
            return true
        end  
    
        if self.character:getModData()["NPC"].AI.findItems.Bags and NPCUtils:evalIsBags(item) then
            return true
        end  
    
        if self.character:getModData()["NPC"].AI.findItems.Melee and NPCUtils:evalIsMelee(item) then
            return true
        end  
    
        if self.character:getModData()["NPC"].AI.findItems.Literature and NPCUtils:evalIsLiterature(item) then
            return true
        end  
    
        return false
    end)

    self.sqPath = {}
    table.insert(self.sqPath, self.character:getSquare())
    local count = 1

    for i=1, self.squaresCount+1 do
        local dist = 999
        for sq, _ in pairs(self.itemSquares) do
            local d = NPCUtils.getDistanceBetween(sq, self.sqPath[count])
            if sq:getZ() ~= self.sqPath[count]:getZ() then
                d = d + 30
            end
            if self.character:getModData()["NPC"].AI.TaskArgs.FIND_ITEMS_WHERE == "NEAR" then
                if NPCUtils.getDistanceBetween(sq, self.mainPlayer) < 4 and self.mainPlayer:getZ() == sq:getZ() then
                    dist = d
                    self.sqPath[count+1] = sq
                    count = count + 1
                end    
            else
                if d < dist then
                    dist = d
                    self.sqPath[count+1] = sq
                    count = count + 1
                end
            end
        end
        self.itemSquares[self.sqPath[count]] = nil
    end

    self.nextPoint = 2
end

function FindItemsTask:isComplete()
	return self.complete
end

function FindItemsTask:stop()
end

function FindItemsTask:isValid()
    return self.character ~= nil
end

function FindItemsTask:update()
    if not self:isValid() then return false end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if self.character:getModData().NPC.lastWalkActionForceStopped then
        self.nextPoint = self.nextPoint + 1
        self.character:getModData().NPC.lastWalkActionForceStopped = false
    end

    if actionCount == 0 then
        if self.sqPath[self.nextPoint] == nil then
            if self.character:getModData()["NPC"].AI.TaskArgs.FIND_ITEMS_WHERE == "NEAR" then
                if NPCUtils.getDistanceBetween(self.character, self.mainPlayer) >= 4 then 
                    local goalSquare = NPCUtils.AdjacentFreeTileFinder_Find(self.mainPlayer:getSquare()) 
		            ISTimedActionQueue.add(NPCWalkToAction:new(self.character, goalSquare, false))
                end
                self:updateItemLocation()
                return true
            end
            if self.character:getModData().NPC.AI:getType() == "AutonomousAI" then
                self.complete = true
                local newRoomID = NPC_InterestPointMap:getNearestNewRoom(self.character:getX(), self.character:getY(), self.character:getModData().NPC.visitedRooms)
                if NPCUtils.getDistanceBetweenXYZ(self.character:getX(), self.character:getY(), NPC_InterestPointMap.Rooms[newRoomID].x, NPC_InterestPointMap.Rooms[newRoomID].y) < 50 then
                    self.character:getModData().NPC.visitedRooms[newRoomID] = true
                    self.character:getModData().NPC.AI.checkInterestPoint = false     
                end
            end
            return false
        end

        if self.sqPath[self.nextPoint] ~= nil then
            local items = self.character:getModData().NPC:getItemsInSquare(function(item)
                if self.character:getModData()["NPC"].AI.findItems.Food and NPCUtils:evalIsFood(item) then
                    return true
                end          
            
                if self.character:getModData()["NPC"].AI.findItems.Weapon and NPCUtils:evalIsWeapon(item) then
                    return true
                end  
            
                if self.character:getModData()["NPC"].AI.findItems.Clothing and NPCUtils:evalIsClothing(item) then
                    return true
                end  
            
                if self.character:getModData()["NPC"].AI.findItems.Meds and NPCUtils:evalIsMeds(item) then
                    return true
                end  
            
                if self.character:getModData()["NPC"].AI.findItems.Bags and NPCUtils:evalIsBags(item) then
                    return true
                end  
            
                if self.character:getModData()["NPC"].AI.findItems.Melee and NPCUtils:evalIsMelee(item) then
                    return true
                end  
            
                if self.character:getModData()["NPC"].AI.findItems.Literature and NPCUtils:evalIsLiterature(item) then
                    return true
                end  
            
                return false
            end, 
            self.sqPath[self.nextPoint])

            for i=1, #items do
                if items[i]:getWorldItem() then
                    ISTimedActionQueue.add(NPCWalkToAction:new(self.character, self.sqPath[self.nextPoint], false))
                    ISTimedActionQueue.add(ISGrabItemAction:new(self.character, items[i]:getWorldItem(), ISWorldObjectContextMenu.grabItemTime(self.character, items[i]:getWorldItem())))
                else
                    local sq = NPCUtils.getNearestFreeSquare(self.character, self.sqPath[self.nextPoint], NPCUtils.isInRoom(self.sqPath[self.nextPoint] ))
                    if sq ~= nil then
                        if NPCUtils.getDistanceBetween(sq, self.character) > 1 then
                            ISTimedActionQueue.add(NPCWalkToAction:new(self.character, sq, false))            
                        end
                    end
                    ISTimedActionQueue.add(ISInventoryTransferAction:new(self.character, items[i], items[i]:getContainer(), self.character:getInventory()))
                end
            end

            self.nextPoint = self.nextPoint + 1
        end
    end

    return true
end