#ifndef STDINREADER_H
#define STDINREADER_H

#include <iostream>
#include <string>

class StdInReader {
	public:
		StdInReader(std::string &input);
		void operator()();
	private:
		std::string &input;
};

inline StdInReader::StdInReader(std::string &input) : input {input} {

}

#endif // STDINREADER_H
