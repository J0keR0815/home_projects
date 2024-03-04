#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Description:

This program is used to update the DynDNS-information

Usage: update-dyndns.py [OPTIONS]

Options:

-c <configfile>:    Loads specified configuration file
                    Default: /etc/.update-dyndns.conf

-f:                 The DynDNS-settings of the FritzBox are updated

-h:                 Print usage information
"""

# from fritzconnection import FritzConnection
import dns.resolver
import getopt
import json
import logging
import re
import requests
import socket
import sys

EXIT_SUCCESS = 0
EXIT_FAILURE = 1

# Path to default configuration file
default_path_config = "/etc/.update-dyndns.conf"

# Valid configuration options
config_opts = [
    "ddns_domain_name",
    "ddns_url",
    "ddns_token",
    "ddns_verbose",
    "domain_name",
    "dns_provider_api_url",
    "dns_provider_api_token",
    "path_fritz_conf",
    "path_logfile",
]

fritz_config_opts = [
    "address",
    "password",
    "use_tls",
    "user"
]


def error(msg):
    """
    This function logs the error message and terminates the program
    """

    print("Error: {}".format(msg), file=sys.stderr)
    sys.exit(EXIT_FAILURE)


def is_valid_ipv4_addr(addr):
    """
    This function checks for valid IPv4 address.

    @return True if address is valid otherwise False
    """
    try:
        socket.inet_aton(addr)
        return True
    except Exception:
        return False


def read_config(path, config_opts=config_opts):
    """
    This function reads the information from a configuration file

    @return JSON formatted object on success
    """

    result = {}

    if path is None:
        raise ValueError("Missing path for configuration file")

    fd = open(path, "r")
    lines = fd.readlines()
    fd.close()

    regex = re.compile("(^[ \t]*$|^[ \t]*#.*$)")
    for line in lines:
        if not regex.search(line):
            # Delete whitespaces and attached comments
            entry = line.replace(
                " ", ""
            ).replace(
                "\t", ""
            ).replace(
                "\n", ""
            ).replace(
                "\r", ""
            ).split("#")[0]

            (key, value) = entry.split("=")
            if key not in config_opts:
                raise ValueError("Invalid configuration option {}".format(key))

            if key == "ddns_verbose":
                if value == "True":
                    value = True
                elif value == "False":
                    value = False
                else:
                    raise ValueError("Invalid ddns_verbose option")

            if key == "use_tls":
                if value == "True":
                    value = True
                elif value == "False":
                    value = False
                else:
                    raise ValueError("Invalid use_tls option")

            result[key] = value

    return result


def resolve_domainname(domain_name):
    """
    This function resolves the specified domainname

    @return Corresponding IPv4 address
    """

    ipv4_addr = None
    dns_record = dns.resolver.resolve(domain_name, "A")
    for ipval in dns_record:
        ipv4_addr = ipval.to_text()
    if is_valid_ipv4_addr(ipv4_addr):
        return ipv4_addr
    else:
        raise ValueError("Invalid IPv4-address {}".format(ipv4_addr))


def update_ddns(config):
    """
    This function updates the DynDNS-information via the configured
    DynDNS-provider.
    """

    # Create URL
    dn = config["ddns_domain_name"].split(".")[0]
    url = "{}?domains={}&token={}".format(
        config["ddns_url"],
        dn,
        config["ddns_token"]
    )
    if config["ddns_verbose"] is True:
        url = "{}&verbose={}".format(url, config["ddns_verbose"])

    # Send update-request
    resp = requests.get(url=url)
    html_content = resp.content.decode("utf-8")
    ipv4_addr = None
    for line in html_content.split("\n"):
        if is_valid_ipv4_addr(line):
            ipv4_addr = line
            break
    if ipv4_addr is None:
        raise ValueError("Invalid IPv4-address {}".format(line))

    return ipv4_addr


def update_dns(ipv4_addr, config):
    """
    Updates A-record of configured domain

    @return Old IPv4 address
    """

    resp = None

    # Get all zones
    url = "{}/zones".format(config["dns_provider_api_url"])
    try:
        resp = requests.get(
            url=url,
            headers={
                "Auth-API-Token": config["dns_provider_api_token"]
            }
        )
    except Exception:
        raise Exception("Could not request zones from {}".format(url))

    resp = resp.content.decode("utf-8")
    resp = json.loads(resp)
    zone_id = None
    for z in resp["zones"]:
        if z["name"] == config["domain_name"]:
            zone_id = z["id"]
            break
    if zone_id is None:
        raise Exception("Unknown zone {}".format(config["domain_name"]))

    # Get all records for zone
    url = "{}/records".format(config["dns_provider_api_url"])
    try:
        resp = requests.get(
            url=url,
            params={
                "zone_id": zone_id
            },
            headers={
                "Auth-API-Token": config["dns_provider_api_token"]
            }
        )
    except Exception:
        raise Exception(
            "Could not request records from zone {} from {}".format(
                config["domain_name"], url
            )
        )
    resp = resp.content.decode("utf-8")
    resp = json.loads(resp)
    record_id = None
    record_ipv4 = None
    for r in resp["records"]:
        if r["type"] == "A" and r["name"] == "@":
            record_id = r["id"]
            record_ipv4 = r["value"]
            break
    if record_id is None or not is_valid_ipv4_addr(record_ipv4):
        raise Exception("Record for {} not found".format(
            config["domain_name"]
        ))

    # Update record
    url = "{}/records/{}".format(config["dns_provider_api_url"], record_id)
    try:
        resp = requests.put(
            url=url,
            headers={
                "Content-Type": "application/json",
                "Auth-API-Token": config["dns_provider_api_token"]
            },
            data=json.dumps({
                "value": ipv4_addr,
                "ttl": 60,
                "type": "A",
                "name": "@",
                "zone_id": zone_id
            })
        )
    except Exception:
        raise Exception(
            "Could not update A-record for {} from {} to {}".format(
                config["domain_name"], record_ipv4, ipv4_addr
            )
        )

    return record_ipv4


def update_fritz(config):
    """
    This function updates the DynDNS-settings of the FritzBox

    To get the API-information use the commandline-tool:
    # --port <port>: Set port (Default TLS-port: 49443)
    # -u <user>: Username (Default user: Last logged-in user)
    # -c: Complete API
    # -e: Encryption
    $ fritzconnection -i <ip> --port <port> -u <user> -p <password> -c -e > api

    Updating DynDNS-settings does not work!
    """

    """
    # Load Fritzbox configuration
    fritz_conf = read_config(
        config["path_fritz_conf"], fritz_config_opts
    )

    # Connect to Fritzbox
    if "user" not in fritz_conf:
        fritz_conn = FritzConnection(
            address=fritz_conf["address"],
            password=fritz_conf["password"],
            use_tls=fritz_conf["use_tls"]
        )
    else:
        fritz_conn = FritzConnection(
            address=fritz_conf["address"],
            password=fritz_conf["password"],
            user=fritz_conf["user"],
            use_tls=fritz_conf["use_tls"]
        )

    # Call action
    fritz_conn.call_action("DeviceInfo1", "GetInfo")
    del fritz_conn
    """

    pass


def usage(fail=True):
    """
    This function terminates the program printing usage information.
    """

    if fail is True:
        print(__doc__, file=sys.stderr)
        sys.exit(EXIT_FAILURE)
    else:
        print(__doc__)
        sys.exit(EXIT_SUCCESS)


if __name__ == "__main__":
    # Reading commandline arguments
    path_config = default_path_config
    is_update_fritz = False
    try:
        (opts, args) = getopt.getopt(sys.argv[1:], "c:fh")
        for opt in opts:
            if opt[0] == "-c":
                path_config = opt[1]
            elif opt[0] == "-f":
                is_update_fritz = True
            elif opt[0] == "-h":
                usage(fail=False)
            else:
                raise Exception()
    except Exception:
        usage()

    # Reading configuration file
    config = None
    try:
        config = read_config(path_config)
    except Exception as e:
        error("Could not read config: {}".format(e))

    # Configure the logging-module
    try:
        logging.basicConfig(
            filename=config["path_logfile"],
            level=logging.INFO,
            format="%(asctime)s %(levelname)s: %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
            filemode="w"
        )
    except Exception as e:
        error("Error: Set logging failed: {}".format(e))

    # Update DynDNS-settings of Fritzbox
    if is_update_fritz is True:
        logging.info(
            "Updating DynDNS-information of Fritzbox ..."
        )
        update_fritz(config)

    # Update DynDNS-information
    logging.info("Updating DynDNS-information ...")
    ddns_ipv4 = None
    try:
        ddns_ipv4 = update_ddns(config)
    except Exception:
        error("Updating DynDNS-information for {} failed".format(
            config["ddns_domain_name"]
        ))
    logging.info("IPv4 address for {} is {} ...".format(
        config["ddns_domain_name"], ddns_ipv4
    ))

    # Resolve A-record for configured domain
    logging.info("Resolving A-record for {} ...".format(
        config["domain_name"]
    ))
    dn_ipv4 = None
    try:
        dn_ipv4 = resolve_domainname(config["domain_name"])
    except Exception as e:
        error("Could not resolve {}: {}".format(config["domain_name"], e))
    logging.info("IPv4 address for {} is {} ...".format(
        config["domain_name"], dn_ipv4
    ))

    # Update A-record
    if ddns_ipv4 != dn_ipv4:
        logging.info(
            "Current DynDNS-information differ from "
            "resolved domain IP address: "
            "Updating A-record for domain ..."
        )
        old_ipv4 = None
        try:
            old_ipv4 = update_dns(ddns_ipv4, config)
        except Exception as e:
            error("Updating A-record for domain {} failed: {}".format(
                config["domain_name"], e
            ))
        logging.info(
            "Updated A-record for domain {} from {} to {}".format(
                config["domain_name"], old_ipv4, ddns_ipv4
            )
        )

    sys.exit(EXIT_SUCCESS)
