public event_user_spawn(user_id) {
  if (!is_user(user_id)) {
    return HAM_HANDLED;
  }

  // give gunmenu setup
  client_print(0, print_chat, "> event_user_spawn");
  client_print(0, print_chat, "%d", user_id);

  return HAM_HANDLED;
}

public event_user_dies(user_id, attacker_id) {
  // flash both screens if not bot
  // give hp/ap to attacker if vip
  // give money to attacker if vip
  client_print(0, print_chat, "> event_user_dies");
  client_print(0, print_chat, "%d, %d", user_id, attacker_id);

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

  // get flash duration to prevent screen fade from removing flashed screen
  client_print(0, print_chat, "> event_user_flashed");
  client_print(0, print_chat, "%d, %f, %f, %f, %f",
    user_id, user_blind, flash_duration, hold_duration, alpha);
  
  return HAM_HANDLED;
}

public event_user_buyzone(user_id) {
  if (!gunmenu_enabled_by_config() || !is_user_vip(user_id)) {
    return PLUGIN_HANDLED;
  }

  // show/hide gunmenu depending on if in buytime
  client_print(0, print_chat, "> event_user_buyzone");
  client_print(0, print_chat, "%d", user_id);

  static status[8];
  static bool:user_in_buyzone;

  get_msg_arg_string(2, status, 7);

  // check if hud icon is "buyzone"
  if (!equal(status, "buyzone")) {
    return PLUGIN_CONTINUE;
  }

  user_in_buyzone = bool:get_msg_arg_int(1);

  // hide menu if user left buyzone
  if (!user_in_buyzone) {
    #if defined DEBUG_EVENTS
      client_print(0, print_chat, "user left buyzone [%d]", user_id);
    #endif
  }

  return PLUGIN_CONTINUE;
}
