#if defined _weapon_spawner_menus_included
	#endinput
#endif
#define _weapon_spawner_menus_included

void DisplayOfferMenu(int client, int id)
{
	Menu menu = new Menu(OfferMenuHandler, MENU_ACTIONS_DEFAULT|MenuAction_DisplayItem);

	for(int i = 0; i < 2; ++i)
		menu.AddItem("", "");
	
	char szName[128];
	g_Config.GetTypeName(id, szName, sizeof(szName));
	int price = g_Config.GetPrice(id);
	menu.SetTitle("%T", "Offer Menu Title", client, szName, price);
	menu.ExitButton = false;
	menu.Display(client, 20);
}

public int OfferMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	switch(action)
	{
		case MenuAction_End:
			menu.Close();
		
		case MenuAction_DisplayItem:
		{
			char szBuffer[128];
			switch(param)
			{
				case 0: Format(szBuffer, sizeof(szBuffer), "%T", "Yes", client);
				case 1: Format(szBuffer, sizeof(szBuffer), "%T", "No", client);
			}
			return RedrawMenuItem(szBuffer);
		}

		case MenuAction_Select:
		{
			if(param != 0 || !IsPlayerAlive(client))
				return 0;
			
			int trigger = EntRefToEntIndex(g_iTargetRef[client]);
			if(!IsValidEntity(trigger) || GetEntPropEnt(trigger, Prop_Send, "m_hEffectEntity") == -1)
				return 0;
			
			float fClientOrigin[3], fTriggerOrigin[3];
			GetClientAbsOrigin(client, fClientOrigin);
			GetEntPropVector(trigger, Prop_Send, "m_vecOrigin", fTriggerOrigin);
			if(GetVectorDistance(fClientOrigin, fTriggerOrigin) > 100.0)
			{
				return 0;
			}

			int id = GetEntProp(trigger, Prop_Data, "m_iHammerID");
			int price = g_Config.GetPrice(id);
			int money = GetEntProp(client, Prop_Send, "m_iAccount");
			if(money < price)
			{
				char szName[128];
				g_Config.GetTypeName(id, szName, sizeof(szName));
				CGOPrintToChat(client, "%t", "Not Enough Money", szName, price);
				return 0;
			}

			char szItemName[128], szItem[128];
			if(!g_Config.GetRandomItem(id, szItemName, sizeof(szItemName), szItem, sizeof(szItem)))
				return 0;
			
			if(g_Modules.OnGet(client, szItem))
			{
				SetEntProp(client, Prop_Send, "m_iAccount", money - price);
				CGOPrintToChat(client, "%t", "You Get Item", szItemName, price);

				g_UseCounter.IncUseCount(client, trigger);
				if(IsLimitReached(trigger, id))
				{
					DisableSpawn(trigger);
					return 0;
				}

				ReloadSpawn(trigger, id);
			}
		}
	}
	return 0;
}

void DisplayItemsListMenu(int client, int id)
{
	Menu menu = new Menu(ItemsListMenuHandler);
	if(g_Config.AddItemsToMenu(id, menu))
	{
		char szName[128];
		g_Config.GetTypeName(id, szName, sizeof(szName));
		int price = g_Config.GetPrice(id);
		menu.SetTitle("%T", "Items List Menu Title", client, szName, price);
		menu.Display(client, 20);
	}
	else
	{
		menu.Close();
	}
}

public int ItemsListMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	switch(action)
	{
		case MenuAction_End:
			menu.Close();
		
		case MenuAction_Select:
		{
			if(!IsPlayerAlive(client))
				return 0;
			
			int trigger = EntRefToEntIndex(g_iTargetRef[client]);
			if(!IsValidEntity(trigger) || GetEntPropEnt(trigger, Prop_Send, "m_hEffectEntity") == -1)
				return 0;
			
			float fClientOrigin[3], fTriggerOrigin[3];
			GetClientAbsOrigin(client, fClientOrigin);
			GetEntPropVector(trigger, Prop_Send, "m_vecOrigin", fTriggerOrigin);
			if(GetVectorDistance(fClientOrigin, fTriggerOrigin) > 100.0)
			{
				return 0;
			}

			int id = GetEntProp(trigger, Prop_Data, "m_iHammerID");
			int price = g_Config.GetPrice(id);
			int money = GetEntProp(client, Prop_Send, "m_iAccount");
			if(money < price)
			{
				char szName[128];
				g_Config.GetTypeName(id, szName, sizeof(szName));
				CGOPrintToChat(client, "%t", "Not Enough Money", szName, price);
				return 0;
			}
			
			char szItem[128], szName[128];
			menu.GetItem(param, szItem, sizeof(szItem), _, szName, sizeof(szName));
			if(g_Modules.OnGet(client, szItem))
			{
				SetEntProp(client, Prop_Send, "m_iAccount", money - price);
				CGOPrintToChat(client, "%t", "You Get Item", szName, price);

				g_UseCounter.IncUseCount(client, trigger);
				if(IsLimitReached(trigger, id))
				{
					DisableSpawn(trigger);
					return 0;
				}

				ReloadSpawn(trigger, id);
			}
		}
	}
	return 0;
}
