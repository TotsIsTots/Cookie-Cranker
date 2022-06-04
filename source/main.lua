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


playdate.display.setInverted(true)

-- Garbage collection
pd.setCollectsGarbage(false)
local gcint = 10
local gcframes = 0

-- make a function that rounds a number to x decimal places
function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- make a function that shortens numbers
function shorten(num)
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
local cookieSprite = gfx.sprite.new(cookieImage)
cookieSprite:moveTo(320, 160)
cookieSprite:add()

-- little cookie
local smallCookieImage = gfx.image.new("images/smallcookie")
local smallCookieSprite = gfx.sprite.new(smallCookieImage)
smallCookieSprite:moveTo(83, 18)
smallCookieSprite:add()

-- cookies
local cookies = 0
local CpS = 0

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
-- local miniDrillState = 1
-- local miniDrillTable = gfx.imagetable.new("images/minidrill/minidrill")
-- local radian = 0.5 * math.pi
-- local miniDrillSprite = gfx.sprite.new(miniDrillTable:getImage(miniDrillState))
-- miniDrillSprite:setClipRect(243, 4, 153, 232)
-- miniDrillSprite:moveTo(395, 235)
-- miniDrillSprite:add()


-- store
local menuOptions = {"Drill", "Grandma", "Farm", "Mine", "Factory", "Bank", "Temple", "Wizard tower", "Shipment", "Alchemy Lab", "Portal", "Time Machine", "Antimatter Condenser", "Prism", "Chancemaker", "Fractal Engine", "Javascript Console", "Idleverse"}
local menuOptionsUnlocked = 0
local numberPurchased = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
local prices = {15, 100, 1100, 12000, 130000, 1400000, 20000000, 330000000, 5100000000, 75000000000, 1000000000000, 14000000000000, 170000000000000, 2100000000000000, 26000000000000000, 310000000000000000, 71000000000000000000, 12000000000000000000000}
local buying = true
local buildingCpS = {.1, 1, 8, 47, 260, 1400, 7800, 44000, 260000, 1600000, 10000000, 65000000, 430000000, 2900000000, 21000000000, 150000000000, 1100000000000, 8300000000000}
local store = pd.ui.gridview.new(0, 20)
store:setNumberOfRows(menuOptionsUnlocked)
store:setContentInset(0, 0, 1, 1)

function store:drawCell(section, row, column, selected, x, y, width, height)
    if row <= menuOptionsUnlocked + 2 then
        if selected then
            gfx.fillRoundRect(x, y, 180, 20, 4)
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        else
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
        end
        if row <= menuOptionsUnlocked then
            gfx.drawTextInRect(menuOptions[row], x+5, y+2, width, height)
        else
            gfx.drawTextInRect("???", x+5, y+2, width, height)
        end
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        if numberPurchased[row] > 0 then
            gfx.drawTextInRect(shorten(numberPurchased[row]), x+width-64, y+2, 56, height, nil, nil, kTextAlignment.right)
        end
    end
end

-- load save
if pd.datastore.read("save") ~= nil then
    local save = pd.datastore.read("save")
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
    cookies = save[1]
    numberPurchased = save[2]
    menuOptionsUnlocked = save[3]
    for i = 1, #numberPurchased do
        prices[i] = prices[i] * (1.15 ^ numberPurchased[i])
    end
    for i = 1, #numberPurchased do
        CpS += buildingCpS[i] * numberPurchased[i]
    end
else
    local save = {cookies, numberPurchased, menuOptionsUnlocked}
    pd.datastore.write(save, "save", true)
end

function playdate.gameWillTerminate()
    -- load into save file
    save = {cookies, numberPurchased, menuOptionsUnlocked}
    pd.datastore.write(save, "save", true)
end

function playdate.deviceWillSleep()
    -- load into save file
    save = {cookies, numberPurchased, menuOptionsUnlocked}
    pd.datastore.write(save, "save", true)
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
        gfx.drawText("*Store*       " .. shorten(math.ceil(prices[store:getSelectedRow()])), 14, 10)
        gfx.drawTextAligned("_Buying_", 226, 10, kTextAlignment.right)
    else
        gfx.drawText("*Store*       " .. shorten(math.ceil(prices[store:getSelectedRow()] / 10)), 14, 10)
        gfx.drawTextAligned("_Selling_", 226, 10, kTextAlignment.right)
    end
    store:drawInRect(9, 30, 225, 207)
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
    end
    if pd.buttonJustPressed(pd.kButtonA) and not buying and numberPurchased[store:getSelectedRow()] > 0 then
        cookies = cookies + math.ceil(prices[store:getSelectedRow()] / 10)
        CpS -= buildingCpS[store:getSelectedRow()]
        numberPurchased[store:getSelectedRow()] -= 1
        prices[store:getSelectedRow()] = prices[store:getSelectedRow()] / 1.15
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

    gfx.drawLine(240, 4, 240, 236, 5) -- dividing line

    -- cookie code
    cookies += math.abs(crankSpeed/360)
    gfx.drawTextAligned(shorten(math.floor(cookies)) .. " cookies", 320, 10, kTextAlignment.center) -- cookie count
    gfx.drawTextAligned(shorten(CpS) .. " CpS", 320, 30, kTextAlignment.center) -- CpS
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
    -- for i = 1, numberPurchased[1] do
    --     miniDrillSprite:draw(250, i * 10 + 10)
    -- end
    --miniDrillSprite:moveTo(55 * math.sin(radian) + 320, 55 * math.cos(radian) + 160)
    --miniDrillSprite:setRotation(270)

    -- garbage collection
    if gcframes == gcint then
        gcframes = 0
        collectgarbage()
    else
        gcframes = gcframes + 1
    end

    pd.timer.updateTimers()
end