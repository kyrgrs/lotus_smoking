local QBCore = exports['qb-core']:GetCoreObject()
local InvType = Config.CoreSettings.Inventory.Type
local NotifyType = Config.CoreSettings.Notify.Type

--notification function
local function SendNotify(src, msg, type, time, title)
    if NotifyType == nil then print("lotus_smoking: NotifyType Not Set in Config.CoreSettings.Notify.Type!") return end
    if not title then title = "Smoking" end
    if not time then time = 5000 end
    if not type then type = 'success' end
    if not msg then print("Notification Sent With No Message") return end
    if NotifyType == 'qb' then
        TriggerClientEvent('QBCore:Notify', src, msg, type, time)
    elseif NotifyType == 'okok' then
        TriggerClientEvent('okokNotify:Alert', src, title, msg, time, type, Config.CoreSettings.Notify.Sound)
    elseif NotifyType == 'mythic' then
        TriggerClientEvent('mythic_notify:client:SendAlert', src, { type = type, text = msg, style = { ['background-color'] = '#00FF00', ['color'] = '#FFFFFF' } })
    elseif NotifyType == 'ox' then 
        TriggerClientEvent('ox_lib:notify', src, ({ title = title, description = msg, length = time, type = type, style = 'default'}))
    end
end

--remove items
local function removeItem(src, item, amount)
    if InvType == 'qb' then
        if exports['qb-inventory']:RemoveItem(src, item, amount, false, false, false) then
            TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'remove', amount)
        end
    elseif InvType == 'ox' then
        exports.ox_inventory:RemoveItem(src, item, amount)
    end
end

--add items
local function addItem(src, item, amount)
    if InvType == 'qb' then
        if exports['qb-inventory']:AddItem(src, item, amount, false, false, false) then
            TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'add', amount)
        end
    elseif InvType == 'ox' then
        if exports.ox_inventory:CanCarryItem(src, item, amount) then
            exports.ox_inventory:AddItem(src, item, amount)
        else
            SendNotify(src, Config.Language.Notifications.CantCarry, 'error', 5000)
        end
    end
end

--useable items
for itemName, _ in pairs(Config.Consumables) do
    QBCore.Functions.CreateUseableItem(itemName, function(source, item)
        TriggerClientEvent('lotus_smoking:client:UseItem', source, item.name)
    end)
end


--callback for items and required items
QBCore.Functions.CreateCallback('lotus_smoking:server:hasItem', function(source, cb, itemName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local item = Config.Consumables[itemName]
    if item then
        if item.requiredItem then
            local requiredItem = Player.Functions.GetItemByName(item.requiredItem)         
            if requiredItem then
                cb(true)
            else
                SendNotify(src, 'You need a ' .. item.requiredLabel .. ' to use this!', 'error', 5000)    
                cb(false)
            end
        else
            cb(true)
        end
    else
        cb(false)       
    end
end)

--use item
RegisterNetEvent('lotus_smoking:server:UseItem', function(itemName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        removeItem(src, itemName, 1)
    end
end)

--return item
RegisterNetEvent('lotus_smoking:server:returnItems', function(itemName, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        addItem(src, itemName, amount)
    end
end)

RegisterNetEvent('lotus_smoking:server:UseVapeJuice', function(itemName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local itemConfig = Config.Consumables[itemName]
    if not itemConfig then return end -- Item config yoksa işlemi durdur

    local requiredItem = itemConfig.requiredItem
    local chance = itemConfig.juiceChance or 25 -- Default 25% şans

    -- Gerekli item kontrolü
    if not requiredItem then
        print(("Config hatası: %s item'i için requiredItem tanımlı değil!"):format(itemName))
        return
    end

    -- Şans kontrolü ile item'ı sil
    if chance >= math.random(1, 100) then
        Player.Functions.RemoveItem(requiredItem, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[requiredItem], "remove")
    end
end)









--qb inventory shop
RegisterNetEvent('lotus_smoking:server:openShop', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local smokingShop = {
        { name = "redwoodpack",      price = 250, amount = 100, info = {}, type = "item", slot = 1,}, 
        { name = "debonairepack",    price = 250, amount = 100, info = {}, type = "item", slot = 2,},
        { name = "sixtyninepack",    price = 250, amount = 100, info = {}, type = "item", slot = 3,},
        { name = "yukonpack",        price = 250, amount = 100, info = {}, type = "item", slot = 4,},
        { name = "vape",             price = 100, amount = 100, info = {}, type = "item", slot = 5,},
        { name = "vapejuice",        price = 50,  amount = 100, info = {}, type = "item", slot = 6,},
        { name = "lighter",          price = 5,   amount = 100, info = {}, type = "item", slot = 7,},
    }
    exports['qb-inventory']:CreateShop({
        name = 'smokingShop',
        label = 'Smoking Shop',
        slots = 7,
        items = smokingShop
    })
    if Player then
        exports['qb-inventory']:OpenShop(source, 'smokingShop')
    end
end)

--ox_ivnentory shop
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() == resourceName) then
        if InvType == 'ox' then
            exports.ox_inventory:RegisterShop('smokingShop', {
                name = 'Smoking Shop',
                inventory = {
                    { name = 'vozol10kblackberryice', price = 70 },
                    { name = 'vozol10kcherryice', price = 70 },
                    { name = 'vozol10kblueberryice', price = 70 },
                    { name = 'vozol10kstrawberrysmoothie', price = 70 },
                    { name = 'vozol10kraspberrywatermelon', price = 70 },
                    { name = 'vozol10kmangosmoothie', price = 70 },
                    { name = 'vozol10kpeachice', price = 70 },
                    { name = 'vozol10kmixedberries', price = 70 },
                    { name = 'vozol10kmiamimint', price = 70 },
                    { name = 'vozol10klushice', price = 70 },
                    { name = 'vozol10klemonmint', price = 70 },
                    { name = 'vozol10kgrapeice', price = 70 },
                    { name = 'vozol10kforestberrystorm', price = 70 },
                    { name = 'vozol10kcreamtobacco', price = 70 },
                    { name = 'vozol10kcottoncandy', price = 70 },
                    { name = 'vozol10kcedarberries', price = 70 },
                    { name = 'vozol10kbluerazzice', price = 70 },
                    { name = 'vozol10kbluerazzlemon', price = 70 },
                    { name = 'vozol10klemonlime', price = 70 },
                    --12K
                    { name = 'vozol12kpeachice', price = 70 },
                    { name = 'vozol12klemonmint', price = 70 },
                    { name = 'vozol12klemonlime', price = 70 },
                    { name = 'vozol12kwatermelonice', price = 70 },
                    { name = 'vozol12kbluerazzice', price = 70 },
                    { name = 'vozol12kvzbull', price = 70 },
                    { name = 'vozol12kstrawberrywatermelon', price = 70 },
                    { name = 'vozol12kstrawberryraspberrycherry', price = 70 },
                    { name = 'vozol12krainbowcandy', price = 70 },
                    { name = 'vozol12kpineapplecoconutice', price = 70 },
                    { name = 'vozol12kmexicanmangoice', price = 70 },
                    { name = 'vozol12kdragonfruitbananacherry', price = 70 },
                    { name = 'vozol12kcremesaverscandy', price = 70 },
                    { name = 'vozol12kcranberrymangograpefruit', price = 70 },
                    { name = 'vozol12kcherrypeachlemonade', price = 70 },
                    { name = 'vozol12kcherrylime', price = 70 },
                    { name = 'vozol12kcherrycola', price = 70 },
                    --20K
                    { name = 'vozol20kwatermelonice', price = 70 },
                    { name = 'vozol20ktropicalblast', price = 70 },
                    { name = 'vozol20kstrawberrymango', price = 70 },
                    { name = 'vozol20kstrawberrykiwi', price = 70 },
                    { name = 'vozol20kraspberrywatermelon', price = 70 },
                    { name = 'vozol20kraspberryapplewatermelonpineapple', price = 70 },
                    { name = 'vozol20kperfumelemon', price = 70 },
                    { name = 'vozol20kpeachmangowatermelon', price = 70 },
                    { name = 'vozol20korangepineapplelychee', price = 70 },
                    { name = 'vozol20kmixedberries', price = 70 },
                    { name = 'vozol20kmangoice', price = 70 },
                    { name = 'vozol20klove777', price = 70 },
                    { name = 'vozol20klemonlime', price = 70 },
                    { name = 'vozol20kjuicypeachice', price = 70 },
                    { name = 'vozol20kgrapeice', price = 70 },
                    { name = 'vozol20kdragonstrawnana', price = 70 },
                    { name = 'vozol20kdoubleappleice', price = 70 },
                    { name = 'vozol20kcherrycola', price = 70 },
                    { name = 'vozol20kblueberrystorm', price = 70 },
                    { name = 'vozol20kbluerazzice', price = 70 },
                    --Likit
                    { name = 'likit_tropical_blast', price = 5 },
                    { name = 'likit_strawberry_mango', price = 5 },
                    { name = 'likit_strawberry_kiwi', price = 5 },
                    { name = 'likit_raspberry_watermelon', price = 5 },
                    { name = 'likit_raspberry_apple_watermelon_pineapple', price = 5 },
                    { name = 'likit_perfume_lemon', price = 5 },
                    { name = 'likit_peach_mango_watermelon', price = 5 },
                    { name = 'likit_orange_pineapple_lychee', price = 5 },
                    { name = 'likit_love_777', price = 5 },
                    { name = 'likit_juicy_peach_ice', price = 5 },
                    { name = 'likit_dragon_strawnana', price = 5 },
                    { name = 'likit_double_apple_ice', price = 5 },
                    { name = 'likit_blueberry_storm', price = 5 },
                    { name = 'likit_vz_bull', price = 5 },
                    { name = 'likit_strawberry_watermelon', price = 5 },
                    { name = 'likit_strawberry_raspberry_cherry', price = 5 },
                    { name = 'likit_rainbow_candy', price = 5 },
                    { name = 'likit_pineapple_coconut_ice', price = 5 },
                    { name = 'likit_mexican_mango_ice', price = 5 },
                    { name = 'likit_dragon_fruit_banana_cherry', price = 5 },
                    { name = 'likit_creme_savers_candy', price = 5 },
                    { name = 'likit_cranberry_mango_grapefruit', price = 5 },
                    { name = 'likit_cherry_peach_lemonade', price = 5 },
                    { name = 'likit_cherry_lime', price = 5 },
                    { name = 'likit_cherry_cola', price = 5 },
                    { name = 'likit_blackberry_ice', price = 5 },
                    { name = 'likit_watermelon_ice', price = 5 },
                    { name = 'likit_blueberry_ice', price = 5 },
                    { name = 'likit_strawberry_smoothie', price = 5 },
                    { name = 'likit_raspberry_watermelon', price = 5 },
                    { name = 'likit_mango_smoothie', price = 5 },
                    { name = 'likit_peach_ice', price = 5 },
                    { name = 'likit_mixed_berries', price = 5 },
                    { name = 'likit_miami_mint', price = 5 },
                    { name = 'likit_lush_ice', price = 5 },
                    { name = 'likit_lemon_mint', price = 5 },
                    { name = 'likit_grape_ice', price = 5 },
                    { name = 'likit_forest_berry_storm', price = 5 },
                    { name = 'likit_cream_tobacco', price = 5 },
                    { name = 'likit_cotton_candy', price = 5 },
                    { name = 'likit_cedar_berries', price = 5 },
                    { name = 'likit_blue_razz_ice', price = 5 },
                    { name = 'likit_blue_razz_lemon', price = 5 },
                    { name = 'likit_lemon_lime', price = 5 },
                },
            })
        end
    end
end)