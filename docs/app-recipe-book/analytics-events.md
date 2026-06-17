# Analytics Events

**Naming convention:** `snake_case`, `verb_noun` pattern where applicable. All event and parameter names are lower-snake-case strings. Define them as Dart constants (`static const String appOpen = 'app_open'`) in a central `AnalyticsEvents` class to prevent typos across the codebase.

**Default sink:** `firebase_analytics` (initialized in `bootstrap.dart`, routed through `FirebaseAnalyticsObserver` added to `auto_route`'s router observers). Swap for PostHog or Mixpanel by changing the analytics service implementation behind a Riverpod provider — the event taxonomy below is sink-agnostic.

**PII rule:** Never log personal identifiable information (email, full name, phone number, precise location) as event parameters. Use anonymized user IDs (Firebase UID or an internal UUID) where user identity is needed. Log codes, counts, and categories — not user content.

---

## Core events (all apps)

These events apply regardless of app type. Every app implementing this recipe book should fire all of them.

| Event | When to fire | Key parameters |
|---|---|---|
| `app_open` | Cold start (first frame after launch from killed state) | `source` (notification / deep_link / organic), `is_first_open` (bool) |
| `screen_view` | Every route change (auto-fired by `FirebaseAnalyticsObserver` if wired) | `screen_name`, `screen_class` |
| `sign_up` | User completes registration (account created) | `method` (email / google / apple) |
| `login` | User completes authentication (existing account) | `method` (email / google / apple) |
| `logout` | User explicitly signs out | _(none)_ |
| `error_shown` | A user-facing error message is displayed | `error_code`, `screen_name`, `is_recoverable` (bool) |
| `settings_changed` | User modifies a setting | `setting_key`, `setting_value` (use a string; avoid booleans that encode PII) |
| `onboarding_started` | First screen of onboarding shown | _(none)_ |
| `onboarding_completed` | User reaches end of onboarding and enters the app | `time_spent_seconds` |
| `onboarding_skipped` | User explicitly skips onboarding | `step_skipped_at` (int — which step index) |
| `permission_requested` | System permission dialog triggered | `permission_type` (notifications / camera / location) |
| `permission_granted` | User grants a permission | `permission_type` |
| `permission_denied` | User denies a permission | `permission_type` |

**Implementation note:** `screen_view` is typically automatic when `FirebaseAnalyticsObserver` is added to the `auto_route` router. Verify it fires correctly after adding the observer — check the Firebase DebugView in the console.

---

## Utility / tools

Apps where users perform discrete actions with a tool (converter, calculator, scanner, generator). The core analytics question: "Is the tool being used and producing successful results?"

| Event | When to fire | Key parameters |
|---|---|---|
| `tool_run` | User invokes the primary tool action | `tool_name` (string slug of the tool), `result` (success / error / empty) |
| `tool_result_shared` | User shares or exports a tool result | `tool_name`, `share_target` (system_share / copy / save) |
| `tool_input_cleared` | User clears/resets tool input | `tool_name` |
| `ad_watched` | User watches a rewarded ad to unlock something | `reward_type` (extra_use / unlock / remove_ads_temp) |
| `paywall_shown` | Premium paywall is displayed | `trigger_screen` |
| `one_time_purchase_completed` | One-time unlock IAP completed | `product_id`, `price_micros`, `currency` |

**Key funnels to monitor:** `app_open` → `tool_run` → `tool_result_shared` (measures core value delivery). `paywall_shown` → `one_time_purchase_completed` (measures monetization conversion).

---

## Content / feed

Apps where the primary loop is browsing, reading, or viewing content (news, blog, media, social feed). The core analytics question: "What content is consumed and shared, and how long do users engage?"

| Event | When to fire | Key parameters |
|---|---|---|
| `content_view` | A piece of content is opened/displayed | `content_id`, `content_type` (article / video / post), `content_category`, `is_sponsored` (bool) |
| `content_read_completed` | User scrolls to end of article or watches full video | `content_id`, `read_time_seconds` |
| `content_share` | User shares content externally | `content_id`, `share_target` (system_share / copy_link / social_platform) |
| `content_saved` | User saves/bookmarks content | `content_id`, `content_type` |
| `content_liked` | User likes/reacts to content | `content_id`, `reaction_type` |
| `search_performed` | User submits a search query | `query_length` (int — do NOT log the query itself if it could contain PII), `results_count` |
| `search_result_tapped` | User taps a search result | `result_position` (int), `content_id` |
| `feed_refreshed` | User manually pulls-to-refresh the feed | `feed_type` (home / trending / following) |
| `notification_tapped` | User opens app from a push notification | `notification_type`, `content_id` |
| `paywall_shown` | Subscription paywall displayed (for subscription-gated content) | `trigger` (content_limit_reached / premium_content_tap) |

**Key funnels to monitor:** `app_open` → `content_view` → `content_read_completed` (measures content quality). `search_performed` → `search_result_tapped` → `content_view` (measures search effectiveness).

---

## Productivity / notes

Apps where users create, organize, and complete tasks or notes (to-do apps, note-takers, project trackers). The core analytics question: "Are users completing their core productivity loop — creating, organizing, and marking done?"

| Event | When to fire | Key parameters |
|---|---|---|
| `item_created` | User creates a new item (note, task, project) | `item_type` (note / task / project / list), `creation_method` (manual / template / voice) |
| `item_updated` | User modifies an existing item | `item_type`, `fields_changed` (comma-separated field names, no content) |
| `item_deleted` | User deletes an item | `item_type`, `was_completed` (bool for tasks) |
| `item_completed` | User marks a task/item as done | `item_type`, `time_to_complete_hours` (int, optional) |
| `item_reopened` | User reopens a completed item | `item_type` |
| `sync_completed` | Cloud sync cycle finishes | `direction` (upload / download / bidirectional), `items_synced` (int), `duration_ms` (int) |
| `sync_failed` | Cloud sync fails | `error_code`, `items_pending` (int) |
| `export_performed` | User exports data | `format` (pdf / csv / json / markdown) |
| `widget_used` | Home screen widget interacted with | `widget_type`, `action` (create / view) |
| `reminder_set` | User sets a reminder on an item | `item_type`, `reminder_offset_minutes` (int) |
| `search_performed` | User searches within their items | `query_length` (int), `results_count` (int) |

**Key funnels to monitor:** `item_created` → `item_completed` (measures core productivity loop). `sync_failed` rate (measures reliability). D7 and D30 `item_created` (measures habit formation).

---

## Subscription / SaaS / AI

Apps where the core business model is a recurring subscription, often with AI-powered features. The core analytics questions: "Where does the paywall convert? What is the AI feature utilization? Are costs controlled?"

| Event | When to fire | Key parameters |
|---|---|---|
| `paywall_view` | Subscription paywall is displayed | `paywall_variant` (A/B test variant), `trigger` (onboarding / feature_gate / upgrade_prompt / manual) |
| `paywall_dismissed` | User closes paywall without purchasing | `paywall_variant`, `time_on_paywall_seconds` (int) |
| `purchase_started` | User taps a subscription offer | `sku` (product identifier), `offer_type` (trial / introductory / standard), `paywall_variant` |
| `purchase_completed` | RevenueCat purchase confirmed with active entitlement | `sku`, `period` (monthly / annual / lifetime), `revenue_usd` (float, use RevenueCat's value) |
| `purchase_failed` | Purchase attempt fails | `sku`, `error_code`, `error_message` |
| `subscription_cancelled` | User cancels subscription (via RevenueCat webhook event → analytics) | `sku`, `days_subscribed` (int) |
| `trial_started` | Free trial begins | `sku`, `trial_days` (int) |
| `trial_converted` | Trial user converts to paid | `sku` |
| `trial_expired_no_convert` | Trial ends without conversion | `sku`, `trial_days_used` (int) |
| `ai_request` | User submits a prompt or AI action | `feature` (summarize / generate / chat / analyze), `model` (string, e.g. claude-3-5-sonnet), `input_tokens` (int), `is_streaming` (bool) |
| `ai_response_received` | AI response completes | `feature`, `model`, `output_tokens` (int), `latency_ms` (int), `was_error` (bool) |
| `ai_response_copied` | User copies or saves the AI output | `feature` |
| `feature_gate_hit` | User hits a usage limit or paywall feature gate | `feature_name`, `remaining_uses` (int) |
| `upgrade_prompt_shown` | In-context upgrade prompt displayed | `prompt_location`, `feature_name` |

**Key funnels to monitor:** `paywall_view` → `purchase_started` → `purchase_completed` (measures paywall CVR). `trial_started` → `trial_converted` (measures trial-to-paid). `ai_request` + `ai_response_received` aggregate: monitor average tokens per request and cost-per-DAU to catch runaway AI spend early.

**Cost monitoring note:** Combine `ai_request` events with server-side token logging for accurate cost attribution per user. Analytics events give you product signal (what features are used); server logs give you billing signal. Both are needed for AI-powered apps.
