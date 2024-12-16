---This class is responsible for adding UI settings and mapping them to the existing settings variables
---@class SettingsUI
---@field sectionTitle table @The UI control which displays the section title
---@field controls table @A list of UI controls
---@field loadedConfig table @A reference to the loaded configuration object
---@field enableContractValueOverrides table @A UI control
---@field rewardFactor table @A UI control
---@field maxContractsPerFarm table @A UI control
---@field maxContractsPerType table @A UI control
---@field maxContractsOverall table @A UI control
---@field enableStrawFromHarvestMissions table @A UI control
---@field enableSwathingForHarvestMissions table @A UI control
---@field enableGrassFromMowingMissions table @A UI control
---@field enableStonePickingFromMissions table @A UI control
---@field enableFieldworkToolFillItems table @A UI control
---@field baleMissionReward table @A UI control
---@field baleWrapMissionReward table @A UI control
---@field plowMissionReward table @A UI control
---@field cultivateMissionReward table @A UI control
---@field sowMissionReward table @A UI control
---@field harvestMissionReward table @A UI control
---@field hoeMissionReward table @A UI control
---@field weedMissionReward table @A UI control
---@field herbicideMissionReward table @A UI control
---@field fertilizeMissionReward table @A UI control
---@field mowMissionReward table @A UI control
---@field tedderMissionReward table @A UI control
---@field stonePickMissionReward table @A UI control
---@field deadwoodMissionReward table @A UI control
---@field treeTransportMissionReward table @A UI control
---@field destructibleRockMissionReward table @A UI control
SettingsUI = {
}

-- Create a meta table to get basic Class-like behavior
local SettingsUI_mt = Class(SettingsUI)

---Creates the settings UI object
---@return SettingsUI @The new object
function SettingsUI.new()
    local self = setmetatable({}, SettingsUI_mt)

    self.controls = {}
    self.loadedConfig = nil
    self.isInitialized = false

    return self
end

---Injects the UI controls into the general settings menu
---@param loadedConfig table @The loaded config
function SettingsUI:injectUiSettings(loadedConfig)
    -- Remember the settings object
    self.loadedConfig = loadedConfig

    if self.isInitialized then
        return
    end
    self.isInitialized = true

    -- Get a reference to the base game general settings page
    local settingsPage = g_gui.screenControllers[InGameMenu].pageSettings

    -- Define the UI controls. For bool values, supply just the name, for ranges, supply min, max and step, and for choices, supply a values table
    -- For every name, a <prefix>_<name>_long and _short text must exist in the l10n files
    -- The _short text will be the title of the setting, the _long" text will be its tool tip
    -- For each control, a on_<name>_changed callback will be called on change
    local controlProperties = {
        { name = "enableContractValueOverrides", autoBind = true },
        { name = "rewardFactor", min = 0.5, max = 5.0, step = 0.1, autoBind = true },
        { name = "maxContractsPerFarm", values = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 15, 20, 25, 30, 40, 50, 60, 70, 80, 90, 100 }, autoBind = true },
        { name = "maxContractsPerType", min = 1, max = 25, step = 1, autoBind = true },
        { name = "maxContractsOverall", values = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 15, 20, 25, 30, 40, 50, 60, 70, 80, 90, 100 }, autoBind = true },
        { name = "enableStrawFromHarvestMissions", autoBind = true },
        { name = "enableSwathingForHarvestMissions", autoBind = true },
        { name = "enableGrassFromMowingMissions", autoBind = true },
        { name = "enableHayFromTedderMissions", autoBind = true },
        { name = "enableStonePickingFromMissions", autoBind = true },
        { name = "enableCollectingBalesFromMissions", autoBind = true },
        { name = "enableFieldworkToolFillItems", autoBind = true },
    }

    -- Dynamically add the rest since they're all the same
    local missionTypes = {
        "baleMission", "baleWrapMission", "plowMission", "cultivateMission", "sowMission", "harvestMission", "hoeMission", "weedMission",
        "herbicideMission", "fertilizeMission", "mowMission", "tedderMission", "stonePickMission",
        "deadwoodMission", "treeTransportMission", "destructibleRockMission"
    }

    local missionTypesCalculatedPerItem = {
        baleMission = true,
        baleWrapMission = true,
        deadwoodMission = true,
        treeTransportMission = true,
        destructibleRockMission = true,
    }

    -- Add in the customRewards types
    for _, prop in missionTypes do
        
        if missionTypesCalculatedPerItem[prop] then 
            table.insert(controlProperties, {
                name = prop .. "Reward",
                nillable = true,
                min = 0,
                max = 1000,
                step = 50,
                autoBind = true,
                subTable = "customRewards",
                propName = prop
            })
        else 
            table.insert(controlProperties, {
                name = prop .. "Reward",
                nillable = true,
                min = 0,
                max = 5000,
                step = 100,
                autoBind = true,
                subTable = "customRewards",
                propName = prop
            })
        end
    end

    -- Add in the customMaxPerType
    for _, prop in missionTypes do
        table.insert(controlProperties, {
            name = prop .. "MaxPerType",
            nillable = true,
            -- values = { '-', 0, 1, 2, 3, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50 },
            min = 0,
            max = 50,
            step = 1,
            autoBind = true,
            subTable = "customMaxPerType",
            propName = prop
        })
    end

    UIHelper.createControlsDynamically(settingsPage, "contract_boosted", self, controlProperties, "cb_")
    UIHelper.setupAutoBindControls(self, self.loadedConfig, SettingsUI.onSettingsChange)

    -- Apply initial values
    self:updateUiElements()

    -- Update any additional settings whenever the frame gets opened
    InGameMenuSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuSettingsFrame.onFrameOpen, function()
        self:updateUiElements(true) -- We can skip autobind controls here since they are already registered to onFrameOpen
    end)
end

function SettingsUI:onSettingsChange(control)
    self:updateUiElements()
    -- TODO: Multiplayer synchronization

    -- Grab the setting and new value from the UI element
    local setting = control.elements[1]
    local newValue = setting.texts[setting.state]

    local fullResetSettings = {

    }
    
    if fullResetSettings[setting] then
        ContractBoost:activateSettings()
    end


    -- -- Type conversion from the current "value" to boolean
    -- if newValue == 'On' then newValue = true end
    -- if newValue == 'Off' then newValue = false end

    -- -- Allow nil values from the UI, from the 'nillable' property
    -- if newValue == '-' then newValue = nil end

    -- -- Type conversion from strings back to numbers 
    -- if tonumber(newValue) ~= nil then newValue = tonumber(newValue) end

    -- -- Check for a subTable and if one is there - put the value back into the config object
    -- local subTable = setting.parent.subTable or nil
    -- local propName = setting.parent.propName or nil
    -- if subTable ~= nil and propName ~= nil then
    --     if ContractBoost.debug then
    --         printf('!! settings change: ContractBoost.config.%s.%s | value: %s ', subTable, propName, newValue)
    --     end
    --     if not ContractBoost.config[subTable] then
    --         ContractBoost.config[subTable] = {}
    --     end
    --     ContractBoost.config[subTable][propName] = newValue
    -- else
    --     if ContractBoost.debug then 
    --         printf('!! settings change: ContractBoost.config.%s | value: %s ', control.name, newValue)
    --     end
    --     ContractBoost.config[control.name] = newValue
    -- end

end

---Updates the UI elements to reflect the current settings
---@param skipAutoBindControls boolean|nil @True if controls with the autoBind properties shall not be newly populated
function SettingsUI:updateUiElements(skipAutoBindControls)

    if not skipAutoBindControls then
        -- Note: This method is created dynamically by UIHelper.setupAutoBindControls
        self.populateAutoBindControls()
    end

    -- Disable settings if required
    local contractValueOverrideRewards = {
        self.rewardFactor, self.maxContractsPerFarm, self.maxContractsPerType, self.maxContractsOverall,
        self.baleMissionReward, self.baleWrapMissionReward, self.plowMissionReward, self.cultivateMissionReward,
        self.sowMissionReward, self.harvestMissionReward, self.hoeMissionReward, self.weedMissionReward, 
        self.herbicideMissionReward, self.fertilizeMissionReward, self.mowMissionReward, self.tedderMissionReward,
        self.stonePickMissionReward, self.deadwoodMissionReward, self.treeTransportMissionReward, self.destructibleRockMissionReward
    }
    for _, control in ipairs(contractValueOverrideRewards) do
        if control ~= self.enableContractValueOverrides then
            control:setDisabled(not self.loadedConfig.enableContractValueOverrides)
        end
    end

    -- Update the focus manager
    local settingsPage = g_gui.screenControllers[InGameMenu].pageSettings
    settingsPage.generalSettingsLayout:invalidateLayout()
end