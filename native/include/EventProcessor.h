#pragma once

class EventProcessor final :
	public RE::BSTEventSink<RE::MenuOpenCloseEvent>,
	public RE::BSTEventSink<SKSE::ModCallbackEvent>,
	public RE::BSTEventSink<RE::InputEvent*>
{
public:
	static EventProcessor& GetSingleton();

	static void Register();
	static void Unregister();

	RE::BSEventNotifyControl ProcessEvent(
		const RE::MenuOpenCloseEvent* a_event,
		RE::BSTEventSource<RE::MenuOpenCloseEvent>* a_source) override;

	RE::BSEventNotifyControl ProcessEvent(
		const SKSE::ModCallbackEvent* a_event,
		RE::BSTEventSource<SKSE::ModCallbackEvent>* a_source) override;

	RE::BSEventNotifyControl ProcessEvent(
		RE::InputEvent* const* a_event,
		RE::BSTEventSource<RE::InputEvent*>* a_source) override;

private:
	bool previewRequested = false;
	bool menuOpen = false;
	bool allowCameraControl = false;
	std::vector<RE::BSFixedString> hiddenMenus;

	void RequestPreview();
	void StartPreview();
	void StopPreview();
	void RotatePreview(float a_direction);
	void HideOtherMenus();
	void HideMenu(std::string_view a_menuName);
	void RestoreOtherMenus();
};
