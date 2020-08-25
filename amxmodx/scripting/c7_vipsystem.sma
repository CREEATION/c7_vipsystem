#include <amxmodx>
#include <amxmisc>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>
#include <chatcolor>
#include <cstrike>
#include <fun>
#include <lang>

#pragma semicolon 1

#define DEBUG // uncomment this line to enable basic debugging messages

#define PLUGIN_NAME "C7 VIP System"
#define PLUGIN_VERSION "3.0"
#define PLUGIN_AUTHOR "CREE7EN."

// default english translations if no translation file is present
#define CHAT_PREFIX "d: ^4[C7 VIP Gunmenu]^3 "
#define HUD_PREFIX "d: none | "

#define CHAT_MSG_SETUP_RECIEVED "d: %sYou got ^1%s ^4+ ^1%s^3 and full equipment"
#define CHAT_MSG_SETUP_SPAWN "d: %sYou will spawn with ^1%s ^4+ ^1%s^3 and full equipment"
#define CHAT_MSG_SETUP_SAVED "d: %sSay ^4/guns ^3to select a new setup"

#define CHAT_MSG_GUNMENU_RESET "d: %sGunmenu will show again next round"
#define CHAT_MSG_GUNMENU_DISABLED "d: %sGunmenu disabled. Say ^4/guns ^3to enable it again"

#define HUD_MSG_BUYTIME_PASSED "d: %s%d seconds have passed.^rGunmenu will show again next round"
#define HUD_MSG_BUYTIME_LEFT "d: %sGunmenu will close in %d seconds^ror when leaving the buyzone"

#define CHAT_MSG_NEED_VIP "d: %sYou need to be VIP to see the gunmenu (^1say ^4/wantvip^3)"
#define CHAT_MSG_ROUND_NOT_REACHED "d: %sYou need to wait ^1%d %s ^3to see the gunmenu"

#define HUD_MSG_AWP_ALL "d: [ AWP is restricted for all players ]"
#define HUD_MSG_AWP_VIP "d: [ AWP is only available for VIPs ]"
#define HUD_MSG_AUTOSNIPER_ALL "d: [ Auto-Sniper is restricted for all players ]"
#define HUD_MSG_AUTOSNIPER_VIP "d: [ Auto-Sniper is only available for VIPs ]"

// tasks
#define TASK_FLASHED_ID 6700
#define TASK_DISABLE_ID 6764
#define TASK_HIDE_ID 6828

enum _:MAINMENU_OPTION {
  O_EMPTY,
  O_NEW_SETUP,
  O_PREV_SETUP,
  O_SAVE_SETUP,
  O_DISABLE,
  O_CLOSE,
};

// TODO: add to translation
new const g_MenuOptions[MAINMENU_OPTION][] = {
  "",
  "\ySelect Weapons",
  "Previous Setup%s",
  "Previous \d[\r+ Save\d]",
  "\rDisable Gunmenu",
  "Close"
};

// TODO: read from gunmenu config
new const g_WeaponConstants[][] = {
  // rifles
  "famas", "galil", "m4a1", "ak47", "aug", "sg552",
  // shotguns
  "m3", "xm1014",
  // smg
  "mac10", "tmp", "mp5navy", "ump45", "p90",
  // snipers
  "awp", "scout",
  // auto-snipers
  "g3sg1", "sg550",
  // mg
  "m249",
  // pistols
  "usp", "glock18", "deagle", "elite", "fiveseven", "p228"
};

// TODO: read from gunmenu config
new const g_WeaponAmmo[] = {
  // rifles
  90, 90, 90, 90, 90, 90,
  // shotguns
  32, 32,
  // smg
  100, 120, 120, 100, 100,
  // snipers
  30, 90,
  // auto-snipers
  90, 90,
  // mg
  200,
  // pistols
  100, 120, 35, 120, 100, 52,
  0, 52, 0, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90,
  100, 120, 30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, 0, 100
};

// TODO: read from gunmenu config
new const g_WeaponSlots[] = {
  // rifles
  1, 1, 1, 1, 1, 1,
  // shotguns
  1, 1,
  // smg
  1, 1, 1, 1, 1,
  // snipers
  1, 1,
  // auto-snipers
  1, 1,
  // mg
  1,
  // pistols
  2, 2, 2, 2, 2, 2
};

// max players
// TODO: read from server
// @see https://www.amxmodx.org/api/amxmodx/get_maxplayers
#define MAX_PLAYERS 32

// global vars
new g_CurrentRound;

new g_PlayerInBuyzone[MAX_PLAYERS+1],
    g_PlayerPrimaryWeapon[MAX_PLAYERS+1],
    g_PlayerSecondaryWeapon[MAX_PLAYERS+1],
    g_PlayerSavedSetup[MAX_PLAYERS+1],
    g_PlayerSpawnSetup[MAX_PLAYERS+1],
    g_PlayerDisableMenu[MAX_PLAYERS+1],
    bool:g_PlayerRecievedSetup[MAX_PLAYERS+1],
    bool:g_PlayerFlashed[MAX_PLAYERS+1];

new g_ConfigsDir[128],
    g_FilePointer;

new Array:g_WeaponSetups,
    Array:g_WeaponNames,
    Array:g_PrimaryWeapons,
    Array:g_SecondaryWeapons;

new g_Mainmenu,
    g_PrimaryMenu,
    g_SecondaryMenu;

new g_MsgMoney,
    g_VIPBonusMoney,
    g_MsgMoneyHook,
    g_HudDmgMade,
    g_HudDmgRecieved,
    g_HudHealthUp;

static
  Float:g_Buytime,
  Float:g_RoundStartTime,
  bool:g_InFreezetime;

// cvar pointers
new g_VIP_Flag[27];

new c7_vips_enable,
    c7_vips_gunmenu_enable,
    c7_vips_gunmenu_round,
    c7_vips_gunmenu_grens,
    c7_vips_flag,
    c7_vips_money_kill,
    c7_vips_money_hs,
    c7_vips_hp_kill,
    c7_vips_hp_hs,
    c7_vips_hp_max,
    c7_vips_awp,
    c7_vips_autosniper;

public plugin_init() {
  register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

  // register dictionary
  register_dictionary("c7_vipsystem.txt");

  // register cvars
  c7_vips_enable = register_cvar("c7_vips_enable", "1", FCVAR_SPONLY | FCVAR_UNLOGGED);
  c7_vips_flag = register_cvar("c7_vips_flag", "t", FCVAR_SPONLY | FCVAR_UNLOGGED);

  // money bonus
  c7_vips_money_kill = register_cvar("c7_vips_money_kill", "200", FCVAR_SPONLY | FCVAR_UNLOGGED);
  c7_vips_money_hs = register_cvar("c7_vips_money_hs", "400", FCVAR_SPONLY | FCVAR_UNLOGGED);

  // hp bonus
  c7_vips_hp_kill = register_cvar("c7_vips_hp_kill", "15", FCVAR_SPONLY | FCVAR_UNLOGGED);
  c7_vips_hp_hs = register_cvar("c7_vips_hp_hs", "30", FCVAR_SPONLY | FCVAR_UNLOGGED);
  c7_vips_hp_max = register_cvar("c7_vips_hp_max", "100", FCVAR_SPONLY | FCVAR_UNLOGGED);

  // sniper restriction
  c7_vips_awp = register_cvar("c7_vips_awp", "1", FCVAR_SPONLY | FCVAR_UNLOGGED);
  c7_vips_autosniper = register_cvar("c7_vips_autosniper", "0", FCVAR_SPONLY | FCVAR_UNLOGGED);

  // gunmenu cvars
  c7_vips_gunmenu_enable = register_cvar("c7_vips_gunmenu_enable", "1", FCVAR_SPONLY | FCVAR_UNLOGGED);
  c7_vips_gunmenu_round = register_cvar("c7_vips_gunmenu_round", "3", FCVAR_SPONLY | FCVAR_UNLOGGED);
  c7_vips_gunmenu_grens = register_cvar("c7_vips_gunmenu_grens", "1 2 1", FCVAR_SPONLY | FCVAR_UNLOGGED);

  // register say commands
  // TODO: read from config
  new t_CmdStr[32], a_RegisterCmds[][] = {
    "gun", "/gun", "!gun", ".gun",
    "guns", "/guns", "!guns", ".guns",
    "gunmenu", "/gunmenu", "!gunmenu", ".gunmenu",
    "rg", "/rg", "!rg", ".rg",
    "resetguns", "/resetguns", "!resetguns", ".resetguns"
  };

  for (new i; i < sizeof a_RegisterCmds; i++) {
    formatex(t_CmdStr, charsmax(t_CmdStr), "say %s", a_RegisterCmds[i]);
    register_clcmd(t_CmdStr, "user_reset_mainmenu");
    formatex(t_CmdStr, charsmax(t_CmdStr), "say_team %s", a_RegisterCmds[i]);
    register_clcmd(t_CmdStr, "user_reset_mainmenu");
  }

  // round events
  register_event("HLTV", "event_round_new", "ac", "1=0", "2=0");
  register_event("TeamScore", "event_team_score", "ac");
  register_event("TextMsg", "event_round_restart", "ac", "2&#Game_w", "2&#Game_C");
  register_logevent("event_round_start", 2, "0=World triggered", "1=Round_Start");
  register_logevent("event_round_end", 2, "0=World triggered", "1=Round_End");

  // player spawns
  RegisterHam(Ham_Spawn, "player", "event_player_spawn", 1);
  // player enters/leaves buyzone
  register_message(get_user_msgid("StatusIcon"), "event_player_buyzone");
  // player dies
  register_event("DeathMsg", "event_player_death", "a");
  // player damage
  register_event("Damage", "event_player_damage", "b", "2!0", "3=0", "4!0");
  // player flashed
  register_event("ScreenFade", "event_player_flashed", "be", "4=255", "5=255", "6=255", "7>199");
  // player current weapon
  register_event("CurWeapon", "event_current_weapon", "be");

  // msg ids
  g_MsgMoney = get_user_msgid("Money");

  // buy via menu
  // awp
  register_menucmd(register_menuid("CT_BuyRifle", 1), (1<<5), "handle_buy_menu");
  register_menucmd(register_menuid("T_BuyRifle", 1), (1<<4), "handle_buy_menu");
  // auto-snipers
  register_menucmd(register_menuid("CT_BuyRifle", 1), (1<<4), "handle_buy_menu");
  register_menucmd(register_menuid("T_BuyRifle", 1), (1<<5), "handle_buy_menu");

  // buy via console
  // awp
  register_clcmd("awp", "handle_buy_awp");
  register_clcmd("magnum", "handle_buy_awp");
  // auto-snipers
  register_clcmd("g3sg1", "handle_buy_autosniper");
  register_clcmd("d3au1", "handle_buy_autosniper");
  register_clcmd("sg550", "handle_buy_autosniper");
  register_clcmd("krieg550", "handle_buy_autosniper");

  // motd commands
  // TODO: read from config
  new a_RegisterMotdCmds[][] = {
    "wantvip", "/wantvip", "!wantvip", ".wantvip",
    "vip", "/vip", "!vip", ".vip",
    "buyvip", "/buyvip", "!buyvip", ".buyvip",
    "getvip", "/getvip", "!getvip", ".getvip"
  };

  for (new i; i < sizeof a_RegisterMotdCmds; i++) {
    formatex(t_CmdStr, charsmax(t_CmdStr), "say %s", a_RegisterMotdCmds[i]);
    register_clcmd(t_CmdStr, "user_show_wantvip");
    formatex(t_CmdStr, charsmax(t_CmdStr), "say_team %s", a_RegisterMotdCmds[i]);
    register_clcmd(t_CmdStr, "user_show_wantvip");
  }

  // set initial values
  get_pcvar_string(c7_vips_flag, g_VIP_Flag, charsmax(g_VIP_Flag));
  g_Buytime = get_pcvar_float(get_cvar_pointer("mp_buytime")) * 60.0;
  g_InFreezetime = false;

  arrayset(g_PlayerFlashed, false, MAX_PLAYERS);
  arrayset(g_PlayerInBuyzone, false, MAX_PLAYERS);
  arrayset(g_PlayerPrimaryWeapon, -1, MAX_PLAYERS);
  arrayset(g_PlayerSecondaryWeapon, -1, MAX_PLAYERS);
  arrayset(g_PlayerSavedSetup, false, MAX_PLAYERS);
  arrayset(g_PlayerSpawnSetup, false, MAX_PLAYERS);
  arrayset(g_PlayerDisableMenu, false, MAX_PLAYERS);
  arrayset(g_PlayerRecievedSetup, false, MAX_PLAYERS);

  // TODO: read actual number of setups and weapons from file
  g_WeaponSetups = ArrayCreate(18, 4);
  g_PrimaryWeapons = ArrayCreate(8, 18);
  g_SecondaryWeapons = ArrayCreate(10, 6);
  g_WeaponNames = ArrayCreate(32, 24);

  // fill gunmenus with data
  populate_menus();
}

public plugin_precache() {
  // TODO: load all configs
  get_configsdir(g_ConfigsDir, charsmax(g_ConfigsDir));
  server_cmd("exec %s/c7_vipsystem/plugin.cfg", g_ConfigsDir);

  g_HudDmgMade = CreateHudSyncObj();
  g_HudDmgRecieved = CreateHudSyncObj();
  g_HudHealthUp = CreateHudSyncObj();
}

public plugin_end() {
  ArrayDestroy(g_WeaponNames);
  ArrayDestroy(g_WeaponSetups);
  ArrayDestroy(g_PrimaryWeapons);
  ArrayDestroy(g_SecondaryWeapons);
}

/*
 * Reset vars on connect/disconnect
 */
public client_disconnect(p_userid) {
  g_PlayerFlashed[p_userid] = false;
  g_PlayerInBuyzone[p_userid] = false;
  g_PlayerSavedSetup[p_userid] = false;
  g_PlayerSpawnSetup[p_userid] = false;
  g_PlayerDisableMenu[p_userid] = false;
}

/*
 * Player Events
 */
public event_player_spawn(p_userid) {
  // check if we actually have a valid player to work with
  if (!is_user_connected(p_userid) || !get_pcvar_num(c7_vips_gunmenu_enable) || !is_user_vip(p_userid)) {
    return HAM_HANDLED;
  }

  // check if minimum amount of rounds is reached to display gunmenu
  if (!is_gunmenu_enabled()) {
    print_gunmenu_roundsleft(p_userid);

    // abort until number of rounds is reached
    return HAM_HANDLED;
  }

#if defined DEBUG
  client_print(p_userid,print_chat,"event_player_spawn [%d]",p_userid);
#endif

  g_PlayerFlashed[p_userid] = false;
  g_PlayerRecievedSetup[p_userid] = false;

  // give previous setup if saved
  // TODO: refactor
  if (g_PlayerSavedSetup[p_userid]) {
    user_give_setup(p_userid, g_PlayerPrimaryWeapon[p_userid], g_PlayerSecondaryWeapon[p_userid], true);

    return HAM_HANDLED;
  } else if (g_PlayerSpawnSetup[p_userid]) {
    g_PlayerSpawnSetup[p_userid] = false;

    user_give_setup(p_userid, g_PlayerPrimaryWeapon[p_userid], g_PlayerSecondaryWeapon[p_userid]);

    // reset to disable countdown of menu
    // will set itself to false again when player dies
    g_PlayerSpawnSetup[p_userid] = true;

    return HAM_HANDLED;
  } else if (g_PlayerDisableMenu[p_userid]) {
    user_give_setup(p_userid, -1, -1, true);

    return HAM_HANDLED;
  } else {
    user_show_mainmenu(p_userid);
  }

  if (!round_is_buytime_over() && !g_InFreezetime && !g_PlayerRecievedSetup[p_userid]) {
    // show countdown for menu
    user_start_buytime_countdown(p_userid);

    if (task_exists(p_userid + TASK_HIDE_ID)) {
      remove_task(p_userid + TASK_HIDE_ID);
    }

    set_task(round_get_buytime_left(), "hide_menu", p_userid + TASK_HIDE_ID);
  } else if (round_is_buytime_over()) {
    client_print(p_userid, print_center, HUD_MSG_BUYTIME_PASSED, HUD_PREFIX, floatround(g_Buytime, floatround_floor));
  }

  return HAM_HANDLED;
}

// TODO: refactor into several functions
public event_player_death() {
  if (!get_pcvar_num(c7_vips_enable)) {
    return PLUGIN_CONTINUE;
  }

  new i_Victim = read_data(2);

  // no valid victim, abort
  if (!is_user_connected(i_Victim) || (i_Victim < 1 || i_Victim > MAX_PLAYERS)) {
    return PLUGIN_HANDLED;
  }

  // color victim screen when killed (ignore flashed state)
  // user_screen_fade(i_Victim, 0, 237, 41, 7, 100)
  user_screen_fade(i_Victim, 0, 0, 0, 0, 0); // just remove flashed screen

  // remove "flashed" task
  if (task_exists(i_Victim + TASK_FLASHED_ID)) {
    remove_task(i_Victim + TASK_FLASHED_ID);
  }

#if defined DEBUG
  client_print(i_Victim,print_chat,"event_player_death [%d]",i_Victim);
#endif

  g_PlayerInBuyzone[i_Victim] = false;
  g_PlayerSpawnSetup[i_Victim] = false;

  // stop countdown when dead
  if (is_user_vip(i_Victim) && task_exists(i_Victim)) {
    remove_task(i_Victim);
  }

  // handle attacker bonus if vip
  new i_Attacker = read_data(1);

  // no valid attacker
  if (!is_user_connected(i_Attacker) || (i_Attacker < 1 || i_Attacker > MAX_PLAYERS)) {
    return PLUGIN_HANDLED;
  }

  // skip suicide & non-vips
  if (!is_user_vip(i_Attacker) || i_Attacker == i_Victim) {
    return PLUGIN_CONTINUE;
  }

  new i_Headshot = read_data(3),
      // i_MoneyFlashUp = 1,
      CsArmorType:t_ArmorTypeVIP, s_ArmorType[17];

  static n_BonusMoney,
    n_HealthBonus,
    n_HealthMax,
    n_HealthVIP,
    n_ArmorVIP,
    n_ArmorBonus;

  // headshot bonus?
  // TODO: refactor
  if (i_Headshot == 1) {
    n_HealthBonus = get_pcvar_num(c7_vips_hp_hs);
    n_BonusMoney = get_pcvar_num(c7_vips_money_hs);
  } else {
    n_HealthBonus = get_pcvar_num(c7_vips_hp_kill);
    n_BonusMoney = get_pcvar_num(c7_vips_money_kill);
  }

#if defined DEBUG
  client_print(i_Attacker,print_center,"bonus money: %d", n_BonusMoney);
#endif

  // add money bonus
  // TODO: read maximum amount of money (16k) from server?
  g_VIPBonusMoney = clamp(cs_get_user_money(i_Attacker) + n_BonusMoney, 0, 16000);
  g_MsgMoneyHook = register_message(g_MsgMoney, "msg_user_money");

  // add health bonus
  n_HealthMax = get_pcvar_num(c7_vips_hp_max);
  n_HealthVIP = get_user_health(i_Attacker);

  // show added hp, if not already full HP
  if (n_HealthVIP != n_HealthMax) {
    set_hudmessage(0, 255, 0, -1.0, 0.15, 0, 3.0, 1.0, 0.5, 1.0, -1);

    // show "headshot" alongside added health
    // TODO: add to translation file
    switch (i_Headshot) {
      case 0: ShowSyncHudMsg(i_Attacker, g_HudHealthUp, "+%i HP^nfor KILL!", n_HealthBonus);
      case 1: ShowSyncHudMsg(i_Attacker, g_HudHealthUp, "+%i HP^nfor HEADSHOT!", n_HealthBonus);
    }
  }

  n_HealthVIP += n_HealthBonus;

  // don't go over max hp
  if (n_HealthVIP > n_HealthMax) {
    n_HealthVIP = n_HealthMax;
  }

  // get user armor
  n_ArmorVIP = cs_get_user_armor(i_Attacker, t_ArmorTypeVIP);

  // if max hp reached, give half of bonus hp as armor
  if (n_HealthVIP >= n_HealthMax) {
    if (t_ArmorTypeVIP == CsArmorType:CS_ARMOR_NONE) {
      // if no armor type, set to kevlar
      t_ArmorTypeVIP = CsArmorType:CS_ARMOR_KEVLAR;
    } else if (t_ArmorTypeVIP == CS_ARMOR_KEVLAR && n_ArmorVIP == 100) {
      // if already kevlar & max armor reached, set to vesthelm
      t_ArmorTypeVIP = CsArmorType:CS_ARMOR_VESTHELM;
    }

    if (i_Headshot == 1) {
      n_ArmorBonus = get_pcvar_num(c7_vips_hp_hs) / 2;
    } else {
      n_ArmorBonus = get_pcvar_num(c7_vips_hp_kill) / 2;
    }

    // no bonus, max armor reached :(
    if (n_ArmorVIP >= 100 && t_ArmorTypeVIP == CsArmorType:CS_ARMOR_VESTHELM) {
      n_ArmorBonus = 0;
    }

    // TODO: add to translation file
    switch (CsArmorType:t_ArmorTypeVIP) {
      case CS_ARMOR_KEVLAR: copy(s_ArmorType, charsmax(s_ArmorType), " (Vest)");
      case CS_ARMOR_VESTHELM: copy(s_ArmorType, charsmax(s_ArmorType), " (Vest & Helmet)");
    }

    // show added armor, if not already 100 AP
    if (n_ArmorVIP != 100 && n_ArmorBonus != 0) {
      set_hudmessage(12, 160, 250, -1.0, 0.15, 0, 3.0, 1.0, 0.5, 1.0, -1);

      // show "headshot" alongside added armor
      // TODO: add to translation file
      switch (i_Headshot) {
        case 0: ShowSyncHudMsg(i_Attacker, g_HudHealthUp, "+%i AP%s^nfor KILL!", n_ArmorBonus, s_ArmorType);
        case 1: ShowSyncHudMsg(i_Attacker, g_HudHealthUp, "+%i AP%s^nfor HEADSHOT!", n_ArmorBonus, s_ArmorType);
      }
    }

    n_ArmorVIP += n_ArmorBonus;

    // max armor reached, no bonus
    if (n_ArmorVIP > 100) {
      n_ArmorVIP = 100;
    }
  }

  // set bonus hp
  set_user_health(i_Attacker, n_HealthVIP);

  // set bonus ap
  cs_set_user_armor(i_Attacker, n_ArmorVIP, t_ArmorTypeVIP);

  // color killer screen when killing someone
  user_screen_fade(i_Attacker, 1, 100, 233, 12, 60);

  return PLUGIN_CONTINUE;
}

// @see https://forums.alliedmods.net/showthread.php?t=104887
public msg_user_money(_msgid, _msgdest, p_userid) {
  unregister_message(g_MsgMoney, g_MsgMoneyHook);
  set_pdata_int(p_userid, 115, g_VIPBonusMoney, 5);
  set_msg_arg_int(1, ARG_LONG, g_VIPBonusMoney);
}

public event_player_damage(p_victim) {
  if (!is_user_connected(p_victim) || !get_pcvar_num(c7_vips_enable)) {
    return PLUGIN_CONTINUE;
  }

  new n_Damage,
      i_Attacker;

  n_Damage = read_data(2);
  i_Attacker = get_user_attacker(p_victim);

#if defined DEBUG
  client_print(p_victim, print_chat, "event_player_damage [%d]->[%d]", i_Attacker, p_victim);
#endif

  // show damage to victim
  user_show_damage_recieved(p_victim, n_Damage, g_HudDmgRecieved);

  // show damage to vips if not self-inflicted damage & victim is alive
  if (p_victim != i_Attacker && i_Attacker <= MAX_PLAYERS && is_user_vip(i_Attacker)) {
    user_show_damage_made(i_Attacker, n_Damage, g_HudDmgMade);
  }

  // show to spectators
  new a_Players[MAX_PLAYERS],
      n_Players;
  
  // @see https://www.amxmodx.org/api/amxmodx/get_players
  get_players(a_Players, n_Players, "bch");

  // TODO: refactor
  for (new i; i < n_Players; i++) {
    if (!is_user_connected(a_Players[i]) || (!is_spectating(a_Players[i], i_Attacker) && !is_spectating(a_Players[i], p_victim))) {
      continue;
    }

    if (is_spectating(a_Players[i], p_victim)) {
      user_show_damage_recieved(a_Players[i], n_Damage, g_HudDmgRecieved);
    }

    // show damage made of not self-inflicted damage
    if (p_victim != i_Attacker && i_Attacker <= MAX_PLAYERS && is_spectating(a_Players[i], i_Attacker)) {
      user_show_damage_made(a_Players[i], n_Damage, g_HudDmgMade);
    }
  }

  return PLUGIN_CONTINUE;
}

/*
 * Player is flashed
 */
public event_player_flashed(p_userid) {
  if (!is_user_connected(p_userid) || !get_pcvar_num(c7_vips_enable)) {
    return PLUGIN_CONTINUE;
  }

  if (task_exists(p_userid + TASK_FLASHED_ID)) {
    remove_task(p_userid + TASK_FLASHED_ID);
  }

  static Float:f_FlashDuration;
  f_FlashDuration = (read_data(1) + read_data(2)) / 5000.0;

#if defined DEBUG
  client_print(p_userid, print_chat, "player flashed [%d](%.2f)", p_userid, f_FlashDuration);
#endif

  g_PlayerFlashed[p_userid] = true;

  set_task(f_FlashDuration, "task_player_reset_flashed", p_userid + TASK_FLASHED_ID);

  return PLUGIN_CONTINUE;
}

public task_player_reset_flashed(p_taskid) {
  new i_User = p_taskid - TASK_FLASHED_ID;

#if defined DEBUG
  client_print(i_User, print_chat, "player not flashed [%d]", i_User);
#endif

  g_PlayerFlashed[i_User] = false;

  return PLUGIN_CONTINUE;
}

/*
 * Player touches Buyzone
 */
public event_player_buyzone(_msgid, _dest, p_userid) {
  if (!is_user_connected(p_userid) || !is_user_alive(p_userid) || !get_pcvar_num(c7_vips_gunmenu_enable)) {
    return PLUGIN_CONTINUE;
  }

  static s_Msg[8];
  get_msg_arg_string(2, s_Msg, 7);

  if (!is_user_vip(p_userid) || is_user_bot(p_userid) || !is_gunmenu_enabled() || !equal(s_Msg, "buyzone")) {
    return PLUGIN_CONTINUE;
  }

  g_PlayerInBuyzone[p_userid] = bool:get_msg_arg_int(1);

  if (!g_PlayerInBuyzone[p_userid] && !g_InFreezetime) {
#if defined DEBUG
  client_print(p_userid, print_chat, "player left buyzone [%d]", p_userid);
#endif

    // stop countdown
    user_stop_buytime_countdown(p_userid);
    hide_menu(p_userid + TASK_HIDE_ID);
  }

  return PLUGIN_CONTINUE;
}

/*
 * Round restart
 */
public event_round_restart() {
  if (!get_pcvar_num(c7_vips_gunmenu_enable)) {
    return PLUGIN_CONTINUE;
  }

  g_CurrentRound = 0;

  new a_Players[MAX_PLAYERS],
      n_Players;

  get_players(a_Players, n_Players, "ach");

  for (new i; i < n_Players; i++) {
    if (!is_user_vip(a_Players[i])) {
      continue;
    }

#if defined DEBUG
  client_print(a_Players[i], print_chat, "reset user [%d]", a_Players[i]);
#endif

    hide_menu(a_Players[i] + TASK_HIDE_ID);
  }

  return PLUGIN_CONTINUE;
}

public event_team_score() {
  if (!is_gunmenu_enabled()) {
    g_CurrentRound += 1;

#if defined DEBUG
  client_print(0, print_chat, "current round: [%d]", g_CurrentRound);
#endif
  }

  return PLUGIN_CONTINUE;
}

/*
 * New Round in Freezetime
 */
public event_round_new() {
  if (!get_pcvar_num(c7_vips_gunmenu_enable)) {
    return PLUGIN_CONTINUE;
  }

#if defined DEBUG
  client_print(0, print_chat, "event_round_new");
#endif

  // set buytime
  g_Buytime = get_pcvar_float(get_cvar_pointer("mp_buytime")) * 60.0;

  // set freezetime started
  g_InFreezetime = true;

  // read cvars again
  // TODO: refactor this madness
  set_pcvar_num(c7_vips_enable, get_pcvar_num(c7_vips_enable));
  get_pcvar_string(c7_vips_flag, g_VIP_Flag, charsmax(g_VIP_Flag));
  set_pcvar_string(c7_vips_flag, g_VIP_Flag);
  set_pcvar_num(c7_vips_money_kill, get_pcvar_num(c7_vips_money_kill));
  set_pcvar_num(c7_vips_money_hs, get_pcvar_num(c7_vips_money_hs));
  set_pcvar_num(c7_vips_hp_kill, get_pcvar_num(c7_vips_hp_kill));
  set_pcvar_num(c7_vips_hp_hs, get_pcvar_num(c7_vips_hp_hs));
  set_pcvar_num(c7_vips_hp_max, get_pcvar_num(c7_vips_hp_max));
  set_pcvar_num(c7_vips_awp, get_pcvar_num(c7_vips_awp));
  set_pcvar_num(c7_vips_autosniper, get_pcvar_num(c7_vips_autosniper));
  // gunmenu
  set_pcvar_num(c7_vips_gunmenu_enable, get_pcvar_num(c7_vips_gunmenu_enable));
  set_pcvar_num(c7_vips_gunmenu_round, get_pcvar_num(c7_vips_gunmenu_round));

  return PLUGIN_CONTINUE;
}

public event_round_start() {
  if (!get_pcvar_num(c7_vips_gunmenu_enable) || !is_gunmenu_enabled()) {
    return PLUGIN_CONTINUE;
  }

  g_RoundStartTime = get_gametime();
  g_InFreezetime = false;

  new a_Players[MAX_PLAYERS],
      n_Players;

  get_players(a_Players, n_Players, "ach");

  for (new i; i < n_Players; i++) {
    // show a message to all non-vips that the gunmenu is disabled for them
    // TODO: add config option to toggle this message
    if (!is_user_vip(a_Players[i])) {
      client_print_color(a_Players[i], Grey, CHAT_MSG_NEED_VIP, CHAT_PREFIX);
      continue;
    }

    if (
      g_PlayerSavedSetup[a_Players[i]] ||
      g_PlayerSpawnSetup[a_Players[i]] ||
      g_PlayerRecievedSetup[a_Players[i]] ||
      g_PlayerDisableMenu[a_Players[i]]
    ) {
      continue;
    }

#if defined DEBUG
  client_print(a_Players[i], print_chat, "(start) user: [%d]", a_Players[i]);
#endif

    if (
      !g_PlayerSavedSetup[a_Players[i]] &&
      !g_PlayerSpawnSetup[a_Players[i]] &&
      !g_PlayerDisableMenu[a_Players[i]]
    ) {
      // count down time left for buymenu
      user_start_buytime_countdown(a_Players[i]);

      // set menu timeout task
      if (task_exists(a_Players[i] + TASK_HIDE_ID)) {
        remove_task(a_Players[i] + TASK_HIDE_ID);
      }

      set_task(g_Buytime, "hide_menu", a_Players[i] + TASK_HIDE_ID);
    }
  }

  return PLUGIN_CONTINUE;
}

public event_round_end() {
  if (!get_pcvar_num(c7_vips_gunmenu_enable) || !is_gunmenu_enabled()) {
    return PLUGIN_CONTINUE;
  }

  new a_Players[MAX_PLAYERS],
      n_Players;

  get_players(a_Players, n_Players, "ach");

  for (new i; i < n_Players; i++) {
    if (
      !is_user_vip(a_Players[i]) ||
      g_PlayerSavedSetup[a_Players[i]] ||
      !is_user_alive(a_Players[i])
    ) {
      continue;
    }

#if defined DEBUG
  client_print(a_Players[i], print_chat, "(end) user: [%d]", a_Players[i]);
#endif

    if (is_user_alive(a_Players[i])) {
      g_PlayerSpawnSetup[a_Players[i]] = false;
    }
  }

  return PLUGIN_CONTINUE;
}

/*
 * Gunmenu handlers
 */
populate_menus() {
  if (!get_pcvar_num(c7_vips_gunmenu_enable)) {
    return PLUGIN_CONTINUE;
  }

  // TODO: redo gunmenu config
  get_configsdir(g_ConfigsDir, charsmax(g_ConfigsDir));
  format(g_ConfigsDir, charsmax(g_ConfigsDir), "%s/c7_vipsystem/gunmenu.ini", g_ConfigsDir);

  g_FilePointer = fopen(g_ConfigsDir, "r");

  if (!g_FilePointer) {
    set_fail_state("[C7 VIP] Gunmenu Configuration File not found");
    return PLUGIN_HANDLED;
  }

  new s_Line[64],
      s_WeaponName[32],
      n_SetupCount;

  // create menus with fallback titles
  g_Mainmenu = menu_create("GUNMENU_TITLE", "handle_mainmenu");
  g_PrimaryMenu = menu_create("GUNMENU_PRIMARY_WEAPON_TITLE", "handle_primary_menu");
  g_SecondaryMenu = menu_create("GUNMENU_SECONDARY_WEAPON_TITLE", "handle_secondary_menu");

  // populate
  while (!feof(g_FilePointer)) {
    fgets(g_FilePointer, s_Line, charsmax(s_Line));
    trim(s_Line);

    // skip empty lines & comments
    if (!s_Line[0] || containi(s_Line, ";") != -1) {
      continue;
    }

    // populate predefined setups
    if (containi(s_Line, "+") == 0) {
      new s_SetupMenuKey[3],
        s_SetupName[32],
        s_SetupConstants[32],
        s_LineR[32],
        s_WeaponSetupString[64];

      strtok(s_Line, s_SetupConstants, charsmax(s_SetupConstants), s_LineR, charsmax(s_LineR), ':');
      trim(s_SetupConstants);
      replace(s_SetupConstants, charsmax(s_SetupConstants), "+", "");

      trim(s_LineR); parse(s_LineR, s_WeaponName, charsmax(s_WeaponName));
      formatex(s_WeaponSetupString, charsmax(s_WeaponSetupString), "%s:%s", s_SetupConstants, s_WeaponName);

      strtok(s_WeaponSetupString, s_SetupConstants, charsmax(s_SetupConstants), s_SetupName, charsmax(s_SetupName), ':');
      trim(s_SetupName);
      remove_quotes(s_SetupName);
      format(s_SetupMenuKey, charsmax(s_SetupMenuKey), "s%d", n_SetupCount);

      ArrayPushString(g_WeaponSetups, s_SetupConstants);
      menu_additem(g_Mainmenu, s_SetupName, s_SetupMenuKey);

      n_SetupCount++;

      continue;
    }

    new s_WeaponConst[32],
        s_LineR[32];

    strtok(s_Line, s_WeaponConst, charsmax(s_WeaponConst), s_LineR, charsmax(s_LineR), ':');

    for (new i; i < sizeof g_WeaponConstants; i++) {
      // get weapon label
      trim(s_LineR); parse(s_LineR, s_WeaponName, charsmax(s_WeaponName));

      // populate weapon labels array
      if (equal(g_WeaponConstants[i], s_WeaponConst)) {
        ArrayPushString(g_WeaponNames, s_WeaponName);
      }

      if (equal(g_WeaponConstants[i], s_WeaponConst) && g_WeaponSlots[i] == 1) {
        // populate primary weapons array
        ArrayPushString(g_PrimaryWeapons, s_WeaponConst);
        menu_additem(g_PrimaryMenu, s_WeaponName, s_WeaponConst);
      } else if (equal(g_WeaponConstants[i], s_WeaponConst) && g_WeaponSlots[i] == 2) {
        // populate secondary weapons array
        ArrayPushString(g_SecondaryWeapons, s_WeaponConst);
        menu_additem(g_SecondaryMenu, s_WeaponName, s_WeaponConst);
      }
    }
  }

  // finish reading data
  fclose(g_FilePointer);

  // populate main menu with static options now
  populate_mainmenu();

  return PLUGIN_CONTINUE;
}

populate_mainmenu() {
  if (!get_pcvar_num(c7_vips_gunmenu_enable)) {
    return PLUGIN_HANDLED;
  }

  // add a blank item (if any setups are present)
  if (menu_items(g_Mainmenu) > 0) {
    menu_addblank(g_Mainmenu, 0);
  }

  // add main menu
  new s_MenuItemKey[3];

  for (new i = 1; i < sizeof g_MenuOptions; i++) {
    formatex(s_MenuItemKey, charsmax(s_MenuItemKey), "m%d", i);

    if (i >= 5) {
      menu_addblank(g_Mainmenu);
    }

    menu_additem(g_Mainmenu, g_MenuOptions[i], s_MenuItemKey);
  }

  // disable pagination & default close button
  menu_setprop(g_Mainmenu, MPROP_PERPAGE, 0);
  menu_setprop(g_Mainmenu, MPROP_EXIT, -1);

  return PLUGIN_HANDLED;
}

/*
 * Handle Gunmenu Selection
 */
public handle_mainmenu(p_userid, p_menu, p_menuitem) {
  if (
    !is_user_connected(p_userid) ||
    !is_user_vip(p_userid) ||
    !get_pcvar_num(c7_vips_gunmenu_enable)
  ) {
    return PLUGIN_HANDLED;
  }

  // allocate menu space
  new s_MenuItemKey[7], t_Empty;
  menu_item_getinfo(p_menu, p_menuitem, t_Empty, s_MenuItemKey, 6, "", 0, t_Empty);

#if defined DEBUG
  client_print(p_userid, print_chat, "handle_mainmenu [%d](%s)(%d)", p_userid, s_MenuItemKey, p_menuitem);
#endif

  // exit menu
  if (p_menuitem == MENU_EXIT) {
    // stop countdown
    user_stop_buytime_countdown(p_userid);

    if (!g_PlayerSpawnSetup[p_userid]) {
      g_PlayerSavedSetup[p_userid] = false;
      g_PlayerRecievedSetup[p_userid] = true;

      hide_menu(p_userid + TASK_HIDE_ID);

      return PLUGIN_HANDLED;
    }

    g_PlayerSpawnSetup[p_userid] = false;

    return PLUGIN_CONTINUE;
  }

  // predefined setups menu
  if (containi(s_MenuItemKey[0], "s") != -1) {
    replace(s_MenuItemKey, charsmax(s_MenuItemKey), "s", "");

#if defined DEBUG
  client_print(p_userid, print_chat, "selected: [%d]", str_to_num(s_MenuItemKey));
#endif

    handle_menu_setup(p_userid, str_to_num(s_MenuItemKey));

    return PLUGIN_HANDLED;
  }

  // main menu
  replace(s_MenuItemKey, charsmax(s_MenuItemKey), "m", "");

#if defined DEBUG
  client_print(p_userid, print_chat, "selected: [%d]", str_to_num(s_MenuItemKey));
#endif

  switch (str_to_num(s_MenuItemKey)) {
    case O_NEW_SETUP:
      handle_menu_setup_new(p_userid);

    case O_PREV_SETUP:
      handle_menu_setup_prev(p_userid);

    case O_SAVE_SETUP:
      handle_menu_setup_prev(p_userid, true);

    case O_DISABLE:
      handle_menu_disable(p_userid);

    case O_CLOSE:
      hide_menu(p_userid);
  }

  return PLUGIN_HANDLED;
}

/*
 * Hide Gunmenu
 */
public hide_menu(p_userid) {
  p_userid -= TASK_HIDE_ID;

  if (
    !is_user_connected(p_userid) ||
    !is_user_vip(p_userid) ||
    !get_pcvar_num(c7_vips_gunmenu_enable)
  ) {
    return PLUGIN_HANDLED;
  }

  new m_Old, m_New;
  player_menu_info(p_userid, m_Old, m_New);

  // hide gunmenu only
  if (m_New != -1) {
#if defined DEBUG
  client_print(p_userid, print_chat, "hiding menu [%d]", p_userid);
#endif

    if (task_exists(p_userid)) {
      remove_task(p_userid);
    }

    // stop countdown
    user_stop_buytime_countdown(p_userid);

    show_menu(p_userid, 0, "^n", 1);
  }

  return PLUGIN_CONTINUE;
}

/*
 * Handle New Setup
 */
handle_menu_setup_new(p_userid) {
  if (
    !is_user_connected(p_userid) ||
    !is_user_vip(p_userid) ||
    !get_pcvar_num(c7_vips_gunmenu_enable)
  ) {
    return PLUGIN_HANDLED;
  }

#if defined DEBUG
  client_print(p_userid, print_chat, "handle_menu_setup_new [%d]", p_userid);
#endif

  // rename exit
  // TODO: add to translations
  menu_setprop(g_PrimaryMenu, MPROP_EXITNAME, "\d[\rBack to \yMainmenu\d]");

  menu_display(p_userid, g_PrimaryMenu, 0);

  return PLUGIN_CONTINUE;
}

/*
 * Handle Primary Gun Selection
 */
public handle_primary_menu(p_userid, p_menu, p_menuitem) {
  if (
    !is_user_connected(p_userid) ||
    !is_user_vip(p_userid) ||
    !get_pcvar_num(c7_vips_gunmenu_enable)
  ) {
    return PLUGIN_HANDLED;
  }

  // allocate menu space
  new s_MenuItemKey[9],
      t_Empty;

  menu_item_getinfo(p_menu, p_menuitem, t_Empty, s_MenuItemKey, charsmax(s_MenuItemKey), "", 0, t_Empty);

#if defined DEBUG
  client_print(p_userid, print_chat, "handle_primary_menu [%d](%s)", p_userid, s_MenuItemKey);
#endif

  // back to mainmenu
  if (p_menuitem == MENU_EXIT) {
    menu_display(p_userid, g_Mainmenu, 0);

    return PLUGIN_HANDLED;
  }

  g_PlayerPrimaryWeapon[p_userid] = p_menuitem;

  // rename exit
  // TODO: add to translations
  menu_setprop(g_SecondaryMenu, MPROP_EXITNAME, "\d[\rBack to \yPrimary Weapons\d]");

  menu_display(p_userid, g_SecondaryMenu, 0);

  return PLUGIN_CONTINUE;
}

/*
 * Handle Secondary Gun Selection
 */
public handle_secondary_menu(p_userid, p_menu, p_menuitem) {
  if (
    !is_user_connected(p_userid) ||
    !is_user_vip(p_userid) ||
    !get_pcvar_num(c7_vips_gunmenu_enable)
  ) {
    return PLUGIN_HANDLED;
  }

  // allocate menu space
  new s_MenuItemKey[11],
      t_Empty;

  menu_item_getinfo(p_menu, p_menuitem, t_Empty, s_MenuItemKey, charsmax(s_MenuItemKey), "", 0, t_Empty);

#if defined DEBUG
  client_print(p_userid, print_chat, "handle_secondary_menu [%d](%s)", p_userid, s_MenuItemKey);
#endif

  // back to primary weapons menu
  if (p_menuitem == MENU_EXIT) {
    menu_display(p_userid, g_PrimaryMenu, 0);

    return PLUGIN_HANDLED;
  }

  g_PlayerSecondaryWeapon[p_userid] = p_menuitem;

  // give weapons to player
  user_give_setup(p_userid, g_PlayerPrimaryWeapon[p_userid], g_PlayerSecondaryWeapon[p_userid]);

  return PLUGIN_CONTINUE;
}

/*
 * Handle Weapon Restriction
 */
public handle_buy_menu(p_userid, p_key) {
  if (!is_user_connected(p_userid) || !get_pcvar_num(c7_vips_enable)) {
    return PLUGIN_HANDLED;
  }

  new u_Team = get_user_team(p_userid);

  if ((u_Team == 1 && p_key == 4) || (u_Team == 2 && p_key == 5)) {
    handle_menu_weapon(p_userid, c7_vips_awp);
  }

  if ((u_Team == 1 && p_key == 5) || (u_Team == 2 && p_key == 4)) {
    handle_menu_weapon(p_userid, c7_vips_autosniper);
  }

  return PLUGIN_CONTINUE;
}

public handle_menu_weapon(p_userid, p_pcvar) {
  if (!is_user_connected(p_userid) || !get_pcvar_num(c7_vips_enable)) {
    return PLUGIN_HANDLED;
  }

  if (get_pcvar_num(p_pcvar) == 0) {
    client_print(p_userid, print_center, HUD_MSG_AWP_ALL);
    engclient_cmd(p_userid, "menuselect", "10");

    return PLUGIN_HANDLED;
  }

  if (get_pcvar_num(p_pcvar) == 1 && !is_user_vip(p_userid))
  {
    client_print(p_userid, print_center, HUD_MSG_AWP_VIP);
    engclient_cmd(p_userid, "menuselect", "10");

    return PLUGIN_HANDLED;
  }

  return PLUGIN_CONTINUE;
}

// TODO: refactor
stock handle_buy_weapon(p_userid, p_pcvar) {
  if (!is_user_connected(p_userid) || !get_pcvar_num(c7_vips_enable)) {
    return PLUGIN_HANDLED;
  }

  if (get_pcvar_num(p_pcvar) == 0) {
    client_print(p_userid, print_center, HUD_MSG_AWP_ALL)

    return PLUGIN_HANDLED;
  }

  if (get_pcvar_num(p_pcvar) == 1 && !is_user_vip(p_userid)) {
    client_print(p_userid, print_center, HUD_MSG_AWP_VIP)

    return PLUGIN_HANDLED;
  }

  return PLUGIN_CONTINUE;
}

public handle_buy_awp(p_userid) {
  handle_buy_weapon(p_userid, c7_vips_awp);
}

public handle_buy_autosniper(p_userid) {
  handle_buy_weapon(p_userid, c7_vips_autosniper);
}

stock handle_current_weapon(p_userid, p_pcvar, const p_weapon[], const p_msg_all[], const p_msg_vip[]) {
  if (user_drop_weapon(p_userid, p_pcvar, p_weapon) == 0) {
    client_print(p_userid, print_center, p_msg_all);
  }

  if (user_drop_weapon(p_userid, p_pcvar, p_weapon) == 1 && !is_user_vip(p_userid)) {
    client_print(p_userid, print_center, p_msg_vip);
  }
}

// TODO: refactor
public event_current_weapon(p_userid) {
  if (!is_user_connected(p_userid) || !get_pcvar_num(c7_vips_enable)) {
    return PLUGIN_HANDLED;
  }

  if (get_pcvar_num(c7_vips_awp) == 2 || get_pcvar_num(c7_vips_autosniper) == 2) {
    return PLUGIN_HANDLED;
  }

  switch (get_user_weapon(p_userid, _, _)) {
    case CSW_AWP: handle_current_weapon(p_userid, c7_vips_awp, "weapon_awp", HUD_MSG_AWP_ALL, HUD_MSG_AWP_VIP);
    case CSW_SG550: handle_current_weapon(p_userid, c7_vips_autosniper, "weapon_sg550", HUD_MSG_AUTOSNIPER_ALL, HUD_MSG_AUTOSNIPER_VIP);
    case CSW_G3SG1: handle_current_weapon(p_userid, c7_vips_autosniper, "weapon_g3sg1", HUD_MSG_AUTOSNIPER_ALL, HUD_MSG_AUTOSNIPER_VIP);
  }

  return PLUGIN_CONTINUE;
}

public user_reset_mainmenu(p_userid) {
  if (!is_user_connected(p_userid) || !get_pcvar_num(c7_vips_gunmenu_enable)) {
    return PLUGIN_HANDLED;
  }

  if (!is_user_vip(p_userid)) {
    client_print_color(p_userid, Grey, CHAT_MSG_NEED_VIP, CHAT_PREFIX);

    return PLUGIN_HANDLED;
  }

  if (!is_gunmenu_enabled()) {
    print_gunmenu_roundsleft(p_userid);

    return PLUGIN_HANDLED;
  }

  // reset saved setup
  g_PlayerSavedSetup[p_userid] = false;

  // re-enable gunmenu
  g_PlayerDisableMenu[p_userid] = false;

  if (g_PlayerInBuyzone[p_userid] && is_user_alive(p_userid)) {
    if (!round_is_buytime_over()) {
      user_show_mainmenu(p_userid);

      // show countdown for menu
      user_start_buytime_countdown(p_userid);

      if (task_exists(p_userid + TASK_HIDE_ID)) {
        remove_task(p_userid + TASK_HIDE_ID);
      }

      set_task(round_get_buytime_left(), "hide_menu", p_userid + TASK_HIDE_ID);
    } else {
      client_print(p_userid, print_center, HUD_MSG_BUYTIME_PASSED, HUD_PREFIX, floatround(g_Buytime, floatround_floor));
    }

    return PLUGIN_HANDLED;
  } else {
    if (!is_user_alive(p_userid)) {
      g_PlayerSpawnSetup[p_userid] = true;
      user_show_mainmenu(p_userid);
    } else {
      client_print(p_userid, print_center, CHAT_MSG_GUNMENU_RESET, HUD_PREFIX);
    }

    return PLUGIN_HANDLED;
  }

  return PLUGIN_HANDLED;
}

/*
 * Show VIP Info
 * TODO: make dynamic, read from config
 */
public user_show_wantvip(p_userid) {
  show_motd(p_userid, "<meta http-equiv='refresh' content='0; url=http://shop.lamdaprocs.in/#donationinfo' />", "Lamda Pro CS - Shop");

  return PLUGIN_HANDLED;
}

/*
 * Stocks
 * ???
 */
stock user_screen_fade(p_userid, p_checkflash=1, p_r=0, p_g=0, p_b=0, p_a=80) {
  if (p_checkflash == 1 && g_PlayerFlashed[p_userid]) {
    return false;
  }

  message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, p_userid);
  write_short(1<<10);
  write_short(1<<10);
  write_short(0x0000);
  write_byte(p_r);
  write_byte(p_g);
  write_byte(p_b);
  write_byte(p_a);
  message_end();

  return true;
}

// TODO?
// stock user_show_hud_damage(p_userid, p_dmg, const p_hud, p_red, p_green, p_blue, p_x, p_y, p_fade)
// {
//   set_hudmessage(p_red, p_green, p_blue, p_x, p_y, 2, 0.1, 3.0, p_fade, p_fade, -1)
//   ShowSyncHudMsg(p_userid, p_hud, "%i^n", p_dmg)
// }
// user_show_hud_damage(p_userid, p_dmg, const p_hud, 240, 0, 25, 0.5, -1.0, 0.1)
// user_show_hud_damage(p_userid, p_dmg, const p_hud, 0, 200, 100, -1.0, 0.5, 0.05)

stock user_show_damage_recieved(p_userid, p_dmg, const p_hud) {
  set_hudmessage(255, 0, 0, 0.45, 0.50, 2, 0.1, 3.0, 0.1, 0.1, -1);
  ShowSyncHudMsg(p_userid, p_hud, "%i^n", p_dmg);
}

stock user_show_damage_made(p_userid, p_dmg, const p_hud) {
  set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 3.0, 0.05, 0.05, -1);
  ShowSyncHudMsg(p_userid, p_hud, "%i^n", p_dmg);
}

/*
 * get primary weapon label
 */
stock get_weaponlabel_primary(p_userid, p_string[], const p_stringlen) {
  ArrayGetString(g_WeaponNames, g_PlayerPrimaryWeapon[p_userid], p_string, p_stringlen);
}

/*
 * get secondary weapon label
 */
stock get_weaponlabel_secondary(p_userid, p_string[], const p_stringlen) {
  new i_Secondary = g_PlayerSecondaryWeapon[p_userid];

  // shift secondary index
  i_Secondary = ArraySize(g_PrimaryWeapons) + i_Secondary;

  ArrayGetString(g_WeaponNames, i_Secondary, p_string, p_stringlen);
}

stock user_show_mainmenu(p_userid) {
  if (!is_user_vip(p_userid) || !is_gunmenu_enabled()) {
    return;
  }

#if defined DEBUG
  client_print(p_userid, print_chat, "show menu [%d]", p_userid);
#endif

  // translate menu titles
  new s_Mainmenu_Title[64],
      s_Mainmenu_PrimaryWeaponTitle[64],
      s_Mainmenu_SecondaryWeaponTitle[64];

  formatex(s_Mainmenu_Title, charsmax(s_Mainmenu_Title), "%L", p_userid, "GUNMENU_TITLE");
  formatex(s_Mainmenu_PrimaryWeaponTitle, charsmax(s_Mainmenu_PrimaryWeaponTitle), "%L^n%L", p_userid, "GUNMENU_TITLE", p_userid, "GUNMENU_PRIMARY_WEAPON_TITLE");
  formatex(s_Mainmenu_SecondaryWeaponTitle, charsmax(s_Mainmenu_SecondaryWeaponTitle), "%L^n%L", p_userid, "GUNMENU_TITLE", p_userid, "GUNMENU_SECONDARY_WEAPON_TITLE");
  
  menu_setprop(g_Mainmenu, MPROP_TITLE, s_Mainmenu_Title);
  menu_setprop(g_PrimaryMenu, MPROP_TITLE, s_Mainmenu_PrimaryWeaponTitle);
  menu_setprop(g_SecondaryMenu, MPROP_TITLE, s_Mainmenu_SecondaryWeaponTitle);

  // change "previous setup" title if necessary
  new s_MenuPreviousTitle[128];

  new i_PreviousSetup,
      i_PreviousSetupSave;

  i_PreviousSetup = ArraySize(g_WeaponSetups) + 1;
  i_PreviousSetupSave = ArraySize(g_WeaponSetups) + 2;

  // show "previous setup" (with selected weapons if any) & "previous + save"
  if (g_PlayerPrimaryWeapon[p_userid] >= 0 && g_PlayerSecondaryWeapon[p_userid] >= 0) {
    new s_PrimaryWeapon[32],
        s_SecondaryWeapon[32];

    get_weaponlabel_primary(p_userid, s_PrimaryWeapon, charsmax(s_PrimaryWeapon));
    get_weaponlabel_secondary(p_userid, s_SecondaryWeapon, charsmax(s_SecondaryWeapon));

    // show primary & secondary weapon next to "previous setup"
    formatex(
      s_MenuPreviousTitle, charsmax(s_MenuPreviousTitle),
      " \d[\y%s \r+ \y%s\d]",
      s_PrimaryWeapon, s_SecondaryWeapon
    );

    format(s_MenuPreviousTitle, charsmax(s_MenuPreviousTitle), g_MenuOptions[2], s_MenuPreviousTitle);

    menu_item_setname(g_Mainmenu, i_PreviousSetup, s_MenuPreviousTitle);
    menu_item_setcall(g_Mainmenu, i_PreviousSetup, -1);
    menu_item_setcall(g_Mainmenu, i_PreviousSetupSave, -1);
  } else {
    // show "previous" & "previous + save" as disabled
    // default format "previous" menuitem (don't show primary + secondary)
    formatex(s_MenuPreviousTitle, charsmax(s_MenuPreviousTitle), g_MenuOptions[2], " \d[none]");

    menu_item_setname(g_Mainmenu, i_PreviousSetup, s_MenuPreviousTitle);
    menu_item_setcall(g_Mainmenu, i_PreviousSetup, menu_makecallback("callback_menu_disabled"));
    menu_item_setcall(g_Mainmenu, i_PreviousSetupSave, menu_makecallback("callback_menu_disabled"));
  }

  menu_display(p_userid, g_Mainmenu, 0);

  return;
}

stock user_give_setup(p_userid, p_primary=-1, p_secondary=-1, bool:p_save=false) {
  user_stop_buytime_countdown(p_userid);

  g_PlayerRecievedSetup[p_userid] = false;

  if (round_is_buytime_over() && is_user_alive(p_userid)) {
    client_print(p_userid, print_center, HUD_MSG_BUYTIME_PASSED, HUD_PREFIX, floatround(g_Buytime, floatround_floor));

    return;
  }

  if (p_primary >= 0 && p_secondary >= 0) {
    new s_SetupPrimaryC[15],
        s_SetupSecondaryC[17];

    ArrayGetString(g_PrimaryWeapons, p_primary, s_SetupPrimaryC, charsmax(s_SetupPrimaryC));
    ArrayGetString(g_SecondaryWeapons, p_secondary, s_SetupSecondaryC, charsmax(s_SetupSecondaryC));

    format(s_SetupPrimaryC, charsmax(s_SetupPrimaryC), "weapon_%s", s_SetupPrimaryC);
    format(s_SetupSecondaryC, charsmax(s_SetupSecondaryC), "weapon_%s", s_SetupSecondaryC);

    if (is_user_alive(p_userid)) {
      g_PlayerSpawnSetup[p_userid] = false;

      user_strip_weapons(p_userid);
      user_give_equip(p_userid);
      user_give_weapon(p_userid, s_SetupPrimaryC);
      user_give_weapon(p_userid, s_SetupSecondaryC);
    } else {
      // remember (save) weapons for next spawn
      g_PlayerSpawnSetup[p_userid] = true;
    }

    // save last recieved weapons
    g_PlayerPrimaryWeapon[p_userid] = p_primary;
    g_PlayerSecondaryWeapon[p_userid] = p_secondary;

    // remember (save) weapons
    // if true, don't task again until next reset
    g_PlayerSavedSetup[p_userid] = p_save;

    // show "setup recieved" in chat for player
    new s_PrimaryWeapon[32],
        s_SecondaryWeapon[32];

    // shift secondary index
    p_secondary = ArraySize(g_PrimaryWeapons) + p_secondary;

    ArrayGetString(g_WeaponNames, p_primary, s_PrimaryWeapon, charsmax(s_PrimaryWeapon));
    ArrayGetString(g_WeaponNames, p_secondary, s_SecondaryWeapon, charsmax(s_SecondaryWeapon));

    g_PlayerRecievedSetup[p_userid] = true;

    if (!g_PlayerSpawnSetup[p_userid]) {
      client_print_color(
        p_userid, Grey,
        CHAT_MSG_SETUP_RECIEVED,
        CHAT_PREFIX, s_PrimaryWeapon, s_SecondaryWeapon
      );
    } else {
      client_print_color(
        p_userid, Grey,
        CHAT_MSG_SETUP_SPAWN,
        CHAT_PREFIX, s_PrimaryWeapon, s_SecondaryWeapon
      );
    }

    if (p_save) {
      client_print_color(p_userid, Grey, CHAT_MSG_SETUP_SAVED, CHAT_PREFIX);
    }
  } else {
    // disable gunmenu, no weapons given
    g_PlayerDisableMenu[p_userid] = true;

    client_print_color(p_userid, Grey, CHAT_MSG_GUNMENU_DISABLED, CHAT_PREFIX);
  }

  return;
}

stock user_give_weapon(p_userid, s_WeaponConst[]) {
  if (is_user_connected(p_userid)) {
    new i_Weapon = get_weaponid(s_WeaponConst);
    give_item(p_userid, s_WeaponConst);

    replace(s_WeaponConst, 31, "weapon_", "");

    for (new i; i < sizeof g_WeaponConstants; i++) {
      if (equal(g_WeaponConstants[i], s_WeaponConst)) {
        cs_set_user_bpammo(p_userid, i_Weapon, g_WeaponAmmo[i]);
        break;
      }
    }
  }
}

stock user_give_equip(p_userid) {
  // give defuser if CT
  if (get_user_team(p_userid) == 2) {
    cs_set_user_defuse(p_userid, 1);
  }

  // get grenades amount
  new s_Grenades[9],
      n_HE[3],
      n_Flash[3],
      n_Smoke[3];

  get_pcvar_string(c7_vips_gunmenu_grens, s_Grenades, charsmax(s_Grenades));
  parse(s_Grenades, n_HE, 2, n_Flash, 2, n_Smoke, 2);

  // grenades
  if (str_to_num(n_HE) > 0) {
    give_item(p_userid, "weapon_hegrenade");
    cs_set_user_bpammo(p_userid, CSW_HEGRENADE, str_to_num(n_HE));
  }

  if (str_to_num(n_Flash) > 0) {
    give_item(p_userid, "weapon_flashbang");
    cs_set_user_bpammo(p_userid, CSW_FLASHBANG, str_to_num(n_Flash));
  }

  if (str_to_num(n_Smoke) > 0) {
    give_item(p_userid, "weapon_smokegrenade");
    cs_set_user_bpammo(p_userid, CSW_SMOKEGRENADE, str_to_num(n_Smoke));
  }

  // armor
  cs_set_user_armor(p_userid, 100, CS_ARMOR_VESTHELM);
}

stock user_drop_weapon(p_userid, p_pcvar, const p_weapon[]) {
  static n_pcvar;
  n_pcvar = get_pcvar_num(p_pcvar);

  if (n_pcvar == 0 || (n_pcvar == 1 && !is_user_vip(p_userid))) {
    engclient_cmd(p_userid, "drop", p_weapon);
  }

  return n_pcvar;
}

// strip weapons except bomb
// TODO: refactor
stock user_strip_weapons(p_userid) {
  new iC4Ent = get_pdata_cbase(p_userid, 372);

  if (iC4Ent > 0) {
    set_pdata_cbase(p_userid, 372, FM_NULLENT);
  }

  strip_user_weapons(p_userid);

  give_item(p_userid, "weapon_knife");
  set_pdata_int(p_userid, 116, 0);

  if (iC4Ent > 0) {
    set_pev(p_userid, pev_weapons, pev(p_userid, pev_weapons) | (1<<CSW_C4));
    set_pdata_cbase(p_userid, 372, iC4Ent);
    cs_set_user_bpammo(p_userid, CSW_C4, 1);
    cs_set_user_plant(p_userid, 1);
  }
}

// @see https://forums.alliedmods.net/showpost.php?p=2039952&postcount=4
stock is_spectating(spectator, player) {
  if (!pev_valid(spectator) || !pev_valid(player)) {
    return 0;
  }

  if (!is_user_connected(spectator) || !is_user_connected(player)) {
    return 0;
  }

  if (is_user_alive(spectator)) {
    return 0;
  }

  if(pev(spectator, pev_deadflag) != 2) {
    return 0;
  }

  static specmode;
  specmode = pev(spectator, pev_iuser1);

  if (!(specmode == 1 || specmode == 2 || specmode == 4)) {
    return 0;
  }

  if (pev(spectator, pev_iuser2) == player) {
    return 1;
  }

  return 0;
}

stock bool:is_user_vip(p_userid) {
  return is_user_connected(p_userid) && (get_user_flags(p_userid) & read_flags(g_VIP_Flag));
}

stock Float:round_get_buytime_left() {
  static Float:n_BuytimeLeft;
  n_BuytimeLeft = (get_gametime() - g_RoundStartTime - g_Buytime) * -1;

  // TODO: -10???
  if (n_BuytimeLeft <= -10) {
    return g_Buytime;
  }

  return n_BuytimeLeft;
}

stock bool:round_is_buytime_over() {
  return !g_InFreezetime && (get_gametime() - g_RoundStartTime) > g_Buytime;
}

stock user_start_buytime_countdown(p_userid) {
  // stop buytime countdown
  user_stop_buytime_countdown(p_userid);

  client_print(
    p_userid, print_center,
    HUD_MSG_BUYTIME_LEFT, HUD_PREFIX,
    floatround(round_get_buytime_left(), floatround_ceil)
  );

  set_task(
    1.0, "task_menu_timeleft", p_userid + TASK_DISABLE_ID, _, _, "a",
    floatround(round_get_buytime_left(), floatround_ceil)
  );
}

public task_menu_timeleft(p_taskid) {
  new i_User = p_taskid - TASK_DISABLE_ID;

  if (round_get_buytime_left() >= 0.1 && g_PlayerInBuyzone[i_User]) {
    client_print(i_User, print_center, HUD_MSG_BUYTIME_LEFT, HUD_PREFIX, floatround(round_get_buytime_left(), floatround_ceil));
  } else {
    client_print(i_User, print_center, HUD_MSG_BUYTIME_PASSED, HUD_PREFIX, floatround(g_Buytime, floatround_floor));
  }
}

stock user_stop_buytime_countdown(p_userid) {
  // stop buytime countdown
  if (task_exists(p_userid + TASK_DISABLE_ID)) {
    remove_task(p_userid + TASK_DISABLE_ID);
  }
}

stock is_gunmenu_enabled() {
  return g_CurrentRound >= get_pcvar_num(c7_vips_gunmenu_round);
}

stock print_gunmenu_roundsleft(p_userid=0) {
  new s_RoundString[7] = "rounds",
      n_RoundsLeft = get_pcvar_num(c7_vips_gunmenu_round) - g_CurrentRound;

  if (n_RoundsLeft <= 1) {
    formatex(s_RoundString, charsmax(s_RoundString), "round");
  }

  client_print_color(
    p_userid, Grey, CHAT_MSG_ROUND_NOT_REACHED, CHAT_PREFIX,
    n_RoundsLeft, s_RoundString
  );
}

/*
 * Handle Predefined Setup Selection
 * TODO: refactor, read from gunmenu config
 */
stock handle_menu_setup(p_userid, p_setupid) {
  if (!is_user_vip(p_userid)) {
    return false;
  }

#if defined DEBUG
  client_print(p_userid, print_chat, "handle_menu_setup [%d]", p_userid);
#endif

  new s_SetupConstants[18],
      s_SetupPrimaryC[15],
      s_SetupSecondaryC[17],
      i_Primary = -1,
      i_Secondary = -1;

  ArrayGetString(g_WeaponSetups, p_setupid, s_SetupConstants, charsmax(s_SetupConstants));
  parse(s_SetupConstants, s_SetupPrimaryC, charsmax(s_SetupPrimaryC), s_SetupSecondaryC, charsmax(s_SetupSecondaryC));

  // loop through primary weapons
  for (new i; i < ArraySize(g_PrimaryWeapons); i++) {
    new s_PrimaryWeapon[15];

    ArrayGetString(g_PrimaryWeapons, i, s_PrimaryWeapon, charsmax(s_PrimaryWeapon));

    // match found, save id and stop looping
    if (equali(s_SetupPrimaryC, s_PrimaryWeapon)) {
      i_Primary = i;
      break;
    }
  }

  // loop through secondary weapons
  for (new i; i < ArraySize(g_SecondaryWeapons); i++) {
    new s_SecondaryWeapon[17];

    ArrayGetString(g_SecondaryWeapons, i, s_SecondaryWeapon, charsmax(s_SecondaryWeapon));

    // match found, save id and stop looping
    if (equali(s_SetupSecondaryC, s_SecondaryWeapon)) {
      i_Secondary = i;
      break;
    }
  }

#if defined DEBUG
  client_print(p_userid, print_chat, "primary: [%d] | secondary: [%d]", i_Primary, i_Secondary);
#endif

  // give weapons to player
  user_give_setup(p_userid, i_Primary, i_Secondary);

  return true;
}

/*
 * Handle Previous Setup Selection
 */
stock handle_menu_setup_prev(p_userid, bool:p_save=false) {
  if (!is_user_vip(p_userid)) {
    return false;
  }

#if defined DEBUG
  client_print(p_userid, print_chat, "handle_menu_setup_prev [%d](save: %d)", p_userid, p_save);
#endif

  user_give_setup(p_userid, g_PlayerPrimaryWeapon[p_userid], g_PlayerSecondaryWeapon[p_userid], p_save);

  return true;
}

/*
 * Handle Disable Gunmenu
 */
stock handle_menu_disable(p_userid) {
  if (!is_user_vip(p_userid)) {
    return false;
  }

#if defined DEBUG
  client_print(p_userid, print_chat, "handle_menu_disable [%d]", p_userid);
#endif

  user_give_setup(p_userid, -1, -1, true);

  return true;
}

public callback_menu_disabled() {
  return ITEM_DISABLED;
}
