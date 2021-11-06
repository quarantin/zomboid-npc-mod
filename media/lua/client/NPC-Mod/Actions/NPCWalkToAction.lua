require "TimedActions/ISBaseTimedAction"

NPCWalkToAction = ISBaseTimedAction:derive("NPCWalkToAction");

function NPCWalkToAction:isValid()
	if self.character:getVehicle() then return false end
    return true;
end

function NPCWalkToAction:update()
    if self.isRun then
        self.character:setRunning(true)
        self.character:setVariable("WalkSpeed", 10);    
    else
        self.character:setVariable("WalkSpeed", 1); 
    end

    self.result = self.character:getPathFindBehavior2():update();

    if self.result == BehaviorResult.Failed then
        NPCPrint("NPCWalkToAction", "Pathfind failed", self.character:getModData().NPC.UUID, self.character:getDescriptor():getSurname()) 
        
        local nearestDoor = self:getNearestDoor(self.character:getX(), self.character:getY(), self.character:getZ())
        local nearestWindow = self:getNearestWindow(self.character:getX(), self.character:getY(), self.character:getZ())

        if nearestDoor and (nearestDoor:isLocked() or nearestDoor:isBarricaded()) then
            if nearestWindow and not nearestWindow:isBarricaded() then
                local sq = self:getSameOutsideSquare(self.character, nearestWindow:getSquare(), nearestWindow:getOppositeSquare()) -- TODO CAN BE ERROR
                self.character:getPathFindBehavior2():pathToLocation(sq:getX(), sq:getY(), sq:getZ())
                if not nearestWindow:isPermaLocked() then
                    if not nearestWindow:IsOpen() then
                        local act = ISOpenCloseWindow:new(self.character, nearestWindow, 100)
                        ISTimedActionQueue.addAfter(self, act)
                        local act3 = ISClimbThroughWindow:new(self.character, nearestWindow, 100)
                        ISTimedActionQueue.addAfter(act, act3)
                    else
                        local act1 = ISClimbThroughWindow:new(self.character, nearestWindow, 100)
                        ISTimedActionQueue.addAfter(self, act1)
                    end
                    return
                else
                    if not nearestWindow:IsOpen() then
                        local act = ISSmashWindow:new(self.character, nearestWindow, 0)
                        ISTimedActionQueue.addAfter(self, act);  
                        local act2 = ISRemoveBrokenGlass:new(self.character, nearestWindow, 100)
                        ISTimedActionQueue.addAfter(act, act2);
                        local act3 = ISClimbThroughWindow:new(self.character, nearestWindow, 20)
                        ISTimedActionQueue.addAfter(act2, act3)
                    else
                        local act1 = ISClimbThroughWindow:new(self.character, nearestWindow, 100)
                        ISTimedActionQueue.addAfter(self, act1)
                    end
                    return
                end            
            end
        end
        
        self.character:getModData().NPC.lastWalkActionFailed = true
        self:forceStop();
        return;
    end

    if self.result == BehaviorResult.Succeeded then
        NPCPrint("NPCWalkToAction", "Pathfind succeeded", self.character:getModData().NPC.UUID, self.character:getDescriptor():getSurname()) 
        self:forceComplete();
    end

    if math.abs(self.lastX - self.character:getX()) > 1 or math.abs(self.lastY - self.character:getY()) > 1 or math.abs(self.lastZ - self.character:getZ()) > 1 then
        self.lastX = self.character:getX();
        self.lastY = self.character:getY();
        self.lastZ = self.character:getZ();
        self.timer = 0
    end
    self.timer = self.timer + 1

    if self.timer == 500 then
        self.character:getModData().NPC.lastWalkActionFailed = true
        self:forceStop()
    end    
end

function NPCWalkToAction:start()
    NPCPrint("NPCWalkToAction", "Calling pathfind method", self.character:getModData().NPC.UUID, self.character:getDescriptor():getSurname()) 
    self.character:getPathFindBehavior2():pathToLocation(self.location:getX(), self.location:getY(), self.location:getZ());
end

function NPCWalkToAction:stop()
    NPCPrint("NPCWalkToAction", "Pathfind cancelled", self.character:getModData().NPC.UUID, self.character:getDescriptor():getSurname()) 
    ISBaseTimedAction.stop(self);
	self.character:getPathFindBehavior2():cancel()
    self.character:setPath2(nil);
end

function NPCWalkToAction:perform()
    NPCPrint("NPCWalkToAction", "Pathfind complete", self.character:getModData().NPC.UUID, self.character:getDescriptor():getSurname()) 
	self.character:getPathFindBehavior2():cancel()
    self.character:setPath2(nil);

    ISBaseTimedAction.perform(self);

    if self.onCompleteFunc then
        local args = self.onCompleteArgs
        self.onCompleteFunc(args[1], args[2], args[3], args[4])
    end
end

function NPCWalkToAction:setOnComplete(func, arg1, arg2, arg3, arg4)
    self.onCompleteFunc = func
    self.onCompleteArgs = { arg1, arg2, arg3, arg4 }
end


function NPCWalkToAction:new (character, location, isRun)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;

    o.stopOnWalk = false;
    o.stopOnRun = false;
    o.maxTime = -1;
    o.location = location;
    o.pathIndex = 0;

    o.isRun = isRun

    o.lastX = character:getX();
    o.lastY = character:getY();
    o.lastZ = character:getZ();
    o.timer = 0

    return o
end


function NPCWalkToAction:getNearestDoor(x, y, z)
    local result = nil
	local dist = 9999
    for i = -10, 10 do
		for j = -10, 10 do
			local sq = getSquare(x + i, y + j, z)
			if sq and NPCUtils:getDoor(sq) ~= nil then
				local d = NPCUtils.getDistanceBetween(sq, getSquare(x, y, z))
				if d < dist then
					result = NPCUtils:getDoor(sq)
					dist = d
				end
			end
		end
	end
	return result
end

function NPCWalkToAction:getNearestWindow(x, y, z)
    local result = nil
	local dist = 9999
    for i = -10, 10 do
		for j = -10, 10 do
			local sq = getSquare(x + i, y + j, z)
			if sq and sq:getWindow() ~= nil then
				local d = NPCUtils.getDistanceBetween(sq, getSquare(x, y, z))
				if d < dist then
					result = sq:getWindow()
					dist = d
				end
			end
		end
	end
	return result
end

function NPCWalkToAction:getSameOutsideSquare(char, sq1, sq2)
    local charSq = char:getSquare()

    if charSq:isOutside() then
        if sq1:isOutside() then
            return sq1
        else
            return sq2
        end
    else
        if not sq1:isOutside() then
            return sq1
        else
            return sq2
        end
    end
end