#define TASK_GM_BUYTIME_LEFT 6764
#define TASK_GM_HIDE 6828

public task_gm(user_id) {
  new buytime_left = floatround(round_get_buytime_left(), floatround_ceil);

  // stop previous buytime countdown
  task_stop(user_id + TASK_GM_BUYTIME);

  engclient_print(user_id, engprint_center,
    "%L", user_id, "HUD_MSG_BUYTIME_LEFT", buytime_left
  );

  set_task(1.0, "task_gunmenu_timeleft", user_id + TASK_GM_BUYTIME,
    _, _, "a", buytime_left
  );
}

public task_gm_buytime_left(user_id) {
  new buytime_left = floatround(round_get_buytime_left(), floatround_floor);

  if (g_UserInBuyzone[user_id] && buytime_left) {
    engclient_print(user_id, engprint_center,
      "%L", user_id, "HUD_MSG_BUYTIME_LEFT", buytime_left
    );
  } else {
    engclient_print(user_id, engprint_center,
      "%L", user_id, "HUD_MSG_BUYTIME_PASSED", g_ServerBuytime
    );
  }
}

public task_gm_hide(task_id) {
  // TODO
  return task_id - TASK_GM_HIDE;
}

public task_gm_hide()
{
	p_userid -= TASK_HIDE_ID

	if ( !is_user_connected(p_userid) || !is_user_vip(p_userid) || !get_pcvar_num(lpc_vip_gunmenu_enable) )
		return PLUGIN_HANDLED

	new m_Old, m_New
	player_menu_info( p_userid, m_Old, m_New )

	// hide gunmenu only
	if ( m_New != -1 )
	{
#if defined DEBUG
		client_print(p_userid,print_chat,"hiding menu [%d]",p_userid)
#endif

		if ( task_exists(p_userid) )
			remove_task(p_userid)

		// stop countdown
		user_stop_buytime_countdown(p_userid)

		show_menu( p_userid, 0, "^n", 1 )
	}

	return PLUGIN_CONTINUE
}
