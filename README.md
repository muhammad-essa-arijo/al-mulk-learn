<div align="center">

# 🌙 Al-Mulk Learn

### Learn to *understand* Surah Al-Mulk, word by word. Completely offline.

<br>

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Offline](https://img.shields.io/badge/100%25-Offline-2E7D5B?style=for-the-badge)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Web](https://img.shields.io/badge/Chrome-Web-C9A24B?style=for-the-badge&logo=googlechrome&logoColor=white)

![Languages](https://img.shields.io/badge/UI-English%20%7C%20اردو-1B7F5C?style=flat-square)
![Surah](https://img.shields.io/badge/Surah-67%20%C2%B7%2030%20ayahs-C9A24B?style=flat-square)
![Storage](https://img.shields.io/badge/Storage-shared__preferences-5B8DEF?style=flat-square)
![No internet permission](https://img.shields.io/badge/Release-no%20INTERNET%20permission-E07A5F?style=flat-square)

</div>

---

## ✨ About

**Al-Mulk Learn** is a study app for students who want to go beyond reading and
actually understand **Surah Al-Mulk** (Surah 67, 30 ayahs). Every word can be
tapped to see its meaning, root and grammar. Around that sit audio, quizzes,
flashcards and memorization tools.

Everything is bundled inside the app. There are no servers, no accounts and no
network calls, so it works in a classroom, on a plane, or anywhere without
signal.

The app opens in a bright **cream, emerald and gold** theme.

---

## 📖 Features

| | |
|---|---|
| 📚 **Reader** | Bismillah header, plain or word-by-word view, adjustable text size and spacing |
| 🔍 **Word details** | Meaning, transliteration, root, lemma, grammar breakdown and other words from the same root |
| 🌿 **Grammar panel** | Every word of an ayah explained in simple English or Urdu |
| 💡 **Explanation** | Word-by-word explanation built from the app's own data, with a slot ready for tafseer |
| 🎧 **Audio** | Mini player with play all, repeat, speed control and a highlighted ayah |
| 🧠 **Quizzes** | 6 quiz types, built from the real surah data |
| 🃏 **Flashcards** | Leitner boxes (1 to 5) so hard words come back sooner |
| 🕌 **Memorization mode** | Practise ayah by ayah |
| 📊 **Progress** | Dashboard, daily goal, streak, weak words and 15 badges |
| 🔖 **Study tools** | Bookmarks, personal notes, search and a vocabulary builder |
| 🖼️ **Share** | Share an ayah as an image |
| ⚙️ **Settings** | Themes, text sizes, translations, daily reminder, backup and restore |

**Languages:** English and Urdu (the Urdu layout is fully right-to-left).
**Themes:** Light (default), Sepia, Soft Blue and Dark.

---

## 🚀 Getting started

You need [Flutter](https://docs.flutter.dev/get-started/install) installed.

```bash
# 1. Download the packages
flutter pub get

# 2. Run the tests
flutter test

# 3. Run in Chrome
flutter run -d chrome
```

### 📦 Build the Android APK

**On your computer**

```bash
flutter build apk --release
```

The file appears at `build/app/outputs/flutter-apk/app-release.apk`.

**With GitHub Actions**

This repository includes `.github/workflows/build.yml`.

1. Open the **Actions** tab.
2. Choose **Build APK** and press **Run workflow** (it also runs on every push to `main`).
3. When it finishes, download **app-release** from the *Artifacts* section.

---

## 🔒 Offline and privacy

- The Quran data, 30 audio files and fonts are all inside the app.
- The release build asks for **no internet permission**. The `INTERNET`
  permission exists only in the debug and profile manifests, which Flutter
  needs for development.
- Your progress, notes, bookmarks and settings stay on your device, stored with
  `shared_preferences`.
- No SQLite and no accounts.

To check it yourself, open the merged release manifest and confirm that
`android.permission.INTERNET` is not listed.

---

## 🗂️ Project structure

```
lib/
├── main.dart          Starts the app and creates the shared controllers
├── app/               Themes
├── core/              Plain logic: grammar parser, quiz generator,
│                      spaced repetition, streak, strings (EN / UR)
├── data/              Models, quran_repository, user_data_store
├── features/          One folder per screen group
│   ├── reader/  word_detail/  audio/  search/  bookmarks/
│   ├── vocabulary/  flashcards/  quiz/  memorization/
│   └── progress/  achievements/  settings/  credits/  home/
└── widgets/           Small shared widgets
test/                  Unit tests
assets/                quran.json, audio/, fonts/
```

**State management:** `provider`. Each controller keeps its own data in
`shared_preferences`.

---

## 🧾 Data format

The surah lives in `assets/quran.json`:

```json
{
  "surah": "Al-Mulk",
  "number": 67,
  "ayahs": [
    {
      "number": 1,
      "arabic": "...",
      "translations": { "en": "...", "ur": "..." },
      "tafseer": { "en": "..." },
      "words": [
        {
          "position": 1,
          "arabic": "...",
          "translit": "...",
          "meaning": "...",
          "root": "...",
          "lemma": "...",
          "pos": "V",
          "grammar": "..."
        }
      ]
    }
  ]
}
```

> The Arabic text is shown exactly as it appears in the data. It is never
> edited by the app.

---

## 🔧 Adding more content later

**Tafseer**
Add a `"tafseer"` object to an ayah, for example `"tafseer": { "en": "..." }`.
The Explanation section shows it automatically. Until then, the section shows a
word-by-word explanation made from the existing word data. Only use a licensed,
reliable source and credit it.

**Sindhi translation**
1. Add `"sd": "..."` inside `translations` for every ayah.
2. Sindhi then appears in Settings under Translations.
3. For Sindhi interface text, add an `'sd'` map in `lib/core/strings.dart`.

---

## ⚠️ Current limits

- **No tajweed colours.** The data has no tajweed information.
- **Ayah-level highlighting only.** Highlighting each word while audio plays
  would need word timing data.
- **Word meanings are in English only.** There is no Urdu or Sindhi word data,
  and none was made up.
- **One reciter:** Mishary Rashid Alafasy.
- **Reminders and image sharing work on Android.** On Chrome the app shows a
  message or a copy-text option instead.
- **No scholarly tafseer is included.** See the section above.

---

## 🙏 Credits

| For | Source |
|---|---|
| Arabic text and translations | [AlQuran Cloud](https://alquran.cloud). English: Saheeh International. Urdu: Fateh Muhammad Jalandhry |
| Word meanings and transliteration | [Quran.com](https://quran.com) (Quran Foundation) |
| Grammar, roots and morphology | [The Quranic Arabic Corpus](https://corpus.quran.com), Kais Dukes, University of Leeds |
| Audio recitation | Mishary Rashid Alafasy via [EveryAyah.com](https://everyayah.com) |
| Fonts | Amiri Quran, Noto Nastaliq Urdu and Inter, all under the SIL Open Font License 1.1 |

The full list is also inside the app under **Settings → Credits and licenses**.

---

## 📜 License note

The Quranic Arabic Corpus data is released under the **GNU General Public
License**. If you plan to publish this app, read that license first. Check the
terms of the other sources too.

---

<div align="center">

Made with care for students of the Qur'an 🤍

</div>
