"""File tests."""
from clib.files import unique_file_name


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
