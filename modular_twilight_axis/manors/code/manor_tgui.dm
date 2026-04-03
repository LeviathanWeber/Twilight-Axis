/datum/manor_panel
	var/mob/living/carbon/human/holder
	var/atom/movable/screen/map_view/manor_panel_screen/manor_panel_screen
	var/datum/preferences/pref = null
	var/is_playing = FALSE
	var/mob/viewing

/datum/manor_panel/New(mob/holder_mob)
	if(holder_mob)
		holder = holder_mob

/datum/manor_panel/Destroy(force)
	holder = null
	viewing = null
	qdel(manor_panel_screen)
	return ..()

/datum/manor_panel/ui_state(mob/user)
	return GLOB.always_state

/atom/movable/screen/map_view/manor_panel_screen
	name = "Manor Overview"

/datum/manor_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ManorPanel")
		ui.open()

/datum/manor_panel/ui_data(mob/user)
	var/datum/manor/manor
	var/manor_name
	var/manor_type
	var/manor_patron
	var/manor_icon = 'modular_twilight_axis/manors/icons/default_icon.png'
	var/total_workers
	var/list/workstations = list()

	if(holder.mind?.owned_manor)
		manor = owned_manor
		manor_name = manor.manor_name
		manor_type = manor.manor_type
		manor_patron = manor.patron
		total_workers = manor.total_workers
		workstations = manor.workstations
	if(manor_type)
		manor_icon = 'modular_twilight_axis/manors/icons/[manor_type]_icon.png'

	var/list/data = list(
		// Identity
		"manor_name" = manor_name,
		"manor_type" = manor_type,
		"manor_patron" = manor_patron,
		"manor_icon" = manor_icon,
		"total_workers" = total_workers
		"workstations" = workstations
	)
	return data
