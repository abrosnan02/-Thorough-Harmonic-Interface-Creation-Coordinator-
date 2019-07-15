--[[
    Thorough Harmonic Interface Creation Coordinator 2
    Anthony Brosnan, July 2019

    Independent library, optional tweening
    TODO: tweens, postprocessing, shadows, dynamic text and other scaling, outlines, textwrap, rotation

    Easing equasion module available here: https://github.com/EmmanuelOga/easing/blob/master/lib/easing.lua
]]--

--/Main Variables/--------------------------------------------------------------
local Thicc2 = {}
local elements = {}
local effects = {}
local tweens = {}
local tweenFunctions = {}
local dt = 1/60
local easingModule = require('easing')

--/THICC Variables/-------------------------------------------------------------
Thicc2.settings = { --unused atm
}


--/UDim/------------------------------------------------------------------------
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
local function newTween(start, dest, duration, easing)
    --putting the check here checks everything
    if not easingModule then error('Easing module not found! It can be downloaded at https://github.com/EmmanuelOga/easing/blob/master/lib/easing.lua') end
    local tween = {
        start = start, --starting value
        dest = dest, --destination
        elapsed = 0, --elapsed time
        duration = duration, --max duration
        type = 'number',

        easingStyle = easing or 'linear',
    }
    

    return tween
end

local function tweenSize(element, size, duration, easing)
    local id = #tweens+1
    local tween = {
        xs = newTween(element.size[1],size[1],duration, easing),
        xp = newTween(element.size[2],size[2],duration, easing),
        ys = newTween(element.size[3],size[3],duration, easing),
        yp = newTween(element.size[4],size[4],duration, easing),
        element = element,
        type = 'size'
    }
    tweens[id] = tween

    return tweens[id]
end

local function tweenPos(element, pos, duration, easing)
    local id = #tweens+1
    local tween = {
        xs = newTween(element.pos[1],pos[1],duration, easing),
        xp = newTween(element.pos[2],pos[2],duration, easing),
        ys = newTween(element.pos[3],pos[3],duration, easing),
        yp = newTween(element.pos[4],pos[4],duration, easing),
        element = element,
        type = 'pos'
    }
    tweens[id] = tween

    return tweens[id]
end

local function updateTween(tween) --updates delta and sends variables
    tween.elapsed = tween.elapsed+dt
    return tween.elapsed, tween.start, tween.dest-tween.start, tween.duration
end

if easingModule then
    for name, equasion in pairs(easingModule) do --retrieve all of the equasions from the module
        tweenFunctions[name] = function(tween)
            local t,b,c,d = updateTween(tween)

            if tween.elapsed > tween.duration then tween.elapsed = tween.duration end
            return equasion(t,b,c,d)
        end
    end
end


--/Base Element/----------------------------------------------------------------
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
        backgroundColor = {100,100,100},

        radius = 0, --UDim2
        radiusSegments = 1, --UDim2

        type = 'base', --modifying this has no effect but it doesnt benefit anything
        parent = parent or nil,

        getChildren = function(element)
            local children = {}
            
            for _,v in pairs(elements) do
                if v.parent == element then
                    table.insert(children, v)
                end
            end

            return children
        end,

        tweenSize = tweenSize,
        tweenPos = tweenPos,
    }
    
    return element
end

local function newEffect(effect, zindex)
    effects[zindex] = moonshine.chain(moonshine.effects[effect])

    return effects[zindex]
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
    element.horizontalAlign = 'center' --left, right, center
    element.verticalAlign = 'center' --top, bottom, center
    element.wrapText = false
    element.textTransparency = 0
    element.textColor = {255,255,255}

    table.insert(elements, element)
    return element
end


--/Draw/------------------------------------------------------------------------
local function draw(element)
    local maxWidth, maxHeight = love.graphics.getDimensions()
    local width, height = udim2(element,element.size[1],element.size[2],element.size[3],element.size[4],'size')
    local x, y = udim2(element,element.pos[1],element.pos[2],element.pos[3],element.pos[4])
    
    --account for parent position, this will look bad for 1 frame if things are not zindexed properly :(
    if element.parent and element.parent.absoluteSize then x = x+element.parent.absolutePos[1] y = y+element.parent.absolutePos[2] end
    element.absoluteSize = {width,height} --set actual pixel size for children


    --Handle drawing
    if not element.visible then return end
    love.graphics.setColor(element.backgroundColor[1]/255, element.backgroundColor[2]/255, element.backgroundColor[3]/255, math.abs(element.transparency-1))

    love.graphics.rectangle('fill', x, y, width, height, element.radius,element.radius, element.radiusSegments)

    if element.image then
        --images dont support rounded corners :(
        local imgWidth, imgHeight = element.image:getDimensions()
        love.graphics.setColor(element.imageColor[1]/255, element.imageColor[2]/255, element.imageColor[3]/255, math.abs(element.imageTransparency-1))
        love.graphics.draw(element.image, x, y, 0, width/imgWidth, height/imgHeight)-- ox, oy, kx, ky )
    elseif element.text then
        local text = love.graphics.newText(element.font, element.text)
        local textWidth, textHeight = text:getDimensions()
        local textX, textY = 0
        
        --horizontal
        if element.horizontalAlign:lower() == 'left' then
            textX = 0
        elseif element.horizontalAlign:lower() == 'right' then
            textX = width-textWidth
        else
            textX = (width/2)-textWidth/2 --roblox math gang
        end

        --vertical
        if element.verticalAlign:lower() == 'top' then
            textY = 0
        elseif element.verticalAlign:lower() == 'bottom' then
            textY = height-textHeight
        else
            textY = (height/2)-textHeight/2 --width is 1, so you subtract your number/2
        end

        if element.wrapText then
            local width, wrappedText = element.font:getWrap(element.text, element.absoluteSize[1]-textX)

            --make wrapped text
            local newTextString = ''
            for _,v in pairs(wrappedText) do
                newTextString = newTextString..v..'\n'
            end
            text:set(newTextString)
        end

        love.graphics.setColor(element.textColor[1]/255, element.textColor[2]/255, element.textColor[3]/255, math.abs(element.textTransparency-1))
        love.graphics.draw(text, x+textX, y+textY)
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

    table.sort(layerNum)


    --render elements
    for _,layer in pairs(layerNum) do
        for _,element in pairs(layers[layer]) do
            draw(element)
        end        
    end

    
end

Thicc2.update = function(delta) --required for tweens
    dt = delta
    for k,v in pairs(tweens) do
        if v.type == 'size' then
            if not tweenFunctions[v.xs.easingStyle] then error('Unknown easing style "'..v.xs.easingStyle..'"') end
            v.element.size[1] = tweenFunctions[v.xs.easingStyle](v.xs)
            v.element.size[2] = tweenFunctions[v.xp.easingStyle](v.xp)
            v.element.size[3] = tweenFunctions[v.xs.easingStyle](v.ys)
            v.element.size[4] = tweenFunctions[v.yp.easingStyle](v.yp)
            
            if v.xs.elapsed == v.xs.duration then
                table.remove(tweens, k)
            end
        elseif v.type == 'pos' then
            if not tweenFunctions[v.xs.easingStyle] then error('Unknown easing style "'..v.xs.easingStyle..'"') end
            v.element.pos[1] = tweenFunctions[v.xs.easingStyle](v.xs)
            v.element.pos[2] = tweenFunctions[v.xp.easingStyle](v.xp)
            v.element.pos[3] = tweenFunctions[v.xs.easingStyle](v.ys)
            v.element.pos[4] = tweenFunctions[v.yp.easingStyle](v.yp)
            
            if v.xs.elapsed == v.xs.duration then
                table.remove(tweens, k)
            end
        end        
        
        
    end
end

--/Return/----------------------------------------------------------------------
Thicc2.newEffect = newEffect
Thicc2.newTween = newTween
Thicc2.tweenSize = tweenSize
Thicc2.tweenPos = tweenPos
return Thicc2
