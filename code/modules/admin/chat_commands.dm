#define IRC_STATUS_THROTTLE 5

/datum/tgs_chat_command/ircstatus
	name = "status"
	help_text = "Gets the admincount, playercount, gamemode, and true game mode of the server"
	admin_only = TRUE
	var/last_irc_status = 0

/datum/tgs_chat_command/ircstatus/Run(datum/tgs_chat_user/sender, params)
	var/rtod = REALTIMEOFDAY
	if(rtod - last_irc_status < IRC_STATUS_THROTTLE)
		return
	last_irc_status = rtod
	var/list/adm = get_admin_counts()
	var/list/allmins = adm["total"]
	var/status = "Admins: [allmins.len] (Active: [english_list(adm["present"])] AFK: [english_list(adm["afk"])] Stealth: [english_list(adm["stealth"])] Skipped: [english_list(adm["noflags"])]). "
	status += "Players: [GLOB.clients.len] (Active: [get_active_player_count(0,1,0)]). Mode: Storytellers."
	return status

/datum/tgs_chat_command/irccheck
	name = "check"
	help_text = "Gets the playercount, gamemode, and address of the server"
	var/last_irc_check = 0

/datum/tgs_chat_command/irccheck/Run(datum/tgs_chat_user/sender, params)
	var/rtod = REALTIMEOFDAY
	if(rtod - last_irc_check < IRC_STATUS_THROTTLE)
		return
	last_irc_check = rtod
	var/server = CONFIG_GET(string/server)
	return "[GLOB.round_id ? "Round #[GLOB.round_id]: " : ""][GLOB.clients.len] players on [SSmapping.config.map_name], Mode: [GLOB.master_mode]; Round [SSticker.HasRoundStarted() ? (SSticker.IsRoundInProgress() ? "Active" : "Finishing") : "Starting"] -- [server ? server : "[world.internet_address]:[world.port]"]"

/datum/tgs_chat_command/namecheck
	name = "namecheck"
	help_text = "Returns info on the specified target"
	admin_only = TRUE

/datum/tgs_chat_command/namecheck/Run(datum/tgs_chat_user/sender, params)
	params = trim(params)
	if(!params)
		return "Insufficient parameters"
	log_admin("Chat Name Check: [sender.friendly_name] on [params]")
	message_admins("Name checking [params] from [sender.friendly_name]")
	return keywords_lookup(params, 1)

/datum/tgs_chat_command/adminwho
	name = "adminwho"
	help_text = "Lists administrators currently on the server"
	admin_only = TRUE

/datum/tgs_chat_command/adminwho/Run(datum/tgs_chat_user/sender, params)
	return ircadminwho()

/datum/tgs_chat_command/sdql
	name = "sdql"
	help_text = "Runs an SDQL query"
	admin_only = TRUE

/datum/tgs_chat_command/sdql/Run(datum/tgs_chat_user/sender, params)
	if(GLOB.AdminProcCaller)
		return "Unable to run query, another admin proc call is in progress. Try again later."
	GLOB.AdminProcCaller = "CHAT_[sender.friendly_name]"	//_ won't show up in ckeys so it'll never match with a real admin
	var/list/results = world.SDQL2_query(params, GLOB.AdminProcCaller, GLOB.AdminProcCaller)
	GLOB.AdminProcCaller = null
	if(!results)
		return "Query produced no output"
	var/list/text_res = results.Copy(1, 3)
	var/list/refs = results.len > 3 ? results.Copy(4) : null
	. = "[text_res.Join("\n")][refs ? "\nRefs: [refs.Join(" ")]" : ""]"

#undef IRC_STATUS_THROTTLE
