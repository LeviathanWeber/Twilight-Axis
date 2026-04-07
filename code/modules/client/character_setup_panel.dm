#ifndef CS_DIRTY_NONE
#define CS_DIRTY_NONE                  0
#endif
#ifndef CS_DIRTY_MAIN_PREVIEW
#define CS_DIRTY_MAIN_PREVIEW          (1<<0)
#endif
#ifndef CS_DIRTY_ACTIVE_CUSTOMIZER
#define CS_DIRTY_ACTIVE_CUSTOMIZER     (1<<1)
#endif
#ifndef CS_DIRTY_CUSTOMIZER_CATALOG
#define CS_DIRTY_CUSTOMIZER_CATALOG    (1<<2)
#endif
#ifndef CS_DIRTY_SLOT_SUMMARIES
#define CS_DIRTY_SLOT_SUMMARIES        (1<<3)
#endif
#ifndef CS_DIRTY_JOBS_CACHE
#define CS_DIRTY_JOBS_CACHE            (1<<4)
#endif
#ifndef CS_DIRTY_DETAILS
#define CS_DIRTY_DETAILS               (1<<5)
#endif
#ifndef CS_DIRTY_KEYBINDINGS
#define CS_DIRTY_KEYBINDINGS           (1<<6)
#endif

#ifndef CS_JOBS_DIRTY_NONE
#define CS_JOBS_DIRTY_NONE             0
#endif
#ifndef CS_JOBS_DIRTY_LIST
#define CS_JOBS_DIRTY_LIST             (1<<0)
#endif
#ifndef CS_JOBS_DIRTY_DETAIL
#define CS_JOBS_DIRTY_DETAIL           (1<<1)
#endif
#ifndef CS_JOBS_DIRTY_ALL
#define CS_JOBS_DIRTY_ALL              (CS_JOBS_DIRTY_LIST | CS_JOBS_DIRTY_DETAIL)
#endif

#define CS_DIRTY_OWNER_VISIBLE_MASK    (CS_DIRTY_MAIN_PREVIEW | CS_DIRTY_ACTIVE_CUSTOMIZER | CS_DIRTY_CUSTOMIZER_CATALOG | CS_DIRTY_SLOT_SUMMARIES | CS_DIRTY_DETAILS | CS_DIRTY_KEYBINDINGS)

/datum/character_setup_panel
	var/datum/preferences/prefs
	var/active_customizer_type
	var/preview_revision = 1
	var/list/preview_asset_cache = list()
	var/list/base_part_icon_cache = list()
	var/last_main_preview_asset = null
	var/customizer_filter = ""
	var/customizer_window_start = 1
	var/customizer_window_size = 8
	var/active_job_slot_title = null
	var/mob/last_user
	var/preview_dir = SOUTH
	var/list/cached_active_customizer_payload
	var/cached_active_customizer_payload_key = null
	var/active_customizer_payload_generation = 1
	var/list/cached_slot_summaries
	var/list/cached_body_marking_catalog
	var/cached_body_marking_catalog_key = null
	var/list/cached_job_entries
	var/cached_job_entries_key = null
	var/list/cached_job_slot_choices
	var/cached_job_slot_choices_key = null
	var/datum/character_setup_jobs_panel/jobs_panel
	var/main_preview_dirty = TRUE
	var/main_preview_asset_key = null
	var/customizer_catalog_generation = 1
	var/list/cached_visible_customizer_types
	var/cached_visible_customizer_types_key = null
	var/list/cached_customizer_summary_payload
	var/cached_customizer_summary_payload_key = null
	var/list/cached_genital_customizer_payload
	var/cached_genital_customizer_payload_key = null
	var/list/cached_body_context_customizer_payload
	var/cached_body_context_customizer_payload_key = null
	var/cached_primary_hair_payload = null
	var/cached_primary_hair_payload_key = null
	var/cached_facial_hair_payload = null
	var/cached_facial_hair_payload_key = null
	var/queued_ui_update = FALSE
	var/queued_ui_update_generation = 0
	var/queued_ui_owner_dirty_flags = CS_DIRTY_NONE
	var/queued_ui_jobs_dirty_flags = CS_JOBS_DIRTY_NONE
	var/queued_ui_force_owner = FALSE
	var/cached_player_quality_ckey = null
	var/cached_player_quality_text = null
	var/list/cached_ui_payload
	var/ui_payload_dirty_flags = CS_DIRTY_OWNER_VISIBLE_MASK
	var/ui_payload_force_full_refresh = TRUE
	var/preview_cache_scope = null

/datum/character_setup_panel/New(datum/preferences/prefs_owner)
	prefs = prefs_owner
	preview_cache_scope = "panel|[REF(src)]"
	return ..()

/datum/character_setup_panel/Destroy()
	if(SSwardrobe && hascall(SSwardrobe, "clear_character_setup_preview_scope") && preview_cache_scope)
		call(SSwardrobe, "clear_character_setup_preview_scope")(preview_cache_scope)
	return ..()

/datum/character_setup_panel/ui_state(mob/user)
	return GLOB.always_state

/datum/character_setup_panel/ui_interact(mob/user, datum/tgui/ui)
	last_user = user
	if(user?.ckey)
		preview_cache_scope = "[user.ckey]|[REF(src)]"
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CharacterSetup")
		ui.open()

/datum/character_setup_panel/proc/character_setup_plaintext(value)
	if(isnull(value))
		return ""
	var/text = "[value]"
	var/start = findtext(text, "<")
	while(start)
		var/finish = findtext(text, ">", start)
		if(!finish)
			break
		text = "[copytext(text, 1, start)][copytext(text, finish + 1)]"
		start = findtext(text, "<")
	text = replacetext(text, "&nbsp;", " ")
	text = replacetext(text, "&amp;", "&")
	text = replacetext(text, "&lt;", "<")
	text = replacetext(text, "&gt;", ">")
	return trim(text)

/datum/character_setup_panel/proc/get_cached_player_quality_text(mob/user)
	if(!user?.ckey)
		return ""
	if(cached_player_quality_ckey != user.ckey || isnull(cached_player_quality_text))
		cached_player_quality_ckey = user.ckey
		cached_player_quality_text = character_setup_plaintext(get_playerquality(user.ckey, text = TRUE))
	return cached_player_quality_text

/datum/character_setup_panel/proc/invalidate_active_customizer_payload()
	active_customizer_payload_generation++
	cached_active_customizer_payload = null
	cached_active_customizer_payload_key = null

/datum/character_setup_panel/proc/invalidate_customizer_catalog_payload()
	customizer_catalog_generation++
	cached_visible_customizer_types = null
	cached_visible_customizer_types_key = null
	cached_customizer_summary_payload = null
	cached_customizer_summary_payload_key = null
	cached_genital_customizer_payload = null
	cached_genital_customizer_payload_key = null
	cached_body_context_customizer_payload = null
	cached_body_context_customizer_payload_key = null
	cached_primary_hair_payload = null
	cached_primary_hair_payload_key = null
	cached_facial_hair_payload = null
	cached_facial_hair_payload_key = null
	invalidate_active_customizer_payload()

/datum/character_setup_panel/proc/invalidate_jobs_payload_cache()
	cached_job_entries = null
	cached_job_entries_key = null
	cached_job_slot_choices = null
	cached_job_slot_choices_key = null

/datum/character_setup_panel/proc/invalidate_ui_payload(dirty_flags = CS_DIRTY_NONE, force_full_refresh = FALSE)
	if(force_full_refresh || !cached_ui_payload)
		ui_payload_force_full_refresh = TRUE
	if(dirty_flags)
		ui_payload_dirty_flags |= dirty_flags

/datum/character_setup_panel/proc/queue_ui_update(owner_dirty_flags = CS_DIRTY_NONE, jobs_panel_dirty_flags = CS_JOBS_DIRTY_NONE, force_owner_update = FALSE)
	if(!owner_dirty_flags && !jobs_panel_dirty_flags && !force_owner_update)
		return
	if(owner_dirty_flags)
		queued_ui_owner_dirty_flags |= owner_dirty_flags
	if(jobs_panel_dirty_flags)
		queued_ui_jobs_dirty_flags |= jobs_panel_dirty_flags
	if(force_owner_update)
		queued_ui_force_owner = TRUE
	queued_ui_update_generation++
	var/current_generation = queued_ui_update_generation
	queued_ui_update = TRUE
	spawn(2)
		if(!queued_ui_update)
			return
		if(current_generation != queued_ui_update_generation)
			return
		flush_queued_ui_update()

/datum/character_setup_panel/proc/flush_queued_ui_update()
	var/owner_dirty_flags = queued_ui_owner_dirty_flags
	var/jobs_dirty_flags = queued_ui_jobs_dirty_flags
	var/should_force_owner_update = queued_ui_force_owner
	queued_ui_update = FALSE
	queued_ui_owner_dirty_flags = CS_DIRTY_NONE
	queued_ui_jobs_dirty_flags = CS_JOBS_DIRTY_NONE
	queued_ui_force_owner = FALSE

	if(owner_dirty_flags & CS_DIRTY_ACTIVE_CUSTOMIZER)
		invalidate_active_customizer_payload()

	if(owner_dirty_flags & CS_DIRTY_CUSTOMIZER_CATALOG)
		invalidate_customizer_catalog_payload()

	if(owner_dirty_flags & CS_DIRTY_SLOT_SUMMARIES)
		cached_slot_summaries = null

	if(owner_dirty_flags & CS_DIRTY_MAIN_PREVIEW)
		preview_revision++
		preview_asset_cache = list()
		base_part_icon_cache = list()
		main_preview_dirty = TRUE
		main_preview_asset_key = null
		if(SSwardrobe && hascall(SSwardrobe, "clear_character_setup_preview_scope") && preview_cache_scope)
			call(SSwardrobe, "clear_character_setup_preview_scope")(preview_cache_scope)

	if(owner_dirty_flags & CS_DIRTY_JOBS_CACHE)
		invalidate_jobs_payload_cache()

	if(should_force_owner_update)
		invalidate_ui_payload(CS_DIRTY_OWNER_VISIBLE_MASK, TRUE)
	else if(owner_dirty_flags & CS_DIRTY_OWNER_VISIBLE_MASK)
		var/ui_dirty_flags = owner_dirty_flags & CS_DIRTY_OWNER_VISIBLE_MASK
		if(ui_dirty_flags & CS_DIRTY_CUSTOMIZER_CATALOG)
			ui_dirty_flags |= CS_DIRTY_ACTIVE_CUSTOMIZER
		invalidate_ui_payload(ui_dirty_flags)

	if(jobs_panel && jobs_dirty_flags && hascall(jobs_panel, "apply_dirty_flags_from_owner"))
		call(jobs_panel, "apply_dirty_flags_from_owner")(jobs_dirty_flags)

	var/should_update_owner_panel = should_force_owner_update || !!(owner_dirty_flags & CS_DIRTY_OWNER_VISIBLE_MASK)
	if(should_update_owner_panel)
		SStgui.update_uis(src)

	if(jobs_panel && jobs_dirty_flags)
		SStgui.update_uis(jobs_panel)


/datum/character_setup_panel/ui_data(mob/user)
	if(!cached_ui_payload)
		cached_ui_payload = list()
		ui_payload_force_full_refresh = TRUE

	if(!prefs || !user)
		return cached_ui_payload

	var/effective_dirty_flags = ui_payload_dirty_flags
	if(ui_payload_force_full_refresh)
		effective_dirty_flags |= CS_DIRTY_OWNER_VISIBLE_MASK

	if(!effective_dirty_flags && length(cached_ui_payload))
		return cached_ui_payload

	if(effective_dirty_flags & (CS_DIRTY_MAIN_PREVIEW | CS_DIRTY_ACTIVE_CUSTOMIZER | CS_DIRTY_CUSTOMIZER_CATALOG | CS_DIRTY_SLOT_SUMMARIES | CS_DIRTY_DETAILS))
		prefs.validate_customizer_entries()
		prefs.validate_body_markings()
		ensure_active_customizer()

	if(ui_payload_force_full_refresh || !("max_save_slots" in cached_ui_payload))
		cached_ui_payload["max_save_slots"] = prefs.max_save_slots

	if(ui_payload_force_full_refresh || !("voice_type_choices" in cached_ui_payload))
		var/list/voice_type_choices = list()
		for(var/voice_name in GLOB.voice_types_list)
			voice_type_choices += "[voice_name]"
		cached_ui_payload["voice_type_choices"] = voice_type_choices

	if(effective_dirty_flags & CS_DIRTY_SLOT_SUMMARIES)
		cached_ui_payload["slot_summaries"] = build_slot_summaries()

	if(effective_dirty_flags & CS_DIRTY_MAIN_PREVIEW)
		cached_ui_payload["preview_asset"] = generate_main_preview_asset(user)
		cached_ui_payload["preview_token"] = preview_revision
		cached_ui_payload["preview_direction"] = "[preview_dir]"

	if(effective_dirty_flags & CS_DIRTY_DETAILS)
		var/datum/faith/selected_faith
		if(prefs.selected_patron)
			selected_faith = GLOB.faithlist[prefs.selected_patron.associated_faith]

		var/list/vices = list()
		for(var/datum/charflaw/cf as anything in prefs.charflaws)
			vices += "[cf]"

		var/extra_language_name = "None"
		if(ispath(prefs.extra_language, /datum/language))
			var/datum/language/extra_language_type = prefs.extra_language
			extra_language_name = initial(extra_language_type.name)

		cached_ui_payload["loaded_slot"] = prefs.loaded_slot
		cached_ui_payload["player_quality"] = get_cached_player_quality_text(user)
		var/triumphs_value = user.get_triumphs()
		if(isnull(triumphs_value) || triumphs_value == "")
			triumphs_value = 0
		cached_ui_payload["triumphs"] = triumphs_value
		cached_ui_payload["loadout_count"] = prefs.selected_loadout_items ? prefs.selected_loadout_items.len : 0
		cached_ui_payload["species_warning"] = prefs.spec_check(user) ? null : "У выбранной расы или подрасы есть ограничение для раундстарта."
		cached_ui_payload["identity"] = list(
			real_name = prefs.real_name,
			nickname = prefs.nickname,
			pronouns = "[prefs.pronouns]",
			titles = "[prefs.titles_pref]",
			clothes = "[prefs.clothes_pref]",
			voice_type = "[prefs.voice_type]",
			voice_pack = "[prefs.voice_pack]",
			accent = prefs.char_accent,
			voice_color = prefs.voice_color,
			voice_pitch = prefs.voice_pitch,
			voice_pitch_min = MIN_VOICE_PITCH,
			voice_pitch_max = MAX_VOICE_PITCH,
			highlight_color = prefs.highlight_color,
			dnr_pref = prefs.dnr_pref,
			combat_music = prefs.combat_music ? (prefs.combat_music.shortname ? prefs.combat_music.shortname : prefs.combat_music.name) : "Default",
			domhand = (prefs.domhand == 1) ? "Left-handed" : "Right-handed"
		)
		var/list/species_taur_list = prefs.pref_species ? prefs.pref_species.get_taur_list() : null
		cached_ui_payload["appearance"] = list(
			species = prefs.pref_species ? prefs.pref_species.base_name : "None",
			subspecies = prefs.pref_species ? prefs.pref_species.sub_name : "None",
			origin = "[prefs.virtue_origin]",
			statpack = prefs.statpack ? prefs.statpack.name : "None",
			faith = selected_faith ? selected_faith.name : "None",
			patron = prefs.selected_patron ? prefs.selected_patron.name : "None",
			extra_language = extra_language_name,
			gender_label = pronoun_gender_label(prefs.pronouns, prefs.gender),
			body_is_feminine = (prefs.gender == FEMALE),
			age = prefs.age,
			hair_color = prefs.get_hair_color(),
			eye_color = prefs.get_eye_color(),
			skin_tone = prefs.skin_tone,
			body_size = round((prefs.features["body_size"] || 1) * 100),
			body_size_min = round(BODY_SIZE_MIN * 100),
			body_size_max = round(BODY_SIZE_MAX * 100),
			taur_type = taur_label(prefs.taur_type),
			taur_color = prefs.taur_color,
			taur_available = LAZYLEN(species_taur_list) ? TRUE : FALSE,
			statpack_virtuous = prefs.statpack?.virtuous ? TRUE : FALSE,
			race_bonus = prefs.race_bonus ? prefs.race_bonus : "None",
			averse_faction = prefs.averse_chosen_faction
		)
		cached_ui_payload["virtues"] = list(
			virtue = prefs.virtue ? prefs.virtue.name : "None",
			virtue_two = prefs.virtuetwo ? prefs.virtuetwo.name : "None",
			vices = vices
		)
		var/descriptor_count = LAZYLEN(prefs.descriptor_entries) + LAZYLEN(prefs.custom_descriptors)
		var/culinary_count = LAZYLEN(prefs.culinary_preferences)
		var/list/sfw_gallery = list()
		if(islist(prefs.img_gallery))
			for(var/entry in prefs.img_gallery)
				sfw_gallery += "[entry]"
		var/list/nsfw_gallery = list()
		if(islist(prefs.nsfw_img_gallery))
			for(var/entry in prefs.nsfw_img_gallery)
				nsfw_gallery += "[entry]"
		cached_ui_payload["roleplay"] = list(
			flavortext = prefs.flavortext ? prefs.flavortext : "",
			ooc_notes = prefs.ooc_notes ? prefs.ooc_notes : "",
			rumour = prefs.rumour ? prefs.rumour : "",
			noble_gossip = prefs.noble_gossip ? prefs.noble_gossip : "",
			headshot_link = prefs.headshot_link ? prefs.headshot_link : "",
			lich_headshot_link = prefs.lich_headshot_link ? prefs.lich_headshot_link : "",
			vampire_headshot_link = prefs.vampire_headshot_link ? prefs.vampire_headshot_link : "",
			nsfwflavortext = prefs.nsfwflavortext ? prefs.nsfwflavortext : "",
			erpprefs = prefs.erpprefs ? prefs.erpprefs : "",
			descriptor_count = descriptor_count,
			culinary_count = culinary_count,
			sfw_gallery_count = LAZYLEN(prefs.img_gallery),
			nsfw_gallery_count = LAZYLEN(prefs.nsfw_img_gallery),
			sfw_gallery = sfw_gallery,
			nsfw_gallery = nsfw_gallery,
			music_url = prefs.ooc_extra ? prefs.ooc_extra : "",
			song_artist = prefs.song_artist ? prefs.song_artist : "",
			song_title = prefs.song_title ? prefs.song_title : ""
		)
		cached_ui_payload["context_selectors"] = build_context_selectors_payload()
		cached_ui_payload["vice_options"] = build_vice_options_payload()
		cached_ui_payload["vice_limit"] = MAX_VICES
		cached_ui_payload["descriptor_editor"] = build_descriptor_editor_payload()
		cached_ui_payload["culinary_editor"] = build_culinary_editor_payload()
		cached_ui_payload["familiar_editor"] = build_familiar_editor_payload(user)
		cached_ui_payload["origin_choices"] = build_origin_choices()
		cached_ui_payload["antag_roles"] = build_antag_role_entries(user)
		cached_ui_payload["villain_settings"] = list(
			lich_headshot_link = prefs.lich_headshot_link ? prefs.lich_headshot_link : "",
			vampire_headshot_link = prefs.vampire_headshot_link ? prefs.vampire_headshot_link : "",
			qsr_pref = prefs.qsr_pref,
			vampire_skin = prefs.vampire_skin,
			vampire_eyes = prefs.vampire_eyes,
			vampire_hair = prefs.vampire_hair,
			vampire_ears = prefs.vampire_ears
		)
		var/list/all_tgui_themes = get_tgui_themes()
		var/is_admin_user = FALSE
		if(user?.ckey && (GLOB.admin_datums[user.ckey] || GLOB.deadmins[user.ckey]))
			is_admin_user = TRUE
		var/examine_theme_name = "None (Use Viewer's)"
		if(prefs.examine_theme)
			examine_theme_name = all_tgui_themes[prefs.examine_theme] || prefs.examine_theme
		cached_ui_payload["system_settings"] = list(
			tgui_theme = prefs.tgui_theme,
			tgui_theme_name = all_tgui_themes[prefs.tgui_theme] || prefs.tgui_theme || "Default",
			examine_theme_name = examine_theme_name,
			tgui_lock = prefs.tgui_lock,
			ambientocclusion = prefs.ambientocclusion,
			windowflashing = prefs.windowflashing,
			clientfps = prefs.clientfps,
			auto_fit_viewport = prefs.auto_fit_viewport,
			widescreenpref = prefs.widescreenpref,
			chat_on_map = prefs.chat_on_map,
			see_chat_non_mob = prefs.see_chat_non_mob,
			buttons_locked = prefs.buttons_locked,
			anonymize = prefs.anonymize,
			masked_examine = prefs.masked_examine,
			full_examine = prefs.full_examine,
			mute_animal_emotes = prefs.mute_animal_emotes,
			autoconsume = prefs.autoconsume,
			no_examine_blocks = prefs.no_examine_blocks,
			no_autopunctuate = prefs.no_autopunctuate,
			no_language_fonts = prefs.no_language_fonts,
			no_language_icon = prefs.no_language_icon,
			no_redflash = prefs.no_redflash,
			is_admin = is_admin_user,
			play_admin_midis = !!(prefs.toggles & SOUND_MIDI),
			hear_adminhelps = !!(prefs.toggles & SOUND_ADMINHELP),
			asaycolor = prefs.asaycolor,
			can_edit_asaycolor = CONFIG_GET(flag/allow_admin_asaycolor),
			deadmin_always = !!(prefs.toggles & DEADMIN_ALWAYS),
			deadmin_antag = !!(prefs.toggles & DEADMIN_ANTAGONIST),
			deadmin_head = !!(prefs.toggles & DEADMIN_POSITION_HEAD),
			schizo_voice = !!(prefs.toggles & SCHIZO_VOICE),
			deadmin_always_forced = CONFIG_GET(flag/auto_deadmin_players),
			deadmin_antag_forced = CONFIG_GET(flag/auto_deadmin_antagonists),
			deadmin_head_forced = CONFIG_GET(flag/auto_deadmin_heads)
		)

	if(effective_dirty_flags & CS_DIRTY_CUSTOMIZER_CATALOG)
		var/list/body_marking_summary = list()
		for(var/zone in GLOB.marking_zones)
			var/list/zone_markings = prefs.body_markings[zone]
			var/list/names = list()
			if(zone_markings)
				for(var/name in zone_markings)
					names += "[name]"
			body_marking_summary += list(list(
				zone = "[zone]",
				label = zone_label(zone),
				count = zone_markings ? zone_markings.len : 0,
				names = names
			))
		cached_ui_payload["body_markings"] = body_marking_summary
		cached_ui_payload["body_marking_catalog"] = build_body_marking_catalog()
		cached_ui_payload["customizer_summaries"] = build_customizer_summary_payload(user)
		cached_ui_payload["genital_customizers"] = build_genital_customizer_payload()
		cached_ui_payload["body_context_customizers"] = build_body_context_customizer_payload()
		cached_ui_payload["hair_customizer"] = build_primary_hair_payload()
		cached_ui_payload["facial_hair_customizer"] = build_facial_hair_payload()

	if(effective_dirty_flags & CS_DIRTY_ACTIVE_CUSTOMIZER)
		cached_ui_payload["active_customizer"] = build_active_customizer_payload(user)

	if(effective_dirty_flags & CS_DIRTY_KEYBINDINGS)
		cached_ui_payload["keybind_mode"] = prefs.hotkeys ? "Hotkey" : "Classic"
		cached_ui_payload["keybinding_categories"] = build_keybinding_categories()

	ui_payload_dirty_flags = CS_DIRTY_NONE
	ui_payload_force_full_refresh = FALSE
	return cached_ui_payload

/datum/character_setup_panel/proc/build_slot_summaries()
	if(!cached_slot_summaries)
		cached_slot_summaries = list()
		var/savefile/S
		if(prefs.path)
			S = new /savefile(prefs.path)
		for(var/i = 1 to prefs.max_save_slots)
			var/name = null
			var/is_empty = TRUE
			if(S)
				S.cd = "/character[i]"
				S["real_name"] >> name
			if(name)
				is_empty = FALSE
			else
				name = "Слот [i]"
			cached_slot_summaries += list(list(
				index = i,
				name = name,
				empty = is_empty
			))

	var/list/output = list()
	for(var/list/slot_entry as anything in cached_slot_summaries)
		var/index = slot_entry["index"]
		var/is_current = (index == prefs.loaded_slot)
		var/name = slot_entry["name"]
		var/is_empty = slot_entry["empty"]
		if(is_current && prefs.real_name)
			name = prefs.real_name
			is_empty = FALSE
		output += list(list(
			index = index,
			name = name,
			current = is_current,
			empty = is_empty
		))
	return output

/datum/character_setup_panel/proc/get_visible_customizer_types()
	if(cached_visible_customizer_types_key == customizer_catalog_generation && cached_visible_customizer_types)
		return cached_visible_customizer_types

	var/list/output = list()
	if(!prefs || !prefs.pref_species)
		cached_visible_customizer_types = output
		cached_visible_customizer_types_key = customizer_catalog_generation
		return output

	var/list/customizers = prefs.pref_species.customizers
	if(!customizers)
		cached_visible_customizer_types = output
		cached_visible_customizer_types_key = customizer_catalog_generation
		return output

	for(var/customizer_type as anything in customizers)
		var/datum/customizer/customizer = CUSTOMIZER(customizer_type)
		if(!customizer || !customizer.is_allowed(prefs))
			continue
		var/customizer_name = lowertext(customizer.name)
		if(customizer_name == "eyes" || customizer_name == "eye")
			continue
		var/datum/customizer_entry/entry = prefs.get_customizer_entry_for_customizer_type(customizer_type)
		if(!entry)
			continue
		var/datum/customizer_choice/choice = CUSTOMIZER_CHOICE(entry.customizer_choice_type)
		var/option_count = choice && choice.sprite_accessories ? choice.sprite_accessories.len : 0
		var/is_hair = istype(entry, /datum/customizer_entry/hair)
		var/has_accessory_colors = choice && choice.allows_accessory_color_customization
		var/can_change_choice = customizer.customizer_choices && length(customizer.customizer_choices) > 1
		if(option_count <= 1 && !is_hair && !has_accessory_colors && !can_change_choice)
			continue
		output += list(customizer_type)
	cached_visible_customizer_types = output
	cached_visible_customizer_types_key = customizer_catalog_generation
	return output

/datum/character_setup_panel/proc/ensure_active_customizer()
	var/list/visible_customizers = get_visible_customizer_types()
	if(!visible_customizers.len)
		active_customizer_type = null
		return
	if(!(active_customizer_type in visible_customizers))
		active_customizer_type = visible_customizers[1]
		customizer_window_start = 1
		customizer_filter = ""

/datum/character_setup_panel/proc/build_customizer_summary_payload(mob/user)
	if(cached_customizer_summary_payload_key == customizer_catalog_generation && cached_customizer_summary_payload)
		return cached_customizer_summary_payload
	var/list/output = list()
	var/list/visible_customizers = get_visible_customizer_types()
	for(var/customizer_type as anything in visible_customizers)
		var/datum/customizer/customizer = CUSTOMIZER(customizer_type)
		var/datum/customizer_entry/entry = prefs.get_customizer_entry_for_customizer_type(customizer_type)
		var/datum/customizer_choice/choice = CUSTOMIZER_CHOICE(entry.customizer_choice_type)
		var/datum/sprite_accessory/current_accessory = entry && entry.accessory_type ? SPRITE_ACCESSORY(entry.accessory_type) : null
		var/current_group = customizer_group(customizer)
		if(current_group != "body")
			continue
		var/current_preview_asset = null
		var/current_icon = null
		var/current_icon_state = null
		output += list(list(
			id = "[customizer_type]",
			name = translate_customizer_name(customizer.name),
			disabled = entry.disabled,
			choice_name = choice ? choice.name : "Нет",
			option_count = choice && choice.sprite_accessories ? choice.sprite_accessories.len : 0,
			current_accessory_name = current_accessory ? current_accessory.name : "Нет",
			group = current_group,
			preview_asset = current_preview_asset,
			icon = current_icon,
			icon_state = current_icon_state
		))
	cached_customizer_summary_payload = output
	cached_customizer_summary_payload_key = customizer_catalog_generation
	return output

/datum/character_setup_panel/proc/build_genital_customizer_payload()
	if(cached_genital_customizer_payload_key == customizer_catalog_generation && cached_genital_customizer_payload)
		return cached_genital_customizer_payload
	var/list/output = list()
	if(!prefs || !prefs.pref_species)
		return output

	var/list/customizers = prefs.pref_species.customizers
	if(!customizers)
		return output

	for(var/customizer_type as anything in customizers)
		var/datum/customizer/customizer = CUSTOMIZER(customizer_type)
		if(!customizer)
			continue
		if(customizer_group(customizer) != "simple")
			continue

		var/list/payload = build_simple_customizer_payload(customizer_type)
		if(payload)
			output += list(payload)
	cached_genital_customizer_payload = output
	cached_genital_customizer_payload_key = customizer_catalog_generation
	return output

/datum/character_setup_panel/proc/ensure_customizer_entry(customizer_type)
	if(!customizer_type || !prefs)
		return null
	var/datum/customizer_entry/existing = prefs.get_customizer_entry_for_customizer_type(customizer_type)
	if(existing)
		return existing
	var/datum/customizer/customizer = CUSTOMIZER(customizer_type)
	if(!customizer || !customizer.customizer_choices || !length(customizer.customizer_choices))
		return null
	var/choice_type = customizer.customizer_choices[1]
	var/datum/customizer_entry/new_entry = customizer.create_customizer_entry(prefs, choice_type)
	if(new_entry)
		prefs.customizer_entries += new_entry
	return new_entry

/datum/character_setup_panel/proc/customizer_size_candidates_for_name(customizer_name)
	var/list/candidates = list("feature_size", "genital_size", "size")
	var/lower_name = lowertext("[customizer_name]")
	if(findtext(lower_name, "penis") || findtext(lower_name, "член") || findtext(lower_name, "cock"))
		candidates = list("penis_size", "cock_size", "member_size", "length", "genital_size", "feature_size", "size") + candidates
	else if(findtext(lower_name, "vagina") || findtext(lower_name, "влаг"))
		candidates = list("vagina_size", "depth", "genital_size", "feature_size", "size") + candidates
	else if(findtext(lower_name, "testicle") || findtext(lower_name, "яич") || findtext(lower_name, "ball"))
		candidates = list("testicles_size", "testicle_size", "balls_size", "ball_size", "genital_size", "feature_size", "size") + candidates
	else if(findtext(lower_name, "breast") || findtext(lower_name, "груд") || findtext(lower_name, "boob"))
		candidates = list("breasts_size", "breast_size", "chest_size", "cup_size", "genital_size", "feature_size", "size") + candidates
	return candidates

/datum/character_setup_panel/proc/get_customizer_size_info(datum/customizer_entry/entry, customizer_name)
	if(!entry)
		return null
	var/list/candidates = customizer_size_candidates_for_name(customizer_name)
	for(var/var_name in candidates)
		if(hasvar(entry, var_name))
			var/current_value = entry.vars[var_name]
			if(!isnull(current_value) && "[current_value]" != "")
				return list(
					var_name = "[var_name]",
					label = "Размер",
					value = current_value,
					is_numeric = isnum(current_value)
				)
	for(var/var_name in entry.vars)
		var/lower_var_name = lowertext("[var_name]")
		if(!(findtext(lower_var_name, "size") || findtext(lower_var_name, "length") || findtext(lower_var_name, "girth") || findtext(lower_var_name, "diameter")))
			continue
		if(lower_var_name in list("icon_size", "window_size", "customizer_window_size"))
			continue
		var/current_value = entry.vars[var_name]
		if(isnull(current_value) || "[current_value]" == "")
			continue
		return list(
			var_name = "[var_name]",
			label = "Размер",
			value = current_value,
			is_numeric = isnum(current_value)
		)
	return null

/datum/character_setup_panel/proc/is_three_step_genital_customizer(customizer_name)
	var/lower_name = lowertext("[customizer_name]")
	if(findtext(lower_name, "penis") || findtext(lower_name, "член") || findtext(lower_name, "cock"))
		return TRUE
	if(findtext(lower_name, "vagina") || findtext(lower_name, "влаг"))
		return TRUE
	if(findtext(lower_name, "testicle") || findtext(lower_name, "яич") || findtext(lower_name, "ball"))
		return TRUE
	if(findtext(lower_name, "breast") || findtext(lower_name, "груд") || findtext(lower_name, "boob"))
		return TRUE
	return FALSE

/datum/character_setup_panel/proc/get_three_step_size_choice_id(current_value)
	if(isnull(current_value))
		return "medium"
	if(isnum(current_value))
		var/num_value = text2num("[current_value]")
		if(num_value <= 1)
			return "small"
		if(num_value >= 3)
			return "large"
		return "medium"
	var/text_value = lowertext("[current_value]")
	if(findtext(text_value, "small") || findtext(text_value, "tiny") || findtext(text_value, "little") || findtext(text_value, "мал"))
		return "small"
	if(findtext(text_value, "large") || findtext(text_value, "huge") || findtext(text_value, "big") || findtext(text_value, "бол"))
		return "large"
	return "medium"

/datum/character_setup_panel/proc/build_three_step_size_options(current_value)
	var/current_id = get_three_step_size_choice_id(current_value)
	return list(
		make_selector_option("small", "Маленький", null, null, current_id == "small"),
		make_selector_option("medium", "Средний", null, null, current_id == "medium"),
		make_selector_option("large", "Большой", null, null, current_id == "large")
	)

/datum/character_setup_panel/proc/three_step_size_value_from_choice(current_value, choice_id)
	if(choice_id == "small")
		if(isnum(current_value))
			return 1
		return "Small"
	if(choice_id == "large")
		if(isnum(current_value))
			return 3
		return "Large"
	if(isnum(current_value))
		return 2
	return "Medium"

/datum/character_setup_panel/proc/build_simple_customizer_payload(customizer_type)
	var/datum/customizer/customizer = CUSTOMIZER(customizer_type)
	var/datum/customizer_entry/entry = ensure_customizer_entry(customizer_type)
	if(!customizer || !entry)
		return null

	var/datum/customizer_choice/choice = CUSTOMIZER_CHOICE(entry.customizer_choice_type)
	var/datum/sprite_accessory/current_accessory = (!entry.disabled && entry.accessory_type) ? SPRITE_ACCESSORY(entry.accessory_type) : null

	var/list/options = list()
	if(choice && choice.sprite_accessories)
		for(var/accessory_type as anything in choice.sprite_accessories)
			var/datum/sprite_accessory/accessory = SPRITE_ACCESSORY(accessory_type)
			if(!accessory)
				continue
			options += list(list(
				id = "[accessory_type]",
				name = accessory.name,
				icon = accessory.icon,
				icon_state = accessory.icon_state
			))

	var/list/choice_groups = list()
	if(customizer.customizer_choices)
		for(var/choice_type as anything in customizer.customizer_choices)
			var/datum/customizer_choice/iter_choice = CUSTOMIZER_CHOICE(choice_type)
			if(!iter_choice)
				continue
			choice_groups += list(list(
				id = "[choice_type]",
				name = iter_choice.name,
				current = (choice_type == entry.customizer_choice_type)
			))

	var/translated_name = translate_customizer_name(customizer.name)
	var/list/payload = list(
		id = "[customizer_type]",
		name = translated_name,
		disabled = entry.disabled,
		allows_disabling = customizer.allows_disabling,
		can_change_choice = length(customizer.customizer_choices) > 1,
		choice_name = choice ? choice.name : "Нет",
		choice_groups = choice_groups,
		current_accessory_name = current_accessory ? current_accessory.name : "None",
		selected_accessory_id = current_accessory ? "[entry.accessory_type]" : "__none__",
		option_count = options.len,
		options = options,
		allows_accessory_color_customization = choice ? choice.allows_accessory_color_customization : FALSE,
		group = "simple"
	)

	var/list/size_info = get_customizer_size_info(entry, translated_name)
	if(size_info)
		payload["size_label"] = size_info["label"]
		payload["size_value"] = size_info["value"]
		payload["size_var_name"] = size_info["var_name"]
		payload["size_is_numeric"] = !!size_info["is_numeric"]
		if(is_three_step_genital_customizer(translated_name))
			payload["size_options"] = build_three_step_size_options(size_info["value"])
			payload["size_selected_id"] = get_three_step_size_choice_id(size_info["value"])

	if(choice && choice.allows_accessory_color_customization && entry.accessory_type && !entry.disabled)
		var/datum/sprite_accessory/current_choice_accessory = SPRITE_ACCESSORY(entry.accessory_type)
		if(current_choice_accessory)
			var/list/color_labels = list()
			var/list/color_values = color_string_to_list(entry.accessory_colors)
			for(var/index in 1 to current_choice_accessory.color_keys)
				var/named_index = (current_choice_accessory.color_keys == 1) ? current_choice_accessory.color_key_name : current_choice_accessory.color_key_names[index]
				color_labels += named_index
			payload["accessory_color_labels"] = color_labels
			payload["accessory_color_values"] = color_values

	return payload

/datum/character_setup_panel/proc/should_use_context_menu_customizer(datum/customizer/customizer)
	if(!customizer)
		return FALSE
	if(customizer_group(customizer) != "body")
		return FALSE
	var/name = translate_customizer_name(customizer.name)
	if(name in list("Волосы", "Волосы на лице", "Глаза"))
		return FALSE
	return TRUE

/datum/character_setup_panel/proc/build_context_customizer_payload(customizer_type)
	var/datum/customizer/customizer = CUSTOMIZER(customizer_type)
	var/datum/customizer_entry/entry = ensure_customizer_entry(customizer_type)
	if(!customizer || !entry)
		return null

	var/datum/customizer_choice/choice = CUSTOMIZER_CHOICE(entry.customizer_choice_type)
	var/datum/sprite_accessory/current_accessory = (!entry.disabled && entry.accessory_type) ? SPRITE_ACCESSORY(entry.accessory_type) : null

	var/list/options = list()
	if(choice && choice.sprite_accessories)
		for(var/accessory_type as anything in choice.sprite_accessories)
			var/datum/sprite_accessory/accessory = SPRITE_ACCESSORY(accessory_type)
			if(!accessory)
				continue
			options += list(list(
				id = "[accessory_type]",
				name = accessory.name,
				icon = accessory.icon,
				icon_state = accessory.icon_state
			))

	var/list/choice_groups = list()
	if(customizer.customizer_choices)
		for(var/choice_type as anything in customizer.customizer_choices)
			var/datum/customizer_choice/iter_choice = CUSTOMIZER_CHOICE(choice_type)
			if(!iter_choice)
				continue
			choice_groups += list(list(
				id = "[choice_type]",
				name = iter_choice.name,
				current = (choice_type == entry.customizer_choice_type)
			))

	var/list/payload = list(
		id = "[customizer_type]",
		name = translate_customizer_name(customizer.name),
		disabled = entry.disabled,
		allows_disabling = customizer.allows_disabling,
		can_change_choice = length(customizer.customizer_choices) > 1,
		choice_name = choice ? choice.name : "Нет",
		choice_groups = choice_groups,
		current_accessory_name = current_accessory ? current_accessory.name : "None",
		selected_accessory_id = current_accessory ? "[entry.accessory_type]" : "__none__",
		option_count = options.len,
		options = options,
		allows_accessory_color_customization = choice ? choice.allows_accessory_color_customization : FALSE,
		group = "simple"
	)

	if(choice && choice.allows_accessory_color_customization && entry.accessory_type && !entry.disabled)
		var/datum/sprite_accessory/current_choice_accessory = SPRITE_ACCESSORY(entry.accessory_type)
		if(current_choice_accessory)
			var/list/color_labels = list()
			var/list/color_values = color_string_to_list(entry.accessory_colors)
			for(var/index in 1 to current_choice_accessory.color_keys)
				var/named_index = (current_choice_accessory.color_keys == 1) ? current_choice_accessory.color_key_name : current_choice_accessory.color_key_names[index]
				color_labels += named_index
			payload["accessory_color_labels"] = color_labels
			payload["accessory_color_values"] = color_values

	return payload

/datum/character_setup_panel/proc/build_body_context_customizer_payload()
	if(cached_body_context_customizer_payload_key == customizer_catalog_generation && cached_body_context_customizer_payload)
		return cached_body_context_customizer_payload
	var/list/output = list()
	if(!prefs || !prefs.pref_species)
		cached_body_context_customizer_payload = output
		cached_body_context_customizer_payload_key = customizer_catalog_generation
		return output
	var/list/customizers = prefs.pref_species.customizers
	if(!customizers)
		cached_body_context_customizer_payload = output
		cached_body_context_customizer_payload_key = customizer_catalog_generation
		return output
	for(var/customizer_type as anything in customizers)
		var/datum/customizer/customizer = CUSTOMIZER(customizer_type)
		if(!customizer)
			continue
		if(!should_use_context_menu_customizer(customizer))
			continue
		var/list/payload = build_context_customizer_payload(customizer_type)
		if(payload)
			output += list(payload)
	cached_body_context_customizer_payload = output
	cached_body_context_customizer_payload_key = customizer_catalog_generation
	return output

/datum/character_setup_panel/proc/build_primary_hair_payload()
	if(cached_primary_hair_payload_key == customizer_catalog_generation && !isnull(cached_primary_hair_payload))
		return cached_primary_hair_payload
	var/list/visible_customizers = get_visible_customizer_types()
	for(var/customizer_type as anything in visible_customizers)
		var/datum/customizer_entry/entry = prefs.get_customizer_entry_for_customizer_type(customizer_type)
		if(istype(entry, /datum/customizer_entry/hair))
			var/datum/customizer/customizer = CUSTOMIZER(customizer_type)
			var/datum/customizer_choice/choice = CUSTOMIZER_CHOICE(entry.customizer_choice_type)
			var/datum/sprite_accessory/current_accessory = entry.accessory_type ? SPRITE_ACCESSORY(entry.accessory_type) : null
			var/datum/customizer_entry/hair/hair_entry = entry
			var/list/payload = list(
				id = "[customizer_type]",
				name = translate_customizer_name(customizer ? customizer.name : "Hair"),
				current_accessory_name = current_accessory ? current_accessory.name : "Нет",
				choice_name = choice ? choice.name : "Нет",
				hair_color = hair_entry.hair_color,
				natural_gradient = hair_gradient_label(hair_entry.natural_gradient),
				natural_color = hair_entry.natural_color,
				dye_gradient = hair_gradient_label(hair_entry.dye_gradient),
				dye_color = hair_entry.dye_color
			)
			cached_primary_hair_payload = payload
			cached_primary_hair_payload_key = customizer_catalog_generation
			return payload
	cached_primary_hair_payload = null
	cached_primary_hair_payload_key = customizer_catalog_generation
	return null

/datum/character_setup_panel/proc/build_facial_hair_payload()
	if(cached_facial_hair_payload_key == customizer_catalog_generation && !isnull(cached_facial_hair_payload))
		return cached_facial_hair_payload
	var/list/visible_customizers = get_visible_customizer_types()
	for(var/customizer_type as anything in visible_customizers)
		var/datum/customizer/customizer = CUSTOMIZER(customizer_type)
		if(!customizer || translate_customizer_name(customizer.name) != "Волосы на лице")
			continue
		var/datum/customizer_entry/entry = prefs.get_customizer_entry_for_customizer_type(customizer_type)
		if(!istype(entry, /datum/customizer_entry/hair))
			continue
		var/datum/customizer_choice/choice = CUSTOMIZER_CHOICE(entry.customizer_choice_type)
		var/datum/sprite_accessory/current_accessory = entry.accessory_type ? SPRITE_ACCESSORY(entry.accessory_type) : null
		var/datum/customizer_entry/hair/hair_entry = entry
		var/list/payload = list(
			id = "[customizer_type]",
			name = translate_customizer_name(customizer.name),
			current_accessory_name = current_accessory ? current_accessory.name : "Нет",
			choice_name = choice ? choice.name : "Нет",
			hair_color = hair_entry.hair_color,
			natural_gradient = hair_gradient_label(hair_entry.natural_gradient),
			natural_color = hair_entry.natural_color,
			dye_gradient = hair_gradient_label(hair_entry.dye_gradient),
			dye_color = hair_entry.dye_color
		)
		cached_facial_hair_payload = payload
		cached_facial_hair_payload_key = customizer_catalog_generation
		return payload
	cached_facial_hair_payload = null
	cached_facial_hair_payload_key = customizer_catalog_generation
	return null

/datum/character_setup_panel/proc/generate_current_customizer_summary_preview_asset(mob/user, customizer_type)
	var/datum/customizer/customizer = CUSTOMIZER(customizer_type)
	if(!customizer)
		return null
	var/datum/customizer_entry/entry = prefs.get_customizer_entry_for_customizer_type(customizer_type)
	if(!entry || !entry.accessory_type)
		return null
	var/preview_focus = get_customizer_preview_focus(customizer)
	return generate_accessory_preview_asset(user, "current|[customizer_type]|[entry.accessory_type]", customizer_type, entry.accessory_type, preview_focus, preview_dir)

/datum/character_setup_panel/proc/generate_customizer_option_preview_asset(mob/user, customizer_type, accessory_type, preview_focus, target_dir = SOUTH)
	return generate_accessory_preview_asset(user, "option|[customizer_type]|[accessory_type]", customizer_type, accessory_type, preview_focus, target_dir)

/datum/character_setup_panel/proc/get_cached_accessory_preview_asset(cache_key, preview_focus, target_dir = SOUTH)
	var/full_key = "[preview_revision]|[cache_key]|[preview_focus]|[target_dir]"
	return preview_asset_cache[full_key]

/datum/character_setup_panel/proc/get_cached_preview_asset_filename(cache_key, preview_focus, target_dir = SOUTH)
	var/full_key = "[preview_revision]|[cache_key]|[preview_focus]|[target_dir]"
	return preview_asset_cache[full_key]

/datum/character_setup_panel/proc/generate_head_base_preview_assets_by_dir(mob/user)
	var/list/assets = list()
	var/south_asset = generate_cached_preview_asset(user, "hair_head_base", "head", SOUTH)
	if(south_asset)
		assets["SOUTH"] = south_asset
	for(var/dir in list(WEST, NORTH, EAST))
		var/cached_asset = get_cached_preview_asset_filename("hair_head_base", "head", dir)
		if(!cached_asset)
			continue
		switch(dir)
			if(WEST)
				assets["WEST"] = cached_asset
			if(NORTH)
				assets["NORTH"] = cached_asset
			if(EAST)
				assets["EAST"] = cached_asset
	return assets

/datum/character_setup_panel/proc/generate_customizer_option_preview_assets_by_dir(mob/user, customizer_type, accessory_type, preview_focus)
	var/list/assets = list()
	var/base_cache_key = "option|[customizer_type]|[accessory_type]"
	var/south_asset = generate_customizer_option_preview_asset(user, customizer_type, accessory_type, preview_focus, SOUTH)
	if(south_asset)
		assets["SOUTH"] = south_asset
	var/west_asset = get_cached_accessory_preview_asset(base_cache_key, preview_focus, WEST)
	if(west_asset)
		assets["WEST"] = west_asset
	var/north_asset = get_cached_accessory_preview_asset(base_cache_key, preview_focus, NORTH)
	if(north_asset)
		assets["NORTH"] = north_asset
	var/east_asset = get_cached_accessory_preview_asset(base_cache_key, preview_focus, EAST)
	if(east_asset)
		assets["EAST"] = east_asset
	return assets

/datum/character_setup_panel/proc/generate_accessory_preview_asset(mob/user, cache_key, customizer_type, accessory_type, preview_focus, target_dir = SOUTH)
	var/full_key = "[preview_revision]|[cache_key]|[preview_focus]|[target_dir]"
	if(preview_asset_cache[full_key])
		return preview_asset_cache[full_key]

	if(SSwardrobe && hascall(SSwardrobe, "render_character_setup_accessory_preview"))
		var/wardrobe_preview = call(SSwardrobe, "render_character_setup_accessory_preview")(user, prefs, customizer_type, accessory_type, preview_revision, preview_focus, target_dir, preview_cache_scope)
		if(wardrobe_preview)
			preview_asset_cache[full_key] = wardrobe_preview
			return wardrobe_preview

	var/icon/preview_icon = build_accessory_preview_icon(customizer_type, accessory_type, preview_focus, target_dir)
	if(!preview_icon)
		return null

	var/filename = "charsetup_[copytext(md5(full_key), 1, 9)].png"
	user << browse_rsc(preview_icon, filename)
	preview_asset_cache[full_key] = filename
	return filename

/datum/character_setup_panel/proc/build_accessory_preview_icon(customizer_type, accessory_type, preview_focus, target_dir = SOUTH)
	if(preview_focus == "head_overlay")
		var/icon/head_overlay_icon = build_preview_directional_accessory_icon(customizer_type, accessory_type, target_dir)
		if(!head_overlay_icon)
			return null
		head_overlay_icon = extract_character_setup_head_features_icon(head_overlay_icon, target_dir, character_setup_preview_debug_logging ? "charsetup-head charsetup_panel_overlay_only_band" : null, target_dir)
		return head_overlay_icon

	if(preview_focus == "head")
		var/icon/fast_head_icon = build_fast_head_accessory_preview_icon(customizer_type, accessory_type, target_dir)
		if(fast_head_icon)
			return fast_head_icon

		var/datum/customizer_entry/focused_entry = prefs.get_customizer_entry_for_customizer_type(customizer_type)
		if(focused_entry)
			var/old_accessory_type = focused_entry.accessory_type
			var/old_disabled = focused_entry.disabled
			focused_entry.accessory_type = accessory_type
			focused_entry.disabled = FALSE
			var/icon/focused_head_icon = build_current_prefs_preview_icon(preview_focus, target_dir)
			focused_entry.accessory_type = old_accessory_type
			focused_entry.disabled = old_disabled
			if(focused_head_icon)
				return focused_head_icon
		return get_base_part_preview_icon(customizer_type, preview_focus, target_dir)

	var/icon/accessory_icon = build_preview_directional_accessory_icon(customizer_type, accessory_type, target_dir)
	if(!accessory_icon)
		return null

	if(preview_focus == "underwear" || preview_focus == "groin" || preview_focus == "legs")
		apply_preview_focus(accessory_icon, preview_focus)
		return accessory_icon

	apply_preview_focus(accessory_icon, preview_focus)
	return accessory_icon

/datum/character_setup_panel/proc/get_base_part_preview_icon(customizer_type, preview_focus, target_dir = SOUTH)
	var/cache_key = "[preview_revision]|[customizer_type]|[preview_focus]|[target_dir]"
	var/icon/cached_icon = base_part_icon_cache[cache_key]
	if(cached_icon)
		return icon(cached_icon)

	var/icon/base_icon = build_current_prefs_base_source_icon(customizer_type, target_dir)
	if(!base_icon)
		return null
	base_icon = icon(base_icon)

	if(preview_focus == "head")
		var/icon/head_band_icon = extract_character_setup_head_features_icon(base_icon, target_dir, character_setup_preview_debug_logging ? "charsetup-head charsetup_panel_head_base_band" : null, target_dir)
		if(head_band_icon)
			base_icon = head_band_icon
	else if(preview_focus == "full")
		var/icon/fixed_full_preview_icon = build_fixed_character_setup_full_preview_icon(base_icon, target_dir, 32, 40, 16, 3, character_setup_preview_debug_logging ? "charsetup_preview" : null, target_dir)
		if(fixed_full_preview_icon)
			base_icon = fixed_full_preview_icon
	else
		apply_preview_focus(base_icon, preview_focus)

	base_part_icon_cache[cache_key] = base_icon
	return icon(base_icon)

/datum/character_setup_panel/proc/get_active_customizer_type_by_name(target_name)
	if(!prefs || !prefs.pref_species || !target_name)
		return null
	var/list/customizers = prefs.pref_species.customizers
	if(!customizers)
		return null
	var/needle = lowertext(target_name)
	for(var/customizer_type as anything in customizers)
		var/datum/customizer/customizer = CUSTOMIZER(customizer_type)
		if(!customizer || lowertext(customizer.name) != needle)
			continue
		var/datum/customizer_entry/entry = prefs.get_customizer_entry_for_customizer_type(customizer_type)
		if(!entry || entry.disabled || !entry.accessory_type)
			continue
		return customizer_type
	return null

/datum/character_setup_panel/proc/prepare_preview_dummy(mob/living/carbon/human/dummy/mannequin)
	if(!mannequin)
		return
	if(hascall(mannequin, "wipe_state"))
		call(mannequin, "wipe_state")()
	if(hascall(mannequin, "delete_equipment"))
		call(mannequin, "delete_equipment")()
	if(hascall(mannequin, "cut_overlays"))
		call(mannequin, "cut_overlays")()
	mannequin.overlays = null
	mannequin.underlays = null

/datum/character_setup_panel/proc/get_preview_dummy()
	return generate_or_wait_for_human_dummy(DUMMY_HUMAN_SLOT_PREFERENCES)

/datum/character_setup_panel/proc/release_preview_dummy(mob/living/carbon/human/dummy/mannequin)
	if(!mannequin)
		return
	unset_busy_human_dummy(DUMMY_HUMAN_SLOT_PREFERENCES)

/datum/character_setup_panel/proc/log_head_preview_icon(stage, icon/source_icon, preview_dir = SOUTH, extra = null)
	if(!character_setup_preview_debug_logging)
		return
	var/extra_text = extra ? " [extra]" : ""
	if(!source_icon)
		preview_debug_log("\[charsetup-head\] [stage] dir=[preview_debug_dir_name(preview_dir)] icon=null[extra_text]")
		return
	preview_debug_log("\[charsetup-head\] [stage] dir=[preview_debug_dir_name(preview_dir)] size=[source_icon.Width()]x[source_icon.Height()][extra_text]")

/datum/character_setup_panel/proc/fix_head_preview_source(icon/source_icon, preview_dir = SOUTH, debug_context = "charsetup-head charsetup_panel_head_preview")
	if(!source_icon)
		return null
	var/effective_debug_context = character_setup_preview_debug_logging ? debug_context : null
	var/icon/fixed_icon = build_fixed_character_setup_full_preview_icon(source_icon, preview_dir, 32, 40, 16, 3, effective_debug_context, preview_dir)
	if(fixed_icon)
		return fixed_icon
	return source_icon

/datum/character_setup_panel/proc/build_preview_directional_accessory_icon(customizer_type, accessory_type, target_dir = SOUTH)
	var/datum/sprite_accessory/accessory = SPRITE_ACCESSORY(accessory_type)
	if(!accessory)
		return null
	var/icon/result_icon = icon(accessory.icon, accessory.icon_state, target_dir)
	if((!result_icon || !get_preview_icon_opaque_bounds(result_icon)) && target_dir != SOUTH)
		var/icon/fallback_icon = icon(accessory.icon, accessory.icon_state)
		if(fallback_icon)
			fallback_icon = turn_preview_accessory_icon(fallback_icon, target_dir)
			if(fallback_icon)
				result_icon = fallback_icon
	if(!result_icon)
		return null
	var/datum/customizer_entry/entry = prefs.get_customizer_entry_for_customizer_type(customizer_type)
	if(istype(entry, /datum/customizer_entry/hair))
		var/datum/customizer_entry/hair/hair_entry = entry
		if(hair_entry.hair_color)
			result_icon.Blend(hair_entry.hair_color, ICON_MULTIPLY)
	else if(entry && entry.accessory_colors)
		var/list/accessory_colors = color_string_to_list(entry.accessory_colors)
		if(accessory_colors && accessory_colors.len && accessory_colors[1])
			result_icon.Blend(accessory_colors[1], ICON_MULTIPLY)
	return result_icon

/datum/character_setup_panel/proc/build_current_prefs_raw_accessory_icon(customizer_type)
	if(!prefs || !customizer_type)
		return null
	var/datum/customizer_entry/entry = prefs.get_customizer_entry_for_customizer_type(customizer_type)
	if(!entry || entry.disabled || !entry.accessory_type)
		return null
	return build_preview_directional_accessory_icon(customizer_type, entry.accessory_type, SOUTH)

/datum/character_setup_panel/proc/turn_preview_accessory_icon(icon/source_icon, target_dir)
	if(!source_icon)
		return null
	var/icon/result_icon = icon(source_icon)
	switch(target_dir)
		if(NORTH)
			result_icon.Turn(180)
		if(EAST)
			result_icon.Turn(-90)
		if(WEST)
			result_icon.Turn(90)
		else
			return result_icon
	return result_icon

/datum/character_setup_panel/proc/preview_icons_are_identical(icon/a, icon/b)
	if(!a || !b)
		return FALSE
	if(a.Width() != b.Width() || a.Height() != b.Height())
		return FALSE
	for(var/y = 1 to a.Height())
		for(var/x = 1 to a.Width())
			if("[a.GetPixel(x, y)]" != "[b.GetPixel(x, y)]")
				return FALSE
	return TRUE

/datum/character_setup_panel/proc/preview_accessory_can_match_base(accessory_type)
	var/datum/sprite_accessory/accessory = accessory_type ? SPRITE_ACCESSORY(accessory_type) : null
	var/name_text = lowertext(accessory ? "[accessory.name]" : "[accessory_type]")
	if(findtext(name_text, "bald"))
		return TRUE
	if(findtext(name_text, "none"))
		return TRUE
	if(findtext(name_text, "shaved"))
		return TRUE
	return FALSE

/datum/character_setup_panel/proc/fast_head_preview_is_valid(icon/base_head_icon, icon/result_icon, icon/overlay_icon, accessory_type, target_dir)
	if(!result_icon)
		return FALSE
	var/allow_base_match = preview_accessory_can_match_base(accessory_type)
	if(!overlay_icon && !allow_base_match)
		return FALSE
	if(result_icon.Width() < 14 || result_icon.Height() < 12)
		return FALSE
	if((target_dir == EAST || target_dir == WEST) && result_icon.Width() < 18)
		return FALSE
	if(!allow_base_match && base_head_icon)
		var/base_rsc = "[base_head_icon.RscFile()]"
		var/result_rsc = "[result_icon.RscFile()]"
		if(length(base_rsc) && length(result_rsc) && base_rsc == result_rsc)
			return FALSE
	return TRUE

/datum/character_setup_panel/proc/build_current_prefs_base_source_icon(customizer_type = null, target_dir = SOUTH)
	var/cache_key = "source|[preview_revision]|[customizer_type]|[target_dir]"
	var/icon/cached_icon = base_part_icon_cache[cache_key]
	if(cached_icon)
		return icon(cached_icon)

	var/mob/living/carbon/human/dummy/mannequin = get_preview_dummy()
	if(!mannequin)
		return null

	prepare_preview_dummy(mannequin)
	var/datum/customizer_entry/entry = null
	var/old_accessory_type = null
	var/old_disabled = FALSE
	if(customizer_type)
		entry = prefs.get_customizer_entry_for_customizer_type(customizer_type)
		if(entry)
			old_accessory_type = entry.accessory_type
			old_disabled = entry.disabled
			entry.accessory_type = null
			entry.disabled = TRUE

	prefs.copy_to(mannequin, 1, TRUE, TRUE)
	mannequin.dir = target_dir
	mannequin.rebuild_obscured_flags()
	mannequin.update_body()
	mannequin.update_hair()
	mannequin.update_body_parts(TRUE)
	if(hascall(mannequin, "regenerate_icons"))
		call(mannequin, "regenerate_icons")()
	if(hascall(mannequin, "update_icons"))
		call(mannequin, "update_icons")()

	var/icon/preview_icon = getFlatIcon(mannequin)
	if(!preview_icon)
		mannequin.rebuild_obscured_flags()
		mannequin.update_body()
		mannequin.update_hair()
		mannequin.update_body_parts(TRUE)
		if(hascall(mannequin, "regenerate_icons"))
			call(mannequin, "regenerate_icons")()
		if(hascall(mannequin, "update_icons"))
			call(mannequin, "update_icons")()
		var/icon/retry_icon = getFlatIcon(mannequin)
		if(retry_icon)
			preview_icon = retry_icon

	release_preview_dummy(mannequin)
	if(entry)
		entry.accessory_type = old_accessory_type
		entry.disabled = old_disabled
	if(!preview_icon)
		return null

	base_part_icon_cache[cache_key] = preview_icon
	return icon(preview_icon)

/datum/character_setup_panel/proc/build_fast_head_accessory_preview_icon(customizer_type, accessory_type, target_dir = SOUTH)
	var/icon/base_head_icon = get_base_part_preview_icon(customizer_type, "head", target_dir)
	if(!base_head_icon)
		return null
	var/icon/overlay_icon = build_preview_directional_accessory_icon(customizer_type, accessory_type, target_dir)
	if(!overlay_icon)
		return null
	overlay_icon = extract_character_setup_head_features_icon(overlay_icon, target_dir, character_setup_preview_debug_logging ? "charsetup-head charsetup_panel_fast_head_overlay_band" : null, target_dir)
	if(!overlay_icon)
		return null

	log_head_preview_icon("charsetup_panel fast base_head_band", base_head_icon, target_dir, "customizer=[customizer_type]")
	log_head_preview_icon("charsetup_panel fast overlay_head_band", overlay_icon, target_dir, "accessory=[accessory_type]")

	var/icon/result_icon = icon(base_head_icon)
	result_icon.Blend(overlay_icon, ICON_OVERLAY)
	log_head_preview_icon("charsetup_panel fast blended_head_band", result_icon, target_dir, "customizer=[customizer_type] accessory=[accessory_type]")

	if(!fast_head_preview_is_valid(base_head_icon, result_icon, overlay_icon, accessory_type, target_dir))
		log_head_preview_icon("charsetup_panel fast sanity_failed", result_icon, target_dir, "customizer=[customizer_type] accessory=[accessory_type]")
		return null
	return result_icon

/datum/character_setup_panel/proc/build_current_prefs_preview_icon(preview_focus, target_dir = SOUTH)
	var/icon/preview_icon = build_current_prefs_base_source_icon(null, target_dir)
	if(!preview_icon || preview_icon_seems_broken(preview_icon, preview_focus))
		return null
	if(preview_focus == "full")
		var/icon/fixed_full_preview_icon = build_fixed_character_setup_full_preview_icon(preview_icon, target_dir, 32, 40, 16, 3, character_setup_preview_debug_logging ? "charsetup_preview" : null, target_dir)
		if(fixed_full_preview_icon)
			preview_icon = fixed_full_preview_icon
	else if(preview_focus == "head")
		log_head_preview_icon("charsetup_panel base_source_before_head_band", preview_icon, target_dir)
		var/icon/head_band_icon = extract_character_setup_head_features_icon(preview_icon, target_dir, character_setup_preview_debug_logging ? "charsetup-head charsetup_panel_head_band" : null, target_dir)
		if(head_band_icon)
			preview_icon = head_band_icon
		log_head_preview_icon("charsetup_panel base_after_head_band", preview_icon, target_dir)
	else
		apply_preview_focus(preview_icon, preview_focus)
	return preview_icon
/datum/character_setup_panel/proc/build_active_customizer_payload(mob/user)
	ensure_active_customizer()
	if(!active_customizer_type)
		return null

	var/payload_cache_key = "[active_customizer_payload_generation]|[active_customizer_type]|[customizer_filter]|[customizer_window_start]|[customizer_window_size]"
	if(payload_cache_key == cached_active_customizer_payload_key && cached_active_customizer_payload)
		return cached_active_customizer_payload

	var/datum/customizer/customizer = CUSTOMIZER(active_customizer_type)
	var/datum/customizer_entry/entry = ensure_customizer_entry(active_customizer_type)
	if(!customizer || !entry)
		return null

	var/datum/customizer_choice/choice = CUSTOMIZER_CHOICE(entry.customizer_choice_type)
	var/datum/sprite_accessory/current_accessory = entry.accessory_type ? SPRITE_ACCESSORY(entry.accessory_type) : null
	var/current_group = customizer_group(customizer)
	var/is_hair_entry = istype(entry, /datum/customizer_entry/hair)

	var/list/all_options = list()
	if(choice && choice.sprite_accessories)
		for(var/accessory_type as anything in choice.sprite_accessories)
			var/datum/sprite_accessory/accessory = SPRITE_ACCESSORY(accessory_type)
			if(!accessory)
				continue
			all_options += list(list(
				id = "[accessory_type]",
				name = accessory.name,
				icon = accessory.icon,
				icon_state = accessory.icon_state
			))

	var/list/filtered_options = list()
	var/filter_text = lowertext(customizer_filter)
	for(var/list/option in all_options)
		var/option_name = lowertext("[option["name"]]")
		if(!length(filter_text) || findtext(option_name, filter_text))
			filtered_options += list(option)

	var/list/choice_groups = list()
	if(customizer.customizer_choices)
		for(var/choice_type as anything in customizer.customizer_choices)
			var/datum/customizer_choice/iter_choice = CUSTOMIZER_CHOICE(choice_type)
			if(!iter_choice)
				continue
			choice_groups += list(list(
				id = "[choice_type]",
				name = iter_choice.name,
				current = (choice_type == entry.customizer_choice_type)
			))

	var/list/visible_options = list()
	var/window_start = max(1, customizer_window_start)
	if(filtered_options.len < window_start)
		window_start = max(1, filtered_options.len - customizer_window_size + 1)
	var/window_end = min(filtered_options.len, window_start + customizer_window_size - 1)
	var/preview_focus = get_customizer_preview_focus(customizer)
	var/list/head_base_assets_by_dir = null
	if(preview_focus == "head" && is_hair_entry)
		head_base_assets_by_dir = generate_head_base_preview_assets_by_dir(user)
	if(filtered_options.len)
		if(current_group == "simple")
			for(var/list/option in filtered_options)
				visible_options += list(option.Copy())
		else
			for(var/i in window_start to window_end)
				var/list/option = filtered_options[i]
				var/list/option_copy = option.Copy()
				var/option_accessory_type = text2path(option_copy["id"])
				if(option_accessory_type)
					var/option_preview_focus = preview_focus
					if(preview_focus == "head" && is_hair_entry)
						option_preview_focus = "head_overlay"
					if(preview_focus == "head")
						var/list/preview_assets_by_dir = generate_customizer_option_preview_assets_by_dir(user, active_customizer_type, option_accessory_type, option_preview_focus)
						option_copy["preview_assets_by_dir"] = preview_assets_by_dir
						option_copy["preview_asset"] = preview_assets_by_dir ? preview_assets_by_dir["SOUTH"] : null
					else
						option_copy["preview_asset"] = generate_customizer_option_preview_asset(user, active_customizer_type, option_accessory_type, option_preview_focus)
				visible_options += list(option_copy)

	var/list/payload = list(
		id = "[active_customizer_type]",
		name = translate_customizer_name(customizer.name),
		disabled = entry.disabled,
		allows_disabling = customizer.allows_disabling,
		can_change_choice = length(customizer.customizer_choices) > 1,
		choice_name = choice ? choice.name : "Нет",
		choice_groups = choice_groups,
		current_accessory_name = current_accessory ? current_accessory.name : "Нет",
		selected_accessory_id = entry.accessory_type ? "[entry.accessory_type]" : null,
		option_count = all_options.len,
		total_filtered = filtered_options.len,
		window_start = window_start,
		window_size = customizer_window_size,
		search_query = customizer_filter,
		options = visible_options,
		allows_accessory_color_customization = choice ? choice.allows_accessory_color_customization : FALSE,
		group = current_group
	)

	if(choice && choice.allows_accessory_color_customization && entry.accessory_type)
		var/datum/sprite_accessory/accessory = SPRITE_ACCESSORY(entry.accessory_type)
		if(accessory)
			var/list/color_labels = list()
			var/list/color_values = color_string_to_list(entry.accessory_colors)
			for(var/index in 1 to accessory.color_keys)
				var/named_index = (accessory.color_keys == 1) ? accessory.color_key_name : accessory.color_key_names[index]
				color_labels += named_index
			payload["accessory_color_labels"] = color_labels
			payload["accessory_color_values"] = color_values

	if(istype(entry, /datum/customizer_entry/hair))
		var/datum/customizer_entry/hair/hair_entry = entry
		payload["is_hair"] = TRUE
		if(preview_focus == "head" && head_base_assets_by_dir)
			payload["head_base_assets_by_dir"] = head_base_assets_by_dir
			payload["overlay_offset_y"] = 1
		payload["hair_color"] = hair_entry.hair_color
		payload["natural_gradient"] = hair_gradient_label(hair_entry.natural_gradient)
		payload["natural_color"] = hair_entry.natural_color
		payload["dye_gradient"] = hair_gradient_label(hair_entry.dye_gradient)
		payload["dye_color"] = hair_entry.dye_color

	cached_active_customizer_payload_key = payload_cache_key
	cached_active_customizer_payload = payload
	return payload

/proc/strip_character_setup_simple_html_tags(text)
	if(isnull(text))
		return text
	var/result = "[text]"
	var/start = findtext(result, "<")
	while(start)
		var/end = findtext(result, ">", start + 1)
		if(!end)
			break
		result = copytext(result, 1, start) + copytext(result, end + 1)
		start = findtext(result, "<")
	return result

/proc/sanitize_character_setup_job_panel_text(value)
	if(isnull(value))
		return null
	var/original_text = "[value]"
	if(!length(original_text))
		return original_text

	var/static/list/job_panel_text_cache = list()
	if(original_text in job_panel_text_cache)
		return job_panel_text_cache[original_text]

	var/text = original_text
	if(findtext(text, "<") || findtext(text, "&nbsp;") || findtext(text, ascii2text(13)) || findtext(text, "\n\n\n"))
		text = replacetext(text, "<br>", "\n")
		text = replacetext(text, "<br/>", "\n")
		text = replacetext(text, "<br />", "\n")
		text = replacetext(text, "&nbsp;", " ")
		if(findtext(text, "<"))
			text = strip_character_setup_simple_html_tags(text)
		if(findtext(text, ascii2text(13)))
			text = replacetext(text, ascii2text(13), "")
		while(findtext(text, "\n\n\n"))
			text = replacetext(text, "\n\n\n", "\n\n")

	if(length(job_panel_text_cache) > 2048)
		job_panel_text_cache = list()
	job_panel_text_cache[original_text] = text
	return text

/datum/character_setup_panel/proc/build_job_entries_cache_key(mob/user)
	var/list/key_parts = list()
	key_parts += "ckey=[user?.ckey]"
	key_parts += "slot=[prefs.loaded_slot]"
	key_parts += "species=[prefs.pref_species ? prefs.pref_species.type : null]"
	key_parts += "gender=[prefs.gender]"
	key_parts += "age=[prefs.age]"
	key_parts += "titles=[prefs.titles_pref]"
	key_parts += "pronouns=[prefs.pronouns]"
	key_parts += "statpack=[prefs.statpack ? prefs.statpack.type : null]"
	key_parts += "jobs=[list2params(prefs.job_preferences)]"
	key_parts += "jobchars=[list2params(prefs.job_characters)]"
	return key_parts.Join("|")

/datum/character_setup_panel/proc/build_job_entries(mob/user)
	var/list/output = list()
	if(!SSjob || !user || !user.client)
		return output

	var/cache_key = build_job_entries_cache_key(user)
	if(cache_key == cached_job_entries_key && cached_job_entries)
		return cached_job_entries

	var/static/list/acceptable_unavailables = list(JOB_AVAILABLE, JOB_UNAVAILABLE_SLOTFULL)
	var/static/list/split_jobs = list("Court Magician", "Bishop", "Merchant", "Archivist", "Towner", "Grenzelhoft Mercenary", "Beggar", "Prisoner", "Goblin King")
	var/column_limit = 14
	var/current_column = 1
	var/current_index = -1
	var/player_quality = null
	#ifdef USES_PQ
	player_quality = get_playerquality(user.ckey)
	#endif

	for(var/datum/job/job in sortList(SSjob.occupations, GLOBAL_PROC_REF(cmp_job_display_asc)))
		if(!job.spawn_positions && !job.always_show_on_latechoices)
			continue

		current_index += 1
		if(current_index >= column_limit)
			current_column += 1
			current_index = 0

		var/rank = job.title
		var/used_name = job.display_title ? job.display_title : job.title
		if((prefs.titles_pref == TITLES_F) && job.f_title)
			used_name = "[job.f_title]"

		var/disabled_reason = null
		if(is_banned_from(user.ckey, rank))
			disabled_reason = "Забанено"
		else
			var/required_playtime_remaining = job.required_playtime_remaining(user.client)
			if(required_playtime_remaining)
				disabled_reason = "[get_exp_format(required_playtime_remaining)] как [job.get_exp_req_type()]"
			else if(!job.player_old_enough(user.client))
				var/available_in_days = job.available_in_days(user.client)
				disabled_reason = "Доступно через [available_in_days] дн."
			else
				#ifdef USES_PQ
				if(!isnull(job.min_pq) && !isnull(player_quality) && (player_quality < job.min_pq))
					disabled_reason = "Мин. PQ: [job.min_pq]"
				else if(!isnull(job.max_pq) && !isnull(player_quality) && (player_quality > job.max_pq))
					disabled_reason = "Макс. PQ: [job.max_pq]"
				#endif
				if(!disabled_reason)
					var/datum/preferences/char_prefs = prefs.get_job_prefs(rank)
					if(!job.validate_prefs_for_job(char_prefs))
						disabled_reason = "Неподходящий персонаж"
					else
						var/job_unavailable_status = JOB_AVAILABLE
						if(isnewplayer(user))
							var/mob/dead/new_player/new_player = user
							job_unavailable_status = new_player.IsJobUnavailable(job.title, latejoin = FALSE)
						if(!(job_unavailable_status in acceptable_unavailables))
							disabled_reason = "Недоступно сейчас"

		var/tutorial_text = job.tutorial ? sanitize_character_setup_job_panel_text(job.tutorial) : ""
		var/list/tooltip_parts = list()
		if(tutorial_text)
			tooltip_parts += tutorial_text
		tooltip_parts += "Слоты: [job.spawn_positions]"
		if(job.round_contrib_points)
			tooltip_parts += "RCP: +[job.round_contrib_points]"

		output += list(list(
			id = rank,
			name = used_name,
			current_pref = job_pref_key(rank),
			current_pref_label = job_pref_label(rank),
			disabled_reason = disabled_reason,
			tutorial = tutorial_text,
			slots = job.spawn_positions,
			round_contrib_points = job.round_contrib_points,
			has_details = !!job.class_setup_examine,
			tooltip = jointext(tooltip_parts, "\n"),
			assigned_slot = prefs.job_characters[rank] ? "Слот [prefs.job_characters[rank]]" : "Активный слот",
			column = current_column,
			separator_before = (rank in split_jobs)
		))
	cached_job_entries = output
	cached_job_entries_key = cache_key
	return output

/datum/character_setup_panel/proc/build_job_slot_choices_cache_key(job_title)
	if(!prefs || !job_title)
		return null
	var/list/key_parts = list()
	key_parts += "job=[job_title]"
	key_parts += "loaded=[prefs.loaded_slot]"
	key_parts += "species=[prefs.pref_species]"
	key_parts += "gender=[prefs.gender]"
	key_parts += "age=[prefs.age]"
	key_parts += "statpack=[prefs.statpack]"
	key_parts += "titles=[prefs.titles_pref]"
	key_parts += "jobchars=[list2params(prefs.job_characters)]"
	return jointext(key_parts, "&")

/datum/character_setup_panel/proc/build_job_slot_choices(job_title)
	var/list/output = list()
	if(!prefs || !job_title)
		return output
	var/cache_key = build_job_slot_choices_cache_key(job_title)
	if(cache_key == cached_job_slot_choices_key && islist(cached_job_slot_choices))
		return cached_job_slot_choices
	var/datum/job/J = SSjob ? SSjob.GetJob(job_title) : null
	if(!J)
		return output
	if(!prefs.path || !fexists(prefs.path))
		output += list(list(id = "default", label = "Активный слот", current = !prefs.job_characters[job_title]))
		cached_job_slot_choices = output
		cached_job_slot_choices_key = cache_key
		return output

	output += list(list(id = "default", label = "Активный слот", current = !prefs.job_characters[job_title]))
	var/savefile/S = new /savefile(prefs.path)
	var/datum/preferences/dummy_pref = new(prefs.parent)
	for(var/i = 1 to prefs.max_save_slots)
		if(i % 5 == 0)
			CHECK_TICK
		dummy_pref.fast_scan_for_job(S, i)
		if(J.validate_prefs_for_job(dummy_pref))
			var/label = "Слот [i] - [dummy_pref.real_name] ([dummy_pref.pref_species.name])"
			output += list(list(id = "[i]", label = label, current = (prefs.job_characters[job_title] == i)))
	qdel(dummy_pref)
	cached_job_slot_choices = output
	cached_job_slot_choices_key = cache_key
	return output


/datum/character_setup_panel/proc/build_antag_role_entries(mob/user)
	var/list/output = list()
	if(!user || !user.client)
		return output

	var/global_antag_ban = is_banned_from(user.ckey, ROLE_SYNDICATE)
	if(global_antag_ban)
		prefs.be_special = list()

	for(var/role_id in GLOB.special_roles_rogue)
		var/disabled_reason = null
		if(global_antag_ban || is_banned_from(user.ckey, role_id))
			disabled_reason = "BANNED"
		else
			var/days_remaining = null
			if(ispath(GLOB.special_roles_rogue[role_id]) && CONFIG_GET(flag/use_age_restriction_for_jobs))
				days_remaining = get_remaining_days(user.client)
			if(days_remaining)
				disabled_reason = "IN [days_remaining] DAYS"

		output += list(list(
			id = "[role_id]",
			name = capitalize("[role_id]"),
			enabled = (role_id in prefs.be_special),
			disabled_reason = disabled_reason
		))
	return output

/datum/character_setup_panel/proc/build_keybinding_categories()
	var/list/list/user_binds = list()
	for(var/key in prefs.key_bindings)
		for(var/kb_name in prefs.key_bindings[key])
			if(!islist(user_binds[kb_name]))
				user_binds[kb_name] = list()
			var/list/bind_keys = user_binds[kb_name]
			bind_keys += key

	var/list/grouped = list()
	for(var/name in GLOB.keybindings_by_name)
		var/datum/keybinding/kb = GLOB.keybindings_by_name[name]
		if(!kb)
			continue
		var/category_name = "[kb.category]"
		if(!grouped[category_name])
			grouped[category_name] = list()
		var/list/bound_keys = user_binds[kb.name]
		grouped[category_name] += list(list(
			id = "[kb.name]",
			label = kb.full_name ? kb.full_name : kb.name,
			keys = bound_keys ? bound_keys.Copy() : list()
		))

	var/list/output = list()
	for(var/category_name in grouped)
		output += list(list(
			name = category_name,
			bindings = grouped[category_name]
		))
	return output

/datum/character_setup_panel/proc/build_origin_choices()
	var/list/output = list()
	for(var/path as anything in GLOB.virtues)
		var/datum/virtue/V = GLOB.virtues[path]
		if(!V.name)
			continue
		if(!istype(V, /datum/virtue/origin))
			continue
		if(V.restricted == TRUE)
			if((prefs.pref_species.type in V.races))
				continue
		if(istype(V, /datum/virtue/origin/racial))
			if(!(prefs.pref_species.type in V.races))
				continue
		var/description = ""
		if(V.origin_desc)
			description = "[V.origin_desc]"
		else if(V.desc)
			description = "[V.desc]"
		output += list(list(
			id = "[path]",
			name = V.name,
			description = description,
			current = (V.name == prefs.virtue_origin.name)
		))
	return output


/datum/character_setup_panel/proc/make_selector_option(id, name, description = null, meta = null, current = FALSE, group = null, icon = null, icon_state = null, preview_asset = null)
	var/list/output = list(
		id = "[id]",
		name = "[name]"
	)
	if(!isnull(description) && length("[description]"))
		output["description"] = "[description]"
	if(!isnull(meta) && length("[meta]"))
		output["meta"] = "[meta]"
	if(current)
		output["current"] = TRUE
	if(!isnull(group) && length("[group]"))
		output["group"] = "[group]"
	if(!isnull(icon))
		output["icon"] = icon
	if(!isnull(icon_state))
		output["icon_state"] = icon_state
	if(!isnull(preview_asset) && length("[preview_asset]"))
		output["preview_asset"] = "[preview_asset]"
	return output

/datum/character_setup_panel/proc/build_context_selectors_payload()
	var/list/output = list()

	var/list/age_options = list()
	for(var/age_option in prefs.pref_species.possible_ages)
		age_options += list(make_selector_option("[age_option]", "[age_option]", null, null, prefs.age == age_option))
	output["age"] = list(
		title = "Возраст",
		current = "[prefs.age]",
		options = age_options
	)

	var/list/skin_tone_options = list()
	var/list/skin_list = prefs.pref_species?.get_skin_list()
	var/current_skin_label = prefs.skin_tone ? "[prefs.skin_tone]" : "Не задан"
	if(islist(skin_list))
		for(var/skin_name in skin_list)
			var/skin_value = skin_list[skin_name]
			if(skin_value == prefs.skin_tone)
				current_skin_label = "[skin_name]"
			skin_tone_options += list(make_selector_option("[skin_name]", "[skin_name]", null, null, skin_value == prefs.skin_tone))
	output["skin_tone"] = list(
		title = "Цвет кожи",
		current = current_skin_label,
		options = skin_tone_options
	)

	var/list/voice_pack_options = list()
	for(var/voice_pack_name in GLOB.voice_packs_list)
		voice_pack_options += list(make_selector_option(voice_pack_name, voice_pack_name, null, null, voice_pack_name == prefs.voice_pack))
	output["voicepack"] = list(
		title = "Голосовой пак",
		current = prefs.voice_pack ? "[prefs.voice_pack]" : "Default",
		options = voice_pack_options
	)

	var/list/accent_options = list()
	for(var/accent_name in GLOB.character_accents)
		accent_options += list(make_selector_option(accent_name, accent_name, null, null, accent_name == prefs.char_accent))
	output["char_accent"] = list(
		title = "Акцент",
		current = prefs.char_accent ? "[prefs.char_accent]" : "No accent",
		options = accent_options
	)

	var/static/list/selectable_languages = list(
		/datum/language/elvish,
		/datum/language/dwarvish,
		/datum/language/orcish,
		/datum/language/hellspeak,
		/datum/language/draconic,
		/datum/language/raneshi,
		/datum/language/grenzelhoftian,
		/datum/language/kazengunese,
		/datum/language/lingyuese,
		/datum/language/gyedzenese,
		/datum/language/valorian,
		/datum/language/etruscan,
		/datum/language/gronnic,
		/datum/language/otavan,
		/datum/language/aavnic,
	)
	var/list/language_options = list(make_selector_option("None", "None", null, null, prefs.extra_language == "None"))
	for(var/language_type in selectable_languages)
		if(language_type in prefs.pref_species.languages)
			continue
		var/datum/language/language = new language_type()
		var/lang_desc = null
		if(language?.desc)
			lang_desc = "[language.desc]"
		language_options += list(make_selector_option("[language_type]", language.name, lang_desc, null, prefs.extra_language == language_type))
	var/current_language_name = "None"
	if(ispath(prefs.extra_language, /datum/language))
		var/datum/language/current_language_type = prefs.extra_language
		current_language_name = initial(current_language_type.name)
	output["extra_language"] = list(
		title = "Дополнительный язык",
		current = current_language_name,
		options = language_options
	)

	var/list/combat_music_options = list()
	var/current_combat_music_name = prefs.combat_music ? (prefs.combat_music.shortname ? prefs.combat_music.shortname : prefs.combat_music.name) : "Default"
	for(var/track_name in GLOB.cmode_tracks_by_name)
		var/datum/combat_music/track = GLOB.cmode_tracks_by_name[track_name]
		var/meta = null
		if(track?.shortname && track.shortname != track_name)
			meta = "[track.shortname]"
		combat_music_options += list(make_selector_option(track_name, track_name, null, meta, prefs.combat_music == track))
	output["combat_music"] = list(
		title = "Боевая музыка",
		current = current_combat_music_name,
		options = combat_music_options
	)

	var/list/taur_options = list(make_selector_option("None", "None", null, null, isnull(prefs.taur_type)))
	for(var/obj/item/bodypart/taur/taur_type as anything in prefs.pref_species.get_taur_list())
		taur_options += list(make_selector_option("[taur_type]", taur_label(taur_type), null, null, prefs.taur_type == taur_type))
	output["taur_type"] = list(
		title = "Таур-тело",
		current = taur_label(prefs.taur_type),
		options = taur_options
	)

	var/list/statpack_options = list()
	for(var/path as anything in GLOB.statpacks)
		var/datum/statpack/statpack = GLOB.statpacks[path]
		if(!statpack?.name)
			continue
		var/meta = null
		if(length(statpack.stat_array))
			meta = "[statpack.generate_modifier_string()]"
		var/description = null
		if(hascall(statpack, "description_string"))
			description = call(statpack, "description_string")()
		statpack_options += list(make_selector_option("[path]", statpack.name, description, meta, prefs.statpack?.type == path))
	output["statpack"] = list(
		title = "Статпак",
		current = prefs.statpack ? prefs.statpack.name : "None",
		options = statpack_options
	)

	var/datum/faith/selected_faith = prefs.selected_patron ? GLOB.faithlist[prefs.selected_patron.associated_faith] : null
	var/list/faith_options = list()
	for(var/path as anything in GLOB.preference_faiths)
		var/datum/faith/faith = GLOB.faithlist[path]
		if(!faith?.name)
			continue
		faith_options += list(make_selector_option("[path]", faith.name, faith.desc, faith.worshippers, selected_faith == faith))
	output["faith"] = list(
		title = "Вера",
		current = selected_faith ? selected_faith.name : "None",
		options = faith_options
	)

	var/current_faith = prefs.selected_patron ? prefs.selected_patron.associated_faith : initial(prefs.default_patron.associated_faith)
	var/list/patron_options = list()
	for(var/path as anything in GLOB.patrons_by_faith[current_faith])
		var/datum/patron/patron = GLOB.patronlist[path]
		if(!patron?.name)
			continue
		patron_options += list(make_selector_option("[path]", patron.name, patron.desc, patron.domain, prefs.selected_patron == patron))
	output["patron"] = list(
		title = "Покровитель",
		current = prefs.selected_patron ? prefs.selected_patron.name : "None",
		options = patron_options
	)

	output["virtue_primary"] = list(
		title = "Особенность",
		current = prefs.virtue ? prefs.virtue.name : "None",
		options = build_virtue_options_payload(TRUE)
	)
	output["virtue_secondary"] = list(
		title = "Вторая особенность",
		current = prefs.virtuetwo ? prefs.virtuetwo.name : "None",
		options = build_virtue_options_payload(FALSE)
	)

	return output

/datum/character_setup_panel/proc/build_virtue_options_payload(primary = TRUE)
	var/list/output = list()
	for(var/path as anything in GLOB.virtues)
		var/datum/virtue/V = GLOB.virtues[path]
		if(!V?.name)
			continue
		if((V.name == prefs.virtue?.name || V.name == prefs.virtuetwo?.name) && !istype(V, /datum/virtue/none))
			if(!V.stackable)
				continue
		if(istype(V, /datum/virtue/origin))
			continue
		if(V.unlisted)
			continue
		if(istype(V, /datum/virtue/heretic) && !istype(prefs.selected_patron, /datum/patron/inhumen))
			continue
		if(V.restricted == TRUE)
			if((prefs.pref_species.type in V.races))
				continue
		if(primary && V.virtuous_only && !prefs.statpack.virtuous)
			continue
		output += list(make_selector_option("[path]", V.name, V.desc, null, primary ? (prefs.virtue?.type == path) : (prefs.virtuetwo?.type == path)))
	return output

/datum/character_setup_panel/proc/build_vice_options_payload()
	var/list/output = list()
	for(var/key in GLOB.character_flaws)
		var/flaw_type = GLOB.character_flaws[key]
		if(flaw_type == /datum/charflaw/noflaw)
			continue
		var/selected = FALSE
		for(var/datum/charflaw/cf as anything in prefs.charflaws)
			if(istype(cf, /datum/charflaw/noflaw))
				continue
			if(cf.type == flaw_type)
				selected = TRUE
				break
		var/datum/charflaw/flaw_preview = new flaw_type()
		var/description = null
		if(flaw_preview?.desc)
			description = flaw_preview.desc
		output += list(list(
			id = "[flaw_type]",
			name = flaw_preview?.name ? flaw_preview.name : "[key]",
			description = description,
			selected = selected
		))
	return output

/datum/character_setup_panel/proc/build_descriptor_editor_payload()
	if(hascall(prefs, "validate_descriptors"))
		call(prefs, "validate_descriptors")()
	var/list/output = list(
		entries = list(),
		custom_entries = list()
	)
	for(var/choice_type in prefs.pref_species.descriptor_choices)
		var/datum/descriptor_choice/choice = DESCRIPTOR_CHOICE(choice_type)
		if(!choice)
			continue
		var/datum/descriptor_entry/entry = null
		if(hascall(prefs, "get_descriptor_entry_for_choice"))
			entry = call(prefs, "get_descriptor_entry_for_choice")(choice_type)
		var/datum/mob_descriptor/current_descriptor = entry ? MOB_DESCRIPTOR(entry.descriptor_type) : null
		var/list/options = list()
		for(var/desc_type in choice.descriptors)
			var/datum/mob_descriptor/descriptor = MOB_DESCRIPTOR(desc_type)
			if(!descriptor)
				continue
			options += list(make_selector_option("[desc_type]", descriptor.name, null, null, entry?.descriptor_type == desc_type))
		output["entries"] += list(list(
			id = "[choice_type]",
			name = choice.name,
			value = current_descriptor ? current_descriptor.name : "None",
			options = options
		))

	var/static/list/translation = CUSTOM_PREFIX_TRANSLATION_LIST
	var/static/list/input_list = CUSTOM_PREFIX_INPUT_LIST
	var/list/prefix_options = list()
	for(var/prefix_name in input_list)
		prefix_options += list(make_selector_option("[input_list[prefix_name]]", prefix_name))
	for(var/i in 1 to CUSTOM_DESCRIPTOR_AMOUNT)
		var/visible = FALSE
		if(i == 1)
			if(hascall(prefs, "has_descriptor_type_in_entries"))
				visible = call(prefs, "has_descriptor_type_in_entries")(/datum/mob_descriptor/prominent/custom/one)
		else if(i == 2)
			if(hascall(prefs, "has_descriptor_type_in_entries"))
				visible = call(prefs, "has_descriptor_type_in_entries")(/datum/mob_descriptor/prominent/custom/two)
		var/datum/custom_descriptor_entry/custom_entry = length(prefs.custom_descriptors) >= i ? prefs.custom_descriptors[i] : null
		output["custom_entries"] += list(list(
			index = i,
			visible = visible,
			prefix_id = custom_entry ? "[custom_entry.prefix_type]" : "[CUSTOM_PREFIX_HAS_A]",
			prefix_label = custom_entry ? translation["[custom_entry.prefix_type]"] : translation["[CUSTOM_PREFIX_HAS_A]"],
			content = custom_entry?.content_text ? "[custom_entry.content_text]" : "",
			prefix_options = prefix_options
		))
	return output

/datum/character_setup_panel/proc/build_food_options_payload()
	var/list/output = list()
	for(var/list/food_data in GLOB.food_with_faretypes)
		var/atom/food_type = food_data["type"]
		var/food_name = food_data["name"]
		var/food_faretype = food_data["faretype"]
		var/food_icon = initial(food_type.icon)
		var/food_icon_state = initial(food_type.icon_state)
		output += list(make_selector_option("[food_type]", capitalize(food_name), null, "Quality: [food_faretype]", FALSE, "food", food_icon, food_icon_state))
	return output

/datum/character_setup_panel/proc/build_drink_options_payload()
	var/list/output = list()
	for(var/list/drink_data in GLOB.drink_with_qualities)
		var/drink_type = drink_data["type"]
		var/drink_name = drink_data["name"]
		var/drink_quality = drink_data["quality"]
		output += list(make_selector_option("[drink_type]", capitalize(drink_name), null, "Quality: [drink_quality]", FALSE, "drink"))
	return output

/datum/character_setup_panel/proc/build_culinary_editor_payload()
	if(hascall(prefs, "validate_culinary_preferences"))
		call(prefs, "validate_culinary_preferences")()
	var/list/food_options = build_food_options_payload()
	var/list/drink_options = build_drink_options_payload()
	var/current_food = prefs.culinary_preferences ? prefs.culinary_preferences[CULINARY_FAVOURITE_FOOD] : null
	var/current_drink = prefs.culinary_preferences ? prefs.culinary_preferences[CULINARY_FAVOURITE_DRINK] : null
	var/current_hated_food = prefs.culinary_preferences ? prefs.culinary_preferences[CULINARY_HATED_FOOD] : null
	var/current_hated_drink = prefs.culinary_preferences ? prefs.culinary_preferences[CULINARY_HATED_DRINK] : null
	var/current_food_name = "None"
	if(current_food)
		var/obj/item/food_instance = current_food
		current_food_name = capitalize(initial(food_instance.name))
	var/current_drink_name = "None"
	if(current_drink)
		var/datum/reagent/consumable/drink_instance = current_drink
		current_drink_name = capitalize(initial(drink_instance.name))
	var/current_hated_food_name = "None"
	if(current_hated_food)
		var/obj/item/hated_food_instance = current_hated_food
		current_hated_food_name = capitalize(initial(hated_food_instance.name))
	var/current_hated_drink_name = "None"
	if(current_hated_drink)
		var/datum/reagent/consumable/hated_drink_instance = current_hated_drink
		current_hated_drink_name = capitalize(initial(hated_drink_instance.name))
	return list(
		entries = list(
			list(key = CULINARY_FAVOURITE_FOOD, label = "Любимая еда", value = current_food_name, mode = "food", options = food_options),
			list(key = CULINARY_FAVOURITE_DRINK, label = "Любимый напиток", value = current_drink_name, mode = "drink", options = drink_options),
			list(key = CULINARY_HATED_FOOD, label = "Нелюбимая еда", value = current_hated_food_name, mode = "food", options = food_options),
			list(key = CULINARY_HATED_DRINK, label = "Нелюбимый напиток", value = current_hated_drink_name, mode = "drink", options = drink_options)
		)
	)

/datum/character_setup_panel/proc/build_familiar_editor_payload(mob/user)
	var/datum/familiar_prefs/fam = prefs.familiar_prefs
	if(!fam)
		return list(
			familiar_name = "",
			familiar_pronouns = "they/them",
			familiar_pronoun_id = "[THEY_THEM]",
			familiar_headshot_link = "",
			familiar_flavortext = "",
			familiar_ooc_notes = "",
			familiar_ooc_extra_link = "",
			familiar_specie = "None selected",
			familiar_specie_id = "",
			queue_joined = FALSE,
			lore_blurb = "",
			pronoun_options = list(),
			species_options = list()
		)
	var/list/pronoun_display = list(
		"[HE_HIM]" = "he/him",
		"[SHE_HER]" = "she/her",
		"[THEY_THEM]" = "they/them",
		"[IT_ITS]" = "it/its"
	)
	var/list/pronoun_options = list(
		make_selector_option("[HE_HIM]", "he/him", null, null, fam.familiar_pronouns == HE_HIM),
		make_selector_option("[SHE_HER]", "she/her", null, null, fam.familiar_pronouns == SHE_HER),
		make_selector_option("[THEY_THEM]", "they/them", null, null, fam.familiar_pronouns == THEY_THEM),
		make_selector_option("[IT_ITS]", "it/its", null, null, fam.familiar_pronouns == IT_ITS)
	)
	var/list/species_options = list()
	var/current_species_name = "None selected"
	for(var/species_name in GLOB.familiar_types)
		var/species_type = GLOB.familiar_types[species_name]
		if(species_type == fam.familiar_specie)
			current_species_name = species_name
		var/species_desc = GLOB.familiar_lore_blurbs[species_type]
		species_options += list(make_selector_option("[species_type]", species_name, species_desc, null, species_type == fam.familiar_specie))
	var/queue_joined = FALSE
	if(user?.client && (user.client in GLOB.familiar_queue))
		queue_joined = TRUE
	return list(
		familiar_name = fam.familiar_name ? fam.familiar_name : "",
		familiar_pronouns = pronoun_display["[fam.familiar_pronouns]"] ? pronoun_display["[fam.familiar_pronouns]"] : "they/them",
		familiar_pronoun_id = "[fam.familiar_pronouns]",
		familiar_headshot_link = fam.familiar_headshot_link ? fam.familiar_headshot_link : "",
		familiar_flavortext = fam.familiar_flavortext ? fam.familiar_flavortext : "",
		familiar_ooc_notes = fam.familiar_ooc_notes ? fam.familiar_ooc_notes : "",
		familiar_ooc_extra_link = fam.familiar_ooc_extra_link ? fam.familiar_ooc_extra_link : "",
		familiar_specie = current_species_name,
		familiar_specie_id = fam.familiar_specie ? "[fam.familiar_specie]" : "",
		queue_joined = queue_joined,
		lore_blurb = fam.familiar_specie ? (GLOB.familiar_lore_blurbs[fam.familiar_specie] || "") : "",
		pronoun_options = pronoun_options,
		species_options = species_options
	)

/datum/character_setup_panel/proc/infer_job_group(datum/job/job)
	if(!job)
		return "Прочее"

	var/title = lowertext("[job.title]")
	var/path_text = lowertext("[job.type]")
	var/search_blob = "[title] [path_text]"

	if(findtext(search_blob, "lord") || findtext(search_blob, "duchess") || findtext(search_blob, "prince") || findtext(search_blob, "princess") || findtext(search_blob, "hand") || findtext(search_blob, "steward") || findtext(search_blob, "councillor") || findtext(search_blob, "clerk") || findtext(search_blob, "jester") || findtext(search_blob, "archivist") || findtext(search_blob, "seneschal") || findtext(search_blob, "marshal") || findtext(search_blob, "court magician"))
		return "Двор и власть"

	if(findtext(search_blob, "knight") || findtext(search_blob, "squire") || findtext(search_blob, "sergeant") || findtext(search_blob, "man at arms") || findtext(search_blob, "warden") || findtext(search_blob, "guard") || findtext(search_blob, "manorguard") || findtext(search_blob, "sheriff") || findtext(search_blob, "watch") || findtext(search_blob, "overseer") || findtext(search_blob, "vanguard") || findtext(search_blob, "mercenary") || findtext(search_blob, "veteran") || findtext(search_blob, "bailiff") || findtext(search_blob, "dungeoneer"))
		return "Стража и войско"

	if(findtext(search_blob, "bishop") || findtext(search_blob, "martyr") || findtext(search_blob, "templar") || findtext(search_blob, "druid") || findtext(search_blob, "acolyte") || findtext(search_blob, "sexton") || findtext(search_blob, "priest") || findtext(search_blob, "monk") || findtext(search_blob, "inquisitor") || findtext(search_blob, "orthodox") || findtext(search_blob, "absolver"))
		return "Церковь"

	if(findtext(search_blob, "physician") || findtext(search_blob, "courtphysician") || findtext(search_blob, "apothecary"))
		return "Лекари"

	if(findtext(search_blob, "magician") || findtext(search_blob, "wapprentice"))
		return "Мистика и учёные"

	if(findtext(search_blob, "merchant") || findtext(search_blob, "guildmaster") || findtext(search_blob, "guildsman") || findtext(search_blob, "tailor") || findtext(search_blob, "shophand") || findtext(search_blob, "trader"))
		return "Торговля и ремёсла"

	if(findtext(search_blob, "innkeeper") || findtext(search_blob, "bathmaster") || findtext(search_blob, "bathworker") || findtext(search_blob, "cook") || findtext(search_blob, "crier") || findtext(search_blob, "tapster") || findtext(search_blob, "servant") || findtext(search_blob, "towner") || findtext(search_blob, "villager") || findtext(search_blob, "mayor"))
		return "Город и служба"

	if(findtext(search_blob, "adventurer") || findtext(search_blob, "bandit") || findtext(search_blob, "assassin") || findtext(search_blob, "vagabond") || findtext(search_blob, "lunatic") || findtext(search_blob, "keeper") || findtext(search_blob, "gnoll") || findtext(search_blob, "hag") || findtext(search_blob, "soilbride") || findtext(search_blob, "wretch"))
		return "Авантюристы и изгои"

	return "Прочее"

/datum/character_setup_panel/proc/job_pref_key(job_title)
	switch(prefs.job_preferences[job_title])
		if(JP_HIGH)
			return "high"
		if(JP_MEDIUM)
			return "medium"
		if(JP_LOW)
			return "low"
	return "never"

/datum/character_setup_panel/proc/job_pref_label(job_title)
	switch(prefs.job_preferences[job_title])
		if(JP_HIGH)
			return "Высокий"
		if(JP_MEDIUM)
			return "Средний"
		if(JP_LOW)
			return "Низкий"
	return "Никогда"


/datum/character_setup_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	var/mob/user = ui.user
	if(!prefs || !user)
		return TRUE

	switch(action)
		if("edit_preference")
			handle_edit_preference(user, params["preference"])
			return TRUE

		if("edit_text_field")
			handle_edit_text_field(user, params["field"])
			return TRUE

		if("randomize_name")
			prefs.real_name = prefs.pref_species.random_name(prefs.gender, 1)
			post_update_after_action(user, "name")
			return TRUE

		if("manage_charflaws")
			handle_manage_charflaws(user)
			return TRUE

		if("add_charflaw")
			var/flaw_type = text2path(params["flaw"])
			if(flaw_type)
				handle_add_charflaw(user, flaw_type)
			return TRUE

		if("remove_charflaw")
			var/index = text2num(params["index"])
			if(index && index >= 1 && index <= prefs.charflaws.len)
				var/datum/charflaw/cf_to_remove = prefs.charflaws[index]
				prefs.charflaws.Remove(cf_to_remove)
				if(!prefs.charflaws.len)
					var/datum/charflaw/no_flaw = new /datum/charflaw/noflaw()
					prefs.charflaws.Add(no_flaw)
				post_update_after_action(user, "charflaw")
			return TRUE

		if("remove_charflaw_type")
			var/flaw_type = text2path(params["flaw"])
			if(flaw_type)
				handle_remove_charflaw(user, flaw_type)
			return TRUE

		if("set_customizer_size_choice")
			var/customizer_type = text2path(params["customizer"])
			var/var_name = "[params["var_name"]]"
			var/choice_id = "[params["value"]]"
			if(customizer_type && var_name && choice_id)
				var/datum/customizer_entry/entry = ensure_customizer_entry(customizer_type)
				if(entry && hasvar(entry, var_name))
					var/current_value = entry.vars[var_name]
					entry.vars[var_name] = three_step_size_value_from_choice(current_value, choice_id)
					post_update_after_action(user, "customizer")
			return TRUE

		if("set_voice_pitch_value")
			var/new_voice_pitch = text2num(params["value"])
			if(!isnull(new_voice_pitch))
				prefs.voice_pitch = clamp(new_voice_pitch, MIN_VOICE_PITCH, MAX_VOICE_PITCH)
				post_update_after_action(user, "voice_pitch")
			return TRUE

		if("set_body_size_value")
			var/new_body_size = text2num(params["value"])
			if(!isnull(new_body_size))
				prefs.features["body_size"] = clamp(new_body_size * 0.01, BODY_SIZE_MIN, BODY_SIZE_MAX)
				post_update_after_action(user, "body_size")
			return TRUE

		if("set_context_preference")
			handle_set_context_preference(user, params["kind"], params["value"])
			return TRUE

		if("set_descriptor_choice")
			var/choice_type = text2path(params["choice"])
			var/descriptor_type = text2path(params["descriptor"])
			if(choice_type && descriptor_type)
				handle_set_descriptor_choice(user, choice_type, descriptor_type)
			return TRUE

		if("set_custom_descriptor_prefix")
			var/custom_index = text2num(params["index"])
			var/prefix_type = text2num(params["prefix"])
			if(custom_index)
				handle_set_custom_descriptor_prefix(user, custom_index, prefix_type)
			return TRUE

		if("set_custom_descriptor_content")
			var/custom_index = text2num(params["index"])
			if(custom_index)
				handle_set_custom_descriptor_content(user, custom_index, params["value"])
			return TRUE

		if("set_culinary_preference")
			handle_set_culinary_preference(user, params["preference_type"], params["mode"], params["value"])
			return TRUE

		if("reset_culinary_preferences")
			if(hascall(prefs, "reset_culinary_preferences"))
				call(prefs, "reset_culinary_preferences")()
			post_update_after_action(user, "culinary")
			return TRUE

		if("set_familiar_name")
			handle_set_familiar_name(user, params["value"])
			return TRUE

		if("set_familiar_pronouns")
			handle_set_familiar_pronouns(user, text2num(params["value"]))
			return TRUE

		if("set_familiar_specie")
			handle_set_familiar_specie(user, text2path(params["value"]))
			return TRUE

		if("set_familiar_headshot")
			handle_set_familiar_headshot(user, params["value"])
			return TRUE

		if("set_familiar_flavortext")
			handle_set_familiar_flavortext(user, params["value"])
			return TRUE

		if("set_familiar_ooc_notes")
			handle_set_familiar_ooc_notes(user, params["value"])
			return TRUE

		if("set_familiar_ooc_extra")
			handle_set_familiar_ooc_extra(user, params["value"])
			return TRUE

		if("toggle_familiar_queue")
			handle_toggle_familiar_queue(user)
			return TRUE

		if("open_loadout")
			prefs.handle_loadout_size(user)
			prefs.clean_loadout(user)
			prefs.loadoutpanel.ui_interact(user)
			return TRUE

		if("open_markings")
			if(hascall(prefs, "ShowMarkings"))
				prefs.ShowMarkings(user)
			return TRUE

		if("remove_body_marking")
			var/zone = params["zone"]
			var/name = params["name"]
			var/list/zone_markings = prefs.body_markings[zone]
			if(zone_markings && (name in zone_markings))
				zone_markings -= name
				if(!zone_markings.len)
					prefs.body_markings -= zone
				post_update_after_action(user, "markings")
			return TRUE

		if("clear_body_marking_zone")
			var/zone = params["zone"]
			if(zone && prefs.body_markings[zone])
				prefs.body_markings -= zone
				post_update_after_action(user, "markings")
			return TRUE

		if("add_body_marking")
			var/zone = params["zone"]
			var/name = params["name"]
			if(zone && name)
				if(!prefs.body_markings[zone])
					prefs.body_markings[zone] = list()
				var/list/zone_markings = prefs.body_markings[zone]
				if(!(name in zone_markings))
					zone_markings += name
				post_update_after_action(user, "markings")
			return TRUE

		if("apply_gender_preset")
			apply_gender_preset(params["preset"])
			post_update_after_action(user, "gender")
			return TRUE

		if("set_gender_body_type")
			var/requested_gender = params["gender"]
			var/target_gender = (requested_gender == "feminine") ? FEMALE : MALE
			if(prefs.gender != target_gender)
				prefs.gender = target_gender
				prefs.genderize_customizer_entries()
				post_update_after_action(user, "gender")
			return TRUE

		if("set_voice_identity")
			var/requested_voice = params["voice_type"]
			if(requested_voice && (requested_voice in GLOB.voice_types_list))
				prefs.voice_type = requested_voice
				push_ui_update(CS_DIRTY_DETAILS)
			return TRUE

		if("open_jobs_window")
			if(!jobs_panel)
				jobs_panel = new /datum/character_setup_jobs_panel(prefs, src)
			jobs_panel.ui_interact(user)
			return TRUE

		if("save_setup")
			prefs.save_preferences()
			cached_slot_summaries = null
			to_chat(user, span_notice("ПЕРСОНАЖ СОХРАНЁН."))
			return TRUE

		if("undo_setup")
			prefs.load_preferences()
			prefs.load_character()
			active_job_slot_title = null
			cached_slot_summaries = null
			cached_job_entries = null
			cached_job_entries_key = null
			cached_job_slot_choices = null
			cached_job_slot_choices_key = null
			post_update_after_action(user, "undo")
			to_chat(user, span_notice("ИЗМЕНЕНИЯ ОТМЕНЕНЫ."))
			return TRUE

		if("rotate_preview")
			var/step = text2num(params["step"])
			if(step > 0)
				switch(preview_dir)
					if(SOUTH)
						preview_dir = WEST
					if(WEST)
						preview_dir = NORTH
					if(NORTH)
						preview_dir = EAST
					else
						preview_dir = SOUTH
			else
				switch(preview_dir)
					if(SOUTH)
						preview_dir = EAST
					if(EAST)
						preview_dir = NORTH
					if(NORTH)
						preview_dir = WEST
					else
						preview_dir = SOUTH
			push_ui_update(CS_DIRTY_MAIN_PREVIEW, CS_JOBS_DIRTY_NONE)
			return TRUE

		if("open_player_quality")
			check_pq_menu(user.ckey)
			return TRUE

		if("open_triumphs")
			user.show_triumphs_list()
			return TRUE

		if("done_setup")
			prefs.process_link(user, list("preference" = "finished"))
			return TRUE

		if("load_slot")
			var/slot = text2num(params["slot"])
			if(slot >= 1 && slot <= prefs.max_save_slots)
				if(!prefs.load_character(slot))
					prefs.random_character(null, FALSE, FALSE)
				active_job_slot_title = null
				cached_slot_summaries = null
				cached_job_entries = null
				cached_job_entries_key = null
				post_update_after_action(user, "changeslot")
			return TRUE

		if("select_origin")
			var/origin_type = text2path(params["origin"])
			if(origin_type && GLOB.virtues[origin_type])
				var/datum/virtue/virtue_chosen = GLOB.virtues[origin_type]
				prefs.virtue_origin = virtue_chosen
				to_chat(user, prefs.process_virtue_text(virtue_chosen))
				post_update_after_action(user, "origin")
			return TRUE

		if("set_job_pref")
			var/job_title = params["job"]
			var/level = params["level"]
			var/datum/job/job = SSjob ? SSjob.GetJob(job_title) : null
			if(job)
				if(level == "never")
					prefs.job_preferences -= job.title
				else
					var/target_level = null
					switch(level)
						if("high")
							target_level = JP_HIGH
						if("medium")
							target_level = JP_MEDIUM
						if("low")
							target_level = JP_LOW
					if(!isnull(target_level))
						prefs.SetJobPreferenceLevel(job, target_level)
				push_ui_update(CS_DIRTY_JOBS_CACHE, CS_JOBS_DIRTY_ALL)
			return TRUE

		if("reset_jobs")
			prefs.ResetJobs()
			push_ui_update(CS_DIRTY_JOBS_CACHE, CS_JOBS_DIRTY_ALL)
			return TRUE

		if("open_job_slot")
			active_job_slot_title = params["job"]
			push_ui_update(CS_DIRTY_NONE, CS_JOBS_DIRTY_LIST)
			return TRUE

		if("assign_job_slot")
			var/job_title = active_job_slot_title ? active_job_slot_title : params["job"]
			if(job_title)
				var/slot_value = params["slot"]
				if(slot_value == "default")
					prefs.job_characters -= job_title
				else
					var/slot_num = text2num(slot_value)
					if(slot_num >= 1 && slot_num <= prefs.max_save_slots)
						prefs.job_characters[job_title] = slot_num
				prefs.save_preferences()
				active_job_slot_title = null
				push_ui_update(CS_DIRTY_JOBS_CACHE, CS_JOBS_DIRTY_ALL)
			return TRUE

		if("select_customizer")
			var/customizer_type = text2path(params["customizer"])
			if(customizer_type)
				active_customizer_type = customizer_type
				customizer_filter = ""
				customizer_window_start = 1
				push_ui_update(CS_DIRTY_ACTIVE_CUSTOMIZER, CS_JOBS_DIRTY_NONE)
			return TRUE

		if("set_customizer_filter")
			var/search_value = params["value"]
			customizer_filter = lowertext("[search_value]")
			customizer_window_start = 1
			push_ui_update(CS_DIRTY_ACTIVE_CUSTOMIZER, CS_JOBS_DIRTY_NONE)
			return TRUE

		if("set_customizer_window")
			customizer_window_start = max(1, text2num(params["start"]))
			push_ui_update(CS_DIRTY_ACTIVE_CUSTOMIZER, CS_JOBS_DIRTY_NONE)
			return TRUE

		if("load_customizer_option_preview_dir")
			var/customizer_type = text2path(params["customizer"])
			var/accessory_type = text2path(params["accessory"])
			var/dir_text = uppertext("[params["direction"]]")
			var/target_dir = SOUTH
			switch(dir_text)
				if("WEST")
					target_dir = WEST
				if("NORTH")
					target_dir = NORTH
				if("EAST")
					target_dir = EAST
				else
					target_dir = SOUTH
			if(customizer_type && accessory_type)
				var/datum/customizer/customizer = CUSTOMIZER(customizer_type)
				var/preview_focus = customizer ? get_customizer_preview_focus(customizer) : null
				var/datum/customizer_entry/current_entry = prefs ? prefs.get_customizer_entry_for_customizer_type(customizer_type) : null
				var/option_preview_focus = preview_focus
				var/base_generated = FALSE
				if(preview_focus == "head" && istype(current_entry, /datum/customizer_entry/hair))
					option_preview_focus = "head_overlay"
					if(!get_cached_preview_asset_filename("hair_head_base", "head", target_dir))
						var/generated_base_asset = generate_cached_preview_asset(user, "hair_head_base", "head", target_dir)
						base_generated = !isnull(generated_base_asset)
				var/cache_key = "option|[customizer_type]|[accessory_type]"
				var/existing_asset = option_preview_focus ? get_cached_accessory_preview_asset(cache_key, option_preview_focus, target_dir) : null
				var/generated_asset = null
				if(option_preview_focus && !existing_asset)
					generated_asset = generate_customizer_option_preview_asset(user, customizer_type, accessory_type, option_preview_focus, target_dir)
				if(generated_asset || base_generated)
					push_ui_update(CS_DIRTY_ACTIVE_CUSTOMIZER, CS_JOBS_DIRTY_NONE)
			return TRUE

		if("set_customizer_accessory")
			var/customizer_type = text2path(params["customizer"])
			var/accessory_type = text2path(params["accessory"])
			if(customizer_type && accessory_type)
				var/datum/customizer_entry/entry = ensure_customizer_entry(customizer_type)
				if(entry)
					var/datum/customizer_choice/choice = CUSTOMIZER_CHOICE(entry.customizer_choice_type)
					if(choice && choice.sprite_accessories && (accessory_type in choice.sprite_accessories))
						entry.disabled = FALSE
						choice.set_accessory_type(prefs, accessory_type, entry)
						post_update_after_action(user, "customizer")
			return TRUE

		if("set_customizer_none")
			var/customizer_type = text2path(params["customizer"])
			if(customizer_type)
				var/datum/customizer_entry/entry = ensure_customizer_entry(customizer_type)
				if(entry)
					entry.disabled = TRUE
					entry.accessory_type = null
					if(hasvar(entry, "accessory_colors"))
						entry:accessory_colors = null
					post_update_after_action(user, "customizer")
			return TRUE

		if("toggle_customizer")
			var/customizer_type = text2path(params["customizer"])
			if(customizer_type)
				var/datum/customizer/customizer = CUSTOMIZER(customizer_type)
				var/datum/customizer_entry/entry = ensure_customizer_entry(customizer_type)
				if(customizer && entry && customizer.allows_disabling)
					entry.disabled = !entry.disabled
					post_update_after_action(user, "customizer")
			return TRUE

		if("set_customizer_choice")
			var/customizer_type = text2path(params["customizer"])
			var/choice_type = text2path(params["choice"])
			if(customizer_type && choice_type)
				var/datum/customizer/customizer = CUSTOMIZER(customizer_type)
				if(customizer && (choice_type in customizer.customizer_choices))
					var/datum/customizer_entry/old_entry = prefs.get_customizer_entry_for_customizer_type(customizer_type)
					if(old_entry)
						prefs.customizer_entries -= old_entry
					prefs.customizer_entries += customizer.create_customizer_entry(prefs, choice_type)
					active_customizer_type = customizer_type
					customizer_filter = ""
					customizer_window_start = 1
					post_update_after_action(user, "customizer")
			return TRUE

		if("reset_customizer_colors")
			var/customizer_type = text2path(params["customizer"])
			if(customizer_type)
				var/datum/customizer_entry/entry = ensure_customizer_entry(customizer_type)
				if(entry)
					var/datum/customizer_choice/choice = CUSTOMIZER_CHOICE(entry.customizer_choice_type)
					if(choice)
						if(istype(entry, /datum/customizer_entry/hair))
							var/datum/customizer_entry/hair/hair_entry = entry
							hair_entry.hair_color = initial(hair_entry.hair_color)
							hair_entry.natural_color = initial(hair_entry.natural_color)
							hair_entry.dye_color = initial(hair_entry.dye_color)
							hair_entry.natural_gradient = initial(hair_entry.natural_gradient)
							hair_entry.dye_gradient = initial(hair_entry.dye_gradient)
						choice.reset_accessory_colors(prefs, entry)
						post_update_after_action(user, "customizer")
			return TRUE

		if("edit_accessory_color")
			var/customizer_type = text2path(params["customizer"])
			var/index = text2num(params["index"])
			if(customizer_type && index)
				var/datum/customizer_entry/entry = ensure_customizer_entry(customizer_type)
				var/datum/customizer_choice/choice = entry ? CUSTOMIZER_CHOICE(entry.customizer_choice_type) : null
				if(entry && choice && choice.allows_accessory_color_customization)
					var/list/color_values = color_string_to_list(entry.accessory_colors)
					var/current_color = color_values[index]
					var/new_color = color_pick_sanitized(user, "Выберите цвет.", "Настройка персонажа", current_color)
					if(new_color)
						color_values[index] = sanitize_hexcolor(new_color)
						entry.accessory_colors = color_list_to_string(color_values)
						post_update_after_action(user, "customizer")
			return TRUE

		if("edit_customizer_size")
			var/customizer_type = text2path(params["customizer"])
			var/var_name = "[params["var_name"]]"
			if(customizer_type && var_name)
				var/datum/customizer_entry/entry = ensure_customizer_entry(customizer_type)
				if(entry && hasvar(entry, var_name))
					var/current_value = entry.vars[var_name]
					if(isnum(current_value))
						var/new_numeric_value = tgui_input_number(user, "Введите размер.", "Настройка персонажа", current_value)
						if(!isnull(new_numeric_value))
							entry.vars[var_name] = new_numeric_value
							post_update_after_action(user, "customizer")
					else
						var/new_text_value = tgui_input_text(user, "Введите значение размера.", "Настройка персонажа", "[current_value]", encode = FALSE)
						if(!isnull(new_text_value))
							entry.vars[var_name] = new_text_value
							post_update_after_action(user, "customizer")
			return TRUE
		if("set_hair_color")
			var/customizer_type = text2path(params["customizer"])
			if(customizer_type)
				var/datum/customizer_entry/hair/hair_entry = prefs.get_customizer_entry_for_customizer_type(customizer_type)
				if(hair_entry)
					var/new_color = color_pick_sanitized(user, "Выберите основной цвет волос.", "Настройка персонажа", hair_entry.hair_color)
					if(new_color)
						hair_entry.hair_color = sanitize_hexcolor(new_color)
						post_update_after_action(user, "customizer")
			return TRUE

		if("set_natural_gradient")
			var/customizer_type = text2path(params["customizer"])
			if(customizer_type)
				var/datum/customizer_entry/hair/hair_entry = prefs.get_customizer_entry_for_customizer_type(customizer_type)
				if(hair_entry)
					var/list/choices = hair_gradient_choice_list()
					var/selection = tgui_input_list(user, "Выберите натуральный градиент.", "Настройка персонажа", choices)
					if(selection)
						hair_entry.natural_gradient = choices[selection]
						post_update_after_action(user, "customizer")
			return TRUE

		if("set_natural_color")
			var/customizer_type = text2path(params["customizer"])
			if(customizer_type)
				var/datum/customizer_entry/hair/hair_entry = prefs.get_customizer_entry_for_customizer_type(customizer_type)
				if(hair_entry)
					var/new_color = color_pick_sanitized(user, "Выберите цвет натурального градиента.", "Настройка персонажа", hair_entry.natural_color)
					if(new_color)
						hair_entry.natural_color = sanitize_hexcolor(new_color)
						post_update_after_action(user, "customizer")
			return TRUE

		if("set_dye_gradient")
			var/customizer_type = text2path(params["customizer"])
			if(customizer_type)
				var/datum/customizer_entry/hair/hair_entry = prefs.get_customizer_entry_for_customizer_type(customizer_type)
				if(hair_entry)
					var/list/choices = hair_gradient_choice_list()
					var/selection = tgui_input_list(user, "Выберите градиент краски.", "Настройка персонажа", choices)
					if(selection)
						hair_entry.dye_gradient = choices[selection]
						post_update_after_action(user, "customizer")
			return TRUE

		if("set_dye_color")
			var/customizer_type = text2path(params["customizer"])
			if(customizer_type)
				var/datum/customizer_entry/hair/hair_entry = prefs.get_customizer_entry_for_customizer_type(customizer_type)
				if(hair_entry)
					var/new_color = color_pick_sanitized(user, "Выберите цвет краски.", "Настройка персонажа", hair_entry.dye_color)
					if(new_color)
						hair_entry.dye_color = sanitize_hexcolor(new_color)
						post_update_after_action(user, "customizer")
			return TRUE

		if("toggle_antag_role")
			var/role_id = params["role"]
			if(role_id)
				if(is_banned_from(user.ckey, ROLE_SYNDICATE) || is_banned_from(user.ckey, role_id))
					return TRUE
				var/days_remaining = null
				if(ispath(GLOB.special_roles_rogue[role_id]) && CONFIG_GET(flag/use_age_restriction_for_jobs))
					days_remaining = get_remaining_days(user.client)
				if(days_remaining)
					return TRUE
				if(role_id in prefs.be_special)
					prefs.be_special -= role_id
				else
					prefs.be_special += role_id
				prefs.save_preferences()
				push_ui_update(CS_DIRTY_DETAILS)
			return TRUE

		if("open_descriptors")
			if(hascall(prefs, "show_descriptors_ui"))
				call(prefs, "show_descriptors_ui")(user)
			return TRUE

		if("open_culinary")
			if(hascall(prefs, "show_culinary_ui"))
				call(prefs, "show_culinary_ui")(user)
			return TRUE

		if("open_familiar_prefs")
			if(prefs.familiar_prefs)
				prefs.familiar_prefs.fam_show_ui()
			return TRUE

		if("preview_flavor")
			var/datum/examine_panel/preview_examine_panel = new(user)
			preview_examine_panel.pref = prefs
			preview_examine_panel.holder = user
			preview_examine_panel.viewing = user
			preview_examine_panel.ui_interact(user)
			return TRUE

		if("manage_gallery")
			handle_manage_gallery(user, text2num(params["nsfw"]))
			return TRUE

		if("edit_system_pref")
			handle_edit_system_pref(user, params["pref"])
			return TRUE

		if("toggle_system_pref")
			handle_toggle_system_pref(user, params["pref"])
			return TRUE

		if("edit_villain_color")
			handle_edit_villain_color(user, params["pref"])
			return TRUE

		if("clear_villain_color")
			handle_clear_villain_color(user, params["pref"])
			return TRUE

		if("set_keybinding")
			handle_set_keybinding(user, params)
			return TRUE

		if("reset_keybindings")
			handle_reset_keybindings(user)
			return TRUE

	return TRUE


/datum/character_setup_panel/proc/handle_edit_system_pref(mob/user, pref)
	var/changed = FALSE
	switch(pref)
		if("tgui_theme")
			var/list/all_themes = get_tgui_themes()
			var/list/display_names = list()
			var/list/display_to_key = list()
			for(var/theme_key in all_themes)
				var/display_name = all_themes[theme_key]
				display_names += display_name
				display_to_key[display_name] = theme_key
			var/current_display = all_themes[prefs.tgui_theme] || prefs.tgui_theme || "Default"
			var/selection = tgui_input_list(user, "Выберите тему TGUI.", "Тема TGUI", sortList(display_names), current_display)
			if(selection)
				prefs.tgui_theme = display_to_key[selection]
				changed = TRUE

		if("clientfps")
			var/new_fps = tgui_input_number(user, "Выберите желаемый FPS. 0 — синхронизация с сервером.", "FPS", prefs.clientfps, 240, 0)
			if(!isnull(new_fps))
				prefs.clientfps = new_fps
				if(prefs.parent)
					prefs.parent.fps = new_fps
				changed = TRUE

		if("asaycolor")
			if(CONFIG_GET(flag/allow_admin_asaycolor))
				var/new_color = color_pick_sanitized(user, "Выберите цвет ASAY.", "Admin settings", prefs.asaycolor ? prefs.asaycolor : "#ff4500")
				if(new_color)
					prefs.asaycolor = new_color
					changed = TRUE

		if("examine_theme")
			var/list/all_themes = get_tgui_themes()
			var/list/choices = list("None (Use Viewer's)")
			for(var/theme_key in all_themes)
				if(theme_key == "trey_liam")
					continue
				choices += all_themes[theme_key]
			var/current_display = "None (Use Viewer's)"
			if(prefs.examine_theme)
				current_display = all_themes[prefs.examine_theme] || prefs.examine_theme
			var/picked = tgui_input_list(user, "Choose the theme others see on your examine panel:", "Examine Theme", choices, current_display)
			if(picked)
				if(picked == "None (Use Viewer's)")
					prefs.examine_theme = null
				else
					for(var/theme_key in all_themes)
						if(all_themes[theme_key] == picked)
							prefs.examine_theme = theme_key
							break
				changed = TRUE

	if(changed)
		prefs.save_preferences()
		push_ui_update(CS_DIRTY_DETAILS)

/datum/character_setup_panel/proc/handle_toggle_system_pref(mob/user, pref)
	var/changed = FALSE
	switch(pref)
		if("tgui_lock")
			prefs.tgui_lock = !prefs.tgui_lock
			changed = TRUE

		if("ambientocclusion")
			prefs.ambientocclusion = !prefs.ambientocclusion
			if(prefs.parent && prefs.parent.screen && prefs.parent.screen.len)
				var/atom/movable/screen/plane_master/game_world/PM = locate(/atom/movable/screen/plane_master/game_world) in prefs.parent.screen
				if(PM)
					PM.backdrop(prefs.parent.mob)
				PM = locate(/atom/movable/screen/plane_master/game_world_fov_hidden) in prefs.parent.screen
				if(PM)
					PM.backdrop(prefs.parent.mob)
				PM = locate(/atom/movable/screen/plane_master/game_world_above) in prefs.parent.screen
				if(PM)
					PM.backdrop(prefs.parent.mob)
			changed = TRUE

		if("windowflashing")
			prefs.windowflashing = !prefs.windowflashing
			changed = TRUE

		if("auto_fit_viewport")
			prefs.auto_fit_viewport = !prefs.auto_fit_viewport
			if(prefs.auto_fit_viewport && prefs.parent)
				prefs.parent.fit_viewport()
			changed = TRUE

		if("widescreenpref")
			prefs.widescreenpref = !prefs.widescreenpref
			if(user.client)
				user.client.change_view(CONFIG_GET(string/default_view))
			changed = TRUE

		if("chat_on_map")
			prefs.chat_on_map = !prefs.chat_on_map
			changed = TRUE

		if("see_chat_non_mob")
			prefs.see_chat_non_mob = !prefs.see_chat_non_mob
			changed = TRUE

		if("buttons_locked")
			prefs.buttons_locked = !prefs.buttons_locked
			changed = TRUE

		if("anonymize")
			prefs.anonymize = !prefs.anonymize
			changed = TRUE

		if("masked_examine")
			prefs.masked_examine = !prefs.masked_examine
			changed = TRUE

		if("full_examine")
			prefs.full_examine = !prefs.full_examine
			changed = TRUE

		if("mute_animal_emotes")
			prefs.mute_animal_emotes = !prefs.mute_animal_emotes
			changed = TRUE

		if("autoconsume")
			prefs.autoconsume = !prefs.autoconsume
			changed = TRUE

		if("no_examine_blocks")
			prefs.no_examine_blocks = !prefs.no_examine_blocks
			changed = TRUE

		if("no_autopunctuate")
			prefs.no_autopunctuate = !prefs.no_autopunctuate
			changed = TRUE

		if("no_language_fonts")
			prefs.no_language_fonts = !prefs.no_language_fonts
			changed = TRUE

		if("no_language_icon")
			prefs.no_language_icon = !prefs.no_language_icon
			changed = TRUE

		if("no_redflash")
			prefs.no_redflash = !prefs.no_redflash
			changed = TRUE

		if("hear_midis")
			prefs.toggles ^= SOUND_MIDI
			changed = TRUE

		if("hear_adminhelps")
			if(user?.client)
				user.client.toggleadminhelpsound()
			else
				prefs.toggles ^= SOUND_ADMINHELP
			changed = TRUE

		if("toggle_deadmin_always")
			if(!CONFIG_GET(flag/auto_deadmin_players))
				prefs.toggles ^= DEADMIN_ALWAYS
				changed = TRUE

		if("toggle_deadmin_antag")
			if(!CONFIG_GET(flag/auto_deadmin_antagonists))
				prefs.toggles ^= DEADMIN_ANTAGONIST
				changed = TRUE

		if("toggle_deadmin_head")
			if(!CONFIG_GET(flag/auto_deadmin_heads))
				prefs.toggles ^= DEADMIN_POSITION_HEAD
				changed = TRUE

		if("qsr_pref")
			prefs.qsr_pref = !prefs.qsr_pref
			changed = TRUE

		if("schizo_voice")
			prefs.toggles ^= SCHIZO_VOICE
			changed = TRUE

	if(changed)
		prefs.save_preferences()
		push_ui_update(CS_DIRTY_DETAILS)

/datum/character_setup_panel/proc/handle_edit_villain_color(mob/user, pref)
	var/current_color = null
	switch(pref)
		if("vampire_skin")
			current_color = prefs.vampire_skin
		if("vampire_eyes")
			current_color = prefs.vampire_eyes
		if("vampire_hair")
			current_color = prefs.vampire_hair
		if("vampire_ears")
			current_color = prefs.vampire_ears

	var/new_color = color_pick_sanitized(user, "Выберите цвет.", "Настройки антагониста", current_color ? current_color : "#FFFFFF")
	if(!new_color)
		return

	switch(pref)
		if("vampire_skin")
			prefs.vampire_skin = sanitize_hexcolor(new_color)
		if("vampire_eyes")
			prefs.vampire_eyes = sanitize_hexcolor(new_color)
		if("vampire_hair")
			prefs.vampire_hair = sanitize_hexcolor(new_color)
		if("vampire_ears")
			prefs.vampire_ears = sanitize_hexcolor(new_color)
		else
			return

	prefs.save_preferences()
	push_ui_update(CS_DIRTY_DETAILS)

/datum/character_setup_panel/proc/handle_clear_villain_color(user, pref)
	switch(pref)
		if("vampire_skin")
			prefs.vampire_skin = null
		if("vampire_eyes")
			prefs.vampire_eyes = null
		if("vampire_hair")
			prefs.vampire_hair = null
		if("vampire_ears")
			prefs.vampire_ears = null
		else
			return
	prefs.save_preferences()
	push_ui_update(CS_DIRTY_DETAILS)

/datum/character_setup_panel/proc/handle_set_keybinding(mob/user, list/params)
	var/kb_name = params["keybinding"]
	if(!kb_name)
		return

	var/clear_key = text2num(params["clear_key"])
	var/old_key = params["old_key"]

	if(clear_key)
		if(old_key && prefs.key_bindings[old_key])
			prefs.key_bindings[old_key] -= kb_name
			if(!length(prefs.key_bindings[old_key]))
				prefs.key_bindings -= old_key
		if(user.client)
			user.client.update_movement_keys()
		prefs.save_preferences()
		push_ui_update(CS_DIRTY_KEYBINDINGS)
		return

	var/new_key = uppertext("[params["key"]]")
	var/AltMod = text2num(params["alt"]) ? "Alt" : ""
	var/CtrlMod = text2num(params["ctrl"]) ? "Ctrl" : ""
	var/ShiftMod = text2num(params["shift"]) ? "Shift" : ""
	var/numpad = text2num(params["numpad"]) ? "Numpad" : ""

	if(GLOB._kbMap[new_key])
		new_key = GLOB._kbMap[new_key]

	var/full_key
	switch(new_key)
		if("Alt")
			full_key = "[new_key][CtrlMod][ShiftMod]"
		if("Ctrl")
			full_key = "[AltMod][new_key][ShiftMod]"
		if("Shift")
			full_key = "[AltMod][CtrlMod][new_key]"
		else
			full_key = "[AltMod][CtrlMod][ShiftMod][numpad][new_key]"

	if(old_key && prefs.key_bindings[old_key])
		prefs.key_bindings[old_key] -= kb_name
		if(!length(prefs.key_bindings[old_key]))
			prefs.key_bindings -= old_key

	prefs.key_bindings[full_key] += list(kb_name)
	prefs.key_bindings[full_key] = sortList(prefs.key_bindings[full_key])

	if(user.client)
		user.client.update_movement_keys()
	prefs.save_preferences()
	push_ui_update(CS_DIRTY_KEYBINDINGS)

/datum/character_setup_panel/proc/handle_reset_keybindings(mob/user)
	var/choice = tgalert(user, "Какие значения по умолчанию применить?", "Сброс клавиш", "Hotkey", "Classic", "Cancel")
	if(choice == "Cancel" || !choice)
		return

	prefs.hotkeys = (choice == "Hotkey")
	prefs.key_bindings = prefs.hotkeys ? deepCopyList(GLOB.hotkey_keybinding_list_by_key) : deepCopyList(GLOB.classic_keybinding_list_by_key)

	if(user.client)
		user.client.update_movement_keys()
	prefs.save_preferences()
	push_ui_update(CS_DIRTY_KEYBINDINGS)

/datum/character_setup_panel/proc/find_customizer_type_by_display_name(display_name)
	if(!prefs?.pref_species?.customizers)
		return null
	for(var/customizer_type as anything in prefs.pref_species.customizers)
		var/datum/customizer/customizer = CUSTOMIZER(customizer_type)
		if(!customizer)
			continue
		if(translate_customizer_name(customizer.name) == display_name)
			return customizer_type
	return null

/datum/character_setup_panel/proc/default_voice_type_for_gender(gender)
	var/needle = (gender == FEMALE) ? "fem" : "masc"
	for(var/voice_name in GLOB.voice_types_list)
		if(findtext(lowertext("[voice_name]"), needle))
			return voice_name
	return prefs.voice_type

/datum/character_setup_panel/proc/apply_gender_preset(preset)
	var/target_gender = (preset == "feminine") ? FEMALE : MALE
	prefs.gender = target_gender
	prefs.pronouns = (target_gender == FEMALE) ? SHE_HER : HE_HIM
	prefs.titles_pref = (target_gender == FEMALE) ? TITLES_F : TITLES_M
	prefs.clothes_pref = (target_gender == FEMALE) ? CLOTHES_F : CLOTHES_M
	prefs.genderize_customizer_entries()
	prefs.voice_type = default_voice_type_for_gender(target_gender)
	prefs.ResetJobs()

	var/breasts_type = find_customizer_type_by_display_name("Грудь")
	var/vagina_type = find_customizer_type_by_display_name("Влагалище")
	var/penis_type = find_customizer_type_by_display_name("Пенис")
	var/testicles_type = find_customizer_type_by_display_name("Яички")

	if(breasts_type)
		var/datum/customizer_entry/breasts_entry = ensure_customizer_entry(breasts_type)
		if(breasts_entry)
			breasts_entry.disabled = (target_gender == MALE)
	if(vagina_type)
		var/datum/customizer_entry/vagina_entry = ensure_customizer_entry(vagina_type)
		if(vagina_entry)
			vagina_entry.disabled = (target_gender == MALE)
	if(penis_type)
		var/datum/customizer_entry/penis_entry = ensure_customizer_entry(penis_type)
		if(penis_entry)
			penis_entry.disabled = (target_gender == FEMALE)
	if(testicles_type)
		var/datum/customizer_entry/testicles_entry = ensure_customizer_entry(testicles_type)
		if(testicles_entry)
			testicles_entry.disabled = (target_gender == FEMALE)

/datum/character_setup_panel/proc/handle_edit_preference(mob/user, preference)
	var/changed = FALSE
	var/update_key = preference
	switch(preference)
		if("name")
			var/new_name = tgui_input_text(user, "Имя персонажа:", "Имя", prefs.real_name, encode = FALSE)
			if(new_name)
				new_name = reject_bad_name(new_name)
				if(new_name)
					prefs.real_name = new_name
					changed = TRUE
				else
					to_chat(user, span_warning("Некорректное имя."))

		if("nickname")
			var/new_name = tgui_input_text(user, "Прозвище персонажа:", "Прозвище", prefs.nickname, encode = FALSE)
			if(new_name)
				new_name = reject_bad_name(new_name)
				if(new_name)
					prefs.nickname = new_name
					changed = TRUE
				else
					to_chat(user, span_warning("Некорректное прозвище."))

		if("pronouns")
			var/pronouns_input = tgui_input_list(user, "Выберите местоимения персонажа.", "Местоимения", GLOB.pronouns_list)
			if(pronouns_input)
				prefs.pronouns = pronouns_input
				prefs.ResetJobs()
				changed = TRUE

		if("titles")
			var/new_titles = (prefs.titles_pref == TITLES_M) ? TITLES_F : TITLES_M
			if(new_titles != prefs.titles_pref)
				prefs.titles_pref = new_titles
				changed = TRUE

		if("clothespref")
			var/new_clothes = (prefs.clothes_pref == CLOTHES_M) ? CLOTHES_F : CLOTHES_M
			if(new_clothes != prefs.clothes_pref)
				prefs.clothes_pref = new_clothes
				changed = TRUE

		if("voicetype")
			var/voicetype_input = tgui_input_list(user, "Выберите тип голоса.", "Тип голоса", GLOB.voice_types_list)
			if(voicetype_input)
				prefs.voice_type = voicetype_input
				changed = TRUE

		if("voicepack")
			var/voicepack_input = tgui_input_list(user, "Выберите голосовой пак.", "Голосовой пак", GLOB.voice_packs_list)
			if(voicepack_input)
				prefs.voice_pack = voicepack_input
				changed = TRUE

		if("species")
			var/list/base_species = list()
			for(var/A in GLOB.roundstart_races)
				var/datum/species/race = GLOB.species_list[A]
				race = new race()
				if(!user.client)
					continue
				if(race.patreon_req > user.client.patreonlevel())
					continue
				if(race.is_subrace == TRUE)
					continue
				base_species[race.base_name] = race
			base_species = sortList(base_species)
			var/current_base = prefs.pref_species ? prefs.pref_species.base_name : null
			var/base_result = tgui_input_list(user, "Выберите расу.", "Раса", base_species, current_base)
			if(base_result)
				var/list/subspecies = list()
				for(var/A in GLOB.roundstart_races)
					var/datum/species/subrace = GLOB.species_list[A]
					subrace = new subrace()
					if(!user.client)
						continue
					if(subrace.patreon_req > user.client.patreonlevel())
						continue
					if(subrace.base_name != base_result)
						continue
					subspecies[subrace.sub_name] = subrace
				var/current_sub = (prefs.pref_species && prefs.pref_species.base_name == base_result) ? prefs.pref_species.sub_name : null
				var/sub_result = null
				if(length(subspecies) == 1)
					for(var/only_key in subspecies)
						sub_result = only_key
				else
					sub_result = tgui_input_list(user, "Выберите подрасу.", "Подраса", sortList(subspecies), current_sub)
				if(sub_result)
					var/datum/species/race_chosen = subspecies[sub_result]
					prefs.set_new_race(race_chosen, user)
					changed = TRUE
					update_key = "subspecies"

		if("subspecies")
			var/list/species = list()
			for(var/A in GLOB.roundstart_races)
				var/datum/species/race = GLOB.species_list[A]
				race = new race()
				if(user.client)
					if(race.base_name != prefs.pref_species.base_name)
						continue
					if(race.sub_name == prefs.pref_species.sub_name)
						continue
				else
					continue
				species[race.sub_name] += race
			var/result = tgui_input_list(user, "Выберите подрасу.", "Подраса", species)
			if(result)
				var/datum/species/subrace_chosen = species[result]
				prefs.set_new_race(subrace_chosen, user)
				changed = TRUE
				update_key = "subspecies"

		if("gender")
			var/pickedGender = MALE
			if(prefs.gender == MALE)
				pickedGender = FEMALE
			if(pickedGender && pickedGender != prefs.gender)
				prefs.gender = pickedGender
				prefs.genderize_customizer_entries()
				changed = TRUE

		if("age")
			var/new_age = tgui_input_list(user, "Выберите возраст персонажа.", "Возраст", prefs.pref_species.possible_ages)
			if(new_age)
				prefs.age = new_age
				var/list/hairs
				if((prefs.age == AGE_OLD) && (OLDGREY in prefs.pref_species.species_traits))
					hairs = prefs.pref_species.get_oldhc_list()
				else
					hairs = prefs.pref_species.get_hairc_list()
				prefs.hair_color = hairs[pick(hairs)]
				prefs.facial_hair_color = prefs.hair_color
				prefs.ResetJobs()
				changed = TRUE

		if("statpack")
			var/list/statpacks_available = list()
			for(var/path as anything in GLOB.statpacks)
				var/datum/statpack/statpack = GLOB.statpacks[path]
				if(!statpack.name)
					continue
				var/index = statpack.name
				if(length(statpack.stat_array))
					index += " \n[statpack.generate_modifier_string()]"
				statpacks_available[index] = statpack
			statpacks_available = sort_list(statpacks_available)
			var/statpack_input = tgui_input_list(user, "Выберите статпак.", "Статпак", statpacks_available, prefs.statpack)
			if(statpack_input)
				var/datum/statpack/statpack_chosen = statpacks_available[statpack_input]
				prefs.statpack = statpack_chosen
				changed = TRUE

		if("origin")
			// Временно оставляем старую панель происхождений.
			// Новый TGUI OriginPicker из PR #906 намеренно не вызывается отсюда, пока карта происхождений не вмержена и не стабилизирована.
			// if(hascall(prefs, "open_origin_picker_tgui"))
			// 	call(prefs, "open_origin_picker_tgui")(user)
			if(hascall(prefs, "open_origin_legacy"))
				call(prefs, "open_origin_legacy")(user)
				changed = TRUE


		if("eyes")
			var/new_eye_color = color_pick_sanitized(user, "Выберите цвет глаз.", "Цвет глаз", "#" + prefs.eye_color)
			if(new_eye_color)
				prefs.eye_color = sanitize_hexcolor(new_eye_color)
				changed = TRUE

		if("faith")
			var/list/faiths_named = list()
			for(var/path as anything in GLOB.preference_faiths)
				var/datum/faith/faith = GLOB.faithlist[path]
				if(!faith.name)
					continue
				faiths_named[faith.name] = faith
			var/faith_input = tgui_input_list(user, "Выберите веру.", "Вера", faiths_named)
			if(faith_input)
				var/datum/faith/faith = faiths_named[faith_input]
				prefs.selected_patron = GLOB.patronlist[faith.godhead] || GLOB.patronlist[pick(GLOB.patrons_by_faith[faith_input])]
				changed = TRUE

		if("patron")
			var/list/patrons_named = list()
			var/current_faith = prefs.selected_patron ? prefs.selected_patron.associated_faith : initial(prefs.default_patron.associated_faith)
			for(var/path as anything in GLOB.patrons_by_faith[current_faith])
				var/datum/patron/patron = GLOB.patronlist[path]
				if(!patron.name)
					continue
				patrons_named[patron.name] = patron
			var/god_input = tgui_input_list(user, "Выберите покровителя.", "Покровитель", patrons_named)
			if(god_input)
				prefs.selected_patron = patrons_named[god_input]
				changed = TRUE

		if("extra_language")
			var/static/list/selectable_languages = list(
				/datum/language/elvish,
				/datum/language/dwarvish,
				/datum/language/orcish,
				/datum/language/hellspeak,
				/datum/language/draconic,
				/datum/language/raneshi,
				/datum/language/grenzelhoftian,
				/datum/language/kazengunese,
				/datum/language/lingyuese,
				/datum/language/gyedzenese,
				/datum/language/valorian,
				/datum/language/etruscan,
				/datum/language/gronnic,
				/datum/language/otavan,
				/datum/language/aavnic,
			)
			var/list/choices = list("None")
			for(var/language in selectable_languages)
				if(language in prefs.pref_species.languages)
					continue
				var/datum/language/a_language = new language()
				choices[a_language.name] = language
			var/chosen_language = tgui_input_list(user, "Выберите дополнительный язык.", "Язык", choices)
			if(chosen_language)
				if(chosen_language == "None")
					prefs.extra_language = "None"
				else
					prefs.extra_language = choices[chosen_language]
				changed = TRUE

		if("taur_type")
			var/list/species_taur_list = prefs.pref_species.get_taur_list()
			if(!LAZYLEN(species_taur_list))
				prefs.taur_type = null
				to_chat(user, span_bad("Для этой расы нет доступных таур-тел."))
				return
			var/list/taur_selection = list("None")
			for(var/obj/item/bodypart/taur/tt as anything in prefs.pref_species.get_taur_list())
				taur_selection[tt::name] = tt
			var/new_taur_type = tgui_input_list(user, "Выберите тип таур-тела.", "Таур", taur_selection)
			if(new_taur_type)
				if(new_taur_type == "None")
					prefs.taur_type = null
				else
					prefs.taur_type = taur_selection[new_taur_type]
				changed = TRUE

		if("taur_color")
			var/new_taur_color = color_pick_sanitized(user, "Выберите цвет таур-части.", "Таур", "#" + prefs.taur_color)
			if(new_taur_color)
				prefs.taur_color = sanitize_hexcolor(new_taur_color)
				changed = TRUE

		if("race_bonus_select")
			if(length(prefs.pref_species.custom_selection))
				var/choice = tgui_input_list(user, "Выберите расовый бонус.", "Расовый бонус", prefs.pref_species.custom_selection)
				if(choice)
					prefs.race_bonus = choice
					changed = TRUE

		if("charflaw_averse_choice")
			var/choice = tgui_input_list(user, "Выберите нелюбимую фракцию.", "Нелюбимая фракция", GLOB.averse_factions)
			if(choice)
				prefs.averse_chosen_faction = choice
				changed = TRUE

		if("virtue")
			var/list/virtue_choices = list()
			for (var/path as anything in GLOB.virtues)
				var/datum/virtue/V = GLOB.virtues[path]
				if (!V.name)
					continue
				if ((V.name == prefs.virtue.name || V.name == prefs.virtuetwo.name) && !istype(V, /datum/virtue/none))
					if(!V.stackable)
						continue
				if (istype(V, /datum/virtue/origin))
					continue
				if(V.unlisted)
					continue
				if (istype(V, /datum/virtue/heretic) && !istype(prefs.selected_patron, /datum/patron/inhumen))
					continue
				if (V.restricted == TRUE)
					if((prefs.pref_species.type in V.races))
						continue
				if(V.virtuous_only && !prefs.statpack.virtuous)
					continue
				virtue_choices[V.name] = V
			virtue_choices = sort_list(virtue_choices)
			var/result = tgui_input_list(user, "Выберите добродетель.", "Добродетель", virtue_choices)
			if(result)
				var/datum/virtue/virtue_chosen = virtue_choices[result]
				prefs.virtue = new virtue_chosen.type
				changed = TRUE

		if("virtuetwo")
			var/list/virtue_choices = list()
			for (var/path as anything in GLOB.virtues)
				var/datum/virtue/V = GLOB.virtues[path]
				if (!V.name)
					continue
				if ((V.name == prefs.virtue.name || V.name == prefs.virtuetwo.name) && !istype(V, /datum/virtue/none))
					if(!V.stackable)
						continue
				if (istype(V, /datum/virtue/origin))
					continue
				if(V.unlisted)
					continue
				if (istype(V, /datum/virtue/heretic) && !istype(prefs.selected_patron, /datum/patron/inhumen))
					continue
				if (V.restricted == TRUE)
					if((prefs.pref_species.type in V.races))
						continue
				virtue_choices[V.name] = V
			virtue_choices = sort_list(virtue_choices)
			var/result = tgui_input_list(user, "Выберите вторую добродетель.", "Вторая добродетель", virtue_choices)
			if(result)
				var/datum/virtue/virtue_chosen = virtue_choices[result]
				prefs.virtuetwo = new virtue_chosen.type
				changed = TRUE

		if("char_accent")
			var/selectedaccent = tgui_input_list(user, "Выберите акцент персонажа.", "Акцент", GLOB.character_accents)
			if(selectedaccent)
				prefs.char_accent = selectedaccent
				changed = TRUE

		if("voice")
			var/new_voice = color_pick_sanitized(user, "Выберите цвет голоса персонажа.", "Цвет голоса", "#" + prefs.voice_color)
			if(new_voice)
				if(color_hex2num(new_voice) < 230)
					to_chat(user, span_warning("Этот цвет голоса слишком тёмный."))
				else
					prefs.voice_color = sanitize_hexcolor(new_voice)
					changed = TRUE

		if("voice_pitch")
			var/new_voice_pitch = tgui_input_number(user, "Выберите высоту голоса ([MIN_VOICE_PITCH] to [MAX_VOICE_PITCH], lower is deeper):", "Voice Pitch", prefs.voice_pitch, 1.35, 0.8, round_value = FALSE)
			if(!isnull(new_voice_pitch))
				if(new_voice_pitch < MIN_VOICE_PITCH || new_voice_pitch > MAX_VOICE_PITCH)
					to_chat(user, span_warning("Значение должно быть между [MIN_VOICE_PITCH] и [MAX_VOICE_PITCH]."))
				else
					prefs.voice_pitch = new_voice_pitch
					changed = TRUE

		if("highlight_color")
			var/new_color = color_pick_sanitized(user, "Выберите цвет ника.", "Цвет ника", prefs.highlight_color)
			if(new_color)
				prefs.highlight_color = sanitize_hexcolor(new_color)
				changed = TRUE

		if("combat_music")
			if(!prefs.combat_music_helptext_shown)
				to_chat(user, span_notice("<span class='bold'>Combat Music Override</span>\nOptions other than \"Default\" override whatever the game dynamically sets for you, which is influenced by your job class, villain status, or certain events."))
				prefs.combat_music_helptext_shown = TRUE
			var/track_select = tgui_input_list(user, "To you, the Signal sounds like:", "COMBAT MUSIC", GLOB.cmode_tracks_by_name, prefs.combat_music?.name)
			if(track_select)
				prefs.combat_music = GLOB.cmode_tracks_by_name[track_select]
				changed = TRUE

		if("dnr")
			prefs.dnr_pref = !prefs.dnr_pref
			changed = TRUE

		if("domhand")
			prefs.domhand = (prefs.domhand == 1) ? 2 : 1
			changed = TRUE

		if("body_size")
			var/current_body_size = (prefs.features["body_size"] || 1) * 100
			var/new_body_size = tgui_input_number(user, "Choose your desired sprite size:\n([BODY_SIZE_MIN*100]%-[BODY_SIZE_MAX*100]%), Warning: May make your character look distorted", "Character Preference", current_body_size)
			if(!isnull(new_body_size))
				new_body_size = clamp(new_body_size * 0.01, BODY_SIZE_MIN, BODY_SIZE_MAX)
				prefs.features["body_size"] = new_body_size
				changed = TRUE
				update_key = "body"

		if("s_tone")
			var/list/listy = prefs.pref_species.get_skin_list()
			var/new_s_tone = tgui_input_list(user, "Choose your character's skin tone:", "SKINTONE", listy)
			if(new_s_tone)
				prefs.skin_tone = listy[new_s_tone]
				prefs.features["mcolor"] = sanitize_hexcolor(prefs.skin_tone)
				if(hascall(prefs, "try_update_mutant_colors"))
					call(prefs, "try_update_mutant_colors")()
				changed = TRUE
				update_key = "body"

		if("ooc_extra")
			var/new_extra_link = tgui_input_text(user, "Input the accessory link (https, hosts: discord, catbox):", "Song URL", prefs.ooc_extra, encode = FALSE)
			if(new_extra_link != null)
				if(new_extra_link == "")
					prefs.ooc_extra = null
					changed = TRUE
				else
					var/static/list/valid_extensions = list("mp3")
					if(valid_headshot_link(user, new_extra_link, FALSE, valid_extensions))
						prefs.ooc_extra = new_extra_link
						changed = TRUE

		if("change_artist")
			var/new_artist = tgui_input_text(user, "Input your song's artist:", "Song Artist", prefs.song_artist, encode = FALSE)
			if(new_artist != null)
				prefs.song_artist = length(new_artist) ? new_artist : null
				changed = TRUE

		if("change_title")
			var/new_title = tgui_input_text(user, "Input your song's title:", "Song title", prefs.song_title, encode = FALSE)
			if(new_title != null)
				prefs.song_title = length(new_title) ? new_title : null
				changed = TRUE

	if(changed)
		post_update_after_action(user, update_key)

/datum/character_setup_panel/proc/handle_edit_text_field(mob/user, field)
	var/changed = FALSE
	switch(field)
		if("flavortext")
			var/new_text = tgui_input_text(user, "Описание персонажа:", "Флавортекст", prefs.flavortext, multiline = TRUE, encode = FALSE, bigmodal = TRUE)
			if(new_text != null)
				prefs.flavortext = length(new_text) ? new_text : null
				prefs.flavortext_cached = prefs.flavortext ? parsemarkdown_basic(html_encode(prefs.flavortext), hyperlink = TRUE) : null
				changed = TRUE
		if("ooc_notes")
			var/new_text = tgui_input_text(user, "OOC-предпочтения:", "OOC заметки", prefs.ooc_notes, multiline = TRUE, encode = FALSE, bigmodal = TRUE)
			if(new_text != null)
				prefs.ooc_notes = length(new_text) ? new_text : null
				prefs.ooc_notes_cached = prefs.ooc_notes ? parsemarkdown_basic(html_encode(prefs.ooc_notes), hyperlink = TRUE) : null
				changed = TRUE
		if("rumour")
			var/new_text = tgui_input_text(user, "Слухи о персонаже:", "Слухи", prefs.rumour, multiline = TRUE, encode = FALSE, bigmodal = TRUE)
			if(new_text != null)
				if(length(new_text) > 800)
					to_chat(user, span_warning("Слухи не должны превышать 800 символов."))
				else
					prefs.rumour = length(new_text) ? new_text : null
					changed = TRUE
		if("noble_gossip")
			var/new_text = tgui_input_text(user, "Дворянские слухи:", "Сплетни знати", prefs.noble_gossip, multiline = TRUE, encode = FALSE, bigmodal = TRUE)
			if(new_text != null)
				if(length(new_text) > 800)
					to_chat(user, span_warning("Сплетни знати не должны превышать 800 символов."))
				else
					prefs.noble_gossip = length(new_text) ? new_text : null
					changed = TRUE
		if("nsfwflavortext")
			var/new_text = tgui_input_text(user, "NSFW-описание персонажа:", "NSFW флавортекст", prefs.nsfwflavortext, multiline = TRUE, encode = FALSE, bigmodal = TRUE)
			if(new_text != null)
				prefs.nsfwflavortext = length(new_text) ? new_text : null
				prefs.nsfwflavortext_cached = prefs.nsfwflavortext ? parsemarkdown_basic(html_encode(prefs.nsfwflavortext), hyperlink = TRUE) : null
				changed = TRUE
		if("erpprefs")
			var/new_text = tgui_input_text(user, "ERP-предпочтения:", "ERP предпочтения", prefs.erpprefs, multiline = TRUE, encode = FALSE, bigmodal = TRUE)
			if(new_text != null)
				prefs.erpprefs = length(new_text) ? new_text : null
				prefs.erpprefs_cached = prefs.erpprefs ? parsemarkdown_basic(html_encode(prefs.erpprefs), hyperlink = TRUE) : null
				changed = TRUE
		if("headshot_link")
			var/new_link = tgui_input_text(user, "Ссылка на обычный headshot:", "Headshot", prefs.headshot_link, encode = FALSE)
			if(new_link != null)
				if(!length(new_link))
					prefs.headshot_link = null
					changed = TRUE
				else if(valid_headshot_link(user, new_link))
					prefs.headshot_link = new_link
					changed = TRUE
		if("lich_headshot_link")
			var/new_link = tgui_input_text(user, "Ссылка на lich headshot:", "Lich Headshot", prefs.lich_headshot_link, encode = FALSE)
			if(new_link != null)
				if(!length(new_link))
					prefs.lich_headshot_link = null
					changed = TRUE
				else if(valid_headshot_link(user, new_link))
					prefs.lich_headshot_link = new_link
					changed = TRUE
		if("vampire_headshot_link")
			var/new_link = tgui_input_text(user, "Ссылка на vampire headshot:", "Vampire Headshot", prefs.vampire_headshot_link, encode = FALSE)
			if(new_link != null)
				if(!length(new_link))
					prefs.vampire_headshot_link = null
					changed = TRUE
				else if(valid_headshot_link(user, new_link))
					prefs.vampire_headshot_link = new_link
					changed = TRUE
	if(changed)
		post_update_after_action(user, field)


/datum/character_setup_panel/proc/handle_add_charflaw(mob/user, flaw_type)
	for(var/datum/charflaw/_existing in prefs.charflaws)
		if(istype(_existing, /datum/charflaw/noflaw))
			prefs.charflaws.Remove(_existing)
			break
	if(prefs.charflaws.len >= MAX_VICES)
		to_chat(user, span_warning("Нельзя выбрать больше пороков."))
		return
	for(var/datum/charflaw/cf as anything in prefs.charflaws)
		if(cf.type == flaw_type && !istype(cf, /datum/charflaw/randflaw))
			to_chat(user, span_warning("Этот порок уже выбран."))
			return
	var/datum/charflaw/new_flaw = new flaw_type()
	prefs.charflaws.Add(new_flaw)
	post_update_after_action(user, "charflaw")

/datum/character_setup_panel/proc/handle_remove_charflaw(mob/user, flaw_type)
	for(var/datum/charflaw/cf as anything in prefs.charflaws)
		if(istype(cf, /datum/charflaw/noflaw))
			continue
		if(cf.type != flaw_type)
			continue
		prefs.charflaws.Remove(cf)
		break
	var/has_real_flaws = FALSE
	for(var/datum/charflaw/cf as anything in prefs.charflaws)
		if(!istype(cf, /datum/charflaw/noflaw))
			has_real_flaws = TRUE
			break
	if(!has_real_flaws)
		prefs.charflaws.Cut()
		prefs.charflaws.Add(new /datum/charflaw/noflaw())
	post_update_after_action(user, "charflaw")

/datum/character_setup_panel/proc/can_select_virtue(virtue_type, primary = TRUE)
	var/datum/virtue/V = GLOB.virtues[virtue_type]
	if(!V?.name)
		return FALSE
	if((V.name == prefs.virtue?.name || V.name == prefs.virtuetwo?.name) && !istype(V, /datum/virtue/none))
		if(!V.stackable)
			return FALSE
	if(istype(V, /datum/virtue/origin))
		return FALSE
	if(V.unlisted)
		return FALSE
	if(istype(V, /datum/virtue/heretic) && !istype(prefs.selected_patron, /datum/patron/inhumen))
		return FALSE
	if(V.restricted == TRUE)
		if((prefs.pref_species.type in V.races))
			return FALSE
	if(primary && V.virtuous_only && !prefs.statpack.virtuous)
		return FALSE
	return TRUE

/datum/character_setup_panel/proc/handle_set_context_preference(mob/user, kind, value)
	if(!kind)
		return
	switch(kind)
		if("age")
			if(value in prefs.pref_species.possible_ages)
				prefs.age = value
				var/list/hairs
				if((prefs.age == AGE_OLD) && (OLDGREY in prefs.pref_species.species_traits))
					hairs = prefs.pref_species.get_oldhc_list()
				else
					hairs = prefs.pref_species.get_hairc_list()
				prefs.hair_color = hairs[pick(hairs)]
				prefs.facial_hair_color = prefs.hair_color
				prefs.ResetJobs()
				post_update_after_action(user, "age")
		if("voicepack")
			if(value in GLOB.voice_packs_list)
				prefs.voice_pack = value
				post_update_after_action(user, "voicepack")
		if("char_accent")
			if(value in GLOB.character_accents)
				prefs.char_accent = value
				post_update_after_action(user, "char_accent")
		if("extra_language")
			if(value == "None")
				prefs.extra_language = "None"
				post_update_after_action(user, "extra_language")
			else
				var/language_type = text2path(value)
				if(language_type && ispath(language_type, /datum/language))
					prefs.extra_language = language_type
					post_update_after_action(user, "extra_language")
		if("combat_music")
			if(value in GLOB.cmode_tracks_by_name)
				prefs.combat_music = GLOB.cmode_tracks_by_name[value]
				post_update_after_action(user, "combat_music")
		if("taur_type")
			if(value == "None")
				prefs.taur_type = null
				post_update_after_action(user, "taur_type")
			else
				var/taur_type = text2path(value)
				if(taur_type && (taur_type in prefs.pref_species.get_taur_list()))
					prefs.taur_type = taur_type
					post_update_after_action(user, "taur_type")
		if("skin_tone")
			var/list/skin_list = prefs.pref_species?.get_skin_list()
			if(islist(skin_list) && !isnull(skin_list[value]))
				prefs.skin_tone = skin_list[value]
				prefs.features["mcolor"] = sanitize_hexcolor(prefs.skin_tone)
				if(hascall(prefs, "try_update_mutant_colors"))
					call(prefs, "try_update_mutant_colors")()
				post_update_after_action(user, "skin_tone")
		if("statpack")
			var/statpack_type = text2path(value)
			if(statpack_type && GLOB.statpacks[statpack_type])
				prefs.statpack = GLOB.statpacks[statpack_type]
				post_update_after_action(user, "statpack")
		if("faith")
			var/faith_type = text2path(value)
			if(faith_type && (faith_type in GLOB.preference_faiths))
				var/datum/faith/faith = GLOB.faithlist[faith_type]
				if(faith)
					prefs.selected_patron = GLOB.patronlist[faith.godhead] || GLOB.patronlist[pick(GLOB.patrons_by_faith[faith.name])]
					post_update_after_action(user, "faith")
		if("patron")
			var/patron_type = text2path(value)
			if(patron_type && GLOB.patronlist[patron_type])
				prefs.selected_patron = GLOB.patronlist[patron_type]
				post_update_after_action(user, "patron")
		if("virtue_primary")
			var/virtue_type = text2path(value)
			if(virtue_type && can_select_virtue(virtue_type, TRUE))
				prefs.virtue = new virtue_type
				post_update_after_action(user, "virtue")
		if("virtue_secondary")
			var/virtue_type = text2path(value)
			if(virtue_type && can_select_virtue(virtue_type, FALSE))
				prefs.virtuetwo = new virtue_type
				post_update_after_action(user, "virtuetwo")

/datum/character_setup_panel/proc/handle_set_descriptor_choice(mob/user, choice_type, descriptor_type)
	if(!(choice_type in prefs.pref_species.descriptor_choices))
		return
	var/datum/descriptor_choice/choice = DESCRIPTOR_CHOICE(choice_type)
	if(!choice || !(descriptor_type in choice.descriptors))
		return
	var/datum/descriptor_entry/entry = null
	if(hascall(prefs, "get_descriptor_entry_for_choice"))
		entry = call(prefs, "get_descriptor_entry_for_choice")(choice_type)
	if(!entry)
		return
	entry.descriptor_type = descriptor_type
	post_update_after_action(user, "descriptors")

/datum/character_setup_panel/proc/handle_set_custom_descriptor_prefix(mob/user, index, prefix_type)
	if(index < 1 || index > CUSTOM_DESCRIPTOR_AMOUNT)
		return
	if(length(prefs.custom_descriptors) < index)
		return
	var/datum/custom_descriptor_entry/custom_entry = prefs.custom_descriptors[index]
	custom_entry.prefix_type = sanitize_integer(prefix_type, 1, CUSTOM_PREFIX_AMOUNT, CUSTOM_PREFIX_HAS_A)
	post_update_after_action(user, "descriptors")

/datum/character_setup_panel/proc/handle_set_custom_descriptor_content(mob/user, index, value)
	if(index < 1 || index > CUSTOM_DESCRIPTOR_AMOUNT)
		return
	if(length(prefs.custom_descriptors) < index)
		return
	var/datum/custom_descriptor_entry/custom_entry = prefs.custom_descriptors[index]
	custom_entry.content_text = STRIP_HTML_SIMPLE(lowertext("[value]"), CUSTOM_DESCRIPTOR_TEXT_LENGTH)
	post_update_after_action(user, "descriptors")

/datum/character_setup_panel/proc/handle_set_culinary_preference(mob/user, preference_type, mode, value)
	if(!preference_type || !mode)
		return
	if(!prefs.culinary_preferences)
		prefs.culinary_preferences = list()
	if(mode == "food")
		var/food_type = text2path(value)
		if(!food_type || !ispath(food_type, /obj/item/reagent_containers/food/snacks))
			return
		var/opposite_preference = (preference_type == CULINARY_FAVOURITE_FOOD) ? CULINARY_HATED_FOOD : CULINARY_FAVOURITE_FOOD
		if(prefs.culinary_preferences[opposite_preference] == food_type)
			to_chat(user, span_warning("Нельзя выбрать одно и то же как любимое и нелюбимое."))
			return
		prefs.culinary_preferences[preference_type] = food_type
		post_update_after_action(user, "culinary")
	else if(mode == "drink")
		var/drink_type = text2path(value)
		if(!drink_type || !ispath(drink_type, /datum/reagent/consumable))
			return
		var/opposite_preference = (preference_type == CULINARY_FAVOURITE_DRINK) ? CULINARY_HATED_DRINK : CULINARY_FAVOURITE_DRINK
		if(prefs.culinary_preferences[opposite_preference] == drink_type)
			to_chat(user, span_warning("Нельзя выбрать один и тот же напиток как любимый и нелюбимый."))
			return
		prefs.culinary_preferences[preference_type] = drink_type
		post_update_after_action(user, "culinary")

/datum/character_setup_panel/proc/handle_set_familiar_name(mob/user, value)
	var/datum/familiar_prefs/fam = prefs.familiar_prefs
	if(!fam)
		return
	var/new_name = reject_bad_name("[value]")
	if(!new_name)
		to_chat(user, span_warning("Некорректное имя фамильяра."))
		return
	fam.familiar_name = new_name
	post_update_after_action(user, "familiar")

/datum/character_setup_panel/proc/handle_set_familiar_pronouns(mob/user, value)
	var/datum/familiar_prefs/fam = prefs.familiar_prefs
	if(!fam)
		return
	if(!(value in list(HE_HIM, SHE_HER, THEY_THEM, IT_ITS)))
		return
	fam.familiar_pronouns = value
	post_update_after_action(user, "familiar")

/datum/character_setup_panel/proc/handle_set_familiar_specie(mob/user, species_type)
	var/datum/familiar_prefs/fam = prefs.familiar_prefs
	if(!fam || !species_type)
		return
	for(var/species_name in GLOB.familiar_types)
		if(GLOB.familiar_types[species_name] == species_type)
			fam.familiar_specie = species_type
			post_update_after_action(user, "familiar")
			return

/datum/character_setup_panel/proc/handle_set_familiar_headshot(mob/user, value)
	var/datum/familiar_prefs/fam = prefs.familiar_prefs
	if(!fam)
		return
	var/link = trim("[value]")
	if(!length(link))
		fam.familiar_headshot_link = null
		post_update_after_action(user, "familiar")
		return
	if(!valid_headshot_link(user, link))
		to_chat(user, span_warning("Ссылка на портрет фамильяра не прошла проверку."))
		return
	fam.familiar_headshot_link = link
	post_update_after_action(user, "familiar")

/datum/character_setup_panel/proc/handle_set_familiar_flavortext(mob/user, value)
	var/datum/familiar_prefs/fam = prefs.familiar_prefs
	if(!fam)
		return
	var/text_value = "[value]"
	if(!length(text_value))
		fam.familiar_flavortext = null
		fam.familiar_flavortext_display = null
	else
		fam.familiar_flavortext = text_value
		var/ft = html_encode(parsemarkdown_basic(fam.familiar_flavortext))
		ft = replacetext(ft, "\n", "<BR>")
		fam.familiar_flavortext_display = ft
	post_update_after_action(user, "familiar")

/datum/character_setup_panel/proc/handle_set_familiar_ooc_notes(mob/user, value)
	var/datum/familiar_prefs/fam = prefs.familiar_prefs
	if(!fam)
		return
	var/text_value = "[value]"
	if(!length(text_value))
		fam.familiar_ooc_notes = null
		fam.familiar_ooc_notes_display = null
	else
		fam.familiar_ooc_notes = text_value
		var/ooc = html_encode(parsemarkdown_basic(fam.familiar_ooc_notes))
		ooc = replacetext(ooc, "\n", "<BR>")
		fam.familiar_ooc_notes_display = ooc
	post_update_after_action(user, "familiar")

/datum/character_setup_panel/proc/handle_set_familiar_ooc_extra(mob/user, value)
	var/datum/familiar_prefs/fam = prefs.familiar_prefs
	if(!fam)
		return
	var/link = trim("[value]")
	if(!length(link))
		fam.familiar_ooc_extra = null
		fam.familiar_ooc_extra_link = null
		post_update_after_action(user, "familiar")
		return
	var/static/list/valid_ext = list("jpg", "jpeg", "png", "gif", "mp4", "mp3")
	if(!valid_headshot_link(user, link, FALSE, valid_ext))
		to_chat(user, span_warning("Ссылка для OOC Extra фамильяра не прошла проверку."))
		return
	fam.familiar_ooc_extra_link = link
	var/ext = lowertext(splittext(link, ".")[length(splittext(link, "."))])
	switch(ext)
		if("jpg", "jpeg", "png", "gif")
			fam.familiar_ooc_extra = "<div align='center'><br><img src='[link]'/></div>"
		if("mp4")
			fam.familiar_ooc_extra = "<div align='center'><br><video width='288' height='288' controls><source src='[link]' type='video/mp4'></video></div>"
		if("mp3")
			fam.familiar_ooc_extra = "<div align='center'><br><audio controls><source src='[link]' type='audio/mp3'>Your browser does not support the audio element.</audio></div>"
	post_update_after_action(user, "familiar")

/datum/character_setup_panel/proc/handle_toggle_familiar_queue(mob/user)
	var/datum/familiar_prefs/fam = prefs.familiar_prefs
	if(!fam || !user?.client)
		return
	if(user.client in GLOB.familiar_queue)
		GLOB.familiar_queue -= user.client
		post_update_after_action(user, "familiar")
		return
	if(!fam.familiar_name || !fam.familiar_flavortext_display || !fam.familiar_specie)
		to_chat(user, span_warning("Чтобы встать в очередь фамильяров, нужно задать имя, описание и тип."))
		return
	GLOB.familiar_queue += user.client
	post_update_after_action(user, "familiar")

/datum/character_setup_panel/proc/handle_manage_charflaws(mob/user)
	for(var/datum/charflaw/_existing in prefs.charflaws)
		if(istype(_existing, /datum/charflaw/noflaw))
			prefs.charflaws.Remove(_existing)
			break
	if(prefs.charflaws.len >= MAX_VICES)
		to_chat(user, span_warning("Нельзя выбрать больше пороков."))
		return
	var/list/cf_list = GLOB.character_flaws.Copy()
	for(var/key in cf_list)
		if(cf_list[key] == /datum/charflaw/noflaw)
			cf_list.Remove(key)
			break
	for(var/datum/charflaw/cf in prefs.charflaws)
		for(var/key in cf_list)
			if(cf_list[key] == cf.type && !istype(cf, /datum/charflaw/randflaw))
				cf_list.Remove(key)
				break
	var/result = tgui_input_list(user, "Выберите порок.", "Пороки", cf_list)
	if(result)
		result = cf_list[result]
		var/datum/charflaw/C = new result()
		prefs.charflaws.Add(C)
		post_update_after_action(user, "charflaw")

/datum/character_setup_panel/proc/handle_manage_gallery(mob/user, nsfw = FALSE)
	var/list/current_gallery = nsfw ? prefs.nsfw_img_gallery : prefs.img_gallery
	if(!islist(current_gallery))
		current_gallery = list()
	var/gallery_name = nsfw ? "NSFW Image Gallery" : "Image Gallery"
	var/list/choices = list("Добавить", "Отмена")
	if(length(current_gallery))
		choices = list("Добавить", "Очистить", "Отмена")
	var/choice = tgui_alert(user, "Управление [gallery_name]. Сейчас изображений: [length(current_gallery)]/3.", gallery_name, choices)
	if(choice == "Добавить")
		if(length(current_gallery) >= 3)
			to_chat(user, span_warning("В галерее уже максимум три изображения."))
			return
		var/new_galleryimg = tgui_input_text(user, "Input the image link (https, hosts: gyazo, discord, lensdump, imgbox, catbox):", gallery_name, encode = FALSE)
		if(new_galleryimg == null)
			return
		if(!length(new_galleryimg))
			return
		if(!valid_headshot_link(user, new_galleryimg))
			to_chat(user, span_notice("Invalid image link. Make sure it's a direct link from a valid host (gyazo, discord, lensdump, imgbox, catbox)."))
			return
		current_gallery += new_galleryimg
		if(nsfw)
			prefs.nsfw_img_gallery = current_gallery
		else
			prefs.img_gallery = current_gallery
		post_update_after_action(user, nsfw ? "nsfw_img_gallery" : "img_gallery")
		return
	if(choice == "Очистить")
		var/confirm = tgui_alert(user, "Очистить [gallery_name]?", gallery_name, list("Да", "Нет"))
		if(confirm == "Да")
			if(nsfw)
				prefs.nsfw_img_gallery = list()
			else
				prefs.img_gallery = list()
			post_update_after_action(user, nsfw ? "nsfw_img_gallery" : "img_gallery")
	return

/datum/character_setup_panel/proc/hair_gradient_choice_list()
	var/list/choices = list()
	choices["Нет"] = null
	for(var/gradient_type as anything in subtypesof(/datum/hair_gradient))
		if(gradient_type == /datum/hair_gradient)
			continue
		var/datum/hair_gradient/gradient = HAIR_GRADIENT(gradient_type)
		if(gradient)
			choices[gradient.name] = gradient_type
	return choices

/datum/character_setup_panel/proc/post_update_after_action(mob/user, preference)
	prefs.validate_customizer_entries()
	prefs.validate_body_markings()
	if(preference == "gender")
		prefs.genderize_customizer_entries()

	var/static/list/visual_updates = list(
		"gender",
		"species",
		"subspecies",
		"customizer",
		"markings",
		"race_bonus_select",
		"body",
		"changeslot",
		"taur_type",
		"taur_color",
		"clothespref",
		"eyes",
		"s_tone",
		"body_size",
		"undo"
	)
	var/static/list/catalog_updates = list(
		"gender",
		"species",
		"subspecies",
		"customizer",
		"markings",
		"body",
		"changeslot",
		"taur_type",
		"taur_color",
		"clothespref",
		"undo"
	)
	var/static/list/job_updates = list(
		"gender",
		"species",
		"subspecies",
		"age",
		"statpack",
		"pronouns",
		"titles",
		"changeslot",
		"undo"
	)
	var/static/list/slot_summary_updates = list(
		"name",
		"changeslot",
		"undo"
	)
	var/static/list/details_updates = list(
		"name",
		"nickname",
		"gender",
		"species",
		"subspecies",
		"age",
		"statpack",
		"pronouns",
		"titles",
		"origin",
		"faith",
		"patron",
		"extra_language",
		"voicetype",
		"voicepack",
		"voice",
		"voice_pitch",
		"highlight_color",
		"combat_music",
		"dnr",
		"domhand",
		"char_accent",
		"virtue",
		"virtuetwo",
		"charflaw",
		"descriptors",
		"culinary",
		"familiar",
		"flavortext",
		"ooc_notes",
		"rumour",
		"noble_gossip",
		"nsfwflavortext",
		"erpprefs",
		"headshot_link",
		"lich_headshot_link",
		"vampire_headshot_link",
		"img_gallery",
		"nsfw_img_gallery",
		"ooc_extra",
		"change_artist",
		"change_title",
		"customizer",
		"body",
		"changeslot",
		"taur_type",
		"taur_color",
		"clothespref",
		"race_bonus_select",
		"charflaw_averse_choice",
		"undo"
	)

	var/owner_dirty_flags = CS_DIRTY_NONE
	var/jobs_dirty_flags = CS_JOBS_DIRTY_NONE

	if(preference in visual_updates)
		owner_dirty_flags |= CS_DIRTY_MAIN_PREVIEW

	if(preference in catalog_updates)
		owner_dirty_flags |= CS_DIRTY_CUSTOMIZER_CATALOG

	if(preference in slot_summary_updates)
		owner_dirty_flags |= CS_DIRTY_SLOT_SUMMARIES

	if(preference in details_updates)
		owner_dirty_flags |= CS_DIRTY_DETAILS

	if(preference in job_updates)
		owner_dirty_flags |= CS_DIRTY_JOBS_CACHE
		jobs_dirty_flags |= CS_JOBS_DIRTY_ALL

	push_ui_update(owner_dirty_flags, jobs_dirty_flags)

/datum/character_setup_panel/proc/push_ui_update(owner_dirty_flags = CS_DIRTY_NONE, jobs_panel_dirty_flags = CS_JOBS_DIRTY_NONE, force_owner_update = FALSE)
	queue_ui_update(owner_dirty_flags, jobs_panel_dirty_flags, force_owner_update)

/datum/character_setup_panel/proc/generate_main_preview_asset(mob/user)
	var/current_key = "[preview_revision]|[preview_dir]"
	if(!main_preview_dirty && current_key == main_preview_asset_key && last_main_preview_asset)
		return last_main_preview_asset
	var/asset = generate_cached_preview_asset(user, "main", "full", preview_dir)
	if(!asset && preview_dir != SOUTH)
		asset = generate_cached_preview_asset(user, "main_fallback", "full", SOUTH)
	if(!asset)
		asset = generate_cached_preview_asset(user, "main_upper_fallback", "upper", SOUTH)
	if(asset)
		last_main_preview_asset = asset
		main_preview_asset_key = current_key
		main_preview_dirty = FALSE
	return asset ? asset : last_main_preview_asset

/datum/character_setup_panel/proc/generate_cached_preview_asset(mob/user, cache_key, preview_focus, target_dir = SOUTH)
	var/full_key = "[preview_revision]|[cache_key]|[preview_focus]|[target_dir]"
	if(preview_asset_cache[full_key])
		return preview_asset_cache[full_key]
	var/filename = generate_preview_asset_from_current_prefs(user, full_key, preview_focus, target_dir)
	if(filename)
		preview_asset_cache[full_key] = filename
	return filename

/datum/character_setup_panel/proc/generate_preview_asset_from_current_prefs(mob/user, cache_key, preview_focus, target_dir = SOUTH)
	if(!user)
		user = last_user
	if(!user)
		return null

	if(SSwardrobe && hascall(SSwardrobe, "render_character_setup_preview"))
		var/wardrobe_preview = call(SSwardrobe, "render_character_setup_preview")(user, prefs, "[preview_revision]|[cache_key]", preview_focus, target_dir, preview_cache_scope)
		if(wardrobe_preview)
			return wardrobe_preview

	var/filename = "charsetup_[copytext(md5("[cache_key]"), 1, 9)].png"
	var/mob/living/carbon/human/dummy/mannequin = get_preview_dummy()
	if(!mannequin)
		return null

	prepare_preview_dummy(mannequin)
	prefs.copy_to(mannequin, 1, TRUE, TRUE)
	mannequin.dir = target_dir
	mannequin.rebuild_obscured_flags()
	mannequin.update_body()
	mannequin.update_hair()
	mannequin.update_body_parts(TRUE)
	if(hascall(mannequin, "regenerate_icons"))
		call(mannequin, "regenerate_icons")()
	if(hascall(mannequin, "update_icons"))
		call(mannequin, "update_icons")()

	var/icon/preview_icon = getFlatIcon(mannequin)
	if(!preview_icon || preview_icon_seems_broken(preview_icon, preview_focus))
		mannequin.rebuild_obscured_flags()
		mannequin.update_body()
		mannequin.update_hair()
		mannequin.update_body_parts(TRUE)
		if(hascall(mannequin, "regenerate_icons"))
			call(mannequin, "regenerate_icons")()
		if(hascall(mannequin, "update_icons"))
			call(mannequin, "update_icons")()
		var/icon/retry_icon = getFlatIcon(mannequin)
		if(retry_icon && !preview_icon_seems_broken(retry_icon, preview_focus))
			preview_icon = retry_icon

	release_preview_dummy(mannequin)
	if(!preview_icon || preview_icon_seems_broken(preview_icon, preview_focus))
		if(preview_focus == "full")
			return generate_preview_asset_from_current_prefs(user, "[cache_key]|upper_fallback", "upper", SOUTH)
		return null
	if(preview_focus == "full")
		var/icon/fixed_full_preview_icon = build_fixed_character_setup_full_preview_icon(preview_icon, target_dir, 32, 40, 16, 3, character_setup_preview_debug_logging ? "charsetup_preview" : null, target_dir)
		if(fixed_full_preview_icon)
			preview_icon = fixed_full_preview_icon
	else if(preview_focus == "head")
		var/icon/head_band_icon = extract_character_setup_head_features_icon(preview_icon, target_dir, "charsetup-head charsetup_panel_asset_head_band", target_dir)
		if(head_band_icon)
			preview_icon = head_band_icon
	else
		apply_preview_focus(preview_icon, preview_focus)
	user << browse_rsc(preview_icon, filename)
	return filename
/datum/character_setup_panel/proc/preview_icon_seems_broken(icon/preview_icon, preview_focus)
	if(!preview_icon)
		return TRUE
	switch(preview_focus)
		if("full")
			if(preview_icon.Width() <= 20 || preview_icon.Height() <= 20)
				return TRUE
		if("upper")
			if(preview_icon.Width() <= 16 || preview_icon.Height() <= 16)
				return TRUE
		else
			return FALSE
	return FALSE

/datum/character_setup_panel/proc/apply_preview_focus(icon/preview_icon, preview_focus)
	if(!preview_icon)
		return
	switch(preview_focus)
		if("upper")
			preview_icon.Crop(4, 10, 29, 32)
		if("head")
			preview_icon.Crop(9, 18, 24, 32)
		if("legs")
			preview_icon.Crop(10, 1, 22, 14)
		if("underwear")
			preview_icon.Crop(9, 7, 23, 18)
		if("groin")
			preview_icon.Crop(9, 4, 23, 18)
		if("torso")
			preview_icon.Crop(6, 6, 27, 26)
		else
			return

/datum/character_setup_panel/proc/get_customizer_preview_focus(datum/customizer/customizer)
	var/customizer_name = lowertext(customizer.name)
	if(findtext(customizer_name, "hair") || findtext(customizer_name, "волос") || findtext(customizer_name, "horn") || findtext(customizer_name, "рог") || findtext(customizer_name, "ear") || findtext(customizer_name, "уш") || findtext(customizer_name, "brow") || findtext(customizer_name, "face") || findtext(customizer_name, "лиц") || findtext(customizer_name, "accessory") || findtext(customizer_name, "аксесс"))
		return "head"
	if(findtext(customizer_name, "legwear") || findtext(customizer_name, "stocking") || findtext(customizer_name, "sock") || findtext(customizer_name, "чул") || findtext(customizer_name, "нос"))
		return "legs"
	if(findtext(customizer_name, "underwear") || findtext(customizer_name, "бель"))
		return "underwear"
	if(findtext(customizer_name, "tail") || findtext(customizer_name, "хвост") || findtext(customizer_name, "wing") || findtext(customizer_name, "крыл"))
		return "torso"
	return "torso"

/datum/character_setup_panel/proc/customizer_group(datum/customizer/customizer)
	if(!customizer)
		return "body"
	var/customizer_name = lowertext(customizer.name)
	if(findtext(customizer_name, "penis") || findtext(customizer_name, "член") || findtext(customizer_name, "testicle") || findtext(customizer_name, "яич") || findtext(customizer_name, "vagina") || findtext(customizer_name, "влаг") || findtext(customizer_name, "breast") || findtext(customizer_name, "груд") || findtext(customizer_name, "piercing") || findtext(customizer_name, "пирс"))
		return "simple"
	return "body"

/datum/character_setup_panel/proc/translate_customizer_name(name)
	switch(name)
		if("Hair")
			return "Волосы"
		if("Facial Hair")
			return "Волосы на лице"
		if("Ears")
			return "Уши"
		if("Eyes")
			return "Глаза"
		if("Accessory")
			return "Аксессуар"
		if("Face Detail")
			return "Детали лица"
		if("Underwear")
			return "Нижнее бельё"
		if("Legwear")
			return "Носки и чулки"
		if("Piercing")
			return "Пирсинг"
		if("Horns")
			return "Рога"
		if("Tail")
			return "Хвост"
		if("Testicles")
			return "Яички"
		if("Penis")
			return "Пенис"
		if("Vagina")
			return "Влагалище"
		if("Breasts")
			return "Грудь"
		if("Wings")
			return "Крылья"
	return name

/datum/character_setup_panel/proc/build_body_marking_catalog()
	var/static/list/shared_body_marking_catalog_by_key = list()
	var/species_cache_key = (prefs && prefs.pref_species) ? "[prefs.pref_species.type]" : "none"
	var/gender_cache_key = prefs ? "[prefs.gender]" : "none"
	var/taur_cache_key = prefs ? "[prefs.taur_type]" : "none"
	var/cache_key = "[species_cache_key]|[gender_cache_key]|[taur_cache_key]"
	if(cached_body_marking_catalog && cached_body_marking_catalog_key == cache_key)
		return cached_body_marking_catalog
	if(shared_body_marking_catalog_by_key[cache_key])
		cached_body_marking_catalog_key = cache_key
		cached_body_marking_catalog = shared_body_marking_catalog_by_key[cache_key]
		return cached_body_marking_catalog

	var/list/output = list()
	var/list/zones = list(
		BODY_ZONE_HEAD = "Голова",
		BODY_ZONE_CHEST = "Грудь",
		BODY_ZONE_L_ARM = "Левая рука",
		BODY_ZONE_R_ARM = "Правая рука",
		BODY_ZONE_PRECISE_L_HAND = "Левая кисть",
		BODY_ZONE_PRECISE_R_HAND = "Правая кисть",
		BODY_ZONE_L_LEG = "Левая нога",
		BODY_ZONE_R_LEG = "Правая нога"
	)

	for(var/zone in zones)
		var/list/options = list()
		for(var/marking_type as anything in subtypesof(/datum/body_marking))
			if(marking_type == /datum/body_marking)
				continue
			var/datum/body_marking/marking = new marking_type()
			if(!marking || !body_marking_matches_zone(marking, zone))
				qdel(marking)
				continue
			if(!body_marking_allowed_for_current_prefs(zone, marking.name))
				qdel(marking)
				continue
			options += list(list(
				name = marking.name
			))
			qdel(marking)

		if(options.len)
			output += list(list(
				zone = "[zone]",
				label = zones[zone],
				options = sortList(options, GLOBAL_PROC_REF(cmp_body_marking_name_asc))
			))

	cached_body_marking_catalog_key = cache_key
	cached_body_marking_catalog = output
	shared_body_marking_catalog_by_key[cache_key] = output
	return output

/datum/character_setup_panel/proc/copy_body_markings(list/source)
	var/list/out = list()
	if(!source)
		return out
	for(var/zone in source)
		var/list/zone_markings = source[zone]
		out[zone] = islist(zone_markings) ? zone_markings.Copy() : zone_markings
	return out

/datum/character_setup_panel/proc/body_marking_allowed_for_current_prefs(zone, name)
	var/static/list/body_marking_allowed_cache = list()
	if(!prefs || !zone || !name)
		return FALSE
	var/cache_key = "[prefs.pref_species ? prefs.pref_species.type : null]|[prefs.gender]|[prefs.taur_type]|[zone]|[name]"
	if(!isnull(body_marking_allowed_cache[cache_key]))
		return !!body_marking_allowed_cache[cache_key]
	var/list/original_markings = copy_body_markings(prefs.body_markings)
	if(!prefs.body_markings)
		prefs.body_markings = list()
	if(!prefs.body_markings[zone])
		prefs.body_markings[zone] = list()
	var/list/zone_markings = prefs.body_markings[zone]
	if(!(name in zone_markings))
		zone_markings += name
	prefs.validate_body_markings()
	var/list/validated_zone_markings = prefs.body_markings[zone]
	var/allowed = !!(validated_zone_markings && (name in validated_zone_markings))
	prefs.body_markings = original_markings
	prefs.validate_body_markings()
	body_marking_allowed_cache[cache_key] = allowed
	return allowed

/proc/cmp_body_marking_name_asc(a, b)
	var/list/la = a
	var/list/lb = b
	return sorttext("[la["name"]]", "[lb["name"]]")

/datum/character_setup_panel/proc/body_marking_matches_zone(datum/body_marking/marking, zone)
	if(!marking)
		return FALSE
	switch(zone)
		if(BODY_ZONE_HEAD)
			return !!(marking.affected_bodyparts & HEAD)
		if(BODY_ZONE_CHEST)
			return !!(marking.affected_bodyparts & CHEST)
		if(BODY_ZONE_L_ARM)
			return !!(marking.affected_bodyparts & ARM_LEFT)
		if(BODY_ZONE_R_ARM)
			return !!(marking.affected_bodyparts & ARM_RIGHT)
		if(BODY_ZONE_PRECISE_L_HAND)
			return !!(marking.affected_bodyparts & HAND_LEFT)
		if(BODY_ZONE_PRECISE_R_HAND)
			return !!(marking.affected_bodyparts & HAND_RIGHT)
		if(BODY_ZONE_L_LEG)
			return !!(marking.affected_bodyparts & LEG_LEFT)
		if(BODY_ZONE_R_LEG)
			return !!(marking.affected_bodyparts & LEG_RIGHT)
	return FALSE

/datum/character_setup_panel/proc/generate_body_marking_preview_asset(datum/body_marking/marking, zone)
	if(!last_user || !marking)
		return null
	var/cache_key = "[preview_revision]|marking|[zone]|[marking.name]"
	if(preview_asset_cache[cache_key])
		return preview_asset_cache[cache_key]
	var/icon/preview_icon = icon(marking.icon, marking.icon_state)
	if(!preview_icon)
		return null
	var/focus = "torso"
	switch(zone)
		if(BODY_ZONE_HEAD)
			focus = "head"
		if(BODY_ZONE_CHEST)
			focus = "torso"
		if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
			focus = "legs"
		if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND)
			focus = "upper"
	apply_preview_focus(preview_icon, focus)
	var/filename = "marking_[copytext(md5(cache_key), 1, 9)].png"
	last_user << browse_rsc(preview_icon, filename)
	preview_asset_cache[cache_key] = filename
	return filename

/datum/character_setup_panel/proc/zone_label(zone)
	switch(zone)
		if(BODY_ZONE_R_ARM)
			return "Правая рука"
		if(BODY_ZONE_L_ARM)
			return "Левая рука"
		if(BODY_ZONE_HEAD)
			return "Голова"
		if(BODY_ZONE_CHEST)
			return "Грудь"
		if(BODY_ZONE_R_LEG)
			return "Правая нога"
		if(BODY_ZONE_L_LEG)
			return "Левая нога"
		if(BODY_ZONE_PRECISE_R_HAND)
			return "Правая кисть"
		if(BODY_ZONE_PRECISE_L_HAND)
			return "Левая кисть"
	return "Неизвестно"

/datum/character_setup_panel/proc/gender_label(gender)
	switch(gender)
		if(MALE)
			return "Мужчина"
		if(FEMALE)
			return "Женщина"
	return "Неопределённый"

/datum/character_setup_panel/proc/pronoun_gender_label(pronouns, gender)
	if(pronouns == SHE_HER)
		return "Женщина"
	if(pronouns == HE_HIM)
		return "Мужчина"

	var/pronouns_text = lowertext("[pronouns]")
	if(findtext(pronouns_text, "they") || findtext(pronouns_text, "them") || findtext(pronouns_text, "it/its") || findtext(pronouns_text, "it") || findtext(pronouns_text, "они"))
		return "Неопределённый"
	if(findtext(pronouns_text, "she") || findtext(pronouns_text, "her") || findtext(pronouns_text, "она"))
		return "Женщина"
	if(findtext(pronouns_text, "he") || findtext(pronouns_text, "him") || findtext(pronouns_text, "он"))
		return "Мужчина"

	return gender_label(gender)

/datum/character_setup_panel/proc/taur_label(taur_type)
	var/obj/item/bodypart/taur/T = taur_type
	return ispath(T) ? T::name : "Нет"

/datum/character_setup_panel/proc/hair_gradient_label(gradient_type)
	if(!gradient_type)
		return "Нет"
	var/datum/hair_gradient/gradient = HAIR_GRADIENT(gradient_type)
	return gradient ? gradient.name : "Нет"
