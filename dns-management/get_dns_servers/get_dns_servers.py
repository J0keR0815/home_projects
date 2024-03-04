#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Description:

This program is used to request available nameservers from OpenNIC.
The requested nameservers are required to not keep logs and to be able
to communicate using TLS-encryption (DNS over TLS).
The program can be used to update stubby and the fritzbox. The default
case is just requesting the nameservers and displaying these.

Usage: get_dns_servers.py [OPTIONS]

Options:

-c <configfile>:    Loads specified configuration file
                    Default: /etc/.get_dns_servers.conf

-f:                 The nameserver settings of the FritzBox are
                    updated using the new nameserver information
                    (not implemented yet)

-h:                 Print usage information

-s:                 The stubby configuration file is updated using
                    the new nameserver information.

-S:                 The stubby configuration file is updated using
                    the backup nameserver information.

-t:                 If this options is used, the following actions
                    are processed:

                    1) stubby.service is stopped
                    2) A temporary stubby process is started using
                       the settings of the configuration file which is
                       specified in the configuration file for this
                       program (option: path_stubby_conf_tmpl)
                    3) The tasks, requested from this program are
                       processed
                    4) The temporary stubby process is finished
                    5) stubby.service is started again
"""

# from fritzconnection import FritzConnection
import getopt
import http.client
import logging
import os
import re
import shlex
import ssl
import subprocess
import sys

# Path to default configuration file
default_path_config = "/etc/.get_dns_servers.conf"

# Valid configuration options
config_opts = [
    "cert_opennic",
    "digest_method",
    "host_opennic",
    "location",
    "path_fritz_conf",
    "path_get_dot_cert",
    "path_logfile",
    "path_stubby_conf",
    "path_stubby_conf_tmpl",
    "tls_port"
]

fritz_config_opts = [
    "address",
    "password",
    "use_tls",
    "user"
]


def create_stubby_config(ns_records, config):
    """
    This function creates a stubby configuration file adding the
    nameserver records into the stubby configuration template
    """

    result = ""

    # Read configuration template
    fd = open(config["path_stubby_conf_tmpl"], "r")
    result = fd.read()
    fd.close()

    # Add upstreams
    if ns_records is not None:
        # Uncomment if backup server shall be commented in stubby-config
        # lines = fd.readlines()
        #
        # regex1 = re.compile(r"^.+- address_data: 9\.9\.9\.9.*$")
        # regex2 = re.compile(r"^[^#].+tls_auth_name: \"dns\.quad9\.net\".*$")
        # for line in lines:
        #     entry = regex1.search(line)
        #     if entry is not None:
        #         result += "#{}".format(line)
        #         continue
        #
        #     entry = regex2.search(line)
        #     if entry is not None:
        #         result += "#{}".format(line)
        #         continue
        #
        #     result += "{}".format(line)

        result += "\n##### IPv4 addresses #####\n\n"
        for ns_record in ns_records:
            upstream = create_stubby_upstream(ns_record, 4)
            result += upstream.replace("\t", " " * 4)
            result += "\n"

        result += "##### IPv6 addresses #####\n#\n"
        for ns_record in ns_records:
            upstream = create_stubby_upstream(ns_record, 6)
            upstream = upstream.replace("\n", "\n#")
            result += "#{}\n".format(upstream.replace("\t", " " * 4))

    fd = open(config["path_stubby_conf"], "w")
    fd.write(result)
    fd.close()


def create_stubby_upstream(ns_record, ipv):
    """
    This function creates an upstream entry for the stubby
    configuration file using the record-object containing the
    nameserver information

    @return upstream string matching yml-format
    """

    upstream = ""
    if ipv == 4:
        upstream += "\t- address_data: {}\n".format(ns_record["ipv4"])
    elif ipv == 6:
        upstream += "\t- address_data: {}\n".format(ns_record["ipv6"])
    else:
        return None

    upstream += "\t  tls_auth_name: \"{}\"\n".format(ns_record["cn"])
    upstream += "\t  tls_port: {}\n".format(ns_record["tls_port"])
    upstream += "\t  tls_pubkey_pinset:\n"
    upstream += "\t\t  - digest: \"{}\"\n".format(
        ns_record["digest_method"]
    )
    upstream += "\t\t    value: {}\n".format(ns_record["digest_value"])

    return upstream


def find_html_elements(html_content, dtagname, str_regex):
    """
    This function filters html elements specified by tagname and a string
    describing a regular expression.

    @return: searched html elements on success, an empty array on error
    """

    results = []

    if not (type(html_content) is str and html_content.strip() != ""):
        return None

    if not (type(dtagname) is str and dtagname.strip() != ""):
        return None

    if not (type(str_regex) is str and str_regex.strip() != ""):
        return None

    delim = "#%" * 3
    elements = html_content.replace(
        "\n", ""
    ).replace(
        "\r", ""
    ).replace(
        "<{}".format(dtagname), "{}<{}".format(delim, dtagname)
    ).replace(
        "</{}>".format(dtagname), "</{}>{}".format(dtagname, delim)
    ).split(delim)

    regex = re.compile(str_regex)
    for elem in elements:
        if regex.search(elem) is not None:
            results.append(elem)

    return results


def get_ns_record(html_entry, config):
    """
    This function resolves the HTML-span-element containing
    the information of the nameserver record

    @return dictionary containing nameserver information or
            None on error
    """

    record = {}

    record["ns"] = find_html_elements(
        html_entry, "span", "class=\'host\'"
    )[0].split(
        "</a>"
    )[0].split(
        ">"
    )[-1]

    record["ipv4"] = find_html_elements(
        html_entry, "span", "class=\'mono ipv4\'"
    )[0].split(
        "</span>"
    )[0].split(
        ">"
    )[-1]

    record["ipv6"] = find_html_elements(
        html_entry, "span", "class=\'mono ipv6\'"
    )[0].split(
        "</span>"
    )[0].replace(
        "<wbr>", ""
    ).split(
        ">"
    )[-1]

    cmd = "/bin/bash {} {} {}".format(
        config["path_get_dot_cert"],
        record["ipv4"],
        config["tls_port"]
    )
    out = run_cmd(cmd)

    if len(out) == 0:
        return None

    record["digest_method"] = config["digest_method"]
    record["digest_value"] = out[0]
    record["cn"] = out[1]
    record["tls_port"] = config["tls_port"]

    return record


def get_ns_records(config):
    """
    This function receives the nameserver information from OpenNIC.

    @return list of nameserver records
    """

    # Receive web-content containing DNS-servers from OpenNIC
    ssl_context = ssl.create_default_context()
    ssl_context.load_verify_locations(config["cert_opennic"])
    https_conn = http.client.HTTPSConnection(
        config["host_opennic"], context=ssl_context
    )

    try:
        logging.debug(
            "Requesting https://{}".format(config["host_opennic"])
        )
        https_conn.request("GET", "/")
    except Exception as e:
        logging.debug(
            "Could not receive information from "
            "https://{}\n{}".format(config["host_opennic"], e)
        )
        sys.exit(os.EX_UNAVAILABLE)

    resp = https_conn.getresponse()
    html_content = resp.read().decode("utf-8")

    # Get div-element containing nameservers from country
    # given by location
    div_ns = find_html_elements(
        html_content,
        "div",
        r"ccg\[{}\]".format(config["location"])
    )[0]

    # Get all nameserver elements from div
    list_ns = find_html_elements(
        div_ns,
        "p",
        "No logs kept.*DNS over TLS.*Pass"
    )

    # Get required nameserver information (name, IPv4 and IPv6 address)
    ns_records = []
    for entry in list_ns:
        ns_record = get_ns_record(entry, config)
        if ns_record is None:
            continue
        if ns_record_exists(ns_records, ns_record) is False:
            ns_records.append(ns_record)

    return ns_records


def ns_record_exists(records, new_record):
    """
    This function checks, if the new record exists in a list of records.
    @return True, if a record with the same sha256-digest exists,
            else False
    """
    if not isinstance(records, list):
        return False

    if len(records) == 0:
        return False

    for r in records:
        if new_record["digest_value"] == r["digest_value"]:
            return True

    return False


def print_ns_records(ns_records):
    """
    This function prints the information of the nameservers.
    """
    output = "\n{} {} {}\n\n".format(
        "#" * 5, "List of nameservers", "#" * 5
    )
    for ns_record in ns_records:
        for key in ns_record:
            if key == "ns":
                output += "{} {} {}\n\n".format(
                    "#" * 3, ns_record[key], "#" * 3
                )
            else:
                output += "{:20s}{}\n".format(
                    "{}:".format(key), ns_record[key]
                )
        output += "\n"
    print(output)


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
                raise ValueError("Invalid configuration option")

            if key == "tls_port":
                value = int(value)
                if value < 0 or value > (2 ** 16 - 1):
                    raise ValueError("Invalid port")

            result[key] = value

    return result


def run_cmd(cmd):
    """
    This function executes a command using /bin/bash specified by
    string cmd.

    @return command output on success
    """

    result = b""

    args = shlex.split(cmd)
    p = subprocess.Popen(args, stdout=subprocess.PIPE)

    buf_size = 150
    read_bytes = 150
    while buf_size == read_bytes:
        buf = p.stdout.read(buf_size)
        read_bytes = len(buf)
        result += buf

    return result.decode("utf-8").split("\n")[:-1]


def update_fritz_ns(ns_records, config):
    """
    This function updates the nameservers of the FritzBox
    """

    """
    fritz_conf = read_config(
        config["path_fritz_conf"], fritz_config_opts
    )

    fritz_conn = FritzConnection(
        address=fritz_conf["address"],
        user=fritz_conf["user"],
        password=fritz_conf["password"],
        use_tls=(True if fritz_conf["use_tls"] == "True" else False)
    )

    del fritz_conf

    # TODO: Update DNS-Servers
    """
    pass


def usage(fail=True):
    """
    This function terminates the program printing usage information.
    """

    if fail is True:
        print(__doc__, file=sys.stderr)
        sys.exit(os.EX_USAGE)
    else:
        print(__doc__)
        sys.exit(os.EX_OK)


if __name__ == "__main__":
    # Reading commandline arguments
    path_config = default_path_config
    update_fritz = False
    update_stubby = False
    use_backup = False
    restart_stubby = False
    try:
        (opts, args) = getopt.getopt(sys.argv[1:], "c:fhsSt")
        for opt in opts:
            if opt[0] == "-c":
                path_config = opt[1]
            elif opt[0] == "-f":
                update_fritz = True
            elif opt[0] == "-h":
                usage(fail=False)
            elif opt[0] == "-s":
                update_stubby = True
            elif opt[0] == "-S":
                update_stubby = True
                use_backup = True
            elif opt[0] == "-t":
                restart_stubby = True
            else:
                raise Exception()
    except Exception:
        usage()

    # Reading configuration file
    config = read_config(path_config)

    # Configure the logging-module
    logging.basicConfig(
        filename=config["path_logfile"],
        level=logging.DEBUG,
        format="%(asctime)s %(levelname)s: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        filemode="w"
    )

    ns_records = None
    if use_backup is False:
        ns_records = get_ns_records(config)
        print_ns_records(ns_records)

    if restart_stubby is True:
        # Stop stubby-service
        logging.debug("Stopping stubby.service")
        args = shlex.split("/bin/systemctl stop stubby.service")
        p = subprocess.Popen(args)
        p.wait()

        # Run stubby temporary using configuration template
        logging.debug(
            "Starting temporary stubby-process in background using "
            "configuration template {}".format(
                config["path_stubby_conf_tmpl"]
            )
        )
        args = shlex.split(
            "/usr/bin/stubby -C {}".format(config["path_stubby_conf_tmpl"])
        )
        p = subprocess.Popen(args)
        logging.debug("PID of stubby: {}".format(p.pid))

    if update_stubby is True:
        # Write configuration file
        logging.debug(
            "Writing nameserver information to "
            "configuration file {}".format(config["path_stubby_conf"])
        )
        create_stubby_config(ns_records, config)

    if restart_stubby is True:
        # Stop temporary stubby process
        logging.debug(
            "Finishing temporary stubby process (PID: {})".format(p.pid)
        )
        p.terminate()

        # Start stubby-service again with new config
        logging.debug(
            "Starting stubby.service with new "
            "configuration ({})".format(config["path_stubby_conf"])
        )
        args = shlex.split("/bin/systemctl start stubby.service")
        p = subprocess.Popen(args)
        p.wait()

    if update_fritz is True:
        logging.debug(
            "Updating DoT-capable nameservers of the FritzBox "
            "is not yet implented..."
        )
        # update_fritz_ns(ns_records, config)

    sys.exit(os.EX_OK)
