#include "include/c7_vipsystem/gunmenu/config.inc"
#include "include/c7_vipsystem/gunmenu/menu.inc"

public gunmenu_print_need_vip(user_id) {
  return client_print_color(
    user_id, Grey, "%L %L",
    user_id, "CHAT_PREFIX",
    user_id, "CHAT_MSG_NEED_VIP"
  );
}

public gunmenu_print_rounds_left(user_id) {
  new user_lang = user_id == 0 ? LANG_PLAYER : user_id;

  return client_print_color(
    user_id, Grey, "%L %L",
    user_lang, "CHAT_PREFIX",
    user_lang, "CHAT_MSG_ROUND_NOT_REACHED",
    get_pcvar_num(c7_vips_gm_enable_on_round) - g_CurrentRound,
    "round(s)"
  );
}

public gunmenu_print_user_reset(user_id) {
  return client_print_color(
    user_id, Grey, "%L %L",
    user_id, "CHAT_PREFIX",
    user_id, "CHAT_MSG_GUNMENU_RESET"
  );
}

public gunmenu_print_user_disabled(user_id) {
  return client_print_color(
    user_id, Grey, "%L %L",
    user_id, "CHAT_PREFIX",
    user_id, "CHAT_MSG_GUNMENU_DISABLED"
  );
}

public gunmenu_print_setup_recieved(user_id) {
  return client_print_color(
    user_id, Grey, "%L %L",
    user_id, "CHAT_PREFIX",
    user_id, "CHAT_MSG_SETUP_RECIEVED",
    "primary",
    "secondary"
  );
}

public gunmenu_print_setup_spawn(user_id) {
  return client_print_color(
    user_id, Grey, "%L %L",
    user_id, "CHAT_PREFIX",
    user_id, "CHAT_MSG_SETUP_SPAWN",
    "primary",
    "secondary"
  );
}

public gunmenu_print_setup_saved(user_id) {
  return client_print_color(
    user_id, Grey, "%L %L",
    user_id, "CHAT_PREFIX",
    user_id, "CHAT_MSG_SETUP_SAVED"
  );
}

public bool:gunmenu_enabled_by_config() {
  return get_pcvar_num(c7_vips_gm_enable) > 0;
}

public bool:gunmenu_rounds_reached() {
  return g_CurrentRound >= get_pcvar_num(c7_vips_gm_enable_on_round);
}

public bool:gunmenu_show_nonvip_message() {
  return get_pcvar_num(c7_vips_gm_show_nonvip_message) > 0;
}

public bool:is_user_gunmenu_vip(user_id) {
  new user_flags[27];

  get_pcvar_string(c7_vips_gm_flags, user_flags, charsmax(user_flags));

  return bool:(get_user_flags(user_id) & read_flags(user_flags));
}

public gunmenu_show() {
  new users[MAX_SLOTS];
  new users_num;

  get_players(users, users_num, "ach");

  for (new i; i < users_num; i++) {
    // show a message to all non-vips that the gunmenu is disabled for them
    if (gunmenu_show_nonvip_message() && !is_user_gunmenu_vip(users[i])) {
      gunmenu_print_need_vip(users[i]);

      continue;
    }

    // actually show gunmenu depending on user preferences and state
  }

  return PLUGIN_CONTINUE;
}
