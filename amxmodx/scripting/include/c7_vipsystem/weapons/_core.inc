/**
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
