local P   = game:GetService("Players")
local RS  = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TS  = game:GetService("TweenService")
local VIM = game:FindService("VirtualInputManager")
local pl  = P.LocalPlayer
local pd  = pl:WaitForChild("PlayerData")
local inv = pd:WaitForChild("Inventory")
local f   = RS:WaitForChild("Remotes")
local rem = f  -- alias (fixes rem references throughout)

local hasGC=false
pcall(function() hasGC=#getconnections(Instance.new("BindableEvent"))>0 end)
local hasVIM   = VIM~=nil
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled


local run=false; local battleRun=false; local questRun=false
local SELECTED_KEY="FREE"; local SELECTED_FREE=true; local SELECTED_PRICE=0
local rounds=0; local soldCount=0; local totalEarned=0; local startTime=0
local autoSell=true; local lastSellTime=0; local SELL_CD=3
local sellFails=0; local MAX_SELL_FAIL=3
local battleWins=0; local battleTotal=0

local old=pl.PlayerGui:FindFirstChild("CP15"); if old then old:Destroy() end
local sg=Instance.new("ScreenGui",pl.PlayerGui)
sg.Name="CP15"; sg.ResetOnSpawn=false; sg.DisplayOrder=999


local C={
    bg    = Color3.fromRGB(30, 31, 38),
    bg1   = Color3.fromRGB(36, 37, 46),
    bg2   = Color3.fromRGB(43, 45, 56),
    bg3   = Color3.fromRGB(52, 54, 68),
    bg4   = Color3.fromRGB(62, 65, 82),
    line  = Color3.fromRGB(55, 57, 72),
    acc   = Color3.fromRGB(78, 150, 240),   -- blue
    acc2  = Color3.fromRGB(80, 210, 120),   -- green
    red   = Color3.fromRGB(215, 70, 70),
    yel   = Color3.fromRGB(225, 185, 55),
    wht   = Color3.fromRGB(210, 215, 225),
    lgr   = Color3.fromRGB(150, 155, 175),
    gry   = Color3.fromRGB(105, 110, 135),
    blk   = Color3.fromRGB(18,  19,  24),
    pur   = Color3.fromRGB(165, 95, 250),
    ton   = Color3.fromRGB(70,  185, 100),
    toff  = Color3.fromRGB(65,  68,  88),
}


local function TW(o,p,t) TS:Create(o,TweenInfo.new(t or .15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),p):Play() end
local function CR(o,r) local c=Instance.new("UICorner",o);c.CornerRadius=UDim.new(0,r or 4) end
local function DIV(par,y,col) -- horizontal divider
    local d=Instance.new("Frame",par);d.Size=UDim2.new(1,0,0,1);d.Position=UDim2.new(0,0,0,y)
    d.BackgroundColor3=col or C.line;d.BorderSizePixel=0;return d
end
local function LBL(par,txt,y,col,sz,bold,xalign)
    local l=Instance.new("TextLabel",par);l.Size=UDim2.new(1,-8,0,12);l.Position=UDim2.new(0,4,0,y)
    l.BackgroundTransparency=1;l.Text=txt;l.TextColor3=col or C.lgr
    l.TextSize=sz or 7;l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextXAlignment=xalign or Enum.TextXAlignment.Left;return l
end
local function BTN(par,txt,x,y,w,h,col)
    local b=Instance.new("TextButton",par);b.Size=UDim2.new(0,w,0,h);b.Position=UDim2.new(0,x,0,y)
    b.BackgroundColor3=col or C.bg3;b.BorderSizePixel=0;b.Text=txt;b.TextColor3=C.wht
    b.TextSize=7;b.Font=Enum.Font.GothamBold;CR(b,3)
    b.MouseEnter:Connect(function() TW(b,{BackgroundColor3=C.bg4},.08) end)
    b.MouseLeave:Connect(function() TW(b,{BackgroundColor3=col or C.bg3},.08) end)
    return b
end
local function SCROLL(par,x,y,w,h)
    local s=Instance.new("ScrollingFrame",par);s.Size=UDim2.new(0,w,0,h);s.Position=UDim2.new(0,x,0,y)
    s.BackgroundTransparency=1;s.BorderSizePixel=0
    s.ScrollBarThickness=isMobile and 5 or 3
    s.ScrollBarImageColor3=C.acc
    s.AutomaticCanvasSize=Enum.AutomaticSize.Y;return s
end

local function Toggle(par,x,y,init,cb)
    local tr=Instance.new("Frame",par);tr.Size=UDim2.new(0,22,0,10);tr.Position=UDim2.new(0,x,0,y)
    tr.BackgroundColor3=init and C.ton or C.toff;tr.BorderSizePixel=0;CR(tr,5)
    local kn=Instance.new("Frame",tr);kn.Size=UDim2.new(0,7,0,7);kn.Position=init and UDim2.new(1,-9,.5,-3.5) or UDim2.new(0,1.5,.5,-3.5)
    kn.BackgroundColor3=C.wht;kn.BorderSizePixel=0;CR(kn,3.5)
    local st=init
    local tb=Instance.new("TextButton",tr);tb.Size=UDim2.new(1,0,1,0);tb.BackgroundTransparency=1;tb.Text=""
    tb.MouseButton1Click:Connect(function()
        st=not st;TW(tr,{BackgroundColor3=st and C.ton or C.toff},.12)
        TW(kn,{Position=st and UDim2.new(1,-9,.5,-3.5) or UDim2.new(0,1.5,.5,-3.5)},.12)
        if cb then cb(st) end
    end)
    return tr
end


local function getBal()
    local c=pd:FindFirstChild("Currencies");if c then local b=c:FindFirstChild("Balance");if b then return b.Value end end;return 0
end
local function getHolos()
    local c=pd:FindFirstChild("Currencies");if c then local t=c:FindFirstChild("Tickets");if t then return t.Value end end;return 0
end
local function getCooldown(key)
    local cc=f:FindFirstChild("CheckCooldown");if not cc then return 0 end
    local ok,r=pcall(function() return cc:InvokeServer(key) end)
    if not ok or r==nil then return 0 end
    if type(r)=="number" then return math.max(0,r) end
    if type(r)=="string" then return tonumber(r:match("[%d%.]+")) or 0 end
    if type(r)=="boolean" then return 0 end
    if type(r)=="table" then
        for _,k in ipairs({"TimeLeft","Cooldown","time","Remaining","seconds","cd","Time"}) do
            if r[k] then local v=r[k]
                if type(v)=="number" then return math.max(0,v) end
                if type(v)=="string" then return tonumber(v:match("[%d%.]+")) or 0 end
            end
        end
        if r[1] then
            if type(r[1])=="number" then return math.max(0,r[1]) end
            if type(r[1])=="string" then return tonumber(r[1]:match("[%d%.]+")) or 0 end
        end
    end
    return 0
end


local function fireBtnConnections(btn)
    if not btn then return false end;local fired=false
    if hasGC then
        for _,ev in ipairs({"MouseButton1Click","Activated"}) do
            local ok,conns=pcall(function() return getconnections(btn[ev]) end)
            if ok and conns then for _,cn in ipairs(conns) do pcall(function() cn:Fire() end);fired=true end end
        end
    end
    pcall(function() btn:Activate();fired=true end);return fired
end
local function vClick(btn)
    if not btn then return false end
    if hasVIM then local ok=pcall(function()
        local x=btn.AbsolutePosition.X+btn.AbsoluteSize.X/2
        local y=btn.AbsolutePosition.Y+btn.AbsoluteSize.Y/2
        VIM:SendMouseButtonEvent(x,y,0,true,workspace.CurrentCamera,1);task.wait(0.05)
        VIM:SendMouseButtonEvent(x,y,0,false,workspace.CurrentCamera,1)
    end);if ok then return true end end
    pcall(function() btn:Activate() end);pcall(function() btn.MouseButton1Click:Fire() end)
    pcall(function() btn.Activated:Fire() end);return true
end
local function findBtn(par,name,d)
    if d>10 then return nil end
    local ok,ch=pcall(function() return par:GetChildren() end);if not ok then return nil end
    for _,o in ipairs(ch) do
        if (o:IsA("TextButton") or o:IsA("ImageButton")) then local nm="";pcall(function() nm=o.Name end);if nm==name then return o end end
        if o:IsA("Frame") or o:IsA("ScrollingFrame") or o:IsA("ScreenGui") then local r=findBtn(o,name,d+1);if r then return r end end
    end
end
local function findBtnByName(n) for _,g in ipairs(pl.PlayerGui:GetChildren()) do if g:IsA("ScreenGui") then local r=findBtn(g,n,0);if r then return r end end end end
local function findAllSellBtns()
    local found={}
    local function scan(p,d) if d>14 then return end
        local ok,ch=pcall(function() return p:GetChildren() end);if not ok then return end
        for _,o in ipairs(ch) do
            if (o:IsA("TextButton") or o:IsA("ImageButton")) then local nm="";pcall(function() nm=o.Name end);if nm:lower():find("sell") then table.insert(found,o) end end
            if o:IsA("Frame") or o:IsA("ScrollingFrame") or o:IsA("ScreenGui") or o:IsA("ImageLabel") or o:IsA("ImageButton") or o:IsA("ViewportFrame") then scan(o,d+1) end
        end
    end
    for _,g in ipairs(pl.PlayerGui:GetChildren()) do if g:IsA("ScreenGui") then scan(g,0) end end;return found
end
local function findInvSell()
    local sellBtn,contents=nil,nil
    local function scan(p,d) if d>10 or sellBtn then return end
        local ok,ch=pcall(function() return p:GetChildren() end);if not ok then return end
        for _,c2 in ipairs(ch) do
            if c2:IsA("Frame") then
                local s=c2:FindFirstChild("Sell");local ic=c2:FindFirstChild("InventoryFrame")
                if s and s:IsA("TextButton") and ic then sellBtn=s;contents=ic:FindFirstChild("Contents") or ic;return end
                scan(c2,d+1);if sellBtn then return end
            end
        end
    end
    for _,g in ipairs(pl.PlayerGui:GetChildren()) do if g:IsA("ScreenGui") then scan(g,0) end;if sellBtn then break end end
    return sellBtn,contents
end
local LOG_F  -- assigned after GUI
local logN=0
local function LOG(txt,col)
    logN=logN+1;if not LOG_F then return end
    local ts=os.date("%H:%M:%S")
    local row=Instance.new("Frame",LOG_F);row.Size=UDim2.new(1,0,0,10);row.BackgroundTransparency=1;row.LayoutOrder=logN
    local mg=Instance.new("TextLabel",row);mg.Size=UDim2.new(1,0,1,0);mg.BackgroundTransparency=1
    mg.Text="["..ts.."] "..txt;mg.TextColor3=col or C.lgr;mg.TextSize=6;mg.Font=Enum.Font.Code;mg.TextXAlignment=Enum.TextXAlignment.Left
    task.defer(function() pcall(function() LOG_F.CanvasPosition=Vector2.new(0,1e9) end) end)
end
local function buildSellTable(items)
    local t={}
    for _,it in ipairs(items) do
        t[#t+1]={
            Name=it.Name,
            Wear=it:GetAttribute("Wear") or "",
            Stattrak=it:GetAttribute("Stattrak") or false,
            Age=it:GetAttribute("TimeObtained") or 0,
            UUID=it:GetAttribute("UUID") or tostring(math.random(100000,999999)),
        }
    end
    return t
end
local function fireAllSell()
    local fired=0
    local sr=f:FindFirstChild("Sell")
    if sr then
        local itemsNow=inv:GetChildren()
        if #itemsNow>0 then
            local t=buildSellTable(itemsNow)
            local ok,r=pcall(function() return sr:InvokeServer(t) end)
            if ok and r~=nil then fired=fired+1 end
            if not ok or r==nil then pcall(function() sr:FireServer(t) end); fired=fired+1 end
        end
    end
    return fired
end
local function doSellItems(items)
    if #items==0 then return false end
    local sr=f:FindFirstChild("Sell"); if not sr then return false end
    local bb=getBal()
    local t=buildSellTable(items)
    local ok,r=pcall(function() return sr:InvokeServer(t) end)
    if ok and r~=nil then task.wait(0.8); return getBal()>bb end
    pcall(function() sr:FireServer(t) end)
    task.wait(0.8)
    return getBal()>bb
end
local function trySell(item)
    local el=os.time()-lastSellTime; if el<SELL_CD then task.wait(SELL_CD-el) end
    local bb=getBal()
    fireAllSell()
    task.wait(1.0)
    local ba=getBal()
    if ba>bb then totalEarned=totalEarned+(ba-bb); lastSellTime=os.time(); return true end
    lastSellTime=os.time(); return false
end


local CASES={
    {n="Free",        k="Free",          p=0,      f=true,  c=Color3.fromRGB(150,150,160)},

    {n="VIP",         k="VIP",           p=0,      f=true,  c=Color3.fromRGB(220,180,50)},
    {n="Medal",       k="MEDAL",         p=0,      f=true,  c=Color3.fromRGB(200,160,60)},
    {n="Roblox+",     k="ROBLOXPLUS",    p=0,      f=true,  c=Color3.fromRGB(100,180,100)},
    {n="Perchance",   k="Perchance",     p=0.37,   f=false, c=Color3.fromRGB(140,200,140)},
    {n="Military",    k="Military",      p=0.67,   f=false, c=Color3.fromRGB(140,165,140)},
    {n="Mil-Spec",    k="MILSPEC",       p=1.30,   f=false, c=Color3.fromRGB(100,160,255)},
    {n="Oblivion",    k="Oblivion",      p=1.70,   f=false, c=Color3.fromRGB(100,160,255)},
    {n="Jungle",      k="Jungle",        p=2.00,   f=false, c=Color3.fromRGB(100,160,255)},
    {n="GLOCK-18",    k="GLOCK18",       p=3.30,   f=false, c=Color3.fromRGB(80,200,100)},
    {n="Restricted",  k="RESTRICTED",    p=3.60,   f=false, c=Color3.fromRGB(80,200,100)},
    {n="Void",        k="Void",          p=3.80,   f=false, c=Color3.fromRGB(80,200,100)},
    {n="Starter",     k="STARTER",       p=4.00,   f=false, c=Color3.fromRGB(80,200,100)},
    {n="Nightmare",   k="NIGHTMARE",     p=4.00,   f=false, c=Color3.fromRGB(80,200,100)},
    {n="Energy",      k="ENERGY",        p=4.40,   f=false, c=Color3.fromRGB(80,200,100)},
    {n="Franklin",    k="Franklin",      p=5.30,   f=false, c=Color3.fromRGB(140,100,255)},
    {n="Toy",         k="TOY",           p=6.40,   f=false, c=Color3.fromRGB(140,100,255)},
    {n="USP-S",       k="USP",           p=6.50,   f=false, c=Color3.fromRGB(140,100,255)},
    {n="Disarray",    k="DISARRAY",      p=7.20,   f=false, c=Color3.fromRGB(140,100,255)},
    {n="Elemental",   k="ELEMENTAL",     p=7.70,   f=false, c=Color3.fromRGB(140,100,255)},
    {n="Inferno",     k="Inferno",       p=8.40,   f=false, c=Color3.fromRGB(170,80,255)},
    {n="AK-47",       k="AK47",          p=9.00,   f=false, c=Color3.fromRGB(170,80,255)},
    {n="M4A4",        k="M4A4",          p=9.00,   f=false, c=Color3.fromRGB(170,80,255)},
    {n="Breach",      k="BREACH",        p=9.00,   f=false, c=Color3.fromRGB(170,80,255)},
    {n="Desolate",    k="Desolate",      p=9.60,   f=false, c=Color3.fromRGB(170,80,255)},
    {n="Techno",      k="TECHNO",        p=10.00,  f=false, c=Color3.fromRGB(170,80,255)},
    {n="AWP",         k="AWP",           p=10.40,  f=false, c=Color3.fromRGB(170,80,255)},
    {n="Tech",        k="TECH",          p=11.00,  f=false, c=Color3.fromRGB(170,80,255)},
    {n="Advanced",    k="ADVANCED",      p=11.00,  f=false, c=Color3.fromRGB(170,80,255)},
    {n="Classified",  k="CLASSIFIED",    p=13.00,  f=false, c=Color3.fromRGB(170,80,255)},
    {n="Sakura",      k="Sakura",        p=16.40,  f=false, c=Color3.fromRGB(220,165,40)},
    {n="Risky",       k="Risky",         p=18.00,  f=false, c=Color3.fromRGB(220,165,40)},
    {n="Circuit",     k="CIRCUIT",       p=24.00,  f=false, c=Color3.fromRGB(220,165,40)},
    {n="Covert",      k="COVERT",        p=25.60,  f=false, c=Color3.fromRGB(220,165,40)},
    {n="Elite",       k="ELITE",         p=29.00,  f=false, c=Color3.fromRGB(220,165,40)},
    {n="Beast",       k="Beast",         p=30.00,  f=false, c=Color3.fromRGB(220,165,40)},
    {n="Industrial",  k="Industrial",    p=34.50,  f=false, c=Color3.fromRGB(230,120,40)},
    {n="Jacob",       k="Jacob",         p=36.00,  f=false, c=Color3.fromRGB(210,60,60)},
    {n="Neon",        k="Neon",          p=38.00,  f=false, c=Color3.fromRGB(210,60,60)},
    {n="Cheese",      k="CHEESE",        p=45.00,  f=false, c=Color3.fromRGB(210,60,60)},
    {n="Iris",        k="Iris",          p=52.00,  f=false, c=Color3.fromRGB(180,100,255)},
    {n="Vaporwave",   k="Vaporwave",     p=58.00,  f=false, c=Color3.fromRGB(200,50,50)},
    {n="Bloodsport",  k="Bloodsport",    p=61.80,  f=false, c=Color3.fromRGB(200,50,50)},
    {n="Hardened",    k="Hardened",      p=76.00,  f=false, c=Color3.fromRGB(200,50,50)},
    {n="Exotic",      k="Exotic",        p=80.00,  f=false, c=Color3.fromRGB(200,50,50)},
    {n="Frosty",      k="Frosty",        p=86.00,  f=false, c=Color3.fromRGB(200,50,50)},
    {n="Ultra",       k="ULTRA",         p=110.00, f=false, c=Color3.fromRGB(180,30,30)},
    {n="Frostbite",   k="Frostbite",     p=110.00, f=false, c=Color3.fromRGB(180,30,30)},
    {n="Tiger",       k="Tiger",         p=114.00, f=false, c=Color3.fromRGB(180,30,30)},
    {n="Cobalt",      k="Cobalt",        p=130.00, f=false, c=Color3.fromRGB(180,30,30)},
    {n="Knife",       k="KNIFE",         p=150.00, f=false, c=Color3.fromRGB(160,20,20)},
    {n="Royal",       k="ROYAL",         p=172.00, f=false, c=Color3.fromRGB(160,20,20)},
    {n="Fade",        k="FADE",          p=179.00, f=false, c=Color3.fromRGB(160,20,20)},
    {n="Radiation",   k="RADIATION",     p=200.00, f=false, c=Color3.fromRGB(140,10,10)},
    {n="Hazardous",   k="HAZARDOUS",     p=270.00, f=false, c=Color3.fromRGB(140,10,10)},
    {n="Gloves",      k="GLOVES",        p=280.00, f=false, c=Color3.fromRGB(140,10,10)},
    {n="Giercz",      k="GIERCZ",        p=300.00, f=false, c=Color3.fromRGB(120,10,10)},
    {n="Abyssal",     k="ABYSSAL",       p=590.00, f=false, c=Color3.fromRGB(100,10,10)},
    {n="Emerald",     k="EMERALD",       p=680.00, f=false, c=Color3.fromRGB(100,10,10)},
    {n="S1mple's",    k="S1MPLE",        p=750.00, f=false, c=Color3.fromRGB(80,10,10)},
    {n="Fifis",       k="FIFIS",         p=750.00, f=false, c=Color3.fromRGB(80,10,10)},
    {n="Luxurious",   k="LUXURIOUS",     p=790.00, f=false, c=Color3.fromRGB(80,10,10)},
    {n="Howling",     k="HOWLING",       p=900.00, f=false, c=Color3.fromRGB(60,10,10)},
    {n="Master",      k="MASTER",        p=940.00, f=false, c=Color3.fromRGB(60,10,10)},
    {n="Piqru",       k="PIQRU",         p=1000.0, f=false, c=Color3.fromRGB(60,10,10)},
    {n="Lore",        k="LORE",          p=1180.0, f=false, c=Color3.fromRGB(40,10,10)},
    {n="Decima",      k="DECIMA",        p=1440.0, f=false, c=Color3.fromRGB(40,10,10)},
    {n="Light's",     k="LIGHTS",        p=2800.0, f=false, c=Color3.fromRGB(30,5,5)},
    
    {n="Lv 10",  k="LEVEL10",  p=0,f=true,c=Color3.fromRGB(60,180,120)},
    {n="Lv 20",  k="LEVEL20",  p=0,f=true,c=Color3.fromRGB(60,180,120)},
    {n="Lv 30",  k="LEVEL30",  p=0,f=true,c=Color3.fromRGB(60,180,120)},
    {n="Lv 40",  k="LEVEL40",  p=0,f=true,c=Color3.fromRGB(60,180,120)},
    {n="Lv 50",  k="LEVEL50",  p=0,f=true,c=Color3.fromRGB(60,195,130)},
    {n="Lv 60",  k="LEVEL60",  p=0,f=true,c=Color3.fromRGB(60,195,130)},
    {n="Lv 70",  k="LEVEL70",  p=0,f=true,c=Color3.fromRGB(60,195,130)},
    {n="Lv 80",  k="LEVEL80",  p=0,f=true,c=Color3.fromRGB(60,210,140)},
    {n="Lv 90",  k="LEVEL90",  p=0,f=true,c=Color3.fromRGB(60,210,140)},
    {n="Lv 100", k="LEVEL100", p=0,f=true,c=Color3.fromRGB(60,220,150)},
    {n="Lv 110", k="LEVEL110", p=0,f=true,c=Color3.fromRGB(60,220,150)},
    {n="Lv 120", k="LEVEL120", p=0,f=true,c=Color3.fromRGB(60,225,160)},
    {n="Lv 130", k="LEVEL130", p=0,f=true,c=Color3.fromRGB(60,225,160)},
    -- 50/50
    {n="50/50 GLOCK",  k="5050GLOCK",  p=0.98,   f=false,c=Color3.fromRGB(100,200,100)},
    {n="50/50 USP",    k="5050USP",    p=2.58,   f=false,c=Color3.fromRGB(100,200,100)},
    {n="50/50 AWP",    k="5050AWP",    p=15.00,  f=false,c=Color3.fromRGB(100,200,100)},
    {n="50/50 DEAGLE", k="5050DEAGLE", p=22.60,  f=false,c=Color3.fromRGB(100,200,100)},
    {n="50/50 M4A1",   k="5050M4A1",   p=58.00,  f=false,c=Color3.fromRGB(80,180,80)},
    {n="50/50 AK-47",  k="5050AK47",   p=126.50, f=false,c=Color3.fromRGB(80,180,80)},
    {n="50/50 KNIFE",  k="5050KNIFE",  p=246.00, f=false,c=Color3.fromRGB(60,160,60)},
    {n="50/50 GLOVES", k="5050GLOVES", p=570.00, f=false,c=Color3.fromRGB(60,160,60)},
    
    {n="Krakow 2017",  k="KRAKOW2017",    p=23.50,  f=false,c=Color3.fromRGB(220,165,40)},
    {n="DreamHack 14", k="DREAMHACK2014", p=500.00, f=false,c=Color3.fromRGB(220,165,40)},
    {n="Kato 2014 L",  k="KATO2014L",     p=5600.0, f=false,c=Color3.fromRGB(220,150,30)},
    {n="Kato 2014 C",  k="KATO2014C",     p=5800.0, f=false,c=Color3.fromRGB(220,150,30)},
}

SELECTED_KEY=CASES[1].k; SELECTED_FREE=CASES[1].f; SELECTED_PRICE=CASES[1].p


local W = isMobile and 210 or 340
local H = isMobile and 210 or 280


local m=Instance.new("Frame",sg)
m.Name="CP15Main"; m.Size=UDim2.new(0,W,0,0)
m.Position=UDim2.new(.5,-W/2,.5,0)
m.BackgroundColor3=C.bg; m.BorderSizePixel=0
m.Active=true; m.Draggable=true; m.ClipsDescendants=true
m.BackgroundTransparency=1; CR(m,4)

local mStroke=Instance.new("UIStroke",m); mStroke.Color=C.acc; mStroke.Thickness=1.2; mStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border


task.wait(0.15)
TW(m,{Size=UDim2.new(0,W,0,H),Position=UDim2.new(.5,-W/2,.5,-H/2),BackgroundTransparency=0},.35)

local menuOpen=true
local function openMenu()
    menuOpen=true; m.Visible=true; m.BackgroundTransparency=1
    TW(m,{Size=UDim2.new(0,W,0,H),Position=UDim2.new(.5,-W/2,.5,-H/2),BackgroundTransparency=0},.3)
end
local function closeMenu()
    menuOpen=false
    TW(m,{Size=UDim2.new(0,W,0,0),Position=UDim2.new(.5,-W/2,.5,0),BackgroundTransparency=1},.2)
    task.delay(.25,function() if not menuOpen then m.Visible=false end end)
end


local tBarH = isMobile and 18 or 14
local tBar=Instance.new("Frame",m)
tBar.Size=UDim2.new(1,0,0,tBarH); tBar.BackgroundColor3=C.blk; tBar.BorderSizePixel=0; CR(tBar,4)


local accent=Instance.new("Frame",tBar); accent.Size=UDim2.new(1,0,0,1); accent.Position=UDim2.new(0,0,1,-1)
accent.BackgroundColor3=C.acc; accent.BorderSizePixel=0


local ico=Instance.new("Frame",tBar); ico.Size=UDim2.new(0,8,0,8); ico.Position=UDim2.new(0,3,.5,-4)
ico.BackgroundColor3=C.acc; ico.BorderSizePixel=0; CR(ico,2)

local function tLbl(txt,x,col,sz,bold)
    local l=Instance.new("TextLabel",tBar); l.Size=UDim2.new(0,200,1,0); l.Position=UDim2.new(0,x,0,0)
    l.BackgroundTransparency=1; l.Text=txt; l.TextColor3=col or C.lgr; l.TextSize=sz or 7
    l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham; l.TextXAlignment=Enum.TextXAlignment.Left; return l
end
tLbl("Case Paradise  Autofarm v16",12,C.wht,7,true)
tLbl(isMobile and "iPhone" or "PC  |  Ins=menu  Home=start  End=stop",120,C.gry,6,false)

local function hBtn(txt,xo,bg)
    local sz = isMobile and 16 or 12
    local b=Instance.new("TextButton",tBar); b.Size=UDim2.new(0,sz,0,sz-4); b.Position=UDim2.new(1,xo,.5,-(sz-4)/2)
    b.BackgroundColor3=bg; b.BorderSizePixel=0; b.Text=txt; b.TextColor3=C.wht
    b.TextSize=isMobile and 8 or 7; b.Font=Enum.Font.GothamBold; CR(b,3)
    b.MouseEnter:Connect(function() TW(b,{BackgroundColor3=C.bg4},.08) end)
    b.MouseLeave:Connect(function() TW(b,{BackgroundColor3=bg},.08) end); return b
end
hBtn("×", isMobile and -20 or -14, C.red).MouseButton1Click:Connect(function()
    run=false; battleRun=false
    TW(m,{Size=UDim2.new(0,W,0,0),BackgroundTransparency=1},.2); task.wait(.25); sg:Destroy()
end)
hBtn("–", isMobile and -40 or -30, C.bg3).MouseButton1Click:Connect(function() closeMenu() end)


local tabBarH = isMobile and 16 or 13
local tabH=Instance.new("Frame",m)
tabH.Size=UDim2.new(1,0,0,tabBarH); tabH.Position=UDim2.new(0,0,0,tBarH)
tabH.BackgroundColor3=C.bg1; tabH.BorderSizePixel=0

local TABS={"FARM","INVENTORY","BATTLE","QUEST"}
local tBtns,tConts,curTab={},{},1
for i,tn in ipairs(TABS) do
    local w=1/#TABS
    local b=Instance.new("TextButton",tabH)
    b.Size=UDim2.new(w,0,1,0); b.Position=UDim2.new(w*(i-1),0,0,0)
    b.BackgroundColor3=i==1 and C.bg2 or C.bg1; b.BorderSizePixel=0
    b.Text=tn; b.TextColor3=i==1 and C.acc or C.gry; b.TextSize=7; b.Font=Enum.Font.GothamBold
    
    local ln=Instance.new("Frame",b); ln.Size=UDim2.new(1,0,0,2); ln.Position=UDim2.new(0,0,1,-2)
    ln.BackgroundColor3=i==1 and C.acc or C.bg1; ln.BorderSizePixel=0
    tBtns[i]={b=b,ln=ln}
    
    local contTop = tBarH + tabBarH  -- starts after title+tabs
    local cont=Instance.new("Frame",m)
    cont.Size=UDim2.new(1,0,0,H-contTop); cont.Position=UDim2.new(0,0,0,contTop)
    cont.BackgroundTransparency=1; cont.ClipsDescendants=true; cont.Visible=i==1
    tConts[i]=cont
    b.MouseButton1Click:Connect(function()
        if curTab==i then return end; curTab=i
        for j,td in ipairs(tBtns) do
            TW(td.b,{BackgroundColor3=j==i and C.bg2 or C.bg1, TextColor3=j==i and C.acc or C.gry},.12)
            TW(td.ln,{BackgroundColor3=j==i and C.acc or C.bg1},.12)
            tConts[j].Visible=j==i
        end
        if i==2 then task.spawn(refreshInv) end
        if i==4 then task.spawn(refreshQuests) end
    end)
end
local FC=tConts[1]; local IC=tConts[2]; local BC=tConts[3]; local QC=tConts[4]


local sBalV,sItemV,sSoldV,sEarnV,sHolV
local function updateStats()
    if sBalV  then sBalV.Text  = string.format("$%.2f",getBal()) end
    if sItemV then sItemV.Text = tostring(#inv:GetChildren()) end
    if sSoldV then sSoldV.Text = tostring(soldCount) end
    if sEarnV then sEarnV.Text = string.format("$%.2f",totalEarned) end
end


local function panel(par,x,y,w,h,col)
    local f2=Instance.new("Frame",par); f2.Size=UDim2.new(0,w,0,h); f2.Position=UDim2.new(0,x,0,y)
    f2.BackgroundColor3=col or C.bg1; f2.BorderSizePixel=0; CR(f2,3); return f2
end
local function panelHdr(par,txt)
    local b=Instance.new("Frame",par); b.Size=UDim2.new(1,0,0,12); b.BackgroundColor3=C.bg2; b.BorderSizePixel=0; CR(b,3)
    local l=Instance.new("TextLabel",b); l.Size=UDim2.new(1,-6,1,0); l.Position=UDim2.new(0,6,0,0)
    l.BackgroundTransparency=1; l.Text=txt; l.TextColor3=C.acc; l.TextSize=6; l.Font=Enum.Font.GothamBold; l.TextXAlignment=Enum.TextXAlignment.Left
    return b
end
local function row(par,label,y,valColor)
    local r=Instance.new("Frame",par); r.Size=UDim2.new(1,0,0,12); r.Position=UDim2.new(0,0,0,y); r.BackgroundTransparency=1
    local l=Instance.new("TextLabel",r); l.Size=UDim2.new(.6,0,1,0); l.Position=UDim2.new(0,4,0,0)
    l.BackgroundTransparency=1; l.Text=label; l.TextColor3=C.lgr; l.TextSize=6; l.Font=Enum.Font.Gotham; l.TextXAlignment=Enum.TextXAlignment.Left
    local v=Instance.new("TextLabel",r); v.Size=UDim2.new(.38,0,1,0); v.Position=UDim2.new(.62,0,0,0)
    v.BackgroundTransparency=1; v.Text="0"; v.TextColor3=valColor or C.acc; v.TextSize=6; v.Font=Enum.Font.GothamBold; v.TextXAlignment=Enum.TextXAlignment.Right
    return v
end
local function togRow(par,label,y,init,cb)
    local r2=Instance.new("Frame",par); r2.Size=UDim2.new(1,0,0,12); r2.Position=UDim2.new(0,0,0,y); r2.BackgroundTransparency=1
    local l=Instance.new("TextLabel",r2); l.Size=UDim2.new(.6,0,1,0); l.Position=UDim2.new(0,4,0,0)
    l.BackgroundTransparency=1; l.Text=label; l.TextColor3=C.lgr; l.TextSize=6; l.Font=Enum.Font.Gotham; l.TextXAlignment=Enum.TextXAlignment.Left
    Toggle(r2, (1-0.3)*180+4, 2, init, cb)  -- place toggle right-aligned ish
    
    local tog=r2:FindFirstChildWhichIsA("Frame",true); if tog then tog.Position=UDim2.new(1,-30,0,1) end
    return r2
end


local lcW = isMobile and 95 or 125
local LC=Instance.new("Frame",FC)
LC.Size=UDim2.new(0,lcW,1,-4); LC.Position=UDim2.new(0,4,0,2); LC.BackgroundTransparency=1


local statP=panel(LC,0,0,lcW-4,isMobile and 52 or 60,C.bg1); panelHdr(statP,"STATS")
sBalV  = row(statP,"Balance",  isMobile and 14 or 16, C.acc)
sItemV = row(statP,"Items",    isMobile and 24 or 28, C.acc2)
sSoldV = row(statP,"Sold",     isMobile and 34 or 40, C.yel)
sEarnV = row(statP,"Earned",   isMobile and 44 or 52, C.pur)

local setP=panel(LC,0,isMobile and 56 or 64,lcW-4,isMobile and 52 or 64,C.bg1); panelHdr(setP,"SETTINGS")
togRow(setP,"Auto-Sell", 20, true,  function(v) autoSell=v end)
togRow(setP,"Auto-Buy",  40, false, function(v) end)


local selSY = isMobile and 112 or 132
local selP2=panel(LC,0,selSY,lcW-4,24,C.bg1); panelHdr(selP2,"SELECTED CASE")
local selNameL=Instance.new("TextLabel",selP2); selNameL.Size=UDim2.new(1,-8,0,14); selNameL.Position=UDim2.new(0,4,0,18)
selNameL.BackgroundTransparency=1; selNameL.Text="Free  |  FREE  |  $0"; selNameL.TextColor3=C.acc
selNameL.TextSize=6; selNameL.Font=Enum.Font.GothamBold; selNameL.TextXAlignment=Enum.TextXAlignment.Left
selNameL.TextTruncate=Enum.TextTruncate.AtEnd


local logSY = selSY + 28
local logP=panel(LC,0,logSY,lcW-4,H-32-logSY-4,C.bg1); panelHdr(logP,"LOG")
LOG_F=SCROLL(logP,4,14,lcW-12,logP.Size.Y.Offset-18)
Instance.new("UIListLayout",LOG_F).Padding=UDim.new(0,1)


local rcX = lcW+8
local RC=Instance.new("Frame",FC)
RC.Size=UDim2.new(1,-(rcX+4),1,-4); RC.Position=UDim2.new(0,rcX,0,2); RC.BackgroundTransparency=1
local caseP=Instance.new("Frame",RC)
caseP.Size=UDim2.new(1,0,1,0); caseP.Position=UDim2.new(0,0,0,0)
caseP.BackgroundColor3=C.bg1; caseP.BorderSizePixel=0; CR(caseP,3)
panelHdr(caseP,"CASES ("..#CASES..")")


local balHdr=Instance.new("TextLabel",caseP:FindFirstChildWhichIsA("Frame"))
balHdr.Size=UDim2.new(.45,0,1,0); balHdr.Position=UDim2.new(.55,0,0,0)
balHdr.BackgroundTransparency=1; balHdr.TextColor3=C.gry; balHdr.TextSize=6; balHdr.Font=Enum.Font.GothamBold
balHdr.TextXAlignment=Enum.TextXAlignment.Right; balHdr.Text="$0.00"
task.spawn(function() while sg.Parent do balHdr.Text=string.format("$%.2f",getBal()); task.wait(2) end end)

local caseScroll=SCROLL(caseP,4,18,0,0)
caseScroll.Size=UDim2.new(1,-8,1,-22); caseScroll.Position=UDim2.new(0,4,0,20)
caseScroll.ScrollBarThickness=4

local cGrid=Instance.new("UIGridLayout",caseScroll)

cGrid.CellSize=UDim2.new(0,isMobile and 48 or 58,0,isMobile and 20 or 22)
cGrid.CellPadding=UDim2.new(0,2,0,2); cGrid.SortOrder=Enum.SortOrder.LayoutOrder

local selCBtn=nil
for i,cs in ipairs(CASES) do
    local cb=Instance.new("TextButton",caseScroll)
    cb.BackgroundColor3=i==1 and C.bg3 or C.bg2; cb.BorderSizePixel=0; cb.Text=""; cb.LayoutOrder=i; CR(cb,3)
    if i==1 then
        local sel=Instance.new("UIStroke",cb); sel.Color=C.acc; sel.Thickness=1; sel.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
        selCBtn=cb
    end
    -- color stripe
    local stripe=Instance.new("Frame",cb); stripe.Size=UDim2.new(1,0,0,2); stripe.Position=UDim2.new(0,0,0,0)
    stripe.BackgroundColor3=cs.c; stripe.BackgroundTransparency=.35; stripe.BorderSizePixel=0
    local nl=Instance.new("TextLabel",cb); nl.Size=UDim2.new(1,-4,0,10); nl.Position=UDim2.new(0,2,0,2)
    nl.BackgroundTransparency=1; nl.Text=cs.n; nl.TextColor3=C.wht; nl.TextSize=5; nl.Font=Enum.Font.GothamBold
    nl.TextXAlignment=Enum.TextXAlignment.Left; nl.TextTruncate=Enum.TextTruncate.AtEnd
    local pl2=Instance.new("TextLabel",cb); pl2.Size=UDim2.new(1,-4,0,8); pl2.Position=UDim2.new(0,2,0,12)
    pl2.BackgroundTransparency=1; pl2.Text=cs.p==0 and "FREE" or "$"..cs.p; pl2.TextColor3=cs.c
    pl2.TextSize=6; pl2.Font=Enum.Font.GothamBlack; pl2.TextXAlignment=Enum.TextXAlignment.Left
    cb.MouseEnter:Connect(function() if cb~=selCBtn then TW(cb,{BackgroundColor3=C.bg3},.08) end end)
    cb.MouseLeave:Connect(function() if cb~=selCBtn then TW(cb,{BackgroundColor3=C.bg2},.08) end end)
    cb.MouseButton1Click:Connect(function()
        SELECTED_KEY=cs.k; SELECTED_FREE=cs.f; SELECTED_PRICE=cs.p
        selNameL.Text=cs.n.."  |  "..cs.k.."  |  "..(cs.p==0 and "FREE" or "$"..cs.p)
        selNameL.TextColor3=cs.c
        if selCBtn then
            for _,ch in ipairs(selCBtn:GetChildren()) do if ch:IsA("UIStroke") then ch:Destroy() end end
            TW(selCBtn,{BackgroundColor3=C.bg2},.1)
        end
        TW(cb,{BackgroundColor3=C.bg3},.1)
        local ns=Instance.new("UIStroke",cb); ns.Color=C.acc; ns.Thickness=1; ns.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
        selCBtn=cb
    end)
end




local invHdr=Instance.new("Frame",IC)
invHdr.Size=UDim2.new(1,-8,0,14); invHdr.Position=UDim2.new(0,4,0,2)
invHdr.BackgroundColor3=C.bg1; invHdr.BorderSizePixel=0; CR(invHdr,3)

local iCntL=Instance.new("TextLabel",invHdr)
iCntL.Size=UDim2.new(.5,0,1,0); iCntL.Position=UDim2.new(0,4,0,0)
iCntL.BackgroundTransparency=1; iCntL.Text="Items: 0"; iCntL.TextColor3=C.gry
iCntL.TextSize=7; iCntL.Font=Enum.Font.GothamBold; iCntL.TextXAlignment=Enum.TextXAlignment.Left

local iSelL=Instance.new("TextLabel",invHdr)
iSelL.Size=UDim2.new(.5,-4,1,0); iSelL.Position=UDim2.new(.5,0,0,0)
iSelL.BackgroundTransparency=1; iSelL.Text="Sel: 0"; iSelL.TextColor3=C.yel
iSelL.TextSize=7; iSelL.Font=Enum.Font.GothamBold; iSelL.TextXAlignment=Enum.TextXAlignment.Right


local invBtnRow=Instance.new("Frame",IC)
invBtnRow.Size=UDim2.new(1,-8,0,16); invBtnRow.Position=UDim2.new(0,4,0,18)
invBtnRow.BackgroundColor3=C.bg1; invBtnRow.BorderSizePixel=0; CR(invBtnRow,3)

local function mkIBtn(txt,xi,wi,col2)
    local b=Instance.new("TextButton",invBtnRow)
    b.Size=UDim2.new(0,wi,0,12); b.Position=UDim2.new(0,xi,0.5,-6)
    b.BackgroundColor3=col2; b.BorderSizePixel=0
    b.Text=txt; b.TextColor3=Color3.fromRGB(10,10,10); b.TextSize=6; b.Font=Enum.Font.GothamBold; CR(b,3)
    b.MouseEnter:Connect(function() TW(b,{BackgroundColor3=C.wht},.08) end)
    b.MouseLeave:Connect(function() TW(b,{BackgroundColor3=col2},.08) end)
    return b
end


local saBtn = mkIBtn("SELL ALL",   4,    78, C.red)
local ssBtn = mkIBtn("SELL SEL",   86,  65, C.yel)
local rfBtn = mkIBtn("REFRESH",    155,  54,  C.acc)

local invScroll=SCROLL(IC,4,38,0,H-38-40)
invScroll.Size=UDim2.new(1,-8,1,-40); invScroll.Position=UDim2.new(0,4,0,38); invScroll.ScrollBarThickness=3
Instance.new("UIListLayout",invScroll).Padding=UDim.new(0,2)
local selItems={}

function refreshInv()
    for _,ch in ipairs(invScroll:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
    selItems={}
    local items=inv:GetChildren(); iCntL.Text="Items: "..#items; iSelL.Text="Sel: 0"
    for idx,item in ipairs(items) do
        local parts=string.split(item.Name,"_")
        local dn=item.Name; if #parts>=2 then dn=parts[1].." | "..item.Name:gsub(parts[1].."_","") end
        local fr=Instance.new("Frame",invScroll); fr.Size=UDim2.new(1,0,0,20); fr.BackgroundColor3=C.bg1; fr.BorderSizePixel=0; CR(fr,3); fr.LayoutOrder=idx
        local chk=Instance.new("TextButton",fr); chk.Size=UDim2.new(0,14,0,14); chk.Position=UDim2.new(0,3,.5,-7)
        chk.BackgroundColor3=C.bg3; chk.BorderSizePixel=0; chk.Text=""; chk.TextColor3=C.acc2; chk.TextSize=8; chk.Font=Enum.Font.GothamBold; CR(chk,2)
        local nl=Instance.new("TextLabel",fr); nl.Size=UDim2.new(1,-70,0,10); nl.Position=UDim2.new(0,20,0,1)
        nl.BackgroundTransparency=1; nl.Text=dn; nl.TextColor3=C.wht; nl.TextSize=7; nl.Font=Enum.Font.GothamBold; nl.TextXAlignment=Enum.TextXAlignment.Left; nl.TextTruncate=Enum.TextTruncate.AtEnd
        local wl=Instance.new("TextLabel",fr); wl.Size=UDim2.new(1,-70,0,8); wl.Position=UDim2.new(0,20,0,11)
        wl.BackgroundTransparency=1; wl.Text=item:GetAttribute("Wear") or ""; wl.TextColor3=C.gry; wl.TextSize=5; wl.Font=Enum.Font.Code; wl.TextXAlignment=Enum.TextXAlignment.Left
        local seB=BTN(fr,"SELL",0,0,34,16,C.red); seB.Position=UDim2.new(1,-38,.5,-8); seB.TextSize=6
        local isSel=false
        chk.MouseButton1Click:Connect(function()
            isSel=not isSel
            if isSel then selItems[item.Name]=item; chk.Text="✓"; TW(chk,{BackgroundColor3=C.acc2},.1); TW(fr,{BackgroundColor3=Color3.fromRGB(24,40,28)},.1)
            else selItems[item.Name]=nil; chk.Text=""; TW(chk,{BackgroundColor3=C.bg3},.1); TW(fr,{BackgroundColor3=C.bg1},.1) end
            local n=0; for _ in pairs(selItems) do n=n+1 end; iSelL.Text="Sel: "..n
        end)
        seB.MouseButton1Click:Connect(function()
            seB.Text="..."; TW(seB,{BackgroundColor3=C.bg3},.1)
            local ok=trySell(item)
            if ok then soldCount=soldCount+1; LOG("Sold: "..dn,C.acc2); seB.Text="✓"; TW(seB,{BackgroundColor3=C.acc2},.1); task.wait(.8); refreshInv(); updateStats()
            else LOG("Fail: "..dn,C.red); seB.Text="✗"; TW(seB,{BackgroundColor3=C.red},.1); task.wait(2); seB.Text="SELL"; TW(seB,{BackgroundColor3=C.red},.1) end
        end)
    end
end
saBtn.MouseButton1Click:Connect(function()
    local items=inv:GetChildren(); if #items==0 then LOG("Inventory empty",C.gry) return end
    LOG("Selling "..#items.." items...",C.acc)
    local bb=getBal()
    for attempt=1,3 do
        if doSellItems(inv:GetChildren()) then break end
        task.wait(1)
    end
    local ba=getBal()
    if ba>bb then totalEarned=totalEarned+(ba-bb); soldCount=soldCount+1; LOG("+$"..string.format("%.2f",ba-bb),C.acc2)
    else LOG("Sell failed — server blocked",C.red) end
    refreshInv(); updateStats()
end)
ssBtn.MouseButton1Click:Connect(function()
    local n=0; for _ in pairs(selItems) do n=n+1 end; if n==0 then LOG("Nothing selected",C.gry) return end
    for nm,item in pairs(selItems) do local ok=trySell(item)
        if ok then soldCount=soldCount+1; LOG("Sold: "..nm,C.acc2) else LOG("Fail: "..nm,C.red) end; task.wait(3)
    end; selItems={}; refreshInv(); updateStats()
end)
rfBtn.MouseButton1Click:Connect(function() refreshInv() end)


local function bPanel(y,h) return panel(BC,4,y,0,h,C.bg1) end

local function bPanelFW(y,h)
    local p=bPanel(y,h); p.Size=UDim2.new(1,-8,0,h); p.Position=UDim2.new(0,4,0,y); return p
end


local bSet=bPanelFW(2,62); panelHdr(bSet,"BATTLE SETTINGS")


local BMODES={"CLASSIC","JESTER","TERMINAL","JACKPOT","SHARED","CRAZY TERMINAL","CRAZY JACKPOT","Coin Flip"}
local bmIdx=1
Instance.new("TextLabel",bSet).Parent=nil  -- clear
local bML=Instance.new("TextLabel",bSet); bML.Size=UDim2.new(.45,0,0,12); bML.Position=UDim2.new(0,4,0,14)
bML.BackgroundTransparency=1; bML.Text="Mode:"; bML.TextColor3=C.lgr; bML.TextSize=6; bML.Font=Enum.Font.Gotham; bML.TextXAlignment=Enum.TextXAlignment.Left
local bmDisp=Instance.new("TextLabel",bSet); bmDisp.Size=UDim2.new(.35,0,0,12); bmDisp.Position=UDim2.new(.4,0,0,14)
bmDisp.BackgroundTransparency=1; bmDisp.Text="CLASSIC"; bmDisp.TextColor3=C.acc; bmDisp.TextSize=6; bmDisp.Font=Enum.Font.GothamBold; bmDisp.TextXAlignment=Enum.TextXAlignment.Center
local bmLB=BTN(bSet,"<",0,14,14,12,C.bg3); bmLB.Position=UDim2.new(1,-32,0,14); bmLB.TextSize=8
local bmRB=BTN(bSet,">",0,14,14,12,C.bg3); bmRB.Position=UDim2.new(1,-16,0,14); bmRB.TextSize=8
bmLB.MouseButton1Click:Connect(function() bmIdx=bmIdx<=1 and #BMODES or bmIdx-1; bmDisp.Text=BMODES[bmIdx] end)
bmRB.MouseButton1Click:Connect(function() bmIdx=bmIdx>=#BMODES and 1 or bmIdx+1; bmDisp.Text=BMODES[bmIdx] end)

local bcIdx=1
local bcML=Instance.new("TextLabel",bSet); bcML.Size=UDim2.new(.45,0,0,12); bcML.Position=UDim2.new(0,4,0,28)
bcML.BackgroundTransparency=1; bcML.Text="Case:"; bcML.TextColor3=C.lgr; bcML.TextSize=6; bcML.Font=Enum.Font.Gotham; bcML.TextXAlignment=Enum.TextXAlignment.Left
local bcDisp=Instance.new("TextLabel",bSet); bcDisp.Size=UDim2.new(.35,0,0,12); bcDisp.Position=UDim2.new(.4,0,0,28)
bcDisp.BackgroundTransparency=1; bcDisp.Text="Free"; bcDisp.TextColor3=C.acc; bcDisp.TextSize=6; bcDisp.Font=Enum.Font.GothamBold; bcDisp.TextXAlignment=Enum.TextXAlignment.Center
local bcLB=BTN(bSet,"<",0,28,14,12,C.bg3); bcLB.Position=UDim2.new(1,-32,0,28); bcLB.TextSize=8
local bcRB=BTN(bSet,">",0,28,14,12,C.bg3); bcRB.Position=UDim2.new(1,-16,0,28); bcRB.TextSize=8
bcLB.MouseButton1Click:Connect(function() bcIdx=bcIdx<=1 and #CASES or bcIdx-1; bcDisp.Text=CASES[bcIdx].n end)
bcRB.MouseButton1Click:Connect(function() bcIdx=bcIdx>=#CASES and 1 or bcIdx+1; bcDisp.Text=CASES[bcIdx].n end)


local bpCount=2
local bpML=Instance.new("TextLabel",bSet); bpML.Size=UDim2.new(.45,0,0,12); bpML.Position=UDim2.new(0,4,0,42)
bpML.BackgroundTransparency=1; bpML.Text="Players (2-4):"; bpML.TextColor3=C.lgr; bpML.TextSize=6; bpML.Font=Enum.Font.Gotham; bpML.TextXAlignment=Enum.TextXAlignment.Left
local bpDisp=Instance.new("TextLabel",bSet); bpDisp.Size=UDim2.new(.15,0,0,12); bpDisp.Position=UDim2.new(.4,0,0,42)
bpDisp.BackgroundTransparency=1; bpDisp.Text="2"; bpDisp.TextColor3=C.acc; bpDisp.TextSize=6; bpDisp.Font=Enum.Font.GothamBold; bpDisp.TextXAlignment=Enum.TextXAlignment.Center
local bpLB=BTN(bSet,"<",0,42,14,12,C.bg3); bpLB.Position=UDim2.new(1,-32,0,42); bpLB.TextSize=8
local bpRB=BTN(bSet,">",0,42,14,12,C.bg3); bpRB.Position=UDim2.new(1,-16,0,42); bpRB.TextSize=8
bpLB.MouseButton1Click:Connect(function() bpCount=math.max(2,bpCount-1); bpDisp.Text=tostring(bpCount) end)
bpRB.MouseButton1Click:Connect(function() bpCount=math.min(4,bpCount+1); bpDisp.Text=tostring(bpCount) end)


local bStP=bPanelFW(68,18)
local bWL=Instance.new("TextLabel",bStP); bWL.Size=UDim2.new(.5,0,1,0); bWL.Position=UDim2.new(0,6,0,0)
bWL.BackgroundTransparency=1; bWL.Text="Wins: 0/0"; bWL.TextColor3=C.yel; bWL.TextSize=7; bWL.Font=Enum.Font.GothamBold; bWL.TextXAlignment=Enum.TextXAlignment.Left
local bHL=Instance.new("TextLabel",bStP); bHL.Size=UDim2.new(.5,-6,1,0); bHL.Position=UDim2.new(.5,0,0,0)
bHL.BackgroundTransparency=1; bHL.Text="Holos: 0"; bHL.TextColor3=C.acc; bHL.TextSize=7; bHL.Font=Enum.Font.GothamBold; bHL.TextXAlignment=Enum.TextXAlignment.Right


local bLogP=bPanelFW(90,96); panelHdr(bLogP,"BATTLE LOG")
local bLogS=SCROLL(bLogP,4,16,0,76); bLogS.Size=UDim2.new(1,-8,0,76); bLogS.Position=UDim2.new(0,4,0,16); bLogS.ScrollBarThickness=3
Instance.new("UIListLayout",bLogS).Padding=UDim.new(0,1)
local bLogN=0
local function BLOG(txt,col)
    bLogN=bLogN+1; local ts=os.date("%H:%M:%S")
    local row2=Instance.new("Frame",bLogS); row2.Size=UDim2.new(1,0,0,10); row2.BackgroundTransparency=1; row2.LayoutOrder=bLogN
    local mg=Instance.new("TextLabel",row2); mg.Size=UDim2.new(1,0,1,0); mg.BackgroundTransparency=1
    mg.Text="["..ts.."] "..txt; mg.TextColor3=col or C.lgr; mg.TextSize=6; mg.Font=Enum.Font.Code; mg.TextXAlignment=Enum.TextXAlignment.Left
    task.defer(function() pcall(function() bLogS.CanvasPosition=Vector2.new(0,1e9) end) end)
end

local function refreshBattle() bWL.Text="Wins: "..battleWins.."/"..battleTotal; bHL.Text="Holos: "..tostring(getHolos()) end


local bCtrl=bPanelFW(190,20)
local bsBtn=BTN(bCtrl,"▶ START BATTLES",4,3,110,14,C.acc); bsBtn.TextColor3=Color3.fromRGB(0,0,0); bsBtn.TextSize=7
local bstBtn=BTN(bCtrl,"■ STOP",118,3,60,14,C.red); bstBtn.TextSize=7

local function doOneBattle()
    local cr=f:FindFirstChild("CreateBattle")
    if not cr then BLOG("CreateBattle not found",C.red); return false end

    local cs=CASES[bcIdx]; local mode=BMODES[bmIdx]
    
    local pc=bpCount; local isTeam=(pc==4)
    BLOG("Create: "..mode.." | "..cs.k.." | "..pc.."p",C.acc)

   
    local ok,bid=pcall(function()
        return cr:InvokeServer({cs.k}, pc, mode, isTeam)
    end)
    -- bid может быть числом 0 — это валидно, проверяем только nil/false
    if not ok or bid==nil or bid==false then
        BLOG("CreateBattle fail: "..tostring(bid),C.red); return false
    end
    BLOG("Battle #"..tostring(bid).." created",C.acc2)
    battleTotal=battleTotal+1


    local ab=f:FindFirstChild("AddBot")
    if ab then
        task.wait(0.8)
       
        local inst=nil
        local function findInst(parent,depth)
            if depth>5 then return end
            for _,v in ipairs(parent:GetChildren()) do
                local vid = v:GetAttribute("BattleId") or v:GetAttribute("Id") or v.Name
                if tostring(vid)==tostring(bid) then inst=v; return end
                if v:IsA("Folder") or v:IsA("Model") then findInst(v,depth+1) end
            end
        end
        findInst(workspace,0)
        if not inst then findInst(RS,0) end

        for _=1,(pc-1) do
            if inst then pcall(function() ab:FireServer(inst,pl) end)
            else         pcall(function() ab:FireServer(bid,pl) end) end
            task.wait(0.3)
        end
        BLOG((pc-1).." bots added",C.acc2)
    end

    
    local sbStart=f:FindFirstChild("StartBattle")
    local done,winner=false,false
    local conns={}

    if sbStart then
        local c1=sbStart.OnClientEvent:Connect(function(playersData)
            if type(playersData)~="table" then return end
            for _,p2 in ipairs(playersData) do
                if type(p2)=="table" then
                    local uid=p2.UserId or p2.Id
                    if tostring(uid)==tostring(pl.UserId) or p2.Name==pl.Name then
                        winner=(p2.Winner==true); done=true
                    end
                end
            end
        end)
        table.insert(conns,c1)
    end

    
    local sbr=f:FindFirstChild("ShowcaseBattleResults")
    if sbr then
        local c2=sbr.OnClientEvent:Connect(function(data)
            if type(data)~="table" then return end
            for _,p2 in pairs(data) do
                if type(p2)=="table" then
                    local uid=p2.UserId or p2.Id
                    if tostring(uid)==tostring(pl.UserId) or p2.Name==pl.Name then
                        winner=(p2.Winner==true)
                    end
                end
            end
            done=true
        end)
        table.insert(conns,c2)
    end

    local t0=tick()
    while not done and tick()-t0<45 do task.wait(0.5) end
    for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end

    -- Exit battle after result
    local eb=f:FindFirstChild("ExitBattle") or f:FindFirstChild("LeaveBattle") or f:FindFirstChild("QuitBattle")
    if eb then
        pcall(function()
            if eb:IsA("RemoteEvent") then eb:FireServer(bid)
            else eb:InvokeServer(bid) end
        end)
        BLOG("Exited battle",C.gry)
    end

    if done then
        if winner then battleWins=battleWins+1; BLOG("WIN! "..battleWins.."/"..battleTotal,C.acc2)
        else BLOG("Defeat "..battleWins.."/"..battleTotal,C.yel) end
    else
        BLOG("Timeout — battle may still run",C.gry)
    end

    if autoSell then
        task.wait(0.5)
        local items=inv:GetChildren()
        if #items>0 then doSellItems(items) end
    end

    refreshBattle(); return true
end

bsBtn.MouseButton1Click:Connect(function()
    if battleRun then return end; battleRun=true; battleWins=0; battleTotal=0
    TW(bsBtn,{BackgroundColor3=Color3.fromRGB(40,100,60),TextColor3=C.wht},.2); bsBtn.Text="RUNNING..."
    BLOG("Battle loop started",C.acc)
    task.spawn(function()
        while battleRun do local ok=doOneBattle(); if not ok then task.wait(3) end; if battleRun then task.wait(1) end end
        BLOG("Stopped",C.gry); TW(bsBtn,{BackgroundColor3=C.acc,TextColor3=Color3.fromRGB(0,0,0)},.2); bsBtn.Text="▶ START BATTLES"
    end)
end)
bstBtn.MouseButton1Click:Connect(function() battleRun=false; BLOG("Stopping…",C.yel) end)

-- ═══════════════════════════════════════════════════════════════════
-- QUEST tab
-- ═══════════════════════════════════════════════════════════════════
local qTopP=panel(QC,4,2,0,16,C.bg1); qTopP.Size=UDim2.new(1,-8,0,16); qTopP.Position=UDim2.new(0,4,0,2)
local qHL=Instance.new("TextLabel",qTopP); qHL.Size=UDim2.new(.7,0,1,0); qHL.Position=UDim2.new(0,4,0,0)
qHL.BackgroundTransparency=1; qHL.Text="Holos: 0  |  Daily Quests"; qHL.TextColor3=C.yel; qHL.TextSize=7; qHL.Font=Enum.Font.GothamBold; qHL.TextXAlignment=Enum.TextXAlignment.Left
local qListP=panel(QC,4,22,0,86,C.bg1); qListP.Size=UDim2.new(1,-8,0,86); qListP.Position=UDim2.new(0,4,0,22)
panelHdr(qListP,"QUESTS")
local qCards=Instance.new("Frame",qListP); qCards.Size=UDim2.new(1,-8,0,70); qCards.Position=UDim2.new(0,4,0,14)
qCards.BackgroundTransparency=1; Instance.new("UIListLayout",qCards).Padding=UDim.new(0,2)

local function parseQuestFromText(txt)
    if not txt or txt=="" then return nil end
    local t=txt:match("^%s*(.-)%s*$") or txt

    -- "Open 50 50/50 AK-47s" or "Open 30 Inferno Cases"
    local req,subj = t:match("^Open%s+(%d+)%s+(.+?)s?%.?$")
    if req and subj then
        subj=subj:match("^(.-)%s*Cases?$") or subj
        return {type="Open", subject=subj:match("^%s*(.-)%s*$"), requirement=tonumber(req)}
    end

    -- "Play 13 JACKPOT mode battles"
    local req2,mode = t:match("^Play%s+(%d+)%s+(.+?)%s+mode")
    if req2 and mode then
        return {type="Play", subject=mode:match("^%s*(.-)%s*$"), requirement=tonumber(req2)}
    end

    -- "Win 10 battles" or "Win 5 JACKPOT"
    local req3,subj3 = t:match("^Win%s+(%d+)%s*(.*)")
    if req3 then
        subj3 = subj3:match("^%s*(.-)%s*$") or ""
        return {type="Win", subject=subj3, requirement=tonumber(req3)}
    end

    return nil
end

local function getQuests()
    local list={}
    local seen={}

    -- Try to read from PlayerData first (structured quests)
    local function tryReadPD(q, isCalendar, path)
        if seen[q] then return end
        seen[q]=true
        local function getVal(obj,name)
            local ch=obj:FindFirstChild(name)
            if ch and ch:IsA("ValueBase") then return ch.Value end
            return nil
        end
        local typ  = getVal(q,"Value") or getVal(q,"Type") or ""
        if typ=="" and q:IsA("StringValue") then typ=q.Value end
        local subj = getVal(q,"Subject") or getVal(q,"Target") or ""
        local req  = getVal(q,"Requirement") or getVal(q,"Goal") or 0
        local prog = getVal(q,"Progress") or getVal(q,"Current") or 0
        local done = getVal(q,"Completed") or getVal(q,"Done") or false
        local attrs=q:GetAttributes()
        if subj=="" then subj=attrs.Subject or attrs.Target or attrs.Case or "" end
        if req==0 then req=attrs.Requirement or attrs.Goal or attrs.Amount or 0 end
        if prog==0 then prog=attrs.Progress or attrs.Current or 0 end
        if not done then done=(attrs.Completed==true or attrs.Done==true) end
        if type(req)=="string" then req=tonumber(req) or 0 end
        if type(prog)=="string" then prog=tonumber(prog) or 0 end
        if typ~="" and req>0 then
            local key=typ..":"..subj..":"..tostring(req)
            if not list[key] then
                list[key]={type=typ,subject=subj,requirement=req,progress=prog,completed=(done==true),isCalendar=isCalendar,path=path}
            end
        end
    end

    local function deepScan(parent, depth, path, isCalendar)
        if depth>5 then return end
        for _,ch in ipairs(parent:GetChildren()) do
            local cpath=path.."/"..ch.Name
            local subCal = isCalendar or ch.Name:find("Calendar")~=nil or ch.Name:find("Daily")~=nil or ch.Name:find("Today")~=nil
            tryReadPD(ch, subCal, cpath)
            if ch:IsA("Folder") or ch:IsA("Model") then
                deepScan(ch, depth+1, cpath, subCal)
            end
        end
    end
    deepScan(pd,0,"PD")

    -- If no structured quests found, scan game UI TextLabels
    if #list==0 then
        local function scanTextLabel(tl)
            local txt=tl.Text
            local q=parseQuestFromText(txt)
            if not q then return end
            -- look for progress "X/Y" in nearby siblings
            local prog=0
            local parent=tl.Parent
            if parent then
                for _,sib in ipairs(parent:GetChildren()) do
                    if sib~=tl and sib:IsA("TextLabel") then
                        local px,py = sib.Text:match("(%d+)/(%d+)")
                        if px and py then
                            local progNum=tonumber(px)
                            local reqNum=tonumber(py)
                            if reqNum==q.requirement then prog=progNum end
                        end
                    end
                end
            end
            q.progress=prog or 0
            q.completed=false
            q.isCalendar=true
            q.path="UI:"..tl:GetFullName()
            local key=q.type..":"..q.subject..":"..tostring(q.requirement)
            if not list[key] then list[key]=q end
        end

        local function scanGUI(obj, depth)
            if depth>8 then return end
            if obj:IsA("TextLabel") then
                scanTextLabel(obj)
            end
            for _,ch in ipairs(obj:GetChildren()) do
                scanGUI(ch,depth+1)
            end
        end
        for _,gui in ipairs(pl.PlayerGui:GetChildren()) do
            scanGUI(gui,0)
        end
    end

    local result={}
    for _,v in pairs(list) do result[#result+1]=v end
    return result
end

function refreshQuests()
    for _,ch in ipairs(qCards:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end

    local candy = getHolos()
    qHL.Text = "Candy: "..tostring(candy).."  |  Daily Quests"

    local function questText(typ,subj,req)
        if typ=="Open" then
            local cname=subj
            for _,cs in ipairs(CASES) do
                if cs.k==subj or cs.k:upper()==subj:upper() or cs.n:upper()==subj:upper() then
                    cname=cs.n; break
                end
            end
            return "Open "..req.." "..cname.."."
        elseif typ=="Play" then
            return "Play "..req.." "..subj.." mode battles."
        elseif typ=="Win" then
            if subj~="" then return "Win "..req.." "..subj.."."
            else return "Win "..req.." battles." end
        end
        return typ.." "..req.." "..subj
    end

    local quests=getQuests()
    for _,q in ipairs(quests) do
        if q.completed or q.progress>=q.requirement then continue end
        local pct = q.requirement>0 and math.min(1,q.progress/q.requirement) or 0

        local card=Instance.new("Frame",qCards)
        card.Size=UDim2.new(1,0,0,26); card.BackgroundColor3=C.bg2; card.BorderSizePixel=0; CR(card,3)

        if q.isCalendar then
            local tag=Instance.new("Frame",card); tag.Size=UDim2.new(0,2,1,0); tag.BackgroundColor3=C.yel; tag.BorderSizePixel=0
        end
        local xOff = q.isCalendar and 5 or 3

        local pbBg=Instance.new("Frame",card); pbBg.Size=UDim2.new(1,0,0,2); pbBg.Position=UDim2.new(0,0,1,-2); pbBg.BackgroundColor3=C.bg4; pbBg.BorderSizePixel=0
        local pb=Instance.new("Frame",card); pb.Size=UDim2.new(pct,0,0,2); pb.Position=UDim2.new(0,0,1,-2); pb.BackgroundColor3=C.acc; pb.BorderSizePixel=0

        local mainTxt=questText(q.type,q.subject,q.requirement)
        local t1=Instance.new("TextLabel",card); t1.Size=UDim2.new(.78,0,0,12); t1.Position=UDim2.new(0,xOff,0,1)
        t1.BackgroundTransparency=1; t1.Text=mainTxt; t1.TextColor3=C.wht
        t1.TextSize=6; t1.Font=Enum.Font.GothamBold; t1.TextXAlignment=Enum.TextXAlignment.Left; t1.TextTruncate=Enum.TextTruncate.AtEnd

        local t2=Instance.new("TextLabel",card); t2.Size=UDim2.new(.78,0,0,8); t2.Position=UDim2.new(0,xOff,0,13)
        t2.BackgroundTransparency=1
        t2.Text=q.progress.."/"..q.requirement
        t2.TextColor3=C.gry; t2.TextSize=5; t2.Font=Enum.Font.Code; t2.TextXAlignment=Enum.TextXAlignment.Left

        local t3=Instance.new("TextLabel",card); t3.Size=UDim2.new(.2,0,0,12); t3.Position=UDim2.new(.8,0,0,7)
        t3.BackgroundTransparency=1; t3.Text=string.format("%.0f%%",pct*100)
        t3.TextColor3=C.yel; t3.TextSize=6; t3.Font=Enum.Font.GothamBlack; t3.TextXAlignment=Enum.TextXAlignment.Right
    end

    if #qCards:GetChildren()==0 then
        local l=Instance.new("TextLabel",qCards); l.Size=UDim2.new(1,0,0,12); l.BackgroundTransparency=1
        l.Text="No active quests"; l.TextColor3=C.gry; l.TextSize=6; l.Font=Enum.Font.Gotham; l.TextXAlignment=Enum.TextXAlignment.Left
    end
end

local qBtns=panel(QC,4,112,0,18,C.bg1); qBtns.Size=UDim2.new(1,-8,0,18); qBtns.Position=UDim2.new(0,4,0,112)
local qClaim=BTN(qBtns,"CLAIM",4,2,50,14,C.acc); qClaim.TextColor3=Color3.fromRGB(0,0,0); qClaim.TextSize=7
local qAuto=BTN(qBtns,"AUTO QUEST: OFF",58,2,100,14,C.bg3); qAuto.TextColor3=C.gry; qAuto.TextSize=7
local qRef=BTN(qBtns,"REFRESH",162,2,50,14,C.bg3); qRef.TextColor3=C.acc; qRef.TextSize=7

local qLogP=panel(QC,4,134,0,H-36-138,C.bg1); qLogP.Size=UDim2.new(1,-8,0,H-36-138); qLogP.Position=UDim2.new(0,4,0,134)
panelHdr(qLogP,"QUEST LOG")
local qLogS=SCROLL(qLogP,4,14,0,0); qLogS.Size=UDim2.new(1,-8,0,qLogP.Size.Y.Offset-18); qLogS.Position=UDim2.new(0,4,0,14); qLogS.ScrollBarThickness=3
Instance.new("UIListLayout",qLogS).Padding=UDim.new(0,2)
local qLogN=0
function QLOG(txt,col)
    qLogN=qLogN+1; local ts=os.date("%H:%M:%S")
    local row2=Instance.new("Frame",qLogS); row2.Size=UDim2.new(1,0,0,10); row2.BackgroundTransparency=1; row2.LayoutOrder=qLogN
    local mg=Instance.new("TextLabel",row2); mg.Size=UDim2.new(1,0,1,0); mg.BackgroundTransparency=1
    mg.Text="["..ts.."] "..txt; mg.TextColor3=col or C.lgr; mg.TextSize=6; mg.Font=Enum.Font.Code; mg.TextXAlignment=Enum.TextXAlignment.Left
    task.defer(function() pcall(function() qLogS.CanvasPosition=Vector2.new(0,1e9) end) end)
end

local function claimQ()
    for _,n in ipairs({"CompleteQuest","ClaimQuest","FinishQuest"}) do local r=f:FindFirstChild(n);if r then pcall(function() r:InvokeServer() end) end end
    local cr=f:FindFirstChild("ClaimMedalReward") or f:FindFirstChild("ClaimCalendar");if cr then pcall(function() cr:FireServer() end) end
end

    local function getQuests()
    local list={}
    local seen={}

    local function tryReadQuest(q, isCalendar, path)
        if seen[q] then return end
        seen[q]=true

        local function getVal(obj,name)
            local ch=obj:FindFirstChild(name)
            if ch and ch:IsA("ValueBase") then return ch.Value end
            return nil
        end

        local typ  = getVal(q,"Value") or getVal(q,"Type") or ""
        local subj = getVal(q,"Subject") or getVal(q,"Target") or ""
        local req  = getVal(q,"Requirement") or getVal(q,"Goal") or 0
        local prog = getVal(q,"Progress") or getVal(q,"Current") or 0
        local done = getVal(q,"Completed") or getVal(q,"Done") or false
        local rew  = getVal(q,"Reward") or 0

        -- also check Attributes
        local attrs=q:GetAttributes()
        if typ=="" and attrs.Type then typ=attrs.Type end
        if typ=="" and attrs.Value then typ=attrs.Value end
        if subj=="" then subj=attrs.Subject or attrs.Target or attrs.Case or "" end
        if req==0 then req=attrs.Requirement or attrs.Goal or attrs.Amount or 0 end
        if prog==0 then prog=attrs.Progress or attrs.Current or 0 end
        if not done then done=(attrs.Completed==true or attrs.Done==true) end
        if rew==0 then rew=attrs.Reward or 0 end

        -- for StringValue, Value IS the type
        if typ=="" and q:IsA("StringValue") then typ=q.Value end

        -- try to extract type from Name if Value is empty
        if typ=="" then
            local nm=q.Name:upper()
            if nm:find("OPEN") then typ="Open"
            elseif nm:find("PLAY") then typ="Play"
            elseif nm:find("WIN") then typ="Win"
            end
        end
        -- try to extract subject from Name
        if subj=="" then subj=q.Name end
        -- convert numeric strings
        if type(req)=="string" then req=tonumber(req) or 0 end
        if type(prog)=="string" then prog=tonumber(prog) or 0 end

        if typ~="" and req>0 then
            local key=typ..":"..subj..":"..tostring(req)
            if not list[key] then
                list[key]={type=typ,subject=subj,requirement=req,progress=prog,completed=(done==true),isCalendar=isCalendar,path=path}
            end
        end
    end

    local function deepScan(parent, depth, path, isCalendar)
        if depth>6 then return end
        for _,ch in ipairs(parent:GetChildren()) do
            local cpath=path.."/"..ch.Name
            local subCal = isCalendar or ch.Name:find("Calendar")~=nil or ch.Name:find("Daily")~=nil or ch.Name:find("Today")~=nil
            -- try to read as quest
            tryReadQuest(ch, subCal, cpath)
            -- recurse into folders
            if ch:IsA("Folder") or ch:IsA("Model") then
                deepScan(ch, depth+1, cpath, subCal)
            end
        end
    end

    deepScan(pd,0,"PD")

    local result={}
    for _,v in pairs(list) do result[#result+1]=v end

    if #result==0 then
        QLOG("No quests found!",C.yel)
    else
        for _,q in ipairs(result) do
            QLOG("Found: "..q.type.." "..q.subject.." "..q.progress.."/"..q.requirement,C.gry)
        end
    end

    return result
end

local function doAutoQuest()
    local quests=getQuests()
    local active={}
    for _,q in ipairs(quests) do
        if not q.completed and q.progress<q.requirement then
            active[#active+1]=q
        end
    end
    if #active==0 then
        QLOG("All quests complete!",C.acc2)
        refreshQuests()
        return
    end

    for _,q in ipairs(active) do
        if not questRun then break end
        local needed=math.max(1, q.requirement-q.progress)
        QLOG(q.type.." "..q.subject.." ("..q.progress.."/"..q.requirement..")",C.acc)

        if q.type=="Open" then
            local caseKey=q.subject
            local isFreeCase=false
            local foundCase=false

            local function matchCase(cKey)
                local cUp=cKey:upper()
                for _,cs in ipairs(CASES) do
                    if cs.k==cKey or cs.k:upper()==cUp or cs.n:upper()==cUp then
                        return cs.k, cs.f, true
                    end
                end
                -- fuzzy: strip "Cases", "50/50", spaces, etc
                local clean=cUp:gsub(" CASES?",""):gsub("  "," "):match("^%s*(.-)%s*$") or cUp
                for _,cs in ipairs(CASES) do
                    if cs.n:upper():find(clean,1,true) or clean:find(cs.n:upper(),1,true) then
                        return cs.k, cs.f, true
                    end
                end
                -- alphanumeric only
                local alphanum=clean:gsub("[^A-Z0-9]","")
                for _,cs in ipairs(CASES) do
                    local ck=cs.k:upper():gsub("[^A-Z0-9]","")
                    local cn=cs.n:upper():gsub("[^A-Z0-9]","")
                    if ck==alphanum or cn==alphanum or ck:find(alphanum,1,true) or alphanum:find(ck,1,true) or cn:find(alphanum,1,true) or alphanum:find(cn,1,true) then
                        return cs.k, cs.f, true
                    end
                end
                return cKey, false, false
            end

            caseKey, isFreeCase, foundCase = matchCase(caseKey)
            QLOG("Open "..caseKey.." x"..needed, foundCase and C.acc or C.yel)

            local oc=f:FindFirstChild("OpenCase")
            if not oc then QLOG("OpenCase not found!",C.red); continue end

            for i=1,needed do
                if not questRun then break end
                local cd=getCooldown(caseKey)
                if cd>0 then QLOG("CD "..string.format("%.0f",cd).."s",C.yel); task.wait(cd+0.5) end

                local opened=false
                if oc:IsA("RemoteEvent") then
                    pcall(function() oc:FireServer(caseKey,1,isFreeCase) end)
                    opened=true
                    task.wait(1.5)
                else
                    -- try InvokeServer with different param combos
                    local r=nil
                    local ok=false
                    ok,r=pcall(function() return oc:InvokeServer(caseKey,1) end)
                    if ok and r then opened=true end
                    if ok and r==nil then
                        ok,r=pcall(function() return oc:InvokeServer(caseKey,1,isFreeCase) end)
                        if ok and r then opened=true end
                    end
                    if ok and r==nil then
                        ok,r=pcall(function() return oc:InvokeServer(caseKey) end)
                        if ok and r then opened=true end
                    end
                end

                if opened then
                    QLOG("  "..i.."/"..needed.." opened",C.acc2)
                else
                    QLOG("  "..i.."/"..needed.." FAIL",C.red)
                end
                task.wait(1.5)
                if autoSell then
                    local items=inv:GetChildren()
                    if #items>0 then doSellItems(items) end
                end
            end

        elseif q.type=="Play" or q.type=="Win" then
            local savedIdx=bmIdx
            if q.subject~="" then
                local subUp=q.subject:upper()
                local foundMode=false
                for mi,m2 in ipairs(BMODES) do
                    if m2:upper()==subUp then bmIdx=mi; foundMode=true; break end
                end
                if not foundMode then
                    for mi,m2 in ipairs(BMODES) do
                        if m2:upper():find(subUp,1,true) or subUp:find(m2:upper(),1,true) then
                            bmIdx=mi; foundMode=true; break
                        end
                    end
                end
                if not foundMode then
                    local words={}
                    for w in subUp:gmatch("[A-Z0-9]+") do words[#words+1]=w end
                    for mi,m2 in ipairs(BMODES) do
                        local mu=m2:upper()
                        for _,w in ipairs(words) do
                            if #w>2 and mu:find(w,1,true) then bmIdx=mi; foundMode=true; break end
                        end
                        if foundMode then break end
                    end
                end
            end
            local modeName=BMODES[bmIdx]
            QLOG("Play "..needed.." x "..modeName,C.lgr)

            for i=1,needed do
                if not questRun then break end
                QLOG("Battle "..i.."/"..needed.."...",C.lgr)
                local ok2=doOneBattle()
                if not ok2 then
                    QLOG("Battle failed, wait 3s",C.red); task.wait(3)
                else
                    QLOG("Battle "..i.." done",C.acc)
                end
                task.wait(1.5)
            end
            bmIdx=savedIdx
        end
    end
    QLOG("Quest cycle done",C.acc2)
    task.wait(1); refreshQuests()
end

qClaim.MouseButton1Click:Connect(function() claimQ(); LOG("Quest claim sent",C.acc2); refreshQuests() end)
qRef.MouseButton1Click:Connect(function() refreshQuests() end)
qAuto.MouseButton1Click:Connect(function()
    questRun=not questRun
    if questRun then
        TW(qAuto,{BackgroundColor3=C.acc2,TextColor3=C.blk},.12); qAuto.Text="AUTO QUEST: ON"
        QLOG("Auto quest started",C.acc2)
        task.spawn(function()
            while questRun do
                QLOG("Scanning quests...",C.lgr)
                doAutoQuest()
                if questRun then task.wait(5) end
            end
            QLOG("Auto quest stopped",C.gry)
        end)
    else TW(qAuto,{BackgroundColor3=C.bg3,TextColor3=C.gry},.12); qAuto.Text="AUTO QUEST: OFF" end
end)


local barH   = isMobile and 30 or 24
local btnH   = isMobile and 24 or 18
local btnOff = isMobile and -(btnH/2) or -(btnH/2)

local bar=Instance.new("Frame",sg)
bar.Size=UDim2.new(0,W,0,barH); bar.Position=UDim2.new(.5,-W/2,1,-(barH+6))
bar.BackgroundColor3=C.blk; bar.BorderSizePixel=0; bar.Active=true; bar.Draggable=true; bar.ZIndex=60; CR(bar,isMobile and 10 or 4)
local barLine=Instance.new("UIStroke",bar); barLine.Color=C.acc; barLine.Thickness=1; barLine.ApplyStrokeMode=Enum.ApplyStrokeMode.Border

-- на мобиле кнопки шире и крупнее
local sBtnW = isMobile and 66 or 74
local stBtnW= isMobile and 58  or 60
local sBtnSz= isMobile and 8  or 7

local startBtn=Instance.new("TextButton",bar)
startBtn.Size=UDim2.new(0,sBtnW,0,btnH); startBtn.Position=UDim2.new(0,8,.5,btnOff)
startBtn.BackgroundColor3=C.acc; startBtn.BorderSizePixel=0; CR(startBtn,isMobile and 8 or 3)
startBtn.Text=isMobile and "▶ START" or "START"; startBtn.TextColor3=Color3.fromRGB(0,0,0); startBtn.TextSize=sBtnSz; startBtn.Font=Enum.Font.GothamBold; startBtn.ZIndex=61

local stopBtn=Instance.new("TextButton",bar)
stopBtn.Size=UDim2.new(0,stBtnW,0,btnH); stopBtn.Position=UDim2.new(0,sBtnW+12,.5,btnOff)
stopBtn.BackgroundColor3=C.red; stopBtn.BorderSizePixel=0; CR(stopBtn,isMobile and 8 or 3)
stopBtn.Text=isMobile and "■ STOP" or "STOP"; stopBtn.TextColor3=C.wht; stopBtn.TextSize=sBtnSz; stopBtn.Font=Enum.Font.GothamBold; stopBtn.ZIndex=61

local timeL=Instance.new("TextLabel",bar)
timeL.Size=UDim2.new(0,42,0,btnH); timeL.Position=UDim2.new(0,sBtnW+stBtnW+8,.5,btnOff)
timeL.BackgroundTransparency=1; timeL.Text="00:00:00"; timeL.TextColor3=C.gry
timeL.TextSize=isMobile and 7 or 6; timeL.Font=Enum.Font.Code; timeL.ZIndex=61; timeL.TextXAlignment=Enum.TextXAlignment.Center

local menuBtn=Instance.new("TextButton",bar)
menuBtn.Size=UDim2.new(0,isMobile and 30 or 26,0,btnH); menuBtn.Position=UDim2.new(1,-(isMobile and 36 or 30),.5,btnOff)
menuBtn.BackgroundColor3=C.bg3; menuBtn.BorderSizePixel=0; CR(menuBtn,isMobile and 6 or 3)
menuBtn.Text="≡"; menuBtn.TextColor3=C.acc; menuBtn.TextSize=isMobile and 16 or 12; menuBtn.Font=Enum.Font.GothamBold; menuBtn.ZIndex=61
local ms=Instance.new("UIStroke",menuBtn); ms.Color=C.acc; ms.Thickness=1; ms.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
menuBtn.MouseButton1Click:Connect(function() if menuOpen then closeMenu() else openMenu() end end)

local function setRunning(v)
    if v then
        startBtn.Text=isMobile and "● RUN" or "RUNNING"
        TW(startBtn,{BackgroundColor3=Color3.fromRGB(35,90,50),TextColor3=C.wht},.15)
        TW(stopBtn,{BackgroundColor3=C.red,TextColor3=C.wht},.15)
    else
        startBtn.Text=isMobile and "▶ START" or "START"
        TW(startBtn,{BackgroundColor3=C.acc,TextColor3=Color3.fromRGB(0,0,0)},.15)
        TW(stopBtn,{BackgroundColor3=C.bg3,TextColor3=C.gry},.15)
    end
end


startBtn.MouseButton1Click:Connect(function()
    if run then return end
    run=true; setRunning(true)
    local key=SELECTED_KEY; local isFree=SELECTED_FREE
    LOG(">> Start  key="..key.."  free="..tostring(isFree).."  sell="..tostring(autoSell),C.acc)
    startTime=os.time(); rounds=0; soldCount=0; totalEarned=0; sellFails=0

            local oc=f:FindFirstChild("OpenCase")
            if not oc then LOG("ERROR: OpenCase remote not found!",C.red); run=false; setRunning(false); return end

            task.spawn(function()
                while run do
                    key=SELECTED_KEY; isFree=SELECTED_FREE

                    local cd=getCooldown(key)
                    if cd>0 then
                        LOG("CD "..string.format("%.1f",cd).."s",C.yel)
                        local t0=tick(); while run and tick()-t0<cd do task.wait(.5) end
                    end
                    if not run then break end

                    local ok,r=false,nil
                    if oc:IsA("RemoteEvent") then
                        pcall(function() oc:FireServer(key,1,isFree) end)
                        ok=true; r=true
                        task.wait(1.5)
                    else
                        -- Try with amount=1
                        ok,r=pcall(function() return oc:InvokeServer(key,1) end)
                        LOG("Open1: ok="..tostring(ok).." r="..string.sub(tostring(r),1,30),C.gry)

                        -- Fallback: try with more params
                        if ok and r==nil then
                            ok,r=pcall(function() return oc:InvokeServer(key,1,isFree) end)
                            LOG("Open2: ok="..tostring(ok).." r="..string.sub(tostring(r),1,30),C.gry)
                        end

                        -- Fallback: try amount only
                        if ok and r==nil then
                            ok,r=pcall(function() return oc:InvokeServer(key) end)
                            LOG("Open3: ok="..tostring(ok).." r="..string.sub(tostring(r),1,30),C.gry)
                        end

                        -- Fallback: try with 4 params
                        if ok and r==nil then
                            ok,r=pcall(function() return oc:InvokeServer(key,1,true,isFree) end)
                            LOG("Open4: ok="..tostring(ok).." r="..string.sub(tostring(r),1,30),C.gry)
                        end
                    end

                    local gotItem=false
                    local iname="?"
                    if ok then
                        if type(r)=="table" then
                            local raw=r[1] or r.Item or r.items and r.items[1]
                            if raw then
                                gotItem=true
                                if type(raw)=="table" then iname=tostring(raw.Item or raw.UUID or raw.Name or raw.id or "?")
                                else iname=tostring(raw) end
                            else
                                -- table but no obvious item field — check all keys
                                for k2,v2 in pairs(r) do
                                    if type(v2)=="string" and #v2>0 and k2~="ok" and k2~="success" then
                                        gotItem=true; iname=v2; break
                                    elseif type(v2)=="table" and not gotItem then
                                        local inner=v2.Item or v2.UUID or v2.Name or v2.id or v2[1]
                                        if inner then gotItem=true; iname=tostring(inner) end
                                    end
                                end
                                if not gotItem then gotItem=true; iname="opened (table)" end
                            end
                        elseif type(r)=="string" and #r>0 then
                            gotItem=true; iname=r:sub(1,30)
                        elseif type(r)=="boolean" and r then
                            gotItem=true; iname="opened"
                        elseif r==nil and oc:IsA("RemoteEvent") then
                            gotItem=true; iname="fired"
                        end
                    end

            if gotItem then
                rounds=rounds+1
                LOG("#"..rounds.." "..iname:sub(1,20).."  Bal: $"..string.format("%.2f",getBal()),Color3.fromRGB(120,230,160))

                if autoSell and sellFails<MAX_SELL_FAIL then
                    task.wait(1.0)
                    local sold=false
                    for attempt=1,5 do
                        local itemsNow=inv:GetChildren()
                        if #itemsNow==0 then sold=true; break end
                        if doSellItems(itemsNow) then sold=true; break end
                        task.wait(0.8)
                    end
                    if sold then
                        soldCount=soldCount+1; sellFails=0
                        LOG("Sold!",C.acc2)
                    else
                        sellFails=sellFails+1
                        LOG("Sell fail "..sellFails.."/"..MAX_SELL_FAIL,C.red)
                        if sellFails>=MAX_SELL_FAIL then LOG("Auto-sell paused",C.red) end
                    end
                end
                updateStats()
            else
                local stillCd=getCooldown(key)
                if stillCd>0 then
                    LOG("CD "..string.format("%.1f",stillCd).."s",C.yel)
                    local t0=tick(); while run and tick()-t0<stillCd do task.wait(.5) end
                else
                    local isCd=false
                    if type(r)=="string" and r:lower():find("cooldown") then isCd=true end
                    if type(r)=="table" then for _,v in pairs(r) do if type(v)=="string" and v:lower():find("cooldown") then isCd=true end end end
                    if isCd then LOG("CD (server) wait 3s",C.yel); task.wait(3)
                    else
                        LOG("FAIL: ok="..tostring(ok).." typeof="..tostring(typeof(r)).." val="..string.sub(tostring(r),1,50),C.red)
                        task.wait(2)
                    end
                end
            end
            if not run then break end
            task.wait(0.3); updateStats()
        end
        LOG(">> Stop  "..rounds.." opened  "..soldCount.." sold",C.red)
        setRunning(false); updateStats()
    end)
end)

stopBtn.MouseButton1Click:Connect(function() run=false; LOG(">> Stopping…",C.yel) end)

-- PC hotkeys
if not isMobile then
    UIS.InputBegan:Connect(function(i,gp)
        if gp then return end
        if i.KeyCode==Enum.KeyCode.Insert then if menuOpen then closeMenu() else openMenu() end
        elseif i.KeyCode==Enum.KeyCode.Home then if not run then startBtn:Activate() end
        elseif i.KeyCode==Enum.KeyCode.End  then if run  then stopBtn:Activate()  end end
    end)
end

-- stats / timer loop
task.spawn(function()
    while sg.Parent do
        updateStats()
        if run and startTime>0 then
            local el=os.time()-startTime
            timeL.Text=string.format("%02d:%02d:%02d",math.floor(el/3600),math.floor(el%3600/60),el%60)
        end
        task.wait(1)
    end
end)

-- Boot messages
LOG("v16 | "..#CASES.." cases | "..(isMobile and "Mobile" or "PC"),C.acc)
LOG("OpenCase="..tostring(f:FindFirstChild("OpenCase")~=nil).." Sell="..tostring(f:FindFirstChild("Sell")~=nil).." Battle="..tostring(f:FindFirstChild("CreateBattle")~=nil),C.gry)
updateStats(); refreshInv()

-- DEBUG: dump PlayerData structure to F9 console (copyable)
task.spawn(function()
    task.wait(1)
    warn("=== AUTOFARM DEBUG START ===")

    warn("--- PlayerData ---")
    local function dumpTree(parent,depth,prefix)
        if depth>4 then return end
        for _,ch in ipairs(parent:GetChildren()) do
            local info=ch.Name.."["..ch.ClassName.."]"
            if ch:IsA("ValueBase") then info=info.."="..tostring(ch.Value) end
            local extra=""
            if ch:IsA("Folder") then extra=" ("..#ch:GetChildren().." items)" end
            -- dump attributes
            local attrs=ch:GetAttributes()
            local attrStr=""
            for k,v in pairs(attrs) do attrStr=attrStr..k.."="..tostring(v)..", " end
            if attrStr~="" then extra=extra.." ATTRS: "..attrStr end
            warn(prefix..info..extra)
            if ch:IsA("Folder") then dumpTree(ch,depth+1,prefix.."  ") end
        end
    end
    dumpTree(pd,0,"")

    warn("--- All Remotes ---")
    for _,r in ipairs(f:GetChildren()) do
        warn("  "..r.Name.." ["..r.ClassName.."]")
    end

    warn("--- Quest remotes ---")
    for _,r in ipairs(f:GetChildren()) do
        local nm=r.Name:lower()
        if nm:find("quest") or nm:find("daily") or nm:find("calendar") or nm:find("reward") or nm:find("afk") then
            warn("Remote: "..r.Name.." ["..r.ClassName.."]")
        end
    end

    warn("--- Try all quest remotes ---")
    for _,r in ipairs(f:GetChildren()) do
        local nm=r.Name:lower()
        if nm:find("quest") or nm:find("daily") or nm:find("calendar") or nm:find("reward") then
            if r:IsA("RemoteFunction") then
                local ok,res=pcall(function() return r:InvokeServer() end)
                warn(r.Name..": ok="..tostring(ok).." type="..tostring(typeof(res)).." val="..string.sub(tostring(res),1,300))
            end
        end
    end

    warn("=== AUTOFARM DEBUG END ===")
end)
