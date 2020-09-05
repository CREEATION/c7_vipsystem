public event_game_start() {
  if (!gunmenu_enabled_by_config()) {
    return PLUGIN_CONTINUE;
  }

  #if defined DEBUG_EVENTS
    client_print(0, print_chat, "> event_game_start");
  #endif

  g_CurrentRound = 0;

  task_stop(TASK_BUYTIME);

  // new users[MAX_SLOTS];
  // new users_num;

  // get_players(users, users_num, "ach");

  // for (new i; i < users_num; i++) {
  //   if (!is_user_gunmenu_vip(users[i])) {
  //     continue;
  //   }

  //   #if defined DEBUG_EVENTS
  //     client_print(users[i], print_chat, "reset user [%d]", users[i]);
  //   #endif

  //   task_gm_hide(users[i] + TASK_GM_HIDE);
  // }

  return PLUGIN_CONTINUE;
}
