
local function on_tick(event)
  for _, comb in pairs(storage.logGroupComb or {}) do
    if comb.valid then
      control_behaviour = comb.get_control_behavior()
      circuit_net_green = comb.get_circuit_network(defines.wire_connector_id.circuit_green)

      if control_behaviour ~= nil and control_behaviour.sections_count > 0 and circuit_net_green ~= nil then
        section = control_behaviour.get_section(1)
        if section.group ~= "" then
          for i = 1, section.filters_count, 1 do
            section.clear_slot(i)
          end
          current_signals = {}
          current_index = 1
          for _, signal in ipairs(circuit_net_green.signals or {}) do
            if signal.signal.type == nil then
              if current_signals[signal.signal.name] == nil then
                local slot = {
                  value = signal.signal.name,
                  min=signal.count
                }
                section.set_slot(current_index, slot)
                current_signals[signal.signal.name] = {index=current_index, count=signal.count}
                current_index = current_index + 1
              else
                current_signals[signal.signal.name].count = current_signals[signal.signal.name].count + signal.count
                local slot = {
                  value = signal.signal.name,
                  min= current_signals[signal.signal.name].count
                }
                section.set_slot(current_signals[signal.signal.name].index, slot)
              end
            end
          end
        end
      end
    end
  end
end

local function on_entity_created(event)
  local entity = event.created_entity or event.entity
  if entity and entity.valid then
    table.insert(storage.logGroupComb, entity)
  end
end

local function on_entity_removed(event)
  local newLogGroupComb = {}
  local entity = event.entity
  if entity and entity.valid then
    for _, v in pairs(storage.logGroupComb) do
      if v ~= entity then
        table.insert(newLogGroupComb, v)
      end
    end
  end
  storage.logGroupComb = newLogGroupComb
end

do

  local function init_combinators()
    storage.logGroupComb = {}

    for _, surface in pairs(game.surfaces) do
      local lgcs = surface.find_entities_filtered{ name = {
        "logistic-group-combinator",
      } }
      for _, lgc in pairs(lgcs) do
        table.insert(storage.logGroupComb, lgc)
      end
    end
  end

  local function init_events()
    local filter = {
      { filter="name", name="logistic-group-combinator"},
    }
    script.on_event(defines.events.on_built_entity, on_entity_created, filter)
    script.on_event(defines.events.on_robot_built_entity, on_entity_created, filter)
    script.on_event(defines.events.script_raised_built, on_entity_created, filter)
    script.on_event(defines.events.script_raised_revive, on_entity_created, filter)
    script.on_event(defines.events.on_space_platform_built_entity, on_entity_created, filter)
    script.on_event(defines.events.on_tick, on_tick)
    script.on_event(defines.events.on_player_mined_entity, on_entity_removed, filter)
    script.on_event(defines.events.on_robot_mined_entity, on_entity_removed, filter)
    script.on_event(defines.events.on_entity_died, on_entity_removed, filter)
    script.on_event(defines.events.script_raised_destroy, on_entity_removed, filter)
    script.on_event(defines.events.on_space_platform_mined_entity, on_entity_removed, filter)
  end

  -- Register load handler
  script.on_load(function()
    init_events()
  end)

  -- Register init handler
  script.on_init(function()
    init_combinators()
    init_events()
  end)

  -- Register configuration changed handler
  script.on_configuration_changed(function(data)
    init_combinators()
    init_events()
  end)

end