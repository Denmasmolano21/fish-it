-- Auto Fish Speed Script for Fish It
-- Pastikan gunakan executor yang mendukung getconnections / firetouchinterest / etc.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local waitTime = 0.1 -- waktu antara cast dan reel, bisa diubah lebih kecil untuk lebih cepat

while true do
    -- Cast rod
    local rod = LocalPlayer.Backpack:FindFirstChild("Rod") or LocalPlayer.Character:FindFirstChild("Rod")
    if rod then
        rod:Activate()
    end
    
    wait(waitTime)
    
    -- Reel in
    if rod and rod:IsDescendantOf(game) then
        rod:Activate()
    end
    
    wait(waitTime)
end
