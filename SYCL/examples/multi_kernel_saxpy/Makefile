objects = saxpy_multi_kernel saxpy_multi_device1 saxpy_multi_device2

all: $(objects)

$(objects): %: %.cpp
	icpx -fsycl $< -o $@ -Wall -O3

clean:
	rm -f $(objects)
