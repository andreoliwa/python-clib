"""Docker module."""

import argparse
import json
from pathlib import Path
from subprocess import PIPE
from typing import List

from clib.config import JsonConfig
from clib.files import existing_directory_type, existing_file_type, shell, shell_find
from clib.types import JsonDict

YML_DIRS = JsonConfig("docker-find-yml-dirs.json")
YML_FILES = JsonConfig("docker-find-yml-files.json")


class DockerContainer:
    """A helper for Docker containers."""

    def __init__(self, container_name: str) -> None:
        """Init instance."""
        self.container_name = container_name
        self.inspect_json: List[JsonDict] = []

    def inspect(self) -> "DockerContainer":
        """Inspect a Docker container and save its JSON info."""
        if not self.inspect_json:
            raw_info = shell(f"docker inspect {self.container_name}", quiet=True, capture_output=True).stdout
            self.inspect_json = json.loads(raw_info)
        return self

    def replace_mount_dir(self, path: Path) -> Path:
        """Replace a mounted dir on a file/dir path inside a Docker container."""
        self.inspect()
        for mount in self.inspect_json[0]["Mounts"]:
            source = mount["Source"]
            if str(path).startswith(source):
                new_path = str(path).replace(source, mount["Destination"])
                return Path(new_path)
        return path


def rescan_files(dirs):
    """Rescan all directories and save the yml files that were found."""
    sorted_dirs = sorted(dirs)
    YML_DIRS.dump(sorted_dirs)

    files = set()
    for dir in sorted_dirs:
        print(f"Files on {dir}")
        for file in shell_find(f"{dir} -name docker-compose.yml"):
            print(f"  {file}")
            files.add(str(file))
    sorted_files = sorted(files)
    YML_FILES.dump(sorted_files)


def scan_command(parser, args):
    """Scan directories and add them to the list."""
    dirs = YML_DIRS.load_set()
    if not args.dir:
        print("Rescanning existing directories")
    for dir in args.dir:
        dirs.add(str(dir))
        print(f"Directory added: {dir}")
    rescan_files(dirs)


def rm_command(parser, args):
    """Remove directories from the list."""
    dirs = YML_DIRS.load_set()
    for one_dir in args.dir:
        str_dir = str(one_dir)
        if str_dir in dirs:
            dirs.remove(str_dir)
            print(f"Directory removed: {one_dir}")
        else:
            print(f"Directory was not configured: {one_dir}")
    rescan_files(dirs)


def ls_command(parser, args):
    """List registered yml files."""
    for yml_file in sorted(YML_FILES.load_set()):
        print(yml_file)


def yml_command(parser, args):
    """Run a docker-compose command on one of the yml files."""
    found = set()
    partial_name = args.yml_file

    for file in YML_FILES.load_set():
        if partial_name in file:
            found.add(file)
    if not found:
        print(f"No .yml file was found with the string '{partial_name}'")
        exit(1)

    sorted_found = sorted(found)
    if len(sorted_found) > 1:
        choices = "\n".join(sorted_found)
        chosen_yml = shell(
            f"echo '{choices}' | fzf --height={len(sorted_found) + 2} --cycle --tac", quiet=True, stdout=PIPE
        ).stdout.strip()
        if not chosen_yml:
            print("No .yml file was chosen")
            exit(2)
    else:
        chosen_yml = sorted_found[0]
    shell(f"docker-compose -f {chosen_yml} {' '.join(args.docker_compose_arg)}")


# TODO: Convert to click
def docker_find():
    """Find docker.compose.yml files."""
    parser = argparse.ArgumentParser(description="find docker.compose.yml files")
    parser.set_defaults(chosen_function=None)
    subparsers = parser.add_subparsers(title="commands")

    parser_scan = subparsers.add_parser("scan", help="scan directories and add them to the list")
    parser_scan.add_argument("dir", nargs="*", help="directory to scan", type=existing_directory_type)
    parser_scan.set_defaults(chosen_function=scan_command)

    parser_rm = subparsers.add_parser("rm", help="remove directories from the list")
    parser_rm.add_argument("dir", nargs="+", help="directory to remove", type=existing_directory_type)
    parser_rm.set_defaults(chosen_function=rm_command)

    parser_ls = subparsers.add_parser("ls", help="list yml files")
    parser_ls.set_defaults(chosen_function=ls_command)

    parser_yml = subparsers.add_parser("yml", help="choose one of the yml files to call docker-compose on")
    parser_yml.add_argument("yml_file", help="partial name of the desired .yml file")
    parser_yml.add_argument("docker_compose_arg", nargs=argparse.REMAINDER, help="docker-compose arguments")
    parser_yml.set_defaults(chosen_function=yml_command)

    args = parser.parse_args()
    if not args.chosen_function:
        parser.print_help()
        return
    args.chosen_function(parser, args)
    return


def backup(parser, args):
    """Backup a Docker volume."""
    for volume in args.volume_name:
        # TODO: when piping from stdin, stdout is printed only at the end (buffered)
        shell(
            "docker run --rm -i -v /var/lib/docker/volumes:/volumes -v {dir}:/backup busybox "
            "tar czf /backup/{volume}.tgz /volumes/{volume}".format(dir=args.backup_dir, volume=volume)
        )


def restore(parser, args):
    """Restore a Docker volume."""
    tgz_file: Path = args.tgz_file
    backup_dir = tgz_file.parent
    new_volume_name = args.volume_name if args.volume_name else tgz_file.stem

    busybox = "docker run --rm -i -v /var/lib/docker:/docker -v {backup_dir}:/backup busybox ".format(
        backup_dir=backup_dir
    )

    # Delete the destination directory before restoring
    shell(busybox + f"rm -rf /docker/volumes/{new_volume_name}")

    # Create the full path
    shell(busybox + f"mkdir /docker/volumes/{new_volume_name}")

    # Restore the .tgz file in the new empty directory
    shell(
        busybox
        + "tar xzf /backup/{tgz} -C /docker/volumes/{new_volume_name}/ --strip-components 2".format(
            tgz=tgz_file.name, new_volume_name=new_volume_name
        )
    )


# TODO: Convert to click
def docker_volume():
    """Backup and restore Docker volumes.

    See also https://stackoverflow.com/a/23778599/1391315.
    """
    parser = argparse.ArgumentParser(description="backup and restore Docker volumes")
    parser.set_defaults(chosen_function=None)
    subparsers = parser.add_subparsers(title="commands")

    parser_backup = subparsers.add_parser("backup", aliases=["b"], help="backup a Docker volume")
    parser_backup.add_argument("backup_dir", type=existing_directory_type, help="directory to store the backups")
    parser_backup.add_argument("volume_name", nargs="+", help="Docker volume name")
    parser_backup.set_defaults(chosen_function=backup)

    parser_restore = subparsers.add_parser("restore", aliases=["r"], help="restore a Docker volume")
    parser_restore.add_argument(
        "tgz_file", type=existing_file_type, help="full path of the .tgz file created by the 'backup' command"
    )
    parser_restore.add_argument("volume_name", nargs="?", help="volume name (default: basename of .tgz file)")
    parser_restore.set_defaults(chosen_function=restore)

    args = parser.parse_args()
    if not args.chosen_function:
        parser.print_help()
        return
    args.chosen_function(parser, args)
    return
