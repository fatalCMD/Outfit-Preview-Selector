#pragma once

namespace Settings
{
	inline constexpr const wchar_t* DLL_NAME = L"OutfitPreviewSelectorCamera.dll";
	inline constexpr const char* INI_NAME = "OutfitPreviewSelectorCamera.ini";

	inline bool loaded = false;
	inline bool enabled = true;
	inline bool clearMenuBlur = true;
	inline bool hideOtherUI = true;
	inline bool enablePreviewLight = true;
	inline bool previewLightDefaultOn = false;
	inline float offsetX = -54.0f;
	inline float offsetY = -12.0f;
	inline float offsetZ = -24.0f;
	inline float distance = 182.0f;
	inline float fov = 60.0f;
	inline float lightStrength = 0.65f;
	inline float lightAmbient = 0.04f;
	inline float lightRadius = 420.0f;
	inline float lightRed = 1.0f;
	inline float lightGreen = 0.88f;
	inline float lightBlue = 0.72f;
	inline float lightOffsetX = -70.0f;
	inline float lightOffsetY = -25.0f;
	inline float lightOffsetZ = 110.0f;

	void SetDefaults();
	void Load();
	bool SaveCameraValues(float a_distance, float a_height);
	[[nodiscard]] std::filesystem::path GetINIPath();
}
