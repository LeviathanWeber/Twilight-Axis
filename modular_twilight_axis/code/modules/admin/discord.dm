/datum/config_entry/string/admin_bans_channel
	default = null

/datum/config_entry/string/admin_bans_channel2
	default = null

/datum/config_entry/string/admin_notes_channel
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

// Админ тикеты в дискорд

/datum/config_entry/string/admin_ahelp_channel
	default = null

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

/world/proc/TgsAnnounceAhelpInteraction(datum/admin_help/ticket, raw_message, admin_ckey = null)
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

	var/datum/tgs_message_content/message = new("")
	message.embed = embed

	send2chat(message, admin_ahelp_channel)


// ТГС команды
// Команда для ответа из дискорда в тикет

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

	var/res = AH.DiscordReply(sender.friendly_name, message)
	if(res != "Message Successful")
		return res

	log_admin("[sender.friendly_name] replied to ticket #[ticket_id] via Discord: [message]")
	message_admins("Discord reply to ticket #[ticket_id] from [sender.friendly_name].")

	return "Reply sent to ticket #[ticket_id]."

// Закрытие тикета через дискорд

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

	var/old_usr = usr
	var/old_sender = GLOB.AdminProcCaller

	GLOB.AdminProcCaller = "CHAT_[sender.friendly_name]"


	var/result = null

	switch(action)
		if("handle")
			result = AH.DiscordHandle(sender.friendly_name)
		if("resolve", "resolved")
			result = AH.DiscordResolve(sender.friendly_name)
		if("close", "closed")
			result = AH.DiscordClose(sender.friendly_name)
		if("reject", "rejected")
			result = AH.DiscordReject(sender.friendly_name)
		if("reopen", "reopened")
			result = AH.DiscordReopen(sender.friendly_name)
		if("ic", "icissue")
			result = AH.DiscordICIssue(sender.friendly_name)
		if("mentor", "mentorissue")
			result = AH.DiscordMentorIssue(sender.friendly_name)
		else
			result = "Unknown action. Allowed: handle, resolve, close, reject, reopen, ic, mentor"

	GLOB.AdminProcCaller = old_sender
	usr = old_usr

	log_admin("[sender.friendly_name] used ticketaction [action] on ticket #[ticket_id] via Discord.")
	message_admins("Discord ticket action: [sender.friendly_name] -> [action] on ticket #[ticket_id].")

	return result
