public event_user_spawn(user_id) {
  if (!is_user(user_id)) {
    return HAM_HANDLED;
  }

  #if defined DEBUG_EVENTS
    client_print(0, print_chat, "> event_user_spawn [%d]", user_id);
  #endif

  // give gunmenu setup

  return HAM_HANDLED;
}

public event_user_dies(user_id, attacker_id) {
  // flash both screens if not bot
  // give hp/ap to attacker if vip
  // give money to attacker if vip
  #if defined DEBUG_EVENTS
    client_print(0, print_chat, "> event_user_dies [%d killed by %d]", user_id, attacker_id);
  #endif

  return HAM_HANDLED;
}

public event_user_receives_damage(user_id, weapon_id, attacker_id, Float:damage) {
  new not_self_inflicted = user_id != attacker_id;
  new CsTeams:user_team = cs_get_user_team(user_id);
  new CsTeams:attacker_team = cs_get_user_team(attacker_id);
  new friendlyfire = !not_self_inflicted && user_team == attacker_team;

  if (friendlyfire && !g_ServerFriendlyFire) {
    return HAM_HANDLED;
  }

  if (is_user(user_id)) {
    hud_show_damage_received(user_id, damage);
  }
  
  if (is_user_vip(attacker_id) && not_self_inflicted) {
    hud_show_damage_inflicted(attacker_id, damage);
  }

  // show damage to spectators
  new users[MAX_SLOTS];
  new users_num;

  get_players(users, users_num, "bh");

  for (new i; i < users_num; i++) {
    if (is_spectating(users[i], user_id)) {
      hud_show_damage_received(users[i], damage);
    }

    if (is_spectating(users[i], attacker_id) && not_self_inflicted) {
      hud_show_damage_inflicted(users[i], damage);
    }
  }

  return HAM_HANDLED;
}

public event_user_flashed(user_id, Float:user_blind, Float:flash_duration, Float:hold_duration, alpha) {
  if (!is_user(user_id)) {
    return HAM_HANDLED;
  }

  #if defined DEBUG_EVENTS
    client_print(0, print_chat, "> event_user_flashed [%d]", user_id);
  #endif

  // get flash duration to prevent screen fade from removing flashed screen
  
  return HAM_HANDLED;
}

public event_user_inside_buyzone(user_id) {
  if (!gunmenu_enabled_by_config() || !is_user_vip(user_id)) {
    return PLUGIN_HANDLED;
  }

  #if defined DEBUG_EVENTS
    client_print(0, print_chat, "user entered buyzone [%d]", user_id);
  #endif

  return PLUGIN_CONTINUE;
}

public event_user_outside_buyzone(user_id) {
  if (!gunmenu_enabled_by_config() || !is_user_vip(user_id)) {
    return PLUGIN_HANDLED;
  }

  #if defined DEBUG_EVENTS
    client_print(0, print_chat, "user left buyzone [%d]", user_id);
  #endif

  return PLUGIN_CONTINUE;
}
