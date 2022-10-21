#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
new Handle:cvarServerNameFormatCase1 = INVALID_HANDLE;
new Handle:cvarMpGameMode = INVALID_HANDLE;
new Handle:cvarSI = INVALID_HANDLE;
new Handle:cvarMpGameMin = INVALID_HANDLE;
new Handle:cvarHostPort = INVALID_HANDLE;
new String:SavePath[256];
new Handle:HostName = INVALID_HANDLE;
static		Handle:g_hHostNameFormat, Handle:g_hHostName, Handle:g_hMainName , String:g_sDefaultN[68];
public OnPluginStart()
{
	HostName = CreateKeyValues("AnneHappy");
	BuildPath(Path_SM, SavePath, 255, "configs/hostname/hostname.txt");
	if (FileExists(SavePath))
	{
		FileToKeyValues(HostName, SavePath);
	}
	g_hHostName	= FindConVar("hostname");
	g_hMainName = CreateConVar("sn_main_name", "");
	if(FindConVar("l4d_infected_limit"))
		cvarSI = FindConVar("l4d_infected_limit");
	cvarMpGameMin = FindConVar("versus_special_respawn_interval");
	cvarHostPort = FindConVar("hostport");
	g_hHostNameFormat = CreateConVar("sn_hostname_format", "{hostname}{gamemode}");
	cvarServerNameFormatCase1 = CreateConVar("sn_hostname_format1", "{AnneHappy}{Confogl}");
	if(FindConVar("l4d_ready_cfg_name"))
		cvarMpGameMode = FindConVar("l4d_ready_cfg_name");
	if(FindConVar("l4d_infected_limit"))
		HookConVarChange(cvarSI, OnCvarChanged);
	HookConVarChange(cvarMpGameMin, OnCvarChanged);
	if(FindConVar("l4d_ready_cfg_name"))
		HookConVarChange(cvarMpGameMode, OnCvarChanged);
	GetConVarString(g_hHostName, g_sDefaultN, sizeof(g_sDefaultN));
	if (strlen(g_sDefaultN))
		ChangeServerName();
}
public OnMapStart()
{
	HostName = CreateKeyValues("AnneHappy");
	BuildPath(Path_SM, SavePath, 255, "configs/hostname/hostname.txt");
	FileToKeyValues(HostName, SavePath);
}

public OnCvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	char sReadyUpCfgName[128], FinalHostname[128], buffer[128];
	bool IsAnne = false;
	GetConVarString(cvarServerNameFormatCase1, FinalHostname, sizeof(FinalHostname));
	GetConVarString(cvarMpGameMode, sReadyUpCfgName, sizeof(sReadyUpCfgName));	
	if(StrContains(sReadyUpCfgName, "AnneHappy", false)!=-1){
		ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}","[普通药役]");
		IsAnne = true;
	}	
	else if(StrContains(sReadyUpCfgName, "AllCharger", false)!=-1){
		ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}","[牛牛冲刺]");
		IsAnne = true;
	}	
	else if(StrContains(sReadyUpCfgName, "Hunters", false)!=-1)
		{ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}","[HT训练]");IsAnne = true;}
	else if(StrContains(sReadyUpCfgName, "WitchParty", false)!=-1)
		{ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}","[女巫派对]");IsAnne = true;}
	else if(StrContains(sReadyUpCfgName, "Alone", false)!=-1)
		{ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}","[单人装逼]");IsAnne = true;}
	else{
		if(FindConVar("l4d_ready_cfg_name")){
			GetConVarString(cvarMpGameMode, buffer, sizeof(buffer));
			Format(buffer, sizeof(buffer),"[%s]", buffer);
			ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}", buffer);
		}else{
			ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}","");
		}
	}
	if(FindConVar("l4d_infected_limit") && IsAnne){
		Format(buffer, sizeof(buffer),"[%d特%d秒]", GetConVarInt(cvarSI), GetConVarInt(cvarMpGameMin));
		ReplaceString(FinalHostname, sizeof(FinalHostname), "{AnneHappy}",buffer);
	}else{
		ReplaceString(FinalHostname, sizeof(FinalHostname), "{AnneHappy}","");
	}
		
	ChangeServerName(FinalHostname);
}
public OnAllPluginsLoaded()
{
	cvarMpGameMode = FindConVar("l4d_infected_limit");
	cvarMpGameMin = FindConVar("versus_special_respawn_interval");
	cvarMpGameMode = FindConVar("l4d_ready_cfg_name");
}
public OnConfigsExecuted()
{		
	if (!strlen(g_sDefaultN)) return;
		

	if (cvarMpGameMode == INVALID_HANDLE || cvarMpGameMin == INVALID_HANDLE)
	{
	
		ChangeServerName();
	}
	else 
	{
		char sReadyUpCfgName[128], FinalHostname[128], buffer[128];
		bool IsAnne = false;
		GetConVarString(cvarServerNameFormatCase1, FinalHostname, sizeof(FinalHostname));
		GetConVarString(cvarMpGameMode, sReadyUpCfgName, sizeof(sReadyUpCfgName));	
		if(StrContains(sReadyUpCfgName, "AnneHappy", false)!=-1){
			ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}","[普通药役]");
			IsAnne = true;
		}	
		else if(StrContains(sReadyUpCfgName, "AllCharger", false)!=-1){
			ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}","[牛牛冲刺]");
			IsAnne = true;
		}	
		else if(StrContains(sReadyUpCfgName, "Hunters", false)!=-1)
			{ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}","[HT训练]");IsAnne = true;}
		else if(StrContains(sReadyUpCfgName, "WitchParty", false)!=-1)
			{ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}","[女巫派对]");IsAnne = true;}
		else if(StrContains(sReadyUpCfgName, "Alone", false)!=-1)
			{ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}","[单人装逼]");IsAnne = true;}
		else{
			if(FindConVar("l4d_ready_cfg_name")){
				GetConVarString(cvarMpGameMode, buffer, sizeof(buffer));
				Format(buffer, sizeof(buffer),"[%s]", buffer);
				ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}", buffer);
			}else{
				ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}","");
			}
		}
		if(FindConVar("l4d_infected_limit") && IsAnne){
			Format(buffer, sizeof(buffer),"[%d特%d秒]", GetConVarInt(cvarSI), GetConVarInt(cvarMpGameMin));
			ReplaceString(FinalHostname, sizeof(FinalHostname), "{AnneHappy}",buffer);
		}else{
			ReplaceString(FinalHostname, sizeof(FinalHostname), "{AnneHappy}","");
		}
		ChangeServerName(FinalHostname);
	}
	
}
ChangeServerName(String:sReadyUpCfgName[] = "")
{
		char sPath[128], ServerPort[128];
		GetConVarString(cvarHostPort, ServerPort, sizeof(ServerPort));
		KvJumpToKey(HostName, ServerPort, false);
		KvGetString(HostName,"servername", sPath, sizeof(sPath));
		KvGoBack(HostName);
		char sNewName[128];
		if(strlen(sReadyUpCfgName) == 0)
		{
			Format(sNewName, sizeof(sNewName), "%s", g_hMainName);
		}
		else
		{
			GetConVarString(g_hHostNameFormat, sNewName, sizeof(sNewName));
			ReplaceString(sNewName, sizeof(sNewName), "{hostname}", sPath);
			ReplaceString(sNewName, sizeof(sNewName), "{gamemode}", sReadyUpCfgName);
		}
		SetConVarString(g_hHostName,sNewName);
		Format(g_sDefaultN,sizeof(g_sDefaultN),"%s",sNewName);
}