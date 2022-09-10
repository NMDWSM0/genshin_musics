GLOBAL.continuous_mode = (GetModConfigData("music_mode")~="busy")

Assets = {
	Asset("SOUNDPACKAGE", "sound/music_mod.fev"),
    Asset("SOUND", "sound/music_mod.fsb"),
}
RemapSoundEvent("dontstarve/music/music_FE", "music_mod/music/music_FE")
RemapSoundEvent("dontstarve/music/music_FE_yotc", "music_mod/music/music_FE")
RemapSoundEvent("dontstarve/music/music_FE_WF", "music_mod/music/music_FE")
RemapSoundEvent("dontstarve/together_FE/DST_theme_portaled", "music_mod/music/DST_theme_portaled")
RemapSoundEvent("dontstarve/HUD/Together_HUD/collectionscreen/music/jukebox", "music_mod/music/jukebox")
RemapSoundEvent("dontstarve/music/music_hoedown", "music_mod/music/music_hoedown")
RemapSoundEvent("dontstarve/music/music_hoedown_moose", "music_mod/music/music_hoedown_moose")
RemapSoundEvent("dontstarve/music/music_hoedown_goose", "music_mod/music/music_hoedown_goose")
RemapSoundEvent("dontstarve_DLC001/music/music_wigfrid_FE", "music_mod/music/music_FE")
RemapSoundEvent("turnoftides/sanity/lunacy_FE", "music_mod/music/music_FE")
RemapSoundEvent("yotb_2021/music/FE", "music_mod/music/music_FE")
RemapSoundEvent("dontstarve/music/music_moonstorm_FE", "music_mod/music/music_FE")
RemapSoundEvent("dontstarve/music/music_FE_summerevent", "music_mod/music/music_FE")
RemapSoundEvent("dontstarve/music/music_FE_webber", "music_mod/music/music_FE")
RemapSoundEvent("dontstarve/music/music_FE_pirates", "music_mod/music/music_FE")
RemapSoundEvent("dontstarve/music/music_FE_wx", "music_mod/music/music_FE")
RemapSoundEvent("dontstarve/music/music_FE_wolfgang", "music_mod/music/music_FE")
RemapSoundEvent("dontstarve/music/music_FE_wanda", "music_mod/music/music_FE")
RemapSoundEvent("dontstarve/music/music_FE_wickerbottom", "music_mod/music/music_FE")