//PORTED FROM /tg/station
//https://github.com/tgstation/tgstation/pull/63225


/// This subsystem strives to make loading large amounts of select objects as smooth at execution as possible
/// It preloads a set of types to store, and caches them until requested
/// Doesn't catch everything mind, this is intentional. There's many types that expect to either
/// A: Not sit in a list for 2 hours, or B: have extra context passed into them, or for their parent to be their location
/// You should absolutely not spam this system, it will break things in new and wonderful ways
/// S close enough for government work though.
/// Fuck you goonstation
SUBSYSTEM_DEF(wardrobe)
	name = "Wardrobe"
	wait = 10 // This is more like a queue then anything else
	flags = SS_BACKGROUND
	init_order = INIT_ORDER_WARDROBE
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT // We're going to fill up our cache while players sit in the lobby
	/// How much to cache outfit items
	/// Multiplier, 2 would mean cache enough items to stock 1 of each preloaded order twice, etc
	var/cache_intensity = 2
	/// How many more then the template of a type are we allowed to have before we delete applicants?
	var/overflow_lienency = 2
	/// List of type -> list(insertion callback, removal callback) callbacks for insertion/removal to use.
	/// Set in setup_callbacks, used in canonization.
	var/list/initial_callbacks = list()
	/// Canonical list of types required to fill all preloaded stocks once.
	/// Type -> list(count, last inspection timestamp, call on insert, call on removal)
	var/list/canon_minimum = list()
	/// List of types to load. Type -> count //(I'd do a list of lists but this needs to be refillable)
	var/list/order_list = list()
	/// List of lists. Contains our preloaded atoms. Type -> list(last inspect time, list(instances))
	var/list/preloaded_stock = list()
	/// The last time we inspected our stock
	var/last_inspect_time = 0
	/// How often to inspect our stock, in deciseconds
	var/inspect_delay = 30 SECONDS
	/// What we're currently doing
	var/current_task = SSWARDROBE_STOCK
	/// How many times we've had to generate a stock item on request
	var/stock_miss = 0
	/// How many times we've successfully returned a cached item
	var/stock_hit = 0
	/// How many items would we make just by loading the master list once?
	var/one_go_master = 0
	/// Item types that should not ever be recycled, only generated (like modsuits)
	var/static/list/recycle_blacklist = typecacheof(list( ))

/datum/controller/subsystem/wardrobe/Initialize()
	setup_callbacks()
	load_outfits()
	load_species()
	load_storage_contents()
	hard_refresh_queue()
	stock_hit = 0
	stock_miss = 0
	return ..()

/// Resets the load queue to the master template, accounting for the existing stock
/datum/controller/subsystem/wardrobe/proc/hard_refresh_queue()
	for(var/datum/type_to_queue as anything in canon_minimum)
		var/list/master_info = canon_minimum[type_to_queue]
		var/amount_to_load = master_info[WARDROBE_CACHE_COUNT] * cache_intensity

		var/list/stock_info = preloaded_stock[type_to_queue]
		if(stock_info) // If we already have stuff, reduce the amount we load
			amount_to_load -= length(stock_info[WARDROBE_STOCK_CONTENTS])
		set_queue_item(type_to_queue, amount_to_load)

/datum/controller/subsystem/wardrobe/stat_entry(msg)
	var/total_provided = max(stock_hit + stock_miss, 1)
	var/current_max_store = (one_go_master * cache_intensity) + (overflow_lienency * length(canon_minimum))
	msg += "\n  P:[length(canon_minimum)] Q:[length(order_list)] S:[length(preloaded_stock)] I:[cache_intensity] O:[overflow_lienency] MAX:[current_max_store]"
	msg += "\n  H:[stock_hit] M:[stock_miss] T:[total_provided] H/T:[PERCENT(stock_hit / total_provided)]% M/T:[PERCENT(stock_miss / total_provided)]%"
	msg += "\n  ID:[inspect_delay] NI:[last_inspect_time + inspect_delay]"
	return ..()

/datum/controller/subsystem/wardrobe/fire(resumed=FALSE)
	if(current_task != SSWARDROBE_INSPECT && world.time - last_inspect_time >= inspect_delay)
		current_task = SSWARDROBE_INSPECT

	switch(current_task)
		if(SSWARDROBE_STOCK)
			stock_wardrobe()
		if(SSWARDROBE_INSPECT)
			run_inspection()
			if(state != SS_RUNNING)
				return
			current_task = SSWARDROBE_STOCK
			last_inspect_time = world.time

/// Turns the order list into actual loaded items, this is where most work is done
/datum/controller/subsystem/wardrobe/proc/stock_wardrobe()
	for(var/atom/movable/type_to_stock as anything in order_list)
		var/amount_to_stock = order_list[type_to_stock]
		for(var/i in 1 to amount_to_stock)
			if(MC_TICK_CHECK)
				order_list[type_to_stock] = (amount_to_stock - (i - 1)) // Account for types we've already created
				return
			var/atom/movable/new_member = new type_to_stock()
			stash_object(new_member)

		order_list -= type_to_stock
		if(MC_TICK_CHECK)
			return

/// Once every medium while, go through the current stock and make sure we don't have too much of one thing
/// Or that we're not too low on some other stock
/// This exists as a failsafe, so the wardrobe doesn't just end up generating too many items or accidentially running out somehow
/datum/controller/subsystem/wardrobe/proc/run_inspection()
	for(var/datum/loaded_type as anything in canon_minimum)
		var/list/master_info = canon_minimum[loaded_type]
		var/last_looked_at = master_info[WARDROBE_CACHE_LAST_INSPECT]
		if(last_looked_at == last_inspect_time)
			continue

		var/list/stock_info = preloaded_stock[loaded_type]
		var/amount_held = 0
		if(stock_info)
			var/list/held_objects = stock_info[WARDROBE_STOCK_CONTENTS]
			amount_held = length(held_objects)

		var/target_stock = master_info[WARDROBE_CACHE_COUNT] * cache_intensity
		var/target_delta = amount_held - target_stock
		// If we've got too much
		if(target_delta > overflow_lienency)
			unload_stock(loaded_type, target_delta - overflow_lienency)
			if(state != SS_RUNNING)
				return

		// If we have more then we target, just don't you feel me?
		target_delta = min(target_delta, 0) //I only want negative numbers to matter here

		// If we don't have enough, queue enough to make up the remainder
		// If we have too much in the queue, cull to 0. We do this so time isn't wasted creating and destroying entries
		set_queue_item(loaded_type, abs(target_delta))

		master_info[WARDROBE_CACHE_LAST_INSPECT] = last_inspect_time

		if(MC_TICK_CHECK)
			return

/// Takes a path to get the callback owner for
/// Returns the deepest path in our callback store that matches the input
/// The hope is this will prevent dumb conflicts, since the furthest down is always going to be the most relevant
/datum/controller/subsystem/wardrobe/proc/get_callback_type(datum/to_check)
	var/longest_path
	var/longest_path_length = 0
	for(var/datum/path as anything in initial_callbacks)
		if(ispath(to_check, path))
			var/stringpath = "[path]"
			var/pathlength = length(splittext(stringpath, "/")) // We get the "depth" of the path
			if(pathlength < longest_path_length)
				continue
			longest_path = path
			longest_path_length = pathlength
	return longest_path

/**
 * Canonizes the type, which means it's now managed by the subsystem, and will be created deleted and passed out to comsumers
 *
 * Arguments:
 * * type to stock - What type exactly do you want us to remember?
 *
*/
/datum/controller/subsystem/wardrobe/proc/canonize_type(type_to_stock)
	if(!type_to_stock)
		return
	if(!ispath(type_to_stock))
		stack_trace("Non path [type_to_stock] attempted to canonize itself. Something's fucky")
	var/list/master_info = canon_minimum[type_to_stock]
	if(!master_info)
		master_info = new /list(WARDROBE_CACHE_CALL_REMOVAL)
		master_info[WARDROBE_CACHE_COUNT] = 0
		//Decide on the appropriate callbacks to use
		var/callback_type = get_callback_type(type_to_stock)
		var/list/callback_info = initial_callbacks[callback_type]
		if(callback_info)
			master_info[WARDROBE_CACHE_CALL_INSERT] = callback_info[WARDROBE_CALLBACK_INSERT]
			master_info[WARDROBE_CACHE_CALL_REMOVAL] = callback_info[WARDROBE_CALLBACK_REMOVE]
		canon_minimum[type_to_stock] = master_info
	master_info[WARDROBE_CACHE_COUNT] += 1
	one_go_master++

/datum/controller/subsystem/wardrobe/proc/add_queue_item(queued_type, amount)
	var/amount_held = order_list[queued_type] || 0
	set_queue_item(queued_type, amount_held + amount)

/datum/controller/subsystem/wardrobe/proc/remove_queue_item(queued_type, amount)
	var/amount_held = order_list[queued_type]
	if(!amount_held)
		return
	set_queue_item(queued_type, amount_held - amount)

/datum/controller/subsystem/wardrobe/proc/set_queue_item(queued_type, amount)
	var/list/master_info = canon_minimum[queued_type]
	if(!master_info)
		stack_trace("We just tried to queue a type \[[queued_type]\] that's not stored in the master canon")
		return

	var/target_amount = master_info[WARDROBE_CACHE_COUNT] * cache_intensity
	var/list/stock_info = preloaded_stock[queued_type]
	if(stock_info)
		target_amount -= length(stock_info[WARDROBE_STOCK_CONTENTS])

	amount = min(amount, target_amount) // If we're trying to set more then we need, don't!

	if(amount <= 0) // If we already have all we need, end it
		order_list -= queued_type
		return

	order_list[queued_type] = amount

/// Take an existing object, and recycle it if we are allowed to by stashing it back into our storage
/datum/controller/subsystem/wardrobe/proc/recycle_object(obj/item/object)
	// Don't restock blacklisted items, instead just delete them
	if(is_type_in_typecache(object, recycle_blacklist))
		qdel(object)
		return
	stash_object(object)

/// Take an existing object, and insert it into our storage
/// If we can't or won't take it, it's deleted. You do not own this object after passing it in
/datum/controller/subsystem/wardrobe/proc/stash_object(obj/item/object)
	var/object_type = object.type
	var/list/master_info = canon_minimum[object_type]
	// I will not permit objects you didn't reserve ahead of time
	if(!master_info)
		qdel(object)
		return

	var/stock_target = master_info[WARDROBE_CACHE_COUNT] * cache_intensity
	var/amount_held = 0
	var/list/stock_info = preloaded_stock[object_type]
	if(stock_info)
		amount_held = length(stock_info[WARDROBE_STOCK_CONTENTS])

	// Doublely so for things we already have too much of
	if(amount_held - stock_target >= overflow_lienency)
		qdel(object)
		return
	// Fuck off
	if(QDELETED(object))
		stack_trace("We tried to stash a qdeleted object, what did you do")
		return

	if(!stock_info)
		stock_info = new /list(WARDROBE_STOCK_CALL_REMOVAL)
		stock_info[WARDROBE_STOCK_CONTENTS] = list()
		stock_info[WARDROBE_STOCK_CALL_INSERT] = master_info[WARDROBE_CACHE_CALL_INSERT]
		stock_info[WARDROBE_STOCK_CALL_REMOVAL] = master_info[WARDROBE_CACHE_CALL_REMOVAL]
		preloaded_stock[object_type] = stock_info

	var/datum/callback/do_on_insert = stock_info[WARDROBE_STOCK_CALL_INSERT]
	if(do_on_insert)
		do_on_insert.object = object
		do_on_insert.Invoke()
		do_on_insert.object = null

	object.moveToNullspace()
	stock_info[WARDROBE_STOCK_CONTENTS] += object

/datum/controller/subsystem/wardrobe/proc/provide_type(datum/requested_type, atom/movable/location)
	var/atom/movable/requested_object
	var/list/stock_info = preloaded_stock[requested_type]
	if(!stock_info)
		stock_miss++
		requested_object = new requested_type(location)
		return requested_object

	var/list/contents = stock_info[WARDROBE_STOCK_CONTENTS]
	var/contents_length = length(contents)
	requested_object = contents[contents_length]
	contents.len--

	if(QDELETED(requested_object))
		stack_trace("We somehow ended up with a qdeleted or null object in SSwardrobe's stock. Something's weird, likely to do with reinsertion. Typepath of [requested_type]")
		stock_miss++
		requested_object = new requested_type(location)
		return requested_object

	if(location)
		requested_object.forceMove(location)

	var/datum/callback/do_on_removal = stock_info[WARDROBE_STOCK_CALL_REMOVAL]
	if(do_on_removal)
		do_on_removal.object = requested_object
		do_on_removal.Invoke()
		do_on_removal.object = null

	stock_hit++
	add_queue_item(requested_type, 1) // Requeue the item, under the assumption we'll never see it again
	if(!(contents_length - 1))
		preloaded_stock -= requested_type

	return requested_object

/// Unloads an amount of some type we have in stock
/// Private function, for internal use only
/datum/controller/subsystem/wardrobe/proc/unload_stock(datum/unload_type, amount, force = FALSE)
	var/list/stock_info = preloaded_stock[unload_type]
	if(!stock_info)
		return

	var/list/unload_from = stock_info[WARDROBE_STOCK_CONTENTS]
	for(var/i in 1 to min(amount, length(unload_from)))
		var/datum/nuke = unload_from[unload_from.len]
		unload_from.len--
		qdel(nuke)
		if(!force && MC_TICK_CHECK && length(unload_from))
			return

	if(!length(stock_info[WARDROBE_STOCK_CONTENTS]))
		preloaded_stock -= unload_type

/// Sets up insertion and removal callbacks by typepath
/// We will always use the deepest path. So /obj/item/blade/knife superceeds the entries of /obj/item and /obj/item/blade
/// Mind this
/datum/controller/subsystem/wardrobe/proc/setup_callbacks()
	var/list/play_with = new /list(WARDROBE_CALLBACK_REMOVE) // Turns out there's a global list of pdas. Let's work around that yeah?

	play_with = new /list(WARDROBE_CALLBACK_REMOVE) // Don't want organs rotting on the job
	play_with[WARDROBE_CALLBACK_INSERT] = CALLBACK(null, TYPE_PROC_REF(/obj/item/organ,enter_wardrobe))
	play_with[WARDROBE_CALLBACK_REMOVE] = CALLBACK(null, TYPE_PROC_REF(/obj/item/organ,exit_wardrobe))
	initial_callbacks[/obj/item/organ] = play_with

/datum/controller/subsystem/wardrobe/proc/load_outfits()
	for(var/datum/outfit/to_stock as anything in subtypesof(/datum/outfit))
		if(!initial(to_stock.preload)) // Clearly not interested
			continue
		var/datum/outfit/hang_up = new to_stock()
		for(var/datum/outfit_item as anything in hang_up.get_types_to_preload())
			canonize_type(outfit_item)
		CHECK_TICK

/datum/controller/subsystem/wardrobe/proc/load_species()
	for(var/datum/species/to_record as anything in subtypesof(/datum/species))
		if(!initial(to_record.preload))
			continue
		var/datum/species/fossil_record = new to_record()
		for(var/obj/item/species_request as anything in fossil_record.get_types_to_preload())
			for(var/i in 1 to 5) // Store 5 of each species, since that seems on par with 1 of each outfit
				canonize_type(species_request)
		CHECK_TICK

	for(var/datum/species/to_record as anything in subtypesof(/obj/item/bodypart))
		for(var/i in 1 to 10) // Store 10 of each bodypart since everyone have one
			canonize_type(to_record)
			CHECK_TICK

/datum/controller/subsystem/wardrobe/proc/load_storage_contents()
	for(var/obj/item/storage/crate as anything in subtypesof(/obj/item/storage))
		if(!initial(crate.preload))
			continue
		var/obj/item/storage/another_crate = new crate()
		//Unlike other uses, I really don't want people being lazy with this one.
		var/list/somehow_more_boxes = another_crate.get_types_to_preload()
		if(!length(somehow_more_boxes))
			stack_trace("You appear to have set preload to true on [crate] without defining get_types_to_preload. Please be more strict about your scope, this stuff is spooky")
		for(var/datum/a_really_small_box as anything in somehow_more_boxes)
			canonize_type(a_really_small_box)
		qdel(another_crate)


//Since you all like to use preEquip, i had to do this shitcode
//REMOVE IF PEOPLE WILL STOP USING preEquip instead of writing in datum
/datum/controller/subsystem/wardrobe/proc/load_rogueitems()
	for(var/obj/item/clothing/suit/roguetown/to_record as anything in subtypesof(/obj/item/clothing/suit/roguetown))
		canonize_type(to_record)
		CHECK_TICK
	for(var/obj/item/clothing/under/roguetown/to_record as anything in subtypesof(/obj/item/clothing/under/roguetown))
		canonize_type(to_record)
		CHECK_TICK
	for(var/obj/item/clothing/shoes/roguetown/to_record as anything in subtypesof(/obj/item/clothing/shoes/roguetown))
		canonize_type(to_record)
		CHECK_TICK
	for(var/obj/item/clothing/gloves/roguetown/to_record as anything in subtypesof(/obj/item/clothing/gloves/roguetown))
		canonize_type(to_record)
		CHECK_TICK
	for(var/obj/item/clothing/wrists/roguetown/to_record as anything in subtypesof(/obj/item/clothing/wrists/roguetown))
		canonize_type(to_record)
		CHECK_TICK
	for(var/obj/item/rogueweapon/to_record as anything in subtypesof(/obj/item/rogueweapon))
		canonize_type(to_record)
		CHECK_TICK
	for(var/obj/item/storage/belt/rogue/to_record as anything in subtypesof(/obj/item/storage/belt/rogue))
		canonize_type(to_record)
		CHECK_TICK
	for(var/obj/item/clothing/neck/roguetown/to_record as anything in subtypesof(/obj/item/clothing/neck/roguetown))
		canonize_type(to_record)
		CHECK_TICK


/datum/controller/subsystem/wardrobe
	var/list/character_setup_preview_geometry_cache = list()
	var/list/character_setup_preview_scope_cache = list()

/datum/controller/subsystem/wardrobe/proc/clear_character_setup_preview_cache()
	character_setup_preview_geometry_cache = list()
	character_setup_preview_scope_cache = list()

/datum/controller/subsystem/wardrobe/proc/get_character_setup_preview_scope_key(scope_key, cache_key)
	var/effective_scope_key = scope_key ? "[scope_key]" : "global"
	return "scope|[effective_scope_key]|[cache_key]"

/datum/controller/subsystem/wardrobe/proc/clear_character_setup_preview_scope(scope_key)
	if(!scope_key)
		return
	var/prefix = "scope|[scope_key]|"
	var/list/keys_to_clear = list()
	for(var/key in character_setup_preview_scope_cache)
		if(findtext("[key]", prefix) == 1)
			keys_to_clear += key
	for(var/key in keys_to_clear)
		character_setup_preview_scope_cache -= key

/datum/controller/subsystem/wardrobe/proc/get_character_setup_scope_cached_icon(scope_key, cache_key)
	var/scoped_key = get_character_setup_preview_scope_key(scope_key, cache_key)
	var/icon/cached_icon = character_setup_preview_scope_cache[scoped_key]
	if(cached_icon)
		return icon(cached_icon)
	return null

/datum/controller/subsystem/wardrobe/proc/set_character_setup_scope_cached_icon(scope_key, cache_key, icon/source_icon)
	if(!source_icon)
		return
	var/scoped_key = get_character_setup_preview_scope_key(scope_key, cache_key)
	character_setup_preview_scope_cache[scoped_key] = icon(source_icon)

/datum/controller/subsystem/wardrobe/proc/get_character_setup_scope_cached_value(scope_key, cache_key)
	var/scoped_key = get_character_setup_preview_scope_key(scope_key, cache_key)
	return character_setup_preview_scope_cache[scoped_key]

/datum/controller/subsystem/wardrobe/proc/set_character_setup_scope_cached_value(scope_key, cache_key, value)
	var/scoped_key = get_character_setup_preview_scope_key(scope_key, cache_key)
	character_setup_preview_scope_cache[scoped_key] = value


/datum/controller/subsystem/wardrobe/proc/character_setup_preview_entry_allowed_in_head_only(customizer_key, datum/customizer_entry/entry)
	var/combined_text = lowertext("[customizer_key]|[entry ? entry.type : null]|[entry ? entry.accessory_type : null]")
	if(findtext(combined_text, "/wings") || findtext(combined_text, "/tail"))
		return FALSE
	if(findtext(combined_text, "/hair/head"))
		return TRUE
	if(findtext(combined_text, "/horn"))
		return TRUE
	if(findtext(combined_text, "/ear"))
		return TRUE
	if(findtext(combined_text, "/eye"))
		return TRUE
	return FALSE

/datum/controller/subsystem/wardrobe/proc/suppress_non_head_customizer_entries_for_preview(datum/preferences/prefs)
	var/list/state = list(
		"entries" = list(),
		"disabled" = list(),
	)
	if(!prefs || !islist(prefs.customizer_entries))
		return state

	var/list/suppressed_entries = state["entries"]
	var/list/suppressed_disabled = state["disabled"]
	for(var/customizer_key in prefs.customizer_entries)
		var/datum/customizer_entry/entry = prefs.customizer_entries[customizer_key]
		if(!istype(entry))
			continue
		if(character_setup_preview_entry_allowed_in_head_only(customizer_key, entry))
			continue
		suppressed_entries += entry
		suppressed_disabled += entry.disabled
		entry.disabled = TRUE
	return state

/datum/controller/subsystem/wardrobe/proc/restore_suppressed_customizer_entries(list/state)
	if(!islist(state))
		return
	var/list/suppressed_entries = state["entries"]
	var/list/suppressed_disabled = state["disabled"]
	if(!islist(suppressed_entries) || !islist(suppressed_disabled))
		return
	var/count = min(length(suppressed_entries), length(suppressed_disabled))
	for(var/i in 1 to count)
		var/datum/customizer_entry/entry = suppressed_entries[i]
		if(!istype(entry))
			continue
		entry.disabled = suppressed_disabled[i]

/datum/controller/subsystem/wardrobe/proc/character_setup_head_only_preview_should_keep_organ(obj/item/organ/current_organ)
	if(!current_organ)
		return FALSE
	var/type_text = lowertext("[current_organ.type]")
	if(findtext(type_text, "/eyes"))
		return TRUE
	if(findtext(type_text, "/ears"))
		return TRUE
	if(findtext(type_text, "/tongue"))
		return TRUE
	if(findtext(type_text, "/brain"))
		return TRUE
	if(findtext(type_text, "/horn"))
		return TRUE
	return FALSE

/datum/controller/subsystem/wardrobe/proc/strip_non_head_organs_for_preview(mob/living/carbon/human/dummy/mannequin)
	if(!mannequin)
		return
	var/list/organs_to_strip = list()
	for(var/obj/item/organ/current_organ as anything in mannequin.internal_organs)
		if(current_organ && !character_setup_head_only_preview_should_keep_organ(current_organ))
			organs_to_strip += current_organ
	for(var/slot in mannequin.internal_organs_slot)
		var/obj/item/organ/current_organ = mannequin.internal_organs_slot[slot]
		if(current_organ && !character_setup_head_only_preview_should_keep_organ(current_organ) && !(current_organ in organs_to_strip))
			organs_to_strip += current_organ
	for(var/obj/item/organ/current_organ as anything in organs_to_strip)
		current_organ.Remove(mannequin, special = TRUE)
		recycle_object(current_organ)

/datum/controller/subsystem/wardrobe/proc/build_character_setup_accessory_head_band_icon(datum/preferences/prefs, revision_tag, customizer_type, accessory_type, preview_dir = SOUTH, scope_key = null)
	var/color_key = null
	var/datum/customizer_entry/entry = prefs ? prefs.get_customizer_entry_for_customizer_type(customizer_type) : null
	if(istype(entry, /datum/customizer_entry/hair))
		var/datum/customizer_entry/hair/hair_entry = entry
		color_key = hair_entry.hair_color
	else if(entry)
		color_key = entry.accessory_colors
	var/cache_key = "overlay_head_band|[revision_tag]|[customizer_type]|[accessory_type]|[preview_dir]|[color_key]"
	var/icon/cached_icon = get_character_setup_scope_cached_icon(scope_key, cache_key)
	if(cached_icon)
		return cached_icon

	var/icon/overlay_icon = build_character_setup_directional_accessory_icon(prefs, customizer_type, accessory_type, preview_dir)
	if(!overlay_icon)
		return null
	var/icon/overlay_band_icon = extract_character_setup_head_features_icon(overlay_icon, preview_dir, null, preview_dir)
	if(!overlay_band_icon)
		return null
	set_character_setup_scope_cached_icon(scope_key, cache_key, overlay_band_icon)
	return overlay_band_icon

/datum/controller/subsystem/wardrobe/proc/character_setup_preview_icon_seems_broken(icon/preview_icon, preview_focus)
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

/datum/controller/subsystem/wardrobe/proc/get_character_setup_active_customizer_type_by_name(datum/preferences/prefs, target_name)
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

/datum/controller/subsystem/wardrobe/proc/build_character_setup_raw_accessory_icon(datum/preferences/prefs, customizer_type)
	if(!prefs || !customizer_type)
		return null
	var/datum/customizer_entry/entry = prefs.get_customizer_entry_for_customizer_type(customizer_type)
	if(!entry || entry.disabled || !entry.accessory_type)
		return null
	return build_character_setup_directional_accessory_icon(prefs, customizer_type, entry.accessory_type, SOUTH)

/datum/controller/subsystem/wardrobe/proc/turn_character_setup_accessory_icon(icon/source_icon, preview_dir)
	if(!source_icon)
		return null
	var/icon/result_icon = icon(source_icon)
	switch(preview_dir)
		if(NORTH)
			result_icon.Turn(180)
		if(EAST)
			result_icon.Turn(-90)
		if(WEST)
			result_icon.Turn(90)
		else
			return result_icon
	return result_icon

/datum/controller/subsystem/wardrobe/proc/build_character_setup_directional_accessory_geometry_icon(accessory_type, preview_dir = SOUTH)
	if(!accessory_type)
		return null
	var/cache_key = "geom|acc_raw|[accessory_type]|[preview_dir]"
	var/icon/cached_icon = character_setup_preview_geometry_cache[cache_key]
	if(cached_icon)
		return icon(cached_icon)

	var/datum/sprite_accessory/accessory = SPRITE_ACCESSORY(accessory_type)
	if(!accessory)
		return null

	var/icon/result_icon = icon(accessory.icon, accessory.icon_state, preview_dir)
	if((!result_icon || result_icon.Width() <= 0 || result_icon.Height() <= 0) && preview_dir != SOUTH)
		var/icon/fallback_icon = icon(accessory.icon, accessory.icon_state)
		if(fallback_icon)
			fallback_icon = turn_character_setup_accessory_icon(fallback_icon, preview_dir)
			if(fallback_icon)
				result_icon = fallback_icon
	if(!result_icon)
		return null

	character_setup_preview_geometry_cache[cache_key] = icon(result_icon)
	return result_icon

/datum/controller/subsystem/wardrobe/proc/build_character_setup_directional_accessory_icon(datum/preferences/prefs, customizer_type, accessory_type, preview_dir = SOUTH)
	var/icon/result_icon = build_character_setup_directional_accessory_geometry_icon(accessory_type, preview_dir)
	if(!result_icon)
		return null

	var/datum/customizer_entry/entry = prefs ? prefs.get_customizer_entry_for_customizer_type(customizer_type) : null
	if(istype(entry, /datum/customizer_entry/hair))
		var/datum/customizer_entry/hair/hair_entry = entry
		if(hair_entry.hair_color)
			result_icon.Blend(hair_entry.hair_color, ICON_MULTIPLY)
	else if(entry && entry.accessory_colors)
		var/list/accessory_colors = color_string_to_list(entry.accessory_colors)
		if(accessory_colors && accessory_colors.len && accessory_colors[1])
			result_icon.Blend(accessory_colors[1], ICON_MULTIPLY)
	return result_icon

/datum/controller/subsystem/wardrobe/proc/build_character_setup_accessory_overlay_icon(datum/preferences/prefs, revision_tag, customizer_type, accessory_type, preview_focus, preview_dir = SOUTH, scope_key = null)
	var/cache_key = "overlay|[revision_tag]|[customizer_type]|[accessory_type]|[preview_focus]|[preview_dir]"
	var/icon/cached_icon = get_character_setup_scope_cached_icon(scope_key, cache_key)
	if(cached_icon)
		return cached_icon

	var/icon/result_icon = build_character_setup_directional_accessory_icon(prefs, customizer_type, accessory_type, preview_dir)
	if(!result_icon)
		return null
	if(preview_focus != "head")
		apply_character_setup_preview_focus(result_icon, preview_focus)
	set_character_setup_scope_cached_icon(scope_key, cache_key, result_icon)
	return result_icon

/datum/controller/subsystem/wardrobe/proc/prepare_character_setup_dummy(mob/living/carbon/human/dummy/mannequin)
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

/datum/controller/subsystem/wardrobe/proc/get_character_setup_preview_dummy()
	return generate_or_wait_for_human_dummy(DUMMY_HUMAN_SLOT_PREFERENCES)

/datum/controller/subsystem/wardrobe/proc/release_character_setup_preview_dummy(mob/living/carbon/human/dummy/mannequin)
	if(!mannequin)
		return
	unset_busy_human_dummy(DUMMY_HUMAN_SLOT_PREFERENCES)

/datum/controller/subsystem/wardrobe/proc/log_character_setup_head_preview_icon(stage, icon/source_icon, preview_dir = SOUTH, extra = null)
	if(!character_setup_preview_debug_logging)
		return
	var/extra_text = extra ? " [extra]" : ""
	if(!source_icon)
		preview_debug_log("\[charsetup-head\] [stage] dir=[preview_debug_dir_name(preview_dir)] icon=null[extra_text]")
		return
	preview_debug_log("\[charsetup-head\] [stage] dir=[preview_debug_dir_name(preview_dir)] size=[source_icon.Width()]x[source_icon.Height()][extra_text]")

/datum/controller/subsystem/wardrobe/proc/fix_character_setup_head_preview_source(icon/source_icon, preview_dir = SOUTH, debug_context = "charsetup-head wardrobe_head_preview")
	if(!source_icon)
		return null
	var/effective_debug_context = character_setup_preview_debug_logging ? debug_context : null
	var/icon/fixed_icon = build_fixed_character_setup_full_preview_icon(source_icon, preview_dir, 32, 40, 16, 3, effective_debug_context, preview_dir)
	if(fixed_icon)
		return fixed_icon
	return source_icon

/datum/controller/subsystem/wardrobe/proc/preview_icons_are_identical(icon/a, icon/b)
	if(!a || !b)
		return FALSE
	if(a.Width() != b.Width() || a.Height() != b.Height())
		return FALSE
	for(var/y = 1 to a.Height())
		for(var/x = 1 to a.Width())
			if("[a.GetPixel(x, y)]" != "[b.GetPixel(x, y)]")
				return FALSE
	return TRUE

/datum/controller/subsystem/wardrobe/proc/character_setup_accessory_preview_can_match_base(accessory_type)
	var/datum/sprite_accessory/accessory = accessory_type ? SPRITE_ACCESSORY(accessory_type) : null
	var/name_text = lowertext(accessory ? "[accessory.name]" : "[accessory_type]")
	if(findtext(name_text, "bald"))
		return TRUE
	if(findtext(name_text, "none"))
		return TRUE
	if(findtext(name_text, "shaved"))
		return TRUE
	return FALSE

/datum/controller/subsystem/wardrobe/proc/character_setup_fast_head_preview_is_valid(icon/base_head_icon, icon/result_icon, icon/overlay_icon, accessory_type, preview_dir)
	if(!result_icon)
		return FALSE
	var/allow_base_match = character_setup_accessory_preview_can_match_base(accessory_type)
	if(!overlay_icon && !allow_base_match)
		return FALSE
	if(result_icon.Width() < 14 || result_icon.Height() < 12)
		return FALSE
	if((preview_dir == EAST || preview_dir == WEST) && result_icon.Width() < 18)
		return FALSE
	if(!allow_base_match && base_head_icon)
		var/base_rsc = "[base_head_icon.RscFile()]"
		var/result_rsc = "[result_icon.RscFile()]"
		if(length(base_rsc) && length(result_rsc) && base_rsc == result_rsc)
			return FALSE
	return TRUE

/datum/controller/subsystem/wardrobe/proc/build_character_setup_base_source_icon(datum/preferences/prefs, revision_tag, preview_dir = SOUTH, customizer_type = null, scope_key = null, head_only = FALSE)
	var/cache_key = "base_source|[revision_tag]|[customizer_type]|[preview_dir]|[head_only]"
	var/icon/cached_icon = get_character_setup_scope_cached_icon(scope_key, cache_key)
	if(cached_icon)
		return cached_icon

	var/mob/living/carbon/human/dummy/mannequin = get_character_setup_preview_dummy()
	if(!mannequin)
		return null

	prepare_character_setup_dummy(mannequin)

	var/datum/customizer_entry/entry = null
	var/old_accessory = null
	var/old_disabled = FALSE
	var/list/head_only_state = null
	if(customizer_type)
		entry = prefs.get_customizer_entry_for_customizer_type(customizer_type)
		if(entry)
			old_accessory = entry.accessory_type
			old_disabled = entry.disabled
			entry.accessory_type = null
			entry.disabled = TRUE
	if(head_only)
		head_only_state = suppress_non_head_customizer_entries_for_preview(prefs)

	prefs.copy_to(mannequin, 1, TRUE, TRUE)
	if(head_only)
		strip_non_head_organs_for_preview(mannequin)
	mannequin.dir = preview_dir
	mannequin.rebuild_obscured_flags()
	mannequin.update_body()
	mannequin.update_hair()
	mannequin.update_body_parts(TRUE)
	if(hascall(mannequin, "regenerate_icons"))
		call(mannequin, "regenerate_icons")()
	if(hascall(mannequin, "update_icons"))
		call(mannequin, "update_icons")()

	var/icon/base_icon = getFlatIcon(mannequin)
	if(!base_icon)
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
			base_icon = retry_icon

	release_character_setup_preview_dummy(mannequin)
	if(entry)
		entry.accessory_type = old_accessory
		entry.disabled = old_disabled
	if(head_only_state)
		restore_suppressed_customizer_entries(head_only_state)
	if(!base_icon)
		return null
	if(character_setup_preview_debug_logging && head_only)
		preview_debug_log("charsetup-head: base_source_head_only dir=[preview_debug_dir_name(preview_dir)] size=[base_icon.Width()]x[base_icon.Height()] customizer=[customizer_type]")

	set_character_setup_scope_cached_icon(scope_key, cache_key, base_icon)
	return base_icon

/datum/controller/subsystem/wardrobe/proc/build_character_setup_fast_head_option_icon(datum/preferences/prefs, revision_tag, customizer_type, accessory_type, preview_dir = SOUTH, scope_key = null)
	var/cache_key = "opt_head|[revision_tag]|[customizer_type]|[accessory_type]|[preview_dir]"
	var/icon/cached_icon = get_character_setup_scope_cached_icon(scope_key, cache_key)
	if(cached_icon)
		return cached_icon

	var/icon/base_head_icon = build_character_setup_base_icon(prefs, revision_tag, "head", preview_dir, customizer_type, scope_key, TRUE)
	if(!base_head_icon)
		return null

	var/icon/overlay_icon = build_character_setup_accessory_head_band_icon(prefs, revision_tag, customizer_type, accessory_type, preview_dir, scope_key)
	if(!overlay_icon)
		return null

	var/icon/result_icon = icon(base_head_icon)
	result_icon.Blend(overlay_icon, ICON_OVERLAY)

	if(!character_setup_fast_head_preview_is_valid(base_head_icon, result_icon, overlay_icon, accessory_type, preview_dir))
		log_character_setup_head_preview_icon("fast|[revision_tag]|[customizer_type]|[accessory_type] sanity_failed", result_icon, preview_dir, "customizer=[customizer_type] accessory=[accessory_type]")
		return null

	set_character_setup_scope_cached_icon(scope_key, cache_key, result_icon)
	return result_icon

/datum/controller/subsystem/wardrobe/proc/render_character_setup_preview(mob/user, datum/preferences/prefs, revision_tag, preview_focus = "full", preview_dir = SOUTH, scope_key = null)
	if(!user || !prefs)
		return null

	var/cache_key = "main|[revision_tag]|[preview_focus]|[preview_dir]"
	var/cached_filename = get_character_setup_scope_cached_value(scope_key, cache_key)
	if(cached_filename)
		return cached_filename

	var/filename = "wardrobe_charsetup_[copytext(md5("[cache_key]|[scope_key]"), 1, 11)].png"
	if(preview_focus == "head")
		var/icon/head_preview_icon = build_character_setup_base_icon(prefs, revision_tag, "head", preview_dir, null, scope_key, TRUE)
		if(!head_preview_icon)
			return null
		user << browse_rsc(head_preview_icon, filename)
		set_character_setup_scope_cached_value(scope_key, cache_key, filename)
		return filename

	var/mob/living/carbon/human/dummy/mannequin = get_character_setup_preview_dummy()
	if(!mannequin)
		return null

	prepare_character_setup_dummy(mannequin)
	prefs.copy_to(mannequin, 1, TRUE, TRUE)
	mannequin.dir = preview_dir
	mannequin.rebuild_obscured_flags()
	mannequin.update_body()
	mannequin.update_hair()
	mannequin.update_body_parts(TRUE)
	if(hascall(mannequin, "regenerate_icons"))
		call(mannequin, "regenerate_icons")()
	if(hascall(mannequin, "update_icons"))
		call(mannequin, "update_icons")()

	var/icon/preview_icon = getFlatIcon(mannequin)
	if(!preview_icon || character_setup_preview_icon_seems_broken(preview_icon, preview_focus))
		mannequin.rebuild_obscured_flags()
		mannequin.update_body()
		mannequin.update_hair()
		mannequin.update_body_parts(TRUE)
		if(hascall(mannequin, "regenerate_icons"))
			call(mannequin, "regenerate_icons")()
		if(hascall(mannequin, "update_icons"))
			call(mannequin, "update_icons")()
		var/icon/retry_icon = getFlatIcon(mannequin)
		if(retry_icon && !character_setup_preview_icon_seems_broken(retry_icon, preview_focus))
			preview_icon = retry_icon
	if(!preview_icon || character_setup_preview_icon_seems_broken(preview_icon, preview_focus))
		var/icon/base_icon = build_character_setup_base_icon(prefs, revision_tag, preview_focus, preview_dir, null, scope_key)
		if(base_icon && !character_setup_preview_icon_seems_broken(base_icon, preview_focus))
			preview_icon = base_icon

	release_character_setup_preview_dummy(mannequin)
	if(!preview_icon)
		return null

	if(preview_focus == "full")
		var/icon/fixed_full_preview_icon = build_fixed_character_setup_full_preview_icon(preview_icon, preview_dir, 32, 40, 16, 3, character_setup_preview_debug_logging ? "wardrobe_full_preview" : null, preview_dir)
		if(fixed_full_preview_icon)
			preview_icon = fixed_full_preview_icon

	apply_character_setup_preview_focus(preview_icon, preview_focus)
	user << browse_rsc(preview_icon, filename)
	set_character_setup_scope_cached_value(scope_key, cache_key, filename)
	return filename

/datum/controller/subsystem/wardrobe/proc/render_character_setup_accessory_preview(mob/user, datum/preferences/prefs, customizer_type, accessory_type, revision_tag, preview_focus = "head", preview_dir = SOUTH, scope_key = null)
	if(!user || !prefs || !customizer_type || !accessory_type)
		return null

	var/cache_key = "opt|[revision_tag]|[customizer_type]|[accessory_type]|[preview_focus]|[preview_dir]"
	var/cached_filename = get_character_setup_scope_cached_value(scope_key, cache_key)
	if(cached_filename)
		return cached_filename

	var/icon/result_icon = null
	var/datum/customizer_entry/entry = prefs.get_customizer_entry_for_customizer_type(customizer_type)

	switch(preview_focus)
		if("underwear", "groin", "legs")
			result_icon = build_character_setup_directional_accessory_icon(prefs, customizer_type, accessory_type, preview_dir)
			if(result_icon)
				apply_character_setup_preview_focus(result_icon, preview_focus)
		if("head")
			if(istype(entry, /datum/customizer_entry/hair))
				result_icon = build_character_setup_fast_head_option_icon(prefs, revision_tag, customizer_type, accessory_type, preview_dir, scope_key)
			if(!result_icon)
				result_icon = build_character_setup_customizer_option_icon(prefs, revision_tag, customizer_type, accessory_type, "head", preview_dir, scope_key)
		if("head_overlay")
			result_icon = build_character_setup_accessory_head_band_icon(prefs, revision_tag, customizer_type, accessory_type, preview_dir, scope_key)
		else
			result_icon = build_character_setup_directional_accessory_icon(prefs, customizer_type, accessory_type, preview_dir)
			if(result_icon)
				apply_character_setup_preview_focus(result_icon, preview_focus)

	if(!result_icon)
		return null

	var/filename = "wardrobe_charsetup_[copytext(md5("[cache_key]|[scope_key]"), 1, 11)].png"
	user << browse_rsc(result_icon, filename)
	set_character_setup_scope_cached_value(scope_key, cache_key, filename)
	return filename

/datum/controller/subsystem/wardrobe/proc/build_character_setup_customizer_option_icon(datum/preferences/prefs, revision_tag, customizer_type, accessory_type, preview_focus, preview_dir = SOUTH, scope_key = null)
	var/cache_key = "focused|[revision_tag]|[customizer_type]|[accessory_type]|[preview_focus]|[preview_dir]"
	var/icon/cached_icon = get_character_setup_scope_cached_icon(scope_key, cache_key)
	if(cached_icon)
		return cached_icon

	if(preview_focus == "underwear" || preview_focus == "groin" || preview_focus == "legs")
		var/icon/direct_icon = build_character_setup_directional_accessory_icon(prefs, customizer_type, accessory_type, preview_dir)
		if(!direct_icon)
			return null
		apply_character_setup_preview_focus(direct_icon, preview_focus)
		set_character_setup_scope_cached_icon(scope_key, cache_key, direct_icon)
		return direct_icon

	var/mob/living/carbon/human/dummy/mannequin = get_character_setup_preview_dummy()
	if(!mannequin)
		return null

	prepare_character_setup_dummy(mannequin)

	var/datum/customizer_entry/entry = null
	var/old_accessory = null
	var/old_disabled = FALSE
	var/list/head_only_state = null
	if(customizer_type)
		entry = prefs.get_customizer_entry_for_customizer_type(customizer_type)
		if(entry)
			old_accessory = entry.accessory_type
			old_disabled = entry.disabled
			entry.accessory_type = accessory_type
			entry.disabled = FALSE
	if(preview_focus == "head")
		head_only_state = suppress_non_head_customizer_entries_for_preview(prefs)

	prefs.copy_to(mannequin, 1, TRUE, TRUE)
	mannequin.dir = preview_dir
	mannequin.rebuild_obscured_flags()
	mannequin.update_body()
	mannequin.update_hair()
	mannequin.update_body_parts(TRUE)
	if(hascall(mannequin, "regenerate_icons"))
		call(mannequin, "regenerate_icons")()
	if(hascall(mannequin, "update_icons"))
		call(mannequin, "update_icons")()

	var/icon/focused_icon = getFlatIcon(mannequin)
	if(!focused_icon)
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
			focused_icon = retry_icon
	release_character_setup_preview_dummy(mannequin)
	if(entry)
		entry.accessory_type = old_accessory
		entry.disabled = old_disabled
	if(head_only_state)
		restore_suppressed_customizer_entries(head_only_state)
	if(!focused_icon)
		return null

	if(preview_focus == "head")
		var/icon/head_band_icon = extract_character_setup_head_features_icon(focused_icon, preview_dir, null, preview_dir)
		if(head_band_icon)
			focused_icon = head_band_icon
	else
		apply_character_setup_preview_focus(focused_icon, preview_focus)
	set_character_setup_scope_cached_icon(scope_key, cache_key, focused_icon)
	return focused_icon

/datum/controller/subsystem/wardrobe/proc/build_character_setup_base_icon(datum/preferences/prefs, revision_tag, preview_focus, preview_dir = SOUTH, customizer_type = null, scope_key = null, head_only = FALSE)
	var/effective_head_only = (preview_focus == "head") || head_only
	var/cache_key = "base|[revision_tag]|[preview_focus]|[preview_dir]|[customizer_type]|[effective_head_only]"
	var/icon/cached_icon = get_character_setup_scope_cached_icon(scope_key, cache_key)
	if(cached_icon)
		return cached_icon

	var/icon/base_icon = build_character_setup_base_source_icon(prefs, revision_tag, preview_dir, customizer_type, scope_key, effective_head_only)
	if(!base_icon)
		return null
	base_icon = icon(base_icon)

	if(preview_focus == "full")
		var/icon/fixed_full_preview_icon = build_fixed_character_setup_full_preview_icon(base_icon, preview_dir, 32, 40, 16, 3, character_setup_preview_debug_logging ? "wardrobe_full_preview" : null, preview_dir)
		if(fixed_full_preview_icon)
			base_icon = fixed_full_preview_icon
	else if(preview_focus == "head")
		var/icon/head_band_icon = extract_character_setup_head_features_icon(base_icon, preview_dir, null, preview_dir)
		if(head_band_icon)
			base_icon = head_band_icon

	if(preview_focus != "head")
		apply_character_setup_preview_focus(base_icon, preview_focus)
	set_character_setup_scope_cached_icon(scope_key, cache_key, base_icon)
	return base_icon

/datum/controller/subsystem/wardrobe/proc/apply_character_setup_preview_focus(icon/preview_icon, preview_focus)
	if(!preview_icon)
		return
	switch(preview_focus)
		if("head")
			preview_icon.Crop(9, 18, 24, 32)
		if("upper")
			preview_icon.Crop(6, 13, 26, 32)
		if("torso")
			preview_icon.Crop(7, 8, 26, 24)
		if("underwear")
			preview_icon.Crop(10, 8, 23, 16)
		if("groin")
			preview_icon.Crop(10, 6, 23, 18)
		if("legs")
			preview_icon.Crop(10, 1, 22, 12)
		else
			return
