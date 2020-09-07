#include <amxmodx>
#include <amxmisc>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>
#include <colorchat>
#include <cstrike>
#include <fun>
#include <lang>

#pragma semicolon 1

// enable plugin debug messages
#define DEBUG_CORE
#define DEBUG_EVENTS
#define DEBUG_GUNMENU
#define DEBUG_VIPMENU
#define DEBUG_WEAPONS

// plugin info
#define PLUGIN_NAME "C7 VIP System"
#define PLUGIN_VERSION "3.0"
#define PLUGIN_AUTHOR "CREE7EN."
#define PLUGIN_DICTIONARY "c7_vipsystem.txt"
#define PLUGIN_CONFIGS_DIR "c7_vipsystem"

//- GLOBAL CONSTANTS
#define MAX_SLOTS 32

//- GLOBALS
#include "../include/c7_vipsystem/globals.inc"

//- CVARS
#include "../include/c7_vipsystem/cvars.inc"

// plugin core
#include "../include/c7_vipsystem/tasks.inc"
#include "../include/c7_vipsystem/helpers.inc"

#include "../include/c7_vipsystem/events/_core.inc"
#include "../include/c7_vipsystem/gunmenu/_core.inc"
#include "../include/c7_vipsystem/hud/_core.inc"

public plugin_init() {
  register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

  // register translations file
  register_dictionary(PLUGIN_DICTIONARY);

  // set global plugin vars
  g_ServerSlots = get_maxplayers();
  g_ServerBuytime = get_pcvar_float(get_cvar_pointer("mp_buytime")) * 60.0;
  g_ServerFreezetime = get_pcvar_float(get_cvar_pointer("mp_freezetime"));
  g_ServerFriendlyFire = get_pcvar_num(get_cvar_pointer("mp_friendlyfire"));

  // setup hud messages
  g_HudDmgReceived = CreateHudSyncObj();
  g_HudDmgInflicted = CreateHudSyncObj();

  //- EVENTS
  // game events
  register_event("TextMsg", "event_game_start", "ac", "2&#Game_C", "2&#Game_w");

  // round events
  register_event("HLTV", "event_round_start_buytime", "ac", "1=0", "2=0");
  register_logevent("event_round_start", 2, "1=Round_Start");
  register_logevent("event_round_end", 2, "1=Round_End");

  // user events
  RegisterHam(Ham_Spawn, "player", "event_user_spawn", 1);
  RegisterHam(Ham_Killed, "player", "event_user_dies", 1);
  RegisterHam(Ham_TakeDamage, "player", "event_user_receives_damage", 1);
  register_event("ScreenFade", "event_user_flashed", "be", "4=255", "5=255", "6=255", "7>199");
  register_event("StatusIcon", "event_user_inside_buyzone", "be", "1=1", "2=buyzone");
  register_event("StatusIcon", "event_user_outside_buyzone", "be", "1=0", "2=buyzone");
}

public plugin_precache() {}
public plugin_end() {}

public client_putinserver(user_id) {}
public client_disconnect(user_id) {}
