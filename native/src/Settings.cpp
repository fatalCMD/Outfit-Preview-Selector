#include "Settings.h"

namespace
{
	std::string Trim(std::string a_value)
	{
		const auto first = a_value.find_first_not_of(" \t\r\n");
		if (first == std::string::npos) {
			return {};
		}

		const auto last = a_value.find_last_not_of(" \t\r\n");
		return a_value.substr(first, last - first + 1);
	}

	std::string Upper(std::string a_value)
	{
		for (char& ch : a_value) {
			ch = static_cast<char>(std::toupper(static_cast<unsigned char>(ch)));
		}

		return a_value;
	}

	bool ParseBool(std::string a_value, bool a_fallback)
	{
		a_value = Upper(Trim(std::move(a_value)));

		if (a_value == "1" || a_value == "TRUE" || a_value == "YES" || a_value == "ON") {
			return true;
		}

		if (a_value == "0" || a_value == "FALSE" || a_value == "NO" || a_value == "OFF") {
			return false;
		}

		return a_fallback;
	}

	float ParseFloat(std::string a_value, float a_fallback)
	{
		a_value = Trim(std::move(a_value));
		if (a_value.empty()) {
			return a_fallback;
		}

		try {
			size_t index = 0;
			const float parsed = std::stof(a_value, &index);
			return index == a_value.size() ? parsed : a_fallback;
		} catch (...) {
			return a_fallback;
		}
	}

	void ApplyValue(std::string a_section, std::string a_key, std::string a_value)
	{
		a_section = Upper(Trim(std::move(a_section)));
		a_key = Upper(Trim(std::move(a_key)));
		a_value = Trim(std::move(a_value));

		if (a_section == "GENERAL") {
			if (a_key == "BENABLE") {
				Settings::enabled = ParseBool(a_value, Settings::enabled);
			} else if (a_key == "BCLEARMENUBLUR") {
				Settings::clearMenuBlur = ParseBool(a_value, Settings::clearMenuBlur);
			} else if (a_key == "BENABLEPREVIEWLIGHT") {
				Settings::enablePreviewLight = ParseBool(a_value, Settings::enablePreviewLight);
			} else if (a_key == "BPREVIEWLIGHTDEFAULTON") {
				Settings::previewLightDefaultOn = ParseBool(a_value, Settings::previewLightDefaultOn);
			}

			return;
		}

		if (a_section == "LIGHT") {
			if (a_key == "FSTRENGTH") {
				Settings::lightStrength = ParseFloat(a_value, Settings::lightStrength);
			} else if (a_key == "FAMBIENT") {
				Settings::lightAmbient = ParseFloat(a_value, Settings::lightAmbient);
			} else if (a_key == "FRADIUS") {
				Settings::lightRadius = ParseFloat(a_value, Settings::lightRadius);
			} else if (a_key == "FRED") {
				Settings::lightRed = ParseFloat(a_value, Settings::lightRed);
			} else if (a_key == "FGREEN") {
				Settings::lightGreen = ParseFloat(a_value, Settings::lightGreen);
			} else if (a_key == "FBLUE") {
				Settings::lightBlue = ParseFloat(a_value, Settings::lightBlue);
			}
			return;
		}

		if (a_section != "CAMERA") {
			return;
		}

		if (a_key == "FOFFSETX") {
			Settings::offsetX = ParseFloat(a_value, Settings::offsetX);
		} else if (a_key == "FOFFSETY") {
			Settings::offsetY = ParseFloat(a_value, Settings::offsetY);
		} else if (a_key == "FOFFSETZ") {
			Settings::offsetZ = ParseFloat(a_value, Settings::offsetZ);
		} else if (a_key == "FDISTANCE") {
			Settings::distance = ParseFloat(a_value, Settings::distance);
		} else if (a_key == "FFOV") {
			Settings::fov = ParseFloat(a_value, Settings::fov);
		}
	}
}

namespace Settings
{
	std::filesystem::path GetINIPath()
	{
		wchar_t modulePath[MAX_PATH]{};

		const HMODULE module = GetModuleHandleW(Settings::DLL_NAME);
		if (!module) {
			return std::filesystem::path("Data/SKSE/Plugins") / Settings::INI_NAME;
		}

		const DWORD length = GetModuleFileNameW(module, modulePath, MAX_PATH);
		if (length == 0 || length == MAX_PATH) {
			return std::filesystem::path("Data/SKSE/Plugins") / Settings::INI_NAME;
		}

		return std::filesystem::path(modulePath).parent_path() / Settings::INI_NAME;
	}

	void SetDefaults()
	{
		enabled = true;
		clearMenuBlur = true;
		enablePreviewLight = true;
		previewLightDefaultOn = false;
		offsetX = -54.0f;
		offsetY = -12.0f;
		offsetZ = -24.0f;
		distance = 182.0f;
		fov = 60.0f;
		lightStrength = 1.25f;
		lightAmbient = 0.08f;
		lightRadius = 420.0f;
		lightRed = 1.0f;
		lightGreen = 0.88f;
		lightBlue = 0.72f;
	}

	void Load()
	{
		if (loaded) {
			return;
		}

		loaded = true;
		SetDefaults();

		const auto path = GetINIPath();
		std::ifstream file(path);
		if (!file.is_open()) {
			logger::warn("[Settings] Could not open {}. Defaults will be used.", path.string());
			return;
		}

		std::string section;
		std::string line;

		while (std::getline(file, line)) {
			const auto comment = line.find_first_of(";#");
			if (comment != std::string::npos) {
				line = line.substr(0, comment);
			}

			line = Trim(std::move(line));
			if (line.empty()) {
				continue;
			}

			if (line.front() == '[' && line.back() == ']') {
				section = line.substr(1, line.size() - 2);
				continue;
			}

			const auto equals = line.find('=');
			if (equals == std::string::npos) {
				continue;
			}

			ApplyValue(section, line.substr(0, equals), line.substr(equals + 1));
		}

		logger::info(
			"[Settings] enabled={} clearBlur={} light={} lightDefault={} offsetX={} offsetY={} offsetZ={} distance={} fov={}",
			enabled,
			clearMenuBlur,
			enablePreviewLight,
			previewLightDefaultOn,
			offsetX,
			offsetY,
			offsetZ,
			distance,
			fov);
	}
}
