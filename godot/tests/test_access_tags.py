"""Mirror of godot/scenes/ui/access_tags.gd — access tag intersection + wall limits.

Run: py -3 godot/tests/test_access_tags.py
"""

from __future__ import annotations

FLOOR_AIR = "floor_air"
WALL_AIR = "wall_air"
FLOOR_WATER = "floor_water"
WALL_WATER = "wall_water"
SWIM = "swim"


def has_tag(access: list, tag: str) -> bool:
    return tag in [str(t) for t in access]


def allows(
    cell_tags: list,
    access: list,
    limits: dict | None = None,
    from_floor_cm: int = 0,
) -> bool:
    if not access:
        return False
    limits = limits or {}
    cell_set = {str(t) for t in cell_tags}
    for raw in access:
        tag = str(raw)
        if tag not in cell_set:
            continue
        if tag == WALL_AIR and WALL_AIR in limits:
            lim = int(limits[WALL_AIR])
            if lim >= 0 and from_floor_cm >= lim:
                continue
        return True
    return False


def test_intersection() -> None:
    assert allows(["floor_air"], ["floor_air", "wall_air"])
    assert not allows(["swim"], ["floor_air"])


def test_swim() -> None:
    assert allows(["floor_water", "swim"], ["swim"])


def test_wall_air_unlimited() -> None:
    assert allows(["wall_air"], ["wall_air"], {}, from_floor_cm=20)


def test_wall_air_limit() -> None:
    limits = {WALL_AIR: 5}
    assert allows(["wall_air"], ["wall_air"], limits, from_floor_cm=4)
    assert not allows(["wall_air"], ["wall_air"], limits, from_floor_cm=5)
    assert not allows(["wall_air"], ["wall_air"], limits, from_floor_cm=6)


def test_wall_air_limit_other_tag_ok() -> None:
    """Height-blocked wall_air still allows swim on same cell tags."""
    limits = {WALL_AIR: 5}
    assert allows(["wall_air", "swim"], ["wall_air", "swim"], limits, from_floor_cm=10)


def test_empty_access() -> None:
    assert not allows(["floor_air"], [])


def test_has_tag() -> None:
    assert has_tag(["floor_air", "swim"], SWIM)
    assert not has_tag(["floor_air"], WALL_WATER)


def main() -> None:
    tests = [
        test_intersection,
        test_swim,
        test_wall_air_unlimited,
        test_wall_air_limit,
        test_wall_air_limit_other_tag_ok,
        test_empty_access,
        test_has_tag,
    ]
    for fn in tests:
        fn()
        print(f"ok  {fn.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
