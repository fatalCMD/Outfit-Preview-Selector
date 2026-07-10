#pragma once

#include "RE/Skyrim.h"
#include "SKSE/SKSE.h"

#include <Windows.h>
#include <spdlog/sinks/basic_file_sink.h>

#include <algorithm>
#include <atomic>
#include <cctype>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <memory>
#include <string>
#include <string_view>
#include <utility>

namespace logger = SKSE::log;
using namespace std::literals;
