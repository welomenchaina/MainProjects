local HealthSysFile = "https://rscripts.net/raw/health-system-take-and-sethealth-for-script-developers_1751936776495_sG5nv8AJPN.txt"

local function load(link)
    loadstring(game:HttpGet(link, true))()
end

repeat task.wait() until game:IsLoaded()

load(HealthSysFile)
else
