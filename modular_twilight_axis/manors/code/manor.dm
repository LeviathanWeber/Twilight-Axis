/datum/manor
	var/manor_name = "Неизвестное имение"
	var/manor_size = 15
	var/manor_type = "manor"
	var/min_workers = 5
	var/total_workers = 5
	var/patron = /datum/patron/divine/astrata
	var/list/workstations = list()
	var/list/workstation_types = list(/datum/workstation/field)

/datum/manor/proc/on_creation(mob/living/carbon/human/owner)
	var/datum/preferences/pref = owner.client?.prefs
	var/workers_limit = 0
	if(pref)
		manor_name = pref.manor_name
	if(owner.mind?.patron)
		patron = owner.mind.patron
	for(var/W in workstation_types)
		var/datum/workstation/NW = new W()
		workstations += NW
		workers_limit += NW.workstation_size
	switch(patron)
		if(/datum/patron/divine/xylix)
			if(/datum/workstation/trade in workstation_types)
				for(var/datum/workstation/trade/T in workstations)
					T.workstation_size += 10
					workers_limit += 10
			else
				workstations += new /datum/workstation/trade()
				workers_limit += 5
	total_workers = rand(min_workers, workers_limit)

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
