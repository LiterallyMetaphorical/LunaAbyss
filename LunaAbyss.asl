// Shoutouts to Micrologist for all of the sig scan related shenanigans in this ASL (taken from SPRAWL.) Not sure why loading didnt work, so that's pointer based for now.
//Luna Abyss ASL Script made by Nikoheart and Meta
state("LunaAbyss-Win64-Shipping")
{
    bool loading : 0x046AA160, 0xD18, 0x10, 0x1A0, 0x2A0, 0xD0, 0xFC4;
}

startup
{
    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
    {
        var timingMessage = MessageBox.Show (
            "This game uses Time without Loads (Game Time) as the main timing method.\n"+
            "LiveSplit is currently set to show Real Time (RTA).\n"+
            "Would you like to set the timing method to Game Time?",
            "LiveSplit | Luna Abyss",
            MessageBoxButtons.YesNo,MessageBoxIcon.Question
        );

        if (timingMessage == DialogResult.Yes)
        {
            timer.CurrentTimingMethod = TimingMethod.GameTime;
        }
    }

    	//creates text components for variable information
	vars.SetTextComponent = (Action<string, string>)((id, text) =>
	{
	        var textSettings = timer.Layout.Components.Where(x => x.GetType().Name == "TextComponent").Select(x => x.GetType().GetProperty("Settings").GetValue(x, null));
	        var textSetting = textSettings.FirstOrDefault(x => (x.GetType().GetProperty("Text1").GetValue(x, null) as string) == id);
	        if (textSetting == null)
	        {
	        var textComponentAssembly = Assembly.LoadFrom("Components\\LiveSplit.Text.dll");
	        var textComponent = Activator.CreateInstance(textComponentAssembly.GetType("LiveSplit.UI.Components.TextComponent"), timer);
	        timer.Layout.LayoutComponents.Add(new LiveSplit.UI.Components.LayoutComponent("LiveSplit.Text.dll", textComponent as LiveSplit.UI.Components.IComponent));
	
	        textSetting = textComponent.GetType().GetProperty("Settings", BindingFlags.Instance | BindingFlags.Public).GetValue(textComponent, null);
	        textSetting.GetType().GetProperty("Text1").SetValue(textSetting, id);
	        }
	
	        if (textSetting != null)
	        textSetting.GetType().GetProperty("Text2").SetValue(textSetting, text);
    	});

    //Parent setting
	settings.Add("Variable Information", true, "Variable Information");
	//Child settings that will sit beneath Parent setting
	settings.Add("Camera", true, "Camera", "Variable Information");
    settings.Add("Map", true, "Map", "Variable Information");
    settings.Add("Checkpoint", true, "Checkpoint", "Variable Information");

    //Parent setting
	settings.Add("Checkpoint Splits", true, "Checkpoint Splits");
	//Child settings that will sit beneath Parent setting
    settings.Add("Sorrows Entrance", true, "Sorrows Entrance", "Checkpoint Splits");
    settings.Add("Sorrows Canyon", true, "Sorrows Canyon", "Checkpoint Splits");
    settings.Add("First Arena", true, "First Arena", "Checkpoint Splits");
    settings.Add("Oops", true, "Oops", "Checkpoint Splits");
    settings.Add("The Waif", true, "The Waif", "Checkpoint Splits");
    settings.Add("Sorrow Tower Climb I", true, "Sorrow Tower Climb I", "Checkpoint Splits");
    settings.Add("Sorrow Tower Climb II", true, "Sorrow Tower Climb II", "Checkpoint Splits");
    settings.Add("Arena Bridge", true, "Arena Bridge", "Checkpoint Splits");
    settings.Add("Shieldbreaker", true, "Shieldbreaker", "Checkpoint Splits");
    settings.Add("Shieldbreaker Ravine", true, "Shieldbreaker Ravine", "Checkpoint Splits");
    settings.Add("Second Arena", true, "Second Arena", "Checkpoint Splits");
    settings.Add("Ending Split", true, "Ending Split", "Checkpoint Splits");
}

init
{
    // Scanning the MainModule for static pointers to GSyncLoadCount, UWorld, UEngine and FNamePool
    var scn = new SignatureScanner(game, game.MainModule.BaseAddress, game.MainModule.ModuleMemorySize);
    var uWorldTrg = new SigScanTarget(8, "0F 2E ?? 74 ?? 48 8B 1D ?? ?? ?? ?? 48 85 DB 74") { OnFound = (p, s, ptr) => ptr + 0x4 + game.ReadValue<int>(ptr) };
    var uWorld = scn.Scan(uWorldTrg);
    var gameEngineTrg = new SigScanTarget(3, "48 39 35 ?? ?? ?? ?? 0F 85 ?? ?? ?? ?? 48 8B 0D") { OnFound = (p, s, ptr) => ptr + 0x4 + game.ReadValue<int>(ptr) };
    var gameEngine = scn.Scan(gameEngineTrg);
    var fNamePoolTrg = new SigScanTarget(13, "89 5C 24 ?? 89 44 24 ?? 74 ?? 48 8D 15") { OnFound = (p, s, ptr) => ptr + 0x4 + game.ReadValue<int>(ptr) };
    var fNamePool = scn.Scan(fNamePoolTrg);

    // Throwing in case any base pointers can't be found (yet, hopefully)
    if(uWorld == IntPtr.Zero || gameEngine == IntPtr.Zero || fNamePool == IntPtr.Zero)
    {
        throw new Exception("One or more base pointers not found - retrying");
    }

	vars.Watchers = new MemoryWatcherList
    {
        // UWorld.Name
        new MemoryWatcher<ulong>(new DeepPointer(uWorld, 0x18)) { Name = "worldFName"},
        // GameEngine.GameInstance.LocalPlayers[0].PlayerController.PlayerCameraManager.ViewTarget.Target.Name
        new MemoryWatcher<ulong>(new DeepPointer(gameEngine, 0xD28, 0x38, 0x0, 0x30, 0x2B8, 0xE90, 0x18)) { Name = "camViewTargetFName"},
        // GameEngine.Gameinstance.LocalPlayers[0].PlayerController.MyHUD.PawnSpecificWidgets[0].UI_LevelEndScreen
        //new MemoryWatcher<IntPtr>(new DeepPointer(gameEngine, 0xD28, 0x38, 0x0, 0x30, 0x2B0, 0x310, 0x0, 0x2E0)) { Name = "levelEndScreenPtr"},

        new StringWatcher(new DeepPointer(gameEngine, 0xD28, 0x2F0,0x0),500) { Name = "CurrentCheckpointName"},
    };

    // Translating FName to String, this *could* be cached
    vars.FNameToString = (Func<ulong, string>)(fName =>
    {
        var number   = (fName & 0xFFFFFFFF00000000) >> 0x20;
        var chunkIdx = (fName & 0x00000000FFFF0000) >> 0x10;
        var nameIdx  = (fName & 0x000000000000FFFF) >> 0x00;
        var chunk = game.ReadPointer(fNamePool + 0x10 + (int)chunkIdx * 0x8);
        var nameEntry = chunk + (int)nameIdx * 0x2;
        var length = game.ReadValue<short>(nameEntry) >> 6;
        var name = game.ReadString(nameEntry + 0x2, length);
        return number == 0 ? name : name + "_" + number;
    });

    vars.Watchers.UpdateAll(game);

    current.world = old.world = vars.FNameToString(vars.Watchers["worldFName"].Current);
    
    //helps with null values throwing errors
    current.camTarget = "";
    current.world = "";
    current.checkpointname = "";
}

update
{
    vars.Watchers.UpdateAll(game);

    // Get the current world name as string, only if *UWorld isnt null
    var worldFName = vars.Watchers["worldFName"].Current;
    current.world = worldFName != 0x0 ? vars.FNameToString(worldFName) : old.world;

    // Get the Name of the current target for the CameraManager
    current.camTarget = vars.FNameToString(vars.Watchers["camViewTargetFName"].Current);

    // Get the name of the current checkpoint
    if (!String.IsNullOrWhiteSpace(vars.Watchers["CurrentCheckpointName"].Current)) current.checkpointname = vars.Watchers["CurrentCheckpointName"].Current;

        if(settings["Camera"]) 
    {
        vars.SetTextComponent("Camera Target:",current.camTarget.ToString());
        if (old.camTarget != current.camTarget) print("Camera Target:" + current.camTarget.ToString());
    }

        if(settings["Map"]) 
    {
        vars.SetTextComponent("Map:",current.world.ToString());
        if (old.world != current.world) print("Camera Target:" + current.world.ToString());
    }

        if(settings["Checkpoint"] && current.world != "MainMenuMap") 
    {
        vars.SetTextComponent("Checkpoint:",current.checkpointname.ToString());
        if (old.checkpointname != current.checkpointname) print("Camera Target:" + current.checkpointname.ToString());
    }

//DEBUG CODE
    //print(current.loading.ToString());
    //print("Loaded Map = " + current.world.ToString());
    //print("Camera Target = " + current.camTarget.ToString());
    //print(modules.First().ModuleMemorySize.ToString());
}

start
{
    if (old.world == "MainMenuMap" && current.world == "Abyss_PERSISTENT")
    {
        timer.IsGameTimePaused = true;
        return true;
    }
    //return current.camTarget == "BP_Fawkes_Character_C_2147435681" && old.camTarget != current.camTarget;
}

split
{
    //return current.camTarget == "CineCameraActor_2147450557" && old.camTarget != current.camTarget; // just for testing purposes
    if (settings["Sorrows Entrance"] && old.checkpointname == "SorrowsEntrance" && current.checkpointname == "SorrowsCanyon")
    {
        print("Split 1");
        return true;
    }

    if (settings["Sorrows Canyon"] && old.checkpointname == "SorrowsCanyon" && current.checkpointname == "FirstArenaStart")
    {
        print("Split 2");
        return true;
    }

    if (settings["First Arena"] && old.checkpointname == "FirstArenaStart" && current.checkpointname == "FirstArenaEnd")
    {
        print("Split 3");
        return true;
    }

        if (settings["Oops"] && old.checkpointname == "FirstArenaEnd" && current.checkpointname == "TheWaif")
    {
        print("Split 4");
        return true;
    }

    if (settings["The Waif"] && old.checkpointname == "TheWaif" && current.checkpointname == "SorrowTowerClimb")
    {
        print("Split 5");
        return true;
    }

    if (settings["Sorrow Tower Climb I"] && old.checkpointname == "SorrowTowerClimb" && current.checkpointname == "Tower")
    {
        print("Split 6");
        return true;
    }

    if (settings["Sorrow Tower Climb II"] && old.checkpointname == "SorrowTowerPuzzleEnd" && current.checkpointname == "ArenaBridge")
    {
        print("Split 7");
        return true;
    }

    if (settings["Arena Bridge"] && old.checkpointname == "ArenaBridge" && current.checkpointname == "BeforeShieldbreaker")
    {
        print("Split 8");
        return true;
    }

    if (settings["Shieldbreaker"] && old.checkpointname == "Shieldbreaker" && current.checkpointname == "ShieldBreakerRavine")
    {
        print("Split 9");
        return true;
    }

    if (settings["Shieldbreaker Ravine"] && old.checkpointname == "FirstHealthChest" && current.checkpointname == "SecondArenaStart")
    {
        print("Split 10");
        return true;
    }

    if (settings["Second Arena"] && old.checkpointname == "SecondArenaStart" && current.checkpointname == "AfterShieldbreakerHardCombat")
    {
        print("Split 11");
        return true;
    }
}

isLoading
{
    return current.loading;
}