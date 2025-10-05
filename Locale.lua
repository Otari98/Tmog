Tmog = {}

local axes, axes2H, bows, guns, maces, maces2H, polearms, swords, swords2H, staves, fists, miscellaneous, daggers, thrown, crossbows, wands, fishingPole = GetAuctionItemSubClasses(1)
local miscellaneous, cloth, leather, mail, plate, shields, librams, idols, totems = GetAuctionItemSubClasses(2)
local weapon, armor, container, consumable, tradeGoods, projectile, quiver, recipe, reagent, miscellaneous =  GetAuctionItemClasses(1)

Tmog.L = {
	-- Do not translate!
	["Cloth"] = cloth,
	["Leather"] = leather,
	["Mail"] = mail,
	["Plate"] = plate,
	["Miscellaneous"] = miscellaneous,
	["Daggers"] = daggers,
	["One-Handed Axes"] = axes,
	["One-Handed Swords"] = swords,
	["One-Handed Maces"] = maces,
	["Fist Weapons"] = fists,
	["Polearms"] = polearms,
	["Staves"] = staves,
	["Two-Handed Axes"] = axes2H,
	["Two-Handed Swords"] = swords2H,
	["Two-Handed Maces"] = maces2H,
	["Shields"] = shields,
	["Bows"] = bows,
	["Guns"] = guns,
	["Crossbows"] = crossbows,
	["Wands"] = wands,
	["Weapon"] = weapon,
	["Armor"] = armor,
	["Fishing Pole"] = fishingPole,
	----------------------------

	-- Translate
	["Collected"] = true,
	["Not collected"] = true,
	["Unique appearance"] = true,
	["Non-unique appearance"] = true,
	["Unknown appearance"] = true,
	["Shares appearance with"] = true,
	["Outfits"] = true,
	["New outfit"] = true,
	["Create an outfit from currently selected items."] = true,
	["Enter outfit name:"] = true,
	["Outfit with this name already exists."] = true,
	["Outfit name not valid."] = true,
	["Delete outfit?"] = true,
	["Invalid outfit code."] = true,
	["Enter outfit code:"] = true,
	["toggle dressing room"] = true,
	["reset minimap button position"] = true,
	["lock/unlock minimap button"] = true,
	["print debug messages in chat"] = true,
	["attempt to repair this character's cache (can fix minor bugs)"] = true,
	["minimap button unlocked"] = true,
	["minimap button locked"] = true,
	["debug is on"] = true,
	["debug is off"] = true,
	["Cache repair started."] = true,
	["bad item %d, requesting info from server, try #%d"] = true,
	["Cache repair finished: bad items deleted: %d, item names restored: %d, missing shared items added: %d"] = true,
	["Share outfit"] = true,
	["Import outfit"] = true,
	["Select outfit"] = true,
	["Save outfit"] = true,
	["Delete outfit"] = true,
	["Select type"] = true,
	["Only usable"] = true,
	["Check this to only show items that you can equip. Can be inaccurate for quest rewards."] = true,
	["Check this to ignore level requirements while \"Only usable\" filter is active. Can be inaccurate for quest rewards."] = true,
	["Ignore level"] = true,
	["Hide UI"] = true,
	["Show UI"] = true,
	["Clear"] = true,
	["Undress"] = true,
	["Reset Position"] = true,
	["Revert"] = true,
	["Full Screen"] = true,
	["Share"] = true,
	["Import"] = true,
	["Copy this code:"] = true,
	["Left-click to toggle dressing room\nHold Left-click and drag to move this button"] = true,
	["Loading"] = true,
}

if GetLocale() == "ruRU" then
	Tmog.L["Collected"] = "В коллекции"
	Tmog.L["Not collected"] = "Не в коллекции"
	Tmog.L["Unique appearance"] = "Уникальный внешний вид"
	Tmog.L["Non-unique appearance"] = "Не уникальный внешний вид"
	Tmog.L["Unknown appearance"] = "Неизвестный внешний вид"
	Tmog.L["Shares appearance with"] = "Общий внешний вид с"
	Tmog.L["Outfits"] = "Наряды"
	Tmog.L["New outfit"] = "Новый наряд"
	Tmog.L["Create an outfit from currently selected items."] = "Создать наряд из выбранных предметов."
	Tmog.L["Enter outfit name:"] = "Введите название наряда:"
	Tmog.L["Outfit with this name already exists."] = "Наряд с таким названием уже существует."
	Tmog.L["Outfit name not valid."] = "Некорректное название."
	Tmog.L["Delete outfit?"] = "Удалить наряд?"
	Tmog.L["Invalid outfit code."] = "Некорректный код."
	Tmog.L["Enter outfit code:"] = "Введите код наряда:"
	Tmog.L["toggle dressing room"] = "открыть примерочную."
	Tmog.L["reset minimap button position"] = "восстановить позицию мини-кнопки."
	Tmog.L["lock/unlock minimap button"] = "зафиксировать/разблокировать мини-кнопкую"
	Tmog.L["print debug messages in chat"] = "вывод отладочных сообщений в чат."
	Tmog.L["attempt to repair this character's cache (can fix minor bugs)"] = "попытка исправить кэш данного персонажа (может помочь в случае незначительных ошибок)"
	Tmog.L["minimap button unlocked"] = "мини-кнопка разблокирована"
	Tmog.L["minimap button locked"] = "мини-кнопка зафиксирована"
	Tmog.L["debug is on"] = "отладка включена"
	Tmog.L["debug is off"] = "отладка выключена"
	Tmog.L["Cache repair started."] = "Починка кэша начата."
	Tmog.L["bad item %d, requesting info from server, try #%d"] = "некорректный предмет %d, запрос с сервера номер %d"
	Tmog.L["Cache repair finished: bad items deleted: %d, item names restored: %d, missing shared items added: %d"] = "Починка кэша завершена: удалено предметов: %d, названий предметов восстановлено: %d, похожих предметов добавлено: %d"
	Tmog.L["Share outfit"] = "Экспортировать наряд"
	Tmog.L["Import outfit"] = "Импортировать наряд"
	Tmog.L["Select outfit"] = "Выбрать наряд"
	Tmog.L["Save outfit"] = "Сохранить наряд"
	Tmog.L["Delete outfit"] = "Удалить наряд"
	Tmog.L["Select type"] = "Выбрать тип"
	Tmog.L["Only usable"] = "Подходящее"
	Tmog.L["Ignore level"] = "Игнор. уровень"
	Tmog.L["Check this to only show items that you can equip. Can be inaccurate for quest rewards."] = "Кликните чтобы показать только те предметы, которые вы можете надеть. Награды за задания могут отображаться некорректно."
	Tmog.L["Check this to ignore level requirements while \"Only usable\" filter is active. Can be inaccurate for quest rewards."] = "Кликните чтобы не учитывать требуемый уровень предметов, когда \"Подходящее\" фильтр активен. Награды за задания могут отображаться некорректно."
	Tmog.L["Hide UI"] = "СкрытьUI"
	Tmog.L["Show UI"] = "Показ.UI"
	Tmog.L["Clear"] = "Очистить"
	Tmog.L["Undress"] = "Раздеть"
	Tmog.L["Reset Position"] = "Сброс позиции"
	Tmog.L["Revert"] = "Сброс"
	Tmog.L["Full Screen"] = "Во весь экран"
	Tmog.L["Share"] = "Экспорт"
	Tmog.L["Import"] = "Импорт"
	Tmog.L["Copy this code:"] = "Скопируйте код:"
	Tmog.L["Left-click to toggle dressing room\nHold Left-click and drag to move this button"] = "ЛКМ чтобы открыть или закрыть примерочную\nУдерживайте ЛКМ и тащите чтобы перемесить эту кнопку."
	Tmog.L["Loading"] = "Загрузка"

elseif GetLocale() == "esES" then

elseif GetLocale() == "ptBR" then

elseif GetLocale() == "zhCN" then

elseif GetLocale() == "deDE" then

end

for k, v in pairs(Tmog.L) do
	if v == true then
		Tmog.L[k] = k
	end
end