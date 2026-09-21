"""Read only Terraform outputs and update private addresses in host_vars."""
import argparse
import ipaddress
import json
from pathlib import Path
import subprocess

import yaml


def private_addresses(instances):
    if isinstance(instances, dict) and "value" in instances and "type" in instances:
        instances = instances["value"]
    expected = {"k1", "k2", "k3"}
    if set(instances) != expected:
        raise ValueError("Expected exactly k1, k2 and k3 in Terraform output instances")
    addresses = {}
    for name, instance in instances.items():
        private_ip = instance.get("private_ip")
        if not private_ip:
            raise ValueError(f"{name}: expected private_ip in Terraform output")
        addresses[name] = str(ipaddress.IPv4Address(private_ip))
    if len(set(addresses.values())) != len(addresses):
        raise ValueError("Duplicate private IP addresses")
    return addresses


def terraform_instances(terraform_dir):
    command = ["terraform", f"-chdir={terraform_dir}", "output", "-json", "instances"]
    try:
        result = subprocess.run(command, check=False, capture_output=True, text=True)
    except FileNotFoundError:
        raise SystemExit("terraform was not found on PATH. Install Terraform or use --output-json.")
    if result.returncode == 0:
        return json.loads(result.stdout)
    detail = (result.stderr or result.stdout).strip() or f"exit status {result.returncode}"
    raise SystemExit(
        "terraform output failed.\n"
        f"{detail}\n"
        "On this machine run terraform init in terraform/environments/production "
        "with the S3 backend keys, or copy `terraform output -json instances` "
        "from the host that has state and pass --output-json."
    )


def main():
    root = Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--terraform-dir", type=Path,
                        default=root / "terraform/environments/production")
    parser.add_argument("--output-json", type=Path,
                        help="File produced by terraform output -json instances")
    args = parser.parse_args()
    if args.output_json:
        instances = json.loads(args.output_json.read_text(encoding="utf-8-sig"))
    else:
        instances = terraform_instances(args.terraform_dir)
    addresses = private_addresses(instances)
    directory = root / "ansible/inventory/production/host_vars"
    # Validate all addresses before modifying any host files. Preserve other host settings.
    for name, address in sorted(addresses.items()):
        path = directory / f"{name}.yml"
        variables = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
        variables.update(ansible_host=address, ip=address, access_ip=address)
        path.write_text("---\n" + yaml.safe_dump(variables, sort_keys=False), encoding="utf-8")
        print(f"{name}: {address}")


if __name__ == "__main__":
    try:
        main()
    except ValueError as error:
        raise SystemExit(error) from error
