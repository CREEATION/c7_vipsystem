#define TASK_BUYTIME 7887

public task_start_buytime() {
  // first client_print doesn't print at all for some reason
  client_print(0, print_chat, "");

  g_RoundTime += 1.0;

  #if defined DEBUG_EVENTS
    client_print(
      0, print_chat, "buytime: [%d/%d], buytime left: [%d], buytime over: [%s]",
      floatround(g_RoundTime, floatround_floor),
      floatround(g_ServerBuytime, floatround_floor),
      round_get_buytime_left(),
      round_buytime_over() ? "yes" : "no"
    );
  #endif
}
