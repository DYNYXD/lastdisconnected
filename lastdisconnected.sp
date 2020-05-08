#include <sourcemod>
#include <adminmenu>
#include <multicolors>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define PREFIX "\x04[\x01Disconnected\x04] "

ConVar gcv_iArraySize = null;

ArrayList g_Name;
ArrayList g_SID;

public Plugin myinfo =
{
	name = "Last disconnected players list",
	author = "Dyny",
	description = "Last 10 disconnected players",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_disconnected", Command_Disconnected);

	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	LoadADTArray();
}

public void OnClientPostAdminCheck(int client)
{
	char SID1[32];
	GetClientAuthId(client, AuthId_Steam2, SID1, sizeof(SID1));

	if (FindStringInArray(g_SID, SID1) != -1)
	{
		g_Name.Erase(g_SID.FindString(SID1));
		g_SID.Erase(g_SID.FindString(SID1));
	}
}

public Action Event_PlayerDisconnect(Event hEvent, char[] name, bool bDontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (IsValidClient(client))
	{
		char Name[MAX_NAME_LENGTH];
		GetClientName(client, Name, sizeof(Name));
		
		char DisconnectedSID1[32];
		GetClientAuthId(client, AuthId_Steam2, DisconnectedSID1, sizeof(DisconnectedSID1));
		
		if (FindStringInArray(g_SID, DisconnectedSID1) == -1)
		{
			PushToArrays(Name, DisconnectedSID1);
		}
	}
}

void PushToArrays(const char[] clientName, const char[] clientSteam)
{	
	if (g_Name.Length == 0)
	{
		g_Name.PushString(clientName);
		g_SID.PushString(clientSteam);
	}
	else
	{
		g_Name.ShiftUp(0);
		g_SID.ShiftUp(0);
		
		g_Name.SetString(0, clientName);
		g_SID.SetString(0, clientSteam);
	}
	
	if (g_Name.Length >= gcv_iArraySize.IntValue && gcv_iArraySize.IntValue > 0)
	{
		g_Name.Resize(gcv_iArraySize.IntValue);
		g_SID.Resize(gcv_iArraySize.IntValue);
	}
}

public Action Command_Disconnected(int client, int args)
{
	if (g_Name.Length >= 10)
	{
		CPrintToChat(client, "Last {darkred}%i {default}Disconnected players");
		for (int i = 0; i <= 10; i++)
		{
			char Name[MAX_TARGET_LENGTH], SID1[32];
			
			g_Name.GetString(i, Name, sizeof(Name));
			g_SID.GetString(i, SID1, sizeof(SID1));
			
			CPrintToChat(client, "Name : {green}%s  {default}SteamID : {green}%s", Name, SID1);
		}
	}
	else
	{
		if (g_Name.Length == 0)
		{
			CPrintToChat(client, "%s Not enough disconnected players yet!!", PREFIX);
		}
		else
		{
			CPrintToChat(client, "Last {darkred}%i {default}Disconnected players", GetArraySize(g_Name));
			for (int i = 0; i < g_Name.Length; i++)
			{
				char Name[MAX_TARGET_LENGTH], SID1[32];
				
				g_Name.GetString(i, Name, sizeof(Name));
				g_SID.GetString(i, SID1, sizeof(SID1));
			
				CPrintToChat(client, "Name : {green}%s  {default}SteamID : {green}%s", Name, SID1);
			}
		}
	}
	return Plugin_Handled;
}

void LoadADTArray()
{
	g_Name = new ArrayList(MAX_TARGET_LENGTH);
	g_SID = new ArrayList(32);
}

bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}