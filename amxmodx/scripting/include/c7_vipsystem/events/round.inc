public round_get_buytime_left() {
  new roundtime = floatround(g_RoundTime, floatround_floor);
  new freezetime = floatround(g_ServerFreezetime, floatround_floor);
  new buytime = floatround(g_ServerBuytime, floatround_floor);

  return (roundtime < 0 ? freezetime : 0) + buytime - roundtime;
}

public bool:round_buytime_over() {
  return g_RoundTime >= g_ServerBuytime;
}

static round_buytime_starts() {
  // set all the times
  g_ServerFreezetime = get_pcvar_float(get_cvar_pointer("mp_freezetime"));
  g_ServerBuytime = get_pcvar_float(get_cvar_pointer("mp_buytime")) * 60.0;
  g_RoundTime = g_ServerFreezetime * -1.0;

  // start buytime counter
  set_task(1.0, "task_start_buytime", TASK_BUYTIME,
    _, _, "a", floatround(g_ServerFreezetime + g_ServerBuytime, floatround_floor)
  );

  // show gunmenu to everyone except users without specified flags
  gunmenu_show();
}

//- EVENTS
public event_round_start_buytime() {
  if (!gunmenu_enabled_by_config()) {
    return PLUGIN_CONTINUE;
  }

  // update current round counter
  g_CurrentRound += 1;

  #if defined DEBUG_EVENTS
    client_print(0, print_chat, "> event_round_start_buytime");
  #endif

  if (!gunmenu_rounds_reached()) {
    gunmenu_print_rounds_left(0);

    #if defined DEBUG_EVENTS
      client_print(
        0, print_chat, "round: [%d/%d]",
        g_CurrentRound,
        get_pcvar_num(c7_vips_gm_enable_on_round)
      );
    #endif

    return PLUGIN_CONTINUE;
  }

  // start buytime
  round_buytime_starts();

  return PLUGIN_CONTINUE;
}

public event_round_start() {
  if (!gunmenu_enabled_by_config() || !gunmenu_rounds_reached()) {
    return PLUGIN_CONTINUE;
  }
  
  #if defined DEBUG_EVENTS
    client_print(0, print_chat, "> event_round_start");
  #endif

  // new users[MAX_SLOTS];
  // new users_num;

  // get_players(users, users_num, "ach");

  // for (new i; i < users_num; i++) {
  //   // skip all non-vips
  //   if (!is_user_gunmenu_vip(users[i])) {
  //     continue;
  //   }

  //   if (
  //     !g_UserSavedSetup[users[i]] &&
  //     !g_UserSpawnSetup[users[i]] &&
  //     !g_UserDisableMenu[users[i]]
  //   ) {
  //     // count down time left for buymenu
  //     task_start_buytime_countdown(users[i]);

  //     // set menu timeout task
  //     task_stop(users[i] + TASK_HIDE_ID);

  //     set_task(g_ServerBuytime, "task_gunmenu_hide", users[i] + TASK_HIDE_ID);
  //   }
  // }

  return PLUGIN_CONTINUE;
}

public event_round_end() {
  if (!gunmenu_enabled_by_config() || !gunmenu_rounds_reached()) {
    return PLUGIN_CONTINUE;
  }

  task_stop(TASK_BUYTIME);

  #if defined DEBUG_EVENTS
    client_print(0, print_chat, "> event_round_end");
  #endif

  // new users[MAX_SLOTS];
  // new users_num;

  // get_players(users, users_num, "ach");

  // for (new i; i < users_num; i++) {
  //   if (
  //     is_user_alive(users[i]) &&
  //     is_user_gunmenu_vip(users[i]) &&
  //     !g_UserSavedSetup[users[i]]
  //   ) {
  //     g_UserSpawnSetup[users[i]] = false;
  //   }
  // }

  return PLUGIN_CONTINUE;
}
