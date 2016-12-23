local Tablet = AceLibrary("Tablet-2.0")
local L = AceLibrary("AceLocale-2.0"):new("FuBar_ZepMaster")

ZepMaster = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceConsole-2.0", "AceDB-2.0", "FuBarPlugin-2.0")

ZepMaster.version = "2.0." .. string.sub("$Revision: 0001 $", 12, -3)
ZepMaster.hasIcon = false
ZepMaster.defaultPosition = 'RIGHT'
ZepMaster.hideWithoutStandby = true
ZepMaster.clickableTooltip = true

function ZepMaster:OnEnable()
	self:SetText("ZepMaster");
	self:ScheduleRepeatingEvent(self.Update, 1, self)
end

-- Disabled this feature for now.  It's almost done, but not sure it's worthwhile.
function ZepMaster:OnTextUpdateDisabled()
	local tooltiptext = "ZepMaster";
	local lowestName;
	local lowestTime = 500;
	local lowestTimeStr;	
		
	if ((activeTransit ~= -1) and (known_times[activeTransit] ~= nil)) then
			local transit = activeTransit;
			local cycle = ZSM_CalcTripCycle(transit);
			local coord_data = ZSM_GetZepCoords(transit, cycle);					
			
			tooltiptext = tooltiptext..activeTransitName.."\n\n";
			
			for index, data in zsm_data[transit..'_plats'] do
					--ZSM_CalcTripCycleTime(transit,cycle)								
					--DEFAULT_CHAT_FRAME:AddMessage(data['name']..":"..ZSM_CalcTripCycleTimeByIndex(transit,data['index']-1));																 				
					local arrival_time = 0;
					if (ZSM_CalcTripCycleTimeByIndex(transit,data['index']-1) > (cycle*zsm_data[transit..'_time'])) then
							arrival_time = ZSM_CalcTripCycleTimeByIndex(transit,data['index']-1) - (cycle*zsm_data[transit..'_time']);
							--DEFAULT_CHAT_FRAME:AddMessage("Arrival Time of "..data['name']..": "..arrival_time .." sec.");										
					else
							arrival_time = zsm_data[transit..'_time'] - (cycle*zsm_data[transit..'_time']);
							arrival_time = arrival_time + ZSM_CalcTripCycleTimeByIndex(transit,data['index']-1);
							--DEFAULT_CHAT_FRAME:AddMessage("Arrival Time of "..data['name']..": "..arrival_time .." sec.");
					end 
					--DEFAULT_CHAT_FRAME:AddMessage(GetRealZoneText());
													
					local platname;
					if (ZSM_Data['Opts']['CityAlias']) then
							platname = data['alias'];
					else
							platname = data['name'];
					end																
					getglobal("ZSMFramePlat"..(index+1).."Name"):SetText(platname);								
					
					local coord_data = ZSM_GetZepCoords(transit, cycle);
					local depart_time = ZSM_CalcTripCycleTime(transit,cycle) - (cycle*zsm_data[transit..'_time']) - data['adj'];
					
					local formated_depart_time = "";
					if (depart_time > 59) then
							local time_min = format("%0.0f",math.floor(depart_time/60));
							local time_sec = format("%0.0f",depart_time-(math.floor(depart_time/60)*60));
							formated_depart_time = time_min.."m, "..time_sec.."s";
					else
							formated_depart_time = format("%0.0f",depart_time).."s";
					end				

					local formated_arrival_time = "";
					if (arrival_time > 59) then
							local time_min = format("%0.0f",math.floor(arrival_time/60));
							local time_sec = format("%0.0f",arrival_time-(math.floor(arrival_time/60)*60));
							formated_arrival_time = time_min.."m, "..time_sec.."s";
					else
							formated_arrival_time = format("%0.0f",arrival_time).."s";
					end															
					
					if ((data['x'] == tonumber(coord_data[1])) and (data['y'] == tonumber(coord_data[2])) and (depart_time > 0)) then					
							tooltiptext = "ZM: "..platname.." D:: ".. formated_depart_time;
					else 
							
							tooltiptext = "ZM: "..platname.." A: ".. formated_arrival_time;

					end																	
			end		
	elseif ((activeTransit ~= -1) and (known_times[activeTransit] == nil)) then					
			local transit = activeTransit;
			
			tooltiptext = tooltiptext..activeTransitName.."\n\n";
			
			for index, data in zsm_data[transit..'_plats'] do
					
					local platname;
					if (ZSM_Data['Opts']['CityAlias']) then
							platname = data['alias'];
					else
							platname = data['name'];
					end
				

					tooltiptext = tooltiptext..platname.."\n";
					tooltiptext = tooltiptext..L["N/A"];
					
					
			end
	end
	self:SetText(tooltiptext);
end

function ZepMaster:OnClick()
	ZSM_Data['Opts']['ShowGUI'] = not ZSM_Data['Opts']['ShowGUI'];
	if (ZSM_Data['Opts']['ShowGUI']) then
		ZSMHeaderFrame:Show();
	else
		ZSMHeaderFrame:Hide();
	end
end

function ZepMaster:OnMenuClick(val)
	DEFAULT_CHAT_FRAME.editBox:Show();
	DEFAULT_CHAT_FRAME.editBox:SetText(val);
end

function ZepMaster:OnTooltipUpdate()
	local cat = Tablet:AddCategory(
		'columns', 3,
		'child_textR', 1,
		'child_textG', 1,
		'child_textB', 0,
		'child_text2R', 1,
		'child_text2G', 1,
		'child_text2B', 0,
		'child_text3R', 1,
		'child_text3G', 1,
		'child_text3B', 0
	);

	cat:AddLine(
		'text', string.format(L["Platform"]),
		'text2', string.format(L["Path"]),
		'text3', string.format(L["ETA"])
	);

	for i = 1, getn(zsm_data['transports']), 1 do
		local transit = zsm_data['transports'][i]['label'];

		for index, data in zsm_data[transit..'_plats'] do

			if ((ZSM_Data['Opts']['FactionSpecific']) 	-- Only display faction specific transports if that's what settings say.
				and ((zsm_data['transports'][i]['faction'] == UnitFactionGroup("player")) or (zsm_data['transports'][i]['faction'] == "Nuetral"))
				and (not ZSM_Data['Opts']['ZoneSpecific']	-- Only display zone specific transports if that's what settings say.
					or not string.find(string.lower(zsm_data['transports'][i]['name']), string.lower(GetRealZoneText())))
				) then
				
				local platname;
				local zepname;
				
				if (ZSM_Data['Opts']['CityAlias']) then
						platname = data['alias'];
				else
						platname = data['name'];
				end
				if (ZSM_Data['Opts']['CityAlias']) then
						zepname = zsm_data['transports'][i]['namealias'];
				else
						zepname = zsm_data['transports'][i]['name'];
				end
				if (known_times[transit] == nil) then
					cat:AddLine( 
							'text', platname,
							'text2', zepname,
							'text3', L["Unknown"]
						);
				else
					local arrival_time = 0;
					local cycle = ZSM_CalcTripCycle(transit);
					local coord_data = ZSM_GetZepCoords(transit, cycle);

					if (ZSM_CalcTripCycleTimeByIndex(transit,data['index']-1) > (cycle*zsm_data[transit..'_time'])) then
							arrival_time = ZSM_CalcTripCycleTimeByIndex(transit,data['index']-1) - (cycle*zsm_data[transit..'_time']);
							--DEFAULT_CHAT_FRAME:AddMessage("Arrival Time of "..data['name']..": "..arrival_time .." sec.");										
					else
							arrival_time = zsm_data[transit..'_time'] - (cycle*zsm_data[transit..'_time']);
							arrival_time = arrival_time + ZSM_CalcTripCycleTimeByIndex(transit,data['index']-1);
							--DEFAULT_CHAT_FRAME:AddMessage("Arrival Time of "..data['name']..": "..arrival_time .." sec.");
					end 
					--DEFAULT_CHAT_FRAME:AddMessage(GetRealZoneText());
													
					local platname;
					local destname;
					if (ZSM_Data['Opts']['CityAlias']) then
							platname = data['alias'];
					else
							platname = data['name'];
					end																
					
					local coord_data = ZSM_GetZepCoords(transit, cycle);
					local depart_time = ZSM_CalcTripCycleTime(transit,cycle) - (cycle*zsm_data[transit..'_time']) - data['adj'];
					
					local formated_depart_time = format("%0.0f",math.floor(depart_time/60))..":"..format("%02.0f",depart_time-(math.floor(depart_time/60)*60));
					local formated_arrival_time = format("%0.0f",math.floor(arrival_time/60))..":"..format("%02.0f",arrival_time-(math.floor(arrival_time/60)*60));
					
					if ((data['x'] == tonumber(coord_data[1])) and (data['y'] == tonumber(coord_data[2])) and (depart_time > 0)) then					
						local color;
						if (depart_time > 30) then
							cat:AddLine( 
									'text', platname,
									'text2',zepname,
									'text3', L["Departs in"] .. " " .. formated_depart_time,
									'child_text3G', 0,
									'child_text3R', 0,
									'child_text3B', 1,
									'func', 'OnMenuClick',
									'arg1', self,
									'arg2', zepname .. " " .. L["will be departing"] .. " " .. platname .. " " .. L["in"] .. " " .. formated_depart_time
								);
						else
							cat:AddLine( 
									'text', platname,
									'text2', zepname,
									'text3', L["Departs in"] .. " " .. formated_depart_time,
									'child_text3G', 0,
									'child_text3R', 1,
									'child_text3B', 0,
									'func', 'OnMenuClick',
									'arg1', self,
									'arg2', zepname .. " " .. L["will be departing"] .. " " .. platname .. " " .. L["in"] .. " " .. formated_depart_time
								);
							end
					else 
							
						cat:AddLine( 
								'text', platname,
								'text2',zepname,
								'text3', formated_arrival_time,
								'child_text3G', 1,
								'child_text3R', 0,
								'child_text3B', 0,
								'func', 'OnMenuClick',
								'arg1', self,
								'arg2', zepname .. " " .. L["will be arriving at"] .. " " .. platname .. " " .. L["in"] .. " " .. formated_arrival_time
							);

					end																	
				end				
			end
			
		
					
		end
	end
end
