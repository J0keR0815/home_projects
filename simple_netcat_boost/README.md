# README #

* This program was used to implement a **simple netcat** using `boost` for multithreading and socket communication.
* To build the program install the developer `boost` library (`boost` for Arch Linux, `libboost-dev` for Debian) and run the following command:

```bash
user@host:/PATH/TO/PROJECT_DIR$ \
    g++ -o mynetcat *.cpp *.h -lboost_system -lboost_thread
```

* Run on server side:

```
user@host:/PATH/TO/PROJECT_DIR$ mynetcat -lp 44444
```

* Run on client side:

```
user@host:/PATH/TO/PROJECT_DIR$ mynetcat 127.0.0.1 44444
```

* Now you can send messages between server and client.
