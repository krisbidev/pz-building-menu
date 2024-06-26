---@class ISThreeTileGarageDoor: ISBuildingObject
ISThreeTileGarageDoor = ISBuildingObject:derive("ISThreeTileGarageDoor")

--- Constructor for creating a new three-tile garage door instance
--- @param sprite string Main sprite for the garage door
--- @param sprite2 string Sprite for the second tile
--- @param sprite3 string Sprite for the third tile
--- @param northSprite string North-facing sprite for the main tile
--- @param northSprite2 string North-facing sprite for the second tile
--- @param northSprite3 string North-facing sprite for the third tile
--- @return ISThreeTileGarageDoor ISBuildingObject instance
function ISThreeTileGarageDoor:new(sprite, sprite2, sprite3, northSprite, northSprite2, northSprite3)
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    o:init();
    o:setSprite(sprite);

    o.sprite2 = sprite2;
    o.sprite3 = sprite3;

    o.northSprite = northSprite;
    o.northSprite2 = northSprite2;
    o.northSprite3 = northSprite3;

    o.consumedItems = {};
    o.isDoor = true;
    o.thumpDmg = 5;
    o.name = "Garage Door";
    return o;
end

--- Creates and adds parts of the garage door to the game world
--- @param x number x coordinate in the world
--- @param y number y coordinate in the world
--- @param z number z coordinate (floor level)
--- @param north boolean Indicates if the door is facing north
--- @param sprite string The sprite to use for the main part of the door
function ISThreeTileGarageDoor:create(x, y, z, north, sprite)
    local cell = getWorld():getCell();
    local square = cell:getGridSquare(x, y, z);
    local xa, ya = self:getSquare2Pos(square, north);
    local xb, yb = self:getSquare3Pos(square, north);
    local spriteAName = self.sprite2;
    local spriteBName = self.sprite3;

    if self.north then
        spriteAName = self.northSprite2;
        spriteBName = self.northSprite3;
    end

    self:addDoorPart(x, y, z, north, sprite, 1);
    self:addDoorPart(xa, ya, z, north, spriteAName, 2);
    self:addDoorPart(xb, yb, z, north, spriteBName, 3);
end

--- Adds a door part to the specified location
--- @param x number x coordinate in the world
--- @param y number y coordinate in the world
--- @param z number z coordinate (floor level)
--- @param north boolean Indicates if the door is facing north
--- @param sprite string The sprite for this door part
--- @param index number The index of the door part (1, 2, or 3)
function ISThreeTileGarageDoor:addDoorPart(x, y, z, north, sprite, index)
    local cell = getWorld():getCell();
    self.sq = cell:getGridSquare(x, y, z);

    if self:partExists(self.sq, index) then return; end

    self.javaObject = IsoDoor.new(cell, self.sq, sprite, north);
    self.javaObject:setHealth(self:getHealth());

    if index == 1 then
        self.consumedItems = buildUtil.consumeMaterial(self);
    end

    for _, item in ipairs(self.consumedItems) do
        if item:getType() == "Doorknob" and item:getKeyId() ~= -1 then
            self.javaObject:setKeyId(item:getKeyId());
        end
    end

    self.sq:AddSpecialObject(self.javaObject);
    self.javaObject:transmitCompleteItemToServer();
end

--- Returns the health of the garage door based on construction parameters
--- @return number health The health value of the door
function ISThreeTileGarageDoor:getHealth()
    return 500 + buildUtil.getWoodHealth(self);
end

--- Validates if the garage door can be placed on the specified square
--- @param square IsoGridSquare The square to validate for placement
--- @return boolean validity Returns true if the door can be placed, otherwise false
function ISThreeTileGarageDoor:isValid(square)
    if not self:haveMaterial(square) then
        return false;
    end
    if not square:hasFloor(self.north) then
        return false;
    end
    if not self:partExists(square, 1) and not square:isFreeOrMidair(false) then
        return false;
    end
    if square:isVehicleIntersecting() then
        return false;
    end

    local xa, ya = self:getSquare2Pos(square, self.north);
    local xb, yb = self:getSquare3Pos(square, self.north);
    local squareA = getCell():getGridSquare(xa, ya, square:getZ());
    local squareB = getCell():getGridSquare(xb, yb, square:getZ());

    if (not squareA) or (not squareB) then
        return false;
    end

    local existsA = self:partExists(squareA, 2);
    local existsB = self:partExists(squareB, 3);

    if not existsA and not buildUtil.canBePlace(self, squareA) then
        return false;
    end
    if not existsB and not buildUtil.canBePlace(self, squareB) then
        return false;
    end

    if squareA:isSomethingTo(square) then
        return false;
    end
    if squareB:isSomethingTo(squareA) then
        return false;
    end

    if buildUtil.stairIsBlockingPlacement(square, true, self.north) then
        return false;
    end
    if buildUtil.stairIsBlockingPlacement(squareA, true, self.north) then
        return false;
    end
    if buildUtil.stairIsBlockingPlacement(squareB, true, self.north) then
        return false;
    end

    return true;
end

--- Renders a ghost tile of the garage door for placement preview
--- @param x number x coordinate in the world
--- @param y number y coordinate in the world
--- @param z number z coordinate (floor level)
--- @param square IsoGridSquare The square where the garage door will be placed
function ISThreeTileGarageDoor:render(x, y, z, square)
    local spriteName;
    if not self:partExists(square, 1) then
        spriteName = self:getSprite();
        local sprite = IsoSprite.new();
        sprite:LoadFramesNoDirPageSimple(spriteName);

        local spriteFree = ISBuildingObject.isValid(self, square);
        if buildUtil.stairIsBlockingPlacement(square, true, self.north) then
            spriteFree = false;
        end
        if spriteFree then
            sprite:RenderGhostTile(x, y, z);
        else
            sprite:RenderGhostTileRed(x, y, z);
        end
    end

    local spriteAName = self.sprite2;
    local spriteBName = self.sprite3;

    local spriteAFree = true;
    local spriteBFree = true;

    local xa, ya = self:getSquare2Pos(square, self.north);
    local xb, yb = self:getSquare3Pos(square, self.north);

    if self.north then
        spriteName = self.northSprite;
        spriteAName = self.northSprite2;
        spriteBName = self.northSprite3;
    end

    local squareA = getCell():getGridSquare(xa, ya, z)
    if squareA == nil and getWorld():isValidSquare(xa, ya, z) then
        squareA = IsoGridSquare.new(getCell(), nil, xa, ya, z);
        getCell():ConnectNewSquare(squareA, false);
    end

    local squareB = getCell():getGridSquare(xb, yb, z)
    if squareB == nil and getWorld():isValidSquare(xb, yb, z) then
        squareB = IsoGridSquare.new(getCell(), nil, xb, yb, z);
        getCell():ConnectNewSquare(squareB, false);
    end

    local existsA = self:partExists(squareA, 2);
    local existsB = self:partExists(squareB, 3);

    if not existsA and not buildUtil.canBePlace(self, squareA) then
        spriteAFree = false;
    end
    if not existsB and not buildUtil.canBePlace(self, squareB) then
        spriteBFree = false;
    end

    if squareA and (squareA:isSomethingTo(square) or buildUtil.stairIsBlockingPlacement(squareA, true, self.north)) then
        spriteAFree = false;
    end
    if squareB and (squareB:isSomethingTo(squareA) or buildUtil.stairIsBlockingPlacement(squareB, true, self.north)) then
        spriteBFree = false;
    end

    if not existsA then
        local spriteA = IsoSprite.new();
        spriteA:LoadFramesNoDirPageSimple(spriteAName);
        if spriteAFree then
            spriteA:RenderGhostTile(xa, ya, z);
        else
            spriteA:RenderGhostTileRed(xa, ya, z);
        end
    end
    if not existsB then
        local spriteB = IsoSprite.new();
        spriteB:LoadFramesNoDirPageSimple(spriteBName);
        if spriteBFree then
            spriteB:RenderGhostTile(xb, yb, z);
        else
            spriteB:RenderGhostTileRed(xb, yb, z);
        end
    end
end

--- Calculate positions for the second part of the door
--- @param square IsoGridSquare The main square for the door
--- @param north boolean Indicates if the door is facing north
--- @return number x, number y, number z Position for the second part
function ISThreeTileGarageDoor:getSquare2Pos(square, north)
    local x = square:getX();
    local y = square:getY();
    local z = square:getZ();
    if north then
        x = x + 1;
    else
        y = y - 1;
    end
    return x, y, z;
end

--- Calculate positions for the third part of the door
--- @param square IsoGridSquare The main square for the door
--- @param north boolean Indicates if the door is facing north
--- @return number x, number y, number z Position for the third part
function ISThreeTileGarageDoor:getSquare3Pos(square, north)
    local x = square:getX();
    local y = square:getY();
    local z = square:getZ();
    if north then
        x = x + 2;
    else
        y = y - 2;
    end
    return x, y, z;
end

--- Checks if a part of the door already exists on a given square
--- @param square IsoGridSquare The square to check
--- @param index number The index of the door part (1, 2, or 3)
--- @return boolean exists True if part exists, false otherwise
function ISThreeTileGarageDoor:partExists(square, index)
    local spriteIndex = index;
    if spriteIndex == 1 then spriteIndex = ""; end
    local spriteName = self.north and self["northSprite" .. spriteIndex] or self["sprite" .. spriteIndex];
    local objects = square:getSpecialObjects();
    for i = 1, objects:size() do
        local object = objects:get(i - 1);
        if
            IsoDoor.getGarageDoorIndex(object) == index and object:getNorth() == self.north and not object:IsOpen() and
            object:getSprite():getName() == spriteName
        then
            return true;
        end
    end
    return false;
end
