// gunmenu
new c7_vips_gm_enable;
new c7_vips_gm_enable_on_round;
new c7_vips_gm_show_nonvip_message;
new c7_vips_gm_flags;

public plugin_cfg() {
  //- REGISTER CVARS
  // gunmenu
  c7_vips_gm_enable = register_cvar("c7_vips_gm_enable", "1", FCVAR_DEFAULT);
  c7_vips_gm_enable_on_round = register_cvar("c7_vips_gm_enable_on_round", "3", FCVAR_DEFAULT);
  c7_vips_gm_show_nonvip_message = register_cvar("c7_vips_gm_show_nonvip_message", "1", FCVAR_DEFAULT);
  c7_vips_gm_flags = register_cvar("c7_vips_gm_flags", "t", FCVAR_DEFAULT);

  plugin_reload_configs();
}

public plugin_reload_configs() {
  //- READ CONFIGS
  static configs_path[256];
  get_configsdir(configs_path, charsmax(configs_path));

  // gunmenu
  server_cmd("exec %s/%s/gunmenu/config.cfg", configs_path, PLUGIN_CONFIGS_DIR);
}
