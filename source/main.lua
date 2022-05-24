import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/object"
import "CoreLibs/ui"

local pd <const> = playdate
local gfx <const> = pd.graphics
local crankSpeed = nil
local test = 0

playdate.display.setInverted(true)

-- make a function that shortens numbers
function shorten(num)
    -- if num < 1e3 then
    --     return num
    -- elseif num < 1e6 then
    --     return string.format("%.3fk", num/1e3)
    -- elseif num < 1e9 then
    --     return string.format("%.3fm", num/1e6)
    -- elseif num < 1e12 then
    --     return string.format("%.3fb", num/1e9)
    -- elseif num < 1e15 then
    --     return string.format("%.3ft", num/1e12)
    -- elseif num < 1e18 then
    --     return string.format("%.3fq", num/1e15)
    -- elseif num < 1e21 then
    --     return string.format("%.3fQ", num/1e18)
    -- elseif num < 1e24 then
    --     return string.format("%.3fs", num/1e21)
    -- elseif num < 1e27 then
    --     return string.format("%.3fS", num/1e24)
    -- elseif num < 1e30 then
    --     return string.format("%.3fo", num/1e27)
    -- elseif num < 1e33 then
    --     return string.format("%.3fn", num/1e30)
    -- elseif num < 1e36 then
    --     return string.format("%.3fd", num/1e33)
    -- else
    --     return string.format("%.3f TOO_MANY", num/1e36)
    -- end
    local abbrv = {
        "%.3f",
        "%.3fk",
        "%.3fm",
        "%.3fb",
        "%.3ft",
        "%.3fq",
        "%.3fQ",
        "%.3fs",
        "%.3fS",
        "%.3fo",
        "%.3fn",
        "%.3fd"
    }
    local i = math.max(math.floor((math.log(100, 10) / 3) + 1), 1)
    print(i)
    return string.format(abbrv[math.max(math.floor(math.log(num, 10) / 3) + 1, 1)], num / 10 ^ (math.max(math.floor(math.log(num, 10) / 3), 0) * 3))
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

local drill1Table = gfx.imagetable.new("images/drill1/drill1")

local drillTable = drill1Table

local drillSprite = gfx.sprite.new(drillTable:getImage(drillState))
drillSprite:setCenter(.5, 1)
drillSprite:moveTo(320, 113)
drillSprite:add()

-- store
local menuOptions = {"Drill", "Grandma", "Farm", "Factory", "Mine", "Shipment", "Alchemy Lab", "Portal", "Time Machine", "Antimatter Condenser", "Prism", "Chancemaker", "Fractal Engine", "Javascript Console", "Idleverse"}
local numberPurchased = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
local prices = {15, 100, 1100, 12000, 130000, 1400000, 20000000, 330000000, 5100000000, 75000000000, 1000000000000, 14000000000000, 170000000000000, 2100000000000000, 26000000000000000, 310000000000000000, 71000000000000000000, 12000000000000000000000}
local buildingCpS = {.1, 1, 8, 47, 260, 1400, 7800, 44000, 260000, 1600000, 10000000, 65000000, 430000000, 2900000000, 21000000000, 150000000000, 1100000000000, 8300000000000}
local store = pd.ui.gridview.new(0, 20)
store:setNumberOfRows(#menuOptions)
store:setContentInset(0, 0, 1, 1)

function store:drawCell(section, row, column, selected, x, y, width, height)
    if selected then
            gfx.fillRoundRect(x, y, width, 20, 4)
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    else
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end
    gfx.drawTextInRect(menuOptions[row], x+5, y+2, width, height)
end

-- code
function pd.update()
    gfx.sprite.update()

    -- store code
    gfx.drawText("*Store*       " .. shorten(prices[store:getSelectedRow()]), 14, 10)
    store:drawInRect(9, 30, 180, 207)
    if pd.buttonJustPressed(pd.kButtonDown) then
        store:selectNextRow(1)    
    end
    if pd.buttonJustPressed(pd.kButtonUp) then
        store:selectPreviousRow(1)
    end
    if pd.buttonJustPressed(pd.kButtonA) and cookies >= prices[store:getSelectedRow()] then
        cookies = cookies - prices[store:getSelectedRow()]
        CpS += buildingCpS[store:getSelectedRow()]
        numberPurchased[store:getSelectedRow()] += 1
        prices[store:getSelectedRow()] = prices[store:getSelectedRow()] * 1.15
    end

    gfx.drawLine(240, 4, 240, 236, 5) -- dividing line

    -- cookie code
    crankSpeed = pd.getCrankChange(change)
    cookies += math.abs(crankSpeed/360)
    gfx.drawTextAligned(shorten(math.floor(cookies)) .. " cookies", 320, 5, kTextAlignment.center) -- cookie count
    gfx.drawRoundRect(295, 22, 50, 10, 2) -- cookie progress outline
    gfx.fillRoundRect(295, 22, math.max(cookies - math.floor(cookies), .08) * 50, 10, 2) -- cookie progress
    gfx.drawTextAligned(shorten(CpS) .. " CpS", 320, 35, kTextAlignment.center) -- CpS
    cookies = cookies + (CpS/30)

    -- drill code
    drillState = math.floor(360 - pd.getCrankPosition() / 45) % 4 + 1
    drillSprite:setImage(drillTable:getImage(drillState))
    
    pd.drawFPS()

    pd.timer.updateTimers()
end
