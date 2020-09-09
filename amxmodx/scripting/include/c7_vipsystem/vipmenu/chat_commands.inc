/**
 * Show VIP Info
 * TODO: make dynamic, read from config
 */
public user_show_wantvip(p_userid) {
  show_motd(p_userid, "<meta http-equiv='refresh' content='0; url=http://shop.lamdaprocs.in/#donationinfo' />", "Lamda Pro CS - Shop");

  return PLUGIN_HANDLED;
}
