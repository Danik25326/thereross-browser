// =============================================================================
// TRS Browser — ua_shield.cc
// UA Shield: блокування RU-доменів, пропагандистського контенту,
// ворожих трекерів і фішингових сайтів.
//
// Як це працює:
//   1. При старті завантажуємо списки доменів з shield/blocklists/
//   2. Chromium викликає ShouldBlockRequest() перед кожним запитом
//   3. Якщо домен у списку — блокуємо з поясненням
// =============================================================================

#include "trs/shield/ua_shield.h"

#include <fstream>
#include <sstream>

#include "base/files/file_path.h"
#include "base/logging.h"
#include "base/strings/string_util.h"
#include "content/public/browser/browser_thread.h"
#include "net/base/registry_controlled_domains/registry_controlled_domain.h"

namespace trs {

UAShield::UAShield() : enabled_(false) {}
UAShield::~UAShield() = default;

void UAShield::Enable() {
  enabled_ = true;
  LOG(INFO) << "[TRS Shield] Активовано. Заблоковано категорій: "
            << blocklists_.size();
}

void UAShield::Disable() {
  enabled_ = false;
  LOG(INFO) << "[TRS Shield] Вимкнено";
}

void UAShield::LoadBlocklists() {
  // Завантажуємо списки з вбудованих ресурсів
  // У продакшні — оновлення через CDN кожні 24 год
  LoadListFromFile("ru_propaganda", GetBuiltinRUDomains());
  LoadListFromFile("trackers",      GetBuiltinTrackers());
  LoadListFromFile("phishing",      GetBuiltinPhishingList());

  LOG(INFO) << "[TRS Shield] Завантажено " << total_blocked_domains_
            << " доменів у " << blocklists_.size() << " категоріях";
}

void UAShield::LoadListFromFile(const std::string& category,
                                 const std::vector<std::string>& domains) {
  auto& list = blocklists_[category];
  for (const auto& domain : domains) {
    if (!domain.empty() && domain[0] != '#') {  // # — коментар
      list.insert(base::ToLowerASCII(domain));
      total_blocked_domains_++;
    }
  }
}

UAShield::BlockResult UAShield::ShouldBlockRequest(const GURL& url) {
  if (!enabled_) return BlockResult::kAllow;

  std::string host = url.host();
  if (host.empty()) return BlockResult::kAllow;

  // Перевіряємо кожну категорію
  for (const auto& [category, domains] : blocklists_) {
    if (IsInBlocklist(host, domains)) {
      LogBlock(url, category);
      return BlockResult::kBlock;
    }
  }

  return BlockResult::kAllow;
}

bool UAShield::IsInBlocklist(const std::string& host,
                              const std::unordered_set<std::string>& list) {
  // Перевіряємо і точний домен, і батьківські домени
  // наприклад: sub.rt.com → перевіряємо sub.rt.com, rt.com, com
  std::string check_host = base::ToLowerASCII(host);

  while (!check_host.empty()) {
    if (list.count(check_host)) return true;

    auto dot_pos = check_host.find('.');
    if (dot_pos == std::string::npos) break;
    check_host = check_host.substr(dot_pos + 1);
  }

  return false;
}

void UAShield::LogBlock(const GURL& url, const std::string& category) {
  blocked_count_++;
  VLOG(1) << "[TRS Shield] Заблоковано [" << category << "]: " << url.host();
}

// =============================================================================
// Вбудовані списки (мінімальний набір для старту)
// У продакшні — завантажувати з github.com/thereross-browser/trs-shield/lists/
// =============================================================================

std::vector<std::string> UAShield::GetBuiltinRUDomains() {
  return {
    // Державні пропагандистські ЗМІ РФ
    "rt.com", "rt.ru",
    "russia-1.ru",
    "vesti.ru",
    "ria.ru", "ria-novosti.ru",
    "tass.ru", "tass.com",
    "1tv.ru",
    "ntv.ru",
    "sputnik.ru", "sputniknews.com",
    "rg.ru",
    "rossiyskayagazeta.ru",
    "tvzvezda.ru",
    "life.ru",
    "rbc.ru",        // вилучено з редакції у 2022
    "gazeta.ru",
    "iz.ru",         // Известия
    "msk.ru",
    "argumenti.ru",
    // Соціальні мережі РФ заблоковані в Україні
    "vk.com", "vkontakte.ru",
    "ok.ru", "odnoklassniki.ru",
    "mail.ru", "bk.ru", "inbox.ru", "list.ru",
    // Додавай більше через trs-shield репо
  };
}

std::vector<std::string> UAShield::GetBuiltinTrackers() {
  return {
    // Відомі трекери
    "mc.yandex.ru",
    "metrika.yandex.ru",
    "yandex-team.ru",
    "counter.yadro.ru",
    // Додавай через lists/trackers.txt
  };
}

std::vector<std::string> UAShield::GetBuiltinPhishingList() {
  return {
    // Відомі фішингові домени (приклад)
    // Реальний список — через Safe Browsing + власні звіти
  };
}

}  // namespace trs
