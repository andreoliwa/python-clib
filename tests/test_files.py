"""File tests."""
from pathlib import Path

from clib.files import merge_directories, unique_file_name


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
    file.parent.mkdir(parents=True, exist_ok=True)
    file.touch()


def test_merge_directories(tmp_path):
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

    files = [
        (tmp_path / "2020" / "12" / "one.txt"),
        (tmp_path / "2020" / "12" / "one_Copy.txt"),
        (tmp_path / "2020" / "root.txt"),
        (tmp_path / "2020" / "root_Copy.txt"),
        (tmp_path / "2020" / "12" / "two.txt"),
        (tmp_path / "2021" / "01" / "three.txt"),
        (tmp_path / "2020" / "12" / "one_Copy2.txt"),
        (tmp_path / "2020" / "12" / "two_Copy.txt"),
        (tmp_path / "2020" / "root_Copy2.txt"),
    ]
    """
    2020/12/one.txt
    2020/12/one_Copy.txt
    2020/12/one_Copy2.txt
    2020/12/two.txt
    2020/12/two_Copy.txt
    2020/root.txt
    2020/root_Copy.txt
    2020/root_Copy2.txt
    2021/01/three.txt
    """
    for file in sorted(files):
        print(file.relative_to(tmp_path))
        # assert file.exists()
    actual = sorted(tmp_path.rglob("*"))
    compare
    assert False
