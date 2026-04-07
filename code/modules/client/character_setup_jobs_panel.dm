
#ifndef CS_DIRTY_JOBS_CACHE
#define CS_DIRTY_JOBS_CACHE            (1<<4)
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

/datum/character_setup_jobs_panel
	parent_type = /datum/character_setup_panel
	var/datum/character_setup_panel/owner_panel
	var/list/active_job_detail = null
	var/tmp/jobs_dirty_flags = CS_JOBS_DIRTY_ALL
	var/tmp/list/cached_jobs_panel_data = null

/datum/character_setup_jobs_panel/New(datum/preferences/prefs_owner, datum/character_setup_panel/owner)
	owner_panel = owner
	return ..(prefs_owner)

/datum/character_setup_jobs_panel/ui_interact(mob/user, datum/tgui/ui)
	last_user = user
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CharacterSetupJobs")
		ui.open()

/datum/character_setup_jobs_panel/ui_data(mob/user)
	if(!cached_jobs_panel_data)
		cached_jobs_panel_data = list()
	if(!prefs || !user)
		return cached_jobs_panel_data

	if(jobs_dirty_flags & CS_JOBS_DIRTY_LIST)
		cached_jobs_panel_data["job_entries"] = build_jobs_panel_entries(user)
		cached_jobs_panel_data["job_slot_target"] = active_job_slot_title
		cached_jobs_panel_data["job_slot_choices"] = active_job_slot_title ? (owner_panel ? owner_panel.build_job_slot_choices(active_job_slot_title) : build_job_slot_choices(active_job_slot_title)) : list()
		cached_jobs_panel_data["current_joblessrole"] = "[prefs.joblessrole]"

	if(jobs_dirty_flags & CS_JOBS_DIRTY_DETAIL)
		cached_jobs_panel_data["active_job_detail"] = active_job_detail

	jobs_dirty_flags = CS_JOBS_DIRTY_NONE
	return cached_jobs_panel_data

/datum/character_setup_jobs_panel/proc/apply_dirty_flags_from_owner(flags)
	if(!flags)
		return
	jobs_dirty_flags |= flags

/datum/character_setup_jobs_panel/proc/push_both_updates(job_panel_dirty_flags = CS_JOBS_DIRTY_ALL, owner_dirty_flags = CS_DIRTY_JOBS_CACHE)
	jobs_dirty_flags |= job_panel_dirty_flags
	if(owner_panel)
		owner_panel.queue_ui_update(owner_dirty_flags, job_panel_dirty_flags)
	else
		SStgui.update_uis(src)

/datum/character_setup_jobs_panel/proc/build_jobs_panel_entries(mob/user)
	if(owner_panel && hascall(owner_panel, "build_job_entries"))
		return owner_panel.build_job_entries(user)

	var/list/output = list()
	if(!SSjob || !user || !user.client)
		return output
	return output


/datum/character_setup_jobs_panel/proc/sanitize_job_panel_text(value)
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
		// common HTML markup from old job/class descriptions
		text = replacetext(text, "<br>", "\n")
		text = replacetext(text, "<br/>", "\n")
		text = replacetext(text, "<br />", "\n")
		text = replacetext(text, "&nbsp;", " ")

		// strip common span wrappers and any remaining simple html tags defensively
		if(findtext(text, "<"))
			text = strip_simple_html_tags(text)

		// normalize line endings and repeated blank lines a bit
		if(findtext(text, ascii2text(13)))
			text = replacetext(text, ascii2text(13), "")
		while(findtext(text, "\n\n\n"))
			text = replacetext(text, "\n\n\n", "\n\n")

	if(length(job_panel_text_cache) > 2048)
		job_panel_text_cache = list()
	job_panel_text_cache[original_text] = text
	return text

/datum/character_setup_jobs_panel/proc/strip_simple_html_tags(text)
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

/datum/character_setup_jobs_panel/proc/build_stat_rows(list/source)
	var/list/rows = list()
	if(!islist(source))
		return rows
	for(var/stat in source)
		var/value = source[stat]
		rows += list(list(
			"name" = capitalize("[stat]"),
			"value" = "\Roman[value]",
			"positive" = (isnum(value) ? (value >= 0) : null),
		))
	return rows

/datum/character_setup_jobs_panel/proc/build_trait_rows(list/source)
	var/list/rows = list()
	if(!islist(source))
		return rows
	for(var/trait in source)
		rows += list(list(
			"name" = "[trait]",
			"description" = sanitize_job_panel_text(GLOB.roguetraits[trait]),
		))
	return rows

/datum/character_setup_jobs_panel/proc/build_string_rows(list/source)
	var/list/rows = list()
	if(!islist(source))
		return rows
	for(var/item in source)
		rows += sanitize_job_panel_text(item)
	return rows

/datum/character_setup_jobs_panel/proc/build_skill_rows(list/source)
	var/list/rows = list()
	if(!islist(source))
		return rows
	var/list/notable_skills = list()
	for(var/sk in source)
		if(source[sk] >= SKILL_LEVEL_JOURNEYMAN)
			notable_skills[sk] = source[sk]
		else if(ispath(sk, /datum/skill/combat))
			notable_skills[sk] = source[sk]
	if(!length(notable_skills))
		return rows
	notable_skills = sortTim(notable_skills, /proc/cmp_numeric_dsc, TRUE)
	var/max_skills = 5
	for(var/sk in notable_skills)
		if(max_skills <= 0)
			break
		var/datum/skill/skill = sk
		var/skill_name = sanitize_job_panel_text(initial(skill.name))
		var/skill_level = sanitize_job_panel_text(SSskills.level_names[notable_skills[sk]])
		rows += "[skill_name] — [skill_level]"
		max_skills--
	return rows

/datum/character_setup_jobs_panel/proc/build_mage_aspect_rows(list/aspect_cfg)
	var/list/rows = list()
	if(!islist(aspect_cfg) || !LAZYLEN(aspect_cfg))
		return rows
	if(aspect_cfg["mastery"])
		rows += sanitize_job_panel_text("Mastery: Unlocked")
	if(aspect_cfg["major"] > 0)
		rows += sanitize_job_panel_text("Major Aspects: [aspect_cfg["major"]]")
	if(aspect_cfg["minor"] > 0)
		rows += sanitize_job_panel_text("Minor Aspects: [aspect_cfg["minor"]]")
	if(aspect_cfg["utilities"] > 0)
		rows += sanitize_job_panel_text("Utility Slots: [aspect_cfg["utilities"]]")
	if(LAZYLEN(aspect_cfg["locked_aspects"]))
		var/list/locked_names = list()
		var/list/locked = aspect_cfg["locked_aspects"]
		for(var/aspect_path in locked)
			var/datum/magic_aspect/A = aspect_path
			locked_names += "[initial(A.name)]"
		rows += sanitize_job_panel_text("Innate: [jointext(locked_names, ", ")]")
	if(islist(aspect_cfg["variants"]))
		var/list/overrides = aspect_cfg["variants"]
		for(var/aspect_path in overrides)
			var/datum/magic_aspect/A = aspect_path
			rows += sanitize_job_panel_text("Tradition: [capitalize(overrides[aspect_path])] [initial(A.name)]")
	return rows

/datum/character_setup_jobs_panel/proc/build_language_rows(list/source)
	var/list/rows = list()
	if(!islist(source))
		return rows
	for(var/lang_path in source)
		var/datum/language/lang = lang_path
		rows += sanitize_job_panel_text(initial(lang.name))
	return rows

/datum/character_setup_jobs_panel/proc/build_subclass_payload(datum/advclass/adv_ref)
	if(!adv_ref)
		return null

	var/list/subclass = list(
		"id" = "[initial(adv_ref.name)]",
		"name" = "[adv_ref.name]",
		"description" = adv_ref.tutorial ? sanitize_job_panel_text(adv_ref.tutorial) : null,
		"stat_bonuses" = build_stat_rows(adv_ref.subclass_stats),
		"stat_limits" = build_stat_rows(adv_ref.adv_stat_ceiling),
		"traits" = build_trait_rows(adv_ref.traits_applied),
		"notable_skills" = build_skill_rows(adv_ref.subclass_skills),
		"virtues" = list(),
		"stashed_items" = build_string_rows(adv_ref.subclass_stashed_items),
		"languages" = build_language_rows(adv_ref.subclass_languages),
		"mage_aspects" = build_mage_aspect_rows(adv_ref.subclass_mage_aspects),
		"extra_context" = list(),
	)

	if(length(adv_ref.subclass_virtues))
		var/list/virtues = list()
		for(var/virtue_type in adv_ref.subclass_virtues)
			var/datum/virtue/virtue = virtue_type
			virtues += "[initial(virtue.name)]"
		subclass["virtues"] = virtues

	var/list/extra = list()
	if(adv_ref.extra_context)
		extra += sanitize_job_panel_text(adv_ref.extra_context)
	if(istype(adv_ref.age_mod))
		extra += "[adv_ref.age_mod.get_preview_string()]"
	subclass["extra_context"] = extra

	return subclass

/datum/character_setup_jobs_panel/proc/build_job_detail_payload(datum/job/job)
	if(!job)
		return null

	var/list/detail = list(
		"title" = job.display_title ? "[job.display_title]" : "[job.title]",
		"description" = job.tutorial ? sanitize_job_panel_text(job.tutorial) : null,
		"class_stats" = build_stat_rows(job.job_stats),
		"class_stat_limits" = build_stat_rows(job.stat_ceilings),
		"class_traits" = build_trait_rows(job.job_traits),
		"subclasses" = list(),
		"note" = sanitize_job_panel_text("This information is not all-encompassing. Many classes have other quirks and skills that define them."),
	)

	if((prefs?.titles_pref == TITLES_F) && job.f_title)
		detail["title"] = "[job.f_title]"

	if(length(job.job_subclasses))
		var/list/subclasses = list()
		for(var/sclass in job.job_subclasses)
			var/datum/advclass/adv = sclass
			var/datum/advclass/adv_ref = SSrole_class_handler.get_advclass_by_name(initial(adv.name))
			if(!adv_ref)
				continue
			var/list/subclass_payload = build_subclass_payload(adv_ref)
			if(subclass_payload)
				subclasses += list(subclass_payload)
		detail["subclasses"] = subclasses

	if(istype(job, /datum/job/roguetown/jester))
		detail["description"] = "Come one, come all, where Psydon Lies!\nLet Xylix roll the dice,\nunto our untimely demise! Ahahaha!"
		detail["class_stats"] = list(
			list("name" = "STR", "value" = "???"),
			list("name" = "WIL", "value" = "???"),
			list("name" = "CON", "value" = "???"),
			list("name" = "PER", "value" = "???"),
			list("name" = "INT", "value" = "???"),
			list("name" = "FOR", "value" = "???"),
		)
		detail["class_stat_limits"] = list()
		detail["class_traits"] = list()
		detail["subclasses"] = list()
		detail["note"] = null

	return detail

/datum/character_setup_jobs_panel/proc/set_active_job_details(datum/job/job)
	if(!job || !job.class_setup_examine)
		active_job_detail = null
		jobs_dirty_flags |= CS_JOBS_DIRTY_DETAIL
		return
	active_job_detail = build_job_detail_payload(job)
	jobs_dirty_flags |= CS_JOBS_DIRTY_DETAIL

/datum/character_setup_jobs_panel/ui_act(action, params)
	if(!prefs)
		return ..()

	switch(action)
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
				push_both_updates(CS_JOBS_DIRTY_ALL, CS_DIRTY_JOBS_CACHE)
			return TRUE

		if("reset_jobs")
			prefs.ResetJobs()
			push_both_updates(CS_JOBS_DIRTY_ALL, CS_DIRTY_JOBS_CACHE)
			return TRUE

		if("cycle_joblessrole")
			switch(prefs.joblessrole)
				if(RETURNTOLOBBY)
					prefs.joblessrole = BERANDOMJOB
				if(BERANDOMJOB)
					prefs.joblessrole = RETURNTOLOBBY
				else
					prefs.joblessrole = RETURNTOLOBBY
			prefs.save_preferences()
			push_both_updates(CS_JOBS_DIRTY_ALL, CS_DIRTY_JOBS_CACHE)
			return TRUE

		if("open_job_slot")
			active_job_slot_title = params["job"]
			push_both_updates(CS_JOBS_DIRTY_LIST, 0)
			return TRUE

		if("assign_job_slot")
			if(active_job_slot_title)
				var/slot = params["slot"]
				if(slot == "default")
					prefs.job_characters -= active_job_slot_title
				else
					prefs.job_characters[active_job_slot_title] = text2num(slot)
				active_job_slot_title = null
				prefs.save_preferences()
				push_both_updates(CS_JOBS_DIRTY_ALL, CS_DIRTY_JOBS_CACHE)
			return TRUE

		if("open_job_details")
			var/job_title = params["job"]
			var/datum/job/job = SSjob ? SSjob.GetJob(job_title) : null
			if(job)
				set_active_job_details(job)
				push_both_updates(CS_JOBS_DIRTY_DETAIL, 0)
			return TRUE

		if("close_job_details")
			active_job_detail = null
			push_both_updates(CS_JOBS_DIRTY_DETAIL, 0)
			return TRUE

	return ..()
