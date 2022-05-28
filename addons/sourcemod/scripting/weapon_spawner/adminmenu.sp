#if defined _weapon_spawner_adminmenu_included
	#endinput
#endif
#define _weapon_spawner_adminmenu_included

TopMenu g_AdminMenu = null;

void InitAdminMenu()
{
	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
		OnAdminMenuReady(topmenu);
}

public void OnAdminMenuReady(Handle hTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(hTopMenu);
	
	if(topmenu == g_AdminMenu)
		return;
	
	g_AdminMenu = topmenu;
	
	TopMenuObject obj_server_commands = g_AdminMenu.FindCategory(ADMINMENU_SERVERCOMMANDS);
	if(obj_server_commands == INVALID_TOPMENUOBJECT)
		return;
	
	g_AdminMenu.AddItem("sm_weapon_spawner", AdminMenu_WeaponSpawner, obj_server_commands, "sm_weapon_spawner", ADMFLAG_ROOT);
}

public void AdminMenu_WeaponSpawner(Handle topmenu, TopMenuAction action, TopMenuObject topobj_id, int client, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "Admin Menu Item", client);
		case TopMenuAction_SelectOption:
			DisplayMainAdminMenu(client);
	}
}

void DisplayMainAdminMenu(int client)
{
	Menu menu = new Menu(MainAdminMenuHandler, MENU_ACTIONS_DEFAULT | MenuAction_DisplayItem);

	for(int i = 0; i < 2; ++i)
		menu.AddItem("", "");
	
	menu.SetTitle("%T", "Main Admin Menu Title", client, g_PointConfig.Length);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MainAdminMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	switch(action)
	{
		case MenuAction_End:
			menu.Close();
		
		case MenuAction_Cancel:
		{
			if(param == MenuCancel_ExitBack && g_AdminMenu != null)
				g_AdminMenu.Display(client, TopMenuPosition_LastCategory);
		}
		
		case MenuAction_DisplayItem:
		{
			char szBuffer[128];
			switch(param)
			{
				case 0:	Format(szBuffer, sizeof(szBuffer), "%T", "Add Spawn Item", client);
				case 1:	Format(szBuffer, sizeof(szBuffer), "%T", "Remove Spawn Item", client);
			}
			return RedrawMenuItem(szBuffer);
		}
		
		case MenuAction_Select:
		{
			switch(param)
			{
				case 0:
				{
					DisplaySpawnTypeMenu(client);
				}

				case 1:
				{
					RemoveSpawns(client);
					DisplayMainAdminMenu(client);
				}
			}
		}
	}
	return 0;
}

void DisplaySpawnTypeMenu(int client)
{
	Menu menu = new Menu(SpawnTypeMenuHandler);
	if(g_Config.AddSpawnTypesToMenu(menu))
	{
		menu.SetTitle("%T", "Spawn Type Menu Title", client, g_PointConfig.Length);
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		menu.Close();
		DisplayMainAdminMenu(client);
	}
}

public int SpawnTypeMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	switch(action)
	{
		case MenuAction_End:
			menu.Close();
		
		case MenuAction_Cancel:
		{
			if(param == MenuCancel_ExitBack)
				DisplayMainAdminMenu(client);
		}
		
		case MenuAction_Select:
		{
			char szInfo[128];
			menu.GetItem(param, szInfo, sizeof(szInfo));
			int id = StringToInt(szInfo);

			float fOrigin[3];
			if(GetEndPosition(client, fOrigin))
			{
				Point point;
				
				for(int i = 0; i < 3; ++i)
					point.vOrigin[i] = fOrigin[i];

				g_Config.GetTypeName(id, point.szName, sizeof(point.szName));
				g_PointConfig.AddPoint(point);
				g_PointConfig.Save();
				CreatePoint(point);
			}

			DisplayMainAdminMenu(client);
		}
	}
	return 0;
}
