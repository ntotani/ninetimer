require "cocos.cocos2d.json"
require "cocos.ui.GuiConstants"

local MainScene = class("MainScene", cc.load("mvc").ViewBase)

local TIME = 540
local FONT_SIZE = 18
local DELAY = 0.2

function MainScene:onCreate()
    local eb = ccui.EditBox:create(cc.size(256, 36), "editbox.png")
    eb:setFontSize(FONT_SIZE)
    eb:setFontName("Hiragino Kaku Gothic Pro W3")
    eb:setFontColor(cc.c3b(0, 0, 0))
    eb:move(display.cx / 2, display.top - 100):addTo(self)
    local time = TIME
    local countDown = cc.Label:createWithSystemFont("", "Arial", 128)
    countDown:move(display.cx / 2, display.cy):addTo(self)
    local showTime = function()
        local min = math.floor(time / 60)
        countDown:setString(string.format("%02d:%02d", min, time - min * 60))
    end
    showTime()
    local played = false

    local listView = ccui.ListView:create():move(display.cx, 0):addTo(self)
    listView:setDirection(ccui.ListViewDirection.vertical)
    listView:setContentSize(cc.size(display.width / 2, display.height))
    listView:setBounceEnabled(true)
    listView:setGravity(ccui.ListViewGravity.centerHorizontal)

    local playButton = cc.MenuItemImage:create("PlayButton.png", "PlayButton.png")
        :onClicked(function()
            local query = eb:getText()
            require("cocos.cocos2d.luaoc").callStaticMethod("AppController", "requestSearch", {
                query = query,
                callback = function(tweets)
                    local texts = ""
                    local elms = {}
                    local totalHeight = 0
                    for i, v in ipairs(tweets) do
                        v.text = string.gsub(v.text, "\n", " ")
                        v.text = string.gsub(v.text, "　", " ")
                        --v.text = string.gsub(v.text, "\n\n\n+", "\n\n")
                        local item = ccui.Layout:create()
                        fetchIcon(v.icon, function(texture)
                            cc.Sprite:createWithTexture(texture):align(cc.p(0, 1.0), 0, item:getContentSize().height):addTo(item)
                        end)
                        local measure = cc.Label:createWithSystemFont(v.text, "Hiragino Kaku Gothic Pro W3", FONT_SIZE)
                        measure:setDimensions(listView:getContentSize().width - 58, 0)
                        local rt = ccui.RichText:create()
                        rt:setContentSize(measure:getContentSize())
                        rt:ignoreContentAdaptWithSize(false)
                        local re = ccui.RichElementText:create(0, cc.c3b(255, 255, 255), 255, v.text, "Hiragino Kaku Gothic Pro W3", FONT_SIZE)
                        rt:pushBackElement(re)
                        item:setContentSize(listView:getContentSize().width, math.max(48, rt:getContentSize().height) + 24)
                        totalHeight = totalHeight + item:getContentSize().height
                        item.pos = math.max(0, totalHeight - listView:getContentSize().height)
                        rt:move(rt:getContentSize().width / 2 + 58, item:getContentSize().height / 2 + 12):addTo(item)
                        item:align(cc.p(0, 1), 0, item:getContentSize().height)
                        item:setScale(1, 0)
                        item:runAction(cc.Sequence:create(cc.DelayTime:create((i - 1) * DELAY), cc.CallFunc:create(function()
                            listView:jumpToPercentVertical(item.pos / (totalHeight - listView:getContentSize().height) * 100)
                        end), cc.ScaleTo:create(DELAY, 1)))
                        listView:pushBackCustomItem(item)
                        texts = texts .. v.text .. "。"
                        table.insert(elms, {rt = rt, re = re, text = v.text})
                    end
                    require("cocos.cocos2d.luaoc").callStaticMethod("AppController", "requestKeyphrase", {
                        tweets = texts,
                        callback = function(keywords)
                            local proc = nil
                            proc = function(str)
                                for i, kw in ipairs(keywords) do
                                    local head, tail, num = str:find(kw)
                                    if head then
                                        local results = {}
                                        if head > 1 then
                                            for i, e in ipairs(proc(str:sub(1, head - 1))) do
                                                table.insert(results, e)
                                            end
                                        end
                                        local color = i == 1 and cc.c3b(255, 0, 0) or cc.c3b(0, 0, 255)
                                        table.insert(results, {text = kw, color = color})
                                        if tail < #str then
                                            for i, e in ipairs(proc(str:sub(tail + 1))) do
                                                table.insert(results, e)
                                            end
                                        end
                                        return results
                                    end
                                end
                                return {{text = str, color = cc.c3b(255, 255, 255)}}
                            end
                            self:runAction(cc.Sequence:create(cc.DelayTime:create(#tweets * DELAY), cc.CallFunc:create(function()
                                for i, elm in ipairs(elms) do
                                    elm.rt:removeElement(elm.re)
                                    for j, e in ipairs(proc(elm.text, keyword)) do
                                        elm.rt:pushBackElement(ccui.RichElementText:create(j, e.color, 255, e.text, "Hiragino Kaku Gothic Pro W3", FONT_SIZE))
                                    end
                                end
                                cc.Label:createWithSystemFont(keywords[1], "Hiragino Kaku Gothic Pro W3", FONT_SIZE * 2):move(display.cx / 2, display.top - 200):addTo(self)
                                played = true
                            end)))
                        end
                    })
                end
            })
        end)
    cc.Menu:create(playButton)
        :move(display.cx / 2, display.cy - 200)
        :addTo(self)
    self:onUpdate(function(dt)
        if not played then return end
        time = time - dt
        if time <= 0 then
            time = 0
            self:onUpdate(function()end)
            audio.playSound("bell.mp3")
        end
        showTime()
    end)
end

return MainScene
