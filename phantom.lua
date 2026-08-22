local P=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local TS=game:GetService("TweenService")
local VIM=game:FindService("VirtualInputManager")
local pl=P.LocalPlayer
local pd=pl:WaitForChild("PlayerData")
local inv=pd:WaitForChild("Inventory")
local f=RS:WaitForChild("Remotes")

local hasGC=false
pcall(function() hasGC=#getconnections(Instance.new("BindableEvent"))>0 end)
local hasVIM=VIM~=nil

local run=false
local CASE_NAME="Free"
local rounds=0
local soldCount=0
local totalEarned=0
local startTime=0
local autoSell=true
local lastSellTime=0
local SELL_CD=3
local sellFailCount=0
local SELL_MAX_FAIL=3
local hookData={}
local sellCaptures={}
local hOrder=0
local hookInstalled=false
local hScrollRef=nil
local hCountRef=nil

local old=pl.PlayerGui:FindFirstChild("CPSafe")
if old then old:Destroy() end
local sg=Instance.new("ScreenGui",pl.PlayerGui)
sg.Name="CPSafe"
sg.ResetOnSpawn=false

local BG=Color3.fromRGB(16,16,28)
local BG2=Color3.fromRGB(22,22,38)
local BG3=Color3.fromRGB(28,28,48)
local BG4=Color3.fromRGB(35,35,55)
local BG5=Color3.fromRGB(42,42,65)
local ACC=Color3.fromRGB(60,220,130)
local ACC2=Color3.fromRGB(40,180,100)
local RED=Color3.fromRGB(220,80,80)
local GOLD=Color3.fromRGB(255,200,60)
local BLUE=Color3.fromRGB(100,160,255)
local PURPLE=Color3.fromRGB(180,100,255)
local WHITE=Color3.fromRGB(220,220,230)
local GRAY=Color3.fromRGB(100,100,120)
local LGRAY=Color3.fromRGB(140,140,160)
local DGRAY=Color3.fromRGB(60,60,80)
local CYAN=Color3.fromRGB(80,220,220)
local ORANGE=Color3.fromRGB(255,150,50)

local TW=function(o,p,t) local tw=TS:Create(o,TweenInfo.new(t or 0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),p) tw:Play() return tw end
local CR=function(p,r) local c=Instance.new("UICorner",p) c.CornerRadius=UDim.new(0,r or 8) return c end
local ST=function(p,c,t) local s=Instance.new("UIStroke",p) s.Color=c or ACC s.Thickness=t or 1.5 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border return s end

local function getBal()
	local c=pd:FindFirstChild("Currencies")
	if c then local b=c:FindFirstChild("Balance") if b then return b.Value end end
	return 0
end

local function getCooldown()
	local cc=f:FindFirstChild("CheckCooldown")
	if not cc then return 0 end
	local ok,r=pcall(function() return cc:InvokeServer() end)
	if not ok or r==nil then return 0 end
	if type(r)=="number" then return r end
	if type(r)=="string" then
		local n=tonumber(r:match("[%d%.]+"))
		return n or 0
	end
	if type(r)=="table" then
		for _,k in ipairs({"TimeLeft","Cooldown","time","Remaining","seconds","cd","Time"}) do
			if r[k] then
				local v=r[k]
				if type(v)=="number" then return v end
				if type(v)=="string" then return tonumber(v:match("[%d%.]+")) or 0 end
			end
		end
		if r[1] then
			if type(r[1])=="number" then return r[1] end
			if type(r[1])=="string" then return tonumber(r[1]:match("[%d%.]+")) or 0 end
		end
	end
	return 0
end

local function formatArg(v)
	local ok,desc=pcall(function()
		if typeof(v)=="Instance" then return "Instance:"..v.Name.."("..v.ClassName..")"
		elseif typeof(v)=="table" then
			local parts={}
			for k,val in pairs(v) do table.insert(parts,tostring(k).."="..formatArg(val)) end
			return "{"..table.concat(parts,", ").."}"
		elseif typeof(v)=="string" then return "\""..v.."\""
		else return tostring(v).."["..typeof(v).."]"
		end
	end)
	return ok and desc or "?"
end

local function fireBtnConnections(btn)
	if not btn then return false end
	local fired=false
	if hasGC then
		for _,evName in ipairs({"MouseButton1Click","Activated"}) do
			local ok,conns=pcall(function() return getconnections(btn[evName]) end)
			if ok and conns then
				for _,conn in ipairs(conns) do pcall(function() conn:Fire() end) fired=true end
			end
		end
	end
	pcall(function() btn:Activate() fired=true end)
	pcall(function()
		local ab=btn.AbsolutePosition
		local sz=btn.AbsoluteSize
		local cam=workspace.CurrentCamera
		local p1=Vector3.new(ab.X+sz.X/2,ab.Y+sz.Y/2,0)
		local p2=Vector3.new(ab.X+sz.X/2+1,ab.Y+sz.Y/2,0)
		local plane=Ray.new(cam.CFrame.Position,(cam.CFrame*CFrame.new(0,0,-100)).Position-cam.CFrame.Position)
		local x,y=ab.X+sz.X/2,ab.Y+sz.Y/2
		local img=Instance.new("ImageLabel")
		img.Position=UDim2.new(0,x,0,y)
		img.Size=UDim2.new(0,1,0,1)
		img.BackgroundTransparency=1
		img.Parent=btn
		img:Destroy()
		fired=true
	end)
	return fired
end

local function findBtn(parent,path,depth)
	if depth>10 then return nil end
	local ok,ch=pcall(function() return parent:GetChildren() end)
	if not ok then return nil end
	for _,obj in ipairs(ch) do
		if obj:IsA("TextButton") or obj:IsA("ImageButton") then
			local nm=""
			pcall(function() nm=obj.Name end)
			if nm==path then return obj end
		end
		if obj:IsA("Frame") or obj:IsA("ScrollingFrame") or obj:IsA("ScreenGui") then
			local r=findBtn(obj,path,depth+1)
			if r then return r end
		end
	end
	return nil
end

local function findBtnByPath(pathSeg)
	for _,gui in ipairs(pl.PlayerGui:GetChildren()) do
		if gui:IsA("ScreenGui") then
			local r=findBtn(gui,pathSeg,0)
			if r then return r end
		end
	end
	return nil
end

local function findAllSellButtons()
	local found={}
	local function scan(parent,depth)
		if depth>14 then return end
		local ok,ch=pcall(function() return parent:GetChildren() end)
		if not ok then return end
		for _,obj in ipairs(ch) do
			if obj:IsA("TextButton") or obj:IsA("ImageButton") then
				local nm=""
				pcall(function() nm=obj.Name end)
				local lnm=string.lower(nm)
				if lnm:find("sell") then
					table.insert(found,obj)
				end
			end
			if obj:IsA("Frame") or obj:IsA("ScrollingFrame") or obj:IsA("ScreenGui") or obj:IsA("ImageLabel") or obj:IsA("ImageButton") or obj:IsA("ViewportFrame") then
				scan(obj,depth+1)
			end
		end
	end
	for _,gui in ipairs(pl.PlayerGui:GetChildren()) do
		if gui:IsA("ScreenGui") then scan(gui,0) end
	end
	return found
end

local function findInventorySell()
	local sellBtn=nil
	local contents=nil
	local function scan(parent,depth)
		if depth>10 or sellBtn then return end
		local ok,ch=pcall(function() return parent:GetChildren() end)
		if not ok then return end
		for _,child in ipairs(ch) do
			if child:IsA("Frame") then
				local s=child:FindFirstChild("Sell")
				local ic=child:FindFirstChild("InventoryFrame")
				if s and s:IsA("TextButton") and ic then
					sellBtn=s
					contents=ic:FindFirstChild("Contents") or ic
					return
				end
				scan(child,depth+1)
				if sellBtn then return end
			end
		end
	end
	for _,gui in ipairs(pl.PlayerGui:GetChildren()) do
		if gui:IsA("ScreenGui") then scan(gui,0) end
		if sellBtn then break end
	end
	return sellBtn,contents
end

local function virtualClick(btn)
	if not btn then return false end
	if hasVIM then
		local ok=pcall(function()
			local cam=workspace.CurrentCamera
			local x=btn.AbsolutePosition.X+btn.AbsoluteSize.X/2
			local y=btn.AbsolutePosition.Y+btn.AbsoluteSize.Y/2
			VIM:SendMouseButtonEvent(x,y,0,true,cam,1)
			task.wait(0.05)
			VIM:SendMouseButtonEvent(x,y,0,false,cam,1)
		end)
		if ok then return true end
	end
	pcall(function() btn:Activate() end)
	pcall(function() btn.MouseButton1Click:Fire() end)
	pcall(function() btn.Activated:Fire() end)
	return true
end

local function fireAllSell()
	local fired=0
	local sellBtn,contents=findInventorySell()
	LOG("findInventorySell: "..tostring(sellBtn~=nil).." contents: "..tostring(contents~=nil),GRAY)
	if sellBtn and contents then
		local selCount=0
		for _,item in ipairs(contents:GetChildren()) do
			if item:IsA("Frame") and item:GetAttribute("ItemId") then
				item:SetAttribute("selected",true)
				selCount=selCount+1
			end
		end
		LOG("Inventory items: "..selCount,GOLD)
		if selCount>0 then
			pcall(function() sellBtn.Visible=true end)
			LOG("VirtualInput click Sell...",CYAN)
			virtualClick(sellBtn)
			LOG("Connection fire Sell...",CYAN)
			fireBtnConnections(sellBtn)
			fired=fired+1
		end
	end
	local sellAllBtn=findBtnByPath("SellAllButton")
	LOG("SellAllButton: "..tostring(sellAllBtn~=nil),GRAY)
	if sellAllBtn then
		LOG("VirtualInput click SellAll...",CYAN)
		virtualClick(sellAllBtn)
		LOG("Connection fire SellAll...",CYAN)
		fireBtnConnections(sellAllBtn)
		fired=fired+1
	end
	if fired==0 then
		local btns=findAllSellButtons()
		LOG("Fallback sell buttons: "..#btns,GRAY)
		for _,b in ipairs(btns) do
			virtualClick(b)
			fireBtnConnections(b)
			fired=fired+1
		end
	end
	return fired
end

local function trySell(item)
	local elapsed=os.time()-lastSellTime
	if elapsed<SELL_CD then task.wait(SELL_CD-elapsed) end
	local balBefore=getBal()
	local fired=fireAllSell()
	task.wait(0.6)
	local balAfter=getBal()
	if balAfter>balBefore then
		totalEarned=totalEarned+(balAfter-balBefore)
		lastSellTime=os.time()
		return true
	end
	local sr=f:FindFirstChild("Sell")
	if sr then
		pcall(function() sr:InvokeServer(item) end)
		task.wait(0.3)
		pcall(function() sr:InvokeServer(item.Name) end)
		task.wait(0.3)
		pcall(function() sr:InvokeServer({item.Name}) end)
	end

	local dr=f:FindFirstChild("DestroyItem")
	if dr then
		pcall(function() dr:FireServer(item) end)
		pcall(function() dr:FireServer(item.Name) end)
	end

	task.wait(0.5)
	local balAfter=getBal()
	if balAfter>balBefore then
		totalEarned=totalEarned+(balAfter-balBefore)
		lastSellTime=os.time()
		return true
	end
	lastSellTime=os.time()
	return false
end

local cases={
	{name="Free",price=0,c=Color3.fromRGB(150,150,150)},
	{name="Military",price=0.67,c=Color3.fromRGB(120,160,120)},
	{name="50GLOCK",price=0.98,c=Color3.fromRGB(120,160,120)},
	{name="MILSPEC",price=1.3,c=Color3.fromRGB(100,180,255)},
	{name="Oblivion",price=1.7,c=Color3.fromRGB(100,180,255)},
	{name="Jungle",price=2,c=Color3.fromRGB(100,180,255)},
	{name="50USP",price=2.58,c=Color3.fromRGB(100,180,255)},
	{name="GLOCK18",price=3.3,c=Color3.fromRGB(80,220,100)},
	{name="RESTRICTED",price=3.6,c=Color3.fromRGB(80,220,100)},
	{name="Void",price=3.8,c=Color3.fromRGB(80,220,100)},
	{name="STARTER",price=4,c=Color3.fromRGB(80,220,100)},
	{name="NIGHTMARE",price=4,c=Color3.fromRGB(80,220,100)},
	{name="ENERGY",price=4.4,c=Color3.fromRGB(80,220,100)},
	{name="Franklin",price=5.3,c=Color3.fromRGB(140,100,255)},
	{name="TOY",price=6.4,c=Color3.fromRGB(140,100,255)},
	{name="USP",price=6.5,c=Color3.fromRGB(140,100,255)},
	{name="ELEMENTAL",price=7.7,c=Color3.fromRGB(140,100,255)},
	{name="Inferno",price=8.4,c=Color3.fromRGB(220,100,255)},
	{name="AK47",price=9,c=Color3.fromRGB(220,100,255)},
	{name="M4A4",price=9,c=Color3.fromRGB(220,100,255)},
	{name="BREACH",price=9,c=Color3.fromRGB(220,100,255)},
	{name="Desolate",price=9.6,c=Color3.fromRGB(220,100,255)},
	{name="TECH",price=11,c=Color3.fromRGB(220,100,255)},
	{name="ADVANCED",price=11,c=Color3.fromRGB(220,100,255)},
	{name="CLASSIFIED",price=13,c=Color3.fromRGB(220,100,255)},
	{name="50AWP",price=15,c=Color3.fromRGB(255,180,50)},
	{name="Sakura",price=16.4,c=Color3.fromRGB(255,180,50)},
	{name="Risky",price=18,c=Color3.fromRGB(255,180,50)},
	{name="COVERT",price=25.6,c=Color3.fromRGB(255,180,50)},
	{name="ELITE",price=29,c=Color3.fromRGB(255,180,50)},
	{name="Beast",price=30,c=Color3.fromRGB(255,180,50)},
	{name="Industrial",price=34.5,c=Color3.fromRGB(255,140,50)},
	{name="Jacob",price=36,c=Color3.fromRGB(255,100,80)},
	{name="Neon",price=38,c=Color3.fromRGB(255,100,80)},
	{name="CHEESE",price=45,c=Color3.fromRGB(255,60,80)},
	{name="Vaporwave",price=58,c=Color3.fromRGB(255,60,80)},
	{name="Bloodsport",price=61.8,c=Color3.fromRGB(255,60,80)},
	{name="Hardened",price=76,c=Color3.fromRGB(200,40,60)},
	{name="Frosty",price=86,c=Color3.fromRGB(200,40,60)},
	{name="Frostbite",price=110,c=Color3.fromRGB(200,40,60)},
	{name="Tiger",price=114,c=Color3.fromRGB(200,40,60)},
	{name="Cobalt",price=130,c=Color3.fromRGB(200,40,60)},
}

local m=Instance.new("Frame",sg)
m.Name="Main"
m.Size=UDim2.new(0,360,0,440)
m.Position=UDim2.new(0.5,-180,0.5,-220)
m.BackgroundColor3=BG
m.BorderSizePixel=0
m.Active=true
m.Draggable=true
m.ClipsDescendants=true
m.BackgroundTransparency=1
CR(m,14)
ST(m,ACC,2)
m.Size=UDim2.new(0,0,0,0)
m.Position=UDim2.new(0.5,0,0.5,0)
TW(m,{Size=UDim2.new(0,360,0,440),Position=UDim2.new(0.5,-180,0.5,-220),BackgroundTransparency=0},0.5)

local hdr=Instance.new("Frame",m)
hdr.Size=UDim2.new(1,0,0,40)
hdr.BackgroundColor3=Color3.fromRGB(10,10,18)
hdr.BorderSizePixel=0
CR(hdr,14)

local ttl=Instance.new("TextLabel",hdr)
ttl.Size=UDim2.new(0,180,0,20)
ttl.Position=UDim2.new(0,12,0,5)
ttl.BackgroundTransparency=1
ttl.Text="CASE PARADISE"
ttl.TextColor3=WHITE
ttl.TextSize=14
ttl.Font=Enum.Font.GothamBlack
ttl.TextXAlignment=Enum.TextXAlignment.Left

local vr=Instance.new("TextLabel",hdr)
vr.Size=UDim2.new(1,-80,0,12)
vr.Position=UDim2.new(0,12,0,23)
vr.BackgroundTransparency=1
vr.Text="AUTOFARM v9.0  [F1=Show  F2=Start  F3=Stop]"
vr.TextColor3=ACC
vr.TextSize=7
vr.Font=Enum.Font.GothamBold
vr.TextXAlignment=Enum.TextXAlignment.Left

local function hBtn(txt,pos,bg,hv)
	local b=Instance.new("TextButton",hdr)
	b.Size=UDim2.new(0,32,0,32)
	b.Position=pos
	b.BackgroundColor3=bg
	b.BorderSizePixel=0
	b.Text=txt
	b.TextColor3=Color3.fromRGB(255,255,255)
	b.TextSize=14
	b.Font=Enum.Font.GothamBold
	CR(b,8)
	b.MouseEnter:Connect(function() TW(b,{BackgroundColor3=hv},0.15) end)
	b.MouseLeave:Connect(function() TW(b,{BackgroundColor3=bg},0.15) end)
	return b
end

hBtn("X",UDim2.new(1,-38,0,5),RED,Color3.fromRGB(255,80,80)).MouseButton1Click:Connect(function()
	run=false
	TW(m,{Size=UDim2.new(0,360,0,0),Position=UDim2.new(0.5,-180,0.5,0),BackgroundTransparency=1},0.3)
	task.wait(0.3)
	sg:Destroy()
end)
hBtn("-",UDim2.new(1,-72,0,5),BG4,Color3.fromRGB(80,80,110)).MouseButton1Click:Connect(function()
	TW(m,{Size=UDim2.new(0,360,0,40)},0.2)
end)
UIS.InputBegan:Connect(function(i,gp)
	if gp then return end
	if i.KeyCode==Enum.KeyCode.F1 then
		m.Visible=not m.Visible
	elseif i.KeyCode==Enum.KeyCode.F2 then
		if not run then startBtn:Activate() end
	elseif i.KeyCode==Enum.KeyCode.F3 then
		if run then stopBtn:Activate() end
	end
end)
local tBar=Instance.new("Frame",m)
tBar.Size=UDim2.new(1,-16,0,28)
tBar.Position=UDim2.new(0,8,0,44)
tBar.BackgroundColor3=BG2
tBar.BorderSizePixel=0
CR(tBar,8)

local function makeTab(txt,pos,col)
	local b=Instance.new("TextButton",tBar)
	b.Size=UDim2.new(0.48,-4,1,-6)
	b.Position=pos
	b.BackgroundColor3=col
	b.BorderSizePixel=0
	b.Text=txt
	b.TextColor3=col==BG4 and GRAY or BG
	b.TextSize=9
	b.Font=Enum.Font.GothamBlack
	CR(b,7)
	return b
end

local tF=makeTab("FARM",UDim2.new(0.01,0,3),ACC)
local tI=makeTab("INV",UDim2.new(0.51,0,3),BG4)

local fC=Instance.new("Frame",m)
fC.Size=UDim2.new(1,-16,0,330)
fC.Position=UDim2.new(0,8,0,76)
fC.BackgroundTransparency=1
fC.ClipsDescendants=true
fC.Visible=true

local iC=Instance.new("Frame",m)
iC.Size=UDim2.new(1,-16,0,330)
iC.Position=UDim2.new(0,8,0,76)
iC.BackgroundTransparency=1
iC.ClipsDescendants=true
iC.Visible=false

local tabBtns={{btn=tF,cont=fC},{btn=tI,cont=iC}}
local function switchTab(active)
	for _,t in ipairs(tabBtns) do
		t.cont.Visible=(t.btn==active)
		TW(t.btn,{BackgroundColor3=t.btn==active and ACC or BG4},0.15)
		TW(t.btn,{TextColor3=t.btn==active and BG or GRAY},0.15)
	end
	if active==tI then refreshInventory() end
end
tF.MouseButton1Click:Connect(function() switchTab(tF) end)
tI.MouseButton1Click:Connect(function() switchTab(tI) end)
local statsC=Instance.new("Frame",fC)
statsC.Size=UDim2.new(1,0,0,56)
statsC.BackgroundTransparency=1

local function makeStat(par,nm,pos,col,icon)
	local card=Instance.new("Frame",par)
	card.Size=UDim2.new(0,78,0,44)
	card.Position=pos
	card.BackgroundColor3=BG2
	card.BorderSizePixel=0
	CR(card,8)
	ST(card,Color3.fromRGB(35,35,55),1)
	local ab=Instance.new("Frame",card)
	ab.Size=UDim2.new(1,-10,0,2)
	ab.Position=UDim2.new(0,5,0,4)
	ab.BackgroundColor3=col
	ab.BackgroundTransparency=0.4
	CR(ab,2)
	local il=Instance.new("TextLabel",card)
	il.Size=UDim2.new(0,18,0,14)
	il.Position=UDim2.new(0,6,0,10)
	il.BackgroundTransparency=1
	il.Text=icon
	il.TextColor3=col
	il.TextSize=11
	il.Font=Enum.Font.GothamBold
	il.TextXAlignment=Enum.TextXAlignment.Left
	local nl=Instance.new("TextLabel",card)
	nl.Size=UDim2.new(1,-26,0,12)
	nl.Position=UDim2.new(0,22,0,10)
	nl.BackgroundTransparency=1
	nl.Text=nm
	nl.TextColor3=GRAY
	nl.TextSize=7
	nl.Font=Enum.Font.GothamBold
	nl.TextXAlignment=Enum.TextXAlignment.Left
	local vl=Instance.new("TextLabel",card)
	vl.Size=UDim2.new(1,-10,0,18)
	vl.Position=UDim2.new(0,6,0,24)
	vl.BackgroundTransparency=1
	vl.Text="0"
	vl.TextColor3=col
	vl.TextSize=13
	vl.Font=Enum.Font.GothamBlack
	vl.TextXAlignment=Enum.TextXAlignment.Left
	return vl
end

local balV=makeStat(statsC,"BALANCE",UDim2.new(0,0,0,2),ACC,"$")
local itemV=makeStat(statsC,"ITEMS",UDim2.new(0,82,0,2),BLUE,"")
local soldV=makeStat(statsC,"SOLD",UDim2.new(0,164,0,2),GOLD,"")
local earnV=makeStat(statsC,"EARNED",UDim2.new(0,246,0,2),PURPLE,"$")

local function updateStats()
	balV.Text="$"..string.format("%.2f",getBal())
	itemV.Text=tostring(#inv:GetChildren())
	soldV.Text=tostring(soldCount)
	earnV.Text="$"..string.format("%.2f",totalEarned)
end

local csSec=Instance.new("Frame",fC)
csSec.Size=UDim2.new(1,0,0,162)
csSec.Position=UDim2.new(0,0,0,50)
csSec.BackgroundColor3=BG2
csSec.BorderSizePixel=0
CR(csSec,10)
ST(csSec,Color3.fromRGB(35,35,55),1)

local sTit=Instance.new("TextLabel",csSec)
sTit.Size=UDim2.new(1,-16,0,18)
sTit.Position=UDim2.new(0,14,0,8)
sTit.BackgroundTransparency=1
sTit.Text="CASE SELECTOR"
sTit.TextColor3=GRAY
sTit.TextSize=9
sTit.Font=Enum.Font.GothamBlack
sTit.TextXAlignment=Enum.TextXAlignment.Left

local selC=Instance.new("Frame",csSec)
selC.Size=UDim2.new(1,-20,0,26)
selC.Position=UDim2.new(0,10,0,22)
selC.BackgroundColor3=BG3
selC.BorderSizePixel=0
CR(selC,8)
local selS=ST(selC,ACC,1.5)

local selN=Instance.new("TextLabel",selC)
selN.Size=UDim2.new(0,160,1,0)
selN.Position=UDim2.new(0,10,0,0)
selN.BackgroundTransparency=1
selN.Text="Free"
selN.TextColor3=ACC
selN.TextSize=11
selN.Font=Enum.Font.GothamBlack
selN.TextXAlignment=Enum.TextXAlignment.Left

local selP=Instance.new("TextLabel",selC)
selP.Size=UDim2.new(0,80,1,0)
selP.Position=UDim2.new(0,168,0,0)
selP.BackgroundTransparency=1
selP.Text="$0.00"
selP.TextColor3=LGRAY
selP.TextSize=10
selP.Font=Enum.Font.GothamBold
selP.TextXAlignment=Enum.TextXAlignment.Left

local cScr=Instance.new("ScrollingFrame",csSec)
cScr.Size=UDim2.new(1,-20,0,96)
cScr.Position=UDim2.new(0,10,0,54)
cScr.BackgroundTransparency=1
cScr.BorderSizePixel=0
cScr.ScrollBarThickness=3
cScr.ScrollBarImageColor3=ACC
cScr.AutomaticCanvasSize=Enum.AutomaticSize.Y

local grd=Instance.new("UIGridLayout",cScr)
grd.CellSize=UDim2.new(0,74,0,28)
grd.CellPadding=UDim2.new(0,4,0,4)
grd.SortOrder=Enum.SortOrder.LayoutOrder

local selBtn=nil
for i,cs in ipairs(cases) do
	local af=cs.price<=getBal()
	local btn=Instance.new("TextButton",cScr)
	btn.Name=cs.name
	btn.BackgroundColor3=af and BG3 or Color3.fromRGB(35,25,25)
	btn.BorderSizePixel=0
	btn.LayoutOrder=i
	CR(btn,6)
	if i==1 then btn.BorderColor3=ACC btn.BorderSizePixel=2 selBtn=btn end
	local tl=Instance.new("Frame",btn)
	tl.Size=UDim2.new(1,-8,0,2)
	tl.Position=UDim2.new(0,4,0,4)
	tl.BackgroundColor3=cs.c
	tl.BackgroundTransparency=0.5
	CR(tl,1)
	local n=Instance.new("TextLabel",btn)
	n.Size=UDim2.new(1,-8,0,14)
	n.Position=UDim2.new(0,4,0,8)
	n.BackgroundTransparency=1
	n.Text=cs.name
	n.TextColor3=af and WHITE or Color3.fromRGB(100,70,70)
	n.TextSize=7
	n.Font=Enum.Font.GothamBold
	n.TextXAlignment=Enum.TextXAlignment.Left
	n.TextTruncate=Enum.TextTruncate.AtEnd
	local pp=Instance.new("TextLabel",btn)
	pp.Size=UDim2.new(1,-8,0,12)
	pp.Position=UDim2.new(0,4,0,22)
	pp.BackgroundTransparency=1
	pp.Text="$"..cs.price
	pp.TextColor3=cs.c
	pp.TextSize=9
	pp.Font=Enum.Font.GothamBlack
	pp.TextXAlignment=Enum.TextXAlignment.Left
	btn.MouseButton1Click:Connect(function()
		if not af then return end
		CASE_NAME=cs.name
		selN.Text=cs.name
		selN.TextColor3=cs.c
		selP.Text="$"..string.format("%.2f",cs.price)
		TW(selS,{Color=cs.c},0.2)
		if selBtn then selBtn.BorderSizePixel=0 end
		btn.BorderSizePixel=2
		btn.BorderColor3=ACC
		selBtn=btn
		for _,ch in ipairs(cScr:GetChildren()) do
			if ch:IsA("TextButton") and ch~=btn then ch.BorderSizePixel=0 end
		end
	end)
end

local asSec=Instance.new("Frame",fC)
asSec.Size=UDim2.new(1,0,0,28)
asSec.Position=UDim2.new(0,0,0,218)
asSec.BackgroundColor3=BG2
asSec.BorderSizePixel=0
CR(asSec,8)
ST(asSec,Color3.fromRGB(35,35,55),1)

local asLbl=Instance.new("TextLabel",asSec)
asLbl.Size=UDim2.new(0,200,0,28)
asLbl.Position=UDim2.new(0,10,0,0)
asLbl.BackgroundTransparency=1
asLbl.Text="AUTO-SELL"
asLbl.TextColor3=GRAY
asLbl.TextSize=9
asLbl.Font=Enum.Font.GothamBlack
asLbl.TextXAlignment=Enum.TextXAlignment.Left

local asBtn=Instance.new("TextButton",asSec)
asBtn.Size=UDim2.new(0,46,0,20)
asBtn.Position=UDim2.new(1,-56,0.5,-10)
asBtn.BackgroundColor3=ACC
asBtn.BorderSizePixel=0
asBtn.Text="ON"
asBtn.TextColor3=BG
asBtn.TextSize=10
asBtn.Font=Enum.Font.GothamBlack
CR(asBtn,6)

asBtn.MouseButton1Click:Connect(function()
	autoSell=not autoSell
	asBtn.Text=autoSell and "ON" or "OFF"
	TW(asBtn,{BackgroundColor3=autoSell and ACC or RED},0.2)
end)
local fLog=Instance.new("Frame",fC)
fLog.Size=UDim2.new(1,0,0,100)
fLog.Position=UDim2.new(0,0,0,252)
fLog.BackgroundColor3=BG2
fLog.BorderSizePixel=0
CR(fLog,8)
ST(fLog,Color3.fromRGB(35,35,55),1)

local lgTit=Instance.new("TextLabel",fLog)
lgTit.Size=UDim2.new(0,100,0,14)
lgTit.Position=UDim2.new(0,10,0,4)
lgTit.BackgroundTransparency=1
lgTit.Text="LOG"
lgTit.TextColor3=GRAY
lgTit.TextSize=8
lgTit.Font=Enum.Font.GothamBlack
lgTit.TextXAlignment=Enum.TextXAlignment.Left

local flS=Instance.new("ScrollingFrame",fLog)
flS.Size=UDim2.new(1,-12,0,80)
flS.Position=UDim2.new(0,6,0,18)
flS.BackgroundTransparency=1
flS.BorderSizePixel=0
flS.ScrollBarThickness=3
flS.ScrollBarImageColor3=ACC
flS.AutomaticCanvasSize=Enum.AutomaticSize.Y
Instance.new("UIListLayout",flS).Padding=UDim.new(0,2)

local lgO=0
local function LOG(txt,col)
	lgO=lgO+1
	local ts=os.date("%H:%M:%S")
	local l=Instance.new("Frame",flS)
	l.Size=UDim2.new(1,0,0,14)
	l.BackgroundTransparency=1
	l.LayoutOrder=lgO
	local mg=Instance.new("TextLabel",l)
	mg.Size=UDim2.new(1,0,1,0)
	mg.BackgroundTransparency=1
	mg.Text="["..ts.."] "..txt
	mg.TextColor3=col or LGRAY
	mg.TextSize=9
	mg.Font=Enum.Font.Code
	mg.TextXAlignment=Enum.TextXAlignment.Left
	flS.CanvasPosition=Vector2.new(0,flS.AbsoluteCanvasSize.Y)
end
local iH=Instance.new("Frame",iC)
iH.Size=UDim2.new(1,0,0,36)
iH.BackgroundColor3=BG2
iH.BorderSizePixel=0
CR(iH,10)
local iCnt=Instance.new("TextLabel",iH)
iCnt.Size=UDim2.new(0,150,1,0)
iCnt.Position=UDim2.new(0,14,0,0)
iCnt.BackgroundTransparency=1
iCnt.Text="Items: 0"
iCnt.TextColor3=GRAY
iCnt.TextSize=10
iCnt.Font=Enum.Font.GothamBold
iCnt.TextXAlignment=Enum.TextXAlignment.Left
local sCnt=Instance.new("TextLabel",iH)
sCnt.Size=UDim2.new(0,150,1,0)
sCnt.Position=UDim2.new(0,160,0,0)
sCnt.BackgroundTransparency=1
sCnt.Text="Selected: 0"
sCnt.TextColor3=GOLD
sCnt.TextSize=10
sCnt.Font=Enum.Font.GothamBold
sCnt.TextXAlignment=Enum.TextXAlignment.Left
local iScroll=Instance.new("ScrollingFrame",iC)
iScroll.Size=UDim2.new(1,0,0,270)
iScroll.Position=UDim2.new(0,0,0,42)
iScroll.BackgroundTransparency=1
iScroll.BorderSizePixel=0
iScroll.ScrollBarThickness=4
iScroll.ScrollBarImageColor3=ACC
iScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
Instance.new("UIListLayout",iScroll).Padding=UDim.new(0,4)
Instance.new("UIPadding",iScroll).PaddingLeft=UDim.new(0,2)
local selItems={}
local function refreshInventory()
	for _,ch in ipairs(iScroll:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
	selItems={}
	local items=inv:GetChildren()
	iCnt.Text="Items: "..#items
	sCnt.Text="Selected: 0"
	for i,item in ipairs(items) do
		local fr=Instance.new("Frame",iScroll)
		fr.Size=UDim2.new(1,-8,0,48)
		fr.BackgroundColor3=BG3
		fr.BorderSizePixel=0
		CR(fr,8)
		ST(fr,Color3.fromRGB(40,50,40),1)
		fr.LayoutOrder=i
		local check=Instance.new("TextButton",fr)
		check.Size=UDim2.new(0,32,0,32)
		check.Position=UDim2.new(0,8,0.5,-16)
		check.BackgroundColor3=BG4
		check.BorderSizePixel=0
		check.Text=""
		check.TextColor3=ACC
		check.TextSize=16
		check.Font=Enum.Font.GothamBold
		CR(check,7)
		local parts=string.split(item.Name,"_")
		local displayName=item.Name
		if #parts>=2 then displayName=parts[1].." | "..string.gsub(item.Name,parts[1].."_","") end
		local weaponIcon=Instance.new("TextLabel",fr)
		weaponIcon.Size=UDim2.new(0,24,0,24)
		weaponIcon.Position=UDim2.new(0,48,0,6)
		weaponIcon.BackgroundColor3=BG4
		weaponIcon.BorderSizePixel=0
		weaponIcon.Text="#"
		weaponIcon.TextColor3=GOLD
		weaponIcon.TextSize=12
		weaponIcon.Font=Enum.Font.GothamBlack
		CR(weaponIcon,6)
		local nL=Instance.new("TextLabel",fr)
		nL.Size=UDim2.new(1,-130,0,20)
		nL.Position=UDim2.new(0,78,0,6)
		nL.BackgroundTransparency=1
		nL.Text=displayName
		nL.TextColor3=WHITE
		nL.TextSize=12
		nL.Font=Enum.Font.GothamBold
		nL.TextXAlignment=Enum.TextXAlignment.Left
		nL.TextTruncate=Enum.TextTruncate.AtEnd
		local tL=Instance.new("TextLabel",fr)
		tL.Size=UDim2.new(1,-130,0,14)
		tL.Position=UDim2.new(0,78,0,28)
		tL.BackgroundTransparency=1
		tL.Text=item.ClassName
		tL.TextColor3=GRAY
		tL.TextSize=8
		tL.Font=Enum.Font.Code
		tL.TextXAlignment=Enum.TextXAlignment.Left
		local seB=Instance.new("TextButton",fr)
		seB.Size=UDim2.new(0,60,0,32)
		seB.Position=UDim2.new(1,-70,0.5,-16)
		seB.BackgroundColor3=Color3.fromRGB(180,60,60)
		seB.BorderSizePixel=0
		seB.Text="SELL"
		seB.TextColor3=WHITE
		seB.TextSize=10
		seB.Font=Enum.Font.GothamBlack
		CR(seB,7)
		local isSel=false
		check.MouseButton1Click:Connect(function()
			isSel=not isSel
			if isSel then
				selItems[item.Name]=item
				check.Text="OK"
				check.BackgroundColor3=ACC
				check.TextColor3=BG
				TW(fr,{BackgroundColor3=Color3.fromRGB(28,48,38)},0.15)
				fr.BorderSizePixel=1
			else
				selItems[item.Name]=nil
				check.Text=""
				check.BackgroundColor3=BG4
				TW(fr,{BackgroundColor3=BG3},0.15)
			end
			local cnt=0
			for _ in pairs(selItems) do cnt=cnt+1 end
			sCnt.Text="Selected: "..cnt
		end)
		seB.MouseButton1Click:Connect(function()
			seB.Text="..."
			seB.BackgroundColor3=Color3.fromRGB(120,120,40)
			local ok=trySell(item)
			if ok then
				seB.Text="SOLD"
				seB.BackgroundColor3=ACC2
				soldCount=soldCount+1
				LOG("Sold: "..displayName,ACC2)
				task.wait(1)
				refreshInventory()
				updateStats()
			else
				seB.Text="FAIL"
				seB.BackgroundColor3=RED
				LOG("Failed: "..displayName,RED)
				task.wait(3)
				seB.Text="SELL"
				seB.BackgroundColor3=Color3.fromRGB(180,60,60)
			end
		end)
		seB.MouseEnter:Connect(function() TW(seB,{BackgroundColor3=Color3.fromRGB(220,80,80)},0.15) end)
		seB.MouseLeave:Connect(function() if seB.Text=="SELL" then TW(seB,{BackgroundColor3=Color3.fromRGB(180,60,60)},0.15) end end)
	end
end
local iBtn=Instance.new("Frame",iC)
iBtn.Size=UDim2.new(1,0,0,28)
iBtn.Position=UDim2.new(0,0,0,318)
iBtn.BackgroundTransparency=1
local function iB(txt,pos,col)
	local b=Instance.new("TextButton",iBtn)
	b.Size=UDim2.new(0,96,0,24)
	b.Position=pos
	b.BackgroundColor3=col
	b.BorderSizePixel=0
	b.Text=txt
	b.TextColor3=BG
	b.TextSize=9
	b.Font=Enum.Font.GothamBlack
	CR(b,7)
	b.MouseEnter:Connect(function() TW(b,{BackgroundColor3=WHITE},0.15) end)
	b.MouseLeave:Connect(function() TW(b,{BackgroundColor3=col},0.15) end)
	return b
end
iB("SELL ALL",UDim2.new(0,0,0,2),ACC).MouseButton1Click:Connect(function()
	local items=inv:GetChildren()
	if #items==0 then LOG("Inventory empty",GRAY) return end
	LOG("Selling all "..#items.." items...",ACC)
	local bBefore=getBal()
	local fired=fireAllSell()
	LOG("Fired "..fired.." sell button(s)",GOLD)
	task.wait(0.8)
	local bAfter=getBal()
	if bAfter>bBefore then
		local gain=bAfter-bBefore
		totalEarned=totalEarned+gain
		soldCount=soldCount+1
		LOG("Sold! +$"..string.format("%.2f",gain),ACC2)
	else
		LOG("No balance change - try opening the inventory in-game first",RED)
	end
	LOG("Done",ACC)
	refreshInventory()
	updateStats()
end)
iB("SELL SELECTED",UDim2.new(0,100,0,2),BLUE).MouseButton1Click:Connect(function()
	local cnt=0
	for _ in pairs(selItems) do cnt=cnt+1 end
	if cnt==0 then LOG("No selection",GRAY) return end
	for nm,item in pairs(selItems) do
		local ok=trySell(item)
		if ok then soldCount=soldCount+1 LOG("Sold: "..nm,ACC2) else LOG("Failed: "..nm,RED) end
		task.wait(3)
	end
	selItems={}
	LOG("Done",ACC)
	refreshInventory()
	updateStats()
end)
iB("REFRESH",UDim2.new(0,204,0,2),GOLD).MouseButton1Click:Connect(function() refreshInventory() end)


local bot=Instance.new("Frame",m)
bot.Size=UDim2.new(1,0,0,46)
bot.Position=UDim2.new(0,0,1,-46)
bot.BackgroundColor3=Color3.fromRGB(10,10,18)
bot.BorderSizePixel=0
CR(bot,14)

local startBtn=Instance.new("TextButton",bot)
startBtn.Size=UDim2.new(0,120,0,30)
startBtn.Position=UDim2.new(0,10,0.5,-15)
startBtn.BackgroundColor3=ACC
startBtn.BorderSizePixel=0
startBtn.Text="START [F2]"
startBtn.TextColor3=BG
startBtn.TextSize=11
startBtn.Font=Enum.Font.GothamBlack
CR(startBtn,8)

local stopBtn=Instance.new("TextButton",bot)
stopBtn.Size=UDim2.new(0,110,0,30)
stopBtn.Position=UDim2.new(0,138,0.5,-15)
stopBtn.BackgroundColor3=RED
stopBtn.BorderSizePixel=0
stopBtn.Text="STOP [F3]"
stopBtn.TextColor3=WHITE
stopBtn.TextSize=11
stopBtn.Font=Enum.Font.GothamBlack
CR(stopBtn,8)

local titL=Instance.new("TextLabel",bot)
titL.Size=UDim2.new(0,100,0,18)
titL.Position=UDim2.new(1,-108,0,3)
titL.BackgroundTransparency=1
titL.Text="CASE PARADISE"
titL.TextColor3=ACC
titL.TextSize=10
titL.Font=Enum.Font.GothamBlack
titL.TextXAlignment=Enum.TextXAlignment.Right

local timeL=Instance.new("TextLabel",bot)
timeL.Size=UDim2.new(0,100,0,14)
timeL.Position=UDim2.new(1,-108,0,22)
timeL.BackgroundTransparency=1
timeL.Text="00:00:00"
timeL.TextColor3=GRAY
timeL.TextSize=9
timeL.Font=Enum.Font.Code
timeL.TextXAlignment=Enum.TextXAlignment.Right

startBtn.MouseEnter:Connect(function() TW(startBtn,{BackgroundColor3=Color3.fromRGB(80,255,140)},0.15) end)
startBtn.MouseLeave:Connect(function() TW(startBtn,{BackgroundColor3=ACC},0.15) end)
stopBtn.MouseEnter:Connect(function() TW(stopBtn,{BackgroundColor3=Color3.fromRGB(255,100,100)},0.15) end)
stopBtn.MouseLeave:Connect(function() TW(stopBtn,{BackgroundColor3=RED},0.15) end)

startBtn.MouseButton1Click:Connect(function()
	if run then return end
	run=true
	startBtn.Text="RUNNING..."
	TW(startBtn,{BackgroundColor3=Color3.fromRGB(80,130,60)},0.2)
	LOG(">> Start | Case: "..CASE_NAME.." | Sell: "..(autoSell and "ON" or "OFF"),ACC)
	startTime=os.time()
	rounds=0
	soldCount=0
	totalEarned=0
	sellFailCount=0
	local oc=f:FindFirstChild("OpenCase")
	if not oc then LOG("ERROR: OpenCase not found!",RED) run=false startBtn.Text="START [F2]" TW(startBtn,{BackgroundColor3=ACC},0.2) return end
	while run do
		if oc then
			local cdLeft=getCooldown()
			if cdLeft>0 then
				LOG("Cooldown: wait "..string.format("%.1f",cdLeft).."s",GOLD)
				task.wait(cdLeft+0.3)
			end
			local ok,r=pcall(function() return oc:InvokeServer(CASE_NAME,1) end)
			if ok and type(r)=="table" and r[1] then
				rounds=rounds+1
				LOG("#"..rounds.." "..r[1].Item.." Bal: $"..string.format("%.2f",getBal()),Color3.fromRGB(120,230,160))
				LOG("autoSell="..tostring(autoSell).." failCount="..sellFailCount,GOLD)
				if autoSell and sellFailCount<SELL_MAX_FAIL then
					local bBefore=getBal()
					local sold=false
					for attempt=1,4 do
						local ok2,fired=pcall(function() return fireAllSell() end)
						LOG("Attempt "..attempt..": ok="..tostring(ok2).." fired="..tostring(fired),GRAY)
						if ok2 and fired>0 then
							task.wait(0.6)
							local bAfter=getBal()
							if bAfter>bBefore then
								sold=true
								totalEarned=totalEarned+(bAfter-bBefore)
								break
							end
						end
						task.wait(0.5)
					end
					local bAfter=getBal()
					if sold or bAfter>bBefore then
						soldCount=soldCount+1
						sellFailCount=0
						if bAfter>bBefore then
							LOG("Sold! +$"..string.format("%.2f",bAfter-bBefore),ACC2)
						end
					else
						sellFailCount=sellFailCount+1
						LOG("Fail ("..sellFailCount.."/"..SELL_MAX_FAIL..")",RED)
						if sellFailCount>=SELL_MAX_FAIL then
							LOG("Auto-sell DISABLED",RED)
						end
					end
				end
				updateStats()
			else
				local stillCd=getCooldown()
				if stillCd>0 then
					LOG("Open blocked (cooldown), wait "..string.format("%.1f",stillCd).."s",GOLD)
					task.wait(stillCd+0.3)
				else
					local isCd=false
					if type(r)=="string" and r:lower():find("cooldown") then isCd=true end
					if type(r)=="table" then
						for _,v in pairs(r) do
							if type(v)=="string" and v:lower():find("cooldown") then isCd=true end
						end
					end
					if isCd then
						LOG("Open blocked (cooldown), wait 3s",GOLD)
						task.wait(3)
					else
						LOG("Case failed (no item returned)",RED)
						task.wait(2)
					end
				end
			end
		end
		if not run then break end
		task.wait(1)
		updateStats()
	end
	LOG(">> Stop | Cases: "..rounds.." Sold: "..soldCount,RED)
	startBtn.Text="START [F2]"
	TW(startBtn,{BackgroundColor3=ACC},0.2)
	updateStats()
end)

stopBtn.MouseButton1Click:Connect(function()
	run=false
	LOG(">> Stopping...",GOLD)
end)

LOG("Case Paradise v9.0 [DELTA]",ACC)
LOG("VIM: "..tostring(hasVIM).." | GC: "..tostring(hasGC),LGRAY)
LOG("Sell: "..tostring(f:FindFirstChild("Sell")~= nil).." | Open: "..tostring(f:FindFirstChild("OpenCase")~= nil),ACC)
updateStats()
refreshInventory()

task.spawn(function()
	while sg.Parent do
		updateStats()
		if run and startTime>0 then
			local el=os.time()-startTime
			timeL.Text=string.format("%02d:%02d:%02d",math.floor(el/3600),math.floor((el%3600)/60),el%60)
		end
		task.wait(1)
	end
end)
