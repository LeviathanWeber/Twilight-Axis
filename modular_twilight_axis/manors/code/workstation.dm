/datum/workstation
	var/workstation_name = "Угодье"
	var/list/produce = list()
	var/workstation_size = 5
	var/workers_employed = 0
	var/generate_profit = FALSE
	var/production_increase = 0
	var/last_cycle_productivity = 0
	var/workstation_theme = "field"

/datum/workstation/proc/get_theme_key()
	switch(workstation_theme)
		if("fruit")
			return "orchard"
	return workstation_theme

/datum/workstation/field
	workstation_name = "Поля"
	workstation_theme = "field"
	produce = list(
		/datum/roguestock/stockpile/grain,
		/datum/roguestock/stockpile/oat,
		/datum/roguestock/stockpile/rice,
		/datum/roguestock/stockpile/cabbage,
		/datum/roguestock/stockpile/potato,
		/datum/roguestock/stockpile/onion,
		/datum/roguestock/stockpile/garlick,
		/datum/roguestock/stockpile/turnip,
		/datum/roguestock/stockpile/carrot,
		/datum/roguestock/stockpile/cucumber,
		/datum/roguestock/stockpile/eggplant,
	)

/datum/workstation/field/medium
	workstation_size = 15

/datum/workstation/field/big
	workstation_size = 30

/datum/workstation/fruit
	workstation_name = "Сады"
	workstation_theme = "fruit"
	produce = list(
		/datum/roguestock/stockpile/apple,
		/datum/roguestock/stockpile/jacksberry,
		/datum/roguestock/stockpile/pear,
		/datum/roguestock/stockpile/tomato,
		/datum/roguestock/stockpile/pumpkin,
		/datum/roguestock/stockpile/plum,
		/datum/roguestock/stockpile/lime,
		/datum/roguestock/stockpile/lemon,
		/datum/roguestock/stockpile/raspberry,
		/datum/roguestock/stockpile/strawberry,
	)

/datum/workstation/fruit/medium
	workstation_size = 15

/datum/workstation/fruit/big
	workstation_size = 30

/datum/workstation/hunt
	workstation_name = "Охотничьи угодья"
	workstation_theme = "hunt"
	produce = list(
		/datum/roguestock/stockpile/hide,
		/datum/roguestock/stockpile/cured,
		/datum/roguestock/stockpile/fur,
		/datum/roguestock/stockpile/rabbit,
		/datum/roguestock/stockpile/meat,
		/datum/roguestock/stockpile/poultry,
		/datum/roguestock/stockpile/fat,
		/datum/roguestock/stockpile/tallow,
	)

/datum/workstation/hunt/medium
	workstation_size = 15

/datum/workstation/hunt/big
	workstation_size = 30

/datum/workstation/farm
	workstation_name = "Фермы"
	workstation_theme = "farm"
	produce = list(
		/datum/roguestock/stockpile/hide,
		/datum/roguestock/stockpile/meat,
		/datum/roguestock/stockpile/pork,
		/datum/roguestock/stockpile/fat,
		/datum/roguestock/stockpile/tallow,
		/datum/roguestock/stockpile/egg,
		/datum/roguestock/stockpile/butter,
		/datum/roguestock/stockpile/cheese,
	)

/datum/workstation/farm/medium
	workstation_size = 15

/datum/workstation/farm/big
	workstation_size = 30

/datum/workstation/trade
	workstation_name = "Торговые ряды"
	workstation_theme = "trade"
	produce = list(
		/datum/roguestock/stockpile/tangerine,
		/datum/roguestock/stockpile/salt,
		/datum/roguestock/stockpile/sugar,
		/datum/roguestock/stockpile/tea,
		/datum/roguestock/stockpile/coffee,
		/datum/roguestock/stockpile/rocknut,
	)
	generate_profit = TRUE

/datum/workstation/trade/medium
	workstation_size = 15

/datum/workstation/trade/big
	workstation_size = 30
