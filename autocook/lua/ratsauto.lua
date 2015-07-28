
if isPlaying() and isHost() then

    _auto_cook_data = _auto_cook_data or {}
    _auto_cook_data['enabled'] = _auto_cook_data['enabled'] or false
    _auto_cook_data['initialized'] = _auto_cook_data['initialized'] or false

    -- Initialize if not initialized
    if not _auto_cook_data['initialized'] then
        _auto_cook_data['initialized'] = true
        _auto_cook_data["original"] = DialogManager.queue_dialog
        _auto_cook_data["pass"] = function() return true end

        -- Requirement map (acid vat to insert into => muriatic acid)
        _auto_cook_data["requirement_map"] = {}
        _auto_cook_data["requirement_map"]["methlab_caustic_cooler"] = "caustic_soda"
        _auto_cook_data["requirement_map"]["methlab_bubbling"] = "muriatic_acid"
        _auto_cook_data["requirement_map"]["methlab_gas_to_salt"] = "hydrogen_chloride"

        -- Grabbing function
        _auto_cook_data["getSingle"] = function(items, test)
            local player = managers.player:local_player()
            test = test or _auto_cook_data["pass"]
            if not player then return end
            for _,unit in pairs(managers.interaction._interactive_units) do
                for _,item in pairs(items) do
                    if unit:interaction().tweak_data == item then
                        if test(unit) then
                            if unit:interaction():can_interact(player) then
                                unit:interaction():interact(player)
                            end
                            break
                        end
                    end
                end
            end
        end

        -- Figure out the correct cooking flag
        _auto_cook_data["original_update"] = update
        function DialogManager:queue_dialog(id, params)
            if _auto_cook_data["enabled"] then
                if id == "pln_rt1_22" then
                    _auto_cook_data["cook_flag"] = "methlab_caustic_cooler"
                elseif id == "pln_rt1_20" then
                    _auto_cook_data["cook_flag"] = "methlab_bubbling"
                elseif id == "pln_rt1_24" then
                    _auto_cook_data["cook_flag"] = "methlab_gas_to_salt"
                end
            end
            return _auto_cook_data["original"](self, id, params)
        end

        -- Override the main update loop to execute once per second
        _auto_cook_data['timer'] = TimerManager:main()
        _auto_cook_data["last_tick"] = math.floor(_auto_cook_data['timer']:time())
        function onUpdate( ... )
            if managers.job:current_level_id() == 'alex_1' or managers.job:current_level_id() == 'rat' then
                if _auto_cook_data["enabled"] then
                    if _auto_cook_data["last_tick"] ~= math.floor(_auto_cook_data['timer']:time()) then

                        -- Grab Meth Ingredients
                        _auto_cook_data["getSingle"]({"taking_meth"})


                        -- Cook
                        if _auto_cook_data["cook_flag"] then
                            -- Get Ingredients
                            _auto_cook_data["getSingle"]({_auto_cook_data["requirement_map"][_auto_cook_data["cook_flag"]]})
                            -- Insert Ingredients
                            _auto_cook_data["getSingle"]({_auto_cook_data["cook_flag"]})
                            -- Reset
                            _auto_cook_data["cook_flag"] = nil
                        end

                        -- Light the flare
                        _auto_cook_data["getSingle"]({"use_flare", "place_flare", "ignite_flare"})

                        -- Grab the ingredients bag
                        _auto_cook_data["getSingle"]({"carry_drop"}, function(unit)
                            return unit:interaction()._unit:carry_data()._carry_id == "equipment_bag"
                        end)
                    end
                    _auto_cook_data["last_tick"] = math.floor(_auto_cook_data['timer']:time())
                end
            end
            return _auto_cook_data["original_update"]( ... )
        end
        update = onUpdate

    end

    -- Toggles
    ChatMessage(managers.job:current_level_id(), "LEVEL")
    if managers.job:current_level_id() == 'alex_1' or managers.job:current_level_id() == 'rat' or managers.job:current_level_id() == 'mia_1' then
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
