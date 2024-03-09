#include "Reader.h"

using namespace std;

void Reader::operator()() {
	try {
		char buf[this->BUF_SIZE + 1];
		size_t numBytes;
		boost::system::error_code err;
		ostringstream ostrstr;

		do {
			numBytes = this->sock.read_some(
				boost::asio::buffer(buf, this->BUF_SIZE),
				err
			);

			if (err == boost::asio::error::eof) {
				this->is_finished = true;
				this->cond.notify_all();
			} else {
				buf[numBytes] = '\0';
				ostrstr << buf;
				if (ostrstr.str().find('\n') != string::npos) {
					cout << ostrstr.str();
					if (ostrstr.str().compare("exit\n") == 0) {
						this->is_finished = true;
						this->cond.notify_all();
					}
					ostrstr.str("");
					ostrstr.seekp(ios_base::beg);
				}
			}
		} while (numBytes > 0 && !this->is_finished);
	} catch (boost::thread_interrupted &e) {
	}
}
