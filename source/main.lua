import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/object"
import "CoreLibs/ui"

local pd <const> = playdate
local gfx <const> = pd.graphics
local easedCrankSpeed = 0
local crankSpeed = 0
local lastTime = 0
local preFPS = 15 --15 is an initial fps guess, can't be nil because
local FPS = 15    --math is nescessary for FPS calculation to work

-- Garbage collection
pd.setCollectsGarbage(false)
local gcint = 10
local gcframes = 0

--find distance between two gmt time tables
function getTimeDiff(t1, t2)
    local yearDiff = t2["year"] - t1["year"]
    local monthDiff = t2["month"] - t1["month"]
    local dayDiff = t2["day"] - t1["day"]
    local hourDiff = t2["hour"] - t1["hour"]
    local minuteDiff = t2["minute"] - t1["minute"]
    local secondDiff = t2["second"] - t1["second"]
    local millisecondDiff = t2["millisecond"] - t1["millisecond"]
    return (yearDiff * 31536000) + (monthDiff * 2592000) + (dayDiff * 86400) + (hourDiff * 3600) + (minuteDiff * 60) + secondDiff + (millisecondDiff / 1000)
end

function round(num, idp)
    local mult = 10 ^ (idp or 0)
    if math.floor(num * mult + 0.5) / mult == nil then
        return 0
    end
    return math.floor(num * mult + 0.5) / mult
end


function abbreviate(num)
    local abbrv = {
        "",
        "k",
        "m",
        "b",
        "t",
        "q",
        "Q",
        "s",
        "S",
        "o",
        "n",
        "d"
    }
    local result = round(num / 10 ^ (math.max(math.floor(math.log(num, 10) / 3), 0) * 3), 3) .. abbrv[math.max(math.floor(math.log(num, 10) / 3) + 1, 1)]
    if num < 1000 then
        result = string.gsub(result, "%.0", "")
    end
    return result
end

local systemMenu = pd.getSystemMenu()
local confirmState = 0
local confirmImage = gfx.image.new("images/confirm1")
local confirmSprite = gfx.sprite.new(confirmImage)
confirmSprite:moveTo(200, 120)
confirmSprite:setZIndex(32767)
local reseting = false
local confirmTimer = pd.timer.new(500, function ()
    confirmState = (confirmState + 1) % 2
    confirmImage:load("images/confirm" .. confirmState + 1)
end)
confirmTimer.repeats = true
menuDarkMode = systemMenu:addCheckmarkMenuItem("Dark Mode", true, function (value)
    pd.display.setInverted(value)
    if value then
        cookieSprite:setImageDrawMode(gfx.kDrawModeInverted)
    else
        cookieSprite:setImageDrawMode(gfx.kDrawModeCopy)
    end
end)
menuMiniDrills = systemMenu:addCheckmarkMenuItem("Mini Drills", true, function (value)
    if value ~= showMiniDrills then
        showingChanged = true
    end
    showMiniDrills = value
end)
systemMenu:addMenuItem("Restart Game", function ()
    reseting = true
end)

-- background
local backgroundImage = gfx.image.new("images/background")
gfx.sprite.setBackgroundDrawingCallback(
    function(x, y, width, height)
        gfx.setClipRect(x, y, width, height)
        backgroundImage:draw(0, 0)
        gfx.clearClipRect()
    end
)

-- big cookie
local cookieImage = gfx.image.new("images/cookie")
cookieSprite = gfx.sprite.new(cookieImage)
cookieSprite:moveTo(320, 160)
cookieSprite:add()

-- little cookie
local smallCookieImage = gfx.image.new("images/smallcookie")
local smallCookieSprite = gfx.sprite.new(smallCookieImage)
smallCookieSprite:moveTo(83, 16)
smallCookieSprite:add()

-- cookies
local cookies = 0
local CpS = 0
local lastPlayed = pd.getGMTTime()

-- drill
local drillState = 1
local drillTable = gfx.imagetable.new("images/drill1/drill1")
local drillSprite = gfx.sprite.new(drillTable:getImage(drillState))
drillSprite:setCenter(.5, 1)
drillSprite:moveTo(320, 113)
drillSprite:add()
local drillHum = pd.sound.fileplayer.new(10)
drillHum:load("sounds/hum")

-- mini drills
local miniDrillImage = gfx.image.new("images/minidrill")
local radian = 0
local layer = 0
miniDrills = {}
showMiniDrills = true
showingChanged = false

-- store
local menuOptions = {"Drill", "Grandma", "Farm", "Mine", "Factory", "Bank", "Temple", "Wizard Tower", "Shipment", "Alchemy Lab", "Portal", "Time Machine", "Antimatter Condenser", "Prism", "Chancemaker", "Fractal Engine", "Javascript Console", "Idleverse"}
local storeImages = {gfx.image.new("images/Drill"), gfx.image.new("images/Grandma"), gfx.image.new("images/Farm"), gfx.image.new("images/Mine"), gfx.image.new("images/Factory"), gfx.image.new("images/Bank"), gfx.image.new("images/Temple"), gfx.image.new("images/WizardTower"), gfx.image.new("images/Shipment"), gfx.image.new("images/AlchemyLab"), gfx.image.new("images/Portal"), gfx.image.new("images/TimeMachine"), gfx.image.new("images/AntimatterCondenser"), gfx.image.new("images/Prism"), gfx.image.new("images/Chancemaker"), gfx.image.new("images/FractalEngine"), gfx.image.new("images/JavascriptConsole"), gfx.image.new("images/Idleverse")}
local menuOptionsUnlocked = 0
numberPurchased = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
local prices = {15, 100, 1100, 12000, 130000, 1400000, 20000000, 330000000, 5100000000, 75000000000, 1000000000000, 14000000000000, 170000000000000, 2100000000000000, 26000000000000000, 310000000000000000, 71000000000000000000, 12000000000000000000000}
local buying = true
local buildingCpS = {.1, 1, 8, 47, 260, 1400, 7800, 44000, 260000, 1600000, 10000000, 65000000, 430000000, 2900000000, 21000000000, 150000000000, 1100000000000, 8300000000000}
local store = pd.ui.gridview.new(0, 20)
store:setNumberOfRows(menuOptionsUnlocked)
store:setContentInset(0, 0, 1, 1)
store:setCellPadding(0, 0, 1, 1)

function store:drawCell(section, row, column, selected, x, y, width, height)
    if row <= menuOptionsUnlocked + 2 then
        if selected then
            gfx.fillRoundRect(x, y, 180, 20, 4)
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        else
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
        end
        if row <= menuOptionsUnlocked then
            gfx.drawTextInRect(menuOptions[row], x+24, y+2, width, height)
            if selected then
                gfx.setImageDrawMode(gfx.kDrawModeInverted)
            end
            storeImages[row]:draw(x + 5, y + 2)
        else
            gfx.drawTextInRect("???", x+24, y+2, width, height)
            if selected then
                gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            else
                gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
            end
            storeImages[row]:draw(x + 5, y + 2)
        end
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        if numberPurchased[row] > 0 then
            gfx.drawTextInRect(abbreviate(numberPurchased[row]), x+width-64, y+2, 56, height, nil, nil, kTextAlignment.right)
        end
    end
end

-- load save
if pd.datastore.read("save") ~= nil then
    local save = pd.datastore.read("save")
    -- handle wrong types
    if type(save[1]) ~= "number" then
        save[1] = nil
    end
    if type(save[2]) ~= "table" then
        save[2] = nil
    end
    if type(save[3]) ~= "number" then
        save[3] = nil
    end
    if type(save[4]) ~= "table" then
        save[4] = nil
    end
    --handle nil values
    if save[1] == nil then
        save[1] = cookies
    end
    if save[2] == nil then
        save[2] = numberPurchased
    end
    if save[3] == nil then
        save[3] = menuOptionsUnlocked
    end
    if save[4] == nil then
        save[4] = pd.getGMTTime()
    end
    --game items
    cookies = save[1]
    numberPurchased = save[2]
    menuOptionsUnlocked = save[3]
    lastPlayed = save[4]
    for i = 1, #numberPurchased do
        prices[i] = prices[i] * (1.15 ^ numberPurchased[i])
    end
    for i = 1, #numberPurchased do
        CpS += buildingCpS[i] * numberPurchased[i]
    end
    for i = 1, numberPurchased[1] do
        miniDrills[i] = gfx.sprite.new(miniDrillImage)
        miniDrills[i]:setClipRect(243, 4, 153, 232)
        miniDrills[i]:add()
    end
    cookies += CpS * getTimeDiff(save[4], pd.getGMTTime())
else
    local save = {cookies, numberPurchased, menuOptionsUnlocked, pd.getGMTTime()}
    pd.datastore.write(save, "save", true)
end

--load settings
if pd.datastore.read("settings") ~= nil then
    local settings = pd.datastore.read("settings")
    -- handle wrong types
    if type(settings[1]) ~= "boolean" then
        settings[1] = nil
    end
    if type(settings[2]) ~= "boolean" then
        settings[2] = nil
    end
    --handle nil values
    if settings[1] == nil then
        settings[1] = false
    end
    if settings[2] == nil then
        settings[2] = true
    end
    --settings items
    menuDarkMode:setValue(settings[1])
    menuMiniDrills:setValue(settings[2])
    if settings[1] then
        cookieSprite:setImageDrawMode(gfx.kDrawModeInverted)
    else
        cookieSprite:setImageDrawMode(gfx.kDrawModeCopy)
    end
    pd.display.setInverted(settings[1])
    if settings[2] ~= showMiniDrills then
        showingChanged = true
    end
    showMiniDrills = settings[2]
else
    local settings = {false, true}
    local settings = pd.datastore.write(settings, "settings", true)
end

function pd.gameWillTerminate()
    -- load into save file
    save = {cookies, numberPurchased, menuOptionsUnlocked, pd.getGMTTime()}
    pd.datastore.write(save, "save", true)
    local settings = {menuDarkMode:getValue(), menuMiniDrills:getValue()}
    local settings = pd.datastore.write(settings, "settings", true)
end

function pd.deviceWillSleep()
    -- load into save file
    save = {cookies, numberPurchased, menuOptionsUnlocked, pd.getGMTTime()}
    pd.datastore.write(save, "save", true)
    local settings = {menuDarkMode:getValue(), menuMiniDrills:getValue()}
    local settings = pd.datastore.write(settings, "settings", true)
end

function pd.gameWillPause()
    lastPlayed = pd.getGMTTime()
end

function pd.deviceWillLock()
    lastPlayed = pd.getGMTTime()
end

function pd.gameWillResume()
    cookies += CpS * getTimeDiff(lastPlayed, pd.getGMTTime())
end

function pd.deviceDidUnlock()
    cookies += CpS * getTimeDiff(lastPlayed, pd.getGMTTime())
end

-- code

function pd.update()
    gfx.sprite.update()

    crankSpeed = pd.getCrankChange(change)
    easedCrankSpeed = (.95 * easedCrankSpeed) + (.05 * crankSpeed)

    --calculate FPS
    preFPS = FPS
    FPS = 1000 / (pd.getCurrentTimeMilliseconds() - lastTime)
    FPS = (.95 * preFPS) + (.05 * FPS) --smooth FPS
    lastTime = pd.getCurrentTimeMilliseconds()

    -- store code
    if buying then
        gfx.drawText("*Store*       " .. abbreviate(math.ceil(prices[store:getSelectedRow()])), 14, 8)
        gfx.drawTextAligned("_Buying_", 226, 8, kTextAlignment.right)
        if(store:getSelectedRow() <= menuOptionsUnlocked) then
            gfx.drawText("+" .. abbreviate(buildingCpS[store:getSelectedRow()]) .. " CpS", 14, 196)
        end
    else
        gfx.drawText("*Store*       " .. abbreviate(math.ceil(prices[store:getSelectedRow()] / 4.6)), 14, 8)
        gfx.drawTextAligned("_Selling_", 226, 8, kTextAlignment.right)
        if(store:getSelectedRow() <= menuOptionsUnlocked) then
            gfx.drawText("-" .. abbreviate(buildingCpS[store:getSelectedRow()]) .. " CpS", 14, 196)
        end
    end
    if(store:getSelectedRow() <= menuOptionsUnlocked) then
        gfx.drawText(abbreviate(buildingCpS[store:getSelectedRow()] * numberPurchased[store:getSelectedRow()]) .. " total (" .. round((buildingCpS[store:getSelectedRow()] * numberPurchased[store:getSelectedRow()]) / (CpS / 100), 1) .. "% of CpS)", 14, 216)
    end
    store:drawInRect(9, 30, 225, 160)
    if pd.buttonJustPressed(pd.kButtonDown) then
        store:selectNextRow(1)
    end
    if pd.buttonJustPressed(pd.kButtonUp) then
        store:selectPreviousRow(1)
    end
    if pd.buttonJustPressed(pd.kButtonA) and cookies >= math.ceil(prices[store:getSelectedRow()]) and buying then
        cookies = cookies - math.ceil(prices[store:getSelectedRow()])
        CpS += buildingCpS[store:getSelectedRow()]
        numberPurchased[store:getSelectedRow()] += 1
        prices[store:getSelectedRow()] = prices[store:getSelectedRow()] * 1.15
        if store:getSelectedRow() == 1 and showMiniDrills then
            miniDrills[numberPurchased[1]] = gfx.sprite.new(miniDrillImage)
            miniDrills[numberPurchased[1]]:setClipRect(243, 4, 153, 232)
            miniDrills[numberPurchased[1]]:add()
        end
    end
    if pd.buttonJustPressed(pd.kButtonA) and not buying and numberPurchased[store:getSelectedRow()] > 0 then
        cookies = cookies + math.ceil(prices[store:getSelectedRow()] / 4.6)
        CpS -= buildingCpS[store:getSelectedRow()]
        numberPurchased[store:getSelectedRow()] -= 1
        prices[store:getSelectedRow()] = prices[store:getSelectedRow()] / 1.15
        if store:getSelectedRow() == 1 and showMiniDrills then
            miniDrills[numberPurchased[1] + 1]:remove()
            miniDrills[numberPurchased[1] + 1] = nil
        end
    end
    if pd.buttonJustPressed(pd.kButtonB) then
        buying = not buying
    end

    --find new menu options

    numberOfPrices = 0
    for i = 1, menuOptionsUnlocked + 1 do
        if cookies >= prices[i] then
            numberOfPrices += 1
        end
    end
    menuOptionsUnlocked = math.max(numberOfPrices, menuOptionsUnlocked)
    store:setNumberOfRows(menuOptionsUnlocked + 2)

    -- cookie code
    cookies += math.abs(crankSpeed/360)
    gfx.drawTextAligned("*" .. abbreviate(math.floor(cookies)) .. " cookies*", 320, 10, kTextAlignment.center) -- cookie count
    gfx.drawTextAligned("*" .. abbreviate(CpS) .. " CpS*", 320, 30, kTextAlignment.center) -- CpS
    cookies += CpS / FPS

    -- drill code
    drillState = math.floor(360 - pd.getCrankPosition() / 45) % 4 + 1
    drillSprite:setImage(drillTable:getImage(drillState))
    if easedCrankSpeed ~= 0 then
        if drillHum:isPlaying() then
            drillHum:setRate(math.abs(easedCrankSpeed/80))
        else
            drillHum:play(0)
            drillHum:setRate(math.abs(easedCrankSpeed/80))
        end
    else
        drillHum:stop()
    end

    -- mini drill code
    if showingChanged then
        if showMiniDrills then
            for i = 1, numberPurchased[1] do
                miniDrills[i] = gfx.sprite.new(miniDrillImage)
                miniDrills[i]:setClipRect(243, 4, 153, 232)
                miniDrills[i]:add()
            end
        else
            for i = 1, #miniDrills do
                miniDrills[i]:remove()
            end
            miniDrills = {}
        end
        showingChanged = false
    end
    if showMiniDrills then
        for i = 1, numberPurchased[1] do
            layer = math.floor((i - 1) / 25)
            miniDrills[i]:moveTo((55 + (15 * layer)) * math.sin((radian + (layer * (math.pi / 25))) + ((math.pi / 12.5) * i)) + 320, (-55 - (15 * layer)) * math.cos((radian + (layer * (math.pi / 25))) + ((math.pi / 12.5) * i)) + 160) -- calculates drill position around cookie
            miniDrills[i]:setRotation(((math.pi + (radian + (layer * (math.pi / 25))) + ((math.pi / 12.5) * i)) % (2 * math.pi)) * (180 / math.pi))
        end
        radian = (radian + ((math.pi / 25) / FPS)) % (2 * math.pi)
    end

    -- garbage collection
    if gcframes == gcint then
        gcframes = 0
        collectgarbage()
    else
        gcframes = gcframes + 1
    end

    -- reset code
    if reseting then
        gfx.clear()
        confirmSprite:setImage(confirmImage)
        confirmSprite:add()
        gfx.sprite.update()
        if pd.buttonJustPressed(pd.kButtonA) then
            reseting = false
            save = {0, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, 0, pd.getGMTTime()}
            pd.datastore.write(save, "save", true)
            cookies = 0
            numberPurchased = save[2]
            CpS = 0
            menuOptionsUnlocked = 0
            for i = 1, #miniDrills do
                miniDrills[i]:remove()
            end
            miniDrills = {}
            prices = {15, 100, 1100, 12000, 130000, 1400000, 20000000, 330000000, 5100000000, 75000000000, 1000000000000, 14000000000000, 170000000000000, 2100000000000000, 26000000000000000, 310000000000000000, 71000000000000000000, 12000000000000000000000}
            store:setSelectedRow(1)
            confirmSprite:remove()
        end
        if pd.buttonJustPressed(pd.kButtonB) then
            reseting = false
            confirmSprite:remove()
        end
    end

    pd.timer.updateTimers()
end