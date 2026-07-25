#!/usr/bin/env python3
"""Transform the Gym visual exercises dataset into gymapp's bundled catalog.

Reads a local checkout/extract of github.com/hasaneyldrm/exercises-dataset
(pinned commit: see PINNED_COMMIT) and emits:

  gymapp/Resources/exercise-catalog.json      slimmed catalog (en/es)
  gymapp/Resources/ExerciseThumbnails/*.jpg   thumbnails renamed by exercise id
  gymapp/Resources/legacy-mapping.json        copy of the migration table

Usage:
  python3 tools/catalog/transform.py <dataset-dir> [<repo-root>]

<dataset-dir> must contain data/exercises.json and images/.
Run once per dataset upgrade; outputs are checked in.
"""

import json
import re
import shutil
import sys
from pathlib import Path

PINNED_COMMIT = "118e4bd6b14da6df0e36605d7169b65db18389a4"
CATALOG_VERSION = 1
LANGS = ("en", "es")

# Dataset target/secondary vocabulary -> gymapp Muscle raw values.
MUSCLE_MAP = {
    "abductors": "glutes",
    "abs": "abs",
    "adductors": "quads",
    "biceps": "biceps",
    "calves": "calves",
    "cardiovascular system": "full_body",
    "delts": "shoulders",
    "forearms": "forearms",
    "glutes": "glutes",
    "hamstrings": "hamstrings",
    "lats": "lats",
    "levator scapulae": "traps",
    "pectorals": "chest",
    "quads": "quads",
    "serratus anterior": "chest",
    "spine": "lower_back",
    "traps": "traps",
    "triceps": "triceps",
    "upper back": "back",
    # extra values that appear only in secondary_muscles
    "lower back": "lower_back",
    "core": "abs",
    "obliques": "obliques",
    "shoulders": "shoulders",
    "chest": "chest",
    "back": "back",
    "hip flexors": "quads",
    "rotator cuff": "shoulders",
    "rear deltoids": "shoulders",
    "deltoids": "shoulders",
    "front deltoids": "shoulders",
    "rhomboids": "back",
    "erector spinae": "lower_back",
    "soleus": "calves",
    "gastrocnemius": "calves",
    "quadriceps": "quads",
    "grip muscles": "forearms",
    "wrist extensors": "forearms",
    "wrist flexors": "forearms",
    "wrists": "forearms",
    "ankle stabilizers": "calves",
    "ankles": "calves",
    "feet": "calves",
    "shins": "calves",
    "brachialis": "biceps",
    "brachioradialis": "forearms",
    "sternocleidomastoid": "traps",
    "levator scapulae ": "traps",
    "neck": "traps",
    "upper traps": "traps",
    "lower traps": "traps",
    "serratus": "chest",
    "inner thighs": "quads",
    "groin": "quads",
    "hip abductors": "glutes",
    "hip adductors": "quads",
    "cardiovascular": "full_body",
    "full body": "full_body",
    "spinal erectors": "lower_back",
    "trapezius": "traps",
    "latissimus dorsi": "lats",
    "upper chest": "chest",
    "abdominals": "abs",
    "lower abs": "abs",
    "hands": "forearms",
}

# Dataset equipment -> (raw value, English display, Spanish display).
EQUIPMENT = {
    "assisted": ("assisted", "Assisted", "Asistido"),
    "band": ("band", "Band", "Banda elástica"),
    "barbell": ("barbell", "Barbell", "Barra"),
    "body weight": ("body_weight", "Body Weight", "Peso corporal"),
    "bosu ball": ("bosu_ball", "Bosu Ball", "Bosu"),
    "cable": ("cable", "Cable", "Polea"),
    "dumbbell": ("dumbbell", "Dumbbell", "Mancuerna"),
    "elliptical machine": ("elliptical_machine", "Elliptical Machine", "Máquina elíptica"),
    "ez barbell": ("ez_barbell", "EZ Barbell", "Barra EZ"),
    "hammer": ("hammer", "Hammer Machine", "Máquina Hammer"),
    "kettlebell": ("kettlebell", "Kettlebell", "Pesa rusa"),
    "leverage machine": ("leverage_machine", "Leverage Machine", "Máquina de palanca"),
    "medicine ball": ("medicine_ball", "Medicine Ball", "Balón medicinal"),
    "olympic barbell": ("olympic_barbell", "Olympic Barbell", "Barra olímpica"),
    "resistance band": ("resistance_band", "Resistance Band", "Banda de resistencia"),
    "roller": ("roller", "Roller", "Rodillo"),
    "rope": ("rope", "Rope", "Cuerda"),
    "skierg machine": ("skierg_machine", "SkiErg Machine", "Máquina SkiErg"),
    "sled machine": ("sled_machine", "Sled Machine", "Máquina de trineo"),
    "smith machine": ("smith_machine", "Smith Machine", "Máquina Smith"),
    "stability ball": ("stability_ball", "Stability Ball", "Pelota de estabilidad"),
    "stationary bike": ("stationary_bike", "Stationary Bike", "Bicicleta estática"),
    "stepmill machine": ("stepmill_machine", "Stepmill Machine", "Escaladora"),
    "tire": ("tire", "Tire", "Neumático"),
    "trap bar": ("trap_bar", "Trap Bar", "Barra hexagonal"),
    "upper body ergometer": ("upper_body_ergometer", "Upper Body Ergometer", "Ergómetro de brazos"),
    "weighted": ("weighted", "Weighted", "Con peso"),
    "wheel roller": ("wheel_roller", "Wheel Roller", "Rueda abdominal"),
}

# Muscle raw -> in-sentence names for the templated summary.
MUSCLE_SENTENCE = {
    "chest": ("chest", "el pecho"),
    "back": ("back", "la espalda"),
    "lats": ("lats", "los dorsales"),
    "traps": ("traps", "los trapecios"),
    "shoulders": ("shoulders", "los hombros"),
    "biceps": ("biceps", "los bíceps"),
    "triceps": ("triceps", "los tríceps"),
    "forearms": ("forearms", "los antebrazos"),
    "abs": ("abs", "los abdominales"),
    "obliques": ("obliques", "los oblicuos"),
    "lower_back": ("lower back", "la zona lumbar"),
    "glutes": ("glutes", "los glúteos"),
    "quads": ("quads", "los cuádriceps"),
    "hamstrings": ("hamstrings", "los isquiotibiales"),
    "calves": ("calves", "las pantorrillas"),
    "full_body": ("full body", "el cuerpo completo"),
}

LOWERCASE_WORDS = {"a", "an", "and", "at", "by", "for", "in", "of", "on", "or", "the", "to", "with"}
UPPER_TOKENS = {"ez": "EZ", "sz": "SZ", "pov": "POV", "v.": "v."}


def clean_name(raw: str) -> str:
    name = raw.replace("В°", "°").replace("в°", "°").strip()
    name = re.sub(r"\s+", " ", name)

    def cap_word(word: str, first: bool) -> str:
        lower = word.lower()
        if lower in UPPER_TOKENS:
            return UPPER_TOKENS[lower]
        if not first and lower in LOWERCASE_WORDS:
            return lower
        return "-".join(part[:1].upper() + part[1:] for part in word.split("-"))

    words = name.split(" ")
    return " ".join(cap_word(w, i == 0) for i, w in enumerate(words))


def join_names(names, lang):
    conj = " and " if lang == "en" else " y "
    if len(names) == 1:
        return names[0]
    return ", ".join(names[:-1]) + conj + names[-1]


def summary(category, equipment_key, primaries, secondaries, lang):
    eq_en, eq_es = EQUIPMENT[equipment_key][1], EQUIPMENT[equipment_key][2]
    prim = join_names([MUSCLE_SENTENCE[m][0 if lang == "en" else 1] for m in primaries], lang)
    if category == "cardio":
        if lang == "en":
            text = "Cardio exercise that raises the heart rate and works the whole body."
            if equipment_key != "body weight":
                text += f" Performed on the {eq_en.lower()}."
        else:
            text = "Ejercicio de cardio que eleva la frecuencia cardíaca y trabaja todo el cuerpo."
            if equipment_key != "body weight":
                text += f" Se realiza en {eq_es.lower()}."
        return text
    if lang == "en":
        text = f"{eq_en} exercise targeting the {prim}."
        if secondaries:
            sec = join_names([MUSCLE_SENTENCE[m][0] for m in secondaries], lang)
            text += f" Also works the {sec}."
    else:
        text = f"Ejercicio con {eq_es.lower()} enfocado en {prim}."
        if secondaries:
            sec = join_names([MUSCLE_SENTENCE[m][1] for m in secondaries], lang)
            text += f" También trabaja {sec}."
    return text


def main():
    dataset_dir = Path(sys.argv[1])
    repo_root = Path(sys.argv[2]) if len(sys.argv) > 2 else Path(__file__).resolve().parents[2]
    resources = repo_root / "gymapp" / "Resources"
    thumbs_dir = resources / "ExerciseThumbnails"

    records = json.loads((dataset_dir / "data" / "exercises.json").read_text())
    print(f"dataset records: {len(records)}")

    thumbs_dir.mkdir(parents=True, exist_ok=True)
    for stale in thumbs_dir.glob("*.jpg"):
        stale.unlink()

    exercises = []
    problems = []
    for rec in records:
        gvid = f"gv{rec['id']}"
        category = "cardio" if rec["body_part"] == "cardio" else "strength"

        target = rec["target"]
        if target not in MUSCLE_MAP:
            problems.append(f"{gvid}: unmapped target {target!r}")
            continue
        primaries = [MUSCLE_MAP[target]]
        secondaries = []
        for sec in rec.get("secondary_muscles") or []:
            mapped = MUSCLE_MAP.get(sec.strip().lower())
            if mapped is None:
                problems.append(f"{gvid}: unmapped secondary {sec!r}")
            elif mapped not in primaries and mapped not in secondaries:
                secondaries.append(mapped)

        if rec["equipment"] not in EQUIPMENT:
            problems.append(f"{gvid}: unmapped equipment {rec['equipment']!r}")
            continue
        equipment_raw = EQUIPMENT[rec["equipment"]][0]

        steps_en = [s.strip() for s in rec["instruction_steps"].get("en", []) if s.strip()]
        if not steps_en:
            problems.append(f"{gvid}: no English instruction steps")
            continue
        steps_es = [s.strip() for s in rec["instruction_steps"].get("es", []) if s.strip()]

        image = dataset_dir / rec["image"]
        if not image.is_file():
            problems.append(f"{gvid}: missing image {rec['image']}")
            continue
        shutil.copyfile(image, thumbs_dir / f"{gvid}.jpg")

        entry = {
            "id": gvid,
            "name": clean_name(rec["name"]),
            "category": category,
            "primaryMuscles": primaries,
            "secondaryMuscles": secondaries,
            "equipment": equipment_raw,
            "gifFileName": rec["gif_url"].split("/")[-1],
            "summary": summary(category, rec["equipment"], primaries, secondaries, "en"),
            "instructions": steps_en,
            "localizedSummaries": {"es": summary(category, rec["equipment"], primaries, secondaries, "es")},
            "localizedInstructions": {"es": steps_es} if steps_es else {},
        }
        exercises.append(entry)

    if problems:
        print(f"\n{len(problems)} problems:")
        for p in problems:
            print(" ", p)
        sys.exit(1)

    exercises.sort(key=lambda e: e["id"])
    catalog = {
        "version": CATALOG_VERSION,
        "datasetCommit": PINNED_COMMIT,
        "exercises": exercises,
    }
    out = resources / "exercise-catalog.json"
    out.write_text(json.dumps(catalog, ensure_ascii=False, separators=(",", ":")))
    print(f"wrote {out} ({out.stat().st_size / 1024 / 1024:.1f} MB, {len(exercises)} exercises)")
    print(f"wrote {len(list(thumbs_dir.glob('*.jpg')))} thumbnails to {thumbs_dir}")

    mapping_src = Path(__file__).parent / "legacy-mapping.json"
    mapping = json.loads(mapping_src.read_text())
    dataset_ids = {e["id"] for e in exercises}
    bad = [f"{k} -> {v}" for k, v in mapping["mapped"].items() if v not in dataset_ids]
    if bad:
        print("legacy mapping targets missing from catalog:", bad)
        sys.exit(1)
    shutil.copyfile(mapping_src, resources / "legacy-mapping.json")
    print("legacy mapping validated and copied into resources")

    es_missing = sum(1 for e in exercises if not e["localizedInstructions"])
    print(f"exercises without Spanish steps: {es_missing}")


if __name__ == "__main__":
    main()
