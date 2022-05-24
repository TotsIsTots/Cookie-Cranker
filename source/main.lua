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

-- shorten numbers
function shortNumberString(number)
    local steps = {
        {1,""},
        {1e3,"k"},
        {1e6,"m"},
        {1e9,"b"},
        {1e12,"t"},
        {1e15,"q"},
        {1e18,"Q"},
        {1e21, "s"},
        {1e24, "S"},
        {1e27, "o"},
        {1e30, "n"},
        {1e33, "d"},
        -- {1e36, "ud"},
        -- {1e39, "dd"},
        -- {1e42, "td"},
        -- {1e45, "qd"},
        -- {1e48, "Qd"},
        -- {1e51, "sd"},
        -- {1e54, "Sd"},
        -- {1e57, "od"},
        -- {1e60, "nd"},
        -- {1e63, "v"},
        -- {1e66, "uv"},
        -- {1e69, "dv"},
        -- {1e72, "tv"},
        -- {1e75, "qv"},
        -- {1e78, "Qv"},
        -- {1e81, "sv"},
        -- {1e84, "Sv"},
        -- {1e87, "ov"},
        -- {1e90, "nv"},
        -- {1e93, "t"},
        -- {1e96, "ut"},
        -- {1e99, "dt"},
        -- {1e102, "tt"},
        -- {1e105, "qt"},
        -- {1e108, "Qt"},
        -- {1e111, "st"},
        -- {1e114, "St"},
        -- {1e117, "ot"},
        -- {1e120, "nt"},
        -- {1e123, "e"},
        -- {1e126, "ue"},
        -- {1e129, "de"},
        -- {1e132, "te"},
        -- {1e135, "qe"},
        -- {1e138, "Qe"},
        -- {1e141, "se"},
        -- {1e144, "Se"},
        -- {1e147, "oe"},
        -- {1e150, "ne"},
        -- {1e153, "y"},
        -- {1e156, "uy"},
        -- {1e159, "dy"},
        -- {1e162, "ty"},
        -- {1e165, "qy"},
        -- {1e168, "Qy"},
        -- {1e171, "sy"},
        -- {1e174, "Sy"},
        -- {1e177, "oy"},
        -- {1e180, "ny"},
        -- {1e183, "z"},
        -- {1e186, "uz"},
        -- {1e189, "dz"},
        -- {1e192, "tz"},
        -- {1e195, "qz"},
        -- {1e198, "Qz"},
        -- {1e201, "sz"},
        -- {1e204, "Sz"},
        -- {1e207, "oz"},
        -- {1e210, "nz"},
        -- {1e213, "w"},
        -- {1e216, "uw"},
        -- {1e219, "dw"},
        -- {1e222, "tw"},
        -- {1e225, "qw"},
        -- {1e228, "Qw"},
        -- {1e231, "sw"},
        -- {1e234, "Sw"},
        -- {1e237, "ow"},
        -- {1e240, "nw"},
        {1e36, "TOO_MANY"}
    }
    for _,b in ipairs(steps) do
        if b[1] <= number+1 then
            steps.use = _
        end
    end
    local result = string.format("%.3f", number / steps[steps.use][1])
    if tonumber(result) >= 1e3 and steps.use < #steps then
        steps.use = steps.use + 1
        result = string.format("%.3f", tonumber(result) / 1e3)
    end
    
    return string.gsub(string.format("%.1f", tonumber(result)), "%.0", "") .. steps[steps.use][2]
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
    gfx.drawText("*Store*    cost: " .. shortNumberString(prices[store:getSelectedRow()]), 14, 10)
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
    gfx.drawTextAligned(shortNumberString(math.floor(cookies)) .. " cookies", 320, 5, kTextAlignment.center) -- cookie count
    gfx.drawRoundRect(295, 22, 50, 10, 2) -- cookie progress outline
    gfx.fillRoundRect(295, 22, math.max(cookies - math.floor(cookies), .08) * 50, 10, 2) -- cookie progress
    gfx.drawTextAligned(shortNumberString(CpS) .. " CpS", 320, 35, kTextAlignment.center) -- CpS
    cookies = cookies + (CpS/30)

    -- drill code
    drillState = math.floor(360 - pd.getCrankPosition() / 45) % 4 + 1
    drillSprite:setImage(drillTable:getImage(drillState))

    pd.timer.updateTimers()
end
