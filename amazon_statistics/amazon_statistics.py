#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Description:

This program reads csv-files where each file contains the report about
amazon orders of a year. Using these reports statistical analysis can
be done. The default operation is just printing the reports to STDOUT
without analyzing the data.
The files are stored in a data directory. The default path is
"$PWD/data". If the data is stored anywhere else, it must be specified
by an optional parameter in the configuration file.

Usage:  amazon_statistics.py [OPTIONS]

Options:

-a a_1,[a_2,...]:   Processes statistical analysis. The anaylisis
                    methods can be specified by a comma-separated
                    list of anaylisis parameters (See the list of
                    analysis parameters below)

-c <configfile>:    Load specified configuration file

-h:                 Print usage information

Analysis parameters:

ALL:    Proceeds all analyzing methods

CC:     Plots an ogive, where the cumulated consumption over the
        months is visualized

ME:     Prints the following measures for the consumption over the
        months and the consumption of videos over the months:
        - Minimum, maximum
        - Sum in total
        - Mean, variance, standard deviation
        - Median, Inter-quartile-range (iqr), mode

MC:     Plots a bar graph for the monthly consumption in total and for
        the monthly consumption of videos
"""

from collections import OrderedDict
import csv
import getopt
import math
import matplotlib.pyplot as plt
import numpy
import os
import re
import sys
import time

# Default value for data directory which stores the csv-files containing
# the yearly reports for amazon orders
DEFAULT_DATA_DIR = "data"

# Default value for suffix which specifies the suffix of the csv-files.
# The csv-files match the pattern yyyy_<suffix>.csv
DEFAULT_SUFFIX = "amazon_orders"

# List of valid options in configuration file
CONFIG_OPTS = [
    "data_dir",
    "suffix"
]

"""
Analysis options: The options are evaluated by a bit-mask.
If the mask is set to 0, then no analysis will be done and the default
operation is performed, which is printing the reports to STDOUT.
"""

A_ALL = 0xf
A_CUMULATED_CONSUMPTION = 0x1
A_MEASURES = 0x2
A_MONTHLY_CONSUMPTION = 0x4

# List of valid analysis parameters
ANALYSIS_OPTS = {
    "ALL": A_ALL,
    "CC": A_CUMULATED_CONSUMPTION,
    "ME": A_MEASURES,
    "MC": A_MONTHLY_CONSUMPTION
}


class report_year():
    """
    This class is responsible for processing the orders of a year.
    """

    def __init__(self, year):
        """
        Constructor: Initializes a report_month-instance for each month.
        """

        self.year = year
        self.months = [None] * 12
        for i in range(0, 12):
            self.months[i] = report_month(i)

    def add(self, csv_dict):
        """
        This method adds a csv-entry to the data-container of the
        corresponding report_month-instance.
        """

        keys = list(csv_dict.keys())

        # Repair key "order_id"
        csv_dict["order_id"] = csv_dict.pop(keys[0])

        # Repair key "vat"
        csv_dict["vat"] = csv_dict.pop("VAT")

        # Assign data to a month
        t = time.strptime(csv_dict["date"], "%Y-%m-%d")
        csv_dict["date"] = t
        self.months[t.tm_mon - 1].add(csv_dict)

    def get_extrema(self, movies=False):
        """
        This function searches for those months, where the consumption
        of the year were minimal and maximal.
        If movies is True, only the movies are evaluated.

        @return Tupel (minimum, maximum), where both are dictionaries
                matching {"year": <y>, "month": <m>, "val": <v>}
        """

        minimum = {
            "year": self.year,
            "month": "",
            "val": -1
        }
        maximum = {
            "year": self.year,
            "month": "",
            "val": -1
        }
        for m in self.months:
            if minimum["val"] == -1:
                minimum["month"] = maximum["month"] = m.mon
                minimum["val"] = m.sum if movies is False \
                    else m.sum_movies
                maximum["val"] = m.sum if movies is False \
                    else m.sum_movies
            else:
                min_new = m.sum if movies is False \
                    else m.sum_movies
                max_new = m.sum if movies is False \
                    else m.sum_movies
                if min_new < minimum["val"]:
                    minimum["month"] = m.mon
                    minimum["val"] = min_new
                if max_new > maximum["val"]:
                    maximum["month"] = m.mon
                    maximum["val"] = max_new

        return (minimum, maximum)

    def get_months(self, short=False):
        """
        Creates a list of months containing data for the year
        matching the pattern:
        ["JANUARY <yyyy>", "FEBRUARY <yyyy>", ..., "<MONTH> <yyyy>"]
        If short is true the months labels will be shortened:
        ["JAN <yyyy>", "FEB <yyyy>", ..., "<MON> <yyyy>"]

        @return list of months
        """

        months = []
        for m in self.months:
            mon = m.mon if short is False else m.mon[0:3]
            months.append("{} {}".format(mon, self.year))
        return months

    def get_sqrsum_total(self, mean, movies=False):
        """
        This function calculates the sum of squares of the monthly
        expenses on amazon over the year, each subtracted by the mean.
        If movies is True, only the movies are evaluated.

        @return Sum of squares in €^2
        """

        sqrsum_total = 0
        for m in self.months:
            val = m.sum if movies is False else m.sum_movies
            sqrsum_total += (val - mean) ** 2
        return sqrsum_total

    def get_sum_total(self, movies=False):
        """
        This function calculates the total money spent on amazon over
        the year.
        If movies is True, only the movies are evaluated.

        @return Consumption over the year in €
        """

        sum_total = 0
        for m in self.months:
            sum_total += m.sum if movies is False else m.sum_movies
        return sum_total

    def get_values(self, movies=False):
        """
        This function creates a list of expenses for each month of
        the year.

        @return list of expenses over the year in €
        """

        values = []
        for m in self.months:
            values.append(m.sum if movies is False else m.sum_movies)
        return values

    @staticmethod
    def create_report(path_file, year):
        """
        This method reads the order information from a csv-report for a
        year.

        @return report_year-object containing the order information
        """
        
        result = report_year(year)
        fd = open(path_file, "r")
        csv_object = csv.DictReader(fd)
        for d in csv_object:
            result.add(d)
        fd.close()
        result.trim()

        return result

    def str(self):
        """
        This method returns a formatted string containing the
        information for each order of the year.

        @return formatted data string
        """

        result = ""
        for m in self.months:
            s = m.str()
            result += "{}\n".format(s)
        return result

    def trim(self):
        """
        This method removes empty months.
        """

        for i in range(len(self.months), 0, -1):
            if len(self.months[i - 1].data) == 0:
                del(self.months[i - 1])


class report_month():
    """
    This class is responsible for processing the orders of a month of a
    year
    """

    MONTHS = [
        "JANUARY",
        "FEBRUARY",
        "MARCH",
        "APRIL",
        "MAY",
        "JUNE",
        "JULY",
        "AUGUST",
        "SEPTEMBER",
        "OCTOBER",
        "NOVEMBER",
        "DECEMBER"
    ]

    def __init__(self, n_mon):
        """
        Constructor: Initializes the month and an empty data dictionary.
        """

        self.n_mon = n_mon
        self.mon = report_month.MONTHS[self.n_mon]
        self.data = {}
        self.sum = 0
        self.sum_movies = 0

    def add(self, data_dict):
        """
        This method adds an order to the data dictionary.
        The entries are identified by the order id. The values are
        instances of data_object.
        """

        order_id = data_dict.pop("order_id")
        self.data[order_id] = data_object(**data_dict)
        self.sum += self.data[order_id].total
        if self.data[order_id].movie is True:
            self.sum_movies += self.data[order_id].total

    def str(self):
        """
        This method returns a formatted string containing the
        information for each order of the month.

        @return formatted data string
        """

        # Create a header for the month
        result = "{}:\n{}\n\n".format(
            self.mon, (len(self.mon) + 1) * "-"
        )

        # Add the order
        for order_id in self.data:
            result += "Order ID: {}\n\n{}\n\n".format(
                order_id,
                self.data[order_id].str()
            )

        return result


class data_object():
    """
    This class is responsible to process the data of a single order.
    """

    def __init__(
        self,
        items,
        to,
        date,
        total,
        shipping,
        shipping_refund,
        gift,
        vat,
        refund,
        payments
    ):
        """
        Constructor: Initializes the object by assigning the csv-data
        for an order.

        Interesting data for statistical analysis are only:
        - self.movie
        - self.total
        - self.date
        """

        self.items = items
        self.to = int(to) if to == "0" else to
        self.movie = True if to == "0" else False
        self.date = date
        self.total = float(total.replace(",", "."))
        self.shipping = float(shipping.replace(",", "."))
        self.shipping_refund = float(shipping_refund.replace(",", "."))
        self.gift = float(gift.replace(",", "."))
        self.vat = float(vat.replace(",", "."))
        self.refund = float(refund.replace(",", ""))
        self.payments = payments

    def str(self):
        """
        This method returns a formatted string containing the
        information for a single order.

        @return formatted data string
        """

        result = "Items: {}\n"
        result += "Movie: {}\n"
        result += "Date: {}\n"
        result += "Total: {}\n"
        result += "Shipping: {}\n"
        result += "Shpping refund: {}\n"
        result += "Gift: {}\n"
        result += "VAT: {}\n"
        result += "Refund: {}\n"
        result += "Payments: {}\n"
        result = result.format(
            self.items,
            "Yes" if self.movie is True else "No",
            time.strftime("%d.%m.%Y", self.date),
            self.total,
            self.shipping,
            self.shipping_refund,
            self.gift,
            self.vat,
            self.refund,
            self.payments
        )
        return result


def display_cumulated_consumption(data):
    """
    Plots an ogive for the monthly consumption on Amazon and the monthly
    consumption on videos on Amazon.
    """

    values = []
    values_movies = []
    months = []
    for y in data:
        values += data[y].get_values()
        values_movies += data[y].get_values(movies=True)
        months += data[y].get_months(short=True)

    for i in range(1, len(values)):
        values[i] += values[i - 1]
        values_movies[i] += values_movies[i - 1]

    plt.rcdefaults()
    fig, ax = plt.subplots()

    x_pos = numpy.arange(len(months))
    ax.plot(x_pos, values, label="Cumulated expenses in total")
    ax.plot(x_pos, values_movies, label="Cumulated expenses on videos")
    ax.set_xticks(x_pos)
    ax.set_xticklabels(months)
    plt.xticks(rotation=75)
    ax.set_ylabel("Expenses in €")
    title = "Cumulated expenses on Amazon"
    ax.set_title(title)
    ax.grid()
    plt.show()


def display_measures(data, movies=False):
    """
    This function calculates and displays the following measures:
    - Minimum, maximum
    - Sum in total
    - Mean, variance, standard deviation
    - Median, Inter-quartile-range (iqr), mode
    If movies is True, only the movies are evaluated.
    """

    minimum = None
    maximum = None
    sum_total = 0
    n_months = 0
    values = []
    for y in data:
        min_new, max_new = data[y].get_extrema(movies)

        if minimum is None:
            minimum = min_new
            maximum = max_new
        else:
            if min_new["val"] < minimum["val"]:
                minimum = min_new
            if max_new["val"] > maximum["val"]:
                maximum = max_new

        sum_total += data[y].get_sum_total(movies)
        n_months += len(data[y].months)
        arr = data[y].get_values(movies)
        values += arr

    mean = sum_total / n_months

    sqrsum_total = 0
    for y in data:
        sqrsum_total += data[y].get_sqrsum_total(mean, movies)

    var = sqrsum_total / n_months
    sigma = math.sqrt(var)

    values.sort()
    median = get_median(values)
    q1, q3, iqr = get_iqr(values)

    output = "Minimum: {} {} --> {:.2f} €\n".format(
        minimum["month"],
        minimum["year"],
        minimum["val"]
    )

    output += "Maximum: {} {} --> {:.2f} €\n".format(
        maximum["month"],
        maximum["year"],
        maximum["val"]
    )

    output += "Sum total: {:.2f} €\n".format(sum_total)
    output += "Mean: {:.2f} €\n".format(sum_total / n_months)
    output += "Variance: {:.2f} €^2\n".format(var)
    output += "Standard deviation: {:.2f} €\n".format(sigma)
    output += "Q1: {:.2f} €\n".format(q1)
    output += "Median {:.2f} €\n".format(median)
    output += "Q3: {:.2f} €\n".format(q3)
    output += "IQR {:.2f} €\n".format(iqr)

    print(output)


def display_monthly_consumption(data, movies=False):
    """
    Plots a bar graph for the monthly consumption on Amazon.
    If movies is True, only the movies are evaluated.
    """

    values = []
    months = []
    for y in data:
        values += data[y].get_values(movies)
        months += data[y].get_months()

    plt.rcdefaults()
    fig, ax = plt.subplots()

    y_pos = numpy.arange(len(months))
    ax.barh(y_pos, values, align="center")
    ax.set_yticks(y_pos)
    ax.set_yticklabels(months)
    ax.invert_yaxis()
    ax.set_xlabel("Expenses in €")
    title = "Monthly expenses on {}Amazon".format(
        "Movies on " if movies is True else ""
    )
    ax.set_title(title)
    ax.grid()
    plt.show()


def get_iqr(values):
    """
    This function finds the 1st and 3rd quartile (q1 and q3) in a sorted
    list and calculates the inter-quartile-range (iqr).

    @return Tupel: (q1, q3, iqr)
    """

    list1 = None
    list2 = None
    if len(values) % 2 == 0:
        index = int(len(values) / 2)
        list1 = values[0:index]
        list2 = values[index::]
    else:
        index = int(len(values) / 2)
        list1 = values[0:index]
        list2 = values[index + 1::]

    q1 = get_median(list1)
    q3 = get_median(list2)
    iqr = q3 - q1
    return (q1, q3, iqr)


def get_median(values):
    """
    This function finds the median in a list of sorted values.

    @return median
    """

    median = -1
    if len(values) % 2 == 0:
        index = int(len(values) / 2) - 1
        median = 1 / 2 * (values[index] + values[index + 1])
    else:
        index = int(len(values) / 2)
        median = values[index]

    return median


def print_data(data):
    """
    This function prints the data for each year.
    """

    for y in data:
        # Creating header for the year
        print("{} {} {}\n".format(10 * "#", y, 10 * "#"))

        # Print formatted string for orders of a year
        print("{}\n".format(data[y].str()))


def read_config(path, config={}):
    """
    This function reads the information from a configuration file
    and stores it in the dictionary specified as an argument.

    @return JSON formatted object on success
    """

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
            if key not in CONFIG_OPTS:
                raise ValueError("Invalid configuration option")
            config[key] = value


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


if __name__ == '__main__':
    # Initializing config data
    config = {
        "data_dir": DEFAULT_DATA_DIR,
        "suffix": DEFAULT_SUFFIX
    }

    # Reading commandline arguments
    a_opts = None
    try:
        (opts, args) = getopt.getopt(sys.argv[1:], "a:c:h")
        for opt in opts:
            if opt[0] == "-a":
                a_opts = opt[1]
            elif opt[0] == "-c":
                config["path_config"] = opt[1]
            elif opt[0] == "-h":
                usage(fail=False)
            else:
                raise Exception()
    except Exception:
        usage()

    # Check analysis options
    a_opts_mask = 0
    if a_opts is not None:
        a_opts = a_opts.split(",")
        for a_opt in a_opts:
            if a_opt in ANALYSIS_OPTS:
                a_opts_mask |= ANALYSIS_OPTS[a_opt]
            else:
                usage()

    # Reading configuration file
    if "path_config" in config:
        read_config(config["path_config"], config)

    # Reading data
    regex = "^[0-9]{{4}}_{}\\.csv$".format(config["suffix"])
    data = {}
    entries = os.listdir(config["data_dir"])
    for entry in entries:
        if re.match(regex, entry) is not None:
            year = entry.split("_")[0]
            path_file = "{}/{}".format(config["data_dir"], entry)
            data[year] = report_year.create_report(path_file, year)

    # Sort data
    data = OrderedDict(sorted(data.items()))

    # Process analyisis
    if a_opts_mask == 0:
        print_data(data)

    if (a_opts_mask & A_CUMULATED_CONSUMPTION) == A_CUMULATED_CONSUMPTION:
        display_cumulated_consumption(data)

    if (a_opts_mask & A_MEASURES) == A_MEASURES:
        print("{} Measures Total {}\n".format(10 * "#", 10 * "#"))
        display_measures(data)
        print("{} Measures Movies {}\n".format(10 * "#", 10 * "#"))
        display_measures(data, True)

    if (a_opts_mask & A_MONTHLY_CONSUMPTION) == A_MONTHLY_CONSUMPTION:
        display_monthly_consumption(data)
        display_monthly_consumption(data, movies=True)
