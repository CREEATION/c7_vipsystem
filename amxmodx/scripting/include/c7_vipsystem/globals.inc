// default flags for new cvars
new FCVAR_DEFAULT = FCVAR_SPONLY | FCVAR_UNLOGGED;

// generic
new g_ServerSlots = MAX_SLOTS;

// round (c)vars
new Float:g_ServerBuytime;
new Float:g_ServerFreezetime;
new g_ServerFriendlyFire;
new g_CurrentRound = 0;
new Float:g_RoundTime = 0.0;

// hud
new g_HudDmgReceived;
new g_HudDmgInflicted;
