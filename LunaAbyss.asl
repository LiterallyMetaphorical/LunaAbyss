state("LunaAbyss-Win64-Shipping"){}

startup
{
	Assembly.Load(File.ReadAllBytes("Components/uhara9")).CreateInstance("Main");
	vars.Uhara.AlertLoadless();
	vars.CompletedSplits = new List<string>();

    #region TextComponent
		vars.lcCache = new Dictionary<string, LiveSplit.UI.Components.ILayoutComponent>();
		vars.SetText = (Action<string, object>)((text1, text2) =>
		{
			const string FileName = "LiveSplit.Text.dll";
			LiveSplit.UI.Components.ILayoutComponent lc;

			if (!vars.lcCache.TryGetValue(text1, out lc))
			{
				lc = timer.Layout.LayoutComponents.Reverse().Cast<dynamic>()
					.FirstOrDefault(llc => llc.Path.EndsWith(FileName) && llc.Component.Settings.Text1 == text1)
					?? LiveSplit.UI.Components.ComponentManager.LoadLayoutComponent(FileName, timer);

				vars.lcCache.Add(text1, lc);
			}

			if (!timer.Layout.LayoutComponents.Contains(lc)) timer.Layout.LayoutComponents.Add(lc);
			dynamic tc = lc.Component;
			tc.Settings.Text1 = text1;
			tc.Settings.Text2 = text2.ToString();
		});
		vars.RemoveText = (Action<string>)(text1 =>
		{
			LiveSplit.UI.Components.ILayoutComponent lc;
			if (vars.lcCache.TryGetValue(text1, out lc))
			{
				timer.Layout.LayoutComponents.Remove(lc);
				vars.lcCache.Remove(text1);
			}
		});
	#endregion

    dynamic[,] _settings =
    {
        { "CheckpointSplits", true, "Checkpoint Splits", null },
            { "SorrowsCanyon",                  true, "Sorrows Entrance", "CheckpointSplits" },
            { "FirstArenaStart",                true, "Sorrows Canyon", "CheckpointSplits" },
            { "FirstArenaEnd",                  true, "First Arena", "CheckpointSplits" },
            { "TheWaif",                        true, "Oops", "CheckpointSplits" },
            { "SorrowTowerClimb",               true, "The Waif", "CheckpointSplits" },
            { "Tower",                          true, "Sorrow Tower Climb I", "CheckpointSplits" },
            { "ArenaBridge",                    true, "Sorrow Tower Climb II", "CheckpointSplits" },
            { "BeforeShieldbreaker",            true, "Arena Bridge", "CheckpointSplits" },
            { "ShieldBreakerRavine",            true, "Shieldbreaker", "CheckpointSplits" },
            { "SecondArenaStart",               true, "Shieldbreaker Ravine", "CheckpointSplits" },
            { "AfterShieldbreakerHardCombat",   true, "Second Arena", "CheckpointSplits" },
            { "SecondArenaEnd",                 true, "Celebrant Boss", "CheckpointSplits" },
            { "HydraulicWallButton",            true, "Second Arena End", "CheckpointSplits" },
            { "WardenEntrance",                 true, "(Temp) Hydraulic Wall Button", "CheckpointSplits" },
            { "RegretPipes",                    true, "(Temp) Warden Entrance", "CheckpointSplits" },
            { "PlacentalSteps",                 true, "(Temp) Regret Pipes", "CheckpointSplits" },
            { "SorrowsEndingSplit",             true, "Sorrows Canyon End", "CheckpointSplits" },
            { "ScourgeRavine",                  true, "Scourge Ravine", "CheckpointSplits" },
            { "MeadowsCrater",                  true, "Meadows Crater", "CheckpointSplits" },
            { "PostSniperTutorial",             true, "Monarchs Lance", "CheckpointSplits" },
            { "CraterPathway",                  true, "Crater Pathway", "CheckpointSplits" },
            { "ReactorEntrance",                true, "Reactor Entrance", "CheckpointSplits" },
            { "MeadowsReactorClimb",            true, "Meadows Reactor Climb", "CheckpointSplits" },
            { "MeadowsReactor",                 true, "Meadows Reactor", "CheckpointSplits" },
            { "MeadowsBoss",                    true, "Meadows Boss Run Up", "CheckpointSplits" },
            { "ScourgeEndingSplit",             true, "Scourge Crater End", "CheckpointSplits" },
        { "Debug", false, "Debug", null },
            { "GSync",      false, "GSync", "Debug" },
            { "World",      false, "World", "Debug" },
            { "Checkpoint", true, "Checkpoint", "Debug" },
            { "CamTarget", true, "CamTarget", "Debug" },
    };
    
    vars.Uhara.Settings.Create(_settings);
}

init
{
    vars.Utils = vars.Uhara.CreateTool("UnrealEngine", "Utils");
	vars.Events = vars.Uhara.CreateTool("UnrealEngine", "Events");

    if (vars.Utils.GEngine != IntPtr.Zero) vars.Uhara.Log("GEngine found at " + vars.Utils.GEngine.ToString("X"));
    if (vars.Utils.GWorld != IntPtr.Zero) vars.Uhara.Log("GWorld found at " + vars.Utils.GWorld.ToString("X")); 
    if (vars.Utils.FNames != IntPtr.Zero) vars.Uhara.Log("FNames found at " + vars.Utils.FNames.ToString("X"));

	vars.Resolver.Watch<int>("GSync", vars.Utils.GSync);
    vars.Resolver.Watch<uint>("GWorldName", vars.Utils.GWorld, 0x18);
    vars.Resolver.WatchString("CheckpointName", vars.Utils.GEngine, 0xD28, 0x378, 0x0);
    vars.Resolver.WatchString("CamTargetName", vars.Utils.GEngine, 0xD28, 0x38, 0x0, 0x30, 0x2B8, 0xE90, 0x18);
    vars.Resolver.Watch<float>("xVel", vars.Utils.GEngine, 0xD28, 0x38, 0x0, 0x30, 0x260, 0x288, 0xC4);

	vars.Events.FunctionFlag("FMFadeToWidget", "BP_FadeManager_C", "BP_FadeManager_C", "OnFadeToWidget");
    vars.Events.FunctionFlag("FMCutToBlack", "BP_FadeManager_C", "BP_FadeManager_C", "OnCutToBlack");
    vars.Events.FunctionFlag("FMFadeFromWidget", "BP_FadeManager_C", "BP_FadeManager_C", "OnFadeFromWidget");
    vars.Events.FunctionFlag("DemoSlate", "WBP_Demo_EndSlate_C", "WBP_Demo_EndSlate_C", "ExecuteUbergraph_WBP_Demo_EndSlate");
    // vars.Events.FunctionFlag("StartDemo1", "WBP_Splashscreen_VS_C", "WBP_Splashscreen_VS_C", "StartDemo01");
    vars.Events.FunctionFlag("EnteredAbyss", "CAN_Sorrow_GEO_C", "CAN_Sorrow_GEO_C", "EnteredAbyss");
    vars.Events.FunctionFlag("EndOfDemoSorrow", "CAN_Sorrow_GEO_C", "CAN_Sorrow_GEO_C", "End of Demo Event");
    vars.Events.FunctionFlag("EndOfDemoScourge", "MED_Crater_GEO_C", "MED_Crater_GEO_C", "End of Demo Event");

    // vars.Events.FunctionFlag("CheckPointEnterPortal", "BP_Checkpoint_C", "BP_Checkpoint_C", "OnEnterPortal");
    // vars.Events.FunctionFlag("CheckpointHalfwayStart", "BP_CheckPoint_Halfway_C", "BP_CheckPoint_Halfway_C", "Timeline_0__UpdateFunc");

    vars.Loading = false;
    current.StartReady = false;
    current.World = "";
    current.CamTarget = "";
    current.CheckpointName = "";

    #region Text Component
		vars.SetTextIfEnabled = (Action<string, object>)((text1, text2) =>
		{
			if (settings[text1]) vars.SetText(text1, text2); 
			else vars.RemoveText(text1);
		});
	#endregion
}

update
{
    vars.Uhara.Update();

    var world = vars.Utils.FNameToString(current.GWorldName);
	if (!string.IsNullOrEmpty(world) && world != "None") current.World = world;

    var ctFName = vars.Utils.FNameToString(current.CamTargetName);
	if (!string.IsNullOrEmpty(ctFName) && ctFName != "None") current.CamTarget = ctFName;
    if (old.CamTarget != current.CamTarget) vars.Uhara.Log("CamTarget: " + current.CamTarget);

	if (vars.Resolver.CheckFlag("FMFadeToWidget")) vars.Loading = true;
    if (vars.Resolver.CheckFlag("FMCutToBlack")) vars.Loading = true;
	if (vars.Resolver.CheckFlag("FMFadeFromWidget")) vars.Loading = false;

    if (old.CheckpointName != current.CheckpointName) vars.Uhara.Log("Checkpoint Name: " + current.CheckpointName);

    #region Debug Prints
	if (settings["Debug"])
	{
		if (old.GSync != current.GSync) {vars.Uhara.Log("GSync: " + old.GSync + " -> " + current.GSync); vars.SetTextIfEnabled("GSync",current.GSync);}
        if (old.World != current.World) {vars.Uhara.Log("World: " + old.World + " -> " + current.World); vars.SetTextIfEnabled("World",current.World);}
        if (old.CheckpointName != current.CheckpointName) {vars.Uhara.Log("Checkpoint: " + old.CheckpointName + " -> " + current.CheckpointName); vars.SetTextIfEnabled("Checkpoint",current.CheckpointName);}
        if (old.CamTarget != current.CamTarget) {vars.Uhara.Log("CamTarget: " + old.CamTarget + " -> " + current.CamTarget); vars.SetTextIfEnabled("CamTarget",current.CamTarget);}
	}
	#endregion

    if (old.World == "MainMenuMap" && current.World == "Abyss_PERSISTENT")
    {
        current.StartReady = true;
        vars.Uhara.Log("Start Ready? --> " + current.StartReady);
    }
}

onStart
{
	vars.CompletedSplits.Clear();
    current.StartReady = false;
}

start
{
    if (current.StartReady == true && current.xVel != 0 && current.xVel != old.xVel)
    {
        return true;
    }
}

split
{

    if (old.CheckpointName != current.CheckpointName && settings.ContainsKey(current.CheckpointName) && settings[current.CheckpointName] && !vars.CompletedSplits.Contains(current.CheckpointName))
    {
        vars.CompletedSplits.Add(current.CheckpointName);
        print("Split: " + vars.Utils.FNameToString(current.CheckpointName));
        return true;
    }

    if (vars.Resolver.CheckFlag("EndOfDemoSorrow"))
    {
        if (settings["SorrowsEndingSplit"] && !vars.CompletedSplits.Contains("SorrowsEndingSplit"))
        {
            vars.CompletedSplits.Add("SorrowsEndingSplit");
            print("Split: Sorrow Ending Split");
            return true;
        }
    }

    if (vars.Resolver.CheckFlag("EndOfDemoScourge"))
    {
        if (settings["ScourgeEndingSplit"] && !vars.CompletedSplits.Contains("ScourgeEndingSplit"))
        {
            vars.CompletedSplits.Add("ScourgeEndingSplit");
            print("Split: Scourge Ending Split");
            return true;
        }
    }
}

isLoading
{
    return vars.Loading || current.GSync != 0;
}

onReset
{
	vars.CompletedSplits.Clear();
}
