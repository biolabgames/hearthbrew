"""Assemble the additive roster catalogs and native patient scenes."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
data = json.loads((ROOT / 'resources/data/roster_expansion.json').read_text())
names = {i: r['name'] for i, r in enumerate(data['recipes'], 16)}
names.update({1: 'Cloud blanket', 2: 'Rooted lullaby', 3: 'Softstep syrup',
              4: 'Lantern cordial', 5: 'Quiet kettle', 6: 'Petal polish', 8: 'Rosecool tonic'})
for p in data['patients']:
    p['hint'] = 'Use ' + ', then '.join(names[i] for i in p['treatments']) + '. Find the ingredient order in the recipe book.'
(ROOT / 'resources/data/roster_expansion.json').write_text(json.dumps(data, indent=2) + '\n')

def append_catalog(filename, entries):
    path = ROOT / 'resources/data' / filename
    source = path.read_text().replace('\n# Roster expansion\n', '\n; Roster expansion\n')
    # Idempotent: remove only this expansion's appended entries before rebuilding.
    marker = '\n; Roster expansion\n'
    if marker in source:
        source = source.split(marker)[0] + '])\n'
    assert source.rstrip().endswith('])')
    path.write_text(source.rstrip()[:-2] + marker + ', ' + ', '.join(json.dumps(p) for p in entries) + '])\n')

for filename, key in [('patients.tres', 'patients'), ('symptoms.tres', 'symptoms'), ('recipes.tres', 'recipes')]:
    append_catalog(filename, data[key])

lineup = ROOT / 'scenes/patients/patient_lineup.tscn'
source = lineup.read_text().replace('# Roster expansion', '; Roster expansion')
if '; Roster expansion resources' in source:
    source = source.split('; Roster expansion resources')[0] + source.split('; Roster expansion end resources\n')[1]
    source = source.split('; Roster expansion actors')[0]
resources = '; Roster expansion resources\n[ext_resource type="Script" path="res://scripts/symptom_effects.gd" id="symptom_overlay"]\n'
actors = '\n; Roster expansion actors\n[node name="SymptomOverlay" type="Node2D" parent="."]\nz_index = 1\nscript = ExtResource("symptom_overlay")\n'
for p in data['patients']:
    slug = p['name'].lower()
    (ROOT / f'scenes/patients/{slug}.tscn').write_text(f'''[gd_scene format=3]

[ext_resource type="Texture2D" path="res://assets/patients/expanded/{slug}.png" id="portrait"]
[ext_resource type="Shader" path="res://assets/patients/expanded/face_overlay.gdshader" id="face_shader"]

[sub_resource type="ShaderMaterial" id="face_material"]
shader = ExtResource("face_shader")

[node name="{p['name']}" type="Node2D"]
metadata/full_portrait = true

[node name="Body" type="Sprite2D" parent="."]
texture = ExtResource("portrait")
centered = false
hframes = 3
vframes = 3

[node name="Face" type="Sprite2D" parent="."]
material = SubResource("face_material")
texture = ExtResource("portrait")
centered = false
hframes = 3
vframes = 3
''')
    resources += f'[ext_resource type="PackedScene" path="res://scenes/patients/{slug}.tscn" id="{slug}"]\n'
    actors += f'\n[node name="{p["name"]}" parent="." instance=ExtResource("{slug}")]\nvisible = false\n'
resources += '; Roster expansion end resources\n\n'
idx = source.index('[node name="Patients"')
lineup.write_text(source[:idx] + resources + source[idx:] + actors)
