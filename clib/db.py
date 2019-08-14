# -*- coding: utf-8 -*-
"""Database module."""
import argparse
from pathlib import Path
from subprocess import PIPE
from typing import List, Optional

from clib.docker import DockerContainer
from clib.files import existing_directory_type, existing_file_type, shell

POSTGRES_DOCKER_CONTAINER_NAME = "postgres10"


class DatabaseServer:
    """A database server URI parser."""

    uri: str
    protocol: str
    user: Optional[str]
    password: Optional[str]
    server: str
    port: Optional[int]

    def __init__(self, uri):
        """Parser the server URI and extract needed parts."""
        self.uri = uri
        protocol_user_password, server_port = uri.split("@")
        self.protocol, user_password = protocol_user_password.split("://")
        if ":" in user_password:
            self.user, self.password = user_password.split(":")
        else:
            self.user, self.password = None, None
        if ":" in server_port:
            self.server, self.port = server_port.split(":")
            self.port = int(self.port)
        else:
            self.server, self.port = server_port, None

    @property
    def uri_without_port(self):
        """Return the URI without the port."""
        parts = self.uri.split(":")
        if len(parts) != 4:
            # Return the unmodified URI if we don't have port.
            return self.uri
        return ":".join(parts[:-1])


class PostgreSQLServer(DatabaseServer):
    """A PostgreSQL database server URI parser and more stuff."""

    databases: List[str] = []
    inside_docker = False
    psql: str = ""
    pg_dump: str = ""

    def __init__(self, *args, **kwargs):
        """Determine which psql executable exists on this machine."""
        super().__init__(*args, **kwargs)

        self.psql = shell("which psql", quiet=True, return_lines=True)[0]
        if not self.psql:
            self.psql = "psql_docker"
            self.inside_docker = True

        self.pg_dump = shell("which pg_dump", quiet=True, return_lines=True)[0]
        if not self.pg_dump:
            self.pg_dump = "pg_dump_docker"
            self.inside_docker = True

    @property
    def docker_uri(self):
        """Return a URI without port if we are inside Docker."""
        return self.uri_without_port if self.inside_docker else self.uri

    def list_databases(self) -> "PostgreSQLServer":
        """List databases."""
        process = shell(
            f"{self.psql} -c 'SELECT datname FROM pg_database WHERE datistemplate = false' "
            f"--tuples-only {self.docker_uri}",
            quiet=True,
            stdout=PIPE,
        )
        if process.returncode:
            print(f"Error while listing databases.\nstdout={process.stdout}\nstderr={process.stderr}")
            exit(10)

        self.databases = sorted(db.strip() for db in process.stdout.strip().split())
        return self


def backup(parser, args):
    """Backup PostgreSQL databases."""
    pg = PostgreSQLServer(args.server_uri).list_databases()
    container = DockerContainer(POSTGRES_DOCKER_CONTAINER_NAME)
    for database in pg.databases:
        sql_file: Path = Path(args.backup_dir) / f"{pg.protocol}_{pg.server}_{pg.port}" / f"{database}.sql"
        sql_file.parent.mkdir(parents=True, exist_ok=True)

        if pg.inside_docker:
            sql_file = container.replace_mount_dir(sql_file)
        shell(f"{pg.pg_dump} --clean --create --if-exists --file={sql_file} {pg.docker_uri}/{database}")


def restore(parser, args):
    """Restore PostgreSQL databases."""
    pg = PostgreSQLServer(args.server_uri).list_databases()
    new_database = args.database_name or args.sql_file.stem
    if new_database in pg.databases:
        print(f"The database {new_database!r} already exists in the server. Provide a new database name.")
        exit(1)

    if new_database != args.sql_file.stem:
        # TODO Optional argument --owner to set the database owner
        print(f"TODO: Create a user named {new_database!r} if it doesn't exist (or raise an error)")
        print(f"TODO: Parse the .sql file and replace DATABASE/OWNER {args.sql_file.stem!r} by {new_database!r}")
        exit(2)

    shell(f"{pg.psql} {args.server_uri} < {args.sql_file}")


# TODO: Convert to click
def xpostgres():
    """Extra PostgreSQL tools like backup, restore, user creation, etc."""
    parser = argparse.ArgumentParser(description="PostgreSQL helper tools")
    parser.add_argument("server_uri", help="database server URI (postgresql://user:password@server:port)")
    parser.set_defaults(chosen_function=None)
    subparsers = parser.add_subparsers(title="commands")

    parser_backup = subparsers.add_parser("backup", help="backup a PostgreSQL database to a SQL file")
    parser_backup.add_argument("backup_dir", type=existing_directory_type, help="directory to store the backups")
    parser_backup.set_defaults(chosen_function=backup)

    parser_restore = subparsers.add_parser("restore", help="restore a PostgreSQL database from a SQL file")
    parser_restore.add_argument(
        "sql_file", type=existing_file_type, help="full path of the .sql file created by the 'backup' command"
    )
    parser_restore.add_argument("database_name", nargs="?", help="database name (default: basename of .sql file)")
    parser_restore.set_defaults(chosen_function=restore)

    # TODO Subcommand create-user new-user-name or alias user new-user-name to create a new user
    # TODO xpostgres user myuser [mypass]

    args = parser.parse_args()
    if not args.chosen_function:
        parser.print_help()
        return
    args.chosen_function(parser, args)
    return
