#include "EventProcessor.h"

#include "MenuCamera.h"
#include "Settings.h"

namespace
{
	constexpr std::string_view CUSTOM_MENU = "CustomMenu";
	constexpr std::string_view CURSOR_MENU = "Cursor Menu";
	constexpr std::string_view OPEN_EVENT = "OPS_NativePreviewOpen";
	constexpr std::string_view CLOSE_EVENT = "OPS_NativePreviewClose";
	constexpr std::string_view ROTATE_EVENT = "OPS_RotatePlayer";
	constexpr std::string_view LIGHT_EVENT = "OPS_TogglePreviewLight";
	constexpr std::string_view MOUSE_CLICK_EVENT = "OPS_NativeMouseClick";
	constexpr std::string_view MOUSE_MOVE_EVENT = "OPS_NativeMouseMove";
	constexpr std::uint32_t LEFT_MOUSE_BUTTON = 0;
	constexpr std::uint32_t RIGHT_MOUSE_BUTTON = 1;
	constexpr float ROTATION_AMOUNT = 0.10f;
	constexpr float TURN_SENSITIVITY = 3.0f;
	constexpr float DEFAULT_MOUSE_WIDTH = 1280.0f;
	constexpr float DEFAULT_MOUSE_HEIGHT = 720.0f;
	constexpr DWORD MOUSE_MOVE_EVENT_INTERVAL_MS = 16;

	std::atomic_bool blurClearQueued = false;

	bool IsProtectedMenu(std::string_view a_menuName)
	{
		return a_menuName == CUSTOM_MENU || a_menuName == CURSOR_MENU;
	}

	bool IsGamepadCancel(const RE::ButtonEvent& a_button)
	{
		if (!a_button.IsDown()) {
			return false;
		}

		const auto id = static_cast<std::uint32_t>(a_button.GetIDCode());
		if (id == static_cast<std::uint32_t>(RE::BSWin32GamepadDevice::Key::kB)) {
			return true;
		}

		const auto* userEvents = RE::UserEvents::GetSingleton();
		const auto& userEvent = a_button.QUserEvent();
		if (userEvents && (userEvent == userEvents->cancel || userEvent == userEvents->tweenMenu)) {
			return true;
		}

		const auto* controls = RE::ControlMap::GetSingleton();
		if (!controls || !userEvents) {
			return false;
		}

		const auto cancelKey = controls->GetMappedKey(
			userEvents->cancel.c_str(), RE::INPUT_DEVICE::kGamepad, RE::UserEvents::INPUT_CONTEXT_ID::kMenuMode);
		const auto tweenKey = controls->GetMappedKey(
			userEvents->tweenMenu.c_str(), RE::INPUT_DEVICE::kGamepad, RE::UserEvents::INPUT_CONTEXT_ID::kGameplay);
		return (cancelKey != RE::ControlMap::kInvalid && id == cancelKey) ||
		       (tweenKey != RE::ControlMap::kInvalid && id == tweenKey);
	}

	void CloseCustomMenu()
	{
		if (auto* messages = RE::UIMessageQueue::GetSingleton()) {
			messages->AddMessage(RE::BSFixedString(CUSTOM_MENU.data()), RE::UI_MESSAGE_TYPE::kHide, nullptr);
		}
	}

	struct NativeMouseState
	{
		float x = DEFAULT_MOUSE_WIDTH * 0.5f;
		float y = DEFAULT_MOUSE_HEIGHT * 0.5f;
		float width = DEFAULT_MOUSE_WIDTH;
		float height = DEFAULT_MOUSE_HEIGHT;
		DWORD lastMoveEventTime = 0;
		bool ready = false;
	};

	NativeMouseState nativeMouse;

	void ClearVanillaMenuBlur()
	{
		if (!Settings::clearMenuBlur) {
			return;
		}

		auto* blur = RE::UIBlurManager::GetSingleton();
		if (!blur) {
			return;
		}

		while (blur->blurCount > 0) {
			blur->DecrementBlurCount();
		}

		blur->blurCount = 0;
	}

	void QueueVanillaMenuBlurClear()
	{
		ClearVanillaMenuBlur();

		auto* tasks = SKSE::GetTaskInterface();
		if (!tasks) {
			return;
		}

		bool expected = false;
		if (!blurClearQueued.compare_exchange_strong(expected, true)) {
			return;
		}

		tasks->AddUITask([] {
			ClearVanillaMenuBlur();
			blurClearQueued.store(false);
		});
	}

	bool ReadWindowCursor(float& a_x, float& a_y, float& a_width, float& a_height)
	{
		POINT point{};
		if (!GetCursorPos(&point)) {
			return false;
		}

		HWND window = GetForegroundWindow();
		if (!window) {
			window = GetActiveWindow();
		}

		RECT client{};
		if (!window || !ScreenToClient(window, &point) || !GetClientRect(window, &client)) {
			return false;
		}

		const long width = client.right - client.left;
		const long height = client.bottom - client.top;
		if (width <= 0 || height <= 0) {
			return false;
		}

		a_x = static_cast<float>(point.x);
		a_y = static_cast<float>(point.y);
		a_width = static_cast<float>(width);
		a_height = static_cast<float>(height);
		return true;
	}

	std::string BuildCursorPayload()
	{
		return std::to_string(nativeMouse.x) + "|" + std::to_string(nativeMouse.y) + "|" +
		       std::to_string(nativeMouse.width) + "|" + std::to_string(nativeMouse.height);
	}

	void SendNativeMouseEvent(std::string_view a_eventName)
	{
		auto* source = SKSE::GetModCallbackEventSource();
		if (!source) {
			return;
		}

		SKSE::ModCallbackEvent event{};
		event.eventName = RE::BSFixedString(a_eventName.data());
		event.strArg = RE::BSFixedString(BuildCursorPayload());
		event.numArg = 0.0f;
		event.sender = nullptr;
		source->SendEvent(&event);
	}

	void SeedNativeMouse()
	{
		float x = 0.0f;
		float y = 0.0f;
		float width = 0.0f;
		float height = 0.0f;
		if (ReadWindowCursor(x, y, width, height)) {
			nativeMouse.x = std::clamp(x, 0.0f, width);
			nativeMouse.y = std::clamp(y, 0.0f, height);
			nativeMouse.width = width;
			nativeMouse.height = height;
		} else {
			nativeMouse.x = DEFAULT_MOUSE_WIDTH * 0.5f;
			nativeMouse.y = DEFAULT_MOUSE_HEIGHT * 0.5f;
			nativeMouse.width = DEFAULT_MOUSE_WIDTH;
			nativeMouse.height = DEFAULT_MOUSE_HEIGHT;
		}

		nativeMouse.lastMoveEventTime = 0;
		nativeMouse.ready = true;
	}

	void ClearNativeMouse()
	{
		nativeMouse.ready = false;
		nativeMouse.lastMoveEventTime = 0;
	}

	void SendNativeMouseClick()
	{
		if (!nativeMouse.ready) {
			SeedNativeMouse();
		}
		float x = 0.0f;
		float y = 0.0f;
		float width = 0.0f;
		float height = 0.0f;
		if (ReadWindowCursor(x, y, width, height)) {
			nativeMouse.x = std::clamp(x, 0.0f, width);
			nativeMouse.y = std::clamp(y, 0.0f, height);
			nativeMouse.width = width;
			nativeMouse.height = height;
		}

		SendNativeMouseEvent(MOUSE_CLICK_EVENT);
	}

	void UpdateNativeMousePosition(const RE::MouseMoveEvent& a_event)
	{
		if (!nativeMouse.ready) {
			SeedNativeMouse();
		}

		float x = 0.0f;
		float y = 0.0f;
		float width = 0.0f;
		float height = 0.0f;
		if (ReadWindowCursor(x, y, width, height)) {
			nativeMouse.x = std::clamp(x, 0.0f, width);
			nativeMouse.y = std::clamp(y, 0.0f, height);
			nativeMouse.width = width;
			nativeMouse.height = height;
		} else {
			nativeMouse.x = std::clamp(
				nativeMouse.x + static_cast<float>(a_event.mouseInputX),
				0.0f,
				nativeMouse.width);
			nativeMouse.y = std::clamp(
				nativeMouse.y + static_cast<float>(a_event.mouseInputY),
				0.0f,
				nativeMouse.height);
		}

		const DWORD now = GetTickCount();
		if (nativeMouse.lastMoveEventTime == 0 || now - nativeMouse.lastMoveEventTime >= MOUSE_MOVE_EVENT_INTERVAL_MS) {
			nativeMouse.lastMoveEventTime = now;
			SendNativeMouseEvent(MOUSE_MOVE_EVENT);
		}
	}
}

EventProcessor& EventProcessor::GetSingleton()
{
	static EventProcessor instance;
	return instance;
}

void EventProcessor::Register()
{
	auto& processor = GetSingleton();

	if (auto* ui = RE::UI::GetSingleton()) {
		ui->AddEventSink<RE::MenuOpenCloseEvent>(
			static_cast<RE::BSTEventSink<RE::MenuOpenCloseEvent>*>(&processor));
		logger::info("[EventProcessor] Registered menu watcher.");
	} else {
		logger::warn("[EventProcessor] Could not register menu watcher.");
	}

	if (auto* source = SKSE::GetModCallbackEventSource()) {
		source->AddEventSink(static_cast<RE::BSTEventSink<SKSE::ModCallbackEvent>*>(&processor));
		logger::info("[EventProcessor] Registered OPS mod-event watcher.");
	} else {
		logger::warn("[EventProcessor] Could not register OPS mod-event watcher.");
	}

	if (auto* input = RE::BSInputDeviceManager::GetSingleton()) {
		input->AddEventSink(static_cast<RE::BSTEventSink<RE::InputEvent*>*>(&processor));
		logger::info("[EventProcessor] Registered native input watcher.");
	} else {
		logger::warn("[EventProcessor] Could not register native input watcher.");
	}
}

void EventProcessor::Unregister()
{
	auto& processor = GetSingleton();

	if (auto* ui = RE::UI::GetSingleton()) {
		ui->RemoveEventSink<RE::MenuOpenCloseEvent>(
			static_cast<RE::BSTEventSink<RE::MenuOpenCloseEvent>*>(&processor));
	}

	if (auto* source = SKSE::GetModCallbackEventSource()) {
		source->RemoveEventSink(static_cast<RE::BSTEventSink<SKSE::ModCallbackEvent>*>(&processor));
	}

	if (auto* input = RE::BSInputDeviceManager::GetSingleton()) {
		input->RemoveEventSink(static_cast<RE::BSTEventSink<RE::InputEvent*>*>(&processor));
	}
}

RE::BSEventNotifyControl EventProcessor::ProcessEvent(
	const RE::MenuOpenCloseEvent* a_event,
	RE::BSTEventSource<RE::MenuOpenCloseEvent>*)
{
	if (!a_event) {
		return RE::BSEventNotifyControl::kContinue;
	}
	if (a_event->menuName != CUSTOM_MENU) {
		if (menuOpen && a_event->opening && Settings::hideOtherUI) {
			const std::string menuName = a_event->menuName.c_str();
			if (auto* tasks = SKSE::GetTaskInterface()) {
				tasks->AddUITask([this, menuName] { HideMenu(menuName); });
			}
		}
		return RE::BSEventNotifyControl::kContinue;
	}

	if (a_event->opening) {
		if (previewRequested) {
			logger::info("[EventProcessor] OPS CustomMenu opened.");
			StartPreview();
		}
		return RE::BSEventNotifyControl::kContinue;
	}

	if (menuOpen) {
		logger::info("[EventProcessor] OPS CustomMenu closed.");
		StopPreview();
	}

	previewRequested = false;
	return RE::BSEventNotifyControl::kContinue;
}

RE::BSEventNotifyControl EventProcessor::ProcessEvent(
	const SKSE::ModCallbackEvent* a_event,
	RE::BSTEventSource<SKSE::ModCallbackEvent>*)
{
	if (!a_event) {
		return RE::BSEventNotifyControl::kContinue;
	}

	if (a_event->eventName == OPEN_EVENT) {
		RequestPreview();
	} else if (a_event->eventName == CLOSE_EVENT) {
		StopPreview();
		previewRequested = false;
	} else if (a_event->eventName == ROTATE_EVENT && menuOpen) {
		const float direction = a_event->numArg >= 0.0f ? -1.0f : 1.0f;
		RotatePreview(direction);
	} else if (a_event->eventName == LIGHT_EVENT && menuOpen) {
		MenuCamera::GetSingleton().SetPreviewLight(a_event->numArg > 0.0f);
	}

	return RE::BSEventNotifyControl::kContinue;
}

RE::BSEventNotifyControl EventProcessor::ProcessEvent(
	RE::InputEvent* const* a_event,
	RE::BSTEventSource<RE::InputEvent*>*)
{
	if (!a_event || !menuOpen || !MenuCamera::GetSingleton().IsActive()) {
		return RE::BSEventNotifyControl::kContinue;
	}

	for (auto* event = *a_event; event; event = event->next) {
		switch (event->GetEventType()) {
		case RE::INPUT_EVENT_TYPE::kButton:
			{
				auto* button = event->AsButtonEvent();
				if (event->GetDevice() == RE::INPUT_DEVICE::kGamepad && button && IsGamepadCancel(*button)) {
					CloseCustomMenu();
					return RE::BSEventNotifyControl::kContinue;
				}
				if (event->GetDevice() == RE::INPUT_DEVICE::kMouse) {
					if (button) {
						const auto mouseButton = static_cast<std::uint32_t>(button->GetIDCode());
						if (button->IsDown() && mouseButton == LEFT_MOUSE_BUTTON) {
							SendNativeMouseClick();
						}
						allowRotation = mouseButton == RIGHT_MOUSE_BUTTON && button->IsPressed();
					} else {
						allowRotation = false;
					}
				}
			}
			break;
		case RE::INPUT_EVENT_TYPE::kMouseMove:
			{
				auto* mouse = reinterpret_cast<RE::MouseMoveEvent*>(event->AsIDEvent());
				if (mouse) {
					UpdateNativeMousePosition(*mouse);
				}
				if (allowRotation && mouse && std::abs(mouse->mouseInputX) >= TURN_SENSITIVITY) {
					RotatePreview(mouse->mouseInputX > 0 ? -1.0f : 1.0f);
				}
			}
			break;
		case RE::INPUT_EVENT_TYPE::kThumbstick:
			{
				auto* stick = reinterpret_cast<RE::ThumbstickEvent*>(event->AsIDEvent());
				if (stick && stick->IsRight() && std::abs(stick->xValue) > 0.15f && std::abs(stick->yValue) < 0.75f) {
					RotatePreview(stick->xValue > 0.0f ? -1.0f : 1.0f);
				}
			}
			break;
		default:
			break;
		}
	}

	return RE::BSEventNotifyControl::kContinue;
}

void EventProcessor::RequestPreview()
{
	previewRequested = true;
	Settings::Load();

	if (!Settings::enabled) {
		logger::info("[EventProcessor] Preview requested, but native camera is disabled.");
		return;
	}

	if (auto* ui = RE::UI::GetSingleton(); ui && ui->IsMenuOpen(CUSTOM_MENU)) {
		StartPreview();
	}
}

void EventProcessor::StartPreview()
{
	if (!Settings::enabled) {
		return;
	}

	menuOpen = true;
	SeedNativeMouse();
	HideOtherMenus();
	QueueVanillaMenuBlurClear();

	if (MenuCamera::GetSingleton().IsActive()) {
		MenuCamera::GetSingleton().ApplySettings();
	} else {
		MenuCamera::GetSingleton().Start();
	}

	QueueVanillaMenuBlurClear();
}

void EventProcessor::StopPreview()
{
	if (!menuOpen && !MenuCamera::GetSingleton().IsActive()) {
		return;
	}

	MenuCamera::GetSingleton().Stop();
	RestoreOtherMenus();
	menuOpen = false;
	allowRotation = false;
	ClearNativeMouse();
	QueueVanillaMenuBlurClear();
}

void EventProcessor::HideOtherMenus()
{
	if (!Settings::hideOtherUI) {
		return;
	}
	auto* ui = RE::UI::GetSingleton();
	if (!ui) {
		return;
	}
	for (auto& [name, entry] : ui->menuMap) {
		if (IsProtectedMenu(name.c_str()) || !entry.menu || !entry.menu->uiMovie) {
			continue;
		}
		if (entry.menu->uiMovie->GetVisible()) {
			entry.menu->uiMovie->SetVisible(false);
			hiddenMenus.push_back(name);
		}
	}
	logger::info("[EventProcessor] Temporarily hid {} other UI movies.", hiddenMenus.size());
}

void EventProcessor::HideMenu(std::string_view a_menuName)
{
	if (!Settings::hideOtherUI || IsProtectedMenu(a_menuName)) {
		return;
	}
	const auto alreadyHidden = std::find_if(hiddenMenus.begin(), hiddenMenus.end(), [&](const auto& name) {
		return std::string_view(name.c_str()) == a_menuName;
	});
	if (alreadyHidden != hiddenMenus.end()) {
		return;
	}
	if (auto* ui = RE::UI::GetSingleton()) {
		auto movie = ui->GetMovieView(a_menuName);
		if (movie && movie->GetVisible()) {
			movie->SetVisible(false);
			hiddenMenus.emplace_back(a_menuName);
		}
	}
}

void EventProcessor::RestoreOtherMenus()
{
	auto* ui = RE::UI::GetSingleton();
	if (ui) {
		for (const auto& name : hiddenMenus) {
			auto movie = ui->GetMovieView(name.c_str());
			if (movie) {
				movie->SetVisible(true);
			}
		}
	}
	if (!hiddenMenus.empty()) {
		logger::info("[EventProcessor] Restored {} UI movies.", hiddenMenus.size());
	}
	hiddenMenus.clear();
}

void EventProcessor::RotatePreview(float a_direction)
{
	auto* player = RE::PlayerCharacter::GetSingleton();
	auto* camera = RE::PlayerCamera::GetSingleton();
	if (!player || !camera || !player->Is3DLoaded()) {
		return;
	}

	auto* thirdState = static_cast<RE::ThirdPersonState*>(camera->currentState.get());
	if (!thirdState) {
		return;
	}

	player->SetRotationZ(player->data.angle.z + (a_direction * ROTATION_AMOUNT));
	thirdState->freeRotation.x -= (a_direction * ROTATION_AMOUNT);
	player->Update3DPosition(true);
	camera->Update();
}
