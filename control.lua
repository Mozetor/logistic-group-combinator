local function on_tick(event)
    for _, comb in pairs(storage.logGroupComb or {}) do
        if comb.valid then
            local control_behaviour = comb.get_control_behavior()
            local circuit_net_green = comb.get_circuit_network(defines.wire_connector_id.circuit_green)

            if control_behaviour ~= nil and control_behaviour.sections_count > 0 and circuit_net_green ~= nil then
                local section = control_behaviour.get_section(1)
                if section.group ~= "" then
                    local filters = {}
                    local signal_index = {}

                    for _, signal in ipairs(circuit_net_green.signals or {}) do
                        if signal.signal.name then
                            local signal_name = signal.signal.name
                            local signal_type = signal.signal.type or "item"
                            local signal_quality = signal.signal.quality or "normal"
                            local key = signal_type .. "|" .. signal_name .. "|" .. signal_quality

                            if signal_index[key] then
                                local index = signal_index[key]
                                filters[index].min = filters[index].min + signal.count
                            else
                                table.insert(filters, {
                                    value = {
                                        comparator = "=",
                                        type = signal_type,
                                        name = signal_name,
                                        quality = signal_quality
                                    },
                                    min = signal.count
                                })
                                signal_index[key] = #filters
                            end
                        end
                    end

                    section.filters = filters
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