enum _:WeaponInfo
{
  CONSTANT[32],
  BACKPACK_AMMO,
  SLOT,
  NAME[64]
};

enum _:SetupInfo
{
  PRIMARY[32],
  SECONDARY[32],
  NAME[64]
};

public Array:gunmenu_cfg_get_weapons() {
  // get all the weapons
  static Array:weapons;
  static weapons_num;

  static configs_path[256];
  static filepointer_entries;

  // set path for weapons.ini
  get_configsdir(configs_path, charsmax(configs_path));
  format(
    configs_path, charsmax(configs_path),
    "%s/%s/gunmenu/weapons.ini",
    configs_path, PLUGIN_CONFIGS_DIR
  );

  // open weapons.ini
  filepointer_entries = fopen(configs_path, "r");

  if (!filepointer_entries) {
    set_fail_state("[C7 VIP] Gunmenu Weapons File not found");

    return weapons;
  }

  // create weapons array
  weapons = ArrayCreate(WeaponInfo);

  while (!feof(filepointer_entries)) {
    // read line from file
    static weapon_line[64];

    fgets(filepointer_entries, weapon_line, charsmax(weapon_line));

    // trim whitespaces left/right
    trim(weapon_line);

    // skip empty lines, comments and lines that aren't single weapons
    if (!weapon_line[0] || equali(weapon_line[0], ";") || !equali(weapon_line[0], "+")) {
      continue;
    }

    // example weapon line: xm1014[32, 1]: "M4 Super 90"

    // split line by ":" and trim whitespaces to get weapon info and name
    static weapon_info[32];
    static weapon_name[32];

    strtok(
      weapon_line, // text to split
      weapon_info, charsmax(weapon_info), // left half
      weapon_name, charsmax(weapon_name), // right half
      ':' // split by
    );

    trim(weapon_info); // xm1014[32, 1]
    trim(weapon_name); // "M4 Super 90"

    // remove quotes from weapon name
    remove_quotes(weapon_name);

    // get weapon info
    static weapon_constant[32];
    static weapon_details[32];

    strtok(
      weapon_info,
      weapon_constant, charsmax(weapon_constant),
      weapon_details, charsmax(weapon_details),
      '['
    );

    // remove "]" from weapon_details
    replace(weapon_details, charsmax(weapon_details), "]", "");

    // weapon_details = 32, 1

    // get weapon backpack ammo and slot
    static weapon_backpack_ammo[8];
    static weapon_slot[1];

    strtok(
      weapon_details,
      weapon_backpack_ammo, charsmax(weapon_backpack_ammo),
      weapon_slot, charsmax(weapon_slot),
      ','
    );

    // trim whitespaces
    trim(weapon_backpack_ammo);
    trim(weapon_slot);

    // populate weapon array
    new weapon[WeaponInfo];

    weapon[CONSTANT] = weapon_constant;
    weapon[BACKPACK_AMMO] = str_to_num(weapon_backpack_ammo); // convert string to integer
    weapon[SLOT] = str_to_num(weapon_slot); // convert string to integer
    weapon[NAME] = weapon_name;

    // push setup to weapons array
    ArrayPushArray(weapons, weapon);
  }

  return weapons;
}

public Array:gunmenu_cfg_get_setups() {
  // get all the setups
  static Array:setups;
  static setups_num;

  static configs_path[256];
  static filepointer_entries;

  // set path for setups.ini
  get_configsdir(configs_path, charsmax(configs_path));
  format(
    configs_path, charsmax(configs_path),
    "%s/%s/gunmenu/setups.ini",
    configs_path, PLUGIN_CONFIGS_DIR
  );

  // open setups.ini
  filepointer_entries = fopen(configs_path, "r");

  if (!filepointer_entries) {
    set_fail_state("[C7 VIP] Gunmenu Setups File not found");

    return setups;
  }

  // create setups array
  setups = ArrayCreate(SetupInfo);

  while (!feof(filepointer_entries)) {
    // read line from file
    static setup_line[64];

    fgets(filepointer_entries, setup_line, charsmax(setup_line));

    // trim whitespaces left/right
    trim(setup_line);

    // skip empty lines, comments and lines that don't indicate a setup
    if (!setup_line[0] || equali(setup_line[0], ";") || !equali(setup_line[0], "+")) {
      continue;
    }

    // example setup line: +m4a1 deagle: "M4A1 \r+ \wDeagle"

    // remove first "+" from entry
    replace(setup_line, charsmax(setup_line), "+", "");

    // split line by ":" and trim whitespaces to get weapon ids and setup name
    static setup_weapon_ids[32];
    static setup_name[64];

    strtok(
      setup_line, // text to split
      setup_weapon_ids, charsmax(setup_weapon_ids), // left half
      setup_name, charsmax(setup_name), // right half
      ':' // split by
    );

    trim(setup_weapon_ids); // m4a1 deagle
    trim(setup_name); // "M4A1 \r+ \wDeagle"

    // remove quotes from setup name
    remove_quotes(setup_name);

    // get weapon ids
    static setup_primary[32];
    static setup_secondary[32];

    strtok(
      setup_weapon_ids,
      setup_primary, charsmax(setup_primary),
      setup_secondary, charsmax(setup_secondary),
      ' '
    );

    // populate setup array
    new setup[SetupInfo];

    setup[PRIMARY] = setup_primary;
    setup[SECONDARY] = setup_secondary;
    setup[NAME] = setup_name;

    // push setup to setups array
    ArrayPushArray(setups, setup);
  }

  return setups;
}
