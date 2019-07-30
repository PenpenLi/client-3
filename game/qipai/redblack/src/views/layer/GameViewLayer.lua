local GameViewLayer = class("GameViewLayer",function(scene)
		local gameViewLayer =  display.newLayer()
    return gameViewLayer
end)
local module_pre = "game.qipai.redblack.src"

--external
--
local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")
local g_var = ExternalFun.req_var
local ClipText = appdf.EXTERNAL_SRC .. "ClipText"
local PopupInfoHead = appdf.EXTERNAL_SRC .. "PopupInfoHead"
--

local cmd = module_pre .. ".models.CMD_Game"
local game_cmd = appdf.HEADER_SRC .. "CMD_GameServer"
local QueryDialog   = require("app.views.layer.other.QueryDialog")

--utils
--
local UserListLayer = module_pre .. ".views.layer.userlist.UserListLayer"
local ApplyListLayer = module_pre .. ".views.layer.userlist.ApplyListLayer"
local SettingLayer = module_pre .. ".views.layer.SettingLayer"
local WallBillLayer = module_pre .. ".views.layer.WallBillLayer"
local SitRoleNode = module_pre .. ".views.layer.SitRoleNode"
local GameCardLayer = module_pre .. ".views.layer.GameCardLayer"
local GameResultLayer = module_pre .. ".views.layer.GameResultLayer"
local ControlLayer = module_pre..".views.layer.ControlLayer"
local GameRecordLayer = module_pre..".views.layer.GameRecordLayer"
local GameRuleLayer = module_pre..".views.layer.GameRuleLayer"
local GameQuewangLayer = module_pre..".views.layer.GameQuewangLayer"
--
local CardSprite = require(module_pre .. ".views.layer.gamecard.CardSprite")

GameViewLayer.TAG_START				= 100
local enumTable = 
{
	"BT_EXIT",
	"BT_START",
	"BT_LUDAN",
	"BT_BANK",
	"BT_SET",
	"BT_ROBBANKER",
	"BT_APPLYBANKER",
	"BT_USERLIST",
	"BT_APPLYLIST",
	"BANK_LAYER",
	"BT_CLOSEBANK",
	"BT_TAKESCORE",
	"BT_CONTROL",
	"BT_RULE",
	"BT_GUIZE"
}
local TAG_ENUM = ExternalFun.declarEnumWithTable(GameViewLayer.TAG_START, enumTable);
local zorders = 
{
	"CLOCK_ZORDER",
	"SITDOWN_ZORDER",
	"DROPDOWN_ZORDER",
	"DROPDOWN_CHECK_ZORDER",
	"GAMECARD_ZORDER",
	"SETTING_ZORDER",
	"ROLEINFO_ZORDER",
	"BANK_ZORDER",
	"USERLIST_ZORDER",
	"WALLBILL_ZORDER",
	"GAMERS_ZORDER",	
	"ENDCLOCK_ZORDER",
	"CONTROL_ZORDER",
	"GAMERECORD_ZORDER",
	"GAMERULE_ZORDER",
	"GAMEQUEWANG_ZORDER"
}
local TAG_ZORDER = ExternalFun.declarEnumWithTable(1, zorders);

local enumApply =
{
	"kCancelState",
	"kApplyState",
	"kApplyedState",
	"kSupperApplyed"
}

local jettonRepeatTag = 8
local jettonNoRepeatTag = 9
GameViewLayer._apply_state = ExternalFun.declarEnumWithTable(0, enumApply)
local APPLY_STATE = GameViewLayer._apply_state

--默认选中的筹码
local DEFAULT_BET = 1
--筹码运行时间
local BET_ANITIME = 0.2

local topCardPosition =
{
	cc.p(270, 670),
	cc.p(347, 670),
	cc.p(424, 670),
	cc.p(910, 670),
	cc.p(987, 670),
	cc.p(1064, 670)
}

local leftTrianglePos = 
{
	cc.p(420,397),
	cc.p(548,397),
	cc.p(420,292)
}

local rightTrianglePos = 
{
	cc.p(791,397),
	cc.p(920,397),
	cc.p(920,292)
}

local jettonPos1 = {
	cc.p(244,498),
	cc.p(663,193)
}

local jettonPos2 = {
	cc.p(420,397),
	cc.p(920,187)
}

local jettonPos3 = {
	cc.p(675,494),
	cc.p(1094,193)
}

function GameViewLayer:ctor(scene)
	--注册node事件
	ExternalFun.registerNodeEvent(self)
	
	self._scene = scene
	self:gameDataInit();

	--初始化csb界面
	self:initCsbRes();
	--初始化通用动作
	self:initAction();

	--点击事件
	self:setTouchEnabled(true)
	self:registerScriptTouchHandler(function(eventType, x, y)
		return self:onEventTouchCallback(eventType, x, y)
	end)
end

function GameViewLayer:loadRes(  )
	--加载卡牌纹理
	--cc.Director:getInstance():getTextureCache():addImage("game/card.png");
	cc.SpriteFrameCache:getInstance():addSpriteFrames("game/card.plist")
end

---------------------------------------------------------------------------------------
--界面初始化
function GameViewLayer:initCsbRes()
	-- 加载卡牌纹理
	cc.Director:getInstance():getTextureCache():addImage("game/card.png")
	local rootLayer, csbNode = ExternalFun.loadRootCSB("game/GameLayer.csb", self)
	self.m_rootNode = csbNode
	self.m_rootLayer = rootLayer
	--底部按钮
	local bottom_sp = csbNode:getChildByName("bottom_sp")
	self.m_spBottom = bottom_sp

	--初始化按钮
	self:initBtn(csbNode);

	--初始化庄家信息
	self:initBankerInfo();

	--初始化玩家信息
	self:initUserInfo();

	--初始化桌面下注
	self:initJetton(csbNode);

	--初始化座位列表
	self:initSitDownList(csbNode)

	--倒计时
	self:createClockNode()	
	
	--初始化游戏记录
	self:initGameRecord(csbNode)
	
	--游戏记录层
	self.m_gameRecordLayer = g_var(GameRecordLayer):create(self)
	self:addToRootLayer(self.m_gameRecordLayer, TAG_ZORDER.GAMERECORD_ZORDER)
	self.m_gameRecordLayer:setVisible(false)
	--规则层
	self.m_gameRuleLayer = g_var(GameRuleLayer):create(self)
	self:addToRootLayer(self.m_gameRuleLayer, TAG_ZORDER.GAMERULE_ZORDER)
	self.m_gameRuleLayer:setVisible(false)
	--雀王层(暂时不用，功能没做好)
	self.m_gameQueWangLayer = g_var(GameQuewangLayer):create(self)
	self:addToRootLayer(self.m_gameQueWangLayer, TAG_ZORDER.GAMEQUEWANG_ZORDER)
	self.m_gameQueWangLayer:setVisible(false)

	
--[[	--发牌的麻将
	local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("dragon_card_droptile_back.png")
	if nil ~= frame then
		for i=1, 4 do
			self.sp_card[i] = cc.Sprite:createWithSpriteFrame(frame);
			self:addChild(self.sp_card[i]);
			self.sp_card[i]:setVisible(false)
		end
	end--]]
	--等待图片
	self.m_pleaseWait = csbNode:getChildByName("Image_keeping");
	self.m_pleaseWait:setVisible(false)
	
	--自己结算数字
	self.m_selfResultFont = csbNode:getChildByName("selfResult_font");
	self.m_selfResultFont:setVisible(false)
	self.m_selfResultFont:setString("")
	
	--控制层
	self.m_controlLayer = g_var(ControlLayer):create(self)
	self:addChild(self.m_controlLayer, TAG_ZORDER.CONTROL_ZORDER)
	self.m_controlLayer:setVisible(false)
	
	for k,v in pairs(self:getParentNode():getUserList()) do
		self.m_controlLayer:setPlayerEnter(v.dwGameID,v.bAndroid)
    end
	
	--动画层
	local contSize = self.m_rootNode:getContentSize()
	-- 牌动画
	self.m_aniCardNode = ExternalFun.loadCSB("animate/Card.csb", rootLayer)
	self.m_endCardAni = ExternalFun.loadTimeLine("animate/Card.csb")
	self.m_aniCardNode:runAction(self.m_endCardAni)
	self.m_aniCardNode:move(cc.p(contSize.width/2,contSize.height/2))
	-- 开始押注动画
	self.m_aniStartNode = ExternalFun.loadCSB("animate/VS_Start.csb", rootLayer)
	self.m_startBetAni = ExternalFun.loadTimeLine("animate/VS_Start.csb")
	self.m_aniStartNode:runAction(self.m_startBetAni)
	self.m_aniStartNode:move(cc.p(contSize.width/2,contSize.height/2))
	-- 结束押注动画
	self.m_aniEndNode = ExternalFun.loadCSB("animate/End.csb", rootLayer)
	self.m_endBetAni = ExternalFun.loadTimeLine("animate/End.csb")
	self.m_aniEndNode:runAction(self.m_endBetAni)
	self.m_aniEndNode:move(cc.p(contSize.width/2,contSize.height/2))
	--结束发光动画
	self.m_aniAreaLightNode = ExternalFun.loadCSB("animate/Area_Light.csb", self.m_rootNode:getChildByName("win_ani_control"))
	self.m_aniAreaLightAni = ExternalFun.loadTimeLine("animate/Area_Light.csb")
	self.m_aniAreaLightNode:runAction(self.m_aniAreaLightAni)
	self.m_aniAreaLightNode:move(cc.p(contSize.width/2,contSize.height/2))
	self.m_aniAreaLightNode:setVisible(false)
	-- 初始化在线人数
	self.online_num_text = self.m_rootNode:getChildByName("top_control"):getChildByName("online_num_text")
	local userList = self:getDataMgr():getUserList()
	self.online_num_text:setString("当前共有" .. #userList .. "位玩家")
end

function GameViewLayer:reSet(  )
end

function GameViewLayer:reSetForNewGame(  )
	--重置下注区域
	self:cleanJettonArea()

	--闪烁停止
	self:jettonAreaBlinkClean()

	self:showGameResult(false)

	if nil ~= self.m_cardLayer then
		self.m_cardLayer:showLayer(false)
	end
end
--初始化游戏记录
function GameViewLayer:initGameRecord( csbNode )
	
	self.m_recordBg = csbNode:getChildByName("record_bg");
--[[	self.m_newRecordSymbol = self.m_recordBg:getChildByName("Image_newRecord");
	self.m_newRecordSymbol:setVisible(false)
	self.m_symbolPos = cc.p(self.m_newRecordSymbol:getPositionX(),self.m_newRecordSymbol:getPositionY())--]]
	--显示15条记录
	self.m_recordWin = {}
	self.m_recordWinType = {}
--	self.m_pointZhong = {}
--	self.m_pointBai = {}
	local str1 = ""
	local str2 = ""
	for i=1,15 do
		str1 = string.format("Sprite_win_%d", i)
		self.m_recordWin[i] = self.m_recordBg:getChildByName(str1)
		self.m_recordWin[i]:setVisible(false)
	end
	for i=1,7 do
		str2 = string.format("Sprite_win_type_%d", i)
		self.m_recordWinType[i] = self.m_recordBg:getChildByName(str2)
		self.m_recordWinType[i]:setVisible(false)
	end
end
--更新游戏记录
function GameViewLayer:updateGameRecord( )
	
	local vec = self:getDataMgr():getRecords()
	local len = #vec
	local nCount = 1
	local index = 1
	local str1 = ""
	local str2 = ""
	local str3 = ""
	local str4 = ""
	if len>14 then
		index = len - 14
	end
	
	for i = len,index,-1 do
		local rec = vec[i]
		self.m_recordWin[nCount]:setVisible(true)
		if g_var(cmd).AREA_BLACK == rec.m_cbGameResult then
			str1 = "h3card_pailu_black.png"
		else
			str1 = "h3card_pailu_red.png"
		end
		local frame1 = cc.SpriteFrameCache:getInstance():getSpriteFrame(str1)
		if nil ~= frame1 then			
			self.m_recordWin[nCount]:setSpriteFrame(frame1)
		end
		nCount = nCount+1
	end
	
	if len>6 then
		index = len - 6
	end
	 nCount = 1
	for i = len,index,-1 do
		local rec = vec[i]
		self.m_recordWinType[nCount]:setVisible(true)
		str2 = "record_type_" .. rec.m_pServerRecord.cbWinType .. ".png"
		local frame2 = cc.SpriteFrameCache:getInstance():getSpriteFrame(str2)
		if nil ~= frame2 then
			self.m_recordWinType[nCount]:setSpriteFrame(frame2)
		end
		nCount = nCount+1
	end
	if self.m_gameRecordLayer ~= nil and self.m_gameRecordLayer:isVisible() then
		self.m_gameRecordLayer:refreshRecordList()
	end
	
end
--初始化按钮
function GameViewLayer:initBtn( csbNode )
	------
	--切换checkbox
	local function checkEvent( sender,eventType )
		self:onCheckBoxClickEvent(sender, eventType);
	end
	local btnlist_check = csbNode:getChildByName("btnlist_check");
	self.m_btnCheck = btnlist_check;
	btnlist_check:addEventListener(checkEvent);
	btnlist_check:setSelected(false);
	btnlist_check:setLocalZOrder(TAG_ZORDER.DROPDOWN_CHECK_ZORDER)
	------


	------
	--按钮列表
	local function btnEvent( sender, eventType )
		if eventType == ccui.TouchEventType.ended then
			self:onButtonClickedEvent(sender:getTag(), sender);
		end
	end
	local btn_list = csbNode:getChildByName("sp_btn_list");
	self.m_btnList = btn_list;
	btn_list:setScaleY(0.0000001)
	btn_list:setLocalZOrder(TAG_ZORDER.DROPDOWN_ZORDER)
	
		--添加点击监听事件
	local node = btn_list
	local node_listener = cc.EventListenerTouchOneByOne:create()
	node_listener:setSwallowTouches(true)
	node_listener:registerScriptHandler(function(touch, event)
		return node:isVisible()
	end,cc.Handler.EVENT_TOUCH_BEGAN)
	--listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	node_listener:registerScriptHandler(function(touch, event)
		local pos = touch:getLocation()
		pos = node:convertToNodeSpace(pos)
		local rec = cc.rect(0, 0, node:getContentSize().width, node:getContentSize().height)
		if false == cc.rectContainsPoint(rec, pos) then
			--点击范围外响应
			self.m_btnList:stopAllActions();
			self.m_btnList:runAction(self.m_actDropOut);
            self.m_btnCheck:setVisible(true) 
			self.m_btnList:setVisible(false)
		end
		return true
	end,cc.Handler.EVENT_TOUCH_ENDED)
	self:getEventDispatcher():addEventListenerWithSceneGraphPriority(node_listener, node)
	

	--路单
	local btn = csbNode:getChildByName("record_bg"):getChildByName("ludan_btn")
	btn:setTag(TAG_ENUM.BT_LUDAN);
	btn:addTouchEventListener(btnEvent);
	
	--银行
	local btn = btn_list:getChildByName("bank_btn");
	btn:setTag(TAG_ENUM.BT_BANK);
	btn:addTouchEventListener(btnEvent);

	--设置
	btn = btn_list:getChildByName("set_btn");
	btn:setTag(TAG_ENUM.BT_SET);
	btn:addTouchEventListener(btnEvent);

	--离开
	btn = btn_list:getChildByName("back_btn");
	btn:setTag(TAG_ENUM.BT_EXIT);
	btn:addTouchEventListener(btnEvent);
	self.m_btnExit = btn;
	------
	--控制按钮
	btn = csbNode:getChildByName("Button_control");
	btn:setTag(TAG_ENUM.BT_CONTROL);
	btn:addTouchEventListener(btnEvent); 
	--规则按钮
	btn = csbNode:getChildByName("Button_rule");
	btn:setTag(TAG_ENUM.BT_RULE);
	btn:addTouchEventListener(btnEvent); 

	------
	--上庄、抢庄
	local banker_bg = csbNode:getChildByName("banker_bg");
	self.m_spBankerBg = banker_bg;
	self.m_spBankerBg:setVisible(false)
	--抢庄
--[[	btn = banker_bg:getChildByName("rob_btn");
	btn:setTag(TAG_ENUM.BT_ROBBANKER);
	btn:addTouchEventListener(btnEvent);
	self.m_btnRob = btn;
	self.m_btnRob:setEnabled(false);
	self.m_btnRob:setVisible(false);--]]

	--上庄列表
	btn = banker_bg:getChildByName("apply_btn");
	btn:setTag(TAG_ENUM.BT_APPLYLIST);
	btn:addTouchEventListener(btnEvent);	
	self.m_btnApply = btn;
	btn:setVisible(false)
	self.m_btnApply:setVisible(false)
	------

	--玩家列表
	btn = self.m_spBottom:getChildByName("userlist_btn")
	btn:setTag(TAG_ENUM.BT_USERLIST)
	btn:addTouchEventListener(btnEvent)
	
	btn = csbNode:getChildByName("btn_guize")
	btn:setTag(TAG_ENUM.BT_GUIZE)
	btn:addTouchEventListener(btnEvent)
	
	self.image_guize = self.m_rootNode:getChildByName("image_guize")
	self.image_guize:setVisible(false)
	--添加点击监听事件
	local node = self.image_guize
	local node_listener = cc.EventListenerTouchOneByOne:create()
	node_listener:setSwallowTouches(true)
	node_listener:registerScriptHandler(function(touch, event)
		return node:isVisible()
	end,cc.Handler.EVENT_TOUCH_BEGAN)
	--listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	node_listener:registerScriptHandler(function(touch, event)
		local pos = touch:getLocation()
		pos = node:convertToNodeSpace(pos)
		local rec = cc.rect(0, 0, node:getContentSize().width, node:getContentSize().height)
		if false == cc.rectContainsPoint(rec, pos) then
			--点击范围外响应
			self.image_guize:setVisible(false)
		end
		return true
	end,cc.Handler.EVENT_TOUCH_ENDED)
	self:getEventDispatcher():addEventListenerWithSceneGraphPriority(node_listener, node)
	
	-- 帮助按钮 gameviewlayer -> gamelayer -> clientscene
--[[    local url = BaseConfig.WEB_HTTP_URL .. "/Mobile/Introduce.aspx?kindid=122&typeid=0"
    self:getParentNode():getParentNode():createHelpBtn(cc.p(1287, 620), 0, url, csbNode)--]]
end

--设置请等待图片是否可见
function GameViewLayer:setIsShowWait()
	if self.m_lHaveJetton > 0 then
		self.m_pleaseWait:setVisible(false)
	else
		self.m_pleaseWait:setVisible(true)
	end
end

--设置退出按钮是否可用
function GameViewLayer:setExitEnabled(bEnable)
	if self.m_lHaveJetton > 0 then
		self.m_btnExit:setEnabled(bEnable)
	elseif true == self:isMeChair(self.m_wBankerUser) then
		self.m_btnExit:setEnabled(false)
	else
		self.m_btnExit:setEnabled(true)
	end

end
--初始化庄家信息
function GameViewLayer:initBankerInfo( ... )
	local banker_bg = self.m_spBankerBg;
	--庄家姓名
	local tmp = banker_bg:getChildByName("name_text");
	tmp:setString("");
	self.m_clipBankerNick = tmp;
--[[	self.m_clipBankerNick = g_var(ClipText):createClipText(tmp:getContentSize(), "");
	self.m_clipBankerNick:setAnchorPoint(tmp:getAnchorPoint());
	self.m_clipBankerNick:setPosition(tmp:getPosition());
	banker_bg:addChild(self.m_clipBankerNick);--]]

	--庄家金币
	self.m_textBankerCoin = banker_bg:getChildByName("bankercoin_text");

	self:reSetBankerInfo();
	
end

function GameViewLayer:reSetBankerInfo(  )
	self.m_clipBankerNick:setString("");
	self.m_textBankerCoin:setString("");
end

--初始化玩家信息
function GameViewLayer:initUserInfo(  )	
	--玩家头像
	local tmp = self.m_spBottom:getChildByName("player_head")
	--local head = g_var(PopupInfoHead):createNormalCircle(self:getMeUserItem(), tmp:getContentSize().width)
	local head = g_var(PopupInfoHead):createNormalCircle(self:getMeUserItem(), 80,("Circleframe.png"))
	head:setPosition(tmp:getPositionX(),tmp:getPositionY())
	self.m_spBottom:addChild(head)
	head:enableInfoPop(true)

	--玩家金币
	self.m_textUserCoint = self.m_spBottom:getChildByName("coin_text")
	--玩家ID
	self.m_textUserID = self.m_spBottom:getChildByName("ID_text")
	self.m_textUserID:setString("")
	
	self:reSetUserInfo()
end

function GameViewLayer:reSetUserInfo(  )
	self.m_scoreUser = 0
	local myUser = self:getMeUserItem()
	if nil ~= myUser then
		self.m_scoreUser = myUser.lScore;
	end	
	print("自己金币:" .. ExternalFun.formatScore(self.m_scoreUser))
	local str = string.format("%.2f",self.m_scoreUser)
	self.m_textUserCoint:setString(str);
	
	local szNick = ""
	if nil ~= myUser.dwGameID then
		szNick = myUser.dwGameID
	end
	self.m_textUserID:setString("ID:"..szNick);
end

--初始化桌面下注
function GameViewLayer:initJetton( csbNode )
	local bottom_sp = self.m_spBottom;
	------
	--下注按钮	
	local clip_layout = bottom_sp:getChildByName("clip_layout");
	self.m_layoutClip = clip_layout;
	self:initJettonBtnInfo();
	------

	------
	--下注区域
	self:initJettonArea(csbNode);
	------

	-----
	--下注胜利提示
	-----
	self:initJettonSp(csbNode);
end

function GameViewLayer:enableJetton( var )
	--下注按钮
	self:reSetJettonBtnInfo(var);

	--下注区域
	self:reSetJettonArea(var);
end

--下注按钮
function GameViewLayer:initJettonBtnInfo(  )
	local clip_layout = self.m_layoutClip;

	local function clipEvent( sender, eventType )
		if eventType == ccui.TouchEventType.ended then
			self:onJettonButtonClicked(sender:getTag(), sender);
		end
	end

	self.m_pJettonNumber = 
	{
--		{k = 100, i = 2},
		{k = 1, i = 3}, 
		{k = 5, i = 4}, 
		{k = 10, i = 5}, 
		{k = 50, i = 6},
		{k = 100, i = 7},
		{k = 500, i = 8} 
	}
	self.m_tabJettonAnimate = {}
	for i=1,#self.m_pJettonNumber do
		local tag = i - 1
		local str = string.format("chip%d_btn", tag)
		local btn = clip_layout:getChildByName(str)
		btn:setTag(i)
		btn:addTouchEventListener(clipEvent)
		self.m_tableJettonBtn[i] = btn

		str = string.format("chip%d", tag)
		self.m_tabJettonAnimate[i] = clip_layout:getChildByName(str)
	end
	self.chip_repeat_btn_0 = clip_layout:getChildByName("chip_repeat_btn_0")
	self.chip_repeat_btn_1 = clip_layout:getChildByName("chip_repeat_btn_1")
	self:setRepeat(false)
	self.chip_repeat_btn_0:setTag(jettonRepeatTag)
	self.chip_repeat_btn_1:setTag(jettonNoRepeatTag)
	self.chip_repeat_btn_0:addTouchEventListener(clipEvent)
	self.chip_repeat_btn_1:addTouchEventListener(clipEvent)
	self:reSetJettonBtnInfo(false);
end

function GameViewLayer:setRepeat(isEnable)
	self.chip_repeat_btn_0:setVisible(not isEnable)
	self.chip_repeat_btn_0:setEnabled(not isEnable)
	self.chip_repeat_btn_1:setVisible(isEnable)
	self.chip_repeat_btn_1:setEnabled(isEnable)
end

function GameViewLayer:reSetJettonBtnInfo( var )
	for i=1,#self.m_tableJettonBtn do
		self.m_tableJettonBtn[i]:setTag(i)
		self.m_tableJettonBtn[i]:setEnabled(var)

		self.m_tabJettonAnimate[i]:stopAllActions()
		self.m_tabJettonAnimate[i]:setVisible(false)
	end
end

function GameViewLayer:adjustJettonBtn(  )
	--可以下注的数额
	local lCanJetton = self.m_llMaxJetton - self.m_lHaveJetton;
	local lCondition = math.min(self.m_scoreUser, lCanJetton);

	for i=1,#self.m_tableJettonBtn do
		local enable = false
		if self.m_bOnGameRes then
			enable = false
		else
			enable = self.m_bOnGameRes or (lCondition >= self.m_pJettonNumber[i].k)
		end
		self.m_tableJettonBtn[i]:setEnabled(enable);
	end

	if self.m_nJettonSelect > self.m_scoreUser then
		self.m_nJettonSelect = -1;
	end

	--筹码动画
	local enable = lCondition >= self.m_pJettonNumber[self.m_nSelectBet].k;
	if false == enable then
		self.m_tabJettonAnimate[self.m_nSelectBet]:stopAllActions()
		self.m_tabJettonAnimate[self.m_nSelectBet]:setVisible(false)
	end
end
--更新用户显示
function GameViewLayer:OnUpdateUserStatus(viewId)
	
end
function GameViewLayer:refreshJetton(  )
	local str = ExternalFun.numberThousands(self.m_lHaveJetton)
	self.m_clipJetton:setString(str)
	--self.m_userJettonLayout:setVisible(self.m_lHaveJetton > 0)
	self.m_userJettonLayout:setVisible(false)
end

function GameViewLayer:switchJettonBtnState( idx )
	for i=1,#self.m_tabJettonAnimate do
		self.m_tabJettonAnimate[i]:stopAllActions()
		self.m_tabJettonAnimate[i]:setVisible(false)
	end

	--可以下注的数额
	local lCanJetton = self.m_llMaxJetton - self.m_lHaveJetton;
	local lCondition = math.min(self.m_scoreUser, lCanJetton);
	if nil ~= idx and nil ~= self.m_tabJettonAnimate[idx] then
		local enable = lCondition >= self.m_pJettonNumber[idx].k;
		if enable then
			local blink = cc.Blink:create(1.0,1)
			self.m_tabJettonAnimate[idx]:runAction(cc.RepeatForever:create(blink))
		end		
	end
	--防止选中下注筹码开牌阶段还会闪
	if self.m_bOnGameRes == true then
		for i=1,#self.m_tabJettonAnimate do
			self.m_tabJettonAnimate[i]:stopAllActions()
			self.m_tabJettonAnimate[i]:setVisible(false)		
		end
	end
	
end

--下注筹码结算动画
function GameViewLayer:betAnimation( )
	local cmd_gameend = self:getDataMgr().m_tabGameEndCmd
	if nil == cmd_gameend then
		return
	end

	local tmp = self.m_betAreaLayout:getChildren()

	--数量控制
	local maxCount = 300
	local count = 0
	local children = {}
	for k,v in pairs(tmp) do
		table.insert(children, v)
		count = count + 1
		if count > maxCount then
			break
		end
	end
	local left = {}
	print("bankerscore:" .. ExternalFun.formatScore(cmd_gameend.lBankerScore))
	print("selfscore:" .. ExternalFun.formatScore(cmd_gameend.lPlayAllScore))

	--庄家的
	local call = cc.CallFunc:create(function()
		left = self:userBetAnimation(children, "banker", cmd_gameend.lBankerScore)
	end)
	local delay = cc.DelayTime:create(0.5)

	--自己的
	local meChair =  self:getMeUserItem().wChairID
	local call2 = cc.CallFunc:create(function()		
		left = self:userBetAnimation(left, meChair, cmd_gameend.lPlayAllScore)
		
		if true == self:getDataMgr().m_bJoin then
			local score = cmd_gameend.lPlayAllScore
			if score<0 then
				score = -score
			end
			local str = string.format("%.2f",score)
			if cmd_gameend.lPlayAllScore>0 then
				str = "＋"..str
			elseif cmd_gameend.lPlayAllScore<0 then				
				str = "－"..str
			else
				str = "0"
			end
			self.m_selfResultFont:setString(str)
			self.m_selfResultFont:stopAllActions()
			self.m_selfResultFont:setVisible(true)
			self.m_selfResultFont:setPositionY(55)
			--飞行动画
			local moveAct = cc.MoveBy:create(1.0, cc.p(0, 100))
			local hideAct = cc.Hide:create()
			local scoreAct = cc.Sequence:create(moveAct, cc.DelayTime:create(2.0), hideAct)
			self.m_selfResultFont:runAction(scoreAct)
		end
	end)	
	local delay2 = cc.DelayTime:create(0.5)

	--坐下的
--[[	local call3 = cc.CallFunc:create(function()
		for i = 1, g_var(cmd).MAX_OCCUPY_SEAT_COUNT do
			if nil ~= self.m_tabSitDownUser[i] then
				--非自己
				local chair = self.m_tabSitDownUser[i]:getChair()
				local score = cmd_gameend.lOccupySeatUserWinScore[1][i]
				if meChair ~= chair then
					left = self:userBetAnimation(left, chair, cmd_gameend.lOccupySeatUserWinScore[1][i])
				end

				local useritem = self:getDataMgr():getChairUserList()[chair + 1]
				--金币动画
				self.m_tabSitDownUser[i]:gameEndScoreChange(useritem, score)

			end
		end
	end)--]]
	local call3 = cc.CallFunc:create(function()
		for i = 1, g_var(cmd).MAX_OCCUPY_SEAT_COUNT do
			if nil ~= self.m_rankTopUser[i] then
				--非自己
				local chair = self.m_rankTopUser[i]
				local score = cmd_gameend.lAllPlayerScore[1][chair+1]	
				if meChair ~= chair and score then
					left = self:userBetAnimation(left, chair, score)
					--数字动画
					local str = string.format("%.2f",score)
					if score>0 then
						str = "＋"..str
					elseif score<0 then
						score = -score
						str = string.format("%.2f",score)
						str = "－"..str
					else
						str = ""
					end
	
					self.m_resultFont[i]:setString(str)
					self.m_resultFont[i]:stopAllActions()
					self.m_resultFont[i]:setVisible(true)
					self.m_resultFont[i]:setPositionY(-50)
					
					--飞行动画
					local moveAct = cc.MoveBy:create(1.0, cc.p(0, 100))
					local hideAct = cc.Hide:create()
					local scoreAct = cc.Sequence:create(moveAct, cc.DelayTime:create(2.0), hideAct)
					self.m_resultFont[i]:runAction(scoreAct)
				end
			end
		end
	end)
	local delay3 = cc.DelayTime:create(0.5)	

	--其余玩家的
	local call4 = cc.CallFunc:create(function()
		self:userBetAnimation(left, "other", 1)
	end)

	--剩余没有移走的
	local call5 = cc.CallFunc:create(function()
		--下注筹码数量显示移除
		self:cleanJettonArea()
	end)

	local seq = cc.Sequence:create(call, delay, call2, call3, delay3, call4, cc.DelayTime:create(2), call5)
	self:stopAllActions()
	self:runAction(seq)	
end

--玩家分数
function GameViewLayer:userBetAnimation( children, wchair, score )
	if nil == score or score <= 0 then
		return children
	end

	local left = {}
	local getScore = score
	local tmpScore = 0
	local totalIdx = #self.m_pJettonNumber
	local winSize = self.m_betAreaLayout:getContentSize()
	local remove = true
	local count = 0
	for k,v in pairs(children) do
		local idx = nil

		if remove then
			if nil ~= v and v:getTag() == wchair then
				idx = tonumber(v:getName())
				
				local pos = self.m_betAreaLayout:convertToNodeSpace(self:getBetFromPos(wchair))
				self:generateBetAnimtion(v, {x = pos.x, y = pos.y}, count)
				
				
				if nil ~= idx and nil ~= self.m_pJettonNumber[idx] then
					tmpScore = tmpScore + self.m_pJettonNumber[idx].k
				end

				if tmpScore >= score then
					remove = false
				end
			elseif yl.INVALID_CHAIR == wchair then
				--随机抽下注筹码
				idx = self:randomGetBetIdx(getScore, totalIdx)

				local pos = self.m_betAreaLayout:convertToNodeSpace(self:getBetFromPos(wchair))

				if nil ~= idx and nil ~= self.m_pJettonNumber[idx] then
					tmpScore = tmpScore + self.m_pJettonNumber[idx].k
					getScore = getScore - tmpScore
				end

				if tmpScore >= score then
					remove = false
				end
			elseif "banker" == wchair then
				--随机抽下注筹码
				idx = self:randomGetBetIdx(getScore, totalIdx)

				local pos = cc.p(self.m_textBankerCoin:getPositionX(), self.m_textBankerCoin:getPositionY())
				pos = self.m_textBankerCoin:convertToWorldSpace(pos)
				pos = self.m_betAreaLayout:convertToNodeSpace(pos)
				self:generateBetAnimtion(v, {x = pos.x, y = pos.y}, count)
			
				
				if nil ~= idx and nil ~= self.m_pJettonNumber[idx] then
					tmpScore = tmpScore + self.m_pJettonNumber[idx].k
					getScore = getScore - tmpScore
				end

				if tmpScore >= score then
					remove = false
				end
			elseif "other" == wchair then
				self:generateBetAnimtion(v, {x = winSize.width-60, y = 56}, count)
				
			else
				table.insert(left, v)
			end
		else
			table.insert(left, v)
		end	
		count = count + 1	
	end
	return left
end

function GameViewLayer:generateBetAnimtion( bet, pos, count)
	--筹码动画	
	local moveTo = cc.MoveTo:create(BET_ANITIME, cc.p(pos.x, pos.y))
	local call = cc.CallFunc:create(function ( )
		bet:removeFromParent()
	end)
	bet:stopAllActions()

	bet:runAction(cc.Sequence:create(cc.DelayTime:create(0.05 * count),moveTo, call))
	ExternalFun.playSoundEffect("on_bet.mp3")
end

function GameViewLayer:randomGetBetIdx( score, totalIdx )
	if score > self.m_pJettonNumber[1].k and score < self.m_pJettonNumber[2].k then
		return math.random(1,2)
	elseif score > self.m_pJettonNumber[2].k and score < self.m_pJettonNumber[3].k then
		return math.random(1,3)
	elseif score > self.m_pJettonNumber[3].k and score < self.m_pJettonNumber[4].k then
		return math.random(1,4)
	else
		return math.random(totalIdx)
	end	
end

--下注区域
function GameViewLayer:initJettonArea( csbNode )
	local tag_control = csbNode:getChildByName("tag_control");
	self.m_tagControl = tag_control

	--筹码区域
	self.m_betAreaLayout = tag_control:getChildByName("bet_area")

	--按钮列表
	local function btnEvent( sender, eventType )
		if eventType == ccui.TouchEventType.ended then
			self:onJettonAreaClicked(sender:getTag(), sender)
		end
	end	

	for i=1,3 do
		local tag = i - 1
		local str = string.format("tag%d_btn", tag)
		local tag_btn = tag_control:getChildByName(str)
		for k,v in pairs(tag_btn:getChildByName("btn"):getChildren()) do
			v:setTag(i)
			v:addTouchEventListener(btnEvent)
		end
		self.m_tableJettonArea[i] = tag_btn
	end
	

	--下注信息
	local m_userJettonLayout = csbNode:getChildByName("jetton_control");
	local infoSize = m_userJettonLayout:getContentSize()
	local text = ccui.Text:create("本次下注为:", "base/round_body.ttf", 20)
	text:setAnchorPoint(cc.p(1.0,0.5))
	text:setPosition(cc.p(infoSize.width * 0.495, infoSize.height * 0.19))
	m_userJettonLayout:addChild(text)
	m_userJettonLayout:setVisible(false)

	local m_clipJetton = g_var(ClipText):createClipText(cc.size(120, 23), "")
	m_clipJetton:setPosition(cc.p(infoSize.width * 0.5, infoSize.height * 0.19))
	m_clipJetton:setAnchorPoint(cc.p(0,0.5));
	m_clipJetton:setTextColor(cc.c4b(255,165,0,255))
	m_userJettonLayout:addChild(m_clipJetton)

	self.m_userJettonLayout = m_userJettonLayout;
	self.m_clipJetton = m_clipJetton;

	self:reSetJettonArea(false);
end

function GameViewLayer:reSetJettonArea( var )
	for i=1,#self.m_tableJettonArea do
		for k,v in pairs(self.m_tableJettonArea[i]:getChildByName("btn"):getChildren()) do
			v:setEnabled(var)
		end
	end
end

function GameViewLayer:cleanJettonArea(  )
	--移除界面已下注
	self:stopAllActions()
	self.m_betAreaLayout:removeAllChildren()
		
	for i=1,#self.m_tableJettonArea do
		if nil ~= self.m_tableJettonNode[i] then
			--self.m_tableJettonNode[i]:reSet()
			self:reSetJettonNode(self.m_tableJettonNode[i],self.m_tagControl:getChildByName("tag_text_"..(i-1)))
		end
	end
	self.m_userJettonLayout:setVisible(false)
	self.m_clipJetton:setString("")
	
	if self.m_controlLayer ~=nil then
		self.m_controlLayer:cleanAreaBet()
	end	
		
end

--下注胜利提示
function GameViewLayer:initJettonSp( csbNode )
	self.m_tagSpControls = {};
	local sp_control = csbNode:getChildByName("tag_sp_control");
	for i=1,3 do
		local tag = i - 1;
		local str = string.format("tagsp_%d", tag);
		local tagsp = sp_control:getChildByName(str);
		self.m_tagSpControls[i] = tagsp;
	end

	self:reSetJettonSp();
end

function GameViewLayer:reSetJettonSp(  )
	for i=1,#self.m_tagSpControls do
		self.m_tagSpControls[i]:setVisible(false);
	end
end

--胜利区域闪烁
function GameViewLayer:jettonAreaBlink( tabArea )
	for i = 1, #tabArea do
		local score = tabArea[i]
		if score > 0 then
			local rep = cc.RepeatForever:create(cc.Blink:create(1.0,1))
			self.m_tagSpControls[i]:runAction(rep)
		end
	end
end

function GameViewLayer:jettonAreaBlinkClean(  )
	for i = 1, g_var(cmd).AREA_MAX do
		self.m_tagSpControls[i]:stopAllActions()
		self.m_tagSpControls[i]:setVisible(false)
	end
end

--座位列表
function GameViewLayer:initSitDownList( csbNode )
	local m_roleSitDownLayer = csbNode:getChildByName("role_control")
	self.m_roleSitDownLayer = m_roleSitDownLayer
	
	self.m_roleSitDownLayer:setVisible(false)
	--按钮列表
	local function btnEvent( sender, eventType )
		if eventType == ccui.TouchEventType.ended then
			self:onSitDownClick(sender:getTag(), sender);
		end
	end

	local str = ""
	for i=1,g_var(cmd).MAX_OCCUPY_SEAT_COUNT do
		str = string.format("sit_btn_%d", i)
		self.m_tabSitDownList[i] = m_roleSitDownLayer:getChildByName(str)
		self.m_tabSitDownList[i]:setTag(i)
		self.m_tabSitDownList[i]:addTouchEventListener(btnEvent);
	end	
	
	local betRankLayer = csbNode:getChildByName("role_control_rank")
	--betRankLayer:setVisible(false)
	self.m_betRankLayer = betRankLayer
	local str = ""
	for i=1,g_var(cmd).MAX_OCCUPY_SEAT_COUNT do
		str = string.format("totle_bet_%d", i)
		self.m_rankTopNode[i] = betRankLayer:getChildByName(str)
		self.m_rankTopNode[i]:setTag(i)
		self.m_rankTopNode[i]:setVisible(false)
		self.m_resultFont[i] = self.m_rankTopNode[i]:getChildByName("result_font")
		self.m_resultFont[i]:setString("")
		self.m_resultFont[i]:setLocalZOrder(3)
	end
	--雀王
	self.m_queWangUser = csbNode:getChildByName("que_wang")
	self.m_queWangUser:setVisible(false)
	self.m_queWangBg = self.m_queWangUser:getChildByName("Image_bg")
	
end
--更新排名座位玩家
function GameViewLayer:updateRankSitUser()
	
	local userList = self:getDataMgr():getUserList()
	self.online_num_text:setString("当前共有" .. #userList .. "位玩家")
	local lRankScore = {}
	local chairid = {}
	
	local ncount = 1
	for i = 1, #userList do
		if userList[i] ~= nil and userList[i].wChairID ~= yl.INVALID_CHAIR then
			chairid[ncount] = userList[i].wChairID
			lRankScore[ncount] = self:getDataMgr():getChairUserList()[chairid[ncount] + 1].lScore
			ncount = ncount + 1
		end
	end
	--排序操作
	--table.sort(userList, function(a,b) return a.lScore >= b.lScore end)
	
	--排序操作
	local bSorted = true;
	local cbLast = (ncount-1) - 1;
	repeat
		bSorted = true;
		for i=1,cbLast do
			if lRankScore[i] < lRankScore[i+1] then
				--设置标志
				bSorted = false;
				--排序权位
				lRankScore[i], lRankScore[i + 1] = lRankScore[i + 1], lRankScore[i];
				chairid[i],chairid[i + 1] = chairid[i + 1], chairid[i];
			end
		end
		cbLast = cbLast - 1;
	until bSorted ~= false
	
	for i=1, g_var(cmd).MAX_OCCUPY_SEAT_COUNT do
		--清除头像
		if nil ~= self.m_rankHead[i] then
			self.m_rankHead[i]:removeFromParent()
			self.m_rankHead[i] = nil
		end

		local item = nil
		local chair = chairid[i]
		if chair ~= nil and chair ~= yl.INVALID_CHAIR then
			item = self:getDataMgr():getChairUserList()[chair + 1]
		end

		if item ~= nil then
			self.m_rankTopUser[i] = item.wChairID
			self.m_rankTopNode[i]:setVisible(true)
			
			local tmp = self.m_rankTopNode[i]:getChildByName("head_frame")
			local head = g_var(PopupInfoHead):createNormal(item, 60)
			if head ~= nil then
				head:setPosition(tmp:getPositionX(),tmp:getPositionY())
				self.m_rankTopNode[i]:addChild(head)
				
				local size = cc.Director:getInstance():getWinSize()
				local pos = cc.p(self.m_rankTopNode[i]:getPositionX(),self.m_rankTopNode[i]:getPositionY())
				local anchor = cc.p(0, 0)
				if i>4 then
					anchor = cc.p(1, 0)
					pos = cc.p(self.m_rankTopNode[i]:getPositionX()-400,self.m_rankTopNode[i]:getPositionY())
				end
				head:enableInfoPop(true,pos,anchor)
			end
			self.m_rankHead[i] = head
			
			local sp_rank = self.m_rankTopNode[i]:getChildByName("Sprite_rank")
			sp_rank:setLocalZOrder(2)
			
			local nickName = self.m_rankTopNode[i]:getChildByName("Text_name")
			local lScore = self.m_rankTopNode[i]:getChildByName("Text_score")
			local strName = ""
			if nil ~= item.dwGameID then
				strName = item.dwGameID
			end
			nickName:setString("ID:"..strName)
			lScore:setString(item.szAdressLocation)
			
		else
			self.m_rankTopNode[i]:setVisible(false)
		end
	end
end

function GameViewLayer:initAction(  )
	local dropIn = cc.ScaleTo:create(0.2, 1.0);
	dropIn:retain();
	self.m_actDropIn = dropIn;

	local dropOut = cc.ScaleTo:create(0.2, 1.0, 0.0000001);
	dropOut:retain();
	self.m_actDropOut = dropOut;
end
---------------------------------------------------------------------------------------

function GameViewLayer:onButtonClickedEvent(tag,ref)
	ExternalFun.playClickEffect()
	if tag == TAG_ENUM.BT_EXIT then
		self:getParentNode():onQueryExitGame()
	elseif tag == TAG_ENUM.BT_START then
		self:getParentNode():onStartGame()
	elseif tag == TAG_ENUM.BT_USERLIST then
		if nil == self.m_userListLayer then
			self.m_userListLayer = g_var(UserListLayer):create(self)
			self:addToRootLayer(self.m_userListLayer, TAG_ZORDER.USERLIST_ZORDER)
		end
		local userList = self:getDataMgr():getUserList()
		--刷新座位玩家
--		self:updateRankSitUser()
	
		self.m_userListLayer:refreshList(userList)
		self.online_num_text:setString("当前共有" .. #userList .. "位玩家")
		
	elseif tag == TAG_ENUM.BT_APPLYLIST then
		if nil == self.m_applyListLayer then
			self.m_applyListLayer = g_var(ApplyListLayer):create(self)
			self:addToRootLayer(self.m_applyListLayer, TAG_ZORDER.USERLIST_ZORDER)
		end
		local userList = self:getDataMgr():getApplyBankerUserList()		
		self.m_applyListLayer:refreshList(userList)
		self.online_num_text:setString("当前共有" .. #userList .. "位玩家")
		--上庄条件
		self.m_applyListLayer:setBankerCondition(self.m_llCondition);
	
	elseif tag == TAG_ENUM.BT_BANK then
		--银行未开通
		if 0 == GlobalUserItem.cbInsureEnabled then
			showToast(self,"初次使用，请先开通银行！",1)
			return
		end

		if nil == self.m_cbGameStatus or g_var(cmd).GAME_PLAY == self.m_cbGameStatus then
			showToast(self,"游戏过程中不能进行银行操作",1)
			return
		end

		--房间规则
		local rule = self:getParentNode()._roomRule
		if rule == yl.GAME_GENRE_SCORE 
		or rule == yl.GAME_GENRE_EDUCATE then 
			print("练习 or 积分房")
		end
		if false == self:getParentNode():getFrame():OnGameAllowBankTake() then
			--showToast(self,"不允许银行取款操作操作",1)
			--return
		end

		if nil == self.m_bankLayer then
			self:createBankLayer()
		end
		self.m_bankLayer:setVisible(true)
		self:refreshScore()
	elseif tag == TAG_ENUM.BT_SET then
		local setting = g_var(SettingLayer):create()
		self:addToRootLayer(setting, TAG_ZORDER.SETTING_ZORDER)
		--版本号		
		local function asyncUpdateVersion(version)
			local strVersion = "游戏版本："..BaseConfig.BASE_C_VERSION.."."..version
			setting:setVersion(strVersion)
		end
		local customEvent = cc.EventCustom:new(yl.RY_GET_GAME_VERSION_NOTIFY)
		customEvent.obj = {KindID = g_var(cmd).KIND_ID, callback = asyncUpdateVersion}
		cc.Director:getInstance():getEventDispatcher():dispatchEvent(customEvent)

		
	elseif tag == TAG_ENUM.BT_LUDAN then
		if nil == self.m_wallBill then
			self.m_wallBill = g_var(WallBillLayer):create(self)
			self:addToRootLayer(self.m_wallBill, TAG_ZORDER.WALLBILL_ZORDER)
		end
		self.m_wallBill:refreshWallBillList()
	elseif tag == TAG_ENUM.BT_ROBBANKER then
		--超级抢庄
		if g_var(cmd).SUPERBANKER_CONSUMETYPE == self.m_tabSupperRobConfig.superbankerType then
			local str = "超级抢庄将花费 " .. self.m_tabSupperRobConfig.lSuperBankerConsume .. ",确定抢庄?"
			local query = QueryDialog:create(str, function(ok)
		        if ok == true then
		            self:getParentNode():sendRobBanker()
		        end
		    end):setCanTouchOutside(false)
		        :addTo(self) 
		else
			self:getParentNode():sendRobBanker()
		end
	elseif tag == TAG_ENUM.BT_CLOSEBANK then
		if nil ~= self.m_bankLayer then
			self.m_bankLayer:setVisible(false)
		end
	elseif tag == TAG_ENUM.BT_TAKESCORE then
		self:onTakeScore()
	elseif tag == TAG_ENUM.BT_CONTROL then
		if self.m_bIsGameCheatUser == false then
			return
		else
			if nil ~= self.m_controlLayer then
				self.m_controlLayer:setVisible(true)
			end
		end
	elseif tag == TAG_ENUM.BT_RULE then
		if self.m_gameRuleLayer ~= nil then
			self.m_gameRuleLayer:setVisible(true)
		end
	elseif tag == TAG_ENUM.BT_GUIZE then
		self.image_guize:setVisible(true)
	else
		showToast(self,"功能尚未开放！",1)
	end
end

function GameViewLayer:onJettonButtonClicked( tag, ref )
	if tag == jettonRepeatTag or tag == jettonNoRepeatTag then
		local isEnable = false
		if tag == jettonRepeatTag then
			isEnable = true
		end
		self:setRepeat(isEnable)
		return
	end
	if tag >= 1 and tag <= 7 then
		self.m_nJettonSelect = self.m_pJettonNumber[tag].k;
	else
		self.m_nJettonSelect = -1;
	end

	self.m_nSelectBet = tag
	self:switchJettonBtnState(tag)
	print("click jetton:" .. self.m_nJettonSelect);
end

function GameViewLayer:onJettonAreaClicked( tag, ref )

	local m_nJettonSelect = self.m_nJettonSelect;

	if m_nJettonSelect < 0 then
 		return;
	end

	local area = tag - 1;	
	if self.m_lHaveJetton > self.m_llMaxJetton then
		showToast(self,"已超过最大下注限额",1)
		self.m_lHaveJetton = self.m_lHaveJetton - m_nJettonSelect;
		return;
	end
	
	local userself = self:getMeUserItem() 
	if userself and userself.lScore < self.lBottomPourImpose  then
		showToast(self, "真遗憾!玩家金币大于 " .. self.lBottomPourImpose .. " 才可以下注!", 1)
        return
	end

	--下注
	self:getParentNode():sendUserBet(area, m_nJettonSelect);	
end

function GameViewLayer:showGameResult( bShow )
	if true == bShow then
		if nil == self.m_gameResultLayer then
			self.m_gameResultLayer = g_var(GameResultLayer):create()
			self:addToRootLayer(self.m_gameResultLayer, TAG_ZORDER.GAMERS_ZORDER)
		end

		if true == bShow --[[and true == self:getDataMgr().m_bJoin--]] then
			local cmd_gameend = self:getDataMgr().m_tabGameEndCmd
			if cmd_gameend == nil then
				return
			end
			local allPlayerScore = {}
			local maxWinSocer = 0;
			local maxWinner = -1;
			for i=1, g_var(cmd).GAME_PLAYER do
				allPlayerScore[i] = cmd_gameend.lAllPlayerScore[1][i]
				if allPlayerScore[i]>maxWinSocer then
					maxWinSocer = allPlayerScore[i]
					maxWinner = i
				end
			end
			local useritem = self:getDataMgr():getChairUserList()[maxWinner]
			if useritem ~= nil then
				self.m_gameResultLayer:showGameResult(useritem,maxWinSocer)
			end
		end
	else
		if nil ~= self.m_gameResultLayer then
			self.m_gameResultLayer:hideGameResult()
		end
	end
end

function GameViewLayer:onCheckBoxClickEvent( sender,eventType )
	ExternalFun.playClickEffect()
	self.m_btnList:stopAllActions();
	self.m_btnList:runAction(self.m_actDropIn);
	self.m_btnCheck:setVisible(false);
	self.m_btnList:setVisible(true)
end

function GameViewLayer:onSitDownClick( tag, sender )
	print("sit ==> " .. tag)
	local useritem = self:getMeUserItem()
	if nil == useritem then
		return
	end
	print("sit111111111 ==> ")
	--8号位置为雀王位置不能坐下
--[[	if tag == 8 then
		if self.m_gameQueWangLayer ~= nil then
			self.m_gameQueWangLayer:setVisible(true)
			return
		end		
	end--]]
	
	--当前位置有人判断
	if nil ~= self.m_tabSitDownUser[tag] then
		return
	end
	--重复判断
	if nil ~= self.m_nSelfSitIdx and tag == self.m_nSelfSitIdx then
		return
	end
	print("sit2222222 ==> ")
	if nil ~= self.m_nSelfSitIdx then --and tag ~= self.m_nSelfSitIdx  then
		showToast(self, "当前已占 " .. self.m_nSelfSitIdx .. " 号位置,不能重复占位!", 2)
		return
	end	
	print("sit333333 ==> ")
	print("self.m_tabSitDownConfig.occupyseatType ==> ",self.m_tabSitDownConfig.occupyseatType)
	--坐下条件限制
	if self.m_tabSitDownConfig.occupyseatType == g_var(cmd).OCCUPYSEAT_CONSUMETYPE then --金币占座
		if useritem.lScore < self.m_tabSitDownConfig.lOccupySeatConsume then
			local str = "坐下需要消耗 " .. self.m_tabSitDownConfig.lOccupySeatConsume .. " 金币,金币不足!"
			showToast(self, str, 2)
			return
		end
		local str = "坐下将花费 " .. self.m_tabSitDownConfig.lOccupySeatConsume .. ",确定坐下?"
			local query = QueryDialog:create(str, function(ok)
		        if ok == true then
		            self:getParentNode():sendSitDown(tag - 1, useritem.wChairID)
		        end
		    end):setCanTouchOutside(false)
		        :addTo(self)
	elseif self.m_tabSitDownConfig.occupyseatType == g_var(cmd).OCCUPYSEAT_VIPTYPE then --会员占座
		if useritem.cbMemberOrder < self.m_tabSitDownConfig.enVipIndex then
			local str = "坐下需要会员等级为 " .. self.m_tabSitDownConfig.enVipIndex .. " 会员等级不足!"
			showToast(self, str, 2)
			return
		end
		self:getParentNode():sendSitDown(tag - 1, self:getMeUserItem().wChairID)
	elseif self.m_tabSitDownConfig.occupyseatType == g_var(cmd).OCCUPYSEAT_FREETYPE then --免费占座
		if useritem.lScore < self.m_tabSitDownConfig.lOccupySeatFree then
			local str = "免费坐下需要携带金币大于 " .. self.m_tabSitDownConfig.lOccupySeatFree .. " ,当前携带金币不足!"
			showToast(self, str, 2)
			return
		end
		self:getParentNode():sendSitDown(tag - 1, self:getMeUserItem().wChairID)
	end
end

function GameViewLayer:onResetView()
	self:stopAllActions()
	self:gameDataReset()
end

function GameViewLayer:onExit()
	self:onResetView()
end

--上庄状态
function GameViewLayer:applyBanker( state )
	if state == APPLY_STATE.kCancelState then
		self:getParentNode():sendApplyBanker()		
	elseif state == APPLY_STATE.kApplyState then
		self:getParentNode():sendCancelApply()
	elseif state == APPLY_STATE.kApplyedState then
		self:getParentNode():sendCancelApply()		
	end
end

---------------------------------------------------------------------------------------
--网络消息

------
--网络接收
function GameViewLayer:onGetUserScore( item )
	--自己
	if item.dwUserID == GlobalUserItem.dwUserID then
       self:reSetUserInfo()
    end

    --坐下用户
 --[[   for i = 1, g_var(cmd).MAX_OCCUPY_SEAT_COUNT do
    	if nil ~= self.m_tabSitDownUser[i] then
    		if item.wChairID == self.m_tabSitDownUser[i]:getChair() then
    			self.m_tabSitDownUser[i]:updateScore(item)
    		end
    	end
    end--]]

	--更新座位玩家
	--self:updateRankSitUser()
	
    --庄家
    if self.m_wBankerUser == item.wChairID then
    	--庄家金币
		local str = string.format("%.2f",item.lScore)
		self.m_textBankerCoin:setString(str);
    end
	
	
end

function GameViewLayer:refreshCondition(  )
	local applyable = self:getApplyable()
	if applyable then
		------
		--超级抢庄

		--如果当前有超级抢庄用户且庄家不是自己
		if (yl.INVALID_CHAIR ~= self.m_wCurrentRobApply) or (true == self:isMeChair(self.m_wBankerUser)) then
--			ExternalFun.enableBtn(self.m_btnRob, false)
		else
			local useritem = self:getMeUserItem()
			--判断抢庄类型
			if g_var(cmd).SUPERBANKER_VIPTYPE == self.m_tabSupperRobConfig.superbankerType then
				--vip类型				
--				ExternalFun.enableBtn(self.m_btnRob, useritem.cbMemberOrder >= self.m_tabSupperRobConfig.enVipIndex)
			elseif g_var(cmd).SUPERBANKER_CONSUMETYPE == self.m_tabSupperRobConfig.superbankerType then
				--游戏币消耗类型(抢庄条件+抢庄消耗)
				local condition = self.m_tabSupperRobConfig.lSuperBankerConsume + self.m_llCondition
--				ExternalFun.enableBtn(self.m_btnRob, useritem.lScore >= condition)
			end
		end		
	else
--		ExternalFun.enableBtn(self.m_btnRob, false)
	end
end

--游戏free
function GameViewLayer:onGameFree( )
	yl.m_bDynamicJoin = false

	self:reSetForNewGame()

	--上庄条件刷新
	self:refreshCondition()

	--申请按钮状态更新
	self:refreshApplyBtnState()
	------
	self.m_pleaseWait:setVisible(false)
	
	--更新座位玩家
	--self:updateRankSitUser()
end

function GameViewLayer:updateTopCard(isAdd)
	local cardControlNode = self.m_rootNode:getChildByName("top_control"):getChildByName("card_control")
	if isAdd then
		for i=1,6 do
			local sprite = CardSprite:updateSprite(nil, 0)
			sprite:setScale(0.8)
			cardControlNode:addChild(sprite)
			sprite:setPosition(topCardPosition[i])
		end
	else
		cardControlNode:removeAllChildren()
	end
end

function GameViewLayer:clearEndAnimation()
	self.m_aniAreaLightNode:setVisible(false)
	if nil == self.m_cardLayer then
		self.m_cardLayer = g_var(GameCardLayer):create(self)
		self:addToRootLayer(self.m_cardLayer, TAG_ZORDER.GAMECARD_ZORDER)
	end
	self.m_cardLayer:cleanCardAnimation()
end

--游戏开始
function GameViewLayer:onGameStart( )
	
	ExternalFun.playSoundEffect("dragon_start.mp3")
--	self.m_aniStartNode:setVisible(true)
--[[	local startAniCallback = function()
		self.m_endCardAni:play("paiCard", false)
	end
	self.m_startBetAni:setLastFrameCallFunc(startAniCallback)--]]
	self.m_startBetAni:play("startBet",false)
	local paiCardCallback = function()
		self:updateTopCard(true)
	end
	self.m_endCardAni:setLastFrameCallFunc(paiCardCallback)
	self.m_endCardAni:play("paiCard", false)
--[[	--发牌动画
	for i=1,4 do
		if self.sp_card[i] ~=nil then
			self.sp_card[i]:setVisible(true)
		end
	end
	self.sp_card[1]:setPosition(cc.p(620,710))
	self.sp_card[2]:setPosition(cc.p(620,710))
	self.sp_card[3]:setPosition(cc.p(720,710))
	self.sp_card[4]:setPosition(cc.p(720,710))
	local act1 = cc.MoveTo:create(0.2,cc.p(300,690))
	local act2 = cc.MoveTo:create(0.2,cc.p(380,690))
	local act3 = cc.MoveTo:create(0.2,cc.p(950,690))
	local act4 = cc.MoveTo:create(0.2,cc.p(1030,690))
	if self.sp_card[1]~= nil then
		self.sp_card[1]:runAction(act1)
	end 
	if self.sp_card[4]~= nil then
		self.sp_card[4]:runAction(act4)
	end 
	if self.sp_card[2]~= nil then
		self.sp_card[2]:runAction(cc.Sequence:create(cc.DelayTime:create(0.4),act2))
	end 
	if self.sp_card[3]~= nil then
		self.sp_card[3]:runAction(cc.Sequence:create(cc.DelayTime:create(0.4),act3))
	end --]]
	
	
	
	self.m_nJettonSelect = self.m_pJettonNumber[self.m_nSelectBet].k;
	self.m_lHaveJetton = 0;

	--获取玩家携带游戏币	
	self:reSetUserInfo();

	self.m_bOnGameRes = false

	--不是自己庄家,且有庄家
	if false == self:isMeChair(self.m_wBankerUser) and false == self.m_bNoBanker then
		--下注
		self:enableJetton(true);
		--调整下注按钮
		self:adjustJettonBtn();

		--默认选中的筹码
		self:switchJettonBtnState(self.m_nSelectBet)
		-- 自动下注
		if self.chip_repeat_btn_1:isVisible() then
			local allMyTotal = 0
			for area=1,3 do
				 allMyTotal = allMyTotal + self.m_lastJettonMyTotal[area] or 0
			end
			if self.m_scoreUser >= allMyTotal then
				for area=1,3 do
					local areaTotal = self.m_lastJettonMyTotal[area]
					local count = #self.m_pJettonNumber
					while true do
						if areaTotal <= 0 then
							break
						end
						local isResult = false
						for index=count,1,-1 do
							if self.m_pJettonNumber[index].k <= areaTotal then
								areaTotal = areaTotal - self.m_pJettonNumber[index].k
								self:getParentNode():sendUserBet(area-1, self.m_pJettonNumber[index].k)
								count = index
								isResult = true
								break
							end
						end
						if not isResult then
							break
						end
					end
				end
			end
		end
	end	

	math.randomseed(tostring(os.time()):reverse():sub(1, 6))

	--申请按钮状态更新
	self:refreshApplyBtnState()	
	
	--更新座位玩家
	self:updateRankSitUser()
end

--游戏进行
function GameViewLayer:reEnterStart( lUserJetton )
	self.m_nJettonSelect = self.m_pJettonNumber[self.m_nSelectBet].k;
	self.m_lHaveJetton = lUserJetton;

	--获取玩家携带游戏币
	self.m_scoreUser = 0
	self:reSetUserInfo();

	self.m_bOnGameRes = false

	--不是自己庄家
	if false == self:isMeChair(self.m_wBankerUser) then
		--下注
		self:enableJetton(true);
		--调整下注按钮
		self:adjustJettonBtn();

		--默认选中的筹码
		self:switchJettonBtnState(self.m_nSelectBet)
	end	

--[[	--显示四张背面麻将
	for i=1,4 do
		if self.sp_card[i] ~=nil then
			self.sp_card[i]:setVisible(true)
		end
	end
	self.sp_card[1]:setPosition(cc.p(300,690))
	self.sp_card[2]:setPosition(cc.p(380,690))
	self.sp_card[3]:setPosition(cc.p(950,690))
	self.sp_card[4]:setPosition(cc.p(1030,690))--]]

end

--上庄条件
function GameViewLayer:onGetApplyBankerCondition( llCon , rob_config)
	self.m_llCondition = llCon
	--超级抢庄配置
	self.m_tabSupperRobConfig = rob_config

	self:refreshCondition();
	
end

--刷新庄家信息
function GameViewLayer:onChangeBanker( wBankerUser, lBankerScore, bEnableSysBanker )
	print("更新庄家数据:" .. wBankerUser .. "; coin =>" .. lBankerScore)
	--
	--上一个庄家是自己，且当前庄家不是自己，标记自己的状态
	if self.m_wBankerUser ~= wBankerUser and self:isMeChair(self.m_wBankerUser) then
		self.m_enApplyState = APPLY_STATE.kCancelState
	end
	self.m_wBankerUser = wBankerUser
	--获取庄家数据
	self.m_bNoBanker = false

	local nickstr = "";
	--庄家姓名
	if true == bEnableSysBanker then --允许系统坐庄
		if yl.INVALID_CHAIR == wBankerUser then
			nickstr = "系统坐庄"
		else
			local userItem = self:getDataMgr():getChairUserList()[wBankerUser + 1];
			if nil ~= userItem then
				nickstr = "ID: "..userItem.dwGameID 

				if self:isMeChair(wBankerUser) then
					self.m_enApplyState = APPLY_STATE.kApplyedState
				end
			else
				print("获取用户数据失败")
			end
		end	
	else
		if yl.INVALID_CHAIR == wBankerUser then
			nickstr = "无人坐庄"
			self.m_bNoBanker = true
		else
			local userItem = self:getDataMgr():getChairUserList()[wBankerUser + 1];
			if nil ~= userItem then
				nickstr = "ID: "..userItem.dwGameID 

				if self:isMeChair(wBankerUser) then
					self.m_enApplyState = APPLY_STATE.kApplyedState
				end
			else
				print("获取用户数据失败")
			end
		end
	end
	self.m_clipBankerNick:setString(nickstr);

	--庄家金币
--[[	local str = string.formatNumberThousands(lBankerScore);
	if string.len(str) > 11 then
		str = string.sub(str, 1, 7) .. "...";
	end--]]
	local str = string.format("%.2f",lBankerScore)
	self.m_textBankerCoin:setString(str);

	--如果是超级抢庄用户上庄
	if wBankerUser == self.m_wCurrentRobApply then
		self.m_wCurrentRobApply = yl.INVALID_CHAIR
		self:refreshCondition()
	end

	--坐下用户庄家
	local chair = -1
	for i = 1, g_var(cmd).MAX_OCCUPY_SEAT_COUNT do
		if nil ~= self.m_tabSitDownUser[i] then
			chair = self.m_tabSitDownUser[i]:getChair()
			self.m_tabSitDownUser[i]:updateBanker(chair == wBankerUser)
		end
	end
end

--超级抢庄申请
function GameViewLayer:onGetSupperRobApply(  )
	if yl.INVALID_CHAIR ~= self.m_wCurrentRobApply then
		self.m_bSupperRobApplyed = true
--		ExternalFun.enableBtn(self.m_btnRob, false)
	end
	--如果是自己
	if true == self:isMeChair(self.m_wCurrentRobApply) then
		--普通上庄申请不可用
		self.m_enApplyState = APPLY_STATE.kSupperApplyed
	end
end

--超级抢庄用户离开
function GameViewLayer:onGetSupperRobLeave( wLeave )
	if yl.INVALID_CHAIR == self.m_wCurrentRobApply then
		--普通上庄申请不可用
		self.m_bSupperRobApplyed = false

--		ExternalFun.enableBtn(self.m_btnRob, true)
	end

	--如果是自己
end

--更新用户下注
function GameViewLayer:onGetUserBet( )
	local data = self:getParentNode().cmd_placebet;
	if nil == data then
		return
	end
	local area = data.cbBetArea + 1;
	local wUser = data.wChairID;
	local llScore = data.lBetScore
	--玩家区域总下注
	local lPlayerAreaBet = data.playerAreaBet

	local nIdx = self:getJettonIdx(data.lBetScore);
	local str = string.format("table_chip_%d.png", nIdx);
	if nIdx == 7 or nIdx == 8 then
		local randomIdx = math.random(1,3)
		str = "table_chip_" .. nIdx .. "_" .. randomIdx .. ".png"
	end
	local sp = nil
	local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(str)
	if nil ~= frame then
		sp = cc.Sprite:createWithSpriteFrame(frame);
	end
	
	local btn = self.m_tableJettonArea[area];
	if nil == sp then
		print("sp nil");
	end

	if nil == btn then
		print("btn nil");
	end
	if nil ~= sp and nil ~= btn then
		--下注
		--sp:setScale(0.35);
		sp:setTag(wUser);
		local name = string.format("%d", area) --ExternalFun.formatScore(data.lBetScore);
		sp:setName(name)
		
		--筹码飞行起点位置
		local pos = self.m_betAreaLayout:convertToNodeSpace(self:getBetFromPos(wUser))
		--pos = self.m_betAreaLayout:convertToNodeSpace(self:getBetFromPos(wUser))
		sp:setPosition(pos)
		--筹码飞行动画
		local act = self:getBetAnimation(self:getBetRandomPos(btn,area), cc.CallFunc:create(function()
			--播放下注声音
			ExternalFun.playSoundEffect("on_bet.mp3")
		end))
		sp:stopAllActions()
		sp:runAction(act)
		self.m_betAreaLayout:addChild(sp)
		--座位玩家下注抖动
		local actMove1 = cc.MoveBy:create(0.1,cc.p(0,20))
		local actBack1 = cc.MoveBy:create(0.1,cc.p(0,-20))
		local actMove2 = cc.MoveBy:create(0.1,cc.p(20,0))
		local actBack2 = cc.MoveBy:create(0.1,cc.p(-20,0))
--[[		for i = 1, g_var(cmd).MAX_OCCUPY_SEAT_COUNT do
			if nil ~= self.m_tabSitDownUser[i] then
				local chair = self.m_tabSitDownUser[i]:getChair()
				if self:getMeUserItem().wChairID ~= chair then
					if chair == wUser then
						if i == 1 or i == 2 or i == 7 or i == 8 then 
							self.m_tabSitDownUser[i]:runAction(cc.Sequence:create(actMove1,actBack1))
						else
							self.m_tabSitDownUser[i]:runAction(cc.Sequence:create(actMove2,actBack2))
						end
					end
				end
			end
		end--]]
		for i = 1, g_var(cmd).MAX_OCCUPY_SEAT_COUNT do
			if nil ~= self.m_rankTopUser[i] then
				local chair = self.m_rankTopUser[i]
				if self:getMeUserItem().wChairID ~= chair then
					if chair == wUser then
						if i == 1 or i == 2 or i == 7 or i == 8 then 
							self.m_rankTopNode[i]:runAction(cc.Sequence:create(actMove2,actBack2))
						else
							self.m_rankTopNode[i]:runAction(cc.Sequence:create(actMove1,actBack1))
						end
					end
				end
			end
		end
				
		--下注信息显示
		if nil == self.m_tableJettonNode[area] then
			local jettonNode = self:createJettonNode()
			if area==2 then
				jettonNode:setPosition(cc.p(btn:getPositionX(),btn:getPositionY()));
			elseif cbArea==3 then
				jettonNode:setPosition(cc.p(btn:getPositionX()+250,btn:getPositionY()+200))
			elseif cbArea == 1 then
				jettonNode:setPosition(cc.p(btn:getPositionX()+166,btn:getPositionY()+200))
			end
			self.m_tagControl:addChild(jettonNode);
			jettonNode:setTag(-1);
			self.m_tableJettonNode[area] = jettonNode;
		end
		--self.m_tableJettonNode[area]:refreshJetton(llScore, llScore, self:isMeChair(wUser))
		self:refreshJettonNode(self.m_tableJettonNode[area], llScore, llScore, self:isMeChair(wUser),self.m_tagControl:getChildByName("tag_text_"..(area-1)))
		------------------------
		self.m_controlLayer:setAreaTotalBet(area,llScore)
		local useritem = self:getDataMgr():getChairUserList()[wUser + 1]
		if useritem ~= nil then
			self.m_controlLayer:setPlayerAreaBet(useritem.dwGameID,area,lPlayerAreaBet,data.cbAndroidUser)
		end
	end

	if self:isMeChair(wUser) then
		self.m_scoreUser = self.m_scoreUser - self.m_nJettonSelect;
		self.m_lHaveJetton = self.m_lHaveJetton + llScore;
		
		--调整下注按钮
		self:adjustJettonBtn();

		--显示下注信息
		self:refreshJetton();
	end
end

--更新用户下注失败
function GameViewLayer:onGetUserBetFail(  )
	local data = self:getParentNode().cmd_jettonfail;
	if nil == data then
		return;
	end

	--下注玩家
	local wUser = data.wPlaceUser;
	--下注区域
	local cbArea = data.cbBetArea + 1;
	--下注数额
	local llScore = data.lPlaceScore;

	if self:isMeChair(wUser) then
		--提示下注失败
		local str = string.format("下注 %s 失败", ExternalFun.formatScore(llScore))
		showToast(self,str,1)

		--自己下注失败
		self.m_scoreUser = self.m_scoreUser + llScore;
		self.m_lHaveJetton = self.m_lHaveJetton - llScore;
		self:adjustJettonBtn();
		self:refreshJetton()

		--
		if 0 ~= self.m_lHaveJetton then
			if nil ~= self.m_tableJettonNode[cbArea] then
				--self.m_tableJettonNode[cbArea]:refreshJetton(-llScore, -llScore, true)
				self:refreshJettonNode(self.m_tableJettonNode[cbArea],-llScore, -llScore, true,self.m_tagControl:getChildByName("tag_text_"..(cbArea-1)))
			end

			--移除界面下注元素
			local name = string.format("%d", cbArea) --ExternalFun.formatScore(llScore);
			self.m_betAreaLayout:removeChildByName(name)
		end
	end
end

--断线重连更新界面已下注
function GameViewLayer:reEnterGameBet( cbArea, llScore )
	local btn = self.m_tableJettonArea[cbArea];
	if nil == btn or 0 == llSocre then
		return;
	end
	
	local vec = self:getDataMgr().calcuteJetton(llScore, false);
	for k,v in pairs(vec) do
		local info = v;
		for i=1,info.m_cbCount do
			local str = string.format("table_chip_%d.png", info.m_cbIdx);
			if info.m_cbIdx == 7 or info.m_cbIdx == 8 then
				local randomIdx = math.random(1,3)
				str = "table_chip_" .. info.m_cbIdx .. "_" .. randomIdx .. ".png"
			end
			local sp = cc.Sprite:createWithSpriteFrameName(str);
			if nil ~= sp then
				--sp:setScale(0.35);
				sp:setTag(yl.INVALID_CHAIR);
				local name = string.format("%d", cbArea) --ExternalFun.formatScore(info.m_llScore);
				sp:setName(name);

				self:randomSetJettonPos(btn, sp,cbArea);
				self.m_betAreaLayout:addChild(sp);
			end
		end
	end

	--下注信息显示
	if nil == self.m_tableJettonNode[cbArea] then
		local jettonNode = self:createJettonNode()
		if cbArea==2 then
			jettonNode:setPosition(cc.p(btn:getPositionX(),btn:getPositionY()))
		elseif cbArea==3 then
			jettonNode:setPosition(cc.p(btn:getPositionX()+250,btn:getPositionY()+200))
		elseif cbArea == 1 then
			jettonNode:setPosition(cc.p(btn:getPositionX()+166,btn:getPositionY()+200))
		end
		--jettonNode:setPosition(btn:getPosition());
		self.m_tagControl:addChild(jettonNode);
		jettonNode:setTag(-1);
		self.m_tableJettonNode[cbArea] = jettonNode;
	end
	self:refreshJettonNode(self.m_tableJettonNode[cbArea], llScore, llScore, false,self.m_tagControl:getChildByName("tag_text_"..(cbArea-1)))
	---------------------
	self.m_controlLayer:setAreaTotalBet(cbArea,llScore)
end

--断线重连更新玩家已下注
function GameViewLayer:reEnterUserBet( cbArea, llScore )
	local btn = self.m_tableJettonArea[cbArea];
	if nil == btn or 0 == llSocre then
		return;
	end

	--下注信息显示
	if nil == self.m_tableJettonNode[cbArea] then
		local jettonNode = self:createJettonNode()
		if cbArea==2 then
			jettonNode:setPosition(cc.p(btn:getPositionX(),btn:getPositionY()))
		elseif cbArea==3 then
			jettonNode:setPosition(cc.p(btn:getPositionX()+250,btn:getPositionY()+200))
		elseif cbArea == 1 then
			jettonNode:setPosition(cc.p(btn:getPositionX()+166,btn:getPositionY()+200))
		end
		--jettonNode:setPosition(btn:getPosition());
		self.m_tagControl:addChild(jettonNode);
		jettonNode:setTag(-1);
		self.m_tableJettonNode[cbArea] = jettonNode;
	end
	self:refreshJettonNode(self.m_tableJettonNode[cbArea], llScore, 0, true,self.m_tagControl:getChildByName("tag_text_"..(cbArea-1)))
	----------------------------
	self.m_controlLayer:setAreaTotalBet(cbArea,0)
end

--游戏结束
function GameViewLayer:onGetGameEnd(  )
	--发牌的麻将隐藏。显示扑克数据
--[[	for i=1,4 do
		if self.sp_card[i] ~=nil then
			self.sp_card[i]:setVisible(false)
		end
	end--]]
	
	self.m_bOnGameRes = true
	for i=1,3 do
		self.m_lastJettonMyTotal[i] = self.m_tableJettonNode[i] and self.m_tableJettonNode[i].m_llMyTotal or 0
	end
  
	--不可下注
	self:enableJetton(false)
    -- self.m_lHaveJetton=0
	--界面资源清理
	self:reSet()
end

--申请庄家
function GameViewLayer:onGetApplyBanker( )
	if self:isMeChair(self:getParentNode().cmd_applybanker.wApplyUser) then
		self.m_enApplyState = APPLY_STATE.kApplyState
	end

	self:refreshApplyList()
end

--取消申请庄家
function GameViewLayer:onGetCancelBanker(  )
	if self:isMeChair(self:getParentNode().cmd_cancelbanker.wCancelUser) then
		self.m_enApplyState = APPLY_STATE.kCancelState
	end
	
	self:refreshApplyList()
end

--刷新列表
function GameViewLayer:refreshApplyList(  )
	if nil ~= self.m_applyListLayer and self.m_applyListLayer:isVisible() then
		local userList = self:getDataMgr():getApplyBankerUserList()		
		self.m_applyListLayer:refreshList(userList)
		self.online_num_text:setString("当前共有" .. #userList .. "位玩家")
	end
end

function GameViewLayer:refreshUserList(  )
	if nil ~= self.m_userListLayer and self.m_userListLayer:isVisible() then
		local userList = self:getDataMgr():getUserList()		
		self.m_userListLayer:refreshList(userList)
		self.online_num_text:setString("当前共有" .. #userList .. "位玩家")
	end
end

--刷新申请列表按钮状态
function GameViewLayer:refreshApplyBtnState(  )
	if nil ~= self.m_applyListLayer and self.m_applyListLayer:isVisible() then
		self.m_applyListLayer:refreshBtnState()
	end
end

--刷新路单
function GameViewLayer:updateWallBill()
	if nil ~= self.m_wallBill and self.m_wallBill:isVisible() then
		self.m_wallBill:refreshWallBillList()
	end
end

--更新扑克牌
function GameViewLayer:onGetGameCard( tabRes, bAni, cbTime,cbWinArea, cbTimeLeave)
	if nil == self.m_cardLayer then
		self.m_cardLayer = g_var(GameCardLayer):create(self)
		self:addToRootLayer(self.m_cardLayer, TAG_ZORDER.GAMECARD_ZORDER)
	end
	self.m_cardLayer:showLayer(true)
	self.m_cardLayer:showCards(tabRes, bAni, cbTime,cbWinArea, cbTimeLeave)
	self.m_winAreaList = cbWinArea
--[[	if bAni == false then
		for i=1,4 do
			if self.sp_card[i] ~=nil then
				self.sp_card[i]:setVisible(false)
			end
		end
	end--]]

end
--获取游戏结果
function GameViewLayer:onGetGameRecord(tabRes,cbWinArea)
	if nil == self.m_cardLayer then
		self.m_cardLayer = g_var(GameCardLayer):create(self)
		self:addToRootLayer(self.m_cardLayer, TAG_ZORDER.GAMECARD_ZORDER)
	end
	self.m_cardLayer:getGameRecord(tabRes,cbWinArea)
end
--座位坐下信息
function GameViewLayer:onGetSitDownInfo( config, info )
	self.m_tabSitDownConfig = config
	
	local pos = cc.p(0,0)
	--获取已占位信息
	for i = 1, g_var(cmd).MAX_OCCUPY_SEAT_COUNT do
		print("sit chair " .. info[i])
		self:onGetSitDown(i - 1, info[i], false)
	end
end

--座位坐下
function GameViewLayer:onGetSitDown( index, wchair, bAni )
	if wchair ~= nil 
		and nil ~= index
		and index ~= g_var(cmd).SEAT_INVALID_INDEX 
		and wchair ~= yl.INVALID_CHAIR then
		local useritem = self:getDataMgr():getChairUserList()[wchair + 1]

		if nil ~= useritem then
			--下标加1
			index = index + 1
			if nil == self.m_tabSitDownUser[index] then
				self.m_tabSitDownUser[index] = g_var(SitRoleNode):create(self, index)
				self.m_tabSitDownUser[index]:setPosition(self.m_tabSitDownList[index]:getPosition())
				self.m_roleSitDownLayer:addChild(self.m_tabSitDownUser[index])
				
				self.m_tabSitDownList[index]:setVisible(false)
			end
			self.m_tabSitDownUser[index]:onSitDown(useritem, bAni, wchair == self.m_wBankerUser)

			if useritem.dwUserID == GlobalUserItem.dwUserID then
				self.m_nSelfSitIdx = index
			end
		end
	end
end

--座位失败/离开
function GameViewLayer:onGetSitDownLeave( index )
	if index ~= g_var(cmd).SEAT_INVALID_INDEX 
		and nil ~= index then
		index = index + 1
		if nil ~= self.m_tabSitDownUser[index] then
			self.m_tabSitDownUser[index]:removeFromParent()
			self.m_tabSitDownUser[index] = nil
			
			self.m_tabSitDownList[index]:setVisible(true)
		end

		if self.m_nSelfSitIdx == index then
			self.m_nSelfSitIdx = nil
		end
	end
end

--银行操作成功
function GameViewLayer:onBankSuccess( )
	local bank_success = self:getParentNode().bank_success
	if nil == bank_success then
		return
	end
	GlobalUserItem.lUserScore = bank_success.lUserScore
	GlobalUserItem.lUserInsure = bank_success.lUserInsure

	if nil ~= self.m_bankLayer and true == self.m_bankLayer:isVisible() then
		self:refreshScore()
	end

	showToast(self, bank_success.szDescribrString, 2)
end

--银行操作失败
function GameViewLayer:onBankFailure( )
	local bank_fail = self:getParentNode().bank_fail
	if nil == bank_fail then
		return
	end

	showToast(self, bank_fail.szDescribeString, 2)
end

--银行资料
function GameViewLayer:onGetBankInfo(bankinfo)
	bankinfo.wRevenueTake = bankinfo.wRevenueTake or 10
	if nil ~= self.m_bankLayer then
		local str = "温馨提示:取款将扣除" .. bankinfo.wRevenueTake .. "%的手续费"
		self.m_bankLayer.m_textTips:setString(str)
	end
end
------
---------------------------------------------------------------------------------------
function GameViewLayer:getParentNode( )
	return self._scene;
end

function GameViewLayer:getMeUserItem(  )
	if nil ~= GlobalUserItem.dwUserID then
		return self:getDataMgr():getUidUserList()[GlobalUserItem.dwUserID];
	end
	return nil;
end

function GameViewLayer:isMeChair( wchair )
	local useritem = self:getDataMgr():getChairUserList()[wchair + 1];
	if nil == useritem then
		return false
	else 
		return useritem.dwUserID == GlobalUserItem.dwUserID
	end
end

function GameViewLayer:addToRootLayer( node , zorder)
	if nil == node then
		return
	end

	self.m_rootLayer:addChild(node)
	node:setLocalZOrder(zorder)
end

function GameViewLayer:getChildFromRootLayer( tag )
	if nil == tag then
		return nil
	end
	return self.m_rootLayer:getChildByTag(tag)
end

function GameViewLayer:getApplyState(  )
	return self.m_enApplyState
end

function GameViewLayer:getApplyCondition(  )
	return self.m_llCondition
end

--获取能否上庄
function GameViewLayer:getApplyable(  )
	--自己超级抢庄已申请，则不可进行普通申请
	if APPLY_STATE.kSupperApplyed == self.m_enApplyState then
		return false
	end

	local userItem = self:getMeUserItem();
	if nil ~= userItem then
		return userItem.lScore > self.m_llCondition
	else
		return false
	end
end

--获取能否取消上庄
function GameViewLayer:getCancelable(  )
	return self.m_cbGameStatus == g_var(cmd).GAME_SCENE_FREE
end

--下注区域闪烁
function GameViewLayer:showBetAreaBlink(  )
	local blinkArea = self:getDataMgr().m_tabBetArea
	self:jettonAreaBlink(blinkArea)
end

function GameViewLayer:getDataMgr( )
	return self:getParentNode():getDataMgr()
end

function GameViewLayer:logData(msg)
	local p = self:getParentNode()
	if nil ~= p.logData then
		p:logData(msg)
	end	
end

function GameViewLayer:showPopWait( )
	self:getParentNode():showPopWait()
end

function GameViewLayer:dismissPopWait( )
	self:getParentNode():dismissPopWait()
end

function GameViewLayer:gameDataInit( )

    --播放背景音乐
    ExternalFun.playBackgroudAudio("dragon_bg.mp3")

    --用户列表
	self:getDataMgr():initUserList(self:getParentNode():getUserList())

    --加载资源
	self:loadRes()

	--变量声明
	self.m_nJettonSelect = -1
	self.m_lHaveJetton = 0;

	self.m_llMaxJetton = 0;
	self.m_llCondition = 0;
	yl.m_bDynamicJoin = false;
	self.m_scoreUser = self:getMeUserItem().lScore or 0

	--下注信息
	self.m_tableJettonBtn = {};
	self.m_tableJettonArea = {};

	--下注提示
	self.m_tableJettonNode = {};

	self.m_applyListLayer = nil
	self.m_userListLayer = nil
	self.m_wallBill = nil
	self.m_cardLayer = nil
	self.m_gameResultLayer = nil
	self.m_pClock = nil
	self.m_bankLayer = nil
	--控制层
	self.m_controlLayer = nil
	self.m_bIsGameCheatUser = false
	--申请状态
	self.m_enApplyState = APPLY_STATE.kCancelState
	--超级抢庄申请
	self.m_bSupperRobApplyed = false
	--超级抢庄配置
	self.m_tabSupperRobConfig = {}
	--金币抢庄提示
	self.m_bRobAlert = false

	--用户坐下配置
	self.m_tabSitDownConfig = {}
	self.m_tabSitDownUser = {}
	--坐下用户(钱最多的前8名显示在座位上)
	self.m_rankTopUser = {}
	self.m_rankTopNode = {}
	self.m_resultFont = {}
	self.m_rankHead = {}
	--雀王
	self.m_queWangUser = nil
	--自己坐下
	self.m_nSelfSitIdx = nil

	--座位列表
	self.m_tabSitDownList = {}

	--当前抢庄用户
	self.m_wCurrentRobApply = yl.INVALID_CHAIR

	--当前庄家用户
	self.m_wBankerUser = yl.INVALID_CHAIR

	--选中的筹码
	self.m_nSelectBet = DEFAULT_BET
	if self.m_scoreUser >= 20 then
		self.m_nSelectBet = 3
	elseif  self.m_scoreUser >= 5 then
		self.m_nSelectBet = 2
	end

	--是否结算状态
	self.m_bOnGameRes = false

	--是否无人坐庄
	self.m_bNoBanker = false
	
	--发牌的麻将
	self.sp_card = {}
	
	--结果
	self.m_winAreaList = {}
	-- 上次投注区域和金额
	self.m_lastJettonMyTotal = {}
end
--点击事件
function GameViewLayer:onEventTouchCallback(eventType, x, y)
	if eventType == "ended" then	
		local recordBgRect = self.m_recordBg:getBoundingBox()
		if cc.rectContainsPoint(recordBgRect, pos) then
			if self.m_gameRecordLayer ~= nil then
				self.m_gameRecordLayer:setVisible(true)
				self.m_gameRecordLayer:refreshRecordList()
			end
        end
	end
	return true	
end

function GameViewLayer:checkInTriangle(x0, y0, trianglePos)
	local x1 = trianglePos[1].x
	local y1 = trianglePos[1].y
	local x2 = trianglePos[2].x
	local y2 = trianglePos[2].y
	local x3 = trianglePos[3].x
	local y3 = trianglePos[3].y
	local divisor = (y2 - y3)*(x1 - x3) + (x3 - x2)*(y1 - y3)
	local a = ((y2 - y3)*(x0 - x3) + (x3 - x2)*(y0 - y3)) / divisor
	local b = ((y3 - y1)*(x0 - x3) + (x1 - x3)*(y0 - y3)) / divisor
	local c = 1 - a - b

	return a >= 0 and a <= 1 and b >= 0 and b <= 1 and c >= 0 and c <= 1
end


function GameViewLayer:gameDataReset(  )
	--资源释放
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game/card.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("game/card.png")
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game/game.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("game/game.png")
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game/pk_card.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("game/pk_card.png")
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("bank/bank.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("bank/bank.png")

	--特殊处理public_res blank.png 冲突
	local dict = cc.FileUtils:getInstance():getValueMapFromFile("public/public.plist")
	if nil ~= framesDict and type(framesDict) == "table" then
		for k,v in pairs(framesDict) do
			if k ~= "blank.png" then
				cc.SpriteFrameCache:getInstance():removeSpriteFrameByName(k)
			end
		end
	end
--	cc.Director:getInstance():getTextureCache():removeTextureForKey("public_res/public_res.png")

	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("setting/setting.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("setting/setting.png")
	cc.Director:getInstance():getTextureCache():removeUnusedTextures()
	cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()


	--播放大厅背景音乐
	ExternalFun.playPlazzBackgroudAudio()

	--变量释放
	self.m_actDropIn:release();
	self.m_actDropOut:release();
	if nil ~= self.m_cardLayer then
		self.m_cardLayer:clean()
	end

	yl.m_bDynamicJoin = false;
	self:getDataMgr():removeAllUser()
	self:getDataMgr():clearRecord()
	local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("rbBlank.png")
	if nil == frame then
		return
	end
	for i=1,15 do
		self.m_recordWin[i]:setSpriteFrame(frame)
		self.m_recordWin[i]:setVisible(false)
	end
	for i=1,7 do
		self.m_recordWinType[i]:setSpriteFrame(frame)
		self.m_recordWinType[i]:setVisible(false)
	end
end

function GameViewLayer:getJettonIdx( llScore )
	local idx = 2;
	for i=1,#self.m_pJettonNumber do
		if llScore == self.m_pJettonNumber[i].k then
			idx = self.m_pJettonNumber[i].i;
			break;
		end
	end
	return idx;
end

function GameViewLayer:randomSetJettonPos( nodeArea, jettonSp,cbArea )
	if nil == jettonSp then
		return;
	end

	local pos = self:getBetRandomPos(nodeArea,cbArea)
	jettonSp:setPosition(cc.p(pos.x, pos.y));
end

function GameViewLayer:getBetFromPos( wchair )
	if nil == wchair then
		return {x = 0, y = 0}
	end
	local winSize = cc.Director:getInstance():getWinSize()

	--是否是自己
	if self:isMeChair(wchair) then
		local tmp = self.m_spBottom:getChildByName("player_head")
		if nil ~= tmp then
			local pos = cc.p(tmp:getPositionX(), tmp:getPositionY())
			pos = self.m_spBottom:convertToWorldSpace(pos)
			return {x = pos.x, y = pos.y}
		else
			return {x = winSize.width-60, y = 56}
		end
	end

	local useritem = self:getDataMgr():getChairUserList()[wchair + 1]
	if nil == useritem then
		return {x = winSize.width, y = 0}
	end

	--是否是坐下列表
--[[	local idx = nil
	for i = 1,g_var(cmd).MAX_OCCUPY_SEAT_COUNT do
		if (nil ~= self.m_tabSitDownUser[i]) and (wchair == self.m_tabSitDownUser[i]:getChair()) then
			idx = i
			break
		end
	end
	if nil ~= idx then
		local pos = cc.p(self.m_tabSitDownUser[idx]:getPositionX(), self.m_tabSitDownUser[idx]:getPositionY())
		pos = self.m_roleSitDownLayer:convertToWorldSpace(pos)
		return {x = pos.x, y = pos.y}
	end--]]
	
	local idx = nil
	for i = 1,g_var(cmd).MAX_OCCUPY_SEAT_COUNT do
		if (nil ~= self.m_rankTopUser[i]) and (wchair == self.m_rankTopUser[i]) then
			idx = i
			break
		end
	end
	if nil ~= idx then
		local pos = cc.p(self.m_rankTopNode[idx]:getPositionX(), self.m_rankTopNode[idx]:getPositionY())
		--pos = self.m_roleSitDownLayer:convertToWorldSpace(pos)
		return {x = pos.x, y = pos.y}
	end

	--默认位置
	return {x = winSize.width-60, y = 56}
end

function GameViewLayer:getBetAnimation( pos, call_back )
	local moveTo = cc.MoveTo:create(BET_ANITIME, cc.p(pos.x, pos.y))
	if nil ~= call_back then
		return cc.Sequence:create(cc.EaseIn:create(moveTo, 2), call_back)
	else
		return cc.EaseIn:create(moveTo, 2)
	end
end

function GameViewLayer:getBetRandomPos(nodeArea,cbArea)
	if nil == nodeArea then
		return {x = 0, y = 0}
	end

--[[	local nodeSize = cc.size(nodeArea:getContentSize().width - 80, nodeArea:getContentSize().height - 80);
	local xOffset = math.random()
	local yOffset = math.random()

	local posX = nodeArea:getPositionX() - nodeArea:getAnchorPoint().x * nodeSize.width
	local posY = nodeArea:getPositionY() - nodeArea:getAnchorPoint().y * nodeSize.height
	if cbArea == 1 or cbArea == 3 then
		nodeSize.width = nodeSize.width
	else
		nodeSize.height = nodeSize.height - 50
	end
	return cc.p(xOffset * nodeSize.width + posX, yOffset * nodeSize.height + posY)--]]
	local points = nodeArea:getChildByName("points")
	local children = points:getChildren()
	local index = math.random(1, #children)
	local posX,posY = children[index]:getPosition()
	local pos = points:convertToWorldSpace({x=posX,y = posY})
--[[	pos = nodeArea:convertToWorldSpace(pos)
	pos = self.m_tagControl:convertToWorldSpace(pos)--]]
	local addTypeX = math.random(1,2)
	if addTypeX == 2 then
		addTypeX = -1
	end
	local addTypeY = math.random(1,2)
	if addTypeY == 2 then
		addTypeY = -1
	end
	local addX = math.random(1,50) 
	local addY = math.random(1,50)
	return cc.p(pos.x+addTypeX*addX, pos.y+addTypeY*addY)
end

------
--倒计时节点
function GameViewLayer:createClockNode()
	self.m_pClock = cc.Node:create()
	self.m_pClock:setPosition(665,700)
	self:addToRootLayer(self.m_pClock, TAG_ZORDER.CLOCK_ZORDER)

	--加载csb资源
	local csbNode = ExternalFun.loadCSB("game/GameClockNode.csb", self.m_pClock)
	--背景
	self.m_clockBg = csbNode:getChildByName("sp_time_bg_1")
	self.m_clockBg:setVisible(false)
	
	--倒计时
	self.m_pClock.m_atlasTimer = csbNode:getChildByName("timer_atlas")
	self.m_pClock.m_atlasTimer:setString("")

	--提示
	self.m_pClock.m_spTip = csbNode:getChildByName("sp_tip")

	local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("rbBlank.png")
	if nil ~= frame then
		self.m_pClock.m_spTip:setSpriteFrame(frame)
	end
end

function GameViewLayer:updateClock(tag, left)
	
	self.m_pClock:setVisible(left > 0)

	local str = string.format("%02d", left)
	self.m_pClock.m_atlasTimer:setString(str)

	if g_var(cmd).kGAMEFREE_COUNTDOWN == tag then
		self.m_pClock.m_atlasTimer:setVisible(false)
		if 4 == left then
			ExternalFun.playSoundEffect("dragon_ready.mp3")
		end
	elseif g_var(cmd).kGAMEPLAY_COUNTDOWN == tag then
		self.m_pClock.m_atlasTimer:setVisible(true)
		self.m_pleaseWait:setVisible(false)
		if 14 == left then
			ExternalFun.playSoundEffect("dragon_user_bet.mp3")
		end
		if left == 3 then	
--			self.m_aniStartNode:setVisible(true)		
			self.m_endBetAni:play("timeEnd",false)
		end
		if left <= 3 then
			self.m_pClock:setVisible(false)
			ExternalFun.playSoundEffect("dragon_ready_time.mp3")
			if left == 0 then
				ExternalFun.playSoundEffect("bet_end.mp3")
			end
		end
	elseif g_var(cmd).kGAMEOVER_COUNTDOWN == tag then
		self.m_pClock:setVisible(false)
	end
	--设置控制层时间
	---------------------------------------------
	if self.m_controlLayer ~= nil then
		self.m_controlLayer:showLeftTime(left)
	end
	---------------------------------------------
	if g_var(cmd).kGAMEOVER_COUNTDOWN == tag then
		if 8 == left then
			if #self.m_winAreaList > 0 then
				for i=1,#self.m_winAreaList do
					local stri = i-1
					local winNode = self.m_aniAreaLightNode:getChildByName("win_" .. stri)
					local areaNode = self.m_aniAreaLightNode:getChildByName("area_" .. stri)
					if winNode then
						winNode:setVisible( self.m_winAreaList[i] == 1 and true or false)
					end
					if areaNode then
						areaNode:setVisible( self.m_winAreaList[i] == 1 and true or false)
					end
				end
			end
			self.m_aniAreaLightNode:setVisible(true)
			self.m_aniAreaLightAni:play("result_light",false)
		elseif 5 == left then
			self.m_aniAreaLightNode:setVisible(false)
--[[			if self:getDataMgr().m_bJoin then
				if nil ~= self.m_cardLayer then
					self.m_cardLayer:showLayer(false)
				end
			end	--]]				
			--筹码动画
			self:betAnimation()			
		elseif 4 == left then
--[[			if true == self:getDataMgr().m_bJoin then
				self:showGameResult(true)
				if nil ~= self.m_cardLayer then
					self.m_cardLayer:showLayer(false)
				end
			end	--]]
			self:showGameResult(true)
			--更新路单列表
			--self:updateWallBill()	
			--更新游戏记录
			self:updateGameRecord()

		elseif 3 == left then
			if nil ~= self.m_cardLayer then
				self.m_cardLayer:showLayer(false)
			end
		elseif 0 == left then
			self:showGameResult(false)	
			--闪烁停止
			self:jettonAreaBlinkClean()
			self:clearEndAnimation()
		end
	end
end

function GameViewLayer:showTimerTip(tag)
	tag = tag or -1
	--local scale = cc.ScaleTo:create(0.2, 0.0001, 1.0)
	
	local str = string.format("sp_tip_%d.png", tag)
	local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(str)

	self.m_pClock.m_spTip:setVisible(false)
	if nil ~= frame then
		self.m_pClock.m_spTip:setVisible(true)
		self.m_pClock.m_spTip:setSpriteFrame(frame)
	end
	
	if g_var(cmd).kGAMEFREE_COUNTDOWN == tag then
		self.m_pClock.m_atlasTimer:setVisible(false)
	elseif g_var(cmd).kGAMEPLAY_COUNTDOWN == tag then
		self.m_pClock.m_atlasTimer:setVisible(true)		
	elseif g_var(cmd).kGAMEOVER_COUNTDOWN == tag then
		self.m_pClock:setVisible(false)
	end
	
--[[	local call = cc.CallFunc:create(function (  )
		local str = string.format("sp_tip_%d.png", tag)
		local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(str)

		self.m_pClock.m_spTip:setVisible(false)
		if nil ~= frame then
			self.m_pClock.m_spTip:setVisible(true)
			self.m_pClock.m_spTip:setSpriteFrame(frame)
		end
	end)--]]
--[[	local scaleBack = cc.ScaleTo:create(0.2,1.0)
	local seq = cc.Sequence:create(scale, call, scaleBack)--]]

--[[	self.m_pClock.m_spTip:stopAllActions()
	self.m_pClock.m_spTip:runAction(seq)--]]
	
	--控制层
	if self.m_controlLayer ~= nil then
		self.m_controlLayer:showSceneTip(tag)
	end
end
------

------
--下注节点
function GameViewLayer:createJettonNode()
	local jettonNode = cc.Node:create()
	--加载csb资源
	local csbNode = ExternalFun.loadCSB("game/JettonNode.csb", jettonNode)

	local m_imageBg = csbNode:getChildByName("jetton_bg")
	local m_textMyJetton = m_imageBg:getChildByName("jetton_my")
--	local m_textTotalJetton = m_imageBg:getChildByName("jetton_total")

	jettonNode.m_imageBg = m_imageBg
	jettonNode.m_textMyJetton = m_textMyJetton
--	jettonNode.m_textTotalJetton = m_textTotalJetton
	jettonNode.m_llMyTotal = 0
	jettonNode.m_llAreaTotal = 0

	return jettonNode
end

function GameViewLayer:refreshJettonNode( node, my, total, bMyJetton ,tagText)	
	if true == bMyJetton then
		node.m_llMyTotal = node.m_llMyTotal + my
	end

	node.m_llAreaTotal = node.m_llAreaTotal + total
	node:setVisible( node.m_llAreaTotal > 0)

	--自己下注数额
	local str = string.format("%.2f",node.m_llMyTotal)
--	str = str.."/";
	if string.len(str) > 15 then
		str = string.sub(str,1,12)
		str = str .. "... ";
	end
	node:setVisible(true)
	node.m_textMyJetton:setString(str);
	
	if node.m_llMyTotal <= 0 then
		node:setVisible(false)
		node.m_textMyJetton:setString("");
	end

	--总下注
	if node.m_llAreaTotal > 0 then
		str = string.format("%.2f",node.m_llAreaTotal)
		str = ""..str
		if string.len(str) > 15 then
			str = string.sub(str,1,12)
			str = str .. "..."
		else
			local strlen = string.len(str)
			local l = 15 + strlen
			if strlen > l then
				str = string.sub(str, 1, l - 3)
				str = str .. "..."
			end
		end
		tagText:setString(str)
	end
	
	--调整背景宽度
	local mySize = node.m_textMyJetton:getContentSize()
--	local totalSize = node.m_textTotalJetton:getContentSize();
	local total = cc.size(mySize.width + 66, 32)
	node.m_imageBg:setContentSize(total)

--	node.m_textTotalJetton:setPositionX(6 + mySize.width);
end

function GameViewLayer:reSetJettonNode(node, tagText)
	node:setVisible(false);

	node.m_textMyJetton:setString("")
	tagText:setString("")
	node.m_imageBg:setContentSize(cc.size(34, 32))

	node.m_llMyTotal = 0
	node.m_llAreaTotal = 0
end
------

------
--银行节点
function GameViewLayer:createBankLayer()
	self.m_bankLayer = cc.Node:create()
	self:addToRootLayer(self.m_bankLayer, TAG_ZORDER.BANK_ZORDER)
	self.m_bankLayer:setTag(TAG_ENUM.BANK_LAYER)

	--加载csb资源
	local csbNode = ExternalFun.loadCSB("bank/BankLayer.csb", self.m_bankLayer)
	local sp_bg = csbNode:getChildByName("sp_bg")

	------
	--按钮事件
	local function btnEvent( sender, eventType )
		if eventType == ccui.TouchEventType.ended then
			self:onButtonClickedEvent(sender:getTag(), sender)
		end
	end	
	--关闭按钮
	local btn = sp_bg:getChildByName("close_btn")
	btn:setTag(TAG_ENUM.BT_CLOSEBANK)
	btn:addTouchEventListener(btnEvent)

	--取款按钮
	btn = sp_bg:getChildByName("out_btn")
	btn:setTag(TAG_ENUM.BT_TAKESCORE)
	btn:addTouchEventListener(btnEvent)
	------

	------
	--编辑框
	--取款金额
	local tmp = sp_bg:getChildByName("count_temp")
	local editbox = ccui.EditBox:create(tmp:getContentSize(),"blank.png",UI_TEX_TYPE_PLIST)
		:setPosition(tmp:getPosition())
		:setFontName("fonts/round_body.ttf")
		:setPlaceholderFontName("fonts/round_body.ttf")
		:setFontSize(24)
		:setPlaceholderFontSize(24)
		:setMaxLength(32)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:setPlaceHolder("请输入取款金额")
	sp_bg:addChild(editbox)
	self.m_bankLayer.m_editNumber = editbox
	tmp:removeFromParent()

	--取款密码
	tmp = sp_bg:getChildByName("passwd_temp")
	editbox = ccui.EditBox:create(tmp:getContentSize(),"rbBlank.png",UI_TEX_TYPE_PLIST)
		:setPosition(tmp:getPosition())
		:setFontName("fonts/round_body.ttf")
		:setPlaceholderFontName("fonts/round_body.ttf")
		:setFontSize(24)
		:setPlaceholderFontSize(24)
		:setMaxLength(32)
		:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:setPlaceHolder("请输入取款密码")
	sp_bg:addChild(editbox)
	self.m_bankLayer.m_editPasswd = editbox
	tmp:removeFromParent()
	------

	--当前游戏币
	self.m_bankLayer.m_textCurrent = sp_bg:getChildByName("text_current")

	--银行游戏币
	self.m_bankLayer.m_textBank = sp_bg:getChildByName("text_bank")

	--取款费率
	self.m_bankLayer.m_textTips = sp_bg:getChildByName("text_tips")
	self:getParentNode():sendRequestBankInfo()
end

--取款
function GameViewLayer:onTakeScore()
	--参数判断
	local szScore = string.gsub(self.m_bankLayer.m_editNumber:getText(),"([^0-9])","")
	local szPass = self.m_bankLayer.m_editPasswd:getText()

	if #szScore < 1 then 
		showToast(self,"请输入操作金额！",2)
		return
	end

	local lOperateScore = tonumber(szScore)
	if lOperateScore<1 then
		showToast(self,"请输入正确金额！",2)
		return
	end

	if #szPass < 1 then 
		showToast(self,"请输入银行密码！",2)
		return
	end
	if #szPass <6 then
		showToast(self,"密码必须大于6个字符，请重新输入！",2)
		return
	end

	self:showPopWait()	
	self:getParentNode():sendTakeScore(szScore,szPass)
end

--刷新金币
function GameViewLayer:refreshScore(  )
	--携带游戏币
	local str = ExternalFun.numberThousands(GlobalUserItem.lUserScore)
	if string.len(str) > 19 then
		str = string.sub(str, 1, 19)
	end
	self.m_bankLayer.m_textCurrent:setString(str)

	--银行存款
	str = ExternalFun.numberThousands(GlobalUserItem.lUserInsure)
	if string.len(str) > 19 then
		str = string.sub(str, 1, 19)
	end
	self.m_bankLayer.m_textBank:setString(ExternalFun.numberThousands(GlobalUserItem.lUserInsure))

	self.m_bankLayer.m_editNumber:setText("")
	self.m_bankLayer.m_editPasswd:setText("")
end

function GameViewLayer:updateLbottomPourImpose(lBottomPourImpose)
	self.lBottomPourImpose = lBottomPourImpose
end

function GameViewLayer:executecontrol(cmddata)
	self:getParentNode():executecontrol(cmddata)
end

function GameViewLayer:setPlayerEnter(dwGameID,bAndroid)
	self.m_controlLayer:setPlayerEnter(dwGameID,bAndroid)
end
function GameViewLayer:removeuserAreaBet(dwGameID)
	self.m_controlLayer:removeuserAreaBet(dwGameID)
end

function GameViewLayer:ControlAddPeizhi(cmddata)
	self:getParentNode():ControlAddPeizhi(cmddata)
end
function GameViewLayer:OnAdmincontorlpeizhi(cmd_table)
	self.m_controlLayer:OnAddpeizhi(cmd_table.dwGameID,cmd_table.lscore)
end
function GameViewLayer:ControlDelPeizhi(cmddata)
	self:getParentNode():ControlDelPeizhi(cmddata)
end
function GameViewLayer:OnDelPeizhi(cmd_table)
	self.m_controlLayer:OnDelPeizhi(cmd_table.dwGameID)
end
function GameViewLayer:OnUpAlllosewin(cmd_table)
	self.m_controlLayer:UppeizhiLIst(cmd_table.dwGameID,cmd_table.lscore)
end
------
return GameViewLayer