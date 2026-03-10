/datum/config_entry/string/admin_bans_channel
	default = null

/datum/config_entry/string/admin_bans_channel2
	default = null

/datum/config_entry/string/admin_notes_channel
	default = null

/datum/config_entry/string/admin_ahelp_channel
	default = null

// TODO: Обрати внимание на каждый прок. Их нужно будет упростить по DRY.

/world/proc/create_discord_embed_footer()
	return new /datum/tgs_chat_embed/footer(
		"[GLOB.rogue_round_id] / [time2text(world.timeofday, "DD.MM.YYYY hh:mm:ss", world.timezone)]"
	)

/// Отправляет средствами TGS сообщение о блокировке игрока или его ролей.
/world/proc/TgsAnnounceBan(player_ckey, admin_ckey, duration, time_message, roles, reason, severity, applies_to_admins)
	if(!TgsAvailable())
		return

	var/admin_bans_channel = CONFIG_GET(string/admin_bans_channel)
	var/admin_bans_channel2 = CONFIG_GET(string/admin_bans_channel2)

	if(!admin_bans_channel && !admin_bans_channel2)
		return

	var/severity_dict = list(
		"high" = "Высокая",
		"medium" = "Средняя",
		"minor" = "Малая",
		"none" = "None",
	)

	var/is_role_ban = roles[1] != "Server"

	var/title = is_role_ban ? "Бан ролей!" : "Бан!"
	var/description = "Игрок теряет возможность играть на сервере."

	if(is_role_ban)
		description = "Игрок теряет указанные роли:\n"
		for(var/role_name in roles)
			description += "- [role_name]\n"

	description += "\n"

	var/localized_severity = severity_dict[lowertext(severity)]
	if(localized_severity != "none")
		description += "**Тяжесть наказания:** [localized_severity]\n"

	description += "**Срок наказания:** [duration ? time_message : "*НАВСЕГДА*"]"

	if(applies_to_admins)
		description += "\n*Применено к администратору*"

	var/datum/tgs_chat_embed/structure/embed = new()
	embed.title = title
	embed.description = description
	embed.colour = "#ed8796"
	embed.footer = create_discord_embed_footer()

	var/datum/tgs_message_content/message = new("")
	message.embed = embed

	var/datum/tgs_chat_embed/field/field_player_ckey = new(
		"Игрок", "`[player_ckey]`"
	)

	var/datum/tgs_chat_embed/field/field_admin_ckey = new(
		"Администратор", "`[admin_ckey]`"
	)

	var/datum/tgs_chat_embed/field/field_reason = new(
		"Причина", "[copytext_char(reason, 1)]"
	)

	field_player_ckey.is_inline = TRUE
	field_admin_ckey.is_inline = TRUE
	field_reason.is_inline = FALSE

	embed.fields = list(
		field_player_ckey,
		field_admin_ckey,
		field_reason,
	)

	if(admin_bans_channel)
		send2chat(message, admin_bans_channel)

	if(admin_bans_channel2)
		send2chat(message, admin_bans_channel2)

/// Отправляет средствами TGS сообщение в дискорд об изменении PQ игрока.
/world/proc/TgsAnnouncePQChanges(value, player_ckey, admin_ckey, reason)
	if(!TgsAvailable())
		return

	var/admin_notes_channel = CONFIG_GET(string/admin_notes_channel)

	if(!admin_notes_channel)
		return

	var/datum/tgs_chat_embed/structure/embed = new()
	embed.title = "Изменение PQ"
	embed.description = reason ? "**Причина**\n" + reason : "Причина не указана!"
	embed.colour = value > 0 ? "#a6da95" : "#ed8796"
	embed.footer = create_discord_embed_footer()

	var/datum/tgs_chat_embed/field/field_player_ckey = new(
		"Игрок", "`[player_ckey]`"
	)

	var/datum/tgs_chat_embed/field/field_admin_ckey = new(
		"Администратор", "`[admin_ckey]`"
	)

	var/datum/tgs_chat_embed/field/field_changed_value = new(
		"Изменено на", "`[value]`"
	)

	field_player_ckey.is_inline = TRUE
	field_admin_ckey.is_inline = TRUE
	field_changed_value.is_inline = TRUE

	embed.fields = list(
		field_player_ckey,
		field_admin_ckey,
		field_changed_value,
	)

	var/datum/tgs_message_content/message = new("")
	message.embed = embed

	send2chat(
		message,
		admin_notes_channel
	)

/world/proc/TgsAnnounceNote(note, player_ckey, admin_ckey)
	if(!TgsAvailable())
		return

	var/admin_notes_channel = CONFIG_GET(string/admin_notes_channel)

	if(!admin_notes_channel)
		return

	var/datum/tgs_chat_embed/structure/embed = new()
	embed.title = "PQ Note"
	embed.description = note
	embed.colour = "#8aadf4"
	embed.footer = create_discord_embed_footer()

	var/datum/tgs_chat_embed/field/field_player_ckey = new(
		"Игрок", "`[player_ckey]`"
	)

	var/datum/tgs_chat_embed/field/field_admin_ckey = new(
		"Администратор", "`[admin_ckey]`"
	)

	field_player_ckey.is_inline = TRUE
	field_admin_ckey.is_inline = TRUE

	embed.fields = list(
		field_player_ckey,
		field_admin_ckey,
	)

	var/datum/tgs_message_content/message = new("")
	message.embed = embed

	send2chat(
		message,
		admin_notes_channel
	)

/world/proc/TgsAnnounceAdminMessageEntry(admin_ckey, target_key, type, text, secret, expiry)
	if(!TgsAvailable())
		return

	var/admin_notes_channel = CONFIG_GET(string/admin_notes_channel)

	if(!admin_notes_channel)
		return

	var/datum/tgs_chat_embed/structure/embed = new()
	embed.title = capitalize(type)
	embed.description = text
	embed.colour = "#ef9f76"
	embed.footer = create_discord_embed_footer()

	var/datum/tgs_chat_embed/field/field_player_ckey = new(
		"Игрок", "`[target_key]`"
	)

	var/datum/tgs_chat_embed/field/field_admin_ckey = new(
		"Администратор", "`[admin_ckey]`"
	)

	var/datum/tgs_chat_embed/field/field_secret = new(
		"Secret?", "[secret ? "Да" : "Нет"]"
	)

	field_player_ckey.is_inline = TRUE
	field_admin_ckey.is_inline = TRUE
	field_secret.is_inline = TRUE

	embed.fields = list(
		field_player_ckey,
		field_admin_ckey,
		field_secret,
	)

	if(expiry)
		embed.fields.Add(new /datum/tgs_chat_embed/field("Исчезнет", "[expiry]"))

	var/datum/tgs_message_content/message = new("")
	message.embed = embed

	send2chat(
		message,
		admin_notes_channel
	)

/world/proc/TgsAnnounceUnban(player_ckey, admin_ckey, role)
	if(!TgsAvailable())
		return

	var/admin_bans_channel = CONFIG_GET(string/admin_bans_channel)
	var/admin_bans_channel2 = CONFIG_GET(string/admin_bans_channel2)

	if(!admin_bans_channel && !admin_bans_channel2)
		return

	var/description = "Игроку доступна роль `[role]`!"
	if(lowertext(role) == "server")
		description = "Игрок может играть на сервере!"

	var/datum/tgs_chat_embed/structure/embed = new()
	embed.title = "Разбан"
	embed.description = description
	embed.colour = "#a6da95"
	embed.footer = create_discord_embed_footer()

	var/datum/tgs_message_content/message = new("")
	message.embed = embed

	var/datum/tgs_chat_embed/field/field_player_ckey = new(
		"Игрок", "`[player_ckey]`"
	)

	var/datum/tgs_chat_embed/field/field_admin_ckey = new(
		"Администратор", "`[admin_ckey]`"
	)

	field_player_ckey.is_inline = TRUE
	field_admin_ckey.is_inline = TRUE

	embed.fields = list(
		field_player_ckey,
		field_admin_ckey,
	)

	if(admin_bans_channel)
		send2chat(message, admin_bans_channel)

	if(admin_bans_channel2)
		send2chat(message, admin_bans_channel2)

//
// Админ тикеты в дискорд
//

/world/proc/TgsGetAhelpChannel()
	return CONFIG_GET(string/admin_ahelp_channel)

/world/proc/TgsAnnounceAhelpOpened(datum/admin_help/ticket, initial_message, is_bwoink = FALSE)
	if(!TgsAvailable())
		return

	var/admin_ahelp_channel = TgsGetAhelpChannel()
	if(!admin_ahelp_channel)
		return
	if(!ticket)
		return

	var/datum/tgs_chat_embed/structure/embed = new()
	embed.title = "Новый тикет #[ticket.id]"
	embed.colour = is_bwoink ? "#8aadf4" : "#f5a97f"
	embed.footer = create_discord_embed_footer()

	var/description = ""
	description += "**Раунд:** `[GLOB.rogue_round_id]`\n"
	description += "**Тикет:** `#[ticket.id]`\n"
	description += "**Статус:** `OPEN`\n"
	description += "**Тип:** [is_bwoink ? "`BWOINK/PM`" : "`AHELP`"]\n\n"
	description += copytext_char(discord_sanitize_ahelp("[initial_message]"), 1, 3500)

	embed.description = description

	var/datum/tgs_chat_embed/field/field_player_ckey = new(
		"Игрок", "`[ticket.initiator_key_name]`"
	)
	field_player_ckey.is_inline = TRUE

	embed.fields = list(
		field_player_ckey
	)

	var/datum/tgs_message_content/message = new("")
	message.embed = embed

	send2chat(message, admin_ahelp_channel)

/world/proc/TgsAnnounceAhelpInteraction(datum/admin_help/ticket, raw_message, admin_ckey = null, discord_ping_mention = null)
	if(!TgsAvailable())
		return

	var/admin_ahelp_channel = TgsGetAhelpChannel()
	if(!admin_ahelp_channel)
		return
	if(!ticket || !raw_message)
		return

	var/datum/tgs_chat_embed/structure/embed = new()
	embed.title = "Обновление тикета #[ticket.id]"
	embed.colour = "#91d7e3"
	embed.footer = create_discord_embed_footer()

	var/description = ""
	description += "**Раунд:** `[GLOB.rogue_round_id]`\n"
	description += "**Тикет:** `#[ticket.id]`\n"
	description += "**Статус:** `[ticket.GetStateName()]`\n\n"
	description += copytext_char(discord_sanitize_ahelp("[raw_message]"), 1, 3500)

	embed.description = description

	var/datum/tgs_chat_embed/field/field_player_ckey = new(
		"Игрок", "`[ticket.initiator_key_name]`"
	)
	field_player_ckey.is_inline = TRUE

	embed.fields = list(
		field_player_ckey
	)

	if(admin_ckey)
		var/datum/tgs_chat_embed/field/field_admin_ckey = new(
			"Администратор", "`[admin_ckey]`"
		)
		field_admin_ckey.is_inline = TRUE
		embed.fields += field_admin_ckey

	var/datum/tgs_message_content/message = new(discord_ping_mention ? "[discord_ping_mention]" : "")
	message.embed = embed

	send2chat(message, admin_ahelp_channel)

//
// ТГС команды
//

/datum/tgs_chat_command/ticketreply
	name = "ticketreply"
	help_text = "<ticket #> <message>"
	admin_only = TRUE

/datum/tgs_chat_command/ticketreply/Run(datum/tgs_chat_user/sender, params)
	params = trim(params)
	if(!params)
		return "Insufficient parameters"

	var/first_space = findtext(params, " ")
	if(!first_space)
		return "Usage: ticketreply <ticket #> <message>"

	var/ticket_text = copytext(params, 1, first_space)
	var/message = trim(copytext(params, first_space + 1))

	if(!message)
		return "Message is empty."

	var/ticket_id = text2num(ticket_text)
	if(isnull(ticket_id))
		return "Invalid ticket id."

	var/datum/admin_help/AH = GLOB.ahelp_tickets.TicketByID(ticket_id)
	if(!AH)
		return "Ticket #[ticket_id] not found."

	if(AH.state != AHELP_ACTIVE)
		return "Ticket #[ticket_id] is not active."

	var/admin_ckey = get_admin_ckey_by_discord_mention(sender.mention)
	if(!admin_ckey)
		return "Your Discord is not linked to any admin ckey. Use `discordlink <admin ckey>` first."

	var/res = AH.DiscordReply(admin_ckey, message)
	if(res != "Message Successful")
		return res

	log_admin("[admin_ckey] replied to ticket #[ticket_id] via Discord ([sender.friendly_name]): [message]")
	message_admins("Discord reply to ticket #[ticket_id] from [admin_ckey] ([sender.friendly_name]).")

	return "Reply sent to ticket #[ticket_id] as `[admin_ckey]`."

/datum/tgs_chat_command/discordlink
	name = "discordlink"
	help_text = "<admin ckey>"
	admin_only = TRUE

/datum/tgs_chat_command/discordlink/Run(datum/tgs_chat_user/sender, params)
	var/admin_ckey = ckey(trim(params))
	if(!admin_ckey)
		return "Usage: discordlink <admin ckey>"

	return link_admin_discord(admin_ckey, sender.mention)

/datum/tgs_chat_command/discordunlink
	name = "discordunlink"
	help_text = "Removes Discord link for the invoker"
	admin_only = TRUE

/datum/tgs_chat_command/discordunlink/Run(datum/tgs_chat_user/sender, params)
	return unlink_admin_discord_by_mention(sender.mention)

/datum/tgs_chat_command/ticketaction
	name = "ticketaction"
	help_text = "<ticket #> <handle|resolve|close|reject|reopen|ic|mentor>"
	admin_only = TRUE

/datum/tgs_chat_command/ticketaction/Run(datum/tgs_chat_user/sender, params)
	params = trim(params)
	if(!params)
		return "Insufficient parameters"

	var/list/all_params = splittext(params, " ")
	if(all_params.len < 2)
		return "Usage: ticketaction <ticket #> <handle|resolve|close|reject|reopen|ic|mentor>"

	var/ticket_id = text2num(all_params[1])
	if(isnull(ticket_id))
		return "Invalid ticket id."

	var/action = lowertext(trim(all_params[2]))

	var/datum/admin_help/AH = GLOB.ahelp_tickets.TicketByID(ticket_id)
	if(!AH)
		return "Ticket #[ticket_id] not found."

	var/admin_ckey = get_admin_ckey_by_discord_mention(sender.mention)
	if(!admin_ckey)
		return "Your Discord is not linked to any admin ckey. Use `discordlink <admin ckey>` first."

	var/old_usr = usr
	var/old_sender = GLOB.AdminProcCaller

	GLOB.AdminProcCaller = "CHAT_[admin_ckey]"

	var/result = null

	switch(action)
		if("handle")
			result = AH.DiscordHandle(admin_ckey)
		if("resolve", "resolved")
			result = AH.DiscordResolve(admin_ckey)
		if("close", "closed")
			result = AH.DiscordClose(admin_ckey)
		if("reject", "rejected")
			result = AH.DiscordReject(admin_ckey)
		if("reopen", "reopened")
			result = AH.DiscordReopen(admin_ckey)
		if("ic", "icissue")
			result = AH.DiscordICIssue(admin_ckey)
		if("mentor", "mentorissue")
			result = AH.DiscordMentorIssue(admin_ckey)
		else
			result = "Unknown action. Allowed: handle, resolve, close, reject, reopen, ic, mentor"

	GLOB.AdminProcCaller = old_sender
	usr = old_usr

	log_admin("[admin_ckey] used ticketaction [action] on ticket #[ticket_id] via Discord ([sender.friendly_name]).")
	message_admins("Discord ticket action: [admin_ckey] -> [action] on ticket #[ticket_id].")

	return result

/datum/tgs_chat_command/ticketcount
	name = "ticketcount"
	help_text = "<admin ckey>"
	admin_only = TRUE

/datum/tgs_chat_command/ticketcount/Run(datum/tgs_chat_user/sender, params)
	var/target_ckey = ckey(trim(params))
	if(!target_ckey)
		return "Напиши правильно - ticketcount <admin ckey>"

	if(!SSdbcore.Connect())
		return "БД умерла, это конец. Плачь, кричи и пингуй Владмара."

	var/datum/DBQuery/query_count = SSdbcore.NewQuery(
		"SELECT handled_ahelp_count FROM [format_table_name("admin")] WHERE ckey = :ckey",
		list("ckey" = target_ckey)
	)

	if(!query_count.warn_execute())
		qdel(query_count)
		return "Database query failed."

	if(!query_count.NextRow())
		qdel(query_count)
		return "Админ `[target_ckey]` не существует."

	var/count = text2num("[query_count.item[1]]")
	qdel(query_count)

	return "Админ `[target_ckey]` взял [count] тикетов за все время."

/datum/tgs_chat_command/ticketdays
	name = "ticketdays"
	help_text = "<admin ckey>"
	admin_only = TRUE

/datum/tgs_chat_command/ticketdays/Run(datum/tgs_chat_user/sender, params)
	var/admin_ckey = ckey(trim(params))
	if(!admin_ckey)
		return "Usage: ticketdays <admin ckey>"

	if(!SSdbcore.Connect())
		return "Database connection failed."

	var/datum/DBQuery/query_days = SSdbcore.NewQuery({"
		SELECT stat_date, handled_count
		FROM [format_table_name("admin_ahelp_stats")]
		WHERE admin_ckey = :admin_ckey
		ORDER BY stat_date DESC
		LIMIT 30
	"}, list("admin_ckey" = admin_ckey))

	if(!query_days.warn_execute())
		qdel(query_days)
		return "Database query failed."

	var/list/output = list()
	while(query_days.NextRow())
		var/stat_date = "[query_days.item[1]]"
		var/handled_count = text2num("[query_days.item[2]]")

		if(length(stat_date) >= 10)
			stat_date = copytext(stat_date, 1, 11)

		output += "[stat_date] — [handled_count]"

	qdel(query_days)

	if(!output.len)
		return "No handled ticket stats found for `[admin_ckey]`."

	return "Последние дни по `[admin_ckey]`:\n[output.Join("\n")]"

/datum/tgs_chat_command/ticketrange
	name = "ticketrange"
	help_text = "<admin ckey> <date from YYYY-MM-DD|DD.MM.YYYY> <date to YYYY-MM-DD|DD.MM.YYYY>"
	admin_only = TRUE

/datum/tgs_chat_command/ticketrange/Run(datum/tgs_chat_user/sender, params)
	var/list/all_params = splittext(trim(params), " ")
	if(all_params.len < 3)
		return "Usage: ticketrange <admin ckey> <date from YYYY-MM-DD|DD.MM.YYYY> <date to YYYY-MM-DD|DD.MM.YYYY>"

	var/admin_ckey = ckey(all_params[1])
	var/date_from = normalize_ticket_stat_date(all_params[2])
	var/date_to = normalize_ticket_stat_date(all_params[3])

	if(!admin_ckey || !date_from || !date_to)
		return "Invalid parameters. Use dates like `2026-03-09` or `09.03.2026`."

	if(!SSdbcore.Connect())
		return "Database connection failed."

	var/datum/DBQuery/query_range = SSdbcore.NewQuery({"
		SELECT IFNULL(SUM(handled_count), 0)
		FROM [format_table_name("admin_ahelp_stats")]
		WHERE admin_ckey = :admin_ckey
		  AND stat_date >= :date_from
		  AND stat_date <= :date_to
	"}, list(
		"admin_ckey" = admin_ckey,
		"date_from" = date_from,
		"date_to" = date_to
	))

	if(!query_range.warn_execute())
		qdel(query_range)
		return "Database query failed."

	var/count = 0
	if(query_range.NextRow())
		count = text2num("[query_range.item[1]]")
	qdel(query_range)

	return "Админ `[admin_ckey]` взял [count] тикетов с `[date_from]` по `[date_to]`."

//
// Discord <-> Admin link helpers
//

/proc/get_admin_ckey_by_discord_mention(discord_mention)
	if(!discord_mention)
		return null

	if(!SSdbcore.Connect())
		return null

	var/datum/DBQuery/query = SSdbcore.NewQuery(
		"SELECT ckey FROM [format_table_name("admin")] WHERE discord_mention = :discord_mention",
		list("discord_mention" = discord_mention)
	)

	if(!query.warn_execute())
		qdel(query)
		return null

	if(!query.NextRow())
		qdel(query)
		return null

	var/admin_ckey = query.item[1]
	qdel(query)
	return admin_ckey

/proc/get_admin_discord_mention_by_ckey(admin_ckey)
	admin_ckey = ckey(admin_ckey)
	if(!admin_ckey)
		return null

	if(!SSdbcore.Connect())
		return null

	var/datum/DBQuery/query = SSdbcore.NewQuery(
		"SELECT discord_mention FROM [format_table_name("admin")] WHERE ckey = :ckey",
		list("ckey" = admin_ckey)
	)

	if(!query.warn_execute())
		qdel(query)
		return null

	if(!query.NextRow())
		qdel(query)
		return null

	var/discord_mention = query.item[1]
	qdel(query)

	if(!discord_mention || discord_mention == "")
		return null

	return discord_mention

/proc/link_admin_discord(admin_ckey, discord_mention)
	admin_ckey = ckey(admin_ckey)
	if(!admin_ckey || !discord_mention)
		return "Invalid parameters."

	if(!SSdbcore.Connect())
		return "Database connection failed."

	var/datum/DBQuery/query_admin_exists = SSdbcore.NewQuery(
		"SELECT discord_mention FROM [format_table_name("admin")] WHERE ckey = :ckey",
		list("ckey" = admin_ckey)
	)
	if(!query_admin_exists.warn_execute())
		qdel(query_admin_exists)
		return "Database query failed."

	if(!query_admin_exists.NextRow())
		qdel(query_admin_exists)
		return "Admin `[admin_ckey]` not found in admin table."

	var/existing_mention = query_admin_exists.item[1]
	qdel(query_admin_exists)

	if(existing_mention && existing_mention != "")
		if(existing_mention == discord_mention)
			return "Твой дискорд уже привязан к `[admin_ckey]`."
		return "Админ `[admin_ckey]` уже привязан к другому дискорду."

	var/datum/DBQuery/query_mention_used = SSdbcore.NewQuery(
		"SELECT ckey FROM [format_table_name("admin")] WHERE discord_mention = :discord_mention",
		list("discord_mention" = discord_mention)
	)
	if(!query_mention_used.warn_execute())
		qdel(query_mention_used)
		return "Database query failed."

	if(query_mention_used.NextRow())
		var/used_by_ckey = query_mention_used.item[1]
		qdel(query_mention_used)
		if(used_by_ckey == admin_ckey)
			return "Твой дискорд уже привязан к `[admin_ckey]`."
		return "Твой дискорд уже привязан к `[used_by_ckey]`."
	qdel(query_mention_used)

	var/datum/DBQuery/query_link = SSdbcore.NewQuery(
		"UPDATE [format_table_name("admin")] SET discord_mention = :discord_mention WHERE ckey = :ckey",
		list("discord_mention" = discord_mention, "ckey" = admin_ckey)
	)

	if(!query_link.warn_execute())
		qdel(query_link)
		return "Database update failed."

	qdel(query_link)
	return "Дискорд привязан к `[admin_ckey]`."

/proc/unlink_admin_discord_by_mention(discord_mention)
	if(!discord_mention)
		return "Invalid parameters."

	if(!SSdbcore.Connect())
		return "Database connection failed."

	var/datum/DBQuery/query_check = SSdbcore.NewQuery(
		"SELECT ckey FROM [format_table_name("admin")] WHERE discord_mention = :discord_mention",
		list("discord_mention" = discord_mention)
	)

	if(!query_check.warn_execute())
		qdel(query_check)
		return "Database query failed."

	if(!query_check.NextRow())
		qdel(query_check)
		return "Твой дискорд уже ни к какому сикею не привязан."

	var/admin_ckey = query_check.item[1]
	qdel(query_check)

	var/datum/DBQuery/query_unlink = SSdbcore.NewQuery(
		"UPDATE [format_table_name("admin")] SET discord_mention = NULL WHERE discord_mention = :discord_mention",
		list("discord_mention" = discord_mention)
	)

	if(!query_unlink.warn_execute())
		qdel(query_unlink)
		return "Database update failed."

	qdel(query_unlink)
	return "Привязка к дискорду убрана у `[admin_ckey]`."

/proc/normalize_ticket_stat_date(input_date)
	input_date = trim("[input_date]")
	if(!input_date)
		return null

	if(length(input_date) == 10 && copytext(input_date, 5, 6) == "-" && copytext(input_date, 8, 9) == "-")
		return input_date

	if(length(input_date) == 10 && copytext(input_date, 3, 4) == "." && copytext(input_date, 6, 7) == ".")
		var/day = copytext(input_date, 1, 3)
		var/month = copytext(input_date, 4, 6)
		var/year = copytext(input_date, 7, 11)
		return "[year]-[month]-[day]"

	return null
