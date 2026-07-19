"""Terrain cell layers: wall stacks with floor/water; floor↔water exclusive.

Mirrors habitat_stage / water_fluid_layer rules.

Run: py -3 godot/tests/test_terrain_layers.py
"""

from __future__ import annotations

from typing import Any


def empty_layer() -> dict[str, Any]:
    return {"wall": False, "ground": ""}


def migrate_legacy(kind: str) -> dict[str, Any]:
    layer = empty_layer()
    if kind == "wall":
        layer["wall"] = True
    elif kind == "floor":
        layer["ground"] = "floor"
    elif kind in ("water", "water_half"):
        layer["ground"] = kind
    return layer


def parse_cell(raw: Any) -> dict[str, Any]:
    if isinstance(raw, dict):
        return {
            "wall": bool(raw.get("wall", False)),
            "ground": str(raw.get("ground", "")),
        }
    if isinstance(raw, str):
        return migrate_legacy(raw)
    return empty_layer()


def set_wall(layer: dict[str, Any], on: bool) -> dict[str, Any]:
    out = dict(layer)
    out["wall"] = on
    return out


def set_ground(layer: dict[str, Any], ground: str) -> dict[str, Any]:
    """floor ↔ water mutually exclusive; wall may remain."""
    out = dict(layer)
    out["ground"] = ground
    return out


def is_empty(layer: dict[str, Any]) -> bool:
    return (not layer.get("wall")) and str(layer.get("ground", "")) == ""


def is_solid(raw: Any) -> bool:
    """wall OR ground==floor. Water ground alone is not solid."""
    layer = parse_cell(raw)
    if layer["wall"]:
        return True
    return layer["ground"] == "floor"


def apply_bake(
    terrain: dict[str, Any], water_map: dict[str, str]
) -> dict[str, Any]:
    """Refresh ground water only; keep wall; water displaces floor."""
    out: dict[str, Any] = {}
    for key, raw in terrain.items():
        layer = parse_cell(raw)
        g = layer["ground"]
        if g in ("water", "water_half") and key not in water_map:
            layer = set_ground(layer, "")
        if not is_empty(layer):
            out[key] = layer
    for key, kind in water_map.items():
        layer = parse_cell(out.get(key, empty_layer()))
        layer = set_ground(layer, kind)
        out[key] = layer
    return out


def cell_access_tags(
    layer: dict[str, Any],
    *,
    row: int,
    grid_rows: int,
    wall_edge_rows: int = 2,
    adjacent_water: bool = False,
) -> list[str]:
    ground = str(layer.get("ground", ""))
    painted_wall = bool(layer.get("wall", False))
    in_water = ground in ("water", "water_half")
    zone = "water" if in_water else "air"
    is_wall = painted_wall or row < wall_edge_rows
    is_floor = (
        ground == "floor"
        or in_water
        or row >= grid_rows - wall_edge_rows
    )
    tags: list[str] = []
    if is_wall:
        tags.append(f"wall_{zone}")
    if is_floor:
        tags.append(f"floor_{zone}")
    if in_water:
        tags.append("swim")
    if painted_wall and adjacent_water and "wall_water" not in tags:
        tags.append("wall_water")
    return tags


def test_wall_plus_floor() -> None:
    layer = set_ground(set_wall(empty_layer(), True), "floor")
    assert layer == {"wall": True, "ground": "floor"}
    assert is_solid(layer)


def test_wall_plus_water() -> None:
    layer = set_ground(set_wall(empty_layer(), True), "water")
    assert layer == {"wall": True, "ground": "water"}
    assert is_solid(layer)  # wall makes solid


def test_floor_and_water_exclusive() -> None:
    layer = set_ground(empty_layer(), "floor")
    layer = set_ground(layer, "water")
    assert layer["ground"] == "water"
    assert not layer["wall"]
    assert not is_solid(layer)


def test_water_displaces_floor_keeps_wall() -> None:
    terrain = {"1,1": {"wall": True, "ground": "floor"}}
    baked = apply_bake(terrain, {"1,1": "water"})
    assert baked["1,1"]["wall"] is True
    assert baked["1,1"]["ground"] == "water"


def test_bake_clears_water_keeps_wall() -> None:
    terrain = {"0,0": {"wall": True, "ground": "water"}}
    baked = apply_bake(terrain, {})
    assert baked["0,0"] == {"wall": True, "ground": ""}


def test_bake_does_not_erase_wall_only() -> None:
    terrain = {"2,2": {"wall": True, "ground": ""}}
    baked = apply_bake(terrain, {})
    assert baked["2,2"]["wall"] is True


def test_solid_legacy_string() -> None:
    assert is_solid("wall")
    assert is_solid("floor")
    assert not is_solid("water")
    assert not is_solid("water_half")


def test_solid_layered() -> None:
    assert is_solid({"wall": False, "ground": "floor"})
    assert is_solid({"wall": True, "ground": ""})
    assert is_solid({"wall": True, "ground": "water"})
    assert not is_solid({"wall": False, "ground": "water"})
    assert not is_solid({"wall": False, "ground": ""})


def test_migrate_legacy() -> None:
    assert migrate_legacy("wall") == {"wall": True, "ground": ""}
    assert migrate_legacy("floor") == {"wall": False, "ground": "floor"}
    assert migrate_legacy("water") == {"wall": False, "ground": "water"}


def test_access_wall_floor_stack_air() -> None:
    tags = cell_access_tags(
        {"wall": True, "ground": "floor"},
        row=10,
        grid_rows=45,
    )
    assert "wall_air" in tags
    assert "floor_air" in tags
    assert "swim" not in tags


def test_access_wall_water_stack() -> None:
    tags = cell_access_tags(
        {"wall": True, "ground": "water"},
        row=10,
        grid_rows=45,
    )
    assert "wall_water" in tags
    assert "floor_water" in tags
    assert "swim" in tags


def test_access_painted_wall_adjacent_water() -> None:
    tags = cell_access_tags(
        {"wall": True, "ground": ""},
        row=10,
        grid_rows=45,
        adjacent_water=True,
    )
    assert "wall_air" in tags
    assert "wall_water" in tags


def main() -> None:
    tests = [
        test_wall_plus_floor,
        test_wall_plus_water,
        test_floor_and_water_exclusive,
        test_water_displaces_floor_keeps_wall,
        test_bake_clears_water_keeps_wall,
        test_bake_does_not_erase_wall_only,
        test_solid_legacy_string,
        test_solid_layered,
        test_migrate_legacy,
        test_access_wall_floor_stack_air,
        test_access_wall_water_stack,
        test_access_painted_wall_adjacent_water,
    ]
    for fn in tests:
        fn()
        print(f"ok  {fn.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
