#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

enum playerPreview {
	iDummyModelRef, 
	iParticleRef, 
	iTrackRef, 
	iMaterialTrailRef, 
	iPreviewTimeLeft, 
}

int g_ePlayerOptions[MAXPLAYERS + 1][playerPreview];
int g_iPreviewTime = 15;

#define SF_NOUSERCONTROL    2
#define SF_PASSABLE         8


public void Preview_OnPluginStart() {
	for (int i = 0; i < MAXPLAYERS + 1; i += 1) {
		g_ePlayerOptions[i][iDummyModelRef] = -1;
		g_ePlayerOptions[i][iParticleRef] = -1;
		g_ePlayerOptions[i][iTrackRef] = -1;
		g_ePlayerOptions[i][iMaterialTrailRef] = -1;
		g_ePlayerOptions[i][iPreviewTimeLeft] = -1;
	}
}

public void Preview_OnMapStart() {
	CreateTimer(1.0, refreshTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action refreshTimer(Handle timer, any data) {
	for (int i = 1; i < MAXPLAYERS + 1; i += 1) {
		if (g_ePlayerOptions[i][iPreviewTimeLeft] > 0) {
			g_ePlayerOptions[i][iPreviewTimeLeft] -= 1;
		} else if (g_ePlayerOptions[i][iPreviewTimeLeft] == 0) {
			resetAllPreviews(i);
		}
	}
}

public void Preview_OnClientPostAdminCheck(int client) {
	g_ePlayerOptions[client][iDummyModelRef] = -1;
	g_ePlayerOptions[client][iParticleRef] = -1;
	g_ePlayerOptions[client][iTrackRef] = -1;
	g_ePlayerOptions[client][iMaterialTrailRef] = -1;
	g_ePlayerOptions[client][iPreviewTimeLeft] = -1;
}

public void previewItemToPlayer(int client, int itemid) {
	PrintToChat(client, "[-T-] Trying to preview %s: %s", g_eTypeHandlers[g_eItems[itemid][iHandler]][szType], g_eItems[itemid][szName]);
	char itemtype[64];
	strcopy(itemtype, sizeof(itemtype), g_eTypeHandlers[g_eItems[itemid][iHandler]][szType]);
	
	resetAllPreviews(client);
	
	if (StrEqual(itemtype, "playerskin")) {
		createSkinPreview(client, itemid);
	} else if (StrEqual(itemtype, "Aura")) {
		createAuraPreview(client, itemid);
	} else if (StrEqual(itemtype, "Particles")) {
		createParticleTrailPreview(client, itemid);
	} else if (StrEqual(itemtype, "trail")) {
		createMaterialTrailPreview(client, itemid);
	} else {
		PrintToChat(client, "Could not create a Preview for this item. Will be implemented soon!");
	}
}

public void createSkinPreview(int client, int itemid) {
	int dummyModel = createEntityModel(client, g_eItems[itemid][szUniqueId]);
	attachRotator(dummyModel);
	
	// Triggers resetAllPreviews after g_iPreviewTime seconds
	g_ePlayerOptions[client][iPreviewTimeLeft] = g_iPreviewTime;
}

public void createAuraPreview(int client, int itemid) {
	int dummyModel = createEntityModel(client, "models/player/tm_anarchist_variantb.mdl");
	attachParticle(client, dummyModel, g_eItems[itemid][szUniqueId]);
	
	g_ePlayerOptions[client][iPreviewTimeLeft] = g_iPreviewTime;
}

public void createParticleTrailPreview(int client, int itemid) {
	// Create the model
	int dummyModel = createEntityModel(client, "models/player/tm_anarchist_variantb.mdl");
	// attach the particles to the model
	attachParticle(client, dummyModel, g_eItems[itemid][szUniqueId]);
	// create an invisible track in front of the client
	int trackTrain = createTrackTrain(client);
	// attach (and teleport) the model to the tracktrain and run it
	attachEntityToEntity(trackTrain, dummyModel);
	
	g_ePlayerOptions[client][iPreviewTimeLeft] = g_iPreviewTime;
}

public void createMaterialTrailPreview(int client, int itemid) {
	// dummy Model
	int dummyModel = createEntityModel(client, "models/player/tm_anarchist_variantb.mdl");
	// Material trail
	int trail = createMaterialTrail(client, itemid);
	// attach material trail to dummy model
	attachTrail(trail, dummyModel);
	// create tracktain
	int trackTrain = createTrackTrain(client);
	// parent dummy model with material trail to train track
	attachEntityToEntity(trackTrain, dummyModel);
	
	g_ePlayerOptions[client][iPreviewTimeLeft] = g_iPreviewTime;
}

public void resetAllPreviews(int client) {
	deleteParticles(client);
	deleteMaterialTrail(client);
	deleteEntityModel(client);
	deleteTrainTrack(client);
	
	g_ePlayerOptions[client][iPreviewTimeLeft] = -1;
}

/* Base model creation function to use all the time */
public int createEntityModel(int client, char[] entityModel) {
	float m_fPosition[3];
	float m_fAngles[3];
	GetClientAbsOrigin(client, m_fPosition);
	GetClientAbsAngles(client, m_fAngles);
	
	int dummyModel = CreateEntityByName("prop_dynamic");
	if (dummyModel == -1) {
		LogError("failed to create dummyModel");
		return -1;
	}
	int currTime = GetTime();
	char trackTargetname[64];
	Format(trackTargetname, sizeof(trackTargetname), "storePreview_%i-%i-%i", currTime, GetRandomInt(1, 1000), client);
	DispatchKeyValue(dummyModel, "targetname", trackTargetname);
	DispatchKeyValue(dummyModel, "spawnflags", "64");
	DispatchKeyValueVector(dummyModel, "origin", m_fPosition);
	DispatchKeyValueVector(dummyModel, "angles", m_fAngles);
	DispatchKeyValue(dummyModel, "model", entityModel);
	DispatchKeyValue(dummyModel, "rendermode", "0");
	DispatchKeyValue(dummyModel, "renderfx", "0");
	DispatchKeyValue(dummyModel, "rendercolor", "255 255 255");
	DispatchKeyValue(dummyModel, "renderamt", "255");
	DispatchKeyValue(dummyModel, "solid", "0");
	
	DispatchSpawn(dummyModel);
	SetEntProp(dummyModel, Prop_Send, "m_CollisionGroup", 11);
	
	SetVariantString("run_upper_knife");
	AcceptEntityInput(dummyModel, "SetAnimation");
	AcceptEntityInput(dummyModel, "Enable");
	
	TeleportEntity(dummyModel, m_fPosition, m_fAngles, NULL_VECTOR);
	
	SetVariantString("idle");
	AcceptEntityInput(dummyModel, "SetAnimation");
	
	SDKHook(dummyModel, SDKHook_SetTransmit, Hook_SetTransmit_DummyModel);
	
	g_ePlayerOptions[client][iDummyModelRef] = EntIndexToEntRef(dummyModel);
	return dummyModel;
}

/* Rotator to spin models */
public void attachRotator(int attachToEntity) {
	int rotator = CreateEntityByName("func_rotating");
	if (rotator == -1) {
		LogError("failed to create rotator");
		return;
	}
	float m_fPosition[3];
	GetEntPropVector(attachToEntity, Prop_Data, "m_vecOrigin", m_fPosition);
	DispatchKeyValueVector(rotator, "origin", m_fPosition);
	DispatchKeyValue(rotator, "targetname", "Item");
	DispatchKeyValue(rotator, "maxspeed", "40");
	DispatchKeyValue(rotator, "friction", "0");
	DispatchKeyValue(rotator, "dmg", "0");
	DispatchKeyValue(rotator, "solid", "0");
	DispatchKeyValue(rotator, "spawnflags", "64");
	DispatchSpawn(rotator);
	
	SetVariantString("!activator");
	AcceptEntityInput(attachToEntity, "SetParent", rotator, rotator);
	AcceptEntityInput(rotator, "Start");
}

/* Base Particle Generator */
public int attachParticle(int client, int attachToEntity, char[] particleName) {
	if (!IsValidEntity(attachToEntity)) {
		LogError("failed to attach to entity. Id: %i", attachToEntity);
		return -1;
	}
	float m_fPosition[3];
	GetEntPropVector(attachToEntity, Prop_Data, "m_vecOrigin", m_fPosition);
	
	int particleSystem = CreateEntityByName("info_particle_system");
	if (particleSystem == -1) {
		LogError("failed to create particleSystem");
		return -1;
	}
	DispatchKeyValue(particleSystem, "start_active", "0");
	DispatchKeyValue(particleSystem, "effect_name", particleName);
	DispatchSpawn(particleSystem);
	TeleportEntity(particleSystem, m_fPosition, NULL_VECTOR, NULL_VECTOR);
	ActivateEntity(particleSystem);
	SetVariantString("!activator");
	AcceptEntityInput(particleSystem, "SetParent", attachToEntity, particleSystem, 0);
	CreateTimer(0.1, enableParticle, EntIndexToEntRef(particleSystem));
	SetEdictFlags(particleSystem, (GetEdictFlags(particleSystem) ^ FL_EDICT_ALWAYS));
	
	SDKHook(particleSystem, SDKHook_SetTransmit, Hook_SetTransmit_Particle);
	
	g_ePlayerOptions[client][iParticleRef] = EntIndexToEntRef(particleSystem);
	return particleSystem;
}

/* Train Tracks to move stuff */
public int createTrackTrain(int client) {
	int currTime = GetTime();
	char uniqueId[32];
	Format(uniqueId, sizeof(uniqueId), "%i-%i-%i", currTime, client, GetRandomInt(1, 1000));
	
	float m_fOrigin[3], m_fAngles[3], m_fRadians[2], m_fPosition[3];
	
	GetClientAbsOrigin(client, m_fOrigin);
	GetClientAbsAngles(client, m_fAngles);
	
	m_fRadians[0] = DegToRad(m_fAngles[0]);
	m_fRadians[1] = DegToRad(m_fAngles[1]);
	
	m_fPosition[0] = m_fOrigin[0] + 64 * Cosine(m_fRadians[0]) * Cosine(m_fRadians[1]);
	m_fPosition[1] = m_fOrigin[1] + 64 * Cosine(m_fRadians[0]) * Sine(m_fRadians[1]);
	m_fPosition[2] = m_fOrigin[2] + 4 * Sine(m_fRadians[0]);
	
	m_fAngles[0] *= -1.0;
	m_fAngles[1] *= -1.0;
	
	float startPos[3];
	startPos[0] = m_fPosition[0] + (200.0 * Cosine(m_fRadians[1] + DegToRad(45.0)));
	startPos[1] = m_fPosition[1] + (200.0 * Sine(m_fRadians[1] + DegToRad(45.0)));
	startPos[2] = m_fPosition[2];
	
	float endPos[3];
	endPos[0] = m_fPosition[0] - (200.0 * Cosine(m_fRadians[1] + DegToRad(135.0)));
	endPos[1] = m_fPosition[1] - (200.0 * Sine(m_fRadians[1] + DegToRad(135.0)));
	endPos[2] = m_fPosition[2];
	
	int startPath = CreateEntityByName("path_track");
	if (startPath == -1) {
		LogError("failed to create path_track start");
		return -1;
	}
	DispatchKeyValueVector(startPath, "origin", startPos);
	DispatchKeyValueVector(startPath, "angles", m_fAngles);
	char startPathTargetName[64];
	Format(startPathTargetName, sizeof(startPathTargetName), "startPath_%s", uniqueId);
	char endPathTargetName[64];
	Format(endPathTargetName, sizeof(endPathTargetName), "endPath_%s", uniqueId);
	DispatchKeyValue(startPath, "targetname", startPathTargetName);
	DispatchKeyValue(startPath, "target", endPathTargetName);
	
	int endPath = CreateEntityByName("path_track");
	if (endPath == -1) {
		LogError("failed to create path_track end");
		return -1;
	}
	DispatchKeyValueVector(endPath, "origin", endPos);
	DispatchKeyValueVector(endPath, "angles", m_fAngles);
	DispatchKeyValue(endPath, "targetname", endPathTargetName);
	DispatchSpawn(endPath);
	ActivateEntity(endPath);
	TeleportEntity(endPath, endPos, m_fAngles, NULL_VECTOR);
	AcceptEntityInput(endPath, "EnablePath");
	
	// wait because end was not spawned yet
	DispatchSpawn(startPath);
	ActivateEntity(startPath);
	TeleportEntity(startPath, startPos, m_fAngles, NULL_VECTOR);
	AcceptEntityInput(startPath, "EnablePath");
	
	int trackTrain = CreateEntityByName("func_tracktrain");
	if (trackTrain == -1) {
		LogError("failed to create tracktrain");
		return -1;
	}
	
	char trainTrackTargetName[64];
	Format(trainTrackTargetName, sizeof(trainTrackTargetName), "previewTrainTrack_%s", uniqueId);
	DispatchKeyValue(trackTrain, "targetname", trainTrackTargetName);
	DispatchKeyValue(trackTrain, "target", startPathTargetName);
	DispatchKeyValue(trackTrain, "speed", "125");
	DispatchKeyValue(trackTrain, "startspeed", "125");
	DispatchKeyValue(trackTrain, "orientationtype", "2");
	char spawnflags[12];
	FormatEx(spawnflags, sizeof(spawnflags), "%i", SF_NOUSERCONTROL | SF_PASSABLE);
	DispatchKeyValue(trackTrain, "spawnflags", spawnflags);
	DispatchSpawn(trackTrain);
	TeleportEntity(trackTrain, startPos, m_fAngles, NULL_VECTOR);
	ActivateEntity(trackTrain);
	AcceptEntityInput(trackTrain, "StartForward");
	
	CreateTimer(2.1, reverseTrackDirection, EntIndexToEntRef(trackTrain));
	g_ePlayerOptions[client][iTrackRef] = EntIndexToEntRef(trackTrain);
	
	// Note that startPath and endPath are edicts not entities. Therefore about -12312312 as index 
	return trackTrain;
}

public int createMaterialTrail(int client, int itemid) {
	int itemIndex = Store_GetDataIndex(itemid);
	int trail = CreateEntityByName("env_sprite");
	if (trail == -1) {
		LogError("failed to create trail");
		return -1;
	}
	DispatchKeyValue(trail, "classname", "env_sprite");
	DispatchKeyValue(trail, "spawnflags", "1");
	DispatchKeyValue(trail, "scale", "0.0");
	DispatchKeyValue(trail, "rendermode", "10");
	DispatchKeyValue(trail, "rendercolor", "255 255 255 0");
	DispatchKeyValue(trail, "model", g_eTrails[itemIndex][szMaterial]);
	DispatchSpawn(trail);
	SDKHook(trail, SDKHook_SetTransmit, Hook_SetTransmit_MaterialTrail);
	
	int m_iColor[4];
	m_iColor[0] = g_eTrails[itemIndex][iColor][0];
	m_iColor[1] = g_eTrails[itemIndex][iColor][1];
	m_iColor[2] = g_eTrails[itemIndex][iColor][2];
	m_iColor[3] = g_eTrails[itemIndex][iColor][3];
	TE_SetupBeamFollow(trail, g_eTrails[itemIndex][iCacheID], 0, 1.0, g_eTrails[itemIndex][fWidth], g_eTrails[itemIndex][fWidth], 10, m_iColor);
	TE_SendToAll();
	
	return trail;
}

/* CLEANUP FUNCTIONS */
public void deleteEntityModel(int client) {
	if (!IsValidEdict(g_ePlayerOptions[client][iDummyModelRef])) {
		return;
	}
	int deleteDummyModelIndex = EntRefToEntIndex(g_ePlayerOptions[client][iDummyModelRef]);
	if (IsValidEntity(deleteDummyModelIndex)) {
		SetEntProp(deleteDummyModelIndex, Prop_Send, "m_bShouldGlow", false, true);
		SDKUnhook(deleteDummyModelIndex, SDKHook_SetTransmit, Hook_SetTransmit_DummyModel);
		AcceptEntityInput(deleteDummyModelIndex, "kill");
	}
	g_ePlayerOptions[client][iDummyModelRef] = -1;
}

public void deleteParticles(int client) {
	if (!IsValidEdict(g_ePlayerOptions[client][iParticleRef])) {
		return;
	}
	int deleteParticleIndex = EntRefToEntIndex(g_ePlayerOptions[client][iParticleRef]);
	if (IsValidEntity(deleteParticleIndex)) {
		if (IsValidEdict(deleteParticleIndex)) {
			SDKUnhook(deleteParticleIndex, SDKHook_SetTransmit, Hook_SetTransmit_Particle);
			AcceptEntityInput(deleteParticleIndex, "kill");
		}
		g_ePlayerOptions[client][iParticleRef] = -1;
	}
}

public void deleteTrainTrack(int client) {
	if (!IsValidEdict(g_ePlayerOptions[client][iTrackRef])) {
		return;
	}
	int deleteTrackIndex = EntRefToEntIndex(g_ePlayerOptions[client][iTrackRef]);
	if (IsValidEntity(deleteTrackIndex)) {
		if (IsValidEdict(deleteTrackIndex)) {
			AcceptEntityInput(deleteTrackIndex, "kill");
		}
		g_ePlayerOptions[client][iTrackRef] = -1;
	}
}

public void deleteMaterialTrail(int client) {
	if (!IsValidEdict(g_ePlayerOptions[client][iMaterialTrailRef])) {
		return;
	}
	int deleteMaterialTrailIndex = EntRefToEntIndex(g_ePlayerOptions[client][iMaterialTrailRef]);
	if (IsValidEntity(deleteMaterialTrailIndex)) {
		if (IsValidEdict(deleteMaterialTrailIndex)) {
			AcceptEntityInput(deleteMaterialTrailIndex, "kill");
		}
		g_ePlayerOptions[client][iMaterialTrailRef] = -1;
	}
}

/* TRANSMIT HOOKS */
public Action Hook_SetTransmit_DummyModel(int ent, int client) {
	// Invalid Ref
	if (g_ePlayerOptions[client][iDummyModelRef] <= 0) {
		return Plugin_Continue;
	}
	
	int dummyEntityIndex = EntRefToEntIndex(g_ePlayerOptions[client][iDummyModelRef]);
	if (ent == dummyEntityIndex) {
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

public Action Hook_SetTransmit_Particle(int ent, int client) {
	// Particles have a bug that need FL_EDICT_ALWAYS to be constantly set to hide them
	setFlags(ent);
	// Invalid Ref
	if (g_ePlayerOptions[client][iParticleRef] <= 0) {
		return Plugin_Continue;
	}
	
	int particleEntityIndex = EntRefToEntIndex(g_ePlayerOptions[client][iParticleRef]);
	if (ent == particleEntityIndex) {
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

public Action Hook_SetTransmit_MaterialTrail(int ent, int client) {
	// Invalid Ref
	if (g_ePlayerOptions[client][iMaterialTrailRef] <= 0) {
		return Plugin_Continue;
	}
	
	int materialTrailEntityIndex = EntRefToEntIndex(g_ePlayerOptions[client][iMaterialTrailRef]);
	if (ent == materialTrailEntityIndex) {
		return Plugin_Continue;
	}
	return Plugin_Handled;
}


/* PREVIEW HELPER FUNCTIONS */
public Action enableParticle(Handle Timer, any entRef) {
	int ent = EntRefToEntIndex(entRef);
	if (ent > 0 && IsValidEntity(ent)) {
		AcceptEntityInput(ent, "Start");
		setFlags(ent);
	}
}

public void setFlags(int edict) {
	if (GetEdictFlags(edict) & FL_EDICT_ALWAYS) {
		SetEdictFlags(edict, (GetEdictFlags(edict) ^ FL_EDICT_ALWAYS));
	}
}

public void attachEntityToEntity(int attachTo, int toAttach) {
	if (!IsValidEntity(attachTo) && !IsValidEntity(toAttach)) {
		LogError("Could not attach %i to %i", attachTo, toAttach);
		return;
	}
	float m_fPosition[3];
	GetEntPropVector(attachTo, Prop_Data, "m_vecOrigin", m_fPosition);
	PrintToChatAll("%.2f %.2f %.2f", m_fPosition[0], m_fPosition[1], m_fPosition[2]);

	TeleportEntity(toAttach, m_fPosition, NULL_VECTOR, NULL_VECTOR);
	
	// without delay it spawns somewhere in the map. Thanks valve!
	DataPack linkData = CreateDataPack();
	WritePackCell(linkData, EntIndexToEntRef(attachTo));
	WritePackCell(linkData, EntIndexToEntRef(toAttach));
	CreateTimer(0.1, createLink, linkData);
}

public Action createLink(Handle Timer, any datapack) {
	ResetPack(datapack);
	int attachTo = EntRefToEntIndex(ReadPackCell(datapack));
	int toAttach = EntRefToEntIndex(ReadPackCell(datapack));
	
	if (!IsValidEntity(attachTo) || !IsValidEntity(toAttach)) {
		return;
	}
	
	SetVariantEntity(attachTo);
	AcceptEntityInput(toAttach, "SetParent");
}

public Action reverseTrackDirection(Handle timer, any trackTrainObject) {
	int trackTrain = EntRefToEntIndex(trackTrainObject);
	if (!IsValidEntity(trackTrain)) {
		return;
	}
	AcceptEntityInput(trackTrain, "Reverse");
	CreateTimer(1.5, reverseTrackDirection, EntIndexToEntRef(trackTrain));
}

public attachTrail(int trail, int attachTo) {
	float m_fOrigin[3];
	float m_fAngle[3];
	float m_fTemp[3] =  { 0.0, 90.0, 0.0 };
	
	GetEntPropVector(trail, Prop_Data, "m_vecOrigin", m_fOrigin);
	GetEntPropVector(trail, Prop_Data, "m_angAbsRotation", m_fAngle);
	SetEntPropVector(trail, Prop_Data, "m_angAbsRotation", m_fTemp);
	
	float m_fPosition[3];
	m_fPosition[0] = 30.0;
	m_fPosition[1] = 0.0;
	m_fPosition[2] = 35.0;

	AddVectors(m_fOrigin, m_fPosition, m_fOrigin);
	TeleportEntity(trail, m_fOrigin, m_fTemp, NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(trail, "SetParent", attachTo, trail);
	SetEntPropVector(attachTo, Prop_Data, "m_angAbsRotation", m_fAngle);
} 