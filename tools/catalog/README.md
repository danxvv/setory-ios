# Exercise catalog tooling

Transforms the [Gym visual exercises dataset](https://github.com/hasaneyldrm/exercises-dataset)
into the app's bundled catalog. Run once per dataset upgrade; outputs are checked in.

## Pinned dataset

- Commit: `118e4bd6b14da6df0e36605d7169b65db18389a4`
- GIFs are fetched at runtime from jsDelivr pinned to that commit:
  `https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@118e4bd6b14da6df0e36605d7169b65db18389a4/videos/<gifFileName>`
  (the constant lives in `gymapp/Services/ExerciseMediaStore.swift`; keep both in sync
  with `PINNED_COMMIT` in `transform.py` when upgrading)

## Usage

```sh
curl -sL "https://github.com/hasaneyldrm/exercises-dataset/archive/<SHA>.tar.gz" | tar -xz
python3 tools/catalog/transform.py exercises-dataset-<SHA>
```

Outputs:
- `gymapp/Resources/exercise-catalog.json` — 1,324 exercises, en/es content,
  taxonomy mapped onto the app's `Muscle`/`ExerciseCategory`/`Equipment` vocabulary
- `gymapp/Resources/ExerciseThumbnails/` — 180×180 JPGs renamed `<exercise-id>.jpg`
- `gymapp/Resources/legacy-mapping.json` — copy of `legacy-mapping.json` (the
  hand-reviewed legacy-id migration table used by `LegacyCatalogMigrator`)

The script fails loudly on unmapped taxonomy values, missing instructions, missing
images, or legacy-mapping targets absent from the catalog. Bump `CATALOG_VERSION`
(and `CatalogSeeder.bundledCatalogVersion`) whenever the emitted catalog changes so
seeding re-runs on upgraded installs.

## Licensing

Dataset structure and instruction text are MIT. Exercise media is
© Gym visual (https://gymvisual.com/), redistributed with permission at 180×180;
the attribution string must remain visible wherever media is shown.
