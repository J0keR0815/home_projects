#include "Writer.h"

using namespace std;

void Writer::operator()() {
	try {
		string input;
		boost::system::error_code err;
		size_t numBytes;

		do
		{
			input = "";
			StdInReader r(input);
			this->read_thread = new boost::thread(r);
			this->read_thread->join();
			delete this->read_thread;
			this->read_thread = nullptr;

			char buf[input.length() + 2];
			strcpy(buf, input.c_str());
			strcat(buf, "\n");

			numBytes = this->sock.write_some(
				boost::asio::buffer(buf, input.length() + 2),
				err
			);

			if (input.compare("exit") == 0) {
				this->is_finished = true;
				this->cond.notify_all();
			}
		} while (numBytes > 0 && !this->is_finished);
	} catch (boost::thread_interrupted &e) {
	}
}
