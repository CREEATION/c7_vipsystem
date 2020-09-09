enum _:MenuOptions {
  GUNMENU_EMPTY,
  GUNMENU_NEW_SETUP,
  GUNMENU_PREV_SETUP,
  GUNMENU_SAVE_SETUP,
  GUNMENU_DISABLE,
  GUNMENU_CLOSE,
};

public gunmenu_create_main() {
  static gunmenu_main;

  gunmenu_main = menu_create("GUNMENU_TITLE", "gunmenu_handle_main");

  menu_additem(gunmenu_main, "Hello there!", "gm_item1");
  menu_additem(gunmenu_main, "Item 2? No problemo", "gm_item2");
  menu_additem(gunmenu_main, "Another item for your viewing pleasure", "gm_item3");

  return gunmenu_main;
}

public gunmenu_handle_main(user_id, menu_id, item_id) {
  static item_text[128];
  static item_info[32];
  static temp;

  menu_item_getinfo(
    menu_id, item_id,
    temp,
    item_info, charsmax(item_info),
    item_text, charsmax(item_text),
    temp
  );

  // handle main menu
  client_print(user_id, print_chat, "%s", item_text);

  return PLUGIN_HANDLED;
}

public gunmenu_display_main(user_id) {
  static menu;

  menu = gunmenu_create_main();

  menu_display(user_id, menu);

  return PLUGIN_HANDLED;
}

public gunmenu_create_primary() {
  static gunmenu_primary;

  return gunmenu_primary;
}

stock gunmenu_handle_primary(user_id, menu_id, item_id) {
  // handle primary menu
  return PLUGIN_HANDLED;
}

public gunmenu_create_secondary() {
  static gunmenu_secondary;

  return gunmenu_secondary;
}

stock gunmenu_handle_secondary(user_id, menu_id, item_id) {
  // handle secondary menu
  return PLUGIN_HANDLED;
}
