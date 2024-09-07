local BuildingMenu = require("BuildingMenu01_Main")
require("BuildingMenu04_CategoriesDefinitions")

local function formatLeadingZeroes(number)
    return string.format("%02d", number)
end

local function getSpriteName(category, subcategory, batch, index)
    return "en_flags_" .. category .. "_" .. subcategory .. "_" .. formatLeadingZeroes(batch) .. "_" .. index
end

local function addExtraNoisesFlagsToMenu()
    local function createSmallFlag(category, subcategory, batch, index)
        local flagRecipeName = getFlagRecipeName(getSpriteName(category, subcategory, batch, index), true)
        if flagRecipeName == nil then
            flagRecipeName = "BlankFlagSmallRecipe"
        end
        return BuildingMenu.createObject(
                "",
                "",
                BuildingMenu.onBuildSimpleFurniture,
                BuildingMenu[flagRecipeName],
                true,
                {
                    actionAnim = "Build",
                    noNeedHammer = true,
                    craftingBank = "Painting",
                    needToBeAgainstWall = true,
                    blockAllTheSquare = false,
                    renderFloorHelper = false,
                    canPassThrough = true,
                    canBarricade = false
                },
                {
                    sprite = getSpriteName(category, subcategory, batch, index + 4),
                    northSprite = getSpriteName(category, subcategory, batch, index)
                }
        )
    end

    local function createFlag(category, subcategory, batch, index)
        local flagRecipeName = getFlagRecipeName(getSpriteName(category, subcategory, batch, index), false)
        if flagRecipeName == nil then
            flagRecipeName = "BlankFlagRecipe"
        end
        return BuildingMenu.createObject(
                "",
                "",
                BuildingMenu.onBuildThreeTileSimpleFurniture,
                BuildingMenu[flagRecipeName],
                true,
                {
                    actionAnim = "Build",
                    noNeedHammer = true,
                    craftingBank = "Painting",
                    isCorner = true,
                    needToBeAgainstWall = true,
                    blockAllTheSquare = false,
                    renderFloorHelper = false,
                    canPassThrough = true,
                    canBarricade = false
                },
                {
                    sprite = getSpriteName(category, subcategory, batch, index + 5),
                    sprite2 = getSpriteName(category, subcategory, batch, index + 6),
                    sprite3 = getSpriteName(category, subcategory, batch, index + 7),
                    northSprite = getSpriteName(category, subcategory, batch, index + 1),
                    northSprite2 = getSpriteName(category, subcategory, batch, index + 2),
                    northSprite3 = getSpriteName(category, subcategory, batch, index + 3),
                }
        )
    end

    local flagCountCategories = {
        ["local"] = { usa = 16, mixed = 16 },
        misc = { random = 32, org = 16, pride = 16, reddit = 32, fictional = 32, protest = 16, colors = 16 },
        national = { mideast = 16, africa = 32, native = 16, oceania = 16, asia = 16, historical = 32, mixed = 16, movements = 32, europe = 32, americas = 16 },
        regional = { usa = 56, canada = 16, europe = 16 }
    }

    for category, subCategories in pairs(flagCountCategories) do
        for subCategory, count in pairs(subCategories) do
            local flags = {}

            for i = 0, count - 1 do
                table.insert(flags, createSmallFlag(category, subCategory, math.floor(i / 16) + 1, i * 8 % 128))
                table.insert(flags, createFlag(category, subCategory, math.floor(i / 16) + 1, i * 8 % 128))
            end

            BuildingMenu.addObjectsToCategories(
                    getText("IGUI_BuildingMenuTab_ExtraNoiseFlag"),
                    getText("IGUI_BuildingMenuCat_ExtraNoiseFlag_" .. category),
                    getSpriteName(category, subCategory, 1, 4),
                    getText("IGUI_BuildingMenuCat_ExtraNoiseFlag_" .. category .. "_" .. subCategory),
                    getSpriteName(category, subCategory, 1, 4),
                    flags
            )
        end
    end
end

local function addCategoriesToBuildingMenu()
    addExtraNoisesFlagsToMenu()
end
Events.OnGameStart.Add(addCategoriesToBuildingMenu)