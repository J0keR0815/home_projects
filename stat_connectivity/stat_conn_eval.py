#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Usage: stat_conn_eval.py <file>
"""

import re
import sys

EXIT_SUCCESS = 0
EXIT_FAILURE = 255


class stat_conn:
    """
    This class is responsible handle the data of a stat-file, which
    was produced by stat_connectivity.sh
    """

    def __init__(self, fn):
        """
        The constructor reads the stat-file produced from
        stat_connectivity.sh and extracts values for each timestamp
        """

        try:
            self.name = fn

            # Read stat-file
            fd = open(fn, "r")
            lines = fd.read()
            lines = lines.split("\n")[:-1]
            fd.close()

            # Remove RRSIG record entries
            for line in lines:
                regex = r"^.*RRSIG record.*$"
                if re.search(regex, line) is not None:
                    lines.remove(line)

            # Extract results:
            # Number of measurement values
            self.n = int(len(lines) / 2)

            # Number of measurement values with no connectivity
            n_off_conn = 0

            # Number of measurement values with no domain name resolution
            n_off_dn_res = 0

            # Time periods with no connectivity
            self.off_conn = []

            # Time periods with no domain name resolution
            self.off_dn_res = []

            # Set start time of measurement
            self.t_beg = self.get_timestamp(lines[0])

            # Set end time of measurement
            self.t_end = self.get_timestamp(lines[-1])

            # Flag to monitor change of connectivity status
            is_conn = True

            # Flag to monitor change of domain name resolution status
            is_dn_res = True

            for i in range(0, len(lines), 2):
                # Parse entries for timestamp
                v = {
                    "is_connected": self.is_connected(lines[i]),
                    "is_dn_resolved": self.is_dn_resolved(lines[i + 1]),
                    "t": self.get_timestamp(lines[i])
                }

                # Increment if no connection
                if v["is_connected"] is False:
                    n_off_conn += 1

                # Increment if no name resolution
                if v["is_dn_resolved"] is False:
                    n_off_dn_res += 1

                # Monitor timestamps on connection state change
                if is_conn is not v["is_connected"]:
                    if is_conn is True:
                        # Connection lost
                        is_conn = False
                        self.off_conn.append({
                            "t_beg": v["t"]
                        })
                    else:
                        # Connection restored
                        is_conn = True
                        self.off_conn[-1]["t_end"] = v["t"]

                # Monitor timestamps on name resolution state change
                if is_dn_res is not v["is_dn_resolved"]:
                    if is_dn_res is True:
                        # Ability for name resolution lost
                        is_dn_res = False
                        self.off_dn_res.append({
                            "t_beg": v["t"]
                        })
                    else:
                        # Ability for name resolution restored
                        is_dn_res = True
                        self.off_dn_res[-1]["t_end"] = v["t"]

            self.perc_off_conn = float(100 * n_off_conn / self.n)
            self.perc_off_dn_res = float(100 * n_off_dn_res / self.n)

        except Exception as err:
            error(err)

    def is_connected(self, line):
        """
        Extracts from a line of stat-file, if connection to reference
        ip was possible.
        """

        regex = r"cannot be established"
        if re.search(regex, line) is None:
            return True
        else:
            return False

    def is_dn_resolved(self, line):
        """
        Extracts from a line of stat-file, if reference domain name
        could be resolved.
        """

        regex = r"cannot be resolved"
        if re.search(regex, line) is None:
            return True
        else:
            return False

    def get_timestamp(self, line):
        """
        Extracts timestamp from a line of a stat-file
        """

        regex = r"[0-9]{2}\.[0-9]{2}\.[0-9]{4} [0-9]{2}:[0-9]{2}"
        matches = re.findall(regex, line)
        if len(matches) == 1:
            return matches[0]
        else:
            raise ValueError("No timestamp found in line")

    def str(self):
        result = \
            "Results for {}\n" \
            "- Start time: {}\n" \
            "- End time: {}\n" \
            "- Measured values: {}\n" \
            "- Connection offline [%]: {:.2f}\n" \
            "- Name resolution offline [%]: {:.2f}\n\n" \
            .format(
                self.name,
                self.t_beg,
                self.t_end,
                self.n,
                self.perc_off_conn,
                self.perc_off_dn_res
            )

        result += "Connection offline:\n"
        for e in self.off_conn:
            result += "{} - {}\n".format(e["t_beg"], e["t_end"])
        result += "\nName resolution offline:\n"
        for e in self.off_dn_res:
            result += "{} - {}\n".format(e["t_beg"], e["t_end"])

        return result


def error(err):
    """
    This function raises an error after catching an exception.
    The program is terminated using the error code as exit code
    """

    msg = "{}".format(
        err.message if hasattr(err, "message") else err
    )
    print(msg, file=sys.stderr)
    if hasattr(err, "errno"):
        sys.exit(err.errno)
    else:
        sys.exit(EXIT_FAILURE)


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
    if len(sys.argv) <= 1:
        usage()

    for fn in sys.argv[1:]:
        sc = stat_conn(fn)
        print(sc.str(), end="")
