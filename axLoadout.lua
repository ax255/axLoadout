local grid
local selector
local buttons = {}
local lpanel = {}

local config = {}
local axLoadout = {}
local autowield = nil
local profileName = ""

local ax_loadout_enable = CreateClientConVar( "ax_loadout_enable", 1, true, false, "", 0, 1 )
local ax_loadout_autowield = CreateClientConVar( "ax_loadout_autowield", 1, true, false, "", 0, 1 )

local function saveConfig()
    if file.Exists("axLoadout/profiles.json", "DATA") then
        file.Write("axLoadout/profiles.json", util.TableToJSON(config, true) )
        print("Config has been saved")
    end
end

local function selectProfile(name)
    if config.Profiles[name] then
        axLoadout = table.Copy( config.Profiles[name].weapons )
        autowield = config.Profiles[name].autowield
        profileName = name
        print("Profile " .. name .. " has been loaded")
        config.lastSelected = name
        --saveConfig()
    else
        print("Cannot select " .. tostring(name) .. " because it doesn't exist, fallback to Default")
        selectProfile("Default")
    end
end

local function loadProfiles()
    if not file.IsDir("axLoadout", "DATA") then
        print("No axLoadout directory, creating it...")
        file.CreateDir("axLoadout")
    end

    if not file.Exists("axLoadout/profiles.json", "DATA") then
        print("No profile json, creating it...")
        file.Write("axLoadout/profiles.json", util.TableToJSON( {
            lastSelected = "Default",
            Profiles = {
                ["Default"] = {
                    autowield = nil,
                    weapons = {}
                }
            }
        }, true) )
    end

    config = util.JSONToTable( file.Read("axLoadout/profiles.json") )
    print("Profiles loaded, selecting last profile")
    selectProfile(config.lastSelected)

end

local function saveProfile()
    if config.Profiles[profileName] then
        config.Profiles[profileName].autowield = autowield
        config.Profiles[profileName].weapons = table.Copy( axLoadout )
        print("Profile " .. profileName .. " has been saved")
        saveConfig()
    end
end

local function createProfile(name)
    if config.Profiles[name] then
        print("profile already exist")
    else
        config.Profiles[name] = {
            autowield = nil,
            weapons = {}
        }
        print("Profile " .. name .. " has been created")
        selectProfile(name)
        saveConfig()
    end
end

local function deleteProfile(name)
    if config.Profiles[name] and name ~= "Default" then
        config.Profiles[name] = nil
        config.lastSelected = "Default"
        print("Profile " .. name .. " has been deleted")
        saveConfig()
        selectProfile("Default")
    else
        print("Cannot delete " .. name .. " because it doesn't exist or is the default profile!")
    end
end

loadProfiles()

local hl2weps = {} -- manually adding hl2 weapons into the list
local function ADD_WEAPON( name, class )
    table.insert( hl2weps, {ClassName = class, PrintName = name, Category = "Half-Life 2", Author = "VALVe", Spawnable = true } )
end
ADD_WEAPON( "Gravity Gun", "weapon_physcannon" )
ADD_WEAPON( "Stunstick", "weapon_stunstick" )
ADD_WEAPON( "Frag Grenade", "weapon_frag" )
ADD_WEAPON( "Crossbow", "weapon_crossbow" )
ADD_WEAPON( "Bug Bait", "weapon_bugbait" )
ADD_WEAPON( "RPG Launcher", "weapon_rpg" )
ADD_WEAPON( "Crowbar", "weapon_crowbar" )
ADD_WEAPON( "Shotgun", "weapon_shotgun" )
ADD_WEAPON( "9mm Pistol", "weapon_pistol" )
ADD_WEAPON( "S.L.A.M", "weapon_slam" )
ADD_WEAPON( "SMG", "weapon_smg1" )
ADD_WEAPON( "Pulse-Rifle", "weapon_ar2" )
ADD_WEAPON( ".357 Magnum", "weapon_357" )

local weapons = weapons.GetList()
local function GetWeaponsByCategory()
    local categories = {}
    for _, weapon in ipairs(weapons) do
        local category = weapon.Category or "Other"
        if not categories[category] then
            categories[category] = {}
        end
        table.insert(categories[category or "Other"], weapon)
    end
    categories["Half-Life 2"] = hl2weps
    return categories
end
local categories = GetWeaponsByCategory()

local function IsInLoadout(classname)
    for _,weapon in pairs(axLoadout) do
        if weapon.ClassName == classname then
            return true
        end
    end
    return false
end

local function AddToLoadout(weapon, index)

    local tbl = {
        PrintName = weapon.PrintName,
        ClassName = weapon.ClassName,
        Spawnable = weapon.Spawnable,
        AdminOnly = weapon.AdminOnly,
        WorldModel = weapon.WorldModel,
        Icon = weapon.IconOverride or ( file.Exists("materials/entities/" .. weapon.ClassName .. ".png", "GAME") and "entities/" .. weapon.ClassName .. ".png" ) or nil,
    }

    if index then
        --table.insert(axLoadout, index, tbl)
        axLoadout[index] = tbl
    else
        table.insert(axLoadout, tbl)
    end

end

local function RemoveFromLoadout(weapon)

    if type(weapon) == "number" then

        --table.remove(axLoadout, weapon)
        axLoadout[weapon] = nil

    else

        for k,wep in pairs(axLoadout) do
            if wep.ClassName == weapon or wep.PrintName == weapon then
                --table.remove(axLoadout, k)
                axLoadout[k] = nil
            end
        end

    end

end

local function playSound( name )
    LocalPlayer():EmitSound( name )
end

local col_frame = Color( 40, 40, 40 )
local col_frame_bar = Color( 60, 60, 60 )

local col_but = Color( 100, 100, 100 )
local col_but_hover = Color( 120, 120, 120 )
local col_but_pressed = Color( 80, 80, 80 )

local col_white = Color( 255, 255, 255 )
local col_red = Color( 255, 0, 0 )
local col_black = Color( 0, 0, 0 )

local function DrawBlur(panel, amount)
    local x, y = panel:LocalToScreen(0, 0)
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(Material("pp/blurscreen"))

    for i = 1, 3 do
        Material("pp/blurscreen"):SetFloat("$blur", (i / 3) * (amount or 6))
        Material("pp/blurscreen"):Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
    end
end

function lpanel.confirmPrompt(parent, reason, func)

    local frame = vgui.Create("DFrame", parent)
    frame:SetTitle("Confirmation")
    frame:SetSize(300, 150)
    frame:SetPos(ScrW() / 2, ScrH() / 2)
    frame:MakePopup()

    frame.Paint = function(self, w, h)
        draw.RoundedBox( 5, 0, 0, w, h, col_but_hover )
        draw.RoundedBox( 5, 0, 0, w, 25, col_frame_bar )
    end

    local blurPanel = vgui.Create("DPanel", frame)
    blurPanel:SetSize(ScrW(), ScrH())
    blurPanel:SetPos(0, 0)
    blurPanel:MakePopup()

    local startTime = CurTime()
    blurPanel.Paint = function(self, w, h)
        DrawBlur(self, 6)
        surface.SetDrawColor(0, 0, 0, 150)
        surface.DrawRect(0, 0, w, h)
        -- Derma_DrawBackgroundBlur( self, startTime ) -- this blur is kinda meh
    end

    blurPanel.Think = function(self)
        if IsValid(frame) then
            frame:MoveToFront()
        end
    end

    local label = vgui.Create("DLabel", frame)
    label:SetText(reason)
    label:SetFont("HudHintTextLarge")
    label:SizeToContents()
    label:SetPos(frame:GetWide() / 2 - label:GetWide() / 2, 50)

    local confirmButton = vgui.Create("DButton", frame)
    confirmButton:SetText("Confirm")
    confirmButton:SetSize(100, 30)
    confirmButton:SetPos(170, 100)
    confirmButton:SetFont("DefaultBold")
    confirmButton:SetColor(Color(255, 0, 0))

    confirmButton.DoClick = function()
        if func then func() end
        lpanel.buildSideBar(parent)
        lpanel.buildButtons(parent)
        frame:Remove()
        playSound("Buttons.snd42")
    end

    local cancelButton = vgui.Create("DButton", frame)
    cancelButton:SetText("Cancel")
    cancelButton:SetSize(100, 30)
    cancelButton:SetPos(30, 100)

    cancelButton.DoClick = function()
        frame:Remove()
    end

    frame:SetPos( ( ScrW() / 2 ) - frame:GetWide() / 2, ( ScrH() / 2 ) - frame:GetTall() / 2 )

    timer.Simple(60, function()
        if IsValid(blurPanel) then
            blurPanel:Remove()
        end
    end)

end

local lastOpened = 0
function lpanel.openSelector(parent, index)

    local x, y = input.GetCursorPos()
    lastOpened = index

    if IsValid(selector) then
        selector:SetPos( math.Clamp( x, 0, ScrW() - 400 ), math.Clamp( y, 0, ScrH() - 400 ) )
        selector:SetVisible(true)
        selector:MakePopup()
        return
    end

    local frame = vgui.Create("DFrame", parent)
    frame:SetTitle("Weapon List")
    frame:SetSize(400, 400)
    frame:SetPos( math.Clamp( x, 0, ScrW() - 400 ), math.Clamp( y, 0, ScrH() - 400 ) )
    frame:MakePopup()
    frame:SetDeleteOnClose( false )

    frame.Think = function(self, w, h)
        if (input.IsMouseDown( MOUSE_LEFT ) and not ( self:IsHovered() or self:IsChildHovered() ) ) then
            self:Close()
        end
    end

    frame.Paint = function(self, w, h)
        draw.RoundedBox( 5, 0, 0, w, h, col_but_hover )
        draw.RoundedBox( 5, 0, 0, w, 25, col_frame_bar )
    end

    local searchBox = vgui.Create("DTextEntry", frame)
    searchBox:Dock(TOP)
    searchBox:SetPlaceholderText("Search weapons...")

    local tree = vgui.Create("DTree", frame)
    tree:Dock(FILL)

    tree.Paint = function(self, w, h)
        draw.RoundedBox( 5, 0, 2, w, h, Color(230, 230, 230) )
    end

    local function PopulateTree(filter)
        tree:Clear()

        local isFilterEmpty = filter == nil or filter == ""

        for category, weaponList in pairs(categories) do
            local node = tree:AddNode(category, "icon16/gun.png")
            local shouldExpand = false

            for _, weapon in ipairs(weaponList) do
                if not weapon.Spawnable then continue end
                if not filter or string.find(string.lower(weapon.PrintName or weapon.ClassName), string.lower(filter)) then
                    local icon = weapon.IconOverride or (  file.Exists("materials/entities/" .. weapon.ClassName .. ".png", "GAME") and "entities/" .. weapon.ClassName .. ".png" ) or nil
                    local wepNode = node:AddNode(weapon.PrintName or weapon.ClassName, icon or "icon16/gun.png" )

                    local lastClick = 0
                    wepNode.DoClick = function(self)
                        if CurTime() <= lastClick + 0.5 then
                            if IsInLoadout(weapon.ClassName) then
                                RemoveFromLoadout(weapon.ClassName)
                            end
                            AddToLoadout(weapon, lastOpened)
                            lpanel.buildButtons()
                            frame:Close()
                        end
                        lastClick = CurTime()
                    end

                    shouldExpand = filter and true or false
                end
            end

            if #node:GetChildNodes() == 0 then
                node:Remove()
            elseif isFilterEmpty then
                node:SetExpanded(false)
            elseif shouldExpand then
                node:SetExpanded(true)
            end
        end
    end

    PopulateTree()

    searchBox.OnChange = function(self)
        local filter = self:GetValue()
        PopulateTree(filter)
    end

    selector = frame

end

function lpanel.textPrompt(parent)

    local frame = vgui.Create("DFrame", parent)
    frame:SetTitle("Enter profile name")
    frame:SetSize(300, 150)
    frame:SetPos(ScrW() / 2, ScrH() / 2)
    frame:MakePopup()

    frame.Paint = function(self, w, h)
        draw.RoundedBox( 5, 0, 0, w, h, col_but_hover )
        draw.RoundedBox( 5, 0, 0, w, 25, col_frame_bar )
    end

    local blurPanel = vgui.Create("DPanel", frame)
    blurPanel:SetSize(ScrW(), ScrH())
    blurPanel:SetPos(0, 0)
    blurPanel:MakePopup()

    blurPanel.Paint = function(self, w, h)
        DrawBlur(self, 6)
        surface.SetDrawColor(0, 0, 0, 150)
        surface.DrawRect(0, 0, w, h)
    end

    blurPanel.Think = function(self)
        if IsValid(frame) then
            frame:MoveToFront()
        end
    end

    local label = vgui.Create("DLabel", frame)
    label:SetText("Enter profile name")
    label:SetFont("HudHintTextLarge")
    label:SizeToContents()
    label:SetPos(frame:GetWide() / 2 - label:GetWide() / 2, 50)

    local TextEntry = vgui.Create( "DTextEntry", frame )
    TextEntry:SetPos(10, 50)
    TextEntry:SetSize(280, 20)
    TextEntry:SetPlaceholderText("Awesome loadout...")
    TextEntry.OnEnter = function( self )
        createProfile( self:GetValue() )
        lpanel.buildSideBar(parent)
        lpanel.buildButtons(parent)
        frame:Remove()
        playSound("garrysmod/ui_click.wav")
    end

    local confirmButton = vgui.Create("DButton", frame)
    confirmButton:SetText("Create")
    confirmButton:SetSize(100, 30)
    confirmButton:SetPos(170, 100)

    confirmButton.DoClick = function( self )
        createProfile( TextEntry:GetValue() )
        lpanel.buildSideBar(parent)
        lpanel.buildButtons(parent)
        frame:Remove()
        playSound("garrysmod/ui_click.wav")
    end

    local cancelButton = vgui.Create("DButton", frame)
    cancelButton:SetText("Cancel")
    cancelButton:SetSize(100, 30)
    cancelButton:SetPos(30, 100)

    cancelButton.DoClick = function()
        selectProfile(profileName)
        lpanel.buildSideBar(parent)
        lpanel.buildButtons(parent)
        frame:Remove()
    end

    frame:SetPos( ( ScrW() / 2 ) - frame:GetWide() / 2, ( ScrH() / 2 ) - frame:GetTall() / 2 )

    timer.Simple(60, function()
        if IsValid(blurPanel) then
            blurPanel:Remove()
        end
    end)

end

function lpanel.buildButtons(parent)
    buttons = {}

    local items = grid:GetItems()
    for _,item in pairs(items) do
        item:Remove()
    end

    local adminOnlyMat = Material("icon16/shield.png")

    for i = 1, 18 do

        buttons[i] = vgui.Create( "DButton" )
        --buttons[i]:SetText( (axLoadout[i] and axLoadout[i].PrintName) or i )
        buttons[i]:SetText("")
        buttons[i]:SetTextColor(col_white)
        buttons[i]:SetSize( 95, 95 )
        grid:AddItem( buttons[i] )

        if axLoadout[i] then

            local wepMat
            if axLoadout[i].Icon then
                wepMat = Material(axLoadout[i].Icon)
            end

            buttons[i].Paint = function(self, w, h)
                local bcolor = col_but
                if self:IsHovered() then bcolor = col_red end
                if self:IsDown() then bcolor = col_but_pressed end
                draw.RoundedBox( 0, 0, 0, w, h, bcolor )

                if axLoadout[i].Icon then
                    surface.SetDrawColor(col_white)
                    surface.SetMaterial(wepMat)
                    surface.DrawTexturedRect(2, 2, w-4, h-4)
                else
                    draw.RoundedBox( 0, 2, 2, w-4, h-4, col_but )
                end

                if axLoadout[i].AdminOnly then
                    surface.SetDrawColor(col_white)
                    surface.SetMaterial(adminOnlyMat)
                    surface.DrawTexturedRect(4, 4, 15, 15)
                end

                draw.RoundedBox( 0, 0, h-20, w, 20, Color( 50, 50, 50, 150 ) )

            end

            local label = vgui.Create("DLabel", buttons[i])
            label:SetText(axLoadout[i].PrintName)
            label:SetTextColor(col_white)
            label:SetSize(90, 20)
            label:SetPos( buttons[i]:GetWide() / 2 - label:GetTextSize() / 2, 75)

            if axLoadout[i].WorldModel and not axLoadout[i].Icon then

                local mdl = vgui.Create("DModelPanel", buttons[i])
                mdl:SetPos( 0, 0)
                mdl:SetSize( 95, 95)
                mdl:SetModel(axLoadout[i].WorldModel)
                mdl:SetMouseInputEnabled(false)

                if mdl.Entity then
                    local mn, mx = mdl.Entity:GetRenderBounds()
                    local size = 0
                    size = math.max( size, math.abs(mn.x) + math.abs(mx.x) )
                    size = math.max( size, math.abs(mn.y) + math.abs(mx.y) )
                    size = math.max( size, math.abs(mn.z) + math.abs(mx.z) )

                    mdl:SetLookAt((mn + mx) * 0.5)
                    mdl:SetCamPos(Vector(size / 2, size / 2, size / 2))
                end

                mdl.LayoutEntity = function() return end

            end

        else

            buttons[i].Paint = function(self, w, h)
                local bcolor = col_but
                if self:IsHovered() then bcolor = col_but_hover end
                if self:IsDown() then bcolor = col_but_pressed end
                surface.SetDrawColor(bcolor)
                surface.DrawOutlinedRect(0, 0, w, h, 2)

                --surface.SetDrawColor( Color( 255, 255, 255, 150 ))
                surface.DrawRect( ( w / 2 ) - 1, h / 4, 3, h / 2)
                surface.DrawRect(w / 4, ( h / 2 ) - 1, w / 2, 3)
            end

        end

        buttons[i].DoClick = function(self)
            lpanel.openSelector(parent, i)
        end

        buttons[i].DoRightClick = function(self)

            if axLoadout[i] then
                local x, y = input.GetCursorPos()
                local Menu = DermaMenu()
                Menu:SetPos(x, y)
                Menu:MakePopup()

                local autoequip = Menu:AddOption( "Auto equip when spawning", function()
                    if axLoadout[i].ClassName == autowield then
                        autowield = nil
                    else
                        autowield = axLoadout[i].ClassName
                    end
                end)
                if axLoadout[i].ClassName == autowield then
                    autoequip:SetIcon( "icon16/tick.png" )
                    lpanel.buildButtons(parent)
                end
                local remove = Menu:AddOption( "remove", function()
                    RemoveFromLoadout(i)
                    lpanel.buildButtons(parent)
                end)
                remove:SetIcon( "icon16/cancel.png" )
            end

        end

    end

end

function lpanel.buildSideBar(parent)

    local comboBox = vgui.Create( "DComboBox", parent )
    comboBox:SetPos( 630, 30 )
    comboBox:SetSize( 150, 20 )
    comboBox:SetValue( config.lastSelected )
    comboBox:SetSortItems( false )

    for name,profile in pairs(config.Profiles) do
        if profileName == name then
            comboBox:AddChoice( name, nil, nil, "icon16/tick.png" )
        else
            comboBox:AddChoice( name )
        end
    end

    local createNew = comboBox:AddChoice( "Create new", nil, nil, "icon16/add.png" )

    comboBox.OnSelect = function(self, index, value, data)
        if index == createNew then
            lpanel.textPrompt(parent)
        elseif config.Profiles[value] then
            selectProfile(value)
            lpanel.buildButtons(parent)
            lpanel.buildSideBar(parent)
        end
        playSound("Buttons.snd14")
    end

    local checkboxEnable = parent:Add( "DCheckBoxLabel" )
    checkboxEnable:SetPos( 630, 55 )
    checkboxEnable:SetValue( ax_loadout_enable:GetInt() )
    checkboxEnable:SetText("Give loadout on respawn.")
    checkboxEnable:SizeToContents()
    checkboxEnable:SetConVar("ax_loadout_enable")

    local checkboxAutoWield = parent:Add( "DCheckBoxLabel" )
    checkboxAutoWield:SetPos( 630, 75 )
    checkboxAutoWield:SetValue( ax_loadout_autowield:GetInt() )
    checkboxAutoWield:SetText("Auto equip weapon.")
    checkboxAutoWield:SizeToContents()
    checkboxAutoWield:SetConVar("ax_loadout_autowield")

    local deleteButton = vgui.Create( "DButton", parent )
    deleteButton:SetSize(150, 30)
    deleteButton:SetPos(630, 265)
    deleteButton:SetColor(Color(255, 0, 0))
    deleteButton:SetText("Delete")

    deleteButton.DoClick = function(self)
        lpanel.confirmPrompt(parent, "Confirm deletation of '" .. profileName .. "'", function()
            deleteProfile(profileName)
        end)
    end

    local saveButton = vgui.Create( "DButton", parent )
    saveButton:SetSize(150, 30)
    saveButton:SetPos(630, 295)
    saveButton:SetText("Save")

    saveButton.DoClick = function(self)
        saveProfile()
        playSound("garrysmod/ui_click.wav")
        
    end

end

local function loadoutOpen()

    if IsValid(axLoadoutPanel) then
        axLoadoutPanel:SetVisible(true)
        axLoadoutPanel:MakePopup()
        return
    end

    local Frame = vgui.Create( "DFrame" )
    Frame:SetSize( 800, 335 )
    Frame:Center()
    Frame:SetTitle( "Loadout" )
    Frame:SetVisible( true )
    Frame:SetDraggable( true )
    Frame:ShowCloseButton( true )
    Frame:SetDeleteOnClose( false )
    Frame:MakePopup()

    Frame.Paint = function(self, w, h)
        draw.RoundedBox( 5, 0, 0, w, h, col_frame )
        draw.RoundedBox( 5, 0, 0, w, 25, col_frame_bar )
    end

    local DScrollPanel = vgui.Create( "DScrollPanel", Frame )
    DScrollPanel:SetPos(10, 30)
    DScrollPanel:SetSize(612, 360)
    --DScrollPanel:Dock( LEFT )

    if IsValid(grid) then
        grid:Remove()
    end
    grid = vgui.Create( "DGrid", DScrollPanel )
    grid:SetPos( 0, 0)
    grid:SetCols( 6 )
    grid:SetColWide( 100 )
    grid:SetRowHeight( 100 )

    lpanel.buildButtons(Frame)
    lpanel.buildSideBar(Frame)

    axLoadoutPanel = Frame

end

local function giveLoadout()

    print("Giving weapons...")
    PrintTable(axLoadout)
    for _,weapon in pairs(axLoadout) do
        print(weapon.ClassName)
        RunConsoleCommand("gm_giveswep", weapon.ClassName)
    end

    timer.Simple(0.2, function()
        if LocalPlayer():GetWeapon( autowield or "weapon_physgun" ) and ax_loadout_autowield:GetInt() == 1 then
            local wep = LocalPlayer():GetWeapon( autowield or "weapon_physgun" )
            print(autowield or "weapon_physgun")
            if IsValid(wep) then
                input.SelectWeapon( wep )
            end
        end
    end)

end

gameevent.Listen( "player_spawn" )
hook.Add( "player_spawn", "player_spawn_example", function( data )
    if data.userid == LocalPlayer():UserID() and ax_loadout_enable:GetInt() == 1 then
        giveLoadout()
    end
end )

if IsValid(axLoadoutPanel) then
    axLoadoutPanel:Remove()
end

loadoutOpen()
concommand.Add( "ax_loadout", loadoutOpen, nil, "Open loadout gui", 262144 )
