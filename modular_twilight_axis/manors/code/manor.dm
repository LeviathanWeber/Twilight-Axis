/datum/mind
	var/datum/manor/owned_manor = null

/datum/mind/proc/get_owned_manor()
	return owned_manor

/datum/mind/proc/set_owned_manor(datum/manor/manor)
	owned_manor = manor
	return owned_manor

/datum/manor
	var/manor_name = "Неизвестное имение"
	var/manor_size = 15
	var/manor_type = "manor"
	var/min_workers = 5
	var/total_workers = 5
	var/patron = /datum/patron/divine/astrata
	var/last_cycle_productivity = 0
	var/list/workstations = list()
	var/list/workstation_types = list(/datum/workstation/field)

/datum/manor/proc/get_owner_display_name(mob/living/carbon/human/owner)
	if(owner?.real_name && length(owner.real_name))
		return owner.real_name
	if(owner?.name && length(owner.name))
		return owner.name
	return "Неизвестное владение"

/datum/manor/proc/get_owner_patron(mob/living/carbon/human/owner)
	if(!owner || !owner.mind)
		return null
	if(islist(owner.mind.vars) && ("patron" in owner.mind.vars))
		return owner.mind.vars["patron"]
	return null

/datum/manor/proc/on_creation(mob/living/carbon/human/owner)
	var/workers_limit = 0

	manor_name = get_owner_display_name(owner)

	var/owner_patron = get_owner_patron(owner)
	if(owner_patron)
		patron = owner_patron

	workstations = list()
	for(var/workstation_type in workstation_types)
		var/datum/workstation/new_workstation = new workstation_type()
		workstations += new_workstation
		workers_limit += new_workstation.workstation_size

	switch(patron)
		if(/datum/patron/divine/xylix)
			if(/datum/workstation/trade in workstation_types)
				for(var/datum/workstation/trade/trade_station in workstations)
					trade_station.workstation_size += 10
					workers_limit += 10
			else
				var/datum/workstation/trade/new_trade = new /datum/workstation/trade()
				workstations += new_trade
				workers_limit += new_trade.workstation_size

	if(workers_limit < min_workers)
		workers_limit = min_workers
	total_workers = rand(min_workers, workers_limit)

/datum/manor/proc/ensure_initialized(mob/living/carbon/human/owner)
	if(!length(workstations))
		on_creation(owner)
	if(total_workers < min_workers)
		total_workers = min_workers
	return src

/datum/manor/proc/get_assigned_workers()
	. = 0
	for(var/datum/workstation/workstation in workstations)
		. += workstation.workers_employed

/datum/manor/proc/get_free_workers()
	return max(total_workers - get_assigned_workers(), 0)

/datum/manor/proc/get_last_cycle_productivity()
	. = max(last_cycle_productivity, 0)
	for(var/datum/workstation/workstation in workstations)
		. += max(workstation.last_cycle_productivity, 0)
		. += max(workstation.production_increase, 0)

/datum/manor/standart
	workstation_types = list(
		/datum/workstation/field/medium,
		/datum/workstation/fruit/medium,
		/datum/workstation/hunt/medium,
		/datum/workstation/farm/medium,
	)

/datum/manor/village
	manor_type = "village"
	workstation_types = list(
		/datum/workstation/field/big,
		/datum/workstation/farm/medium,
		/datum/workstation/trade/medium,
	)
