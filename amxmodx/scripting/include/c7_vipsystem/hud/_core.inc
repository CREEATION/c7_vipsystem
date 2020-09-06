// public hud_screen_fade(user_id, check_user_flashed=1, red=0, green=0, blue=0, alpha=80) {
//   if (check_user_flashed == 1 && g_PlayerFlashed[user_id]) {
//     return false;
//   }

//   message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, user_id);
//   write_short(1<<10);
//   write_short(1<<10);
//   write_short(0x0000);
//   write_byte(red);
//   write_byte(green);
//   write_byte(blue);
//   write_byte(alpha);
//   message_end();

//   return true;
// }

public hud_show_damage_received(user_id, Float:damage) {
  set_hudmessage(255, 0, 0, 0.45, 0.50, 2, 0.1, 3.0, 0.1, 0.1, -1);
  ShowSyncHudMsg(user_id, g_HudDmgReceived, "%i^n", floatround(damage, floatround_floor));
}

public hud_show_damage_inflicted(user_id, Float:damage) {
  set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 3.0, 0.05, 0.05, -1);
  ShowSyncHudMsg(user_id, g_HudDmgInflicted, "%i^n", floatround(damage, floatround_floor));
}
