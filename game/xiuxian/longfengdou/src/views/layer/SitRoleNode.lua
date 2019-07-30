--
-- Author: zhong
-- Date: 2016-07-14 17:42:14
--
--坐下玩家
local SitRoleNode = class("SitRoleNode", cc.Node)

local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")
local ClipText = require(appdf.EXTERNAL_SRC .. "ClipText")
local PopupInfoHead = require(appdf.EXTERNAL_SRC .. "PopupInfoHead")

function SitRoleNode:ctor( viewParent, index )
	local function nodeEvent( event )
		if event == "exit" then
			ExternalFun.SAFE_RELEASE(self.m_actShowScore)
		end
	end
	self:registerScriptHandler(nodeEvent)

	self.m_parent = viewParent
	--加载csb资源
	local csbNode = ExternalFun.loadCSB("game/SitRoleNode.csb", self)
	self.m_csbNode = csbNode

	--背景特效
--[[	self.m_spEffect = csbNode:getChildByName("sitdown_effect")
	self.m_spEffect:setVisible(false)--]]

	--信息背景
	local infoBg = csbNode:getChildByName("player_info_1")
	infoBg:setLocalZOrder(1)

	--头像
--[[	local tmp = csbNode:getChildByName("head_bg")
	self.m_headSize = tmp:getContentSize().width*0.9
	tmp:removeFromParent()--]]
	
	--头像框
	self.m_headFrame = csbNode:getChildByName("head_frame")
	self.m_headFrame:setLocalZOrder(1)

	--金币
	self.m_textScore = csbNode:getChildByName("score_text")
	self.m_textScore:setLocalZOrder(1)

	--名字
	self.m_clipNick = csbNode:getChildByName("name_text")
	self.m_clipNick:setLocalZOrder(1)
	
	--庄家标示
	self.m_spBanker = csbNode:getChildByName("sp_banker")
	self.m_spBanker:setVisible(false)
	self.m_spBanker:setLocalZOrder(2)

	--分数
	self.m_atlasScore = csbNode:getChildByName("altas_score")
	self.m_atlasScore:setString("")
	self.m_atlasScore:setLocalZOrder(2)

	self.m_nIndex = index
	self.m_spHead = nil

	--飞行动画
--[[local moveBy = cc.MoveBy:create(1.0, cc.p(0, 50))
local fadeout = cc.FadeOut:create(0.5)
local call = cc.CallFunc:create(function( )
	self.m_atlasScore:setPositionY(-40)
end)
self.m_actShowScore = cc.Sequence:create(moveBy, fadeout, call)
ExternalFun.SAFE_RETAIN(self.m_actShowScore)--]]
	
end

function SitRoleNode:onSitDown( useritem, bAni, isBanker )
	if nil == useritem then
		return
	end
	isBanker = isBanker or false
	
	self:setVisible(true)
	self.m_wChair = useritem.wChairID

	--坐下特效
--[[	if bAni then
		local act = cc.Repeat:create(cc.Blink:create(1.0,1),5)
		self.m_spEffect:stopAllActions()
		self.m_spEffect:runAction(act)
	end	--]]

	--头像
	if nil ~= self.m_spHead and nil ~= self.m_spHead:getParent() then
		self.m_spHead:removeFromParent()
	end
	--local head = PopupInfoHead:createNormalCircle(useritem, self.m_headSize,("Circleframe.png"))
	local head = PopupInfoHead:createNormal(useritem, 70)
	if nil ~= head then
		head:setPosition(0,0)
		self.m_csbNode:addChild(head)
		local size = cc.Director:getInstance():getWinSize()
		local pos = cc.p(165, 530-160*(self.m_nIndex-1))
		local anchor = cc.p(0, 0)
		if self.m_nIndex > 3 then			
			pos = cc.p(1170-400, 530-160*(6-self.m_nIndex))
			anchor = cc.p(1, 0)	
		end		

		head:enableInfoPop(true, pos, anchor)
	end	

	self.m_spHead = head

	--昵称
	self.m_clipNick:setString("ID:"..useritem.dwGameID)

	--金币
--[[	local str = ExternalFun.numberThousands(useritem.lScore)
	if string.len(str) > 11 then
		str = string.sub(str,1,11) .. "..."
	end--]]
	--local str = ExternalFun.formatScoreText(useritem.lScore);

	local ipLocation = ""
	ipLocation = useritem.szAdressLocation
	self.m_textScore:setString(ipLocation)
	--庄家
	--self.m_spBanker:setVisible(isBanker)
	
end

function SitRoleNode:getChair(  )
	return self.m_wChair
end

--是否庄家
function SitRoleNode:updateBanker( isBanker )
	--庄家
	self.m_spBanker:setVisible(isBanker)
end

--金币动画、更新自己金币
function SitRoleNode:updateScore( useritem )
	if nil == useritem or nil == useritem.lScore then
		return
	end
	--金币
--[[	local str = ExternalFun.numberThousands(useritem.lScore)
	if string.len(str) > 11 then
		str = string.sub(str,1,11) .. "..."
	end--]]
	--local str = ExternalFun.formatScoreText(useritem.lScore);
	local ipLocation = useritem.szAdressLocation
	self.m_textScore:setString(ipLocation)
	
end

function SitRoleNode:gameEndScoreChange(changescore)
	self:updateScore(total)

	if 0 == changescore then
		return
	end

--[[	self.m_atlasScore:setOpacity(255)

	local str = "." .. ExternalFun.numberThousands(changescore)
	if string.len(str) > 10 then
		str = string.sub(str,1,10) .. "///"
	end
	if changescore >= 0 then
		self.m_atlasScore:setProperty(str, "game/atlas_add.png", 21, 30, ".")
	elseif changescore < 0 then
		self.m_atlasScore:setProperty(str, "game/atlas_sub.png", 21, 30, ".")
	end--]]
	local str = ExternalFun.formatScoreText(changescore)
	if changescore>0 then
		str = "＋"..str
	elseif changescore<0 then
		str = "－"..str
	else
		str = "0"
	end
	self.m_atlasScore:setVisible(true)
	self.m_atlasScore:setString(str)
	self.m_atlasScore:stopAllActions()
	self.m_atlasScore:setPositionY(-40)
	
	local moveAct = cc.MoveBy:create(1.0, cc.p(0, 50))
	local hideAct = cc.Hide:create()
	local scoreAct = cc.Sequence:create(moveAct, cc.DelayTime:create(2.0), hideAct)
	self.m_atlasScore:runAction(scoreAct)
	
end

function SitRoleNode:reSet(  )
	self.m_textScore:setString("")
	self.m_wChair = nil
end

return SitRoleNode