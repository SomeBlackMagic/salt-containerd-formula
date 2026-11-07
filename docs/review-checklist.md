# Чеклист разработки и ревью Salt Formula

Этот документ — инструкция агенту. Общение с пользователем на русском; тексты, создаваемые в репозитории, на английском.

## Перед разработкой

- [ ] Подтверждены целевые версии Salt и ОС либо явно указано, что они неизвестны.
- [ ] Изучены `map.jinja`, `parameters/`, `files/`, `pillar.example`, SLS, тесты и CI.
- [ ] Названы ресурсы компонента, их владельцы, lifecycle и безопасные условия удаления.
- [ ] Отдельно определены mandatory и optional states.
- [ ] Проверена необходимость нового state/module vs built-in state.

## Код

- [ ] Каждый SLS доступен по понятному имени и имеет уникальные state IDs.
- [ ] `init.sls` только композирует нужное и не делает cleanup.
- [ ] В конфигурационных файлах выставляются безопасные owner/group/mode.
- [ ] Преобразования Jinja корректно дают YAML с требуемыми типами.
- [ ] Нет побочных эффектов при Jinja rendering.
- [ ] Правильно выбраны `require`, `watch`, `listen`, `onchanges` и обратные варианты.
- [ ] Обновления конфигурации не порождают лишних restart/reload.
- [ ] Не происходит удаления неуправляемых ресурсов.
- [ ] Pillar overrides поддерживают существующий контракт, нет тихих изменений precedence.
- [ ] Расширения MapStack и TOFS следуют структуре проекта.
- [ ] Нет hardcoded secrets или чувствительных diff.

## Тестовая матрица

| Scenario | Expected result |
| --- | --- |
| Fresh apply | All owned resources reach desired state |
| Repeat apply | No unexpected changes |
| Config modification | Expected file change and controlled reload/restart |
| Unrelated change | No restart |
| Pillar override | Correct final values and types |
| Unsupported OS | Documented failure/skip, not a silent wrong mapping |
| Component only | No unintended optional components |
| Cleanup | Only owned resources are removed |
| Salt test mode | No mutating actions during dry run |
| Invalid configuration | Detect failure without silently reporting success |

## Что считать доказательством

- `passed`: команда действительно запущена; есть результат и exit code.
- `failed`: команда запущена, тест завершился ошибкой; приведена причина.
- `not run`: проверка не выполнялась.
- `blocked`: инфраструктура или зависимости не позволили выполнить проверку.

Для интеграционных тестов указывай конкретные платформу и версию Salt. Для idempotency проверяй output повторного реального converge, а не только успешную компиляцию.

## Перед передачей результата

- [ ] Англоязычная документация перечисляет все публичные states и опции Pillar.
- [ ] Есть migration notes при несовместимом изменении API.
- [ ] Приведены только подтверждённые результаты проверки.
- [ ] Нет ненужных правок в unrelated файлах.
- [ ] Изменения минимальны и повторяют conventions конкретной формулы.
