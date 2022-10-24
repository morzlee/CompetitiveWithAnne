#pragma semicolon 1
#pragma newdecls required
#define DEBUG 0
// 头文件
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#undef REQUIRE_PLUGIN
#include <ai_smoker_new>
#include <si_target_limit>
//#include <l4d2_saferoom_detect>

#define CVAR_FLAG FCVAR_NOTIFY
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
// 特感种类
#define ZC_SPITTER 4
#define ZC_TANK 8
// 数据
#define NAV_MESH_HEIGHT 20.0
#define PLAYER_HEIGHT 72.0
#define PLAYER_CHEST 45.0
#define GAMEDATA "anne_si_spawn"
// 启用特感类型
#define ENABLE_SMOKER			(1 << 0)		
#define ENABLE_BOOMER			(1 << 1)		
#define ENABLE_HUNTER			(1 << 2)		
#define ENABLE_SPITTER			(1 << 3)		
#define ENABLE_JOCKEY			(1 << 4)		
#define ENABLE_CHARGER			(1 << 5)		
#define ENABLE_TANK				(1 << 6)	

stock const char InfectedName[10][] =
{
	"common",
	"smoker",
	"boomer",
	"hunter",
	"spitter",
	"jockey",
	"charger",
	"witch",
	"tank",
	"survivor"
};


#if (DEBUG)
char sLogFile[PLATFORM_MAX_PATH] = "addons/sourcemod/logs/infected_control.txt";
#endif
// 插件基本信息，根据 GPL 许可证条款，需要修改插件请勿修改此信息！
public Plugin myinfo = 
{
	name 			= "Direct InfectedSpawn",
	author 			= "Caibiii, 夜羽真白，东",
	description 	= "特感刷新控制，传送落后特感",
	version 		= "2022.11.01",
	url 			= "https://github.com/Caibiii/AnneServer"
}

// Cvars
ConVar g_hSpawnDistanceMin, g_hSpawnDistanceMax, g_hTeleportSi, g_hTeleportDistance, g_hSiLimit, g_hSiInterval, g_hMaxPlayerZombies, g_hTeleportCheckTime, g_hEnableSIoption, g_hAllChargerMode, g_hAllHunterMode;
// Ints
int g_iSiLimit, iWaveTime, g_iEnableSIoption,
g_iTeleportCheckTime = 5, g_iTeleCount[MAXPLAYERS + 1] = {0}, g_iTargetSurvivor = -1, g_iSpawnMaxCount = 0, g_iSurvivorNum = 0, g_iSurvivors[MAXPLAYERS + 1] = {0};
int g_ArraySIlimit[6],  g_iQueueIndex = 0;
// ArraySpecial[6] = {0};
// Floats
float g_fSpawnDistanceMin, g_fSpawnDistanceMax, g_fSpawnDistance, g_fTeleportDistance, g_fSiInterval;
// Bools
bool g_bTeleportSi, g_bIsLate = false, g_bTargetSystemAvailable = false;
// Handle
Handle g_hTeleHandle = INVALID_HANDLE, g_hSDKIsVisibleToPlayer;
// ArrayList
ArrayList aThreadHandle, aSpawnQueue;


public void OnAllPluginsLoaded(){
	g_bTargetSystemAvailable = LibraryExists("si_target_limit");
}
public void OnLibraryAdded(const char[] name)
{
    if ( StrEqual(name, "si_target_limit") ) { g_bTargetSystemAvailable = true; }
}
public void OnLibraryRemoved(const char[] name)
{
    if ( StrEqual(name, "si_target_limit") ) { g_bTargetSystemAvailable = false; }
}
public void OnPluginStart()
{
	Init();
	// CreateConVar
	g_hSpawnDistanceMin = CreateConVar("inf_SpawnDistanceMin", "250.0", "特感复活离生还者最近的距离限制", CVAR_FLAG, true, 0.0);
	g_hSpawnDistanceMax = CreateConVar("inf_SpawnDistanceMax", "1500.0", "特感复活离生还者最远的距离限制", CVAR_FLAG, true, g_hSpawnDistanceMin.FloatValue);
	g_hTeleportSi = CreateConVar("inf_TeleportSi", "1", "是否开启特感距离生还者一定距离将其传送至生还者周围", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hTeleportCheckTime = CreateConVar("inf_TeleportCheckTime", "5", "特感几秒后没被看到开始传送", CVAR_FLAG, true, 0.0);
	g_hEnableSIoption = CreateConVar("inf_EnableSIoption", "63", "启用生成的特感类型，1 smoker 2 boomer 4 hunter 8 spitter 16 jockey 32 charger,把你想要生成的特感值加起来", CVAR_FLAG, true, 0.0, true, 63.0);
	g_hAllChargerMode = CreateConVar("inf_AllChargerMode", "0", "是否是全牛模式", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hAllHunterMode = CreateConVar("inf_AllHunterMode", "0", "是否是全猎人模式", CVAR_FLAG, true, 0.0, true, 1.0);
	//传送会根据这个数值画一个以选定生还者为核心，两边各长inf_TeleportDistance单位距离，高inf_TeleportDistance距离的长方形区域内找复活位置,PS传送最好近一点
	g_hTeleportDistance = CreateConVar("inf_TeleportDistance", "600.0", "特感传送区域的复活大小", CVAR_FLAG, true, g_hSpawnDistanceMin.FloatValue);
	g_hSiLimit = CreateConVar("l4d_infected_limit", "6", "一次刷出多少特感", CVAR_FLAG, true, 0.0);
	g_hSiInterval = CreateConVar("versus_special_respawn_interval", "16.0", "对抗模式下刷特时间控制", CVAR_FLAG, true, 0.0);
	g_hMaxPlayerZombies = FindConVar("z_max_player_zombies");
	SetConVarInt(FindConVar("director_no_specials"), 1);
	// HookEvents
	HookEvent("player_death", evt_PlayerDeath, EventHookMode_PostNoCopy);
	HookEvent("round_start", evt_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("finale_win", evt_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("map_transition", evt_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("mission_lost", evt_RoundEnd, EventHookMode_PostNoCopy);
	// AddChangeHook
	g_hSpawnDistanceMax.AddChangeHook(ConVarChanged_Cvars);
	g_hSpawnDistanceMin.AddChangeHook(ConVarChanged_Cvars);
	g_hTeleportSi.AddChangeHook(ConVarChanged_Cvars);
	g_hTeleportCheckTime.AddChangeHook(ConVarChanged_Cvars);
	g_hTeleportDistance.AddChangeHook(ConVarChanged_Cvars);
	g_hSiInterval.AddChangeHook(ConVarChanged_Cvars);
	g_hEnableSIoption.AddChangeHook(ConVarChanged_Cvars);
	g_hAllChargerMode.AddChangeHook(ConVarChanged_Cvars);
	g_hAllHunterMode.AddChangeHook(ConVarChanged_Cvars);
	g_hSiLimit.AddChangeHook(MaxPlayerZombiesChanged_Cvars);
	
	// ArrayList
	aThreadHandle = new ArrayList();
	aSpawnQueue = new ArrayList();
	// GetCvars
	GetCvars();
	GetSiLimit();
	// SetConVarBonus
	SetConVarBounds(g_hMaxPlayerZombies, ConVarBound_Upper, true, g_hSiLimit.FloatValue);
	// Debug
	RegAdminCmd("sm_startspawn", Cmd_StartSpawn, ADMFLAG_ROOT, "管理员重置刷特时钟");

}

void Init()
{
	GameData hGameData = new GameData(GAMEDATA);
	if (hGameData == null)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);


	// IsVisibleToPlayer(Vector const&, CBasePlayer *, int, int, float, CBaseEntity const*, TerrorNavArea **, bool *);
	// SDKCall(g_hSDKIsVisibleToPlayer, fTargetPos, i, 2, 3, 0.0, 0, pArea, true);
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "IsVisibleToPlayer"))
		SetFailState("Failed to find signature: IsVisibleToPlayer");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);									// 目标点位
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);								// 客户端
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);								// 客户端团队
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);								// 目标点位团队, 如果为0将考虑客户端的角度
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);										// 不清楚
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);								// 不清楚
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer);							// 目标点位 NavArea 区域
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Pointer);									// 如果为 false，将自动获取目标点位的 NavArea (GetNearestNavArea)
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_hSDKIsVisibleToPlayer = EndPrepSDKCall();
	if (g_hSDKIsVisibleToPlayer == null)
		SetFailState("Failed to create SDKCall: IsVisibleToPlayer");

	delete hGameData;
}

public void OnPluginEnd() {
	if(g_hAllChargerMode.BoolValue){
		FindConVar("z_charger_health").RestoreDefault();
		FindConVar("z_charge_max_speed").RestoreDefault();
		FindConVar("z_charge_start_speed").RestoreDefault();
		FindConVar("z_charger_pound_dmg").RestoreDefault();
		FindConVar("z_charge_max_damage").RestoreDefault();
		FindConVar("z_charge_interval").RestoreDefault();
	}
}

void TweakSettings() {
	if(g_hAllChargerMode.BoolValue){
		FindConVar("z_charger_health").SetFloat(500.0);
		FindConVar("z_charge_max_speed").SetFloat(750.0);
		FindConVar("z_charge_start_speed").SetFloat(350.0);
		FindConVar("z_charger_pound_dmg").SetFloat(10.0);
		FindConVar("z_charge_max_damage").SetFloat(6.0);
		FindConVar("z_charge_interval").SetFloat(2.0);
	}
}

// 向量绘制
// #include "vector/vector_show.sp"

stock Action Cmd_StartSpawn(int client, int args)
{
	if (L4D_HasAnySurvivorLeftSafeArea())
	{
		CreateTimer(0.1, SpawnFirstInfected);
		GetSiLimit();
	}
	return Plugin_Continue;
}

// *********************
//		获取Cvar值
// *********************
void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void MaxPlayerZombiesChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSiLimit = g_hSiLimit.IntValue;
	CreateTimer(0.1, MaxSpecialsSet);
}

void GetCvars()
{
	g_fSpawnDistanceMax = g_hSpawnDistanceMax.FloatValue;
	g_fSpawnDistanceMin = g_hSpawnDistanceMin.FloatValue;
	g_bTeleportSi = g_hTeleportSi.BoolValue;
	g_fTeleportDistance = g_hTeleportDistance.FloatValue;
	g_fSiInterval = g_hSiInterval.FloatValue;
	g_iSiLimit = g_hSiLimit.IntValue;
	g_iTeleportCheckTime = g_hTeleportCheckTime.IntValue;
	g_iEnableSIoption = g_hEnableSIoption.IntValue;
	if(g_hAllChargerMode.BoolValue){
		TweakSettings();
	}
}

public Action MaxSpecialsSet(Handle timer)
{
	SetConVarBounds(g_hMaxPlayerZombies, ConVarBound_Upper, true, g_hSiLimit.FloatValue);
	g_hMaxPlayerZombies.IntValue = g_iSiLimit;
	return Plugin_Continue;
}

// *********************
//		    事件
// *********************
public void evt_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (g_hTeleHandle != INVALID_HANDLE)
	{
		delete g_hTeleHandle;
		g_hTeleHandle = INVALID_HANDLE;
	}
	g_bIsLate = false;
	g_iSpawnMaxCount = 0;
	for (int hTimerHandle = aThreadHandle.Length - 1; hTimerHandle >= 0; hTimerHandle--)
	{
		KillTimer(aThreadHandle.Get(hTimerHandle));
		aThreadHandle.Erase(hTimerHandle);
	}
	aThreadHandle.Clear();
	aSpawnQueue.Resize(1);
	g_iQueueIndex = 0;
	iWaveTime=0;
	CreateTimer(0.1, MaxSpecialsSet);
	CreateTimer(3.0, SafeRoomReset, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void evt_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (g_hTeleHandle != INVALID_HANDLE)
	{
		delete g_hTeleHandle;
		g_hTeleHandle = INVALID_HANDLE;
	}
	g_bIsLate = false;
	g_iSpawnMaxCount = 0;
	// 从 ArrayList 末端往前判断删除时钟，如果从前往后，因为 ArrayList 会通过前移后面的索引来填补前面擦除的空位，导致有时钟句柄无法擦除
	for (int hTimerHandle = aThreadHandle.Length - 1; hTimerHandle >= 0; hTimerHandle--)
	{
		KillTimer(aThreadHandle.Get(hTimerHandle));
		aThreadHandle.Erase(hTimerHandle);
	}
	aThreadHandle.Clear();
	aSpawnQueue.Resize(1);
	g_iQueueIndex = 0;
}

public void evt_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsInfectedBot(client))
	{
		if (GetEntProp(client, Prop_Send, "m_zombieClass") != ZC_SPITTER)
		{
			CreateTimer(0.5, Timer_KickBot, client);
		}
	}
	g_iTeleCount[client] = 0;
}

public Action Timer_KickBot(Handle timer, int client)
{
	if (IsClientInGame(client) && !IsClientInKickQueue(client) && IsFakeClient(client))
	{
		Debug_Print("踢出特感%N",client);
		KickClient(client, "You are worthless and was kicked by console");
	}
	return Plugin_Continue;
}

// *********************
//		  功能部分
// *********************
public void OnGameFrame()
{
	// 根据情况动态调整 z_maxplayers_zombie 数值
	if (g_iSiLimit > g_hMaxPlayerZombies.IntValue)
	{
		CreateTimer(0.1, MaxSpecialsSet);
	}
	if (g_iQueueIndex < g_iSiLimit)
	{
		int zombieclass = 0;
		if (aSpawnQueue.Length < g_iSiLimit)
		{
			zombieclass = IsBotTypeNeeded();
		}
		if (zombieclass != 0 && g_ArraySIlimit[zombieclass - 1] > 0 && !HasReachedLimit(zombieclass) && g_iQueueIndex < g_iSiLimit)
		{
			//这里增加一些boomer和spitter生成的判定，让bommer和spitter比较晚生成
			aSpawnQueue.Push(g_iQueueIndex);
			aSpawnQueue.Set(g_iQueueIndex, zombieclass, 0, false);
			g_ArraySIlimit[zombieclass - 1] -= 1;
			g_iQueueIndex += 1;
			Debug_Print("[Infected-Spawn]：当前入队元素：%d，当前队列长度：%d，当前队列索引位置：%d", zombieclass, aSpawnQueue.Length, g_iQueueIndex);
		}
	}
	if (g_bIsLate && g_iSpawnMaxCount > 0)
	{
		if (g_iSiLimit > HasAnyCountFull())
		{		
			float fSpawnPos[3] = {0.0}, fSurvivorPos[3] = {0.0}, fDirection[3] = {0.0}, fEndPos[3] = {0.0}, fMins[3] = {0.0}, fMaxs[3] = {0.0};	
			if (IsValidSurvivor(g_iTargetSurvivor))
			{
				// 根据指定生还者坐标，拓展刷新范围
				GetClientEyePosition(g_iTargetSurvivor, fSurvivorPos);
				if(g_fSpawnDistance < g_fSpawnDistanceMax)
					g_fSpawnDistance += 5.0;
				//增加高度，增加刷房顶的几率
				if(g_fSpawnDistance < 500.0)
				{
					fMaxs[2] = fSurvivorPos[2] + 800.0;
				}
				else
				{
					fMaxs[2] = fSurvivorPos[2] + g_fSpawnDistance + 300.0;
				}
				fMins[0] = fSurvivorPos[0] - g_fSpawnDistance;
				fMaxs[0] = fSurvivorPos[0] + g_fSpawnDistance;
				fMins[1] = fSurvivorPos[1] - g_fSpawnDistance;
				fMaxs[1] = fSurvivorPos[1] + g_fSpawnDistance;
//				fMaxs[2] = fSurvivorPos[2] + g_fSpawnDistance;
				// 规定射线方向
				fDirection[0] = 90.0;
				fDirection[1] = fDirection[2] = 0.0;
				// 随机刷新位置
				fSpawnPos[0] = GetRandomFloat(fMins[0], fMaxs[0]);
				fSpawnPos[1] = GetRandomFloat(fMins[1], fMaxs[1]);
				fSpawnPos[2] = GetRandomFloat(fSurvivorPos[2], fMaxs[2]);
				// 找位条件，可视，是否在有效 NavMesh，是否卡住，否则先会判断是否在有效 Mesh 与是否卡住导致某些位置刷不出特感
				int count2=0;
				while (PlayerVisibleToSDK(fSpawnPos) || !IsOnValidMesh(fSpawnPos) || IsPlayerStuck(fSpawnPos))
				{
					count2++;
					if(count2 > 20)
					{
						break;
					}
					fSpawnPos[0] = GetRandomFloat(fMins[0], fMaxs[0]);
					fSpawnPos[1] = GetRandomFloat(fMins[1], fMaxs[1]);
					fSpawnPos[2] = GetRandomFloat(fSurvivorPos[2], fMaxs[2]);
					TR_TraceRay(fSpawnPos, fDirection, MASK_PLAYERSOLID, RayType_Infinite);
					if(TR_DidHit())
					{
						TR_GetEndPosition(fEndPos);
						fSpawnPos = fEndPos;
						fSpawnPos[2] += NAV_MESH_HEIGHT;
					}
				}
				if (count2 <= 20)
				{
					int sum =0;
					//Debug_Print("生还者看不到");
					// 生还数量为 4，循环 4 次，检测此位置到生还的距离是否小于 750 是则刷特，此处可以刷新 1 ~ g_iSiLimit 只特感，如果此处刷完，则上面的 SpawnSpecial 将不再刷特
					for (int count = 0; count < g_iSurvivorNum; count++)
					{
						int index = g_iSurvivors[count];
						//不是有效生还者不生成
						if(!IsValidSurvivor(index))
							continue;	
						
						//生还者倒地或者挂边，也不生成
						if(IsClientIncapped(index)){
							sum++;
							//如果全部人都倒了，直接返回
							if(sum == g_iSurvivorNum){
								return;
							}
							continue;	
						}
						
							
						GetClientEyePosition(index, fSurvivorPos);
						fSurvivorPos[2] -= 60.0;
						//获取nav地址
						Address nav1 = L4D_GetNearestNavArea(fSpawnPos, 120.0, false, false, false, TEAM_INFECTED);
						Address nav2 = L4D_GetNearestNavArea(fSurvivorPos, 120.0, false, false, false, TEAM_INFECTED);
						//nav1 和 nav2 必须有网格相连的路，并且生成距离大于g_fSpawnDistanceMin，增加不能是通nav网格的要求
						if (L4D2_NavAreaBuildPath(nav1, nav2, g_fSpawnDistance * 1.73, TEAM_INFECTED, false) && GetVectorDistance(fSurvivorPos, fSpawnPos) >= g_fSpawnDistanceMin && nav1 != nav2)
						{
							int iZombieClass = aSpawnQueue.Get(0);
							if (iZombieClass > 0 && g_iSpawnMaxCount > 0 && !HasReachedLimit(iZombieClass))
							{
								int entityindex = L4D2_SpawnSpecial(iZombieClass, fSpawnPos, view_as<float>({0.0, 0.0, 0.0}));
								if (IsValidEntity(entityindex) && IsValidEdict(entityindex))
								{
									g_iSpawnMaxCount -= 1;
									if (aSpawnQueue.Length > 0 && g_iQueueIndex > 0)
									{
										aSpawnQueue.Erase(0);
										g_iQueueIndex -= 1;
									}
									print_type(iZombieClass, g_fSpawnDistance);
								}
							}								
							else if (HasReachedLimit(iZombieClass))
							{
								ReachedLimit();
							}
							if (g_iSpawnMaxCount <= 0)
							{
								g_iSpawnMaxCount = 0;
								aSpawnQueue.Resize(1);
								g_iQueueIndex = 0;
								GetSiLimit();
							}
						}
					}
				}			
			}			
		}
	}
}

// 当前在场的某种特感种类数量达到 Cvar 限制，但因为刷新一个特感，出队此元素，之后再入队相同特感元素，则会刷不出来，需要处理重复情况，如果队列长度大于 1 且索引大于 0，说明队列存在
// 首非零元，直接擦除队首元素并令队列索引 -1 即可，时间复杂度为 O(1)，如果队列中只有一个元素，则循环 1-6 的特感种类替换此元素（一般不会出现），时间复杂度为 O(n)
// 如：当前存在 2 个 Smoker 未死亡，Smoker 的 Cvar 限制为 2 ，这时入队一个 Smoker 元素，则会导致无法刷出特感
void ReachedLimit()
{
	if (aSpawnQueue.Length > 1 && g_iQueueIndex > 0)
	{
		aSpawnQueue.Erase(0);
		g_iQueueIndex -= 1;
	}
	else
	{
		for (int i = 1; i <= 6; i++)
		{
			if (!HasReachedLimit(i))
			{
				aSpawnQueue.Set(0, i, 0, false);
			}
		}
	}
}


// 当前某种特感数量是否达到 Convar 值限制
bool HasReachedLimit(int zombieclass)
{
	if(g_hAllChargerMode.BoolValue || g_hAllHunterMode.BoolValue){
		return false;
	}
	int count = 0;	char convar[16] = {'\0'};
	for (int infected = 1; infected <= MaxClients; infected++)
	{
		if (IsClientConnected(infected) && IsClientInGame(infected) && GetEntProp(infected, Prop_Send, "m_zombieClass") == zombieclass)
		{
			count += 1;
		}
	}
	FormatEx(convar, sizeof(convar), "z_%s_limit", InfectedName[zombieclass]);
	if (count == GetConVarInt(FindConVar(convar)))
	{
		return true;
	}
	else
	{
		return false;
	}
}

stock void ResetInfectedNumber(){
	int iSIlimit[6];
	for (int infected = 0; infected < MaxClients; infected++)
	{
		if (IsInfectedBot(infected) && (IsPlayerAlive(infected)||IsGhost(infected)))
		{
			int iZombieClass = GetEntProp(infected, Prop_Send, "m_zombieClass");
			switch (iZombieClass)
			{
				case 1:
				{
					iSIlimit[iZombieClass-1]++;
				}
				case 2:
				{
					iSIlimit[iZombieClass-1]++;
				}
				case 3:
				{
					iSIlimit[iZombieClass-1]++;
				}
				case 4:
				{
					iSIlimit[iZombieClass-1]++;
				}
				case 5:
				{
					iSIlimit[iZombieClass-1]++;
				}
				case 6:
				{
					iSIlimit[iZombieClass-1]++;
				}
			}
		}
	}
	for(int i = 0; i < 6; i++){
		g_ArraySIlimit[i] = iSIlimit[i];
	}
}

stock void print_type(int iType,float SpawnDistance){
	char sTime[32];
	FormatTime(sTime, sizeof(sTime), "%I-%M-%S", GetTime()); 
	int iBoomers = 0, iSmokers = 0, iHunters = 0, iSpitters = 0, iJockeys = 0, iChargers = 0;
	for (int infected = 0; infected < MaxClients; infected++)
	{
		if (IsInfectedBot(infected) && IsPlayerAlive(infected)||IsGhost(infected))
		{
			int iZombieClass = GetEntProp(infected, Prop_Send, "m_zombieClass");
			switch (iZombieClass)
			{
				case 1:
				{
					iSmokers++;
				}
				case 2:
				{
					iBoomers++;
				}
				case 3:
				{
					iHunters++;
				}
				case 4:
				{
					iSpitters++;
				}
				case 5:
				{
					iJockeys++;
				}
				case 6:
				{
					iChargers++;
				}
			}
		}
	}
	if (iType == 1)
	{
			Debug_Print("%s:生成一只Smoker，当前Smoker数量：%d,特感总数量 %d,找位最大单位距离：%f",sTime,iSmokers,iSmokers+iBoomers+iHunters+iSpitters+iJockeys+iChargers, SpawnDistance);
	}
	else if (iType == 2)
	{
			Debug_Print("%s:生成一只Boomer，当前Boomer数量：%d,特感总数量 %d, 找位最大单位距离：%f",sTime,iBoomers,iSmokers+iBoomers+iHunters+iSpitters+iJockeys+iChargers, SpawnDistance);
	}
	else if (iType == 3)
	{
			Debug_Print("%s:生成一只Hunter，当前Hunter数量：%d,特感总数量 %d, 找位最大单位距离：%f",sTime,iHunters,iSmokers+iBoomers+iHunters+iSpitters+iJockeys+iChargers, SpawnDistance);
	}
	else if (iType == 4)
	{
			Debug_Print("%s:生成一只Spitter，当前Spitter数量：%d,特感总数量 %d, 找位最大单位距离：%f",sTime,iSpitters,iSmokers+iBoomers+iHunters+iSpitters+iJockeys+iChargers, SpawnDistance);
	}
	else if (iType == 5)
	{
			Debug_Print("%s:生成一只Jockey，当前Jockey数量：%d,特感总数量 %d, 找位最大单位距离：%f",sTime,iJockeys,iSmokers+iBoomers+iHunters+iSpitters+iJockeys+iChargers, SpawnDistance);
	}
	else if (iType == 6)
	{
			Debug_Print("%s:生成一只Charger，当前Charger数量：%d,特感总数量 %d, 找位最大单位距离：%f",sTime,iChargers,iSmokers+iBoomers+iHunters+iSpitters+iJockeys+iChargers, SpawnDistance);
	}

}

// 初始 & 动态刷特时钟
public Action SpawnFirstInfected(Handle timer)
{
	if (!g_bIsLate)
	{
		g_bIsLate = true;
		if (g_hSiInterval.FloatValue > 9.0)
		{
			Handle aSpawnTimer = CreateTimer(g_fSiInterval + 8.0, SpawnNewInfected, _, TIMER_REPEAT);
			aThreadHandle.Push(aSpawnTimer);
			TriggerTimer(aSpawnTimer, true);
		}
		else
		{
			Handle aSpawnTimer = CreateTimer(g_fSiInterval + 4.0, SpawnNewInfected, _, TIMER_REPEAT);
			aThreadHandle.Push(aSpawnTimer);
			TriggerTimer(aSpawnTimer, true);
		}
		if (g_bTeleportSi)
		{
			g_hTeleHandle = CreateTimer(1.0, Timer_PositionSi, _, TIMER_REPEAT);
		}
	}
	return Plugin_Continue;
}


public Action SpawnNewInfected(Handle timer)
{
	char sTime[32];
	FormatTime(sTime, sizeof(sTime), "%I-%M-%S", GetTime()); 
	g_iSurvivorNum = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidSurvivor(client) && IsPlayerAlive(client))
		{
			g_iSurvivors[g_iSurvivorNum] = client;
			g_iSurvivorNum += 1;
		}
	}
	if (g_bIsLate)
	{
		if (g_iSiLimit > aThreadHandle.Length)
		{
			if (g_hSiInterval.FloatValue > 9.0)
			{
				Handle aSpawnTimer = CreateTimer(g_fSiInterval + 8.0, SpawnNewInfected, _, TIMER_REPEAT);
				aThreadHandle.Push(aSpawnTimer);
				TriggerTimer(aSpawnTimer, true);
			}
			else
			{
				Handle aSpawnTimer = CreateTimer(g_fSiInterval + 4.0, SpawnNewInfected, _, TIMER_REPEAT);
				aThreadHandle.Push(aSpawnTimer);
				TriggerTimer(aSpawnTimer, true);
			}
		}
		// 其实这个删除没什么用，因为当 aThreadHandle.Length = g_iSiLimit 时，多出来的句柄将不会存入数组
		else if (g_iSiLimit < aThreadHandle.Length)
		{
			for (int iTimerIndex = 0; iTimerIndex < aThreadHandle.Length; iTimerIndex++)
			{
				if (timer == aThreadHandle.Get(iTimerIndex))
				{
					aThreadHandle.Erase(iTimerIndex);
					return Plugin_Stop;
				}
			}
		}
		g_fSpawnDistance = g_fSpawnDistanceMin;
		//ResetInfectedNumber();

		g_iSpawnMaxCount += 1;
		if (g_iSiLimit == g_iSpawnMaxCount){
			iWaveTime++;
			Debug_Print("%s:开始第%d波刷特",sTime,iWaveTime);
		}
			
		// 当一定时间内刷不出特感，触发时钟使 g_iSpawnMaxCount 超过 g_iSiLimit 值时，最多允许刷出 g_iSiLimit + 2 只特感，防止连续刷 2-3 波的情况
		if (g_iSiLimit < g_iSpawnMaxCount)
		{

			g_iSpawnMaxCount = g_iSiLimit;
			
			Debug_Print("当前特感数量达到上限");
		}

	}
	return Plugin_Continue;
}

// 开局重置特感状态
public Action SafeRoomReset(Handle timer)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsInfectedBot(client) && IsPlayerAlive(client))
		{
			g_iTeleCount[client] = 0;
		}
		if (IsValidSurvivor(client) && !IsPlayerAlive(client))
		{
			L4D_RespawnPlayer(client);
		}
	}
	return Plugin_Continue;
}

// *********************
//		   方法
// *********************
bool IsInfectedBot(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) == TEAM_INFECTED)
	{
		return true;
	}
	else
	{
		return false;
	}
}

bool IsValidSurvivor(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR)
	{
		return true;
	}
	else
	{
		return false;
	}
}

bool IsOnValidMesh(float fReferencePos[3])
{
	Address pNavArea = L4D2Direct_GetTerrorNavArea(fReferencePos);
	if (pNavArea != Address_Null)
	{
		return true;
	}
	else
	{
		return false;
	}
}

//判断该坐标是否可以看到生还或者距离小于g_fSpawnDistanceMin码，减少一层栈函数，增加实时性,单人模式增加2条射线模仿左右眼
stock bool PlayerVisibleTo(float targetposition[3], bool IsTeleport = false)
{
	float position[3], vAngles[3], vLookAt[3], spawnPos[3];
	for (int client = 1; client <= MaxClients; ++client)
	{
		if (IsClientConnected(client) && IsClientInGame(client) && IsValidSurvivor(client) && IsPlayerAlive(client))
		{
			//传送的时候无视倒地或者挂边生还者得实现
			if(IsTeleport && IsClientIncapped(client)){
				int sum = 0;
				float temp[3];
				for(int i = 0; i < MaxClients; i++){
					if(i != client && IsValidSurvivor(i) && !IsClientIncapped(i)){
						GetClientAbsOrigin(i, temp);
						//倒地生还者500范围内已经没有正常生还者，掠过这个人的视线判断
						if(GetVectorDistance(temp, position) < 500.0){
							sum ++;
						}
					}
				}			
				if(sum == 0){
					Debug_Print("Teleport方法，目标位置已经不能被正常生还者所看到");
					continue;
				}else{
					Debug_Print("Teleport方法，目标位置依旧能被正常生还者看到，sum为：%d", sum);
				}			
			}
			GetClientEyePosition(client, position);
			//position[0] += 20;
			if(GetVectorDistance(targetposition, position) < g_fSpawnDistanceMin)
			{
				return true;
			}
			MakeVectorFromPoints(targetposition, position, vLookAt);
			GetVectorAngles(vLookAt, vAngles);
			Handle trace = TR_TraceRayFilterEx(targetposition, vAngles, MASK_VISIBLE, RayType_Infinite, TraceFilter, client);
			if(TR_DidHit(trace))
			{
				static float vStart[3];
				TR_GetEndPosition(vStart, trace);
				if((GetVectorDistance(targetposition, vStart, false) + 75.0) >= GetVectorDistance(position, targetposition))
				{
					return true;
				}
				else
				{
					spawnPos = targetposition;
					spawnPos[2] += 40.0;
					MakeVectorFromPoints(spawnPos, position, vLookAt);
					GetVectorAngles(vLookAt, vAngles);
					Handle trace2 = TR_TraceRayFilterEx(spawnPos, vAngles, MASK_VISIBLE, RayType_Infinite, TraceFilter, client);
					if(TR_DidHit(trace2))
					{
						TR_GetEndPosition(vStart, trace2);
						if((GetVectorDistance(spawnPos, vStart, false) + 75.0) >= GetVectorDistance(position, spawnPos))
							return  true;
					}
					else
					{
						return true;
					}
					delete trace2;
				}
			}
			else
			{
				return true;
			}
			delete trace;
		}
	}
	return false;
}

//thanks fdxx https://github.com/fdxx/l4d2_plugins/blob/main/l4d2_si_spawn_control.sp
stock bool PlayerVisibleToSDK(float targetposition[3], bool IsTeleport = false){
	static float fTargetPos[3];

	float position[3];
	fTargetPos = targetposition;
	fTargetPos[2] += 62.0; //眼睛位置
	Address pArea = L4D_GetNearestNavArea(targetposition, 120.0, false, false, false, 3);

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			GetClientEyePosition(client, position);
			//传送的时候无视倒地或者挂边生还者得实现
			if(IsTeleport && IsClientIncapped(client)){
				int sum = 0;
				float temp[3];
				for(int i = 1; i <= MaxClients; i++){
					if(i != client && IsValidSurvivor(i) && !IsClientIncapped(i)){
						GetClientAbsOrigin(i, temp);
						//倒地生还者500范围内已经没有正常生还者，掠过这个人的视线判断
						if(GetVectorDistance(temp, position) < 500.0){
							sum ++;
						}
					}
				}			
				if(sum == 0){
					Debug_Print("Teleport方法，目标位置已经不能被正常生还者所看到");
					continue;
				}else{
					Debug_Print("Teleport方法，目标位置依旧能被正常生还者看到，sum为：%d", sum);
				}			
			}
			//太近直接返回看见
			if(GetVectorDistance(targetposition, position) < g_fSpawnDistanceMin)
			{
				return true;
			}
			//太远直接返回没看见
			if(GetVectorDistance(targetposition, position) >= g_fSpawnDistanceMax)
			{
				return false;
			}
			if (SDKCall(g_hSDKIsVisibleToPlayer, targetposition, client, 2, 3, 0.0, 0, pArea, true))
			{
				return true;
			}
			if (SDKCall(g_hSDKIsVisibleToPlayer, fTargetPos, client, 2, 3, 0.0, 0, pArea, true))
			{
				return true;
			}
		}
	}

	return false;
}

// 判断玩家是否倒地，倒地返回 true，未倒地返回 false
stock bool IsClientIncapped(int client)
{
	if (IsValidClient(client))
	{
		return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
	}
	else
	{
		return false;
	}
}

bool IsPlayerStuck(float fSpawnPos[3])
{
	//似乎所有客户端的尺寸都一样
	static const float fClientMinSize[3] = {-16.0, -16.0, 0.0};
	static const float fClientMaxSize[3] = {16.0, 16.0, 72.0};

	static bool bHit;
	static Handle hTrace;

	hTrace = TR_TraceHullFilterEx(fSpawnPos, fSpawnPos, fClientMinSize, fClientMaxSize, MASK_PLAYERSOLID, TraceFilter_Stuck);
	bHit = TR_DidHit(hTrace);

	delete hTrace;
	return bHit;
}

stock bool TraceFilter_Stuck(int entity, int contentsMask)
{
	if (entity <= MaxClients || !IsValidEntity(entity))
	{
		return false;
	}
	else{
		static char sClassName[20];
		GetEntityClassname(entity, sClassName, sizeof(sClassName));
		if (strcmp(sClassName, "env_physics_blocker") == 0 && !EnvBlockType(entity)){
			return false;
		}
	}
	return true;
}

stock bool EnvBlockType(int entity){
	int BlockType = GetEntProp(entity, Prop_Data, "m_nBlockType");
	//阻拦ai infected
	if(BlockType == 1 || BlockType == 2){
		return false;
	}
	else{
		return true;
	}
}

stock bool TraceFilter(int entity, int contentsMask)
{
	if (entity <= MaxClients || !IsValidEntity(entity))
	{
		return false;
	}
	else
	{
		static char sClassName[9];
		GetEntityClassname(entity, sClassName, sizeof(sClassName));
		if (strcmp(sClassName, "infected") == 0 || strcmp(sClassName, "witch") == 0)
		{
			return false;
		}
	}
	return true;
}

bool IsPinned(int client)
{
	bool bIsPinned = false;
	if (IsValidSurvivor(client) && IsPlayerAlive(client))
	{
		if(GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0) bIsPinned = true;
		if(GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0) bIsPinned = true;
		if(GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0) bIsPinned = true;
		if(GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0) bIsPinned = true;
		if(GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0) bIsPinned = true;
	}		
	return bIsPinned;
}

bool IsPinningSomeone(int client)
{
	bool bIsPinning = false;
	if (IsInfectedBot(client))
	{
		if (GetEntPropEnt(client, Prop_Send, "m_tongueVictim") > 0) bIsPinning = true;
		if (GetEntPropEnt(client, Prop_Send, "m_jockeyVictim") > 0) bIsPinning = true;
		if (GetEntPropEnt(client, Prop_Send, "m_pounceVictim") > 0) bIsPinning = true;
		if (GetEntPropEnt(client, Prop_Send, "m_pummelVictim") > 0) bIsPinning = true;
		if (GetEntPropEnt(client, Prop_Send, "m_carryVictim") > 0) bIsPinning = true;
	}
	return bIsPinning;
}

bool CanBeTeleport(int client)
{
	if (IsInfectedBot(client) && IsClientInGame(client)&& IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_zombieClass") != ZC_TANK)
	{
		return true;
	}
	else
	{
		return false;
	}
}

//5秒内以1s检测一次，5次没被看到，就可以传送了
public Action Timer_PositionSi(Handle timer)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if(CanBeTeleport(client)){
			float fSelfPos[3] = {0.0};
			GetClientEyePosition(client, fSelfPos);
			if (!PlayerVisibleToSDK(fSelfPos, true))
			{
				if (g_iTeleCount[client] > g_iTeleportCheckTime)
				{
					Debug_Print("%N开始传送",client);
					if (!PlayerVisibleToSDK(fSelfPos, true))
					{
						SDKHook(client, SDKHook_PostThinkPost, SDK_UpdateThink);
						g_iTeleCount[client] = 0;
					}
				}
				g_iTeleCount[client] += 1;
			}
			else{
				g_iTeleCount[client] = 0;
			}
		}
		
	}
	return Plugin_Continue;
}

bool IsSpitter(int client)
{
	if (IsInfectedBot(client) && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_SPITTER)
	{
		g_iTeleCount[client] = 50;//给予spitter立即传送的权限
		return true;
	}
	else
	{
		return false;
	}
}


int HasAnyCountFull()
{
	int iInfectedCount = 0, iSurvivors[8] = {0}, iSurvivorIndex = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsInfectedBot(client) && IsPlayerAlive(client))
		{
			int iZombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");
			if (iZombieClass <= 6)
			{
				iInfectedCount += 1;
			}
		}
		if (IsValidSurvivor(client) && IsPlayerAlive(client) && (!IsPinned(client) || !IsClientIncapped(client)))
		{
			if(g_bTargetSystemAvailable && IsClientReachLimit(client))
			{
				//Debug_Print("玩家%N 目标已满，跳过", client);
				continue;
			}
			g_bIsLate = true;
			if (iSurvivorIndex < 8)
			{
				iSurvivors[iSurvivorIndex] = client;
				iSurvivorIndex += 1;
			}
		}
	}
	if (iSurvivorIndex > 0)
	{
		g_iTargetSurvivor = iSurvivors[GetRandomInt(0, iSurvivorIndex - 1)];
	}
	else
	{
		g_iTargetSurvivor = L4D_GetHighestFlowSurvivor();
	}
	return iInfectedCount;
}


// 传送落后特感
public void SDK_UpdateThink(int client)
{
	if (IsInfectedBot(client) && IsPlayerAlive(client))
	{
		if(IsAiSmoker(client) && !IsSmokerCanUseAbility(client))
		{
			//减去拉失败时间,方便smoker最快开始检测传送
			if(g_hTeleportCheckTime.IntValue - FindConVar("tongue_miss_delay").IntValue >=0)
			{
				g_iTeleCount[client] = g_hTeleportCheckTime.IntValue - 3;
			}
			else
			{
				g_iTeleCount[client] = 0;
			}
			SDKUnhook(client, SDKHook_PostThinkPost, SDK_UpdateThink);
			return;
		}
		g_iTeleCount[client] = 0;
		HardTeleMode(client);
			
	}
}




void HardTeleMode(int client)
{
	static float fEyePos[3] = {0.0}, fSelfEyePos[3] = {0.0};
	GetClientEyePosition(client, fEyePos);
	if (!PlayerVisibleToSDK(fEyePos) && !IsPinningSomeone(client))
	{
		float fSpawnPos[3] = {0.0}, fSurvivorPos[3] = {0.0}, fDirection[3] = {0.0}, fEndPos[3] = {0.0}, fMins[3] = {0.0}, fMaxs[3] = {0.0};
		if (IsValidSurvivor(g_iTargetSurvivor))
		{
			GetClientEyePosition(g_iTargetSurvivor, fSurvivorPos);
			GetClientEyePosition(client, fSelfEyePos);
			fMins[0] = fSurvivorPos[0] - g_fTeleportDistance;
			fMaxs[0] = fSurvivorPos[0] + g_fTeleportDistance;
			fMins[1] = fSurvivorPos[1] - g_fTeleportDistance;
			fMaxs[1] = fSurvivorPos[1] + g_fTeleportDistance;
			fMaxs[2] = fSurvivorPos[2] + g_fTeleportDistance;
			fDirection[0] = 90.0;
			fDirection[1] = fDirection[2] = 0.0;
			fSpawnPos[0] = GetRandomFloat(fMins[0], fMaxs[0]);
			fSpawnPos[1] = GetRandomFloat(fMins[1], fMaxs[1]);
			fSpawnPos[2] = GetRandomFloat(fSurvivorPos[2], fMaxs[2]);
//			fVisiblePos[0] =fSpawnPos[0];
//			fVisiblePos[1] =fSpawnPos[1];
//			fVisiblePos[2] =fSpawnPos[2];
			int count2=0;
			
			while (PlayerVisibleToSDK(fSpawnPos) || !IsOnValidMesh(fSpawnPos) || IsPlayerStuck(fSpawnPos))
			{
				count2 ++;
				if(count2 > 20)
				{
					break;
				}
				fSpawnPos[0] = GetRandomFloat(fMins[0], fMaxs[0]);
				fSpawnPos[1] = GetRandomFloat(fMins[1], fMaxs[1]);
				fSpawnPos[2] = GetRandomFloat(fSurvivorPos[2], fMaxs[2]);
				TR_TraceRay(fSpawnPos, fDirection, MASK_PLAYERSOLID, RayType_Infinite);
				if(TR_DidHit())
				{
					TR_GetEndPosition(fEndPos);
					if(!IsOnValidMesh(fEndPos))
					{
						fSpawnPos[2] = fSurvivorPos[2] + NAV_MESH_HEIGHT;
						TR_TraceRay(fSpawnPos, fDirection, MASK_PLAYERSOLID, RayType_Infinite);
						if(TR_DidHit())
						{
							TR_GetEndPosition(fEndPos);
							fSpawnPos = fEndPos;
							fSpawnPos[2] += NAV_MESH_HEIGHT;
						}
					}
					else
					{
						fSpawnPos = fEndPos;
						fSpawnPos[2] += NAV_MESH_HEIGHT;
					}
				}
			}
			if (count2<= 20)
			{
				for (int count = 0; count < g_iSurvivorNum; count++)
				{
					int index = g_iSurvivors[count];
					if (IsClientInGame(index))
					{
						GetClientEyePosition(index, fSurvivorPos);
						fSurvivorPos[2] -= 60.0;
						Address nav1 = L4D_GetNearestNavArea(fSpawnPos, 120.0, false, false, false, TEAM_INFECTED);
						Address nav2 = L4D_GetNearestNavArea(fSurvivorPos, 120.0, false, false, false, TEAM_INFECTED);
						if (L4D2_NavAreaBuildPath(nav1, nav2, g_fTeleportDistance  * 1.2, TEAM_INFECTED, false) && GetVectorDistance(fSurvivorPos, fSpawnPos) >= g_fSpawnDistanceMin && nav1 != nav2)
						{
							TeleportEntity(client, fSpawnPos, NULL_VECTOR, NULL_VECTOR);
							SDKUnhook(client, SDKHook_PostThinkPost, SDK_UpdateThink);

							return;
						}
					}
				}
			}
		}
	}
}

stock bool IsAiSmoker(int client)
{
	if (client && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && IsFakeClient(client) && GetClientTeam(client) == TEAM_INFECTED && GetEntProp(client, Prop_Send, "m_zombieClass") == 1 && GetEntProp(client, Prop_Send, "m_isGhost") != 1)
	{
		return true;
	}
	else
	{
		return false;
	}
}

stock bool IsGhost(int client)
{
    return (IsValidClient(client) && view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost")));
}
stock bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}

//如果有人倒地或者被控且还有刷新机会，立即刷spitter打伤害
stock bool SpitterSpawn(){
	bool spitter=false;
	bool pin=false;
	for(int i=1;i<=MaxClients;i++){
		if(IsValidSurvivor(i))
			if(IsPinned(i)||L4D_IsPlayerIncapacitated(i))
				pin=true;
		if(IsSpitter(i))
			spitter=true;
	}
	if(!spitter&&pin)
			return true;
	return false;
}

//获取队列里Hunter和Charger数量
stock int getArrayHunterAndChargetNum(){
	int count = 0;
	for(int i = 0; i < aSpawnQueue.Length; i++){
		int type = aSpawnQueue.Get(i);
		if(type == 3 || type == 6){
			count++;
		}
	}
	return count;
}

// 返回在场特感数量，根据 z_%s_limit 限制每种特感上限
int IsBotTypeNeeded()
{
	if(g_hAllChargerMode.BoolValue){
		return 6;
	}
	if(g_hAllHunterMode.BoolValue){
		return 3;
	}
	GetSiLimit();
	int iType = GetRandomInt(1, 6);
	if (iType == 1)
	{
		if ((ENABLE_SMOKER & g_iEnableSIoption) && (g_ArraySIlimit[iType - 1] > 0))
		{
//			iSmokerLimit++;
			return 1;
		}
		else
		{
			IsBotTypeNeeded();
		}
	}
	else if (iType == 2)
	{
		if ((ENABLE_BOOMER & g_iEnableSIoption) && (g_ArraySIlimit[iType - 1] > 0) && (getArrayHunterAndChargetNum() > (g_iSiLimit/4 +1)))
		{
				return 2;
		}
		else
		{
			IsBotTypeNeeded();
		}
	}
	else if (iType == 3)
	{
		if ((ENABLE_HUNTER & g_iEnableSIoption) && (g_ArraySIlimit[iType - 1] > 0))
		{
		//	iHunterLimit++;
			return 3;
		}
		else
		{
			IsBotTypeNeeded();
		}
	}
	else if (iType == 4)
	{
		if ((ENABLE_SPITTER & g_iEnableSIoption) && (g_ArraySIlimit[iType - 1] > 0) && (getArrayHunterAndChargetNum() > (g_iSiLimit/4 +1)))
		{
			//	iSpitterLimit++;
			return 4;
		}
		else
		{
			IsBotTypeNeeded();
		}
	}
	else if (iType == 5)
	{
		if ((ENABLE_JOCKEY & g_iEnableSIoption) && (g_ArraySIlimit[iType - 1] > 0))
		{
			//iJockeyLimit++;
			return 5;
		}
		else
		{
			IsBotTypeNeeded();
		}
	}
	else if (iType == 6)
	{
		if ((ENABLE_CHARGER & g_iEnableSIoption) && (g_ArraySIlimit[iType - 1] > 0))
		{
			//iChargerLimit++;
			return 6;
		}
		else
		{
			IsBotTypeNeeded();
		}
	}
	return 0;
}

// 特感种类限制数组，刷完一波特感时重新读取 Cvar 数值，重置特感种类限制数量
void GetSiLimit()
{
	g_ArraySIlimit[0] = GetConVarInt(FindConVar("z_smoker_limit"));
	g_ArraySIlimit[1] = GetConVarInt(FindConVar("z_boomer_limit"));
	g_ArraySIlimit[2] = GetConVarInt(FindConVar("z_hunter_limit"));
	g_ArraySIlimit[3] = GetConVarInt(FindConVar("z_spitter_limit"));
	g_ArraySIlimit[4] = GetConVarInt(FindConVar("z_jockey_limit"));
	g_ArraySIlimit[5] = GetConVarInt(FindConVar("z_charger_limit"));
	for(int i = 0; i < aSpawnQueue.Length; i++){
		int type = aSpawnQueue.Get(i);
		if(type > 0 && type < 7){
			if(g_ArraySIlimit[type - 1] > 0){
				g_ArraySIlimit[type - 1]--;
			}			
			else
			{
				g_ArraySIlimit[type - 1] = 0;
			}
		}
		
	}
}

stock void Debug_Print(char[] format, any ...)
{
	#if (DEBUG)
	{
		char sBuffer[512];
		VFormat(sBuffer, sizeof(sBuffer), format, 2);
		Format(sBuffer, sizeof(sBuffer), "[%s] %s", "DEBUG", sBuffer);
	//	PrintToChatAll(sBuffer);
		PrintToConsoleAll(sBuffer);
		LogToFile(sLogFile, sBuffer);
	}
	#endif
}
