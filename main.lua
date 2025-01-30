local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Tạo cửa sổ Rayfield
local Window = Rayfield:CreateWindow({
   Name = "Siley Hub",
   Icon = 0,
   LoadingTitle = "Siley Hub",
   LoadingSubtitle = "by Saiky",
   Theme = "Light",
})

-- Tạo Tab "Main"
local MainTab = Window:CreateTab("Main", 4483362458)
local Main = MainTab:CreateSection("Auto Farm")

-- Biến toàn cục để kiểm tra trạng thái các tính năng
local AutoThrowEnabled = false
local AutoCatchEnabled = false
local AutoShakeEnabled = false

-- Toggle AutoThrow
local ToggleAutoThrow = MainTab:CreateToggle({
   Name = "AutoThrow",
   CurrentValue = false,
   Flag = "AutoThrow",
   Callback = function(Value)
      AutoThrowEnabled = Value
   end,
})

-- Toggle AutoCatch
local ToggleAutoCatch = MainTab:CreateToggle({
   Name = "AutoCatch",
   CurrentValue = false,
   Flag = "AutoCatch",
   Callback = function(Value)
      AutoCatchEnabled = Value
   end,
})

-- Toggle AutoShake
local ToggleAutoShake = MainTab:CreateToggle({
   Name = "AutoShake",
   CurrentValue = false,
   Flag = "AutoShake",
   Callback = function(Value)
      AutoShakeEnabled = Value
   end,
})

-- Hàm AutoShake
local function AutoShake()
    local Players = game:GetService('Players')
    local LocalPlayer = Players.LocalPlayer
    local VirtualInputManager = game:GetService('VirtualInputManager')

    local function ClickShakeButton(Descendant)
        if Descendant.Name == "button" and Descendant.Parent.Name == "safezone" then
            task.wait(0.1)
            local pos, size = Descendant.AbsolutePosition, Descendant.AbsoluteSize
            local centerX = math.floor(pos.X + size.X / 1)
            local centerY = math.floor(pos.Y + size.Y / 1)

            VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
        end
    end

    LocalPlayer.PlayerGui.DescendantAdded:Connect(function(Descendant)
        if AutoShakeEnabled then
            ClickShakeButton(Descendant)
        end
    end)
end

-- Chạy AutoShake trong một coroutine
coroutine.wrap(AutoShake)()

-- Hàm AutoThrow
local function AutoThrow()
    local args = {
        [1] = 100,  -- Khoảng cách ném
        [2] = 1     -- Tốc độ hoặc loại ném
    }

    local player = game:GetService("Players").LocalPlayer
    while true do
        if AutoThrowEnabled then
            for _, tool in pairs(player.Character:GetChildren()) do
                if tool:IsA("Tool") and tool.Name:lower():find("rod") then
                    if tool:FindFirstChild("events") and tool.events:FindFirstChild("cast") then
                        tool.events.cast:FireServer(unpack(args))
                    end
                end
            end
        end
        task.wait(0.1)
    end
end

-- Chạy AutoThrow trong một coroutine
coroutine.wrap(AutoThrow)()

-- Hàm AutoCatch
local function AutoCatch()
    local args = {
        [1] = 100,  -- Khoảng cách
        [2] = true  -- Chế độ bắt (catch)
    }

    while true do
        if AutoCatchEnabled then
            game:GetService("ReplicatedStorage").events.reelfinished:FireServer(unpack(args))
        end
        task.wait(0.1)
    end
end

-- Chạy AutoCatch trong một coroutine
coroutine.wrap(AutoCatch)()

local Main = MainTab:CreateSection("Treasure")

-- Danh sách các bản đồ đã equip để tránh trùng lặp
local equippedMaps = {}

-- Đếm số bản đồ đã sửa
local repairedCount = 0

-- Tạo Toggle "Auto Repair Treasure"
local AutoRepairToggle = MainTab:CreateToggle({
   Name = "Auto Repair Treasure",
   CurrentValue = false,
   Flag = "AutoRepairTreasureToggle", -- Identifier for saving this toggle's state
   Callback = function(Value)
      if Value then
         -- Bắt đầu quá trình sửa bản đồ tự động khi toggle được bật
         local player = game:GetService("Players").LocalPlayer
         local backpack = player.Backpack
         local replicatedStorage = game:GetService("ReplicatedStorage")
         local net = replicatedStorage.packages.Net
         local npc = workspace.world.npcs:FindFirstChild("Jack Marrow")

         -- Lặp qua tối đa 25 bản đồ
         while repairedCount < 25 do
            -- Tạo danh sách các bản đồ chưa equip
            local treasureMaps = {}

            for _, item in pairs(backpack:GetChildren()) do
                if item.Name == "Treasure Map" and not equippedMaps[item] then
                    table.insert(treasureMaps, item)
                end
            end

            -- Nếu không còn bản đồ hợp lệ, dừng vòng lặp
            if #treasureMaps == 0 then
                print("Không còn bản đồ kho báu mới để sửa!")
                break
            end

            -- Chọn ngẫu nhiên một bản đồ chưa từng equip
            local selectedMap = treasureMaps[math.random(1, #treasureMaps)]
            equippedMaps[selectedMap] = true  -- Đánh dấu là đã sử dụng

            -- Equip bản đồ kho báu
            local equipArgs = {[1] = selectedMap}
            net:FindFirstChild("RE/Backpack/Equip"):FireServer(unpack(equipArgs))
            
            -- Chờ 0.5 giây để đảm bảo bản đồ đã được trang bị
            task.wait(0.1)

            -- Sửa bản đồ nếu NPC tồn tại
            if npc and npc:FindFirstChild("treasure") then
                npc.treasure.repairmap:InvokeServer()
            end

            -- Chờ 0.5 giây để sửa xong
            task.wait(0.1)

            -- Unequip bản đồ bằng cách trang bị lại từ Character để đưa nó về Backpack
            local unequipArgs = {
                [1] = player.Character:FindFirstChild("Treasure Map")
            }
            if unequipArgs[1] then
                net:FindFirstChild("RE/Backpack/Equip"):FireServer(unpack(unequipArgs))
            end

            -- Chờ 0.5 giây trước khi tiếp tục
            task.wait(0.1)

            -- Tăng số bản đồ đã sửa
            repairedCount = repairedCount + 1
            print("Đã sửa", repairedCount, "bản đồ kho báu")
         end

         print("Hoàn thành sửa 25 bản đồ!")
      else
         -- Dừng quá trình sửa bản đồ khi toggle được tắt
         print("Dừng sửa bản đồ kho báu.")
      end
   end,
})

-- Tạo Toggle "Collect Treasure" nếu bạn muốn thêm tính năng thu thập kho báu nữa
local CollectTreasureToggle = MainTab:CreateToggle({
   Name = "Collect Treasure",
   CurrentValue = false,
   Flag = "CollectTreasureToggle", -- Identifier for saving this toggle's state
   Callback = function(Value)
      if Value then
         -- Bắt đầu quá trình thu thập kho báu khi toggle được bật
         print("Bắt đầu thu thập kho báu...")
         -- Duyệt qua các tọa độ kho báu và mở chúng (dùng danh sách toạ độ kho báu ở đây)
         -- Thêm vào các tọa độ kho báu ở đây nếu cần
         local treasure_positions = {
            {x = -360.715, y = 98.682, z = 1751.031},
            {x = 965.308, y = 121.513, z = -1199.562},
            {x = 96.88, y = 46.941, z = 1618.29},
            {x = 898.77, y = 97.663, z = -1195.711},
            {x = -128.174, y = 149.569, z = -1156.629},
            {x = -360.715, y = 98.682, z = 1751.031},
            {x = 965.308, y = 121.513, z = -1199.562},
            {x = 96.88, y = 46.941, z = 1618.29},
            {x = 898.77, y = 97.663, z = -1195.711},
            {x = -128.174, y = 149.569, z = -1156.629},
            {x = -1296.337, y = 90.864, z = 1650.275},
            {x = -1722.3, y = 141.965, z = 222.761},
            {x = -5.262, y = 92.744, z = -967.854},
            {x = -696.315, y = 95.188, z = -967.854},
            {x = -846.432, y = 131.71, z = -1176.826},
            {x = 1256.724, y = 87.825, z = 627.428},
            {x = 1274.54, y = 76.857, z = 348.746},
            {x = 1765.695, y = 95.03, z = -1138.195},
            {x = 207.123, y = 137.55, z = 35.314},
            {x = 2477.567, y = 87.606, z = 2776.791},
            {x = 698.439, y = 38.316, z = 2134.389},
            {x = 2889.96, y = 41.557, z = 3125.344},
            {x = 381.499, y = 111.771, z = 350.943},
            {x = 2560.012, y = 106.769, z = -495.18},
            {x = 2889.96, y = 41.179, z = 3125.344},
            {x = 2560.179, y = 8.167, z = -348.085},
            -- Thêm các tọa độ rương khác vào đây nếu cần
         }

         for _, pos in ipairs(treasure_positions) do
            local args = {
                [1] = {x = pos.x, y = pos.y, z = pos.z}
            }

-- Tạo Tab "Teleport"
local TeleportTab = Window:CreateTab("Teleport", 4483362458)

-- Cập nhật các vị trí trong CFrame cho các dao
local targetCFrames = {
   ["Ancient Isle"] = CFrame.new(6064.08154, 198.710602, 294.896545, 0.539129496, 0, -0.842222869, 0, 1, 0, 0.842222869, 0, 0.539129496),
   ["Desolate Deep"] = CFrame.new(-1660.67505, -217.181732, -2844.40723, 0.454964399, 0.000282441149, 0.890509605, -1.20638724e-05, 0.99999994, -0.000311004551, -0.890509605, 0.000130753004, 0.45496434),
   ["Moosewood"] = CFrame.new(500.199585, 147.40181, 230.211761, -0.825280786, 0, 0.564722538, 0, 1, 0, -0.564722538, 0, -0.825280786),
   ["Cryogenic Canal"] = CFrame.new(20303.1777, 706.505737, 5767.07324, -0.528041244, 0, -0.849218786, 0, 1, 0, 0.849218786, 0, -0.528041244),
   ["Forsaken"] = CFrame.new(-2498.24585, 133.71489, 1624.8551, 1, 0, 0, 0, 1, 0, 0, 0, 1),
   ["Keepers"] = CFrame.new(1294.57568, -807.365051, -307.565216, 0.0331695676, 0, 0.99944973, 0, 1, 0, -0.99944973, 0, 0.0331695676),
   ["Overgrowth"] = CFrame.new(19640.793, 134.185242, 5249.43408, -0.47142148, 0, -0.881908059, 0, 1, 0, 0.881908059, 0, -0.47142148),
   ["Roslit"] = CFrame.new(-1476.51147, 130.168427, 671.685303, 0, 0, -1, 0, 1, 0, 1, 0, 0),
   ["Snowcap"] = CFrame.new(2667.74072, 148.202011, 2384.3208, -0.464032531, -0.044061318, -0.884721994, -0.0204825327, 0.999028802, -0.0390110984, 0.885581613, 1.89337879e-05, -0.464484453),
   ["Sunstone"] = CFrame.new(-1059.81604, 135.151627, -1147.62671, 0.939700544, -0, -0.341998369, 0, 1, -0, 0.341998369, 0, 0.939700544),
   ["The Depths"] = CFrame.new(965.452759, -710.921082, 1223.67786, -1, 0, 0, 0, 1, 0, 0, 0, -1),
   ["Vertigo"] = CFrame.new(-112.007278, -492.901093, 1040.32788, -1, 0, 0, 0, 1, 0, 0, 0, -1),
   ["Altar"] = CFrame.new(1310.5465087890625, -799.4696044921875, -82.7303466796875),
   ["Terrapin"] = CFrame.new(50.320713, 297.993866, 1992.42078, 0.885196388, 0, 0.465217561, 0, 1, 0, -0.465217561, 0, 0.885196388),
   ["Volcano"] = CFrame.new(-1888.52319, 163.847565, 329.238281, 1, 0, 0, 0, 1, 0, 0, 0, 1),
   ["Crafting Table"] = CFrame.new(-3159.99512, -746.362976, 1684.16797, 1, 0, 0, 0, 1, 0, 0, 0, 1),
   ["The Grand"] = CFrame.new(-3402.86719, 140.060608, 250.846542, -0.457844615, 0, -0.889032245, 0, 1, 0, 0.889032245, 0, -0.457844615),
   ["The Keeper's Secret"] = CFrame.new(2233.21436, -805.562439, 1036.09302, 1, 0, 0, 0, 1, 0, 0, 0, 1),
   ["Mushgrove"] = CFrame.new(2501.48584, 127.758324, -720.699463, 0, 0, -1, 0, 1, 0, 1, 0, 0),
   ["Atlantis"] = CFrame.new(-4254.53613, -606.398193, 1804.92737, -0.825280786, 0, 0.564722538, 0, 1, 0, -0.564722538, 0, -0.825280786),
   -- Add more locations...
}

local selectedIsland = "Select island"

-- Tạo Dropdown để chọn đảo
local IslandDropdown = TeleportTab:CreateDropdown({
   Name = "Chọn Vị Trí Dịch Chuyển (Island)",
   Options = {"Ancient Isle", "Desolate Deep", "Moosewood", "Cryogenic Canal", "Forsaken", "Keepers", "Overgrowth", "Roslit", "Snowcap", "Sunstone", "The Depths", "Vertigo", "Altar", "Terrapin", "Volcano", "Crafting Table", "The Grand", "The Keeper's Secret", "Mushgrove", "Atlantis"},
   CurrentOption = {selectedIsland},
   MultipleOptions = false,
   Flag = "IslandDropdown",
   Callback = function(Options)
      selectedIsland = Options[1]
   end,
})

-- Tạo nút Teleport
TeleportTab:CreateButton({
   Name = "Teleport to Island",
   Callback = function()
      local player = game.Players.LocalPlayer
      if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
         local humanoidRootPart = player.Character.HumanoidRootPart
         local targetCFrame = targetCFrames[selectedIsland]
         humanoidRootPart.CFrame = targetCFrame
      end
   end,
})

-- Lưu trữ các vị trí và CFrame cho các cần câu
local rodCFrames = {
   ["Carbon rod"] = CFrame.new(453.698517, 150.590073, 223.101776, 0.985374212, -0.170404434, 1.41561031e-07, 1.41561031e-07, 1.7285347e-06, 1, -0.170404434, -0.985374212, 1.7285347e-06),
   ["Fast rod"] = CFrame.new(447.183563, 149.580643, 219.807541, -0.193451524, -3.1888485e-06, -0.981109917, -0.264903724, -0.962859035, 0.0522358418, -0.944670618, 0.270004749, 0.186265707),
   ["Long rod"] = CFrame.new(482.618622, 171.656326, 148.242599, -0.630167365, -0.776459217, -5.33461571e-06, 5.33461571e-06, -1.12056732e-05, 1, -0.776459217, 0.630167365, 1.12056732e-05),
   ["Lucky rod"] = CFrame.new(445.58194, 150.289566, 221.319565, 0.974526405, -0.22305499, 0.0233404674, 0.196993902, 0.901088715, 0.386306256, -0.107199371, -0.371867687, 0.922075212),
   ["Plastic rod"] = CFrame.new(454.585754, 150.368546, 228.674957, 0.951755166, 0.0709736273, -0.298537821, -3.42726707e-07, 0.972884834, 0.231290117, 0.306858391, -0.220131472, 0.925948203),
   ["Trident rod"] = CFrame.new(-1479.48987, -228.710632, -2391.39307, 0.0435845852, 0, 0.999049723, 0, 1, 0, -0.999049723, 0, 0.0435845852),
   ["Kings rod"] = CFrame.new(1375.57642, -810.201721, -303.509247, -0.7490201, 0.662445903, -0.0116144121, -0.0837960541, -0.0773290396, 0.993478119, 0.657227278, 0.745108068, 0.113431036),
   ["Phoenix rod"] = CFrame.new(5971.03125, 270.377502, 852.372559, -0.498096943, 0.101641625, -0.861143589, -0.0435730033, 0.988917768, 0.141926154, 0.866025805, 0.108215615, -0.488148093),
   ["Magnet rod"] = CFrame.new(-194.998871, 130.148087, 1930.97107, -0.877933741, 0.200040877, -0.434989601, 0.227177292, 0.973794818, -0.0106849447, 0.421453208, -0.108200423, -0.900372148),
   ["Nocturnal rod"] = CFrame.new(-141.874237, -515.313538, 1139.04529, 0.161644459, -0.98684907, 1.87754631e-05, 1.87754631e-05, 2.21133232e-05, 1, -0.98684907, -0.161644459, 2.21133232e-05),
   ["Aurora rod"] = CFrame.new(-144.462006, -514.395081, 1130.17383, 0.951246321, -0.286451101, -0.114351019, 0.258846343, 0.943026602, -0.20904395, 0.167716935, 0.169252962, 0.971197426),
   ["Scurvy rod"] = CFrame.new(-2828.21851, 213.457199, 1512.20959, -0.939700961, -0.341998369, 0, -0.341998369, 0.939700544, 0, -0, 0, -1.00000048),
   ["Rapid rod"] = CFrame.new(-1509.24463, 139.725906, 759.628174, 0.992959678, 1.84196979e-05, -0.11845281, 0.0317781717, 0.963300347, 0.266538173, 0.114110537, -0.268425852, 0.956517816),
   ["Steady rod"] = CFrame.new(-1511.23523, 139.679504, 759.417114, 0.992959678, 1.84196979e-05, -0.11845281, 0.0317781717, 0.963300347, 0.266538173, 0.114110537, -0.268425852, 0.956517816),
   ["Fortune rod"] = CFrame.new(-1520.87964, 141.283279, 771.946777, 0.220332444, -0.975424826, -5.51939011e-05, -5.51939011e-05, -6.90221786e-05, 1, -0.975424826, -0.220332414, -6.90221786e-05),
   ["Arctic rod"] = CFrame.new(19578.2363, 132.338379, 5307.38281, 0.462664127, 0.826065004, -0.321804911, -0.571607292, 0.000499367714, -0.820527136, -0.677648067, 0.563574493, 0.472415924),
   ["Avalanche rod"] = CFrame.new(19770.1816, 415.680969, 5419.19678, 0.65369606, -0.341275394, -0.675435066, 0.0860147476, 0.920261979, -0.381732106, 0.751852989, 0.19143939, 0.630926371),
   ["Summit rod"] = CFrame.new(20207.7539, 736.058289, 5711.35156, -0.321401596, -0.946943283, -2.30371952e-05, -2.30371952e-05, 3.19480896e-05, -1.00000024, 0.946943283, -0.321401477, -3.24249268e-05),
   ["Reinforced rod"] = CFrame.new(-986.474365, -245.473938, -2689.79248, 0.950221658, -0.248433635, 0.188041329, -0.188312545, 0.0228964686, 0.981842279, -0.248228103, -0.968378305, -0.0250264406),
   ["Rod Of The Depths"] = CFrame.new(1704.84009, -903.546753, 1447.78687, 0.954411745, -0, -0.298493177, 0, 1, -0, 0.298493177, 0, 0.954411745),
   ["Stone rod"] = CFrame.new(5502.14844, 143.893082, -313.94165, 0.300579906, 3.40044498e-05, -0.953756571, 0.952850342, -0.0435936451, 0.30029273, -0.0415675938, -0.999049306, -0.0131357908),
   ["Heaven rod"] = CFrame.new(20025.7578, -468.918365, 7146.93311, -0.999410152, 0, 0.0343510993, 0, 1, 0, -0.0343510993, 0, -0.999410152),
   ["Abyssal Specter Rod"] = CFrame.new(-3804.21948, -565.93811, 1870.35376, 1, 0, 0, 0, 1, 0, 0, 0, 1),
   ["Kraken rod"] = CFrame.new(-4415.44238, -995.197388, 2054.33008, -1.1920929e-07, 0, -1.00000012, 0, 1, 0, 1.00000012, 0, -1.1920929e-07),
   ["Depthseeker Rod"] = CFrame.new(-4466.00439, -604.746887, 1875.24377, -0.344021797, 0, -0.938961744, 0, 1, 0, 0.938961744, 0, -0.344021797),
   ["Champions rod"] = CFrame.new(-4277.32959, -602.254883, 1839.04224, -0.997859359, 0, 0.0653970614, 0, 1, 0, -0.0653970614, 0, -0.997859359),
   ["Tempest rod"] = CFrame.new(-4927.72754, -594.364868, 1856.83557, 0.751858234, -0, -0.659324884, 0, 1, -0, 0.659324884, 0, 0.751858234),
   ["Zeus rod"] = CFrame.new(-4270.88477, -625.938599, 2664.46655, 0.499959469, 0, 0.866048813, 0, 1, 0, -0.866048813, 0, 0.499959469),
   ["Poseidon rod"] = CFrame.new(-4086.17334, -556.94458, 895.043762, -1.1920929e-07, 0, -1.00000012, 0, 1, 0, 1.00000012, 0, -1.1920929e-07),
   -- Add other rods...
}

local selectedRod = "Select rod"

-- Tạo Dropdown để chọn vị trí Rod
local RodDropdown = TeleportTab:CreateDropdown({
   Name = "Chọn Vị Trí Cần Câu",
   Options = {"Carbon rod", "Fast rod", "Long rod", "Lucky rod", "Plastic rod", "Trident rod", "Kings rod", "Phoenix rod", "Magnet rod", "Nocturnal rod", "Aurora rod", "Scurvy rod", "Rapid rod", "Steady rod", "Fortune rod", "Arctic rod", "Avalanche rod", "Summit rod", "Reinforced rod", "Rod Of The Depths", "Stone rod", "Heaven rod", "Abyssal Specter Rod", "Kraken rod", "Depthseeker Rod", "Champions rod", "Tempest rod", "Zeus rod", "Poseidon rod"},
   CurrentOption = {selectedRod},
   MultipleOptions = false,
   Flag = "RodDropdown",
   Callback = function(Option)
      selectedRod = Option[1]
   end,
})

-- Tạo nút Teleport to Rod
TeleportTab:CreateButton({
   Name = "Teleport to Rod",
   Callback = function()
      local player = game.Players.LocalPlayer
      if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
         local humanoidRootPart = player.Character.HumanoidRootPart
         local targetCFrame = rodCFrames[selectedRod]
         humanoidRootPart.CFrame = targetCFrame
      end
   end,
})

-- Lưu trữ các vị trí và CFrame cho các cần câu
local itemCFrames = {
   ["Meteor totem"] = CFrame.new(-1945.82629, 272.438995, 231.544128, 0.758035481, 0.199635401, 0.620909035, -0.0421228558, 0.965000629, -0.258842587, -0.650851786, 0.170057416, 0.73991394),
   ["Windset totem"] = CFrame.new(2851.57422, 178.117111, 2703.02295, -0.369645119, 3.03834677e-05, 0.929172993, 0.141992167, 0.988256574, 0.0564552285, -0.918259621, 0.152803689, -0.365308523),
   ["Sundial totem"] = CFrame.new(-1149.45288, 134.568192, -1077.27637, -0.945118904, 0, -0.326726705, 0, 1, 0, 0.326726705, 0, -0.945118904),
   ["Tempest totem"] = CFrame.new(36.4246826, 133.026794, 1946.0824, 0.602275848, 0, 0.798288047, 0, 1, 0, -0.798288047, 0, 0.602275848),
   ["Smokescreen totem"] = CFrame.new(2791.71216, 137.350662, -629.452271, -0.998513579, 0.0327778272, 0.0435543507, 0.0298345778, 0.997334361, -0.0665888488, -0.0456208885, -0.0651904196, -0.996829748),
   ["Blizzard totem"] = CFrame.new(20148.748, 740.134399, 5803.66113, -0.555555582, 0, 0.83147943, 0, 1, 0, -0.83147943, 0, -0.555555582),
   ["Avalanche totem"] = CFrame.new(19708.2539, 464.812408, 6058.12744, -0.47142148, 0, -0.881908059, 0, 1, 0, 0.881908059, 0, -0.47142148),
   ["Aurora totem"] = CFrame.new(-1812.63257, -139.749878, -3279.98779, 0.671925902, -0.222812086, -0.70630753, 0.0369239748, 0.962564886, -0.268524557, 0.739697337, 0.154348925, 0.654999435),
   ["Pickaxe"] = CFrame.new(19783.1914, 415.743622, 5391.92041, 0.634382486, -0.024009414, -0.772646368, 2.21384689, 0.999518096, -0.0310411081, 0.773019373, 0.0196748301, 0.634077311),
   ["Crab cage"] = CFrame.new(475.411377, 150.63176, 230.392365, 0.864977479, 0, 0.50181067, 0, 1, 0, -0.50181067, 0, 0.864977479),
   -- Add other items...
}

local selectedItem = "Select item"

-- Tạo Dropdown để chọn vị trí Rod
local ItemDropdown = TeleportTab:CreateDropdown({
   Name = "Chọn Vị Trí Item",
   Options = {"Meteor totem", "Windset totem", "Sundial totem", "Tempest totem", "Smokescreen totem", "Blizzard totem", "Avalanche totem", "Aurora totem", "Pickaxe", "Crab cage"},
   CurrentOption = {selectedItem},
   MultipleOptions = false,
   Flag = "ItemDropdown",
   Callback = function(Option)
      selectedItem = Option[1]
   end,
})

-- Tạo nút Teleport to Item
TeleportTab:CreateButton({
   Name = "Teleport to Item",
   Callback = function()
      local player = game.Players.LocalPlayer
      if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
         local humanoidRootPart = player.Character.HumanoidRootPart
         local targetCFrame = itemCFrames[selectedItem]
         humanoidRootPart.CFrame = targetCFrame
      end
   end,
})
