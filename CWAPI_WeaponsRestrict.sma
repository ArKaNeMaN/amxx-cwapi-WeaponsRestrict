#include <amxmodx>
#include <reapi>
#include <cwapi>

#define RESTRCIT_FLAG_ADDITEM BIT(1)
#define RESTRCIT_FLAG_BUY BIT(2)
#define RESTRCIT_FLAG_ALL RESTRCIT_FLAG_ADDITEM|RESTRCIT_FLAG_BUY

new Trie:RestrictedWeapons;

new const PLUG_NAME[] = "[CWAPI] Weapons Restrict";
new const PLUG_VER[] = "1.0.0";

public CWAPI_LoadWeaponsPost(){
    register_plugin(PLUG_NAME, PLUG_VER, "ArKaNeMaN");

    LoadRestrict();

    register_srvcmd("CWAPI_WR_ReloadConfig", "SrvCmd_ReloadConfig");

    server_print("[%s v%s] loaded.", PLUG_NAME, PLUG_VER);
}

public SrvCmd_ReloadConfig(){
    LoadRestrict();
}

public Hook_CWAPI_AddItem(ItemId){
    static UserId; UserId = get_member(ItemId, m_pPlayer)
    client_print(UserId, print_center, "Это оружие запрещено");
    static ItemName[32]; rg_get_iteminfo(ItemId, ItemInfo_pszName, ItemName, charsmax(ItemName));
    rg_remove_item(UserId, ItemName);
    return CWAPI_RET_HANDLED;
}

public Hook_CWAPI_Deploy(ItemId){
    static UserId; UserId = get_member(ItemId, m_pPlayer)
    client_print(UserId, print_center, "Это оружие запрещено");
    static ItemName[32]; rg_get_iteminfo(ItemId, ItemInfo_pszName, ItemName, charsmax(ItemName));
    rg_remove_item(UserId, ItemName);
    return CWAPI_RET_HANDLED;
}

LoadRestrict(){
    if(RestrictedWeapons != Invalid_Trie)
        TrieDestroy(RestrictedWeapons);
    RestrictedWeapons = TrieCreate();

    new File[PLATFORM_MAX_PATH];
    new MapName[32]; get_mapname(MapName, charsmax(MapName));
    get_localinfo("amxx_configsdir", File, charsmax(File));
    add(File, charsmax(File), "/plugins/CustomWeaponsAPI/Modules/WeaponsRestrict");
    if(file_exists(fmt("%s/Maps/%s.json", File, MapName)))
        add(File, charsmax(File), fmt("/Maps/%s.json", MapName));
    else if(file_exists(fmt("%s/Main.json", File)))
        add(File, charsmax(File), "/Main.json");
    else{
        log_amx("[ERROR] Config file '%s' not found", fmt("%s/Main.json", File));
        return;
    }

    new JSON:List = json_parse(File, true);
    if(List == Invalid_JSON || !json_is_object(List)){
        json_free(List);
        log_amx("[ERROR] Invalid config structure. File '%s'.", File);
        return;
    }
    
    new WeaponName[32], RestrictFlags, StrFlags[8];
    for(new i = 0; i < json_object_get_count(List); i++){
        json_object_get_name(List, i, WeaponName, charsmax(WeaponName));
        if(CWAPI_GetWeaponId(WeaponName) == -1){
            log_amx("[WARNING] Custom weapons '%s' not found.", WeaponName);
            continue;
        }
        json_object_get_string(List, WeaponName, StrFlags, charsmax(StrFlags));
        RestrictFlags = GetRestrictFlags(StrFlags);
        TrieSetCell(RestrictedWeapons, WeaponName, RestrictFlags);

        if(RestrictFlags & RESTRCIT_FLAG_ADDITEM) CWAPI_RegisterHook(WeaponName, CWAPI_WE_AddItem, "Hook_CWAPI_AddItem");
        //if(RestrictFlags & RESTRCIT_FLAG_BUY) CWAPI_RegisterHook(CWAPI_WE_Buy, "Hook_CWAPI_Buy");
    }
}

GetRestrictFlags(Str[]){
    new Flags = 0;
    if(strfind(Str, "a",  true) != -1) Flags |= RESTRCIT_FLAG_BUY;
    if(strfind(Str, "b",  true) != -1) Flags |= RESTRCIT_FLAG_ADDITEM;
    if(!Flags)
        Flags = RESTRCIT_FLAG_ALL;
    return Flags;
}