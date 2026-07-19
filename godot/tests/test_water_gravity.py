"""Water cell helpers + bake thresholds (Rapier fluid bakes into these kinds).

Run: py -3 godot/tests/test_water_gravity.py
"""

from __future__ import annotations

KIND_WATER = "water"
KIND_WATER_HALF = "water_half"
FILL_FULL = 1.0
FILL_HALF = 0.5
BAKE_FULL_COUNT = 3
BAKE_HALF_COUNT = 1


def is_water(kind: str) -> bool:
    return kind in (KIND_WATER, KIND_WATER_HALF)


def fill_of(kind: str) -> float:
    if kind == KIND_WATER:
        return FILL_FULL
    if kind == KIND_WATER_HALF:
        return FILL_HALF
    return 0.0


def kind_for_fill(amount: float) -> str:
    if amount >= FILL_FULL - 0.001:
        return KIND_WATER
    if amount >= FILL_HALF - 0.001:
        return KIND_WATER_HALF
    return ""


def bake_from_counts(counts: dict[str, int]) -> dict[str, str]:
    out: dict[str, str] = {}
    for key, n in counts.items():
        if n >= BAKE_FULL_COUNT:
            out[key] = KIND_WATER
        elif n >= BAKE_HALF_COUNT:
            out[key] = KIND_WATER_HALF
    return out


def test_is_water() -> None:
    assert is_water("water")
    assert is_water("water_half")
    assert not is_water("floor")


def test_fill_of() -> None:
    assert fill_of("water") == 1.0
    assert fill_of("water_half") == 0.5
    assert fill_of("") == 0.0


def test_kind_for_fill() -> None:
    assert kind_for_fill(1.0) == KIND_WATER
    assert kind_for_fill(0.5) == KIND_WATER_HALF
    assert kind_for_fill(0.0) == ""


def test_bake_thresholds() -> None:
    baked = bake_from_counts({"0,0": 3, "1,0": 1, "2,0": 0})
    assert baked == {"0,0": KIND_WATER, "1,0": KIND_WATER_HALF}


def test_bake_skips_empty() -> None:
    assert bake_from_counts({}) == {}
    assert bake_from_counts({"0,0": 0}) == {}


def main() -> None:
    tests = [
        test_is_water,
        test_fill_of,
        test_kind_for_fill,
        test_bake_thresholds,
        test_bake_skips_empty,
    ]
    for fn in tests:
        fn()
        print(f"ok  {fn.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
