#!/usr/bin/env python3
# PYTHON_ARGCOMPLETE_OK
import argparse

try:
    import argcomplete

    __argcomplete = True
except ImportError:
    __argcomplete = False
from catkin_pkg.packages import find_packages
from datetime import datetime, timezone
from dateutil.parser import parse as parse_date
import docker
from shutil import copytree, rmtree
from typing import Union, List
from os import getenv, getuid, getgid
import os.path
import sys


class PkgChoicesCompleter:
    def __init__(self, workspace_path):
        self.workspace_path = workspace_path
        self.directory_completer = argcomplete.completers.DirectoriesCompleter()

    def __call__(self, **_):
        packages = find_packages(self.workspace_path)
        return [packages[path].name for path in packages]


def cross_compile(
    workspace_path: str,
    packages: Union[str, List[str]],
    ros_distro: str,
    platform: str,
    output_base_dir: str,
    output_dir: Union[str, None] = None,
    build_type: str = "RelWithDebInfo",
    clean: bool = False,
    no_cache: bool = False,
    rebuild: bool = False,
    pull: bool = False,
    base_image: Union[str, None] = None
) -> bool:
    # if packages is iterable, join them
    if isinstance(packages, list):
        packages = " ".join(packages)
    print(">>> Create output directory")
    if output_dir is None:
        output_dir = output_base_dir
        if ros_distro != os.getenv("ROS_DISTRO"):
            output_dir = os.path.join(output_dir, ros_distro)
        output_dir = os.path.join(output_dir, platform.replace("/", "_"))
        if clean and os.path.isdir(output_dir):
            rmtree(output_dir)
    os.makedirs(output_dir, exist_ok=True)
    print(f"{output_dir} created.")
    platform_cleaned = platform.replace('/', '_')
    if base_image is None:
        tag = f"cross-compile-{ros_distro}-{platform_cleaned}"
        print(f">>> Obtain image for {ros_distro} on {platform}")
    else:
        base_image_cleaned = base_image.replace(':', '_').replace('/', '_')
        tag = f"cross-compile-{base_image_cleaned}-{platform_cleaned}"
        print(f">>> Obtain image based on {base_image} for {platform}")
    docker_client = docker.from_env()
    if not rebuild:
        try:
            image = docker_client.images.get(tag)
            created = (
                datetime.now(timezone.utc)
                if "Created" not in image.attrs
                else parse_date(image.attrs["Created"])
            )
            if (datetime.now(timezone.utc) - created).days > 14:
                print("Container might be outdated. Rebuilding without cache...")
                rebuild = True
                no_cache = True
        except docker.errors.ImageNotFound:
            rebuild = True
    if rebuild:
        path = os.path.join(
            os.path.dirname(getenv("ROSWSS_BASE_SCRIPTS", os.path.dirname(__file__))),
            "docker",
            "cross_compile",
        )
        if not os.path.isfile(os.path.join(path, "Dockerfile")):
            raise RuntimeError("Could not find Dockerfile in " + path)
        result = docker_client.api.build(
            decode=True,
            path=path,
            tag=tag,
            buildargs={
                "BASE_IMAGE": base_image,
                "ROS_DISTRO": ros_distro,
                "USER_ID": f"{getuid()}",
                "GROUP_ID": f"{getgid()}",
            },
            platform=platform,
            pull=pull,
            rm=True,
            forcerm=True,
            nocache=no_cache,
            use_config_proxy=True,
        )

        for item in result:
            if "stream" in item:
                text = item["stream"].strip()
                if text:
                    print(text)
            if "errorDetail" in item:
                print(item["errorDetail"]["message"], file=sys.stderr)
                return False
        print(f"Done. Built image as {tag}")
    else:
        print(f"Using existing image {tag}")
    print(f">>> Cross-compiling {packages}")
    container = None
    try:
        tmp_path = f"/tmp/tudawss/{tag}"
        if clean:
            def ignore_file_not_found(func, path, exc_info):
                if isinstance(exc_info[1], FileNotFoundError):
                    return
                func(path)

            rmtree(f"{tmp_path}/build", onerror=ignore_file_not_found)
            rmtree(f"{tmp_path}/devel", onerror=ignore_file_not_found)
            rmtree(f"{tmp_path}/install", onerror=ignore_file_not_found)
            rmtree(f"{tmp_path}/logs", onerror=ignore_file_not_found)
        os.makedirs(f"{tmp_path}/build", exist_ok=True)
        os.makedirs(f"{tmp_path}/devel", exist_ok=True)
        os.makedirs(f"{tmp_path}/install", exist_ok=True)
        os.makedirs(f"{tmp_path}/logs", exist_ok=True)
        container = docker_client.containers.run(
            tag,
            command=f"{packages}",
            volumes={
                workspace_path: {
                    "bind": "/workspace/src",
                    "mode": "ro",
                },
                f"{tmp_path}/build": {
                    "bind": "/workspace/build",
                    "mode": "rw",
                },
                f"{tmp_path}/devel": {
                    "bind": "/workspace/devel",
                    "mode": "rw",
                },
                f"{tmp_path}/install": {
                    "bind": "/workspace/install",
                    "mode": "rw",
                },
                f"{tmp_path}/logs": {
                    "bind": "/workspace/logs",
                    "mode": "rw",
                },
            },
            environment={"BUILD_TYPE": build_type},
            platform=platform,
            detach=True,
            stdout=True,
            stderr=True,
        )
        for line in container.logs(stream=True):
            text: str = line.decode("utf-8").strip()
            if text:
                print(text)
        result = container.wait()
        if result["StatusCode"] != 0:
            print(
                f"Cross-compilation failed with exit code {result['StatusCode']}",
                file=sys.stderr,
            )
            return False
        print(f">>> Copying results")
        # Copy install folder to workspace
        copytree(f"{tmp_path}/install", output_dir, dirs_exist_ok=True)
        print(f"Copied build results to {output_dir}")
    except docker.errors.ContainerError as e:
        print(f"Failed to cross-compile {packages}:", file=sys.stderr)
        print(e.stderr.decode("utf-8"), file=sys.stderr)
        return False
    except KeyboardInterrupt:
        if container is not None:
            container.kill()
            print("Container killed.")
    finally:
        if container is not None:
            container.remove()
    return True


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Builds the given packages for the given platform/architecture in a docker image."
    )
    parser.add_argument("--base-image", help="An alternative base image to use.")
    parser.add_argument("--build-type", choices=["Debug", "RelWithDebInfo", "Release"])
    parser.add_argument(
        "--no-cache",
        default=False,
        action="store_true",
        help="Do not use the cache when building. Use with --rebuild for a clean build of the docker image.",
    )
    parser.add_argument(
        "--pull",
        default=False,
        action="store_true",
        help="Always try to pull the latest image when building."
    )
    parser.add_argument(
        "--rebuild",
        default=False,
        action="store_true",
        help="Force rebuilding the docker image.",
    )
    parser.add_argument(
        "--clean",
        default=False,
        action="store_true",
        help="Clean build folders before building.",
    )
    parser.add_argument(
        "--platform", choices=["linux/arm64", "linux/amd64"], required=True
    )
    parser.add_argument(
        "--ros-distro",
        choices=["noetic"],
        default=getenv("ROS_DISTRO"),
        help="ROS distro to use for cross-compilation. Defaults to ROS distro on host.",
    )
    workspace_path = os.environ.get("ROS_WORKSPACE")

    parser.add_argument(
        "--output-base-dir",
        default=os.path.join(os.path.dirname(workspace_path), "cross-compile-install"),
        help="Specifies the base directory where the install output is placed. It will be placed in a subdirectory based on the ROS distro and architecture.",
    )
    parser.add_argument(
        "--output-dir",
        default=None,
        help="Use to specify an exact directory where the install output will be placed. Overwrites --output-base-dir setting.",
    )
    package_arg = parser.add_argument(
        "PACKAGE", nargs="*", help="Packages to cross-compile"
    )
    if __argcomplete:
        package_arg.completer = PkgChoicesCompleter(workspace_path)
        argcomplete.autocomplete(parser)
    args = parser.parse_args()
    if not cross_compile(
        workspace_path=workspace_path,
        packages=args.PACKAGE,
        ros_distro=args.ros_distro,
        platform=args.platform,
        clean=args.clean,
        no_cache=args.no_cache,
        rebuild=args.rebuild,
        output_base_dir=args.output_base_dir,
        output_dir=args.output_dir,
        base_image=args.base_image,
        pull=args.pull
    ):
        exit(1)
