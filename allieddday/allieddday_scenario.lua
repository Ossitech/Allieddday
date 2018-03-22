version = 3
ScenarioInfo = {
  name = 'Allied D-Day',
  type = 'skirmish',
  description = '<LOC allieddday_Description>Die Allierten kommen um an der Küste der Normandie zu landen. Das Dritte Reich (also ihr) hat die Aufgabe die Amis davon abzuhalten BurgerKing in Europa einzuführen.',
  starts = true,
  preview = '',
  size = {1024, 1024},
  norushradius = 0,
  norushoffsetX_ARMY_1 = 0,
  norushoffsetY_ARMY_1 = 0,
  norushoffsetX_ARMY_2 = 0,
  norushoffsetY_ARMY_2 = 0,
  norushoffsetX_ARMY_3 = 0,
  norushoffsetY_ARMY_3 = 0,
  norushoffsetX_ARMY_4 = 0,
  norushoffsetY_ARMY_4 = 0,
  norushoffsetX_ARMY_5 = 0,
  norushoffsetY_ARMY_5 = 0,
  norushoffsetX_ARMY_6 = 0,
  norushoffsetY_ARMY_6 = 0,
  norushoffsetX_ARMY_7 = 0,
  norushoffsetY_ARMY_7 = 0,
  norushoffsetX_ARMY_8 = 0,
  norushoffsetY_ARMY_8 = 0,
  map = '/maps/allieddday/allieddday.scmap',
  save = '/maps/allieddday/allieddday_save.lua',
  script = '/maps/allieddday/allieddday_script.lua',
  Configurations = {
    ['standard'] = {
      teams = {
        { name = 'FFA', armies = {'ARMY_1','ARMY_2','ARMY_3','ARMY_4','ARMY_5','ARMY_6','ARMY_7','ARMY_8',} },
      },
      customprops = {
        ['ExtraArmies'] = STRING( 'ARMY_9 NEUTRAL_CIVILIAN ARMY_SURVIVAL_ALLY ARMY_SURVIVAL_ENEMY' ),
      },
    },
  }}
