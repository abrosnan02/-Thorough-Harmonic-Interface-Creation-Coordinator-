--[[
    Thorough Harmonic Interface Creation Coordinator 2
    Anthony Brosnan, July 2019

    Independent library, optional tweening
    Easing equasion module available here: https://github.com/EmmanuelOga/easing/blob/master/lib/easing.lua 
    TODO: padding, postprocessing, shadows, dynamic text and other scaling, outlines, rotation, UDim2 single sets, textboxes

    This library uses the GPLv2 license, which can be read in the LICENSE.txt file.
]]--

--/Main Variables/--------------------------------------------------------------
local Thicc2 = {}
local elements = {}
local effects = {}
local tweenFunctions = {}
local dt = 0 --for one frame at the start no tweening can be performed
local easingModule = require('easing')
local mousePrevDown = nil
local mouseClick = nil


--/THICC Variables/-------------------------------------------------------------
Thicc2.settings = { --unused atm
}


--/UDim2/-----------------------------------------------------------------------
local function udim2(element, xs, xp, ys, yp, size)
	local maxWidth, maxHeight = love.graphics.getDimensions()

	--multiply scale by these
    if element.parent and element.parent.absoluteSize then
		maxWidth = element.parent.absoluteSize[1]
        maxHeight = element.parent.absoluteSize[2]
        
	end

	if size then --dont apply axis for size
		if element.axis:lower() == 'yy' then
			maxWidth = maxHeight
		elseif element.axis:lower() == 'xx' then
			maxHeight = maxWidth
        end
        element.absoluteSize = {(maxWidth*xs)+xp, (maxHeight*ys)+yp}
    else
        element.absolutePos = {(maxWidth*xs)+xp, (maxHeight*ys)+yp}
    end
    
	return (maxWidth*xs)+xp, (maxHeight*ys)+yp
end

local function udim1(xs, xp, height)
    local maxWidth, maxHeight = love.graphics.getDimensions()
    if height then maxWidth = maxHeight end

    return (maxWidth*xs)+xp
end


--/Tweens/----------------------------------------------------------------------
local function checkDupeTweens(element,type)
    local tweens = {}
    for k,v in pairs(element.tweens) do
        if v.type == type then
            table.insert(tweens,v)
        end
    end

    for k,v in pairs(element.tweens) do --go through all element tweens
        for kk, vv in pairs(tweens) do --check the same type as type
            if v == vv and #tweens > 1 then --remove any earlier tweens
                table.remove(tweens,kk)
                table.remove(element.tweens,k)
            end
        end
    end
end

local function newTween(start, dest, duration, easing)
    --putting the check here checks everything
    if not easingModule then error('Easing module not found! There is a link to it at the top of this script.') end
    local tween = {
        start = start, --starting value
        dest = dest, --destination
        elapsed = 0, --elapsed time
        duration = duration, --max duration
        type = 'number',

        easingStyle = easing or 'linear',
    }
    return tween --returns tween table with basic properties
end

local function tweenTable(element, property, dest, duration, easing)
    local tween = {
        indexes = #element[property],
        property = property,
        element = element,
        type = 'table'..property,
        
    }
    --make tweens for each index
    for k,v in pairs(element[property]) do
        tween['t'..k] = newTween(element[property][k], dest[k], duration, easing)
    end

    table.insert(element.tweens, tween)
    checkDupeTweens(element,tween.type)

    return tween
end

local function tweenNum(element, property, dest, duration, easing)
    local tween = {
        tween = newTween(element[property],dest,duration, easing),
        property = property,
        element = element,
        type = 'num'
    }
    table.insert(element.tweens, tween)
    checkDupeTweens(element,tween.type)
    assert(type(element[property]) == 'number', 'Property must be a string with the same name as a numbered property')
    return nil
end

local function updateTween(tween) --updates delta and sends variables
    tween.elapsed = tween.elapsed+dt
    return tween.elapsed, tween.start, tween.dest-tween.start, tween.duration
end

--retrieve all of the equasions from the module, you could add more to it if you wanted to
if easingModule then
    for name, equasion in pairs(easingModule) do 
        tweenFunctions[name] = function(tween)
            local t,b,c,d = updateTween(tween)

            if tween.elapsed > tween.duration then tween.elapsed = tween.duration end
            return equasion(t,b,c,d)
        end
    end
end


--/Base Element/----------------------------------------------------------------
local function getChildren()
    local children = {}
    
    for _,v in pairs(elements) do
        if v.parent == element then
            table.insert(children, v)
        end
    end

    return children
end

local function getDescendants()
    local descendants = {}

    return descendants
end

local function newElement(size, pos, parent, zindex)
    local element = {
        size = size or {0,100,0,100}, --UDim2 sizes
        pos = pos or {0,0,0,0},
        absoluteSize = nil, --actual sizes in pixels
        absolutePos = nil,

        rotation = 0,

        transparency = 0, --BACKGROUND transparency
        zindex = zindex or 1,
        axis = 'XY', --XX, YY, XY

        visible = true,
        childrenVisible = false, --when set to false, all children are hidden, doesnt change their "visible" value
        backgroundColor = {100,100,100},

        radius = 0, --UDim2
        radiusSegments = 1, --UDim2

        type = 'base', --modifying this has no effect but it doesnt benefit anything
        parent = parent or nil,


        getChildren = getChildren,
        getDescendants = getDescendants,

        --assign tween functions to element
        tween = function(element, property, dest, duration, easing)
            --all encompassing tween function with same argument layouts
            if type(element[property]) == 'number' then
                tweenNum(element, property, dest, duration, easing)
            elseif type(element[property]) == 'table' then
                tweenTable(element, property, dest, duration, easing)
            else
                error('Unsupported tween type; ')
            end
        end,

        tweens = {} --all active tweens applied to element
    }

    --auto zindex :)
    if element.parent then element.zindex = element.parent.zindex end

    return element
end


--/Differentiate Elements/------------------------------------------------------
Thicc2.frame = function(size, pos, parent, zindex)
    local element = newElement(size, pos, parent, zindex)
    element.type = 'frame'

    table.insert(elements, element)
    return element
end

Thicc2.image = function(size, pos, parent, zindex)
    local element = newElement(size, pos, parent, zindex)
    element.type = 'image'
    element.image = love.image.newImageData(1,1)
    element.imageTransparency = 0
    element.imageColor = {255,255,255}

    table.insert(elements, element)
    return element
end

Thicc2.text = function(size, pos, parent, zindex)
    local element = newElement(size, pos, parent, zindex)
    element.type = 'text'
    element.text = 'Hello world!'
    element.font = love.graphics.newFont(15)

    --alignment only works with textWrap on
    element.horizontalAlign = 'center' --left, right, center
    element.verticalAlign = 'center' --top, bottom, center
    element.wrapText = false

    element.textTransparency = 0
    element.textColor = {255,255,255}

    
    table.insert(elements, element)
    return element
end

Thicc2.button = function(size, pos, parent, zindex)
    local element = Thicc2.text(size,pos,parent,zindex)
    element.type = 'button'
    element.clickColor = {150,150,150}
    element.hoverColor = {125,125,125}
    
    --these do nothing when nil they're just a reminder
    element.hover = nil
    element.leave = nil

    element.mouse1Down = nil
    element.mouse2Down = nil
    element.mouse3Down = nil

    element.mouse1Click = nil
    element.mouse2Click = nil
    element.mouse3Click = nil

    return element
end

--/Mouse Input/-----------------------------------------------------------------
Thicc2.mouseClick = function(button)
    mouseClick = button
end

--/Draw/------------------------------------------------------------------------
local function draw(element, maxWidth, maxHeight, mouseX, mouseY, mouse1Down)
    local width, height = udim2(element,element.size[1],element.size[2],element.size[3],element.size[4],'size')
    local x, y = udim2(element,element.pos[1],element.pos[2],element.pos[3],element.pos[4])

    --account for parent position, this will look bad for 1 frame if things are not zindexed properly :(
    if element.parent and element.parent.absoluteSize then x = x+element.parent.absolutePos[1] y = y+element.parent.absolutePos[2] end
    element.absoluteSize = {width,height} --set actual pixel size for children


    --Handle drawing
    if not element.visible then return end
    love.graphics.setColor(element.backgroundColor[1]/255, element.backgroundColor[2]/255, element.backgroundColor[3]/255, math.abs(element.transparency-1))

    --detect hover/clicking
    if element.hoverColor then
        if mouseX >= x and mouseX <= x+width and mouseY >= y and mouseY <= y+height then
            if mouse1Down then
                love.graphics.setColor(element.clickColor[1]/255, element.clickColor[2]/255, element.clickColor[3]/255, math.abs(element.transparency-1))
            else
                love.graphics.setColor(element.hoverColor[1]/255, element.hoverColor[2]/255, element.hoverColor[3]/255, math.abs(element.transparency-1))
            end
            if mouseClick and element.type == 'button' then
                if element['mouse'..tostring(mouseClick)..'Click'] then element['mouse'..tostring(mouseClick)..'Click']() end
                mouseClick = nil
            end
        end
    end

    --use math.floor to prevent blurriness
    love.graphics.rectangle('fill', math.floor(x), math.floor(y), math.floor(width), math.floor(height), element.radius,element.radius, element.radiusSegments)

    if element.image then
        --images dont support rounded corners :(
        local imgWidth, imgHeight = element.image:getDimensions()
        love.graphics.setColor(element.imageColor[1]/255, element.imageColor[2]/255, element.imageColor[3]/255, math.abs(element.imageTransparency-1))
        love.graphics.draw(element.image, x, y, 0, width/imgWidth, height/imgHeight)-- ox, oy, kx, ky )
    elseif element.text then
        local wrap = 999999999 --until a screen has this many X pixels it wont be a problem
        local textY = y
        local text = love.graphics.newText(element.font, element.text) --printf is faster but doesnt have Y aligment :(

        if element.wrapText then
            wrap = width
        elseif element.wrapText and element.horizontalAlign == 'center' then
            wrap = text:getWidth()
        end

        --apply wrap and align
        text:setf(element.text, width, element.horizontalAlign)
        
        --set vertical alignment, no top bc it is default
        if element.verticalAlign == 'center' then
            textY = (height/2)-text:getHeight()/2
        elseif element.verticalAlign == 'bottom' then
            textY = height-text:getHeight()
        end

        love.graphics.setColor(element.textColor[1]/255, element.textColor[2]/255, element.textColor[3]/255, math.abs(element.textTransparency-1))
        love.graphics.setFont(element.font)
        
        --keep text from getting blurry
        love.graphics.draw(text, math.floor(x), math.floor(y+textY))
    end
end

Thicc2.draw = function()
    --handle zindexing
	local layers = {}
	local layerNum = {}
	for _,v in pairs(elements) do
        if layers[v.zindex] then
            table.insert(layers[v.zindex],v)
        else
			table.insert(layerNum, v.zindex)
			layers[v.zindex] = {}
            table.insert(layers[v.zindex],v)
		end
	end

    --sort layers into iterable zindex layers
    table.sort(layerNum)

    --render elements by layer
    for _,layer in pairs(layerNum) do
        for _,element in pairs(layers[layer]) do
            local maxWidth, maxHeight = love.graphics.getDimensions()
            local mouseX, mouseY = love.mouse.getPosition()
            draw(element, maxWidth, maxHeight, mouseX, mouseY, love.mouse.isDown(1))
        end        
    end

    --reset color
    love.graphics.setColor(1,1,1)
end


Thicc2.update = function(delta) --required for tweens
    dt = delta
    --update all tweens
    for _, element in pairs(elements) do
        if #element.tweens >  0 then --if there are tweens
            for k, tween in pairs(element.tweens) do
                --update induvidual tween types    
                if string.sub(tween.type,1,5) == 'table' then
                    if not tweenFunctions[tween.t1.easingStyle] then error('Unknown easing style "'..tween.t1.easingStyle..'"') end
                    
                    for i = 1, tween.indexes do
                        tween.element[tween.property][i] = tweenFunctions[tween['t'..tostring(i)].easingStyle](tween['t'..tostring(i)])
                        --v.element.color[1] = tweenFunctions[v.r.easingStyle](v.r)
                    end

                    if tween.t1.elapsed == tween.t1.duration then
                        table.remove(element.tweens, k)
                    end
                elseif tween.type == 'num' then
                    if not tweenFunctions[tween.tween.easingStyle] then error('Unknown easing style "'..tween.xs.easingStyle..'"') end
                    tween.element[tween.property] = tweenFunctions[tween.tween.easingStyle](tween.tween)

                    if tween.tween.elapsed == tween.tween.duration then
                        table.remove(element.tweens, k)
                    end
                end
            end
        end
    end
end

--/Return/----------------------------------------------------------------------
return Thicc2