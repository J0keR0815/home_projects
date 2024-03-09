#ifndef READER_H
#define READER_H

#include <boost/asio.hpp>
#include <boost/thread.hpp>
#include <exception>
#include <iostream>
#include <sstream>
#include <string>

class Reader {
	public:
		Reader(
			boost::asio::ip::tcp::socket &sock,
			boost::condition_variable &cond,
			int buf_size = 1024
		);
		bool finished() const;
		void set_finished(bool b);
		void operator()();
	private:
		boost::asio::ip::tcp::socket &sock;
		boost::condition_variable &cond;
		const size_t BUF_SIZE;
		bool is_finished;
};

inline Reader::Reader(
	boost::asio::ip::tcp::socket &sock,
	boost::condition_variable &cond,
	int buf_size
) : sock {sock},
	cond {cond},
	BUF_SIZE {static_cast<size_t>(buf_size)},
	is_finished {false} {

	if (buf_size <= 0) {
		throw std::invalid_argument(
			"Value of \"buf_size\" must be positiv"
		);
	}
}

inline bool Reader::finished() const {
	return this->is_finished;
}

inline void Reader::set_finished(bool b) {
	this->is_finished = b;
}

#endif // READER_H

