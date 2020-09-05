public bool:is_user_vip(user_id) {
  static user_flags[27];

  get_pcvar_string(c7_vips_gm_flags, user_flags, charsmax(user_flags));

  return is_user_connected(user_id) && (get_user_flags(user_id) & read_flags(user_flags));
}

// @see https://forums.alliedmods.net/showpost.php?p=2039952&postcount=4
public is_spectating(spectator, user) {
  if (!pev_valid(spectator) || !pev_valid(user)) return 0;
  if (!is_user_connected(spectator) || !is_user_connected(user)) return 0;
  if (is_user_alive(spectator)) return 0;
  if (pev(spectator, pev_deadflag) != 2) return 0;

  static specmode;
  specmode = pev(spectator, pev_iuser1);

  if (!(specmode == 1 || specmode == 2 || specmode == 4)) return 0;
  if (pev(spectator, pev_iuser2) == user) return 1;

  return 0;
}

// public register_chat_commands(commands[][], handler[]) {
//   if (sizeof commands <= 0) {
//     return false;
//   }

//   new say_command[32],
//       say_team_command[32];

//   for (new i; i < sizeof commands; i++) {
//     formatex(say_command, charsmax(say_command), "say %s", commands[i]);
//     formatex(say_team_command, charsmax(say_team_command), "say_team %s", commands[i]);

//     register_clcmd(say_command, handler);
//     register_clcmd(say_team_command, handler);
//   }

//   return true;
// }
