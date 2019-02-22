"""Database module."""
from typing import List, Optional

from clit.files import shell


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

        self.psql = shell("which psql", quiet=True, capture_output=True).stdout
        if not self.psql:
            self.psql = "psql_docker"
            self.inside_docker = True

        self.pg_dump = shell("which pg_dump", quiet=True, capture_output=True).stdout
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
            capture_output=True,
        )
        if process.returncode:
            print(f"Error while listing databases.\nstdout={process.stdout}\nstderr={process.stderr}")
            exit(10)

        self.databases = sorted(db.strip() for db in process.stdout.strip().split())
        return self
