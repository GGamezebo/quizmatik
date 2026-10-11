# CrazyGames и Poki: выход на порталы

Обновлено: 2026-10-11. Код готов, осталось собрать билды, подать заявки и проверить на их тестовых стендах.

## Что сделано в коде

| Что | Где |
|---|---|
| Ветки HFSM `WEB/CrazyGames` и `WEB/Poki` | `src/game/hfsm/app_hfsm.json`, регистрация в `main.gd` |
| Выбор ветки по фиче экспорта `crazygames` / `poki` | `web_context.gd` |
| CrazyGames: загрузка, gameplayStart/Stop | `crazygames_context.gd` |
| CrazyGames: реклама midgame + rewarded | `crazygames_shop_context.gd` |
| CrazyGames: облачное сохранение (`SDK.data`) | `crazygames_cloud_save_context.gd` |
| Poki: gameLoadingFinished, gameplayStart/Stop | `poki_context.gd` |
| Poki: commercialBreak / rewardedBreak | `poki_shop_context.gd` |
| Общая база «магазин только с рекламой» | `ads_only_shop_context.gd` |
| Пресеты экспорта `Web-CrazyGames`, `Web-Poki` | `export_presets.cfg` (SDK-скрипт в `head_include`) |

`PlatformServices` и игровая часть не менялись. Покупок на порталах нет: `offer_kind` пустой, золото даёт только rewarded-реклама (лимит 5 в день на устройство из `App/Monetization`). Облачного сохранения у Poki нет, прогресс остаётся локальным.

## Требования порталов

**CrazyGames** ([требования](https://docs.crazygames.com/requirements/intro/), [реклама](https://docs.crazygames.com/requirements/ads/)):
- Basic Launch: первая загрузка ≤ 50 МБ, всего ≤ 250 МБ, ≤ 1500 файлов, без внешних ссылок и своей рекламы. Реклама в этой фазе выключена (приходит `adError` с кодом `adsDisabledBasicLaunch`), игра должна работать и так.
- Full Launch: SDK и событие gameplayStart обязательны, реклама только через SDK.
- Midgame реклама не чаще раза в 3 минуты (режет сам SDK); не на кнопках навигации вроде «в меню»; кнопка rewarded не на экране активной игры; награда только по `adFinished`, при `adError` не выдавать.
- Для rewarded нужна альтернатива получения награды: у нас золото зарабатывается боями.
- До геймплея ≤ 20 с, только относительные пути.

**Poki** ([SDK](https://developers.poki.com/guide/sdk-html5)):
- `PokiSDK.init()` не должен блокировать игру при ошибке (у нас не блокирует).
- `gameLoadingFinished`, `gameplayStart`, `gameplayStop` обязательны, на время рекламы нужно заглушить звук и ввод (делает `PokiShopContext`).
- Подробные правила и лимиты размера смотрите в «Requirements & policies» в кабинете Poki; на момент написания страница SDK их не перечисляла.

## Что нужно проверить вручную (я не мог)

1. Гейм-экспорт `Web-CrazyGames` / `Web-Poki` в Godot и размер: у обоих порталов жёсткие лимиты. Если билд больше 50 МБ, смотрите размер `.pck` и `.wasm`.
2. CrazyGames: `SDK.data.getItem/setItem` я описал по документации и памяти (синхронные, строка в строку). Страницу data мне открыть не удалось, проверьте на тестовом стенде («Preview» в кабинете).
3. Interstitial у нас показывается при возврате в меню после боя (`App/Monetization`). У CrazyGames это допустимо как «после уровня», но на главном меню без боя реклама не идёт. Если QA придерётся, поднимите `interstitial_min_battles`.
4. Языки: порталы не отдают язык через `PlatformServices.language`, будет язык ОС/браузера и выбор в настройках.
5. Ссылки на политику конфиденциальности в игре: CrazyGames не принимает внешние ссылки в Basic Launch. Проверьте, что в игре нет кликабельных внешних ссылок.

## Порядок действий

1. CrazyGames: зарегистрироваться на [developer.crazygames.com](https://developer.crazygames.com), создать игру, загрузить zip из `bin/crazygames/` (все файлы с `index.html` в корне архива), пройти Basic Launch, затем Full Launch (включается реклама).
2. Poki: подать заявку через форму разработчика на [developers.poki.com](https://developers.poki.com); после одобрения вам дадут кабинет и тестовый стенд для загрузки билда `bin/poki/`.
3. Тестерам и модерации без денег: добавить `no_monetization` в Custom Features пресета.
4. Следить за D1/D7 и доходом с рекламы, сравнивая с Яндексом.
