
if isPlaying() and isHost() then
    if managers.job:current_level_id() == 'alex_1' or managers.job:current_level_id() == 'rat' then

        _auto_cook_data = _auto_cook_data or {}
        _auto_cook_data['enabled'] = _auto_cook_data['enabled'] or false
        _auto_cook_data['initialized'] = _auto_cook_data['initialized'] or false

        if not _auto_cook_data['initialized'] then
            _auto_cook_data['initialized'] = true
            _auto_cook_data["original"] = DialogManager.queue_dialog

            _auto_cook_data["getRequiredFor"] = function(name)
                if name == "methlab_caustic_cooler" then
                    return "caustic_soda"
                elseif name == "methlab_bubbling" then
                    return "muriatic_acid"
                elseif name == "methlab_gas_to_salt" then
                    return "hydrogen_chloride"
                end
            end

            _auto_cook_data["getMeth"] = function()
                local player = managers.player:local_player()
                if not player then return end
                for _,unit in pairs(managers.interaction._interactive_units) do
                    if unit:interaction().tweak_data == "taking_meth" then
                        if unit:interaction():can_interact(player) then
                            unit:interaction():interact(player)
                        end
                        break
                    end
                end
            end

            _auto_cook_data["getBag"] = function(bag)
                local player = managers.player:local_player()
                if not player then return end
                for _,unit in pairs(managers.interaction._interactive_units) do
                    if unit:interaction().tweak_data == "carry_drop" then
                        if unit:interaction()._unit:carry_data()._carry_id == bag then
                            if unit:interaction():can_interact(player) then
                                unit:interaction():interact(player)
                            end
                            break
                        end
                    end
                end
            end

            _auto_cook_data["lightFlare"] = function()
                local player = managers.player:local_player()
                if not player then return end
                local found = false
                for _,unit in pairs(managers.interaction._interactive_units) do
                    if unit:interaction().tweak_data == "use_flare" or unit:interaction().tweak_data == "place_flare" or unit:interaction().tweak_data == "ignite_flare" then
                        found = true
                        unit:interaction():interact(player)
                        break
                    end
                end
            end

            _auto_cook_data["cook"] = function(drugs)
                local player = managers.player:local_player()
                local needed = _auto_cook_data["getRequiredFor"](drugs)
                if not player then return end
                for _,unit in pairs(managers.interaction._interactive_units) do
                    if unit:interaction().tweak_data == needed then
                        unit:interaction():interact(player)
                    end
                    break
                end
                found = false
                for _,unit in pairs(managers.interaction._interactive_units) do
                    if unit:interaction().tweak_data == drugs then
                        unit:interaction():interact(player)
                    end
                    break
                end
            end

            function DialogManager:queue_dialog(id, params)
                if _auto_cook_data["enabled"] then
                    if id == "pln_rt1_22" then
                        _auto_cook_data["cook"]("methlab_caustic_cooler")
                    elseif id == "pln_rt1_20" then
                        _auto_cook_data["cook"]("methlab_bubbling")
                    elseif id == "pln_rt1_24" then
                        _auto_cook_data["cook"]("methlab_gas_to_salt")
                    end
                end
                return _auto_cook_data["original"](self, id, params)
            end

            _auto_cook_data["original_update"] = update
            _auto_cook_data['timer'] = TimerManager:main()

            _auto_cook_data["last_tick"] = math.floor(_auto_cook_data['timer']:time())
            function onUpdate( ... )
                if _auto_cook_data["last_tick"] + 1 == math.floor(_auto_cook_data['timer']:time()) then
                    if _auto_cook_data["enabled"] then
                        _auto_cook_data["getMeth"]()
                        _auto_cook_data["getBag"]("equipment_bag")
                        _auto_cook_data["lightFlare"]()
                    end
                    _auto_cook_data["last_tick"] = math.floor(_auto_cook_data['timer']:time())
                end
                return _auto_cook_data["original_update"]( ... )
            end

            rawset(_G, "update", onUpdate)
        end

        if _auto_cook_data['enabled'] then
            _auto_cook_data['enabled'] = false
            show_mid_text( "Press again to re-enable.", "Auto Cooking Disabled", 2 )
        else
            _auto_cook_data['enabled'] = true
            show_mid_text( "Note: For meth and equipment, you'd better have nothing equiped or use a carry stacker.", "Auto Cooking Enabled", 3 )
        end

    else
        showHint('NOT AVAILABLE', 2)
    end
end
