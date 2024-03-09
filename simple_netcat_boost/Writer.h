#ifndef WRITER_H
#define WRITER_H

#define BOOST_BIND_GLOBAL_PLACEHOLDERS

#include <boost/asio.hpp>
#include <boost/bind.hpp>
#include <boost/thread.hpp>
#include <exception>
#include <sstream>
#include "StdInReader.h"

class Writer {
	public:
		Writer(
			boost::asio::ip::tcp::socket &sock,
			boost::condition_variable &cond
		);
		bool finished() const;
		void set_finished(bool b);
		void kill_read_thread();
		void operator()();
	private:
		boost::asio::ip::tcp::socket &sock;
		boost::condition_variable &cond;
		bool is_finished;
		boost::thread *read_thread;
};

inline Writer::Writer(
	boost::asio::ip::tcp::socket &sock,
	boost::condition_variable &cond
) : sock {sock},
	cond {cond},
	is_finished {false},
	read_thread {nullptr} {

}

inline bool Writer::finished() const {
	return this->is_finished;
}

inline void Writer::set_finished(bool b) {
	this->is_finished = b;
}

inline void Writer::kill_read_thread() {
	this->read_thread->interrupt();
}

#endif // WRITER_H
