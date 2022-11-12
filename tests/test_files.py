"""File tests."""
from pathlib import Path
from textwrap import dedent

from testfixtures import compare

from clib.rename import merge_directories, unique_file_name


def test_unique_file_name(tmp_path):
    """Test unique file names with numeric index."""
    path = tmp_path / "file.txt"
    assert unique_file_name(path) == path

    path.touch()
    first = path.with_name("file_Copy.txt")
    assert unique_file_name(path) == first

    first.touch()
    second = path.with_name("file_Copy1.txt")
    assert unique_file_name(first) == second

    second.touch()
    third = path.with_name("file_Copy2.txt")
    assert unique_file_name(second) == third


def create(file: Path):
    """Create an empty file and its parent dirs."""
    file.parent.mkdir(parents=True, exist_ok=True)
    file.touch()


def test_merge_directories(tmp_path):
    """Test merge directories."""
    create(tmp_path / "2020" / "12" / "one.txt")
    create(tmp_path / "2020" / "root.txt")

    other = Path(tmp_path / "other")
    create(other / "2020" / "root_Copy.txt")
    create(other / "2020" / "12" / "one.txt")
    create(other / "2020" / "12" / "two.txt")
    create(other / "2021" / "01" / "three.txt")

    another = Path(tmp_path / "another")
    create(another / "2020" / "12" / "one.txt")
    create(another / "2020" / "12" / "two.txt")
    create(another / "2020" / "root_Copy.txt")

    merge_directories(tmp_path, other, another)

    expected = """
        2020/12/one.txt
        2020/12/one_Copy.txt
        2020/12/one_Copy1.txt
        2020/12/two.txt
        2020/12/two_Copy.txt
        2020/root.txt
        2020/root_Copy.txt
        2020/root_Copy1.txt
        2021/01/three.txt
    """
    actual = sorted(str(path.relative_to(tmp_path)) for path in tmp_path.rglob("*") if path.is_file())
    compare(actual=actual, expected=dedent(expected).strip().splitlines())
