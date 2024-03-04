#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from typing import Any, Dict, List

FILE_PASSWORDS = "./passwords"
FILE_WORDLIST = "./wordlist"

'''
Add expected characters and there substitutions
'''
SUBSTITUTES = {
    "p": ["P"],
    "a": ["A", "4", "@"],
    "s": ["§", "5", "s", "S", "$"],
    "w": ["W"],
    "o": ["O", "0"],
    "r": ["R"],
    "d": ["D"]
}


def make_tree(pw: int, substitutes: Dict[str, List[str]]):
    result = {}

    if len(pw) > 0:
        c = pw[0]
        result[c] = make_tree(pw[1:], substitutes)
        if c in substitutes:
            for v in substitutes[c]:
                result[v] = make_tree(pw[1:], substitutes)
        return result
    else:
        return None


def get_tree_paths(tree: Dict[str, Any], paths: List[str]):
    for k in tree:
        v = tree[k]
        sub_tree_paths = []

        if v is None:
            paths.append(k)
            continue

        if isinstance(v, Dict):
            get_tree_paths(v, sub_tree_paths)

        for i in range(0, len(sub_tree_paths)):
            paths.append(sub_tree_paths[i] + k)


if __name__ == '__main__':
    # Read passwords to vary
    file_passwords = open(FILE_PASSWORDS, "r")
    pws = file_passwords.read()
    pws = pws.splitlines()
    file_passwords.close()

    # Create wordlist set
    wordlist = set()
    for pw in pws:
        tree = make_tree(pw, SUBSTITUTES)
        paths = []
        get_tree_paths(tree, paths)
        wordlist.update(paths)

    # Write sorted wordlist
    file_wordlist = open(FILE_WORDLIST, "w")
    for entry in sorted(wordlist):
        file_wordlist.write(entry[::-1] + "\n")
    file_wordlist.close()
