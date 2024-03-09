#include <cstdlib>
#include <functional>
#include <getopt.h>
#include <libgen.h>
#include "Reader.h"
#include "Writer.h"

using namespace std;

int main(int argc, char *argv[]) {
	boost::asio::io_service ioService;
	boost::asio::ip::tcp::socket sock(ioService);
	boost::asio::ip::tcp::endpoint *endpoint {nullptr};
	boost::asio::ip::tcp::acceptor *acceptor {nullptr};
	boost::system::error_code err;

	if (getopt(argc, argv, "l") == -1 && argc == 3) {
		// Client mode

		int port {atoi(argv[2])};
		if (port < 0) {
			throw invalid_argument("Value of \"port\" cannot be negative!");
		}
		endpoint = new boost::asio::ip::tcp::endpoint(
			boost::asio::ip::address::from_string(argv[1]),
			static_cast<unsigned int>(port)
		);

		sock.connect(
			*endpoint,
			err
		);

		cout << "Local endpoint: " << sock.local_endpoint() << '\n' <<
				"connected to " << sock.remote_endpoint() << '\n';
	} else if (getopt(argc, argv, "p:") != -1 && argc == 3) {
		// Server mode

		int port {atoi(optarg)};
		if (port < 0) {
			throw invalid_argument("Value of \"port\" cannot be negative!");
		}
		endpoint = new boost::asio::ip::tcp::endpoint(
			boost::asio::ip::tcp::v4(),
			static_cast<unsigned int>(port)
		);

		acceptor = new boost::asio::ip::tcp::acceptor(
			ioService,
			*endpoint
		);

		acceptor->accept(
			sock,
			err
		);

		cout << "Local endpoint: " << sock.local_endpoint() << '\n' <<
				"connected to " << sock.remote_endpoint() << '\n';
	} else {
		// Server mode, but no port given
		cerr << "Usage Error:\n" <<
				"\tClient Mode: " <<
				basename(argv[0]) << " <server-ip> <port>\n" <<
				"\tServer Mode: " <<
				basename(argv[0]) << " -l -p <Port>\n";
		exit(EXIT_FAILURE);
	}

	boost::mutex mutex;
	boost::condition_variable cond;

	Reader reader(sock, cond);
	Writer writer(sock, cond);
	boost::thread t_reader(std::ref(reader));
	boost::thread t_writer(std::ref(writer));

	boost::unique_lock<boost::mutex> lock(mutex);
	while (!reader.finished() && !writer.finished()) {
		cond.wait(lock);
	}

	if (reader.finished()) {
		writer.kill_read_thread();
		t_writer.interrupt();
	} else if (writer.finished()) {
		t_reader.interrupt();
	}

	sock.shutdown(boost::asio::ip::tcp::socket::shutdown_both, err);
	t_reader.join();
	t_writer.join();

	if (acceptor) {
		delete acceptor;
	}

	if (endpoint) {
		delete endpoint;
	}
}
